//
//  IotaAPIService.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/2018.
//

import Foundation

struct IotaAPIError: Error {
	
	let message: String
	init(_ message: String) {
		self.message = message
	}
}

class IotaAPIService: IotaAPIServices {
	
	fileprivate static let service: WebServices.Type = PAWSRequest.self
	
	fileprivate static func command(withString command: String) -> [String: Any] {
		return ["command": command]
	}
	
	static func nodeInfo(nodeAddress: String, _ success: @escaping ([String: Any]) -> Void, _ error: @escaping (Error) -> Void) {
		
		let data = command(withString: "getNodeInfo")
	
		service.POST(data: data, destination: nodeAddress, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			success(dict)
		}) { (e) in
			error(e)
		}
	}
	
	static func balances(nodeAddress: String, addresses: [String], _ success: @escaping (_ balances: [String: Int]) -> Void, _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "getBalances")
		data["addresses"] = addresses
		data["threshold"] = 100
		service.POST(data: data, destination: nodeAddress, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			guard let balances = dict["balances"] as? [String] else {
				error(IotaAPIError("Error retrieving hashes"))
				return
			}
			
			var result: [String: Int] = [:]
			for i in 0..<balances.count {
				result[addresses[i]] = Int(balances[i])!
			}
			success(result)
		}) { (e) in
			error(e)
		}
	}
	
	static func findTransactions(nodeAddress: String, addresses: [String], _ success: @escaping (_ hashes: [String]) -> Void, _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "findTransactions")
		data["addresses"] = addresses
		service.POST(data: data, destination: nodeAddress, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			guard let hashes = dict["hashes"] as? [String] else {
				error(IotaAPIError("Error retrieving hashes"))
				return
			}
			success(hashes)
		}) { (e) in
			error(e)
		}
	}
	
	static func trytes(nodeAddress: String, hashes: [String], _ success: @escaping (_ trytes: [String: String]) -> Void, _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "getTrytes")
		data["hashes"] = hashes
		service.POST(data: data, destination: nodeAddress, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			guard let trytes = dict["trytes"] as? [String] else {
				error(IotaAPIError("Error retrieving hashes"))
				return
			}
			var result: [String: String] = [:]
			for i in 0..<hashes.count {
				print(IotaConverter.transactionObject(trytes: trytes[i]))
				result[hashes[i]] = trytes[i]
			}
			success(result)
		}) { (e) in
			error(e)
		}
	}
}
