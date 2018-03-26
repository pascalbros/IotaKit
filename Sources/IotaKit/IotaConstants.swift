//
//  IotaConstants.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 16/01/18.
//

import Foundation

public struct IotaConstants {
	static let addressLengthWithoutChecksum = 81
	static let addressLengthWithChecksum = 90
	static let messageLength = 2187
	static let tagLength = 27
    public static let mwm = 14
	fileprivate init() { }
}
