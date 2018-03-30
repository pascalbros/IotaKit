//
//  IotaConstants.swift
//  IotaKitPackageDescription
//
//  Created by Pasquale Ambrosini on 16/01/18.
//

import Foundation

/// Iota constants.
public struct IotaConstants {
	
	/// Address length without checksum.
	public static let addressLengthWithoutChecksum = 81
	
	/// Address length with checksum.
	public static let addressLengthWithChecksum = 90
	
	/// Max length of message.
	public static let messageLength = 2187
	
	/// Max length of tag.
	public static let tagLength = 27
	
	/// Minimum weight magnitude.
	public static let mwm = 14
	fileprivate init() { }
}
