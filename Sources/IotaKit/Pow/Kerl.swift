//
//  Kerl.swift
//  IOTA
//
//  Created by Pasquale Ambrosini on 06/01/18.
//  Copyright © 2018 Pasquale Ambrosini. All rights reserved.
//

import Foundation

class Kerl: CurlSource {
	
	static let HASH_LENGTH = 243
	fileprivate static let BIT_HASH_LENGTH = 384
	fileprivate static let BYTE_HASH_LENGTH = BIT_HASH_LENGTH / 8
	
	fileprivate static let RADIX = 3
	fileprivate static let MAX_TRIT_VALUE = (RADIX - 1) / 2, MIN_TRIT_VALUE = -MAX_TRIT_VALUE
	fileprivate var keccak: PASHA3!
	fileprivate var byte_state: [UInt8] = []
	fileprivate var trit_state: [Int] = []
	
	fileprivate static let HALF_3: [Int] = [0xa5ce8964, 0x9f007669, 0x1484504f, 0x3ade00d9, 0x0c24486e, 0x50979d57, 0x79a4c702, 0x48bbae36, 0xa9f6808b, 0xaa06a805, 0xa87fabdf, 0x5e69ebef]
	fileprivate static let BYTE_LENGTH = 48;
	fileprivate static let INT_LENGTH = BYTE_LENGTH / 4;
	
	init() {
		self.reset()
	}
	
	deinit {
		self.keccak.close()
	}
	
	func reset() {
		self.reset(false)
	}
	
	func reset(_ onlyKeccak: Bool) {
		self.keccak = PASHA3()
		if (!onlyKeccak) {
			self.byte_state = Array(repeating: 0, count: Kerl.BYTE_HASH_LENGTH)
			self.trit_state = Array(repeating: 0, count: Kerl.HASH_LENGTH)
		}
	}
	
	func absorb(trits: [Int], offset: Int, length: Int) -> CurlSource {
		var off = offset
		var l = length
		if l % 243 != 0 {
			fatalError("Invalid length")
		}
		
		repeat {
			arrayCopy(src: trits, srcPos: off, dest: &trit_state, destPos: 0, length: Kerl.HASH_LENGTH)
			self.trit_state[Kerl.HASH_LENGTH - 1] = 0
			let bytes = Kerl.convertTritsToBytes(self.trit_state)!
			_ = self.keccak.update(withBytes: bytes)
			off += Kerl.HASH_LENGTH
			l -= Kerl.HASH_LENGTH
		} while l > 0

		return self
	}
	
	func absorb(trits: [Int]) -> CurlSource {
		return self.absorb(trits: trits, offset: 0, length: trits.count)
	}
	
	func squeeze(trits: inout [Int], offset: Int, length: Int) -> [Int] {
		var off = offset
		var l = length
		if l % 243 != 0 {
			fatalError("Invalid length")
		}
		repeat {
			self.byte_state = keccak.finalize()
			self.reset(true)
			self.trit_state = Kerl.convertBytesToTrits(self.byte_state)!
			self.trit_state[Kerl.HASH_LENGTH - 1] = 0
			arrayCopy(src: trit_state, srcPos: 0, dest: &trits, destPos: off, length: Kerl.HASH_LENGTH)
			for i in stride(from: self.byte_state.count-1, to: -1, by: -1) {
				self.byte_state[i] = byte_state[i] ^ 0xFF
			}
			_ = self.keccak.update(withBytes: self.byte_state)
			off += Kerl.HASH_LENGTH
			
			l -= Kerl.HASH_LENGTH
		} while l > 0
		
		return trits
	}
	
	func squeeze(trits: inout [Int]) -> [Int] {
		return self.squeeze(trits: &trits, offset: 0, length: trits.count)
	}
	
	private static func toUnsignedLong(_ i: Int) -> UInt64 {
		return UInt64(i & 0xFFFFFFFF);
	}
	
	private static func toUnsignedInt(x: UInt8) -> UInt8 {
		return x & 0xff;
	}
	
	fileprivate static func bigint_not(base: [Int]) -> [Int] {
		var result: [Int] = []
		for i in 0..<base.count {
			result.append(~base[i])
		}
		return result
	}
	
	private static func sum(toSum: [Int]) -> Int {
		return toSum.reduce(0, +)
	}
	
	private static func bigint_add(base: [Int], rh: Int) -> ([Int], Int){
		var result = base.map{$0}
		var res: (Int, Bool) = full_add(ia: result[0], ib: rh, carry: false);
		
		result[0] = res.0
		var j = 1;
		while res.1 {
			res = full_add(ia: result[j], ib: 0, carry: true);
			result[j] = res.0;
			j += 1;
		}
		
		return (result, j)
	}
	
	private static func bigint_add(lh: [Int], rh: [Int]) -> [Int]? {
		var out: [Int] = Array(repeating: 0, count: INT_LENGTH)
		var carry = false
		var ret: (Int, Bool)!
		for i in 0..<INT_LENGTH {
			ret = full_add(ia: lh[i], ib: rh[i], carry: carry);
			out[i] = ret.0
			carry = ret.1
		}
		if carry {
			return nil
		}
		
		return out
	}
	
	fileprivate static func bigint_cmp(lh: [Int], rh: [Int]) -> Int {
		for i in stride(from: INT_LENGTH - 1, to: 0, by: -1) {
			let l = toUnsignedLong(lh[i])
			let r = toUnsignedLong(rh[i])
			if l < r { return -1 }
			else if l > r { return 1 }
			return 0
		}
		return 0
	}
	
	fileprivate static func bigint_sub(lh: [Int], rh: [Int]) -> [Int]? {
		var out: [Int] = Array(repeating: 0, count: INT_LENGTH)
		var noborrow = true
		var ret: (Int, Bool)!
		for i in 0..<INT_LENGTH {
			ret = full_add(ia: lh[i], ib: ~rh[i], carry: noborrow)
			out[i] = ret.0
			noborrow = ret.1
		}
		
		if !noborrow {
			print("noborrow")
		}
		
		return out
	}
	
	fileprivate static func full_add(ia: Int, ib: Int, carry: Bool) -> (Int, Bool) {
		let a = toUnsignedLong(ia)
		let b = toUnsignedLong(ib)
		
		var v = a+b
		var l = v >> 32
		var r = v
		let carry1 = l != 0
		
		if carry { v = r+1 }
		
		l = (v >> 32) & 0xFFFFFFFF
		r = toUnsignedLong(Int(v) & 0xFFFFFFFF)
		
		let carry2 = l != 0
		
		return (Int(r), carry1 || carry2)
	}
	
	
	static func convertTritsToBytes(_ trits: [Int]) -> [UInt8]? {
		if trits.count != HASH_LENGTH {
			return nil
		}
		
		var base: [Int] = Array(repeating: 0, count: INT_LENGTH)
		
		var setUniqueNumbers: [Int: Bool] = [:]
		for x in trits {
			setUniqueNumbers[x] = true
		}
		
		if setUniqueNumbers.count == 1 && setUniqueNumbers[-1] != nil {
			base = HALF_3.map { $0 }
			base = bigint_not(base: base);
			base = bigint_add(base: base, rh: 1).0;
		}else{
			var size = INT_LENGTH
			for i in stride(from: HASH_LENGTH - 2, to: -1, by: -1) {
				let sz = size
				var carry = 0
				
				for j in 0..<sz {
					let v: UInt64 = toUnsignedLong(base[j]) * toUnsignedLong(RADIX) + toUnsignedLong(carry)
					let vv = (v >> 32)
					carry = Int(vv & UInt64(0xFFFFFFFF))
					base[j] = Int(v) & 0xFFFFFFFF
				}
				if carry > 0 {
					base[sz] = carry
					size += 1
				}
				
				let ins = trits[i] + 1;
				let tempSz = bigint_add(base: base, rh: ins)
				
				base = tempSz.0
				if (tempSz.1 > size) {
					size = tempSz.1;
				}
			}
			
			if sum(toSum: base) != 0 {
				if (bigint_cmp(lh: HALF_3, rh: base) <= 0) {
					base = bigint_sub(lh: base, rh: HALF_3)!
				} else {
					base = bigint_sub(lh: HALF_3, rh: base)!
					base = bigint_not(base: base)
					base = bigint_add(base: base, rh: 1).0
				}
			}
		}
		
		var out: [UInt8] = Array(repeating: 0, count: BYTE_LENGTH)
		
		for i in 0..<INT_LENGTH {
			out[i * 4 + 0] = UInt8((base[INT_LENGTH - 1 - i] & 0xFF000000) >> 24)
			out[i * 4 + 1] = UInt8((base[INT_LENGTH - 1 - i] & 0x00FF0000) >> 16)
			out[i * 4 + 2] = UInt8((base[INT_LENGTH - 1 - i] & 0x0000FF00) >> 8)
			out[i * 4 + 3] = UInt8((base[INT_LENGTH - 1 - i] & 0x000000FF) >> 0)
		}
		return out;
	}
	
	static func convertBytesToTrits(_ bytes: [UInt8]) -> [Int]? {
		var base: [Int] = Array(repeating: 0, count: INT_LENGTH)
		var out: [Int] = Array(repeating: 0, count: HASH_LENGTH)
		out[HASH_LENGTH - 1] = 0
		
		if bytes.count != BYTE_LENGTH {
			return nil
		}
		
		for i in 0..<INT_LENGTH {
			base[INT_LENGTH - 1 - i] = Int(toUnsignedLong(Int(bytes[i*4])) << 24)
			base[INT_LENGTH - 1 - i] |= Int(toUnsignedLong(Int(bytes[i*4+1])) << 16)
			base[INT_LENGTH - 1 - i] |= Int(toUnsignedLong(Int(bytes[i*4+2])) << 8)
			base[INT_LENGTH - 1 - i] |= Int(bytes[i*4+3])
		}
		
		if bigint_cmp(lh: base, rh: HALF_3) == 0 {
			var val = 0
			if base[0] > 0 {
				val = -1
			}else if base[0] < 0 {
				val = 1
			}
			
			for i in 0..<HASH_LENGTH {
				out[i] = val
			}
		}else {
			var flipTrits = false
			if toUnsignedLong(base[INT_LENGTH - 1]) >> 31 != 0 {
				base = bigint_not(base: base)
				if bigint_cmp(lh: base, rh: HALF_3) > 0 {
					base = bigint_sub(lh: base, rh: HALF_3)!
					flipTrits = true
				}else {
					base = bigint_add(base: base, rh: 1).0
					base = bigint_sub(lh: HALF_3, rh: base)!
				}
			}else {
				base = bigint_add(lh: HALF_3, rh: base)!
			}
			
			let size = INT_LENGTH
			
			var remainder = 0
			for i in 0..<HASH_LENGTH-1 {
				remainder = 0
				
				for j in stride(from: size - 1, to: -1, by: -1) {
					let lhs = (toUnsignedLong(remainder) << 32) | toUnsignedLong(base[j])
					let rhs = toUnsignedLong(RADIX)
					
					let q = Int(lhs / rhs)
					let r = lhs % rhs
					base[j] = q
					remainder = Int(r)
				}
				out[i] = remainder - 1
			}
			
			if flipTrits {
				for i in 0..<out.count {
					out[i] = -out[i]
				}
			}
		}
		return out
	}
}



