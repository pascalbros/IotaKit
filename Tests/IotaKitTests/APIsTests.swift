//
//  APIsTests.swift
//  IotaKitTests
//
//  Created by Pasquale Ambrosini on 18/01/18.
//

import XCTest
import IotaKit

class APIsTests: XCTestCase {
	
	let iota = Iota(node: "http://iota-tangle.io:14265")
	private let TEST_SEED1 = "XDSCF9LACCU9EMAMWLZUTYLDSRP9BCBYJEDWERJPADUZQFCCPWUMFUYMJLHLJHJ9NGZXMCKGCHBFCUPAL";
	private let TEST_ADDRESS_WITHOUT_CHECKSUM_SECURITY_LEVEL_2 = "ADVFOBBFMSHUTBLHESNRFIZYFVZNDOJV9QSSABSXEYLHKVCEGGWOZGLMLQLYKJNGSBIEYDW9YFJFAMBWA";
	private let TEST_ADDRESS_WITH_CHECKSUM_SECURITY_LEVEL_2 = "ADVFOBBFMSHUTBLHESNRFIZYFVZNDOJV9QSSABSXEYLHKVCEGGWOZGLMLQLYKJNGSBIEYDW9YFJFAMBWACBBTKTGRB";
	private let TEST_MESSAGE = "IOTAKITTEST";
	private let TEST_TAG = "IOTAKIT99999999999999999999";
	private let MIN_WEIGHT_MAGNITUDE = 14;
	private let DEPTH = 9;
	
	override func setUp() {
		iota.debug = true
	}
	
	func testNodeInfo() {
		let expectation = XCTestExpectation(description: "testNodeInfo test")
		
		iota.nodeInfo({ (node) in
			print(node)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 120.0)
	}
	
	func testAccountData() {
		let expectation = XCTestExpectation(description: "testAccountData test")
		
		iota.accountData(seed: TEST_SEED1, { (account) in
			print(account)
			expectation.fulfill()
		}, error: { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		})
		wait(for: [expectation], timeout: 120.0)
	}
	
	func testAccountDataRequestingTransactions() {
		let expectation = XCTestExpectation(description: "testAccountData test")
		
		iota.accountData(seed: TEST_SEED1, requestTransactions: true, { (account) in
			print(account)
			expectation.fulfill()
		}, error: { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		})
		wait(for: [expectation], timeout: 120.0)
	}
	
	func testAttachToTangle() {
		let expectation = XCTestExpectation(description: "testAccountData test")
		iota.attachToTangle(seed: self.TEST_SEED1, index: 0, security: 2, { (tx) in
			print(tx)
			expectation.fulfill()
		}, error: { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		})
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testAttachToTangleWithNewAddress() {
		let expectation = XCTestExpectation(description: "testAccountData test")
		
		func attach(index: Int) {
			iota.attachToTangle(seed: self.TEST_SEED1, index: index, security: 2, { (tx) in
				print(tx)
				expectation.fulfill()
			}, error: { (error) in
				print(error)
				expectation.fulfill()
			})
		}
		
		iota.accountData(seed: self.TEST_SEED1, { (account) in
			attach(index: account.addresses.count)
		}, error: { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
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
	
	func testPrepareTransfers() {
		let expectation = XCTestExpectation(description: "testPrepareTransfers test")
		let transfers = [IotaTransfer(address: TEST_ADDRESS_WITHOUT_CHECKSUM_SECURITY_LEVEL_2, value: 0, timestamp: nil, hash: nil, persistence: false, message: TEST_MESSAGE, tag: TEST_TAG)]
		
		iota.sendTransfers(seed: TEST_SEED1, security: 2, depth: DEPTH, minWeightMagnitude: MIN_WEIGHT_MAGNITUDE, transfers: transfers, inputs: nil, remainderAddress: nil, { (txs) in
			print(txs)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testPrepareTransfersWithValue() {
		let expectation = XCTestExpectation(description: "testPrepareTransfersWithValue test")
		let transfers = [IotaTransfer(address: TEST_ADDRESS_WITH_CHECKSUM_SECURITY_LEVEL_2, value: 10, timestamp: nil, hash: nil, persistence: false, message: TEST_MESSAGE, tag: TEST_TAG)]
		
		iota.prepareTransfers(seed: self.TEST_SEED1, security: 2, transfers: transfers, remainder: nil, inputs: nil, validateInputs: false, { (result) in
			print(result)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testSendTransferWithValue() {
		let expectation = XCTestExpectation(description: "testPrepareTransfersWithValue test")
		let transfers = [IotaTransfer(address: TEST_ADDRESS_WITH_CHECKSUM_SECURITY_LEVEL_2, value: 1, timestamp: nil, hash: nil, persistence: false, message: TEST_MESSAGE, tag: TEST_TAG)]
		
		iota.sendTransfers(seed: TEST_SEED1, security: 2, depth: DEPTH, minWeightMagnitude: MIN_WEIGHT_MAGNITUDE, transfers: transfers, inputs: nil, remainderAddress: nil, { (txs) in
			print(txs)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testFindTransactions() {
		let expectation = XCTestExpectation(description: "testFindTransactions test")
		
		iota.findTransactions(addresses: ["UVXUINMAODVNSZHZTFZLBVPHMEBCCUHXUZMPLEFNJGEDFU9ARH9N9RPCUIIORTGNUKRNWECFQF9PACHTX"], { (hashes) in
			print(hashes)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testCheckConsistency() {
		let expectation = XCTestExpectation(description: "testFindTransactions test")

		IotaAPIService.checkConsistency(nodeAddress: "http://iota-tangle.io:14265", hashes: ["YHDBPGHRSGHNKQECDPLTLXJBTRWIMYICNCOQCGTDNVIRXZICGMQTAECHQNVKQJYHHCDVGXZTCYLR99999"], { (result) in
			print(result)
		}) { (error) in
			print(error)
		}
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testGetTransactionTrytes() {
		let expectation = XCTestExpectation(description: "testFindTransactions test")
		
		iota.trytes(hashes: ["PTKBSAQULPCOCJBUUCLBLASHPAZVOYQGHOKEBOELLCAAZTMNJZJPHBREXLORXWWARTMVIFQ9HNOT99999", "REJJFSYOARFQAJLTUDGI9PKRUZFUO9KVAM9YFWTQELJSGPBMS9QQPECLSS9MZH9PPDO9EWHRLJRDZ9999", "EYL9DPXYUAPGCVQHMYCLSAMOOFJZARRUYZFGHLIBGTRFXGS9NORUVQBULWBXTRJBSQHYPBXYFMNBZ9999", "KWXLWQNSMLMCY9JUDWMKJ9ZH9EYACWPPDTLVATDTGSUCGRSWNMYKCNSXA9GM9QUHBNRINSRBFDPPZ9999", "IKXZNIAFTYSABDABTAASBUO9KBRKIMKIBHWJBODP9BZVDZFKDHEWQHMBVJFYNJSHHHOALXQYHDSJZ9999", "FQEWOKJEQSBTVVKXCMEJLQLHPMJURJBHKYVWYGWADGTTLNOJULB9GNLPURDFUGYIKFLYRVUHUPOCZ9999", "SYKAHYBU9CJMXNYAWNKIGYMBXHLCDGTYMB9LJBJSORPFI9FIVJUIPONPGIAS9LKCYOFTJZMGYIOFA9999", "MMQRX9UNVXZHHYRWDUGLOQWLPBQAR9JDKS9TWVTJDXPGPKJMZZVKKZHC9NEWMCBL9ZMBXGSVFUSVA9999", "OHYQVWPFLMTCTAODXGRZUKFBTKFSCRXGRZHRQVDOFZSUOTLFAQTVDPCANAIAHFJKPYYCWQREYXQW99999", "GSYVJVVPTKGQPX9UFTWIMGUMIDWSCQMKTFJBMCMXWNARCUOMTENEZZTUJKXIBVZETBUSPWFFAVIFA9999"], { (transactions) in
			print(transactions)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testTransactionsFromAddress() {
		let expectation = XCTestExpectation(description: "testReplayBundle test")
		
		iota.transactionsFromAddress(address: "WUXXDPJTYVJ9LP9UAKLUACKPKZSCZKBPIZYKIRALGXRIDPUVFJOVGNKYCOFJBACIZGJWTSRZLLMOUPIQZ", { (txs) in
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
		
		iota.replayBundle(tx: "EWJJQNDEZBXLKIXGCCFEYBPMGENUCPRYMWQCSMONJSDXDQKRSWEVCUJSXLMDKNHYHGBSOXGVDDQG99999", { (txs) in
			print(txs)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testLatestInclusionStates() {
		let expectation = XCTestExpectation(description: "testReplayBundle test")
		
		iota.latestInclusionStates(hashes: ["PTKBSAQULPCOCJBUUCLBLASHPAZVOYQGHOKEBOELLCAAZTMNJZJPHBREXLORXWWARTMVIFQ9HNOT99999", "REJJFSYOARFQAJLTUDGI9PKRUZFUO9KVAM9YFWTQELJSGPBMS9QQPECLSS9MZH9PPDO9EWHRLJRDZ9999", "EYL9DPXYUAPGCVQHMYCLSAMOOFJZARRUYZFGHLIBGTRFXGS9NORUVQBULWBXTRJBSQHYPBXYFMNBZ9999", "KWXLWQNSMLMCY9JUDWMKJ9ZH9EYACWPPDTLVATDTGSUCGRSWNMYKCNSXA9GM9QUHBNRINSRBFDPPZ9999", "IKXZNIAFTYSABDABTAASBUO9KBRKIMKIBHWJBODP9BZVDZFKDHEWQHMBVJFYNJSHHHOALXQYHDSJZ9999", "FQEWOKJEQSBTVVKXCMEJLQLHPMJURJBHKYVWYGWADGTTLNOJULB9GNLPURDFUGYIKFLYRVUHUPOCZ9999", "SYKAHYBU9CJMXNYAWNKIGYMBXHLCDGTYMB9LJBJSORPFI9FIVJUIPONPGIAS9LKCYOFTJZMGYIOFA9999", "MMQRX9UNVXZHHYRWDUGLOQWLPBQAR9JDKS9TWVTJDXPGPKJMZZVKKZHC9NEWMCBL9ZMBXGSVFUSVA9999", "OHYQVWPFLMTCTAODXGRZUKFBTKFSCRXGRZHRQVDOFZSUOTLFAQTVDPCANAIAHFJKPYYCWQREYXQW99999", "GSYVJVVPTKGQPX9UFTWIMGUMIDWSCQMKTFJBMCMXWNARCUOMTENEZZTUJKXIBVZETBUSPWFFAVIFA9999"], { (result) in
			print(result)
			expectation.fulfill()
		}) { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 1200.0)
	}
	
	func testMe() {
		let tx = IotaTransaction(trytes: "MRZOQWOTMFCKHXDTOJUSSQUPUWZKDCIHZZQGXCASITQHCSLMPVR9HGYFLRTWFCLCOUCEUEEAGTUDJERNBBEOQNAMFPMISWIOKSGINYHFDXOCATPVUOTCFR9ZOIIOOTDQAWF9CLIPVNAVV9WRZWT9CZGEW9NIPSWSZB99BUOC9UDHINYIXTNDQTUPLZOAFFXOKCYWHCNZTZTTFLIKRAQIPFBYTQSYKLAKKDHTQI9JPLINJWYOHEDJD9RJRLZIGYCPEEQCKXZUDADNXMEBAUCLAD9BJYHNAGZBYZXVHRUCXQH9ZZMLTGJQZFZSFNEPMEPRZYCCXORJAVTJOPJFLJFQZMAQUSFUVEQBLEDVALPPSOYVIRYSLAFLZAINRPNWXCWUZEEWSHCKNQV9XGAMUUQMZNU9HTH9HIMTL9NOJMUJUNCNRQBTXHB9ENGNJJSY9OKEUUJYQDIETIMBPLNHQCDGXLOVSAW9W9QFGKVOMWEKHHIMDCCAFFQABRPFKKZGFDQ9LQZDFCBBNHFYRZXULOVRSKURIAUNBHMRYCVMZFXZSAVLMYXVVPIEYGCPESKSPRJCCLJOCYYWRFWNKSSAIOZGPBJE9ZMCEHM9BXIQETCFAWWGMLFUFCABWEHTAEOISE9PSRIHHOEZDRDOAJJAYBJGGROFXRGUSSS9LVBDBCLNFUUOEKACUVPLVWIMXTXT9IHUZOMFGDNMPOEETKLONZROBZBBBFVWCFIGRHORQITHITDO9HSIBJQOWGXALWNSTBLB9HFCYRXXNPOARRWJCXZ9GVHFUYXCKFBKBANMMQUVZAUFYUEICPIKZPVRHYVCYKKEVTVSQOSXOWWBLUCKOBOESCDSEIP9GFKOZXEGM9GEWGXCHJN99DZBIWXCNKWE9XDBRIF9TIKYLFTXJEHAL9EDZREOMHQJXMS9OHOQKSCDQJABRDGSOJB9MBXDWTSNKXLAREENDGDSBVAYVLXFFXJRDFYMTYGVSLWTCQANZUCFKXHNBIAIXIVAMDYCALVMLWPQWU9ULFJFEOISTFBVLHTEBPGCSBBN9VYOECIKD9T9EGJKFTJKQGKRPB99LFTBDEQBFGFRTSBUSYUOJPFZ9XDQNLVBDJSLTOTAOZRLYFHIVUCRRYJWRDOTPQSQDQPNAKQKITLVVTTFCUUBTRDALGMJAOPMLDRRZKLGDZFEWDODDGLCCSJGJDYMYUDGMKHUIQ9PDISBFYQGRTAMSMO9DBSZUC9YCIHVMELKY9XAIKCDIEAHVGHBBALYUAEZKHBHEWPGWJAUWXYXCUNSLHQXMEMTLDEMOSZNNZILJPMNNWUXRG9HTRGLKKSPMWXYKJ9FGZWVVVRVP9RKZNUJAUHCNAFTHIWHQFMUOKGPCQWQHQYQMLQLJRXOPOFY9ZNXATRNXELECAYXEKQFMNRQUDJ9XRFDEGAXCJWIEXDQBAJZAOFNNWJHQTIGKYGSNBIZPF9KTLZZEZMQHHATGGVPYGEGJRQCVLVXVJYMJOXWLTNZVLAHBGOFDPNYIEYYAZURDGCMIWIOYMZENAWBGATXTUJVNSAAACARXMUSTKCSNLWBIVLZG9BVMVXFAIFLPDETDVJKQTLRHUJGNVEHHSAWLOPKUTUDXEDJTKDXMYXQMVDTHLDVNAYYKLGXUICB9TSBOEDATXMRGINCENKAZERUJVYRJJSYHF9ZVKQONMGGKJ9OWETSZVEUGFSTAWCVPMVQPGADHTYJAVDAUGKICJHAQLLH9GHRUFFOOOAUQKDWRHRSVUJMUGBG9DGPOXZITCSXWWIWSXTSYIALOJCUGITHRUHMGXOWIMCRXXYAVBTFN9XUSBSJTNWKRORY9PTXYSMBIXWFESFNNVIAREWWHNYOOJBHNWQZAUPNHDEBBHIZSRTSEA9ILLSHBRNMMJAKXBQHTJJMAJML9TT99XPLCDKGWLAKVKOSVEEX9OYKHRXYZQKWDENSKNGXFFNTVOLZ9OEAPTJFVNKUFWQQYHCNXNEYSA9AZBMMOTGBDOXQFEJEURBFIAAR9YW9GZRSREMHXDU99FAIEK9MXTMWQCXUICNKCZGGKKZ99LMBOFQJNATFTJSFAIDVTQYJZOXJNNTLXAPGQCGWCFZBFSYJXDAZSKLDPCFHAIBGENDUHOWISTYHWPNOL9TFAUWMLXUJQCQNJUOFWVLRVUQSXJLVOOTTRTDNTVNTETSRMANXIZKABMMYGVMCMWPGCUHFQHI9YNYJHIIOONMDLXYRSTCHTEGPGHUIIXFXXPCMXNMVMK99999999999999999999999999999IOTAKIT99999999999999999999HZHVSYD99999999999999999999QCZEULBZDTXGUURJUIWHOX9BRDAIIKBHCKUNITFHOITKIIOSJPBQYKNDPJAREJNWWX9TZGLRVBGTLXLQD999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999IOTAKIT999999999999999999999CGRSPC999CGRSPC999CGRSPC99999999999999999999999999999")
		print(tx)
	}
	
	func testGroupTxsByBundle() {
		let expectation = XCTestExpectation(description: "testAccountData test")
		
		iota.accountData(seed: TEST_SEED1, requestTransactions: true, { (account) in
			//let txs = account.addresses.map { $0.transactions! }.flatMap { $0 }
			let result = IotaAPIUtils.historyTransactions(addresses: account.addresses).reversed()
			for tx in result {
				print("Value:\(tx.value) Persistence:\(tx.persistence) Reattaches:\(tx.transactions.count) \(Date(timeIntervalSince1970: TimeInterval(tx.timestamp)) )")
			}
			
			expectation.fulfill()
		}, error: { (error) in
			print(error)
			assertionFailure((error as! IotaAPIError).message)
			expectation.fulfill()
		})
		wait(for: [expectation], timeout: 1200.0)
	}
	
	
	static var allTests = [
		("testSendTrytes", testSendTrytes),
		("testAttachToTangle", testAttachToTangle),
		("testAccountData", testAccountData),
		("testReplayBundle", testReplayBundle)
	]
}

