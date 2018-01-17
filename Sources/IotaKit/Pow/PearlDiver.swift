//
//  PearlDiver.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 17/01/2018.
//	See https://github.com/iotaledger/iri/blob/dev/src/main/java/com/iota/iri/hash/PearlDiver.java

import Foundation

enum PearlDiverState {
	case idle
	case running
	case canceled
	case completed
}

fileprivate let transactionLength = 8019
fileprivate let curlHashLength = 243
fileprivate let curlStateLength = curlHashLength*3

fileprivate let highBits: UInt64 = 0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111
fileprivate let lowBits: UInt64 = 0b00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000

class PearlDiver {
	fileprivate var state: PearlDiverState = .idle
	private let queue = DispatchQueue(label: "iota-pow", qos: .userInteractive, attributes: .concurrent)
	
	func cancel() {
		queue.sync(flags: .barrier) {
			self.state = .canceled
		}
	}
	
	func search(transactionTrits: [Int], numberOfThreads: Int) {
		
		queue.sync(flags: .barrier) {
			self.state = .running
		}
		
		var midCurlStateLow: [UInt64] = Array(repeating: 0, count: curlStateLength)
		var midCurlStateHigh: [UInt64] = Array(repeating: 0, count: curlStateLength)
		
		do {
			for i in curlHashLength..<curlStateLength {
				midCurlStateLow[i] = highBits
				midCurlStateHigh[i] = highBits
			}
			
			var offset = 0
			var curlScratchpadLow: [UInt64] = Array(repeating: 0, count: curlStateLength)
			for i in stride(from: transactionLength-curlHashLength, to: 0, by: -1) {
				for j in 0..<curlHashLength {
					switch transactionTrits[offset] {
					case 0:
						midCurlStateLow[j] = highBits
						midCurlStateHigh[j] = highBits
					case 1:
						midCurlStateLow[j] = lowBits
						midCurlStateHigh[j] = highBits
					default:
						midCurlStateLow[j] = highBits
						midCurlStateHigh[j] = lowBits
					}
					offset += 1
				}
				//transform
			}
			
			for j in 0..<162 {
				switch transactionTrits[offset] {
				case 0:
					midCurlStateLow[j] = highBits
					midCurlStateHigh[j] = highBits
				case 1:
					midCurlStateLow[j] = lowBits
					midCurlStateHigh[j] = highBits
				default:
					midCurlStateLow[j] = highBits
					midCurlStateHigh[j] = lowBits
				}
				offset += 1
			}
			
			midCurlStateLow[162 + 0] = 0b1101101101101101101101101101101101101101101101101101101101101101
			midCurlStateHigh[162 + 0] = 0b1011011011011011011011011011011011011011011011011011011011011011
			midCurlStateLow[162 + 1] = 0b1111000111111000111111000111111000111111000111111000111111000111
			midCurlStateHigh[162 + 1] = 0b1000111111000111111000111111000111111000111111000111111000111111
			midCurlStateLow[162 + 2] = 0b0111111111111111111000000000111111111111111111000000000111111111
			midCurlStateHigh[162 + 2] = 0b1111111111000000000111111111111111111000000000111111111111111111
			midCurlStateLow[162 + 3] = 0b1111111111000000000000000000000000000111111111111111111111111111
			midCurlStateHigh[162 + 3] = 0b0000000000111111111111111111111111111111111111111111111111111111
			
			
		}
	}

}
