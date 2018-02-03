//
//  IotaLocalPow.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 17/01/2018.
//

import Foundation

public protocol IotaLocalPoW {
	func performPoW(trytes: String, minWeightMagnitude: Int) -> String
	func performPoW(trytes: String, minWeightMagnitude: Int, result: @escaping (String)->())
}
