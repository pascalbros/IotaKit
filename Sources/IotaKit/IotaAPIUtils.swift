//
//  IotaAPIUtils.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 08/01/18.
//

import Foundation

public struct IotaAPIUtils {
	
	public static func newAddress(seed: String, index: Int, checksum: Bool, security: Int = 2) -> String {
		let curl = CurlMode.kerl.create()
		return self.newAddress(seed: seed, security: security, index: index, checksum: checksum, curl: curl)
	}
	
	static func newAddress(seed: String, security: Int, index: Int, checksum: Bool, curl: CurlSource) -> String {
		let signing = IotaSigning(curl: curl.clone())
		let seedTrits = IotaConverter.trits(fromString: seed)
		let key = signing.key(inSeed: seedTrits, index: index, security: security)
		let digests = signing.digest(key: key)
		
		let addressTrits = signing.address(digests: digests)
		let address = IotaConverter.string(fromTrits: addressTrits)
		if checksum {
			return address+IotaChecksum.calculateChecksum(address: address)
		}
		return address
	}
	
	public static func isSeed(_ string: String) -> Bool {
		guard string.count > 1 && string.count <= 81 else { return false }
		for c in string {
			guard IotaConverter.trytesAlphabet.index(of: c) != nil else { return false }
		}
		return true
	}
	
	public static func groupTxsByBundle(_ txs: [IotaTransaction]) -> [[IotaTransaction]] {
		
		var result: [String: [IotaTransaction]] = [:]
		for tx in txs {
			if result[tx.bundle] == nil {
				result[tx.bundle] = [tx]
			}else{
				result[tx.bundle]!.append(tx)
			}
		}
		
		return Array(result.values)
	}
	public static func categorizeTransfers(addresses: [IotaAddress]) -> (sent: [[IotaTransaction]], received: [[IotaTransaction]]) {
		let txs = addresses.flatMap { $0.transactions! }
		let bundles = self.groupTxsByBundle(txs)
		return self.categorizeTransfers(bundles: bundles, addresses: addresses.map { $0.hash })
	}
	
	public static func categorizeTransfers(bundles: [[IotaTransaction]], addresses: [String]) -> (sent: [[IotaTransaction]], received: [[IotaTransaction]]){
		var sent: [[IotaTransaction]] = []
		var received: [[IotaTransaction]] = []
		
		for bundle in bundles {
			var spentAlreadyAdded = false
			
			for bundleEntry in bundle {
				guard addresses.index(of: bundleEntry.hash) != nil else { continue }
				
				let isRemainder = (bundleEntry.currentIndex == bundleEntry.lastIndex) && (bundleEntry.lastIndex != 0)
				if bundleEntry.value < 0 && !spentAlreadyAdded && !isRemainder {
					sent.append(bundle)
					spentAlreadyAdded = true
				}else if bundleEntry.value >= 0 && !spentAlreadyAdded && !isRemainder {
					received.append(bundle)
				}
			}
		}
		
		return (sent: sent, received: received)
	}
	
	public static func historyTransactions(addresses: [IotaAddress]) -> [IotaHistoryTransaction]{
		let tempTxs = addresses.flatMap { $0.transactions! }
		let bundles = self.groupTxsByBundle(tempTxs)
		var result: [[[IotaTransaction]]] = []

		for bundle in bundles {
			let txs = bundle.sorted { $0.attachmentTimestamp < $1.attachmentTimestamp }
			let first = txs.first!.currentIndex
			let numOfBundles = txs.reduce(0) { $1.currentIndex == first ? $0+1 : $0 }
			var tempResult: [[IotaTransaction]] = []
			let numberOfTxs = txs.count / numOfBundles
			for i in 0..<numOfBundles {
				let slice = txs.slice(from: i*numberOfTxs, to: i*numberOfTxs + numberOfTxs).sorted { $0.currentIndex < $1.currentIndex }
				tempResult.append(slice)
			}
			result.append(tempResult)
		}
		return result.map { valueFromBundle($0) }.sorted { $0.timestamp < $1.timestamp }
	}
	
	public static func checksumForSeed(_ seed: String) -> String {
		return String(IotaChecksum.calculateChecksum(address: seed).suffix(3))
	}
	
	
	
	
	internal static func valueFromBundle(_ bundleTxs: [[IotaTransaction]]) -> IotaHistoryTransaction{
		var tx = IotaHistoryTransaction()
		tx.transactions = bundleTxs
		for i in 0..<bundleTxs.count {
			let bundle = bundleTxs[i]
			for txs in bundle {
				if i == 0 {
					tx.value += txs.value
					tx.tag = txs.tag
					tx.bundle = txs.bundle
					tx.timestamp = txs.timestamp
					tx.persistence = txs.persistence
				}else{
					if tx.persistence == true { break }else{ tx.persistence = txs.persistence }
				}
			}
		}
		return tx
	}
	
	internal static func signInputs(seed: String, inputs: [IotaInput], bundle b: IotaBundle, signatureFragments: [String], curl: CurlSource) -> [String] {
		
		var bundle = b
		bundle.finalize(customCurl: curl)
		bundle.addTrytes(signatureFragments: signatureFragments)

		for i in 0..<bundle.transactions.count {
			if bundle.transactions[i].value >= 0 { continue }
			let thisAddress = bundle.transactions[i].address
			
			var keyIndex = 0
			var keySecurity = 0
			for input in inputs {
				if input.address == thisAddress {
					keyIndex = input.keyIndex
					keySecurity = input.security
				}
			}
			
			let bundleHash = bundle.transactions[i].bundle
			let signing = IotaSigning(curl: curl.clone())
			let key = signing.key(inSeed: IotaConverter.trits(fromString: seed), index: keyIndex, security: keySecurity)
			
			let firstFragment = key.slice(from: 0, to: 6561)
			
			let normalizedBundleHash = bundle.normalizedBundle(bundleHash: bundleHash)
			
			let firstBundleFragment = normalizedBundleHash.slice(from: 0, to: 27)
			
			let firstSignedFragment = signing.signatureFragment(normalizedBundleFragment: firstBundleFragment, keyFragment: firstFragment)
			
			bundle.transactions[i].signatureFragments = IotaConverter.trytes(trits: firstSignedFragment)
			
			for j in 1..<keySecurity {
				let tx = bundle.transactions[i+j]
				if tx.address == thisAddress && tx.value == 0 {
					let secondFragment = key.slice(from: 6561 * j, to: 6561 * (j + 1))
					let secondBundleFragment = normalizedBundleHash.slice(from: 27 * j, to: 27 * (j + 1))
					let secondSignedFragment = IotaSigning(curl: curl.clone()).signatureFragment(normalizedBundleFragment: secondBundleFragment, keyFragment: secondFragment)
					bundle.transactions[i+j].signatureFragments = IotaConverter.trytes(trits: secondSignedFragment)
				}
			}
		}
		
		var bundleTrytes: [String] = []
		
		for tx in bundle.transactions {
			bundleTrytes.append(tx.trytes)
		}
		
		bundleTrytes.reverse()
		return bundleTrytes
	}
}
