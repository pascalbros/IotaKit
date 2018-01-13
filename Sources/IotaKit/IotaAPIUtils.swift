//
//  IotaAPIUtils.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 08/01/18.
//

import Foundation

public struct IotaAPIUtils {
	
	public static func newAddress(seed: String, security: Int, index: Int, checksum: Bool) -> String {
		let seedTrits = IotaConverter.trits(fromString: seed)
		let key = Signing.key(inSeed: seedTrits, index: index, security: security)
		let digests = Signing.digest(key: key)
		
		let addressTrits = Signing.address(digests: digests)
		let address = IotaConverter.string(fromTrits: addressTrits)
		if checksum {
			return address+IotaChecksum.calculateChecksum(address: address)
		}
		return address
	}
	
	public static func isSeed(_ string: String) -> Bool {
		guard string.count > 1 && string.count <= 81 else { return false }
		for c in string {
			guard IotaConverter.trytesAlphabet.index(of: c) != nil else { return false }
		}
		return true
	}
}
