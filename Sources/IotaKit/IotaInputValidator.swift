//
//  IotaInputValidator.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 16/01/18.
//

import Foundation

/// Input validator for IOTA client.
public struct IotaInputValidator {
	
	/// Checks for a valid address.
	///
	/// - Parameter address: The address.
	/// - Returns: `true` if is a valid address, `false` otherwise.
	public static func isAddress(address: String) -> Bool {
		let isAddressWithChecksum = address.count == IotaConstants.addressLengthWithChecksum
		let isAddressWithoutChecksum = address.count == IotaConstants.addressLengthWithoutChecksum
		let isTrytes = self.isTrytes(trytes: address)
		return (isAddressWithChecksum || isAddressWithoutChecksum) && isTrytes
	}
	
	/// Checks for a valid seed.
	///
	/// - Parameter string: A seed.
	/// - Returns: `true` if is a valid seed, `false` otherwise.
	public static func isSeed(seed string: String) -> Bool {
		guard string.count > 1 && string.count <= 81 else { return false }
		for c in string {
			guard IotaConverter.trytesAlphabet.firstIndex(of: c) != nil else { return false }
		}
		return true
	}
	
	/// Checks for a valid trytes string.
	///
	/// - Parameter trytes: Trytes.
	/// - Returns: `true` if is a valid input, `false` otherwise.
	public static func isTrytes(trytes: String) -> Bool {
		for c in trytes {
			guard IotaConverter.trytesAlphabet.firstIndex(of: c) != nil else { return false }
		}
		return true
	}
	
	/// Checks for a valid hash.
	///
	/// - Parameter hash: An hash string.
	/// - Returns: `true` if is a valid hash, `false` otherwise.
	public static func isHash(hash: String) -> Bool {
		return isTrytes(trytes: hash) && hash.count == 81
	}
	
	/// Checks if is an empty trytes
	///
	/// - Parameter trytes: Trytes.
	/// - Returns: `true` if is a valid string, `false` otherwise.
	public static func isNinesTrytes(trytes: String) -> Bool {
		let value = "".rightPadded(count: trytes.count, character: "9")
		return value == trytes
	}
}
