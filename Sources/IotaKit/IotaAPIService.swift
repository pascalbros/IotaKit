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

		service.POST(data: data, destination: nodeAddress, timeout: 3, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			success(dict)
		}, errorHandler: { err in
			error(err)
		})
	}

	static func balances(
		nodeAddress: String,
		addresses: [String],
		_ success: @escaping (_ balances: [String: Int64]) -> Void,
		_ error: @escaping (Error) -> Void) {
		balancesArray(nodeAddress: nodeAddress, addresses: addresses, { res in
			success(res.reduce(into: [String: Int64]()) { $0[$1.address] = $1.balance })
		}, { err in
			error(err)
		})
	}
	static func balancesArray(
		nodeAddress: String,
		addresses: [String],
		_ success: @escaping (_ balances: [(address: String, balance: Int64)]) -> Void,
		_ error: @escaping (Error) -> Void) {

		var data = command(withString: "getBalances")
		data["addresses"] = addresses
		data["threshold"] = 100
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			guard let balances = dict["balances"] as? [String] else {
				error(IotaAPIError("Error retrieving hashes"))
				return
			}

			var result: [(address: String, balance: Int64)] = []
			for i in 0..<balances.count {
				result.append((address: addresses[i], balance: Int64(balances[i])!))
			}
			success(result)
		}, errorHandler: { err in
			error(err)
		})
	}

	static func findTransactions(
		nodeAddress: String,
		type: IotaFindTxType,
		query: [String],
		_ success: @escaping (_ hashes: [String]) -> Void,
		_ error: @escaping (Error) -> Void) {

		var data = command(withString: "findTransactions")
		data[type.rawValue] = query
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			guard let hashes = dict["hashes"] as? [String] else {
				error(IotaAPIError("Error retrieving hashes"))
				return
			}
			success(hashes)
		},errorHandler: { err in
			error(err)
		})
	}

	static func trytes(
		nodeAddress: String,
		hashes: [String],
		_ success: @escaping (_ trytes: [IotaTransaction]) -> Void,
		_ error: @escaping (Error) -> Void) {

		var data = command(withString: "getTrytes")
		data["hashes"] = hashes
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
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
		}, errorHandler: { err in
			error(err)
		})
	}

	static func attachToTangle(
		nodeAddress: String,
		trunkTx: String,
		branchTx: String,
		minWeightMagnitude: Int = IotaConstants.mwm,
		trytes: [String],
		_ success: @escaping (_ trytes: [String]) -> Void,
		_ error: @escaping (Error) -> Void) {

		var data = command(withString: "attachToTangle")
		data["trunkTransaction"] = trunkTx
		data["branchTransaction"] = branchTx
		data["minWeightMagnitude"] = minWeightMagnitude
		data["trytes"] = trytes
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			guard let trytes = dict["trytes"] as? [String] else {
				error(IotaAPIError("Error retrieving hashes"))
				return
			}
			success(trytes)
		}, errorHandler: { err in
			error(err)
		})
	}

	static func transactionsToApprove(
		nodeAddress: String,
		depth: Int = 10,
		reference: String? = nil,
		_ success: @escaping (_ txs: (trunkTx: String, branchTx: String)) -> Void,
		_ error: @escaping (Error) -> Void) {

		var data = command(withString: "getTransactionsToApprove")
		data["depth"] = depth
		if let reference = reference {
			data["reference"] = reference
		}
		service.POST(data: data, destination: nodeAddress, timeout: 3600, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
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
		}, errorHandler: { err in
			error(err)
		})
	}

	static func broadcastTransactions(nodeAddress: String, trytes: [String], _ success: @escaping (() -> Void), _ error: @escaping (Error) -> Void) {

		var data = command(withString: "broadcastTransactions")
		data["trytes"] = trytes
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}

			if let err = dict["error"] as? String {
				error(IotaAPIError(err))
				return
			}
			if let err = dict["exception"] as? String {
				error(IotaAPIError(err))
				return
			}
			success()

		}, errorHandler: { err in
			error(err)
		})
	}

	static func storeTransactions(nodeAddress: String, trytes: [String], _ success: @escaping (() -> Void), _ error: @escaping (Error) -> Void) {

		var data = command(withString: "storeTransactions")
		data["trytes"] = trytes
		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			if let err = dict["error"] as? String {
				error(IotaAPIError(err))
				return
			}
			if let err = dict["exception"] as? String {
				error(IotaAPIError(err))
				return
			}
			success()
		}, errorHandler: { err in
			error(err)
		})
	}

	static func inclusionStates(
		nodeAddress: String,
		hashes: [String],
		tips: [String],
		_ success: @escaping (([Bool]) -> Void),
		_ error: @escaping (Error) -> Void) {

		var data = command(withString: "getInclusionStates")
		data["transactions"] = hashes
		data["tips"] = tips

		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			if let err = dict["error"] as? String {
				error(IotaAPIError(err))
				return
			}
			if let err = dict["exception"] as? String {
				error(IotaAPIError(err))
				return
			}

			if let states = dict["states"] as? [Bool] {
				success(states)
				return
			}
			error(IotaAPIError("Malformed JSON"))
		}, errorHandler: { err in
			error(err)
		})
	}

	static func checkConsistency(nodeAddress: String, hashes: [String], _ success: @escaping ((Bool) -> Void), _ error: @escaping (Error) -> Void) {

		var data = command(withString: "checkConsistency")
		data["tails"] = hashes

		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			if let err = dict["error"] as? String {
				error(IotaAPIError(err))
				return
			}
			if let err = dict["exception"] as? String {
				error(IotaAPIError(err))
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
		}, errorHandler: { err in
			error(err)
		})
	}

	static func latestInclusionStates(
		nodeAddress: String,
		hashes: [String],
		_ success: @escaping (([Bool]) -> Void),
		_ error: @escaping (Error) -> Void) {

		self.nodeInfo(nodeAddress: nodeAddress, { (nodeInfo) in
			guard let milestone = nodeInfo["latestSolidSubtangleMilestone"] as? String else { error(IotaAPIError("Error getting latest milestone")); return }
			self.inclusionStates(nodeAddress: nodeAddress, hashes: hashes, tips: [milestone], success, error)
		}, error)
	}

	static func wereAddressesSpentFrom(
		nodeAddress: String,
		addresses: [String],
		_ success: @escaping (([Bool]) -> Void),
		_ error: @escaping (Error) -> Void) {

		var data = command(withString: "wereAddressesSpentFrom")
		data["addresses"] = addresses

		service.POST(data: data, destination: nodeAddress, timeout: defaultTimeout, successHandler: { result in
			guard let dict = result.jsonToObject() as? [String: Any] else {
				error(IotaAPIError("Error converting JSON"))
				return
			}
			if let err = dict["error"] as? String {
				error(IotaAPIError(err))
				return
			}
			if let err = dict["exception"] as? String {
				error(IotaAPIError(err))
				return
			}
			if let states = dict["states"] as? [Bool] {
				success(states)
				return
			}
			error(IotaAPIError("Malformed JSON"))
		}, errorHandler: { err in
			error(err)
		})
	}
}
