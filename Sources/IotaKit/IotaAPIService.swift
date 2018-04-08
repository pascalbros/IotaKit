//
//  IotaAPIService.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/2018.
//

import Foundation

/// Carries an error message.
public struct IotaAPIError: Error {
	
	/// The error message.
	public let message: String
	
	/// The initializer for IotaAPIError.
	///
	/// - Parameter message: The error message.
	public init(_ message: String) {
		self.message = message
	}
}

class IotaAPIService: IotaAPIServices {
	
	fileprivate static let service: WebServices.Type = PAWSRequest.self
	
	fileprivate static func command(withString command: String) -> [String: Any] {
		return ["command": command]
	}
	
	fileprivate static let defaultTimeout = 60
	
	static func nodeInfo(nodeAddress: String, _ success: @escaping ([String: Any]) -> Void, _ error: @escaping (Error) -> Void) {
		
		let data = command(withString: "getNodeInfo")
	
		service.POST(data: data, destination: nodeAddress, timeout: 3, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			success(dict)
		}) { (e) in
			error(e)
		}
	}
	
	static func balances(nodeAddress: String, addresses: [String], _ success: @escaping (_ balances: [String: Int64]) -> Void, _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "getBalances")
		data["addresses"] = addresses
		data["threshold"] = 100
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			guard let balances = dict["balances"] as? [String] else {
				error(IotaAPIError("Error retrieving hashes"))
				return
			}
			
			var result: [String: Int64] = [:]
			for i in 0..<balances.count {
				result[addresses[i]] = Int64(balances[i])!
			}
			success(result)
		}) { (e) in
			error(e)
		}
	}
	
	static func findTransactions(nodeAddress: String, type: IotaFindTxType, query: [String], _ success: @escaping (_ hashes: [String]) -> Void, _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "findTransactions")
		data[type.rawValue] = query
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { (r) in
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
	
	static func trytes(nodeAddress: String, hashes: [String], _ success: @escaping (_ trytes: [IotaTransaction]) -> Void, _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "getTrytes")
		data["hashes"] = hashes
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			guard let trytes = dict["trytes"] as? [String] else {
				error(IotaAPIError("Error retrieving hashes"))
				return
			}
			var result: [IotaTransaction] = []
			for i in 0..<trytes.count {
				result.append(IotaTransaction(trytes: trytes[i]))
			}
			success(result)
		}) { (e) in
			error(e)
		}
	}
	
	static func attachToTangle(nodeAddress: String, trunkTx: String, branchTx: String, minWeightMagnitude: Int = IotaConstants.mwm, trytes: [String], _ success: @escaping (_ trytes: [String]) -> Void, _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "attachToTangle")
		data["trunkTransaction"] = trunkTx
		data["branchTransaction"] = branchTx
		data["minWeightMagnitude"] = minWeightMagnitude
		data["trytes"] = trytes
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			guard let trytes = dict["trytes"] as? [String] else {
				error(IotaAPIError("Error retrieving hashes"))
				return
			}
			success(trytes)
		}) { (e) in
			error(e)
		}
	}
	
	static func transactionsToApprove(nodeAddress: String, depth: Int = 10, reference: String? = nil, _ success: @escaping (_ txs: (trunkTx: String, branchTx: String)) -> Void, _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "getTransactionsToApprove")
		data["depth"] = depth
		if let r = reference {
			data["reference"] = r
		}
		service.POST(data: data, destination: nodeAddress, timeout: 3600, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			guard let trunkTx = dict["trunkTransaction"] as? String else {
				error(IotaAPIError("Error retrieving trunkTransaction"))
				return
			}
			guard let branchTx = dict["branchTransaction"] as? String else {
				error(IotaAPIError("Error retrieving branchTransaction"))
				return
			}
			success((trunkTx, branchTx))
		}) { (e) in
			error(e)
		}
	}
	
	static func broadcastTransactions(nodeAddress: String, trytes: [String], _ success: @escaping (() -> Void), _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "broadcastTransactions")
		data["trytes"] = trytes
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			
			if let e = dict["error"] as? String {
				error(IotaAPIError(e))
				return
			}
			if let e = dict["exception"] as? String {
				error(IotaAPIError(e))
				return
			}
			success()
			
		}) { (e) in
			error(e)
		}
	}
	
	static func storeTransactions(nodeAddress: String, trytes: [String], _ success: @escaping (() -> Void), _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "storeTransactions")
		data["trytes"] = trytes
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			if let e = dict["error"] as? String {
				error(IotaAPIError(e))
				return
			}
			if let e = dict["exception"] as? String {
				error(IotaAPIError(e))
				return
			}
			success()
		}) { (e) in
			error(e)
		}
	}
	
	static func inclusionStates(nodeAddress: String, hashes: [String], tips: [String], _ success: @escaping (([Bool]) -> Void), _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "getInclusionStates")
		data["transactions"] = hashes
		data["tips"] = tips
		
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			if let e = dict["error"] as? String {
				error(IotaAPIError(e))
				return
			}
			if let e = dict["exception"] as? String {
				error(IotaAPIError(e))
				return
			}
			
			if let states = dict["states"] as? [Bool] {
				success(states)
				return
			}
			error(IotaAPIError("Malformed JSON"))
		}) { (e) in
			error(e)
		}
	}
	
	static func checkConsistency(nodeAddress: String, hashes: [String], _ success: @escaping ((Bool) -> Void), _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "checkConsistency")
		data["tails"] = hashes
		
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			if let e = dict["error"] as? String {
				error(IotaAPIError(e))
				return
			}
			if let e = dict["exception"] as? String {
				error(IotaAPIError(e))
				return
			}
			if let state = dict["state"] as? Int {
				success(state == 1 ? true : false)
				return
			}
			
			if let state = dict["state"] as? Bool {
				success(state)
				return
			}
			error(IotaAPIError("Malformed JSON"))
		}) { (e) in
			error(e)
		}
	}
	
	static func latestInclusionStates(nodeAddress: String, hashes: [String], _ success: @escaping (([Bool]) -> Void), _ error: @escaping (Error) -> Void) {
		
		self.nodeInfo(nodeAddress: nodeAddress, { (nodeInfo) in
			guard let milestone = nodeInfo["latestSolidSubtangleMilestone"] as? String else { error(IotaAPIError("Error getting latest milestone")); return }
			
			self.inclusionStates(nodeAddress: nodeAddress, hashes: hashes, tips: [milestone], success, error)
		}, error)
	}
	
	static func wereAddressesSpentFrom(nodeAddress: String, addresses: [String], _ success: @escaping (([Bool]) -> Void), _ error: @escaping (Error) -> Void) {
		
		var data = command(withString: "wereAddressesSpentFrom")
		data["addresses"] = addresses
		
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { (r) in
			guard let dict = r.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			if let e = dict["error"] as? String {
				error(IotaAPIError(e))
				return
			}
			if let e = dict["exception"] as? String {
				error(IotaAPIError(e))
				return
			}
			
			if let states = dict["states"] as? [Bool] {
				success(states)
				return
			}
			error(IotaAPIError("Malformed JSON"))
		}) { (e) in
			error(e)
		}
	}
}
