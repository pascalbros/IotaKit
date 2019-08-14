//
//  PearlDiverLocalPow.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 18/01/18.
//

import Foundation
import Dispatch

/// Pearl Diver Local PoW implementation.
public class PearlDiverLocalPoW: IotaLocalPoW {
	
	fileprivate let pearlDiver = PearlDiver()
	
	/// Constructor for PearlDiverLocalPoW.
	public init() { }
	
	/// Perform the PoW synchronously.
	///
	/// - Parameters:
	///   - trytes: Trytes as String.
	///   - minWeightMagnitude: Minimum Weight Magnitude.
	/// - Returns: Trytes as String.
	public func performPoW(trytes: String, minWeightMagnitude: Int) -> String {
		let trits = IotaConverter.trits(fromString: trytes)
		var threadsCount = ProcessInfo.processInfo.activeProcessorCount - 1
		if threadsCount < 1 {
			threadsCount = 1
		}
		let tritsResult = pearlDiver.search(transactionTrits: trits, minWeightMagnitude: minWeightMagnitude, numberOfThreads: threadsCount)
		return IotaConverter.trytes(trits: tritsResult)
	}
	
	/// Perform the PoW asynchronously on `.userInitiated` queue.
	///
	/// - Parameters:
	///   - trytes: Trytes as String.
	///   - minWeightMagnitude: Minimum Weight Magnitude.
	///   - result: Trytes as String.
	public func performPoW(trytes: String, minWeightMagnitude: Int, result: @escaping (String) -> ()) {
		DispatchQueue.global(qos: .userInitiated).async {
			let r = self.performPoW(trytes: trytes, minWeightMagnitude: minWeightMagnitude)
			result(r)
		}
	}
}
