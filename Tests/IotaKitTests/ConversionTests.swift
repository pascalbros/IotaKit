//
//  ConversionTests.swift
//  IotaKitTests
//
//  Created by Pasquale Ambrosini on 09/03/18.
//

import XCTest

class ConversionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAsciiToTrytes() {
		let input = "Hello world!"
		let result = IotaConverter.trytes(fromAsciiString: input)
		XCTAssertNotNil(result)
		XCTAssertEqual(result!, "RBTC9D9DCDEAKDCDFD9DSCFA")
    }
	
	func testTrytesToAscii() {
		let input = "RBTC9D9DCDEAKDCDFD9DSCFA"
		let result = IotaConverter.asciiString(fromTrytes: input)
		XCTAssertNotNil(result)
		XCTAssertEqual(result!, "Hello world!")
	}
    
}
