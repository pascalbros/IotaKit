//
//  IotaUnitsTests.swift
//  IotaKitTests
//
//  Created by Pasquale Ambrosini on 30/01/18.
//

import XCTest

class IotaUnitsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testValueItoKi() {
        let value = IotaUnitsConverter.convert(amount: 1000, fromUnit: .i, toUnit: .Ki)
		XCTAssertEqual(value, 1)
    }

	func testValueKiToI() {
		let value = IotaUnitsConverter.convert(amount: 0.35, fromUnit: .Ki, toUnit: .i)
		XCTAssertEqual(value, 350)
	}
	
	func testValueKiToMi() {
		let value = IotaUnitsConverter.convert(amount: 100000, fromUnit: .Ki, toUnit: .i)
		XCTAssertEqual(value, 100000000)
	}
	
	func testValues() {
		let values: [Float] = [1, 1000, 1000000, 1000000000, 1000000000000, 1000000000000000]
		let units: [IotaUnits] = [.Pi, .Ti, .Gi, .Mi, .Ki, .i]
		for i in 0..<values.count {
			let value = IotaUnitsConverter.convert(amount: 1, fromUnit: .Pi, toUnit: units[i])
			XCTAssertEqual(value, values[i])
		}
	}
	
	func testValueToStringForcingUnit() {
		let units: [IotaUnits] = [.Pi, .Ti, .Gi, .Mi, .Ki, .i]
		let values = ["0.000000000001234 Pi", "0.000000001234 Ti", "0.000001234 Gi", "0.001234 Mi", "1.234 Ki", "1234 i"]
		for i in 0..<units.count {
			let result = IotaUnitsConverter.iotaToString(amount: 1234, forceUnit: units[i])
			XCTAssertEqual(result, values[i])
		}
	}
	
	func testValueToStringAutomaticUnit() {
		var result = IotaUnitsConverter.iotaToString(amount: 234)
		XCTAssertEqual(result, "234 i")
		result = IotaUnitsConverter.iotaToString(amount: 10123)
		XCTAssertEqual(result, "10.12 Ki")
		result = IotaUnitsConverter.iotaToString(amount: 123123)
		XCTAssertEqual(result, "123.12 Ki")
		result = IotaUnitsConverter.iotaToString(amount: 1234567)
		XCTAssertEqual(result, "1.23 Mi")
		result = IotaUnitsConverter.iotaToString(amount: 1231234567)
		XCTAssertEqual(result, "1.23 Gi")
	}
	
	func testValueToStringAutomaticUnitExtended() {
		var result = IotaUnitsConverter.iotaToString(amount: 234, extended: true)
		XCTAssertEqual(result, "234 i")
		result = IotaUnitsConverter.iotaToString(amount: 10123, extended: true)
		XCTAssertEqual(result, "10.123 Ki")
		result = IotaUnitsConverter.iotaToString(amount: 123123, extended: true)
		XCTAssertEqual(result, "123.123 Ki")
		result = IotaUnitsConverter.iotaToString(amount: 1234567, extended: true)
		XCTAssertEqual(result, "1.23457 Mi")
		result = IotaUnitsConverter.iotaToString(amount: 1231234567, extended: true)
		XCTAssertEqual(result, "1.23123 Gi")
	}
	

}
