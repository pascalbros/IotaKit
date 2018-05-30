//
//  Models.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/18.
//

import Foundation

/// Iota account, used to return all the info for an account like the balance or addresses
public struct IotaAccount {
	
	/// The current balance
	public internal(set) var balance: Int64 = 0
	
	/// The addresses associated to the account
	public internal(set) var addresses: [IotaAddress] = []
	
	internal init() {}
}

/// Represents a Iota Bundle and all the reattaches, used to group all the txs in a single object.
public struct IotaHistoryTransaction {
	
	/// The value of the bundle.
	public internal(set) var value: Int64 = 0
	
	/// The address.
	public internal(set) var address = ""
	
	/// The tag.
	public internal(set) var tag = ""
	
	/// The persistence of the bundle.
	public internal(set) var persistence: Bool = false
	
	/// The bundle hash.
	public internal(set) var bundle: String = ""
	
	/// The timestamp.
	public internal(set) var timestamp: UInt64 = 0
	
	/// List of transactions list, each array represent a reattach.
	public internal(set) var transactions: [[IotaTransaction]] = []
}

/// Represents a Iota Transaction.
public struct IotaTransaction {
	
	/// The value.
	public internal(set) var value: Int64 = 0
	
	/// The address.
	public internal(set) var address = ""
	
	/// The tag.
	public internal(set) var tag = ""
	
	/// The hash.
	public internal(set) var hash: String = ""
	
	/// The signature fragments.
	public internal(set) var signatureFragments: String = ""
	
	/// The obsolete tag.
	public internal(set) var obsoleteTag: String = ""
	
	/// The timestamp.
	public internal(set) var timestamp: UInt64 = 0
	
	/// The current index in the bundle.
	public internal(set) var currentIndex: UInt = 0
	
	/// The last index of the bundle.
	public internal(set) var lastIndex: UInt = 0
	
	/// The bundle hash.
	public internal(set) var bundle: String = ""
	
	/// The trunk transaction hash.
	public internal(set) var trunkTransaction: String = ""
	
	/// The branch transaction hash.
	public internal(set) var branchTransaction: String = ""
	
	/// The nonce found from the PoW.
	public internal(set) var nonce: String = ""
	
	/// The persistence of the bundle.
	public internal(set) var persistence: Bool = false
	
	/// The attachment timestamp.
	public internal(set) var attachmentTimestamp: UInt64 = 0
	
	/// The lower bound of the attachment timestamp.
	public internal(set) var attachmentTimestampLowerBound: UInt64 = 0
	
	/// The upper bound of the attachment timestamp.
	public internal(set) var attachmentTimestampUpperBound: UInt64 = 0
	
	internal init(value: Int64, address: String, tag: String, timestamp: UInt64) {
		self.value = value
		self.address = address
		self.tag = tag
		self.obsoleteTag = tag
		self.timestamp = timestamp
	}
}

/// Represents a Iota Transfer.
public struct IotaTransfer {
	
	/// The timestamp (only if stored in the tangle).
	public internal(set) var timestamp: String?
	
	/// The address.
	public internal(set) var address: String
	
	/// The hash (only if stored in the tangle).
	public internal(set) var hash: String?
	
	/// The persistence of the transfer.
	public internal(set) var persistence: Bool
	
	/// The value carried by the transfer.
	public internal(set) var value: UInt64
	
	/// The message.
	public internal(set) var message: String
	
	/// The tag.
	public internal(set) var tag: String
	
	/// Initializer of IotaTransfer.
	///
	/// - Parameters:
	///   - address: The address.
	///   - value: The value.
	///   - timestamp: The timestamp.
	///   - hash: The hash.
	///   - persistence: The persistence state.
	///   - message: The message.
	///   - tag: The tag.
	public init(address: String, value: UInt64 = 0, timestamp: String? = nil, hash: String? = nil, persistence: Bool = false, message: String = "", tag: String = "") {
		self.timestamp = timestamp
		self.address = address
		self.hash = hash
		self.persistence = persistence
		self.value = value
		self.message = message.rightPadded(count: IotaConstants.messageLength, character: "9")
		self.tag = tag.rightPadded(count: 27, character: "9")
	}
}

/// Represents a Iota Bundle.
public struct IotaBundle {
	internal static let emptyHash = "999999999999999999999999999999999999999999999999999999999999999999999999999999999"
	
	/// List of transactions contained in the bundle.
	public internal(set) var transactions: [IotaTransaction] = []
	
	/// The total number of transactions contained in the bundle.
	public internal(set) var length = 0
}

/// Represents a Iota Signature.
public struct IotaSignature {
	
	/// The address where the signature comes from.
	public internal(set) var address: String = ""
	
	/// The signature fragments list.
	public internal(set) var signatureFragments: [String] = []
}

/// Represents a Iota Input.
public struct IotaInput {
	
	/// The address.
	public internal(set) var address: String
	
	/// The balance.
	public internal(set) var balance: Int64
	
	/// The key index.
	public internal(set) var keyIndex: Int
	
	/// The security level.
	public internal(set) var security: Int
}

/// Represents a Iota Address.
public struct IotaAddress {
	
	/// The hash.
	public internal(set) var hash: String
	
	/// The list of transactions, can be `nil`.
	public internal(set) var transactions: [IotaTransaction]?
	
	/// The index of the address (starting from 0), can be `nil`.
	public internal(set) var index: Int?
	
	private var _balance: Int64? = nil
	
	/// The current balance of the address, if `nil`, it can be derived from the list of transactions. In that case there is no guarantee that the value is updated.
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
	
	/// Determines if an addres can be spent or not.
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

/// Used to carry a log message.
public struct IotaLog {
	public internal(set) var message: String = ""
}
