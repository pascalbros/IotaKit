//
//  IotaTransactionExtension.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 15/01/2018.
//

import Foundation

public extension IotaTransaction {

	/// Constructor for IotaTransaction.
	///
	/// - Parameter trytes: The Trytes.
	init(trytes: String) {
		self.transactionObject(trytes: trytes)
	}

	/// Converts a valid Trytes to a IotaTransaction object.
	///
	/// - Parameter trytes: The Trytes.
	mutating func transactionObject(trytes: String) {
		let transactionTrits = IotaConverter.trits(fromString: trytes)
		var hash: [Int] = Array(repeating: 0, count: Curl.hashLength)
		let curl = CurlMode.curlP81.create()
		curl.reset()
		_ = curl.absorb(trits: transactionTrits)
		_ = curl.squeeze(trits: &hash, offset: 0, length: hash.count)

        self.hash = IotaConverter.trytes(trits: hash)
		self.address = trytes.substring(from: 2187, to: 2268)
		self.tag = trytes.substring(from: 2592, to: 2619)
		self.value = IotaConverter.longValue(transactionTrits.slice(from: 6804, to: 6837))
		self.signatureFragments = trytes.substring(from: 0, to: 2187)
		self.obsoleteTag = trytes.substring(from: 2295, to: 2322)
		self.timestamp = UInt64(IotaConverter.longValue(transactionTrits.slice(from: 6966, to: 6993)))
		self.currentIndex = UInt(IotaConverter.longValue(transactionTrits.slice(from: 6993, to: 7020)))
		self.lastIndex = UInt(IotaConverter.longValue(transactionTrits.slice(from: 7020, to: 7047)))
		self.bundle = trytes.substring(from: 2349, to: 2430)
		self.trunkTransaction = trytes.substring(from: 2430, to: 2511)
		self.branchTransaction = trytes.substring(from: 2511, to: 2592)
		self.attachmentTimestamp = UInt64(IotaConverter.longValue(transactionTrits.slice(from: 7857, to: 7884)))
		self.attachmentTimestampLowerBound = UInt64(IotaConverter.longValue(transactionTrits.slice(from: 7884, to: 7911)))
		self.attachmentTimestampUpperBound = UInt64(IotaConverter.longValue(transactionTrits.slice(from: 7911, to: 7938)))
		self.nonce = trytes.substring(from: 2646, to: 2673)
	}
	/// Returns a String of Trytes from the current state.
	var trytes: String {
		let valueTrits = IotaConverter.trits(trytes: Int(self.value), length: 81)
		let timestampTrits = IotaConverter.trits(trytes: Int(self.timestamp), length: 27)
		let currentIndexTrits = IotaConverter.trits(trytes: Int(self.currentIndex), length: 27)
		let lastIndexTrits = IotaConverter.trits(trytes: Int(self.lastIndex), length: 27)
		let attachmentTimestampTrits = IotaConverter.trits(trytes: Int(self.attachmentTimestamp), length: 27)
		let attachmentTimestampLowerTrits = IotaConverter.trits(trytes: Int(self.attachmentTimestampLowerBound), length: 27)
		let attachmentTimestampUpperTrits = IotaConverter.trits(trytes: Int(self.attachmentTimestampUpperBound), length: 27)
		let newTag = !self.tag.isEmpty ? self.tag : self.obsoleteTag
		var result = ""
		result += self.signatureFragments
		result += self.address
		result += IotaConverter.trytes(trits: valueTrits)
		result += self.obsoleteTag
		result += IotaConverter.trytes(trits: timestampTrits)
		result += IotaConverter.trytes(trits: currentIndexTrits)
		result += IotaConverter.trytes(trits: lastIndexTrits)
		result += self.bundle
		result += self.trunkTransaction
		result += self.branchTransaction
		result += newTag
		result += IotaConverter.trytes(trits: attachmentTimestampTrits)
		result += IotaConverter.trytes(trits: attachmentTimestampLowerTrits)
		result += IotaConverter.trytes(trits: attachmentTimestampUpperTrits)
		result += self.nonce

		return result
	}
}

extension IotaTransaction: Equatable {

	/// Implements the Equatable protocol for `IotaTransaction`.
	///
	/// - Parameters:
	///   - lhs: A IotaTransaction.
	///   - rhs: Another IotaTransaction.
	/// - Returns: `true` if the two objects contain the same data, `false` otherwise.
	public static func == (lhs: IotaTransaction, rhs: IotaTransaction) -> Bool {
		if lhs.hash != rhs.hash
		|| lhs.address != rhs.address
		|| lhs.tag != rhs.tag
		|| lhs.value != rhs.value
		|| lhs.signatureFragments != rhs.signatureFragments
		|| lhs.obsoleteTag != rhs.obsoleteTag
		|| lhs.timestamp != rhs.timestamp
		|| lhs.currentIndex != rhs.currentIndex
		|| lhs.lastIndex != rhs.lastIndex
		|| lhs.bundle != rhs.bundle
		|| lhs.trunkTransaction != rhs.trunkTransaction
		|| lhs.branchTransaction != rhs.branchTransaction
		|| lhs.attachmentTimestamp != rhs.attachmentTimestamp
		|| lhs.attachmentTimestampLowerBound != rhs.attachmentTimestampLowerBound
		|| lhs.attachmentTimestampUpperBound != rhs.attachmentTimestampUpperBound
		|| lhs.nonce != rhs.nonce { return false }
		return true
	}
}
