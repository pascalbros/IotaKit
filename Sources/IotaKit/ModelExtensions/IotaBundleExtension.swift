//
//  IotaBundleExtension.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 15/01/2018.
//

import Foundation

public extension IotaBundle {
	
	public mutating func addEntry(signatureMessageLength: Int, address: String, value: Int, tag: String, timestamp: UInt64) {
		for i in 0..<signatureMessageLength {
			let trx = IotaTransaction(value: i == 0 ? value : 0, address: address, tag: tag)
			self.transactions.append(trx)
		}
	}
}
