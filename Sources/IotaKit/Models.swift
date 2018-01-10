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
	
}
