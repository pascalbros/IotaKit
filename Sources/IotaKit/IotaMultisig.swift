//
//  IotaMultisig.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 07/03/18.
//

import Foundation

public class IotaMultisig {
	fileprivate let curl: CurlSource = CurlMode.kerl.create()
	fileprivate var signing: IotaSigning
	public init() {
		 self.signing = IotaSigning(curl: curl.clone())
	}
	
	public func digest(seed: String, security: Int, index: Int) -> String {
		let key = self.signing.key(inSeed: IotaConverter.trits(trytes: seed, length: 243), index: index, security: security)
		return IotaConverter.trytes(trits: self.signing.digest(key: key))
	}
	
	public func address(fromDigests digests: [String]) -> String {
		self.curl.reset()
		for d in digests {
			let digestTrits = IotaConverter.trits(fromString: d)
			_ = self.curl.absorb(trits: digestTrits)
		}
		
		var addressTrits: [Int] = Array(repeating: 0, count: Curl.hashLength)
		_ = self.curl.squeeze(trits: &addressTrits, offset: 0, length: Curl.hashLength)
		return IotaConverter.trytes(trits: addressTrits)
	}
	
	public func validate(address: String, digests: [String]) -> Bool {
		let digestsTrits = digests.map { IotaConverter.trits(fromString: $0) }
		return self.validate(address: address, digests: digestsTrits)
	}
	
	public func validate(address: String, digests: [[Int]]) -> Bool {
		self.curl.reset()
		
		for keyDigest in digests {
			_ = self.curl.absorb(trits: keyDigest)
		}
		
		var addressTrits: [Int] = Array(repeating: 0, count: 243)
		_ = self.curl.squeeze(trits: &addressTrits)
		
		return IotaConverter.trytes(trits: addressTrits) == address
	}
	
	public func addSignature( bundle: inout IotaBundle, inputAddress: String, keyTrytes: String) {
		let security = keyTrytes.count / IotaConstants.messageLength
		let key = IotaConverter.trits(fromString: keyTrytes)
		
		var numSignedTxs = 0
		
		for i in 0..<bundle.transactions.count {
			guard bundle.transactions[i].address == inputAddress else { continue }
			guard !IotaInputValidator.isNinesTrytes(trytes: bundle.transactions[i].signatureFragments) else { numSignedTxs += 1; continue }
			let bundleHash = bundle.transactions[i].bundle
			
			let firstFragment = key.slice(from: 0, to: 6561)
			
			var normalizedBundleFragments: [[Int]] = Array(repeating: [0, 0, 0], count: 27)
			let normalizedBundleHash = bundle.normalizedBundle(bundleHash: bundleHash)
			
			for k in 0..<3 {
				normalizedBundleFragments[k] = normalizedBundleHash.slice(from: k*27, to: (k+1)*27)
			}
			
			let firstBundleFragment = normalizedBundleFragments[numSignedTxs % 3]
			
			let firstSignedFragment = self.signing.signatureFragment(normalizedBundleFragment: firstBundleFragment, keyFragment: firstFragment)
			
			bundle.transactions[i].signatureFragments = IotaConverter.trytes(trits: firstSignedFragment)
			
			for j in 1..<security {
				let nextFragment = key.slice(from: 6561*j, to: (j+1)*6561)
				let nextBundleFragment = normalizedBundleFragments[(numSignedTxs+j) % 3]
				let nextSignedFragment = self.signing.signatureFragment(normalizedBundleFragment: nextBundleFragment, keyFragment: nextFragment)
				
				bundle.transactions[i+j].signatureFragments = IotaConverter.trytes(trits: nextSignedFragment)
			}
			break
		}
	}
}
