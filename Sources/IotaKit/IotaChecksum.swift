//
//  Checksum.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 08/01/18.
//

import Foundation

/// IOTA Checksum utils.
public struct IotaChecksum {
	
	/// Calculates the checksum for an address.
	///
	/// - Parameter address: The address.
	/// - Returns: The checksum.
	public static func calculateChecksum(address: String) -> String {
		let curl: CurlSource = CurlMode.kerl.create()
		_ = curl.absorb(trits: IotaConverter.trits(fromString: address))
		var checksumTrits: [Int] = Array(repeating: 0, count: Kerl.HASH_LENGTH)
		_ = curl.squeeze(trits: &checksumTrits)
		let checksum = IotaConverter.string(fromTrits: checksumTrits)
		
		let start = checksum.index(checksum.startIndex, offsetBy: 72)
		let end = checksum.index(checksum.startIndex, offsetBy: 81)
		
		return String(checksum[start..<end])
	}
	
	/// Removes the checksum from an address.
	///
	/// - Parameter address: A valid address with checksum.
	/// - Returns: The address without the checksum if is a valid address, `nil` otherwise.
	public static func removeChecksum(address: String) -> String? {
		if self.isAddressWithChecksum(address: address) {
			return self.removeChecksumFromAddress(address)
		}else if self.isAddressWithoutChecksum(address: address) {
			return address
		}
		return nil
	}
	
	/// Removes the checksum from an address. NB: The address will be not verified.
	///
	/// - Parameter address: A valid address.
	/// - Returns: The address without the checksum.
	public static func removeChecksumFromAddress(_ address: String) -> String {
		return address.substring(from: 0, to: IotaConstants.addressLengthWithoutChecksum)
	}
	
	/// Checks if an address contains a valid checksum.
	///
	/// - Parameter address: The address.
	/// - Returns: `true` if is a valid checksum, `false` otherwise.
	public static func isValidChecksum(address: String) -> Bool {
		guard let addressWithoutChecksum = self.removeChecksum(address: address) else { return false }
		let addressWithRecalculateChecksum = addressWithoutChecksum + self.calculateChecksum(address: addressWithoutChecksum)
		return addressWithRecalculateChecksum == address
	}
	
	/// Checks if is an address with checksum.
	///
	/// - Parameter address: The address.
	/// - Returns: `true` if is an address with checksum, `false` otherwise.
	public static func isAddressWithChecksum(address: String) -> Bool {
		return IotaInputValidator.isAddress(address:address) && address.count == IotaConstants.addressLengthWithChecksum
	}
	
	/// Checks if is an address without checksum.
	///
	/// - Parameter address: The address.
	/// - Returns: `true` if is an address without checksum, `false` otherwise.
	public static func isAddressWithoutChecksum(address: String) -> Bool {
		return IotaInputValidator.isAddress(address:address) && address.count == IotaConstants.addressLengthWithoutChecksum
	}
}
