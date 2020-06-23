//
//  IotaAPIUtils.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 08/01/18.
//

import Foundation

/// Utils class for Iota
public struct IotaAPIUtils {

	/// Generates a new address from a seed and a given index.
	///
	/// - Parameters:
	///   - seed: The seed.
	///   - index: An Index (0...∞).
	///   - checksum: Determines if the checksum should be included or not.
	///   - security: The security level, default 2.
	///   - multithreaded: If true, the work will be split to multiple threads.
	/// - Returns: The generated address.
	public static func newAddress(seed: String, index: Int, checksum: Bool, security: Int = 2, multithreaded: Bool = false) -> String {
		let curl = CurlMode.kerl.create()
		return self.newAddress(seed: seed, security: security, index: index, checksum: checksum, multithreaded: multithreaded, curl: curl)
	}

	static func newAddress(seed: String, security: Int, index: Int, checksum: Bool, multithreaded: Bool = false, curl: CurlSource) -> String {
		let signing = IotaSigning(curl: curl.clone())
		let seedTrits = IotaConverter.trits(fromString: seed)
		let key = signing.key(inSeed: seedTrits, index: index, security: security)
		let digests = signing.digest(key: key, multithreaded: multithreaded)
		let addressTrits = signing.address(digests: digests)
		let address = IotaConverter.string(fromTrits: addressTrits)
		if checksum {
			return address+IotaChecksum.calculateChecksum(address: address)
		}
		return address
	}

	/// Groups a list of transactions by bundle.
	///
	/// - Parameter txs: The transactions list.
	/// - Returns: A list of grouped transactions.
	public static func groupTxsByBundle(_ txs: [IotaTransaction]) -> [[IotaTransaction]] {
		let result: [String: [IotaTransaction]] = txs.reduce(into: [String: [IotaTransaction]]()) { $0[$1.bundle, default: []].append($1) }
		return Array(result.values)
	}

	/// Categorizes the transfers into sent and received.
	///
	/// - Parameter addresses: The addresses list.
	/// - Returns: Sent and received transactions.
	public static func categorizeTransfers(addresses: [IotaAddress]) -> (sent: [[IotaTransaction]], received: [[IotaTransaction]]) {
		let txs = addresses.flatMap { $0.transactions! }
		let bundles = self.groupTxsByBundle(txs)
		return self.categorizeTransfers(bundles: bundles, addresses: addresses.map { $0.hash })
	}

	/// Categorizes the transfers into sent and received.
	///
	/// - Parameters:
	///   - bundles: The bundles to categorize.
	///   - addresses: Addresses that belong to the user.
	/// - Returns: Sent and received transactions.
	public static func categorizeTransfers(
		bundles: [[IotaTransaction]],
		addresses: [String]) -> (sent: [[IotaTransaction]], received: [[IotaTransaction]]) {
		var sent: [[IotaTransaction]] = []
		var received: [[IotaTransaction]] = []
		
		for bundle in bundles {
			var spentAlreadyAdded = false
		
			for bundleEntry in bundle {
				guard addresses.firstIndex(of: bundleEntry.hash) != nil else { continue }
			
				let isRemainder = (bundleEntry.currentIndex == bundleEntry.lastIndex) && (bundleEntry.lastIndex != 0)
				if bundleEntry.value < 0 && !spentAlreadyAdded && !isRemainder {
					sent.append(bundle)
					spentAlreadyAdded = true
				} else if bundleEntry.value >= 0 && !spentAlreadyAdded && !isRemainder {
					received.append(bundle)
				}
			}
		}
		return (sent: sent, received: received)
	}

	/// Creates a transactions history from the addresses.
	///
	/// - Parameter addresses: The addresses list.
	/// - Returns: Transactions list.
	public static func historyTransactions(addresses: [IotaAddress]) -> [IotaHistoryTransaction] {
		let tempTxs = addresses.flatMap { $0.transactions ?? [] }
		let bundles = self.groupTxsByBundle(tempTxs)
		var result: [[[IotaTransaction]]] = []

		for bundle in bundles {
			let txs = bundle.sorted { $0.attachmentTimestamp < $1.attachmentTimestamp }
			let first = txs.first!.currentIndex
			let numOfBundles = txs.reduce(0) { $1.currentIndex == first ? $0+1 : $0 }
			var tempResult: [[IotaTransaction]] = []
			let numberOfTxs = txs.count / numOfBundles
			for index in 0..<numOfBundles {
				let slice = txs.slice(from: index*numberOfTxs, to: index*numberOfTxs + numberOfTxs).sorted { $0.currentIndex < $1.currentIndex }
				tempResult.append(slice)
			}
			result.append(tempResult)
		}
		return result.map { valueFromBundle($0) }.sorted { $0.timestamp < $1.timestamp }
	}

	/// Calculates the checksum for a seed.
	///
	/// - Parameter seed: The seed.
	/// - Returns: The checksum
	public static func checksumForSeed(_ seed: String) -> String {
		return String(IotaChecksum.calculateChecksum(address: seed).suffix(3))
	}

	internal static func valueFromBundle(_ bundleTxs: [[IotaTransaction]]) -> IotaHistoryTransaction {
		var transaction = IotaHistoryTransaction()
		transaction.transactions = bundleTxs
		for index in 0..<bundleTxs.count {
			let bundle = bundleTxs[index]
			for txs in bundle {
				if index == 0 {
					transaction.value += txs.value
					transaction.tag = txs.tag
					transaction.bundle = txs.bundle
					transaction.timestamp = txs.timestamp
					transaction.persistence = txs.persistence
				} else {
					guard !transaction.persistence else { break }
					transaction.persistence = txs.persistence
				}
			}
		}
		return transaction
	}

	internal static func signInputs(seed: String, inputs: [IotaInput], bundle: IotaBundle, signatureFragments: [String], curl: CurlSource) -> [String] {
		var bundle = bundle
		bundle.finalize(customCurl: curl)
		bundle.addTrytes(signatureFragments: signatureFragments)

		for index in 0..<bundle.transactions.count {
			if bundle.transactions[index].value >= 0 { continue }
			let thisAddress = bundle.transactions[index].address
			var keyIndex = 0
			var keySecurity = 0
			for input in inputs {
				guard input.address == thisAddress else { continue }
				keyIndex = input.keyIndex
				keySecurity = input.security
			}
			let bundleHash = bundle.transactions[index].bundle
			let signing = IotaSigning(curl: curl.clone())
			let key = signing.key(inSeed: IotaConverter.trits(fromString: seed), index: keyIndex, security: keySecurity)
			let firstFragment = key.slice(from: 0, to: 6561)
			let normalizedBundleHash = bundle.normalizedBundle(bundleHash: bundleHash)
			let firstBundleFragment = normalizedBundleHash.slice(from: 0, to: 27)
			let firstSignedFragment = signing.signatureFragment(normalizedBundleFragment: firstBundleFragment, keyFragment: firstFragment)
			bundle.transactions[index].signatureFragments = IotaConverter.trytes(trits: firstSignedFragment)
			for jIndex in 1..<keySecurity {
				let transaction = bundle.transactions[index+jIndex]
				if transaction.address == thisAddress && transaction.value == 0 {
					let secondFragment = key.slice(from: 6561 * jIndex, to: 6561 * (jIndex + 1))
					let secondBundleFragment = normalizedBundleHash.slice(from: 27 * jIndex, to: 27 * (jIndex + 1))
					let secondSignedFragment = IotaSigning(curl: curl.clone())
						.signatureFragment(normalizedBundleFragment: secondBundleFragment, keyFragment: secondFragment)
					bundle.transactions[index+jIndex].signatureFragments = IotaConverter.trytes(trits: secondSignedFragment)
				}
			}
		}
		var bundleTrytes: [String] = []
		for transaction in bundle.transactions {
			bundleTrytes.append(transaction.trytes)
		}
		bundleTrytes.reverse()
		return bundleTrytes
	}

	internal static func mergeAddressesAndTransactions(addresses: [IotaAddress], txs: [IotaTransaction]) -> [IotaAddress] {

		var addressesDict: [String: IotaAddress] = [:]
		for address in addresses { addressesDict[address.hash] = address }

		for transaction in txs {
			let key = transaction.address
			if addressesDict[key] != nil {
				if addressesDict[key]?.transactions != nil {
					addressesDict[key]!.transactions!.append(transaction)
				} else {
					addressesDict[key]!.transactions = [transaction]
				}
			}
		}

		var result = addresses.map { $0 }
		for index in 0..<result.count {
			let key = result[index].hash
			result[index].transactions = addressesDict[key]!.transactions
		}
		return result
	}
}
