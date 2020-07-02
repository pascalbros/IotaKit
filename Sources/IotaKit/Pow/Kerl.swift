//
//  Kerl.swift
//  IOTA
//
//  Created by Pasquale Ambrosini on 06/01/18.
//  Copyright © 2018 Pasquale Ambrosini. All rights reserved.
//

import Foundation

class Kerl: CurlSource {

	static let hashLength = 243
	fileprivate static let bitHashLength = 384
	fileprivate static let byteHashLength = bitHashLength / 8

	fileprivate static let radix: Int64 = 3
	fileprivate static let maxTritValue: Int64 = (radix - 1) / 2
	fileprivate static let minTritValue: Int64 = -maxTritValue
	fileprivate var keccak: PASHA3!
	fileprivate var byteState: [UInt8] = []
	fileprivate var tritState: [Int] = []

	fileprivate static let half3: [Int64] = [
		0xa5ce8964, 0x9f007669, 0x1484504f, 0x3ade00d9,
		0x0c24486e, 0x50979d57, 0x79a4c702, 0x48bbae36,
		0xa9f6808b, 0xaa06a805, 0xa87fabdf, 0x5e69ebef]
	fileprivate static let byteLength = 48
	fileprivate static let intLength = byteLength / 4

	init() {
		self.reset(false)
	}

	deinit {
		self.keccak.close()
	}

	func clone() -> CurlSource {
		return CurlMode.kerl.create()
	}

	func reset() {
		self.reset(true)
	}

	func reset(_ onlyKeccak: Bool) {
		self.keccak = PASHA3()
		if (!onlyKeccak) {
			self.byteState = Array(repeating: 0, count: Kerl.byteHashLength)
			self.tritState = Array(repeating: 0, count: Kerl.hashLength)
		}
	}

	func absorb(trits: [Int], offset: Int, length: Int) -> CurlSource {
		var off = offset
		var length = length
		if length % Curl.hashLength != 0 {
			fatalError("Invalid length")
		}
		repeat {
			arrayCopy(src: trits, srcPos: off, dest: &tritState, destPos: 0, length: Kerl.hashLength)
			self.tritState[Kerl.hashLength - 1] = 0
			let bytes = Kerl.convertTritsToBytes(self.tritState)!
			_ = self.keccak.update(withBytes: bytes)
			off += Kerl.hashLength
			length -= Kerl.hashLength
		} while length > 0

		return self
	}

	func absorb(trits: [Int]) -> CurlSource {
		return self.absorb(trits: trits, offset: 0, length: trits.count)
	}

	func squeeze(trits: inout [Int], offset: Int, length: Int) -> [Int] {
		var off = offset
		var length = length
		if length % Curl.hashLength != 0 {
			fatalError("Invalid length")
		}
		repeat {
			self.byteState = keccak.finalize()
			self.reset(true)
			self.tritState = Kerl.convertBytesToTrits(self.byteState)!
			self.tritState[Kerl.hashLength - 1] = 0
			arrayCopy(src: tritState, srcPos: 0, dest: &trits, destPos: off, length: Kerl.hashLength)
			for i in stride(from: self.byteState.count-1, to: -1, by: -1) {
				self.byteState[i] = byteState[i] ^ 0xFF
			}
			_ = self.keccak.update(withBytes: self.byteState)
			off += Kerl.hashLength
			length -= Kerl.hashLength
		} while length > 0
		return trits
	}

	func squeeze(trits: inout [Int]) -> [Int] {
		return self.squeeze(trits: &trits, offset: 0, length: trits.count)
	}

	private static func toUnsignedLong(_ i: Int64) -> UInt64 {
		return UInt64(i & 0xFFFFFFFF)
	}

	private static func toUnsignedInt(_ value: UInt8) -> UInt8 {
		return value & 0xff
	}

	fileprivate static func bigintNot(base: [Int64]) -> [Int64] {
		var result: [Int64] = []
		for i in 0..<base.count {
			result.append(~base[i])
		}
		return result
	}

	private static func sum(toSum: [Int64]) -> Int64 {
		return toSum.reduce(0, +)
	}

	private static func bigintAdd(base: [Int64], rhValue: Int64) -> ([Int64], Int64) {
		var result = base
		var res: (Int64, Bool) = fullAdd(ia: result[0], ib: rhValue, carry: false)
		result[0] = res.0
		var j = 1
		while res.1 {
			res = fullAdd(ia: result[j], ib: 0, carry: true)
			result[j] = res.0
			j += 1
		}
		return (result, Int64(j))
	}

	private static func bigintAdd(lh lhValue: [Int64], rh rhValue: [Int64]) -> [Int64]? {
		var out: [Int64] = Array(repeating: 0, count: intLength)
		var carry = false
		var ret: (Int64, Bool)!
		for i in 0..<intLength {
			ret = fullAdd(ia: lhValue[i], ib: rhValue[i], carry: carry)
			out[i] = ret.0
			carry = ret.1
		}
		if carry { return nil }
		return out
	}

	fileprivate static func bigint_cmp(lh lhValue: [Int64], rh rhValue: [Int64]) -> Int64 {
		for i in stride(from: intLength - 1, to: 0, by: -1) {
			let lValue = toUnsignedLong(lhValue[i])
			let rValue = toUnsignedLong(rhValue[i])
			if lValue < rValue { return -1
			} else if lValue > rValue { return 1 }
			return 0
		}
		return 0
	}

	fileprivate static func bigintSub(lhValue: [Int64], rhValue: [Int64]) -> [Int64]? {
		var out: [Int64] = Array(repeating: 0, count: intLength)
		var noborrow = true
		var ret: (Int64, Bool)!
		for i in 0..<intLength {
			ret = fullAdd(ia: lhValue[i], ib: ~rhValue[i], carry: noborrow)
			out[i] = ret.0
			noborrow = ret.1
		}
		if !noborrow {
			print("noborrow")
		}
		return out
	}

	fileprivate static func fullAdd(ia iaValue: Int64, ib ibValue: Int64, carry: Bool) -> (Int64, Bool) {
		let aValue = toUnsignedLong(iaValue)
		let bValue = toUnsignedLong(ibValue)
		var vValue = aValue+bValue
		var lValue = vValue >> 32
		var rValue = vValue
		let carry1 = lValue != 0

		if carry { vValue = rValue+1 }

		lValue = (vValue >> 32) & 0xFFFFFFFF
		rValue = toUnsignedLong(Int64(vValue & 0xFFFFFFFF))

		let carry2 = lValue != 0

		return (Int64(rValue), carry1 || carry2)
	}

	static func convertTritsToBytes(_ trits: [Int]) -> [UInt8]? {
		if trits.count != hashLength {
			return nil
		}

		var base: [Int64] = Array(repeating: 0, count: intLength)

		var setUniqueNumbers: [Int: Bool] = [:]
		for i in trits {
			setUniqueNumbers[i] = true
		}

		if setUniqueNumbers.count == 1 && setUniqueNumbers[-1] != nil {
			base = half3.map { $0 }
			base = bigintNot(base: base)
			base = bigintAdd(base: base, rhValue: 1).0
		} else {

			convertTritsToBytesUtils(base: &base, trits: trits)
			if sum(toSum: base) != 0 {
				if (bigint_cmp(lh: half3, rh: base) <= 0) {
					base = bigintSub(lhValue: base, rhValue: half3)!
				} else {
					base = bigintSub(lhValue: half3, rhValue: base)!
					base = bigintNot(base: base)
					base = bigintAdd(base: base, rhValue: 1).0
				}
			}
		}
		var out: [UInt8] = Array(repeating: 0, count: byteLength)

		for i in 0..<intLength {
			out[i * 4 + 0] = UInt8((base[intLength - 1 - i] & 0xFF000000) >> 24)
			out[i * 4 + 1] = UInt8((base[intLength - 1 - i] & 0x00FF0000) >> 16)
			out[i * 4 + 2] = UInt8((base[intLength - 1 - i] & 0x0000FF00) >> 8)
			out[i * 4 + 3] = UInt8((base[intLength - 1 - i] & 0x000000FF) >> 0)
		}
		return out
	}

	fileprivate static func convertTritsToBytesUtils(base: inout [Int64], trits: [Int]) {
		var size = Int64(intLength)
		for i in stride(from: hashLength - 2, to: -1, by: -1) {
			let szValue = Int(size)
			var carry: Int64 = 0
			for j in 0..<szValue {
				let vValue: UInt64 = toUnsignedLong(base[j]) * toUnsignedLong(radix) + toUnsignedLong(carry)
				let vvValue = (vValue >> 32)
				carry = Int64(vvValue & 0xFFFFFFFF)
				base[j] = Int64(vValue) & 0xFFFFFFFF
			}
			if carry > 0 {
				base[szValue] = carry
				size += 1
			}
			let ins = trits[i] + 1
			let tempSz = bigintAdd(base: base, rhValue: Int64(ins))

			base = tempSz.0
			if (tempSz.1 > size) {
				size = tempSz.1
			}
		}
	}

	static func convertBytesToTrits(_ bytes: [UInt8]) -> [Int]? {
		var base: [Int64] = Array(repeating: 0, count: intLength)
		var out: [Int] = Array(repeating: 0, count: hashLength)
		out[hashLength - 1] = 0

		if bytes.count != byteLength {
			return nil
		}

		for i in 0..<intLength {
			base[intLength - 1 - i] = Int64(toUnsignedLong(Int64(bytes[i*4])) << 24)
			base[intLength - 1 - i] |= Int64(toUnsignedLong(Int64(bytes[i*4+1])) << 16)
			base[intLength - 1 - i] |= Int64(toUnsignedLong(Int64(bytes[i*4+2])) << 8)
			base[intLength - 1 - i] |= Int64(bytes[i*4+3])
		}

		if bigint_cmp(lh: base, rh: half3) == 0 {
			var val = 0
			if base[0] > 0 {
				val = -1
			} else if base[0] < 0 {
				val = 1
			}

			for i in 0..<hashLength {
				out[i] = val
			}
		} else {
			var flipTrits = false
			if toUnsignedLong(base[intLength - 1]) >> 31 != 0 {
				base = bigintNot(base: base)
				if bigint_cmp(lh: base, rh: half3) > 0 {
					base = bigintSub(lhValue: base, rhValue: half3)!
					flipTrits = true
				} else {
					base = bigintAdd(base: base, rhValue: 1).0
					base = bigintSub(lhValue: half3, rhValue: base)!
				}
			} else {
				base = bigintAdd(lh: half3, rh: base)!
			}

			let size = intLength
			var remainder: Int64 = 0
			for i in 0..<hashLength-1 {
				remainder = 0
				for j in stride(from: size - 1, to: -1, by: -1) {
					let lhs = (toUnsignedLong(remainder) << 32) | toUnsignedLong(base[j])
					let rhs = toUnsignedLong(radix)
					let qValue = Int64(lhs / rhs)
					let rValue = lhs % rhs
					base[j] = qValue
					remainder = Int64(rValue)
				}
				out[i] = Int(remainder - 1)
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
