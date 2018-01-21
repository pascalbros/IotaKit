//
//  CurlSource.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 15/01/18.
//

import Foundation

protocol CurlSource {
	func absorb(trits: [Int], offset: Int, length: Int) -> CurlSource
	func absorb(trits: [Int]) -> CurlSource
	func squeeze(trits: inout [Int], offset: Int, length: Int) -> [Int]
	func squeeze(trits: inout [Int]) -> [Int]
	func reset()
	func clone() -> CurlSource
}

enum CurlMode {
	case curlP81
	case curlP27
	case kerl
	
	func create() -> CurlSource {
		switch self {
			case .curlP81: return Curl(numberOfRounds: 81)
			case .curlP27: return Curl(numberOfRounds: 27)
			case .kerl: return Kerl()
		}
	}
}

