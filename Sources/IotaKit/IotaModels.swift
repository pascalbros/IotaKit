//
//  Models.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/18.
//

import Foundation

public struct IotaAccount {
	public internal(set) var balance: Int64 = 0
	public internal(set) var addresses: [IotaAddress] = []
	
	internal init() {}
}

public struct IotaHistoryTransaction {
	public internal(set) var value: Int64 = 0
	public internal(set) var address = ""
	public internal(set) var tag = ""
	public internal(set) var persistence: Bool = false
	public internal(set) var bundle: String = ""
	public internal(set) var timestamp: UInt64 = 0
	public internal(set) var transactions: [[IotaTransaction]] = []
}

public struct IotaTransaction {
	public internal(set) var value: Int64 = 0
	public internal(set) var address = ""
	public internal(set) var tag = ""
	public internal(set) var hash: String = ""
	public internal(set) var signatureFragments: String = ""
	public internal(set) var obsoleteTag: String = ""
	public internal(set) var timestamp: UInt64 = 0
	public internal(set) var currentIndex: UInt = 0
	public internal(set) var lastIndex: UInt = 0
	public internal(set) var bundle: String = ""
	public internal(set) var trunkTransaction: String = ""
	public internal(set) var branchTransaction: String = ""
	public internal(set) var nonce: String = ""
	public internal(set) var persistence: Bool = false
	public internal(set) var attachmentTimestamp: UInt64 = 0
	public internal(set) var attachmentTimestampLowerBound: UInt64 = 0
	public internal(set) var attachmentTimestampUpperBound: UInt64 = 0
	
	init(value: Int64, address: String, tag: String, timestamp: UInt64) {
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
	public internal(set) var value: UInt64
	public internal(set) var message: String
	public internal(set) var tag: String
	
	public init(address: String, value: UInt64 = 0, timestamp: String? = nil, hash: String? = nil, persistence: Bool = false, message: String = "", tag: String = "") {
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
	public internal(set) var balance: Int64
	public internal(set) var keyIndex: Int
	public internal(set) var security: Int
}

public struct IotaAddress {
	public internal(set) var hash: String
	public internal(set) var transactions: [IotaTransaction]?
	public internal(set) var index: Int?
	
	private var _balance: Int64? = nil
	public var balance: Int64? {
		get {
			guard let b = _balance else { return calculatedBalance }
			return b
		}
		set(newValue) {
			self._balance = newValue
		}
	}
	
	private var _canSpend: Bool? = nil
	public var canSpend: Bool? {
		get {
			guard let c = _canSpend else { return calculateCanSpend }
			return c
		}
		set(newValue) {
			self._canSpend = newValue
		}
	}
	
	init(hash: String, transactions: [IotaTransaction]?, index: Int?, balance: Int64?) {
		self.hash = hash
		self.transactions = transactions
		self.index = index
		self.balance = balance
	}
	
	private var calculatedBalance: Int64? {
		guard let txs = self.transactions else { return nil }
		return txs.reduce(0) { (r, t) -> Int64 in
			let v = t.persistence ? t.value : 0
			return r+v
		}
	}
	
	private var calculateCanSpend: Bool? {
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
