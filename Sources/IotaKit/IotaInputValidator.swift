//
//  IotaInputValidator.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 16/01/18.
//

import Foundation

struct IotaInputValidator {
	
	static func isAddress(address: String) -> Bool {
		let isAddressWithChecksum = address.count == IotaConstants.addressLengthWithChecksum
		let isAddressWithoutChecksum = address.count == IotaConstants.addressLengthWithoutChecksum
		let isTrytes = self.isTrytes(trytes: address)
		return (isAddressWithChecksum || isAddressWithoutChecksum) && isTrytes
	}
	
	static func isTrytes(trytes: String) -> Bool {
		for c in trytes {
			guard IotaConverter.trytesAlphabet.index(of: c) != nil else { return false }
		}
		return true
	}
	
	static func isHash(hash: String) -> Bool {
		return isTrytes(trytes: hash) && hash.count == 81
	}
	
	static func isNinesTrytes(trytes: String) -> Bool {
		let value = "".rightPadded(count: trytes.count, character: "9")
		return value == trytes
	}
}
