//
//  PearlDiverLocalPow.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 18/01/18.
//

import Foundation
import Dispatch

public class PearlDiverLocalPoW: IotaLocalPoW {
	
	fileprivate let pearlDiver = PearlDiver()
	
	public init() { }
	
	public func performPoW(trytes: String, minWeightMagnitude: Int) -> String {
		let trits = IotaConverter.trits(fromString: trytes)
		let tritsResult = pearlDiver.search(transactionTrits: trits, minWeightMagnitude: minWeightMagnitude, numberOfThreads: ProcessInfo.processInfo.processorCount)
		return IotaConverter.trytes(trits: tritsResult)
	}
	
	public func performPoW(trytes: String, minWeightMagnitude: Int, result: @escaping (String) -> ()) {
		DispatchQueue.global(qos: .userInitiated).async {
			let r = self.performPoW(trytes: trytes, minWeightMagnitude: minWeightMagnitude)
			result(r)
		}
	}
}
