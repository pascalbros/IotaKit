//
//  Signing.swift
//  IOTA
//
//  Created by Pasquale Ambrosini on 06/01/18.
//  Copyright © 2018 Pasquale Ambrosini. All rights reserved.
//

import Foundation


class Signing {
	
	static let KEY_LENGTH = 6561
	static let HASH_LENGTH = 243
	
	static func key(inSeed: [Int], index: Int, security: Int) -> [Int] {
		if security < 1 {
			fatalError("INVALID_SECURITY_LEVEL_INPUT_ERROR")
		}
		
		var seed = inSeed.map { $0 }
		
		for _ in 0..<index {
			for j in 0..<seed.count {
				seed[j] += 1
				if seed[j] > 1 {
					seed[j] = -1
				}else {
					break
				}
			}
		}
		
		let kerl = Kerl()
		_ = kerl.absorb(trits: seed, offset: 0, length: seed.count)
		_ = kerl.squeeze(trits: &seed, offset: 0, length: seed.count)
		kerl.reset()
		_ = kerl.absorb(trits: seed, offset: 0, length: seed.count)
		
		var key: [Int] = Array(repeating: 0, count: security * HASH_LENGTH * 27)
		var buffer: [Int] = Array(repeating: 0, count: seed.count)
		var offset = 0
		var s = security
		while s > 0 {
			s -= 1
			for _ in 0..<27 {
				_ = kerl.squeeze(trits: &buffer, offset: 0, length: seed.count)
				arrayCopy(src: buffer, srcPos: 0, dest: &key, destPos: offset, length: HASH_LENGTH)
				offset += HASH_LENGTH
			}
		}
		return key
	}
	
	
	static func digest(key: [Int]) -> [Int] {
		let security = key.count/KEY_LENGTH
		var digests: [Int] = Array(repeating: 0, count: security * HASH_LENGTH)
		var keyFragment: [Int] = Array(repeating: 0, count: KEY_LENGTH)
		
		let kerl = Kerl()
		
		for i in 0..<security {
			arrayCopy(src: key, srcPos: i*KEY_LENGTH, dest: &keyFragment, destPos: 0, length: KEY_LENGTH)
			for j in 0..<27 {
				for _ in 0..<26 {
					_ = kerl.absorb(trits: keyFragment, offset: j*HASH_LENGTH, length: HASH_LENGTH)
					_ = kerl.squeeze(trits: &keyFragment, offset: j*HASH_LENGTH, length: HASH_LENGTH)
					kerl.reset()
				}
			}
			_ = kerl.absorb(trits: keyFragment, offset: 0, length: keyFragment.count)
			_ = kerl.squeeze(trits: &digests, offset: i*HASH_LENGTH, length: HASH_LENGTH)
			kerl.reset()
		}
		return digests
	}
	
	static func address(digests: [Int]) -> [Int] {
		var address: [Int] = Array(repeating: 0, count: HASH_LENGTH)
		let kerl = Kerl()
		_ = kerl.absorb(trits: digests)
		_ = kerl.squeeze(trits: &address)
		return address
	}
}

