//
//  IotaInputValidator.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 16/01/18.
//

import Foundation

public struct IotaInputValidator {
	
	public static func isAddress(address: String) -> Bool {
		let isAddressWithChecksum = address.count == IotaConstants.addressLengthWithChecksum
		let isAddressWithoutChecksum = address.count == IotaConstants.addressLengthWithoutChecksum
		let isTrytes = self.isTrytes(trytes: address)
		return (isAddressWithChecksum || isAddressWithoutChecksum) && isTrytes
	}
	
	public static func isSeed(_ string: String) -> Bool {
		guard string.count > 1 && string.count <= 81 else { return false }
		for c in string {
			guard IotaConverter.trytesAlphabet.index(of: c) != nil else { return false }
		}
		return true
	}
	
	public static func isTrytes(trytes: String) -> Bool {
		for c in trytes {
			guard IotaConverter.trytesAlphabet.index(of: c) != nil else { return false }
		}
		return true
	}
	
	public static func isHash(hash: String) -> Bool {
		return isTrytes(trytes: hash) && hash.count == 81
	}
	
	public static func isNinesTrytes(trytes: String) -> Bool {
		let value = "".rightPadded(count: trytes.count, character: "9")
		return value == trytes
	}
}
