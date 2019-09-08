//
//  IotaUnits.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 30/01/18.
//

import Foundation

/// Iota units.
public enum IotaUnits: Int {
	/// Iota.
	case i = 0
	/// iE^3.
	case Ki = 3
	/// iE^6.
	case Mi = 6
	/// iE^9.
	case Gi = 9
	/// iE^12.
	case Ti = 12
	/// iE^15.
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
	public static func convert(amount: UInt64, toUnit unit: IotaUnits) -> Double {
		return Double(amount) / pow(10, Double(unit.rawValue))
	}
	
	/// Converts from arbitrary unit to the specified unit.
	///
	/// - Parameters:
	///   - amount: The amount.
	///   - fromUnit: The arbitrary unit.
	///   - toUnit: The final unit.
	/// - Returns: The value in the specified unit.
	public static func convert(amount: Double, fromUnit: IotaUnits, toUnit: IotaUnits) -> Double {
		let amountInSource = UInt64(amount * pow(10, Double(fromUnit.rawValue)))
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
		let value = convert(amount: Double(amount), fromUnit: .i, toUnit: unit)
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
}
