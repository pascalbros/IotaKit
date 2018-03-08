//
//  IotaMultisigTests.swift
//  IotaKitTests
//
//  Created by Pasquale Ambrosini on 07/03/18.
//

import XCTest

class IotaMultisigTests: XCTestCase {
	
	let TEST_SEED1 = "ABCDFG"
	let TEST_SEED2 = "FDSAG"
	
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAddressGeneration() {
        let multisig = IotaMultisig()
		var digests: [String] = []
		digests.append(multisig.digest(seed: TEST_SEED1, security: 3, index: 0))
		digests.append(multisig.digest(seed: TEST_SEED2, security: 3, index: 0))
		let address = multisig.address(fromDigests: digests)
		print(address)
		XCTAssertEqual(address, "JYQOVXIR9GDQMWXBYVZW9FYVQJWXLCXXCYJHOYRVW9NKBNZEVYITXXSRFANMIUNOSVEGUMETUZC9EAPOX")
    }
}
