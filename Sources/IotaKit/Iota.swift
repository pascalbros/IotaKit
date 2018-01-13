//
//  Iota.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/2018.
//

import Foundation

public class Iota {
	
	fileprivate let address: String
	
	public init(node: String, port: UInt) {
		self.address = node.appending(":").appending(String(port))
	}
	
	public func nodeInfo(_ success: @escaping ([String: Any]) -> Void, error: @escaping (Error) -> Void) {
		IotaAPIService.nodeInfo(nodeAddress: self.address, success, error)
	}
	
	public func balances(addresses: [String], _ success: @escaping (_ balances: [String: Int]) -> Void, error: @escaping (Error) -> Void) {
		IotaAPIService.balances(nodeAddress: self.address, addresses: addresses, success, error)
	}
	
	public func findTransactions(addresses: [String], _ success: @escaping (_ hashes: [String]) -> Void, error: @escaping (Error) -> Void) {
		IotaAPIService.findTransactions(nodeAddress: self.address, addresses: addresses, success, error)
	}
	
	public func trytes(hashes: [String], _ success: @escaping (_ trytes: [String: String]) -> Void, error: @escaping (Error) -> Void) {
		IotaAPIService.trytes(nodeAddress: self.address, hashes: hashes, success, error)
	}
	
	public func accountData(seed: String, _ success: @escaping (_ account: IotaAccount) -> Void, error: @escaping (Error) -> Void) {
		
		var account = IotaAccount()
		var index = 0
		var lastAddress = ""
		
		func findBalances() {
			self.balances(addresses: account.addresses, { (balances) in
				account.balance = balances.reduce(0, { (r, e) -> Int in return r+e.value })
				success(account)
			}) { (e) in
				error(e)
			}
		}
		
		func findTransactions() {
			let address = IotaAPIUtils.newAddress(seed: seed, security: 2, index: index, checksum: false)
			IotaAPIService.findTransactions(nodeAddress: self.address, addresses: [address], { (hashes) in
				if hashes.count == 0 {
					findBalances()
				}else{
					account.addresses.append(address)
					DispatchQueue.main.async {
						index += 1
						findTransactions()
					}
				}
			}) { (e) in
				error(e)
			}
		}
		
		findTransactions()
	}
}
