//
//  IotaBundleExtension.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 15/01/2018.
//

import Foundation

public extension IotaBundle {
	
	public mutating func addEntry(signatureMessageLength: Int, address: String, value: Int, tag: String, timestamp: UInt) {
		for i in 0..<signatureMessageLength {

			let trx = IotaTransaction(value: i == 0 ? value : 0, address: address, tag: tag, timestamp: timestamp)
			self.transactions.append(trx)
		}
	}
	
	internal mutating func finalize(customCurl: CurlSource!) {
		//var normalizedBundleValue: [Int]
		var hash: [Int] = Array(repeating: 0, count: 243)
		var obsoleteTagTrits: [Int] = Array(repeating: 0, count: 81)
		var valid = true
		let curl = customCurl == nil ? CurlMode.kerl.create() : customCurl!
		var hashInTrytes: String = ""
		repeat {
			curl.reset()
			for i in 0..<self.transactions.count {
				var t = self.transactions[i]
				let valueTrits = IotaConverter.trits(trytes: Int(t.value), length: 81)
				let timestampTrits = IotaConverter.trits(trytes: Int(t.timestamp), length: 27)
				t.currentIndex = UInt(i)
				let currentIndexTrits = IotaConverter.trits(trytes: Int(t.currentIndex), length: 27)
				t.lastIndex = UInt(i)
				let lastIndexTrits = IotaConverter.trits(trytes: Int(t.lastIndex), length: 27)
				var tt = t.address
				tt += IotaConverter.trytes(trits: valueTrits)
				tt += t.obsoleteTag
				tt += IotaConverter.trytes(trits: timestampTrits)
				tt += IotaConverter.trytes(trits: currentIndexTrits)
				tt += IotaConverter.trytes(trits: lastIndexTrits)
				let ttTrits = IotaConverter.trits(fromString: tt)
				_ = curl.absorb(trits: ttTrits)
			}
			
			_ = curl.squeeze(trits: &hash)
			hashInTrytes = IotaConverter.trytes(trits: hash)
			let normalizedBundleValue = self.normalizedBundle(bundleHash: hashInTrytes)
			var foundValue = false
			for aNormalizedBundleValue in normalizedBundleValue {
				if aNormalizedBundleValue == 13 {
					foundValue = true
					obsoleteTagTrits = IotaConverter.trits(fromString: self.transactions[0].obsoleteTag)
					IotaConverter.increment(trits: &obsoleteTagTrits, size: 81)
					self.transactions[0].obsoleteTag = IotaConverter.trytes(trits: obsoleteTagTrits)
				}
			}
			valid = !foundValue
		} while !valid
		
		for i in 0..<self.transactions.count {
			self.transactions[i].bundle = hashInTrytes
		}
	}
	
	internal mutating func addTrytes(signatureFragments: [String]) {
		var emptySignatureFragment = ""
		let emptyHash = IotaBundle.emptyHash
		let emptyTimestamp: UInt = 999999999
		
		emptySignatureFragment.rightPad(count: 2187, character: "9")
		
		for i in 0..<self.transactions.count {
			self.transactions[i].signatureFragments = (signatureFragments.count <= i || signatureFragments[i].isEmpty) ? emptySignatureFragment : signatureFragments[i]
			self.transactions[i].trunkTransaction = emptyHash
			self.transactions[i].branchTransaction = emptyHash
			
			self.transactions[i].attachmentTimestamp = emptyTimestamp
			self.transactions[i].attachmentTimestampLowerBound = emptyTimestamp
			self.transactions[i].attachmentTimestampUpperBound = emptyTimestamp
			
			var nonce = ""
			nonce.rightPad(count: 27, character: "9")
			self.transactions[i].nonce = nonce
		}
	}
	
	internal func normalizedBundle(bundleHash: String) -> [Int] {
		var normalizedBundle: [Int] = Array(repeating: 0, count: 81)
		
		for i in 0..<3 {
			var sum: Int = 0
			for j in 0..<27 {
				let char = bundleHash.substring(from: i*27 + j, to: i*27 + j + 1)
				normalizedBundle[i*27 + j] = IotaConverter.longValue(IotaConverter.trits(fromString: char))
				sum += normalizedBundle[i*27 + j]
			}
			
			if sum >= 0 {
				while sum > 0 {
					for j in 0..<27 {
						if normalizedBundle[i*27+j] > -13 {
							normalizedBundle[i*27+j] -= 1
							break
						}
					}
					sum -= 1
				}
			}else {
				while sum < 0 {
					for j in 0..<27 {
						if normalizedBundle[i*27+j] < 13 {
							normalizedBundle[i*27+j] += 1
							break
						}
					}
					sum += 1
				}
			}
		}
		return normalizedBundle
	}
}
