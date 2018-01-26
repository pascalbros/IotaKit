//
//  Models.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/18.
//

import Foundation

public struct IotaAccount {
	public internal(set) var balance: Int = 0
	public internal(set) var addresses: [IotaAddress] = []
	
	internal init() {}
}

public struct IotaHistoryTransaction {
	public internal(set) var value: Int = 0
	public internal(set) var address = ""
	public internal(set) var tag = ""
	public internal(set) var persistence: Bool = false
	public internal(set) var bundle: String = ""
	public internal(set) var timestamp: UInt = 0
	public internal(set) var transactions: [[IotaTransaction]] = []
}

public struct IotaTransaction {
	public internal(set) var value: Int = 0
	public internal(set) var address = ""
	public internal(set) var tag = ""
	public internal(set) var hash: String = ""
	public internal(set) var signatureFragments: String = ""
	public internal(set) var obsoleteTag: String = ""
	public internal(set) var timestamp: UInt = 0
	public internal(set) var currentIndex: UInt = 0
	public internal(set) var lastIndex: UInt = 0
	public internal(set) var bundle: String = ""
	public internal(set) var trunkTransaction: String = ""
	public internal(set) var branchTransaction: String = ""
	public internal(set) var nonce: String = ""
	public internal(set) var persistence: Bool = false
	public internal(set) var attachmentTimestamp: UInt = 0
	public internal(set) var attachmentTimestampLowerBound: UInt = 0
	public internal(set) var attachmentTimestampUpperBound: UInt = 0
	
	init(value: Int, address: String, tag: String, timestamp: UInt) {
		self.value = value
		self.address = address
		self.tag = tag
		self.obsoleteTag = tag
		self.timestamp = timestamp
	}
}

public struct IotaTransfer {
	public internal(set) var timestamp: String?
	public internal(set) var address: String
	public internal(set) var hash: String?
	public internal(set) var persistence: Bool
	public internal(set) var value: UInt
	public internal(set) var message: String
	public internal(set) var tag: String
	
	public init(address: String, value: UInt = 0, timestamp: String? = nil, hash: String? = nil, persistence: Bool = false, message: String = "", tag: String = "") {
		self.timestamp = timestamp
		self.address = address
		self.hash = hash
		self.persistence = persistence
		self.value = value
		self.message = message.rightPadded(count: 27, character: "9")
		self.tag = tag.rightPadded(count: 27, character: "9")
	}
}

public struct IotaBundle {
	internal static let emptyHash = "999999999999999999999999999999999999999999999999999999999999999999999999999999999"
	public internal(set) var transactions: [IotaTransaction] = []
	public internal(set) var length = 0
}

public struct IotaSignature {
	public internal(set) var address: String = ""
	public internal(set) var signatureFragments: [String] = []
}

public struct IotaInput {
	public internal(set) var address: String
	public internal(set) var balance: Int
	public internal(set) var keyIndex: Int
	public internal(set) var security: Int
}

public struct IotaAddress {
	public internal(set) var hash: String
	public internal(set) var transactions: [IotaTransaction]?
	public internal(set) var index: Int?
	public var balance: Int? {
		guard let txs = self.transactions else { return nil }
		return txs.reduce(0) { (r, t) -> Int in
			let v = t.persistence ? t.value : 0
			return r+v
		}
	}
	
	public var canSpend: Bool? {
		guard let txs = self.transactions else { return nil }
		for t in txs {
			if t.value < 0 { return false }
		}
		return true
	}
}

public struct IotaLog {
	public internal(set) var message: String = ""
}
