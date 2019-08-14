//
//  CPow.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 26/05/18.
//

import CoreFoundation
#if COCOAPODS
import IotaKit.cpow
#else
import cpow
#endif

/// C implementation of Pearl Diver (PoW).
public class CPearlDiver: IotaLocalPoW {
    
    /// Constructor of CPearlDiver.
    public init() { }
    
	/// Perform the PoW synchronously.
	///
	/// - Parameters:
	///   - trytes: Trytes as String.
	///   - minWeightMagnitude: Minimum Weight Magnitude.
	/// - Returns: Trytes as String.
    public func performPoW(trytes: String, minWeightMagnitude: Int) -> String {
        let cTrytes = trytes.cString(using: .utf8)
        if let resultC = iota_pow(cTrytes, UInt8(minWeightMagnitude)) {
            let result = String(cString: resultC)
            resultC.deallocate()
            var tx = IotaTransaction(trytes: trytes)
            tx.nonce = result
            return tx.trytes
        }
        return ""
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
