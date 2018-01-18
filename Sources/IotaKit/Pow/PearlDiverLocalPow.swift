//
//  PearlDiverLocalPow.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 18/01/18.
//

import Foundation

class PearlDiverLocalPoW: IotaLocalPoW {
	
	fileprivate let pearlDiver = PearlDiver()
	
	func performPoW(trytes: String, minWeightMagnitude: Int) -> String {
		var trits = IotaConverter.trits(fromString: trytes)
		pearlDiver.search(transactionTrits: &trits, minWeightMagnitude: minWeightMagnitude, numberOfThreads: 1)
		return IotaConverter.trytes(trits: trits)
	}
	
	func performPoW(trytes: String, minWeightMagnitude: Int, result: @escaping (String) -> ()) {
		DispatchQueue.global(qos: .userInitiated).async {
			let r = self.performPoW(trytes: trytes, minWeightMagnitude: minWeightMagnitude)
			result(r)
		}
	}
	
	
}
