//
//  WebServices.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/2018.
//

import Foundation

protocol WebServices {
	static func POST(data: Dictionary<String, Any>, destination: String, successHandler: @escaping (_ response: String) -> Void, errorHandler: @escaping (_ error: NSError) -> Void)
}

protocol IotaAPIServices {
	static func nodeInfo(nodeAddress: String, _ success: @escaping (_ result: [String: Any])->Void, _ error: @escaping (_ error: Error)->Void)
	
	static func balances(nodeAddress: String, addresses: [String], _ success: @escaping (_ balances: [String: Int]) -> Void, _ error: @escaping (Error) -> Void)
	
	static func findTransactions(nodeAddress: String, addresses: [String], _ success: @escaping (_ hashes: [String]) -> Void, _ error: @escaping (Error) -> Void)
	
	static func trytes(nodeAddress: String, hashes: [String], _ success: @escaping (_ trytes: [String]) -> Void, _ error: @escaping (Error) -> Void)
}
