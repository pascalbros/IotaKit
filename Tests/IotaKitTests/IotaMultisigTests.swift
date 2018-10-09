//
//  IotaMultisigTests.swift
//  IotaKitTests
//
//  Created by Pasquale Ambrosini on 07/03/18.
//

import XCTest

class IotaMultisigTests: XCTestCase {
	
	let TEST_SEED1 = "ABCDFG"
	let TEST_SEED2 = "FDSAGB"
	let RECEIVE_ADDRESS = "IJWHCMVMEHLRKNGJWJFBIXROGWXUYSNESUAGBOWDKFJLUFOLPMNHUQQNGISDDWNDMXYBXGXLFWLDNGAFBPQLVRGPHB"
	let REMAINDER_ADDRESS = "QWMCMMRKDBSQSN9NHVFZYBVBNMABHZDFCLDCBBZUWMGLLZVEFFOCMZLFMVZZHXCMQAEPVCOMERQYOQNSB"
	let TEST_TAG = "IOTAKIT"
	let ADDRESS = "https://nodes.iota.cafe:443"
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAddressGeneration() {
		let multisig = IotaMultisig(node: ADDRESS)
		var digests: [String] = []
		digests.append(multisig.digest(seed: TEST_SEED1, security: 3, index: 0))
		digests.append(multisig.digest(seed: TEST_SEED2, security: 3, index: 0))
		let address = multisig.address(fromDigests: digests)
		print(address)
		XCTAssertEqual(address, "JYQOVXIR9GDQMWXBYVZW9FYVQJWXLCXXCYJHOYRVW9NKBNZEVYITXXSRFANMIUNOSVEGUMETUZC9EAPOX")
		XCTAssert(multisig.validate(address: address, digests: digests), "Invalid multisig address")
    }
	
	func testSigning() {
		
		let expectation = XCTestExpectation(description: "testSigning multisig test")
		
		let multisig = IotaMultisig(node: ADDRESS)
		
		multisig.debug = true
		var digests: [String] = []
		digests.append(multisig.digest(seed: TEST_SEED1, security: 2, index: 0))
		digests.append(multisig.digest(seed: TEST_SEED2, security: 2, index: 0))
		let address = multisig.address(fromDigests: digests)
		
		var keys: [String] = []
		keys.append(multisig.key(seed: TEST_SEED1, security: 2, index: 0))
		keys.append(multisig.key(seed: TEST_SEED2, security: 2, index: 0))
		
		var transfers: [IotaTransfer] = []
		transfers.append(IotaTransfer(address: address, value: 1, message: "", tag: TEST_TAG))
		multisig.prepareTransfers(securitySum: 4, inputAddress: address, remainderAddress: REMAINDER_ADDRESS, transfers: transfers, keys: keys, skipChecks: true, { (bundle) in
			let isValid = multisig.validateSignature(signedBundle: bundle, inputAddress: address)
			XCTAssertTrue(isValid)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
		}
		
		wait(for: [expectation], timeout: 130)
	}
	
	func testTransfer() {
		let expectation = XCTestExpectation(description: "testTransfer multisig test")
		
		let multisig = IotaMultisig(node: ADDRESS)
		
		multisig.debug = true
		var digests: [String] = []
		digests.append(multisig.digest(seed: TEST_SEED1, security: 2, index: 0))
		digests.append(multisig.digest(seed: TEST_SEED2, security: 2, index: 0))
		let address = multisig.address(fromDigests: digests)
		
		var keys: [String] = []
		keys.append(multisig.key(seed: TEST_SEED1, security: 2, index: 0))
		keys.append(multisig.key(seed: TEST_SEED2, security: 2, index: 0))
		
		var transfers: [IotaTransfer] = []
		transfers.append(IotaTransfer(address: RECEIVE_ADDRESS, value: 1, message: "", tag: TEST_TAG))
		
		multisig.sendTransfers(securitySum: 4, inputAddress: address, remainderAddress: REMAINDER_ADDRESS, transfers: transfers, keys: keys, skipChecks: true, { (transactions) in
			print(transactions)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
		}
		
		wait(for: [expectation], timeout: 240)
	}
	
	func testAttachToTangle() {
		let expectation = XCTestExpectation(description: "testAttachToTangle multisig test")
		
		let multisig = IotaMultisig(node: ADDRESS)
		
		multisig.debug = true
		var digests: [String] = []
		digests.append(multisig.digest(seed: TEST_SEED1, security: 2, index: 0))
		digests.append(multisig.digest(seed: TEST_SEED2, security: 2, index: 0))
		let address = multisig.address(fromDigests: digests)
		
		var keys: [String] = []
		keys.append(multisig.key(seed: TEST_SEED1, security: 2, index: 0))
		keys.append(multisig.key(seed: TEST_SEED2, security: 2, index: 0))
		
		multisig.attachToTangle(securitySum: 4, address: address, keys: keys, { (transactions) in
			print(transactions)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
		}
		
		wait(for: [expectation], timeout: 240)
	}
	
	func testAccountData() {
		let addresses: [String] = [
		"9STCQJBVTQOVZNDRRDJFDKWLEDJZZHOWYCYNXDIIGKTTDSWXDL9WHTVKENCVIXBHYOXMFULNPOLFNKDIY",
		"UVXUINMAODVNSZHZTFZLBVPHMEBCCUHXUZMPLEFNJGEDFU9ARH9N9RPCUIIORTGNUKRNWECFQF9PACHTX",
		"VLCTDOELQI9GUXJTMWRXBUUJTFGRFWNOUYMXQQOFTLCIRHQTXLIGTPPMGQVSIQOJDTIZ9Z9RPTTXHTSVW",
		"LCDYCUUVEUIITECXJQQFBK9CLJMI9TXPAJSTPYOIUKESYM9IXSNJZBXJFDEJORLNCCGILHLOGTTWZBHHX",
		"KLSL9QGRRXKUIIAWAJPVPIDNXJWMRQCASDLLMWDVKXSNZMVTTKOKSYWDNRKNASYBLZMKIMZDQCCWTVGEY",
		"MGCWBYECVVODPGFDWZKNJLBLBPAMMRLQEBKHGXCQJZEIIIZASQPZCL9PMEI9YWKOWHDGGCURWQXLUUVPX",
		"QNJIMQUNZKPRVLVNZLCMCBGGMEZIMXLMFHQUPSWWYLSBVIA9TJYVNEFRZAUGSTLBACAOISHAXEPNXSAFD",
		"XKCEFYBVRVAUTKI9TFEPBIZINQ99RGLMFVIKLHSJE9DTSTM9QIPNNNWFTKXYJHRHBIPWFWXZMZRGYQWTX",
		"KJYIURRYBDKWVTWJLSELEDIHPZMMYJZCGJSJKTYWRUGDAHZRKPQATMBCGOMEQMLEHZDFJHSYP99OBRSNA",
		"ORN9BXPLZRTSP9HMELJQDEVJUULEDKBGELHCGMSBMPSZPLBQSFKCEYYAFVQTHDFJNZZFNYCPSTAWZY9SA",
		"ZNNKDKHYPULCUCQJ9TQQVNJDQSOTDLNGEKPRREJEXJAVYXKUKYWKWNDDHMMHKIEZLGIVAHXARFLCTORVX",
		"GTDXDJHCLKUINSJMVLUQCEEPDICNBPLZHTGUQXDIFOHEZASUEPZNQPE9KHE9LWSTJBMKHO9ECANABWEUX",
		"YIV9EULUXLHPJPHWUGMEUUNO9PWFSCD9DFPFUTWXPTHSAA9WSYHKBNRRHLJOXLZWISXXNFW9HCTDDCNZY",
		"NBOBXGACRWZOYSVUIQBESDDHKVGEFMFOVFMZFVTQU9SGKYBFPPIOYBQKZ9FYXGAKWREDWUPFSSYCFEDIC",
		"LWBLWSAAXHWPJXPZNNIGMIVSLCUX9VXUFTHWFDZCEQYXYC9LLJPVORJCLGGMDYLPBQVNKHKTTILDDBAWD",
		"CPNKPLOZLQMYEFIM9L9IKPDPQTSXHUMALVRFQCYBNEABY9ANUFRBMUVYOFULUOUWJLGPVABYNKLLACEZW",
		"PACDPG9IJCPWH9STICDDANFRJTZZ9J9IHXBOWZDFD9C9LFUGOITDGSUSELIUVXVZZWVOLYFLPVGTINNMB",
		"PVLYPHIZS9OORL9MNHN9XFGVAHKGIAYCHGFYYTIAFQMBNXYCLCCPNVSJCMADP9ETQJGYNMYWXFRYNDWAB",
		"NECPBHBACPOQPAFKYXQRYIRGBYZEWRN9OWLFEVOGFTJNKAOUKKUJTVNKKYVUIEVQXOLD9H9WBPCKSWCRD",
		"9WDLUVZKNEZUKCWTUCKTMMUAVSXNTMFMBBOYMEBIEHOFZPMPGV9HMUHYERRLNW9YLQFKEYKIMEDUVQTXY"
		]
		
		let expectation = XCTestExpectation(description: "testAccountData multisig test")
		
		let multisig = IotaMultisig(node: ADDRESS)
		multisig.debug = true
		multisig.accountData(addresses: addresses, requestTransactions: true, { (account) in
			XCTAssertEqual(12, account.addresses.count)
			expectation.fulfill()
		}, error: { (error) in
			XCTFail(error.localizedDescription)
			expectation.fulfill()
		})
		wait(for: [expectation], timeout: 60)
	}
}
