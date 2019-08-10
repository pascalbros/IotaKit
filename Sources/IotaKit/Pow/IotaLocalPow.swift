//
//  IotaLocalPow.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 17/01/2018.
//

import Foundation

/// Protocol for Iota Local Proof of Work, all the implementations for PoW can implement this protocol in order to be used in Iota client.
public protocol IotaLocalPoW {
	
	/// Perform the PoW synchronously.
	///
	/// - Parameters:
	///   - trytes: Trytes as String
	///   - minWeightMagnitude: Minimum Weight Magnitude
	/// - Returns: Trytes as String
	func performPoW(trytes: String, minWeightMagnitude: Int) -> String
	
	
	/// Perform the PoW asynchronously.
	///
	/// - Parameters:
	///   - trytes: Trytes as String
	///   - minWeightMagnitude: Minimum Weight Magnitude
	///   - result: Trytes as String
	func performPoW(trytes: String, minWeightMagnitude: Int, result: @escaping (String)->())
}
