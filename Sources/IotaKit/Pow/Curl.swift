//
//  Curl.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 15/01/18.
//

import Foundation

class Curl: CurlSource {
	
	func squeeze(trits: inout [Int]) -> [Int] {
		return []
	}
	
	
	static let truthTable: [Int] = [1, 0, -1, 2, 1, -1, 0, 2, -1, 1, 0]
	
	static let hashLength = 243
	static let stateLength = 3*Curl.hashLength
	
	static let numOfRoundsP81 = 81
	static let numOfRoundsP27 = 27
	
	fileprivate let numberOfRounds: Int
	fileprivate var stateLow: [UInt64]?
	fileprivate var stateHigh: [UInt64]?
	fileprivate var scratchPad: [Int] = Array(repeating: 0, count: Curl.stateLength)
	fileprivate var state: [Int]?
	
	init(numberOfRounds: Int, pair: Bool = false) {
		self.numberOfRounds = numberOfRounds
		if pair {
			self.stateHigh = Array(repeating: 0, count: Curl.stateLength)
			self.stateLow = Array(repeating: 0, count: Curl.stateLength)
		}else {
			self.state = Array(repeating: 0, count: Curl.stateLength)
		}
	}
	
	func absorb(trits: [Int], offset: Int, length: Int) -> CurlSource {
		var l = length
		var off = offset
		repeat {
			let arrayLength = l < Curl.hashLength ? l : Curl.hashLength
			arrayCopy(src: trits, srcPos: off, dest: &self.state!, destPos: 0, length: arrayLength)
			_ = self.transform()
			off += Curl.hashLength
			l -= Curl.hashLength
		}while l > 0
		return self
	}
	
	func absorb(trits: [Int]) -> CurlSource {
		return self.absorb(trits: trits, offset: 0, length: trits.count)
	}
	
	func transform() -> CurlSource {
		var scratchPadIndex = 0
		var prevScratchPadIndex = 0
		for _ in 0..<self.numberOfRounds {
			arrayCopy(src: self.state!, srcPos: 0, dest: &self.scratchPad, destPos: 0, length: Curl.stateLength)
			for stateIndex in 0..<Curl.stateLength {
				prevScratchPadIndex = scratchPadIndex
				if scratchPadIndex < 365 {
					scratchPadIndex += 364
				}else{
					scratchPadIndex += -365
				}
				self.state![stateIndex] = Curl.truthTable[scratchPad[prevScratchPadIndex] + (scratchPad[scratchPadIndex] << 2) + 5]
			}
		}
		return self
	}
	
	func clone() -> CurlSource {
		return Curl(numberOfRounds: numberOfRounds)
	}
	
	func reset() {
		if self.state == nil {
			return
		}
		for i in 0..<self.state!.count {
			self.state![i] = 0
		}
	}
	
	fileprivate func set() {
		if self.stateLow != nil {
			for i in 0..<self.stateLow!.count {
				self.stateLow![i] = IotaConverter.highLongBits
			}
		}
		
		if self.stateHigh != nil {
			for i in 0..<self.stateHigh!.count {
				self.stateHigh![i] = IotaConverter.highLongBits
			}
		}
	}
	
	func squeeze(trits: inout [Int], offset: Int, length: Int) -> [Int] {
		var l = length
		var off = offset
		repeat {
			let arrayLength = l < Curl.hashLength ? l : Curl.hashLength
			arrayCopy(src: state!, srcPos: 0, dest: &trits, destPos: off, length: arrayLength)
			_ = self.transform()
			off += Curl.hashLength
			l -= Curl.hashLength
		}while l > 0
		return self.state!
	}
	
	fileprivate func pairTransform() {
		var curlScratchPadLow: [UInt64] = Array(repeating: 0, count: Curl.stateLength)
		var curlScratchPadHigh: [UInt64] = Array(repeating: 0, count: Curl.stateLength)
		var curlScratchPadIndex = 0
		for _ in stride(from: self.numberOfRounds, to: -1, by: -1) {
			arrayCopy(src: self.stateLow!, srcPos: 0, dest: &curlScratchPadLow, destPos: 0, length: Curl.stateLength)
			arrayCopy(src: self.stateHigh!, srcPos: 0, dest: &curlScratchPadHigh, destPos: 0, length: Curl.stateLength)
			for curlStateIndex in 0..<Curl.stateLength {
				let alpha = curlScratchPadLow[curlScratchPadIndex]
				let beta = curlScratchPadHigh[curlScratchPadIndex]
				curlScratchPadIndex += curlScratchPadIndex < 365 ? 364 : -365
				let gamma = curlScratchPadHigh[curlScratchPadIndex]
				let delta = (alpha | (~gamma)) & (curlScratchPadLow[curlScratchPadIndex] ^ beta)
				self.stateLow![curlStateIndex] = ~delta
				self.stateHigh![curlStateIndex] = (alpha ^ gamma) | delta
			}
		}
	}
	
	func absorb(pair: ([UInt64], [UInt64]), offset: Int, length: Int) {
		var o = offset
		var l = length
		repeat {
			arrayCopy(src: pair.0, srcPos: o, dest: &self.stateLow!, destPos: 0, length: l < Curl.hashLength ? l : Curl.hashLength)
			arrayCopy(src: pair.1, srcPos: o, dest: &self.stateHigh!, destPos: 0, length: l < Curl.hashLength ? l : Curl.hashLength)
			self.pairTransform()
			o += Curl.hashLength
			l -= Curl.hashLength
		} while l > 0
	}
	
	func squeeze(pair: ([UInt64], [UInt64]), offset: Int, length: Int) {
		var o = offset
		var l = length
		var low = pair.0
		var high = pair.1
		
		repeat {
			arrayCopy(src: self.stateLow!, srcPos: 0, dest: &low, destPos: o, length: l < Curl.hashLength ? l : Curl.hashLength)
			arrayCopy(src: self.stateHigh!, srcPos: 0, dest: &high, destPos: o, length: l < Curl.hashLength ? l : Curl.hashLength)
			self.pairTransform()
			o += Curl.hashLength
			l -= Curl.hashLength
		} while l > 0
	}
}
