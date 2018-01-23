//
//  IotaAPIUtils.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 08/01/18.
//

import Foundation

public struct IotaAPIUtils {
	
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
