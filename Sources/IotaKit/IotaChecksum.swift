//
//  Checksum.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 08/01/18.
//

import Foundation

struct IotaChecksum {
	
	static func calculateChecksum(address: String) -> String {
		let kerl = CurlMode.kerl.create()
		_ = kerl.absorb(trits: IotaConverter.trits(fromString: address))
		var checksumTrits: [Int] = Array(repeating: 0, count: Kerl.HASH_LENGTH)
		_ = kerl.squeeze(trits: &checksumTrits)
		let checksum = IotaConverter.string(fromTrits: checksumTrits)
		
		let start = checksum.index(checksum.startIndex, offsetBy: 72)
		let end = checksum.index(checksum.startIndex, offsetBy: 81)
		
		return String(checksum[start..<end])
	}
	
	static func removeChecksum(address: String) -> String? {
		if self.isAddressWithChecksum(address: address) {
			return self.removeChecksumFromAddress(address)
		}else if self.isAddressWithoutChecksum(address: address) {
			return address
		}
		return nil
	}
	
	static func removeChecksumFromAddress(_ address: String) -> String {
		return address.substring(from: 0, to: IotaConstants.addressLengthWithoutChecksum)
	}
	
	static func isValidChecksum(address: String) -> Bool {
		guard let addressWithoutChecksum = self.removeChecksum(address: address) else { return false }
		let addressWithRecalculateChecksum = addressWithoutChecksum + self.calculateChecksum(address: addressWithoutChecksum)
		return addressWithRecalculateChecksum == address
	}
	
	static func isAddressWithChecksum(address: String) -> Bool {
		return IotaInputValidator.isAddress(address:address) && address.count == IotaConstants.addressLengthWithChecksum
	}
	
	static func isAddressWithoutChecksum(address: String) -> Bool {
		return IotaInputValidator.isAddress(address:address) && address.count == IotaConstants.addressLengthWithoutChecksum
	}
}
