//
//  IotaTransactionExtension.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 15/01/2018.
//

import Foundation

public extension IotaTransaction {
	
	//TODO
	mutating func transactionObject(trytes: String) {
		let transactionTrits = IotaConverter.trits(fromString: trytes)
		//var hash: [Int] = Array(repeating: 0, count: 243)
		//let kerl = Kerl()
		//_ = kerl.absorb(trits: transactionTrits)
		//_ = kerl.squeeze(trits: &hash, offset: 0, length: hash.count)
		self.address = trytes.substring(from: 2187, to: 2268)
		self.tag = trytes.substring(from: 2592, to: 2619)
		self.value = IotaConverter.longValue(transactionTrits.slice(from: 6804, to: 6837))
		self.signatureFragments = trytes.substring(from: 0, to: 2187)
		self.obsoleteTag = trytes.substring(from: 2295, to: 2322)
		self.timestamp = IotaConverter.longValue(transactionTrits.slice(from: 6966, to: 6993))
		self.currentIndex = IotaConverter.longValue(transactionTrits.slice(from: 6993, to: 7020))
		self.lastIndex = IotaConverter.longValue(transactionTrits.slice(from: 7020, to: 7047))
		self.bundle = trytes.substring(from: 2349, to: 2430)
		self.trunkTransaction = trytes.substring(from: 2430, to: 2511)
		self.branchTransaction = trytes.substring(from: 2511, to: 2592)
		self.attachmentTimestamp = IotaConverter.longValue(transactionTrits.slice(from: 7857, to: 7884))
		self.attachmentTimestampLowerBound = IotaConverter.longValue(transactionTrits.slice(from: 7884, to: 7911))
		self.attachmentTimestampUpperBound = IotaConverter.longValue(transactionTrits.slice(from: 7911, to: 7938))
		self.nonce = trytes.substring(from: 2646, to: 2673)
	}
	
	//TODO
	var trytes: String {
		let valueTrits = IotaConverter.trits(fromString: v)
		return ""
	}
}

