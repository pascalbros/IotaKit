//
//  Checksum.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 08/01/18.
//

import Foundation

struct IotaChecksum {
	
	static func calculateChecksum(address: String) -> String {
		let kerl = Kerl()
		_ = kerl.absorb(trits: IotaConverter.trits(fromString: address))
		var checksumTrits: [Int] = Array(repeating: 0, count: Kerl.HASH_LENGTH)
		_ = kerl.squeeze(trits: &checksumTrits)
		let checksum = IotaConverter.string(fromTrits: checksumTrits)
		
		let start = checksum.index(checksum.startIndex, offsetBy: 72)
		let end = checksum.index(checksum.startIndex, offsetBy: 81)
		
		return String(checksum[start..<end])
	}
}
