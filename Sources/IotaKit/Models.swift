//
//  Models.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/18.
//

import Foundation

public struct IotaAccount {
	public internal(set) var balance: Int = 0
	public internal(set) var addresses: [String] = []
	
	public init() {
	}
}

public struct IotaTransaction {
	public internal(set) var value: Int = 0
	public internal(set) var address = ""
	public internal(set) var tag = ""
	
}

public struct IotaTransfer {
	public internal(set) var timestamp: String?
	public internal(set) var address: String
	public internal(set) var hash: String?
	public internal(set) var persistence: Bool
	public internal(set) var value: UInt
	public internal(set) var message: String
	public internal(set) var tag: String
	
	init(address: String, value: UInt = 0, timestamp: String? = nil, hash: String? = nil, persistence: Bool = false, message: String = "", tag: String = "") {
		self.timestamp = timestamp
		self.address = address
		self.hash = hash
		self.persistence = persistence
		self.value = value
		self.message = message
		self.tag = tag
	}
}

public struct IotaBundle {
	public static let emptyHash = "999999999999999999999999999999999999999999999999999999999999999999999999999999999"
	public internal(set) var transactions: [IotaTransaction] = []
	public internal(set) var length = 0
}
