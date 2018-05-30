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
public class CPearlDiver: IotaLocalPoW {
    
    public init() { }
    
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
    
    public func performPoW(trytes: String, minWeightMagnitude: Int, result: @escaping (String) -> ()) {
        
    }
    

}
