//
//  APIsTests.swift
//  IotaKitTests
//
//  Created by Pasquale Ambrosini on 18/01/18.
//

import XCTest
import IotaKit

class APIsTests: XCTestCase {
	
	let iota = Iota(node: "http://iotanode.party:14265")
	private let TEST_SEED1 = "KRRFGGJXUGCMJILWECFVW9XKWIFDBDRKFCPLZEGJVTZDDJWJZ9VBLGGKPGLQJWK99TVPXBISKAMCBCQEK";
	//private static final String TEST_ADDRESS_WITHOUT_CHECKSUM_SECURITY_LEVEL_2 = "LXQHWNY9CQOHPNMKFJFIJHGEPAENAOVFRDIBF99PPHDTWJDCGHLYETXT9NPUVSNKT9XDTDYNJKJCPQMZC";
	private let TEST_ADDRESS_WITHOUT_CHECKSUM_SECURITY_LEVEL_2 = "ADQYBMQBOCGWQTAVXI9HYKPMMYKHTRHXMQOJFVGYTY9CZUZVQXAIFVZXZXLSOOOQKVORXZITSNGHCDJYD";
	private let TEST_MESSAGE = "";
	private let TEST_TAG = "";
	private let MIN_WEIGHT_MAGNITUDE = 14;
	private let DEPTH = 9;
	
	override func setUp() {
		iota.debug = true
	}
	
	func testAccountData() {
		let expectation = XCTestExpectation(description: "testAccountData test")
		
		iota.accountData(seed: TEST_SEED1, { (account) in
			print(account)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 120.0)
	}
	
	func testAttachToTangle() {
		let expectation = XCTestExpectation(description: "testAccountData test")
		iota.attachToTangle(seed: self.TEST_SEED1, index: 0, security: 2, { (tx) in
			print(tx)
			expectation.fulfill()
		}, error: { (error) in
			print(error)
			expectation.fulfill()
		})
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testSendTrytes() {
		let expectation = XCTestExpectation(description: "testSendTrytes test")
		let transfers = [IotaTransfer(address: TEST_ADDRESS_WITHOUT_CHECKSUM_SECURITY_LEVEL_2, value: 0, timestamp: nil, hash: nil, persistence: false, message: TEST_MESSAGE, tag: TEST_TAG)]
		
		iota.sendTransfers(seed: TEST_SEED1, security: 2, depth: DEPTH, minWeightMagnitude: MIN_WEIGHT_MAGNITUDE, transfers: transfers, inputs: nil, remainderAddress: "", { (txs) in
			print(txs)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testReplayBundle() {
		let expectation = XCTestExpectation(description: "testReplayBundle test")
		
		iota.replayBundle(tx: "BKBALUPMEECOGEYQU9OHXTFTHV9OKEVUGHAUNNQCNETAQWIRJIKDGWSWXY9RSIMZJBPIPEIQEFEIA9999", { (txs) in
			print(txs)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 1200.0)
	}
	
	
	static var allTests = [
		("testSendTrytes", testSendTrytes),
		("testAttachToTangle", testAttachToTangle),
		("testAccountData", testAccountData),
		("testReplayBundle", testReplayBundle)
	]
}

