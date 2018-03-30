//
//  IotaUnits.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 30/01/18.
//

import Foundation

/// Iota units.
///
/// - i: Iota.
/// - Ki: iE^3.
/// - Mi: iE^6.
/// - Gi: iE^9.
/// - Ti: iE^12.
/// - Pi: iE^15.
public enum IotaUnits: Int {
	case i = 0
	case Ki = 3
	case Mi = 6
	case Gi = 9
	case Ti = 12
	case Pi = 15
	
	/// Initializer for IotaUnits.
	///
	/// - Parameter amount: The amount in Iota.
	public init(amount: Int) {
		var v = amount
		if amount < 0 { v = -v }
		self.init(amount: UInt64(v))
	}
	
	/// Initializer for IotaUnits.
	///
	/// - Parameter amount: The amount in Iota.
	public init(amount: UInt64) {
		let length = "\(amount)".count
		switch length {
			case 1...3: self = .i
			case 4...6: self = .Ki
			case 7...9: self = .Mi
			case 10...12: self = .Gi
			case 13...15: self = .Ti
			case 16...18: self = .Pi
			default: self = .i
		}
	}
	
	/// Converts the unit to string.
	public var string: String {
		switch self {
		case .i: return "i"
		case .Ki: return "Ki"
		case .Mi: return "Mi"
		case .Gi: return "Gi"
		case .Ti: return "Ti"
		case .Pi: return "Pi"
		}
	}
}

/// Utils for unit conversion.
public struct IotaUnitsConverter {
	private init() { }
	
	/// Converts from Iota to the specified unit.
	///
	/// - Parameters:
	///   - amount: The amount in Iota.
	///   - unit: The final unit.
	/// - Returns: The value in the specified unit.
	public static func convert(amount: UInt64, toUnit unit: IotaUnits) -> Float {
		return Float(amount) / powf(10, Float(unit.rawValue))
	}
	
	/// Converts from arbitrary unit to the specified unit.
	///
	/// - Parameters:
	///   - amount: The amount.
	///   - fromUnit: The arbitrary unit.
	///   - toUnit: The final unit.
	/// - Returns: The value in the specified unit.
	public static func convert(amount: Float, fromUnit: IotaUnits, toUnit: IotaUnits) -> Float {
		let amountInSource = UInt64(amount * powf(10, Float(fromUnit.rawValue)))
		return convert(amount: amountInSource, toUnit: toUnit)
	}
	
	/// Converts Iota amount to human readable string.
	///
	/// - Parameters:
	///   - amount: The amount.
	///   - extended: If `true`, will return the extended string.
	///   - forceUnit: An arbitrary unit.
	/// - Returns: The string that represents the value and unit.
	public static func iotaToString(amount: UInt64, extended: Bool = false, forceUnit: IotaUnits? = nil) -> String {
		let unit = forceUnit != nil ? forceUnit! : IotaUnits(amount: amount)
		let value = convert(amount: Float(amount), fromUnit: .i, toUnit: unit)
		if unit == .i { return "\(amount) \(unit)" }
		
		var v = "\(NSDecimalNumber(string: "\(value)"))"
		if !extended {
			let values = v.split(separator: ".")
			if values.count == 2 {
				if values.last!.count > 2 {
					v = "\(values.first!).\(values.last!.prefix(2))"
				}
			}
			
		}
		return "\(v) \(unit.string)"
	}
	
	/// Converts Iota amount to human readable string.
	///
	/// - Parameters:
	///   - amount: The amount.
	///   - unit: The unit.
	///   - extended: If `true`, will return the extended string.
	public static func createAmountWithUnitDisplayText(amount: UInt64, unit: IotaUnits, extended: Bool) {
		
	}
	
	public static func createAmountDisplayText(amount: UInt64, unit: IotaUnits, extended: Bool) {
		
	}
}
