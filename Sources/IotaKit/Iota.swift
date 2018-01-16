//
//  Iota.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/2018.
//

import Foundation

public class Iota {
	
	fileprivate(set) var address: String = ""
	public var debug = false
	
	public init(prefersHTTPS: Bool = false, _ onReady: @escaping (Iota?) -> Void) {
		IotaNodeSelector.bestNode({ (nodes) in
			var add = nodes.first!.fullAddress
			if prefersHTTPS {
				for n in nodes {
					if !n.address.hasPrefix("https") {
						continue
					}
					add = n.fullAddress
					break
				}
			}
			self.address = add
			onReady(self)
		}) { (error) in
			onReady(nil)
		}
	}
	
	public init(node: String, port: UInt) {
		self.address = node.appending(":").appending(String(port))
	}
	
	public init(node: String) {
		self.address = node
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
	
	public func trytes(hashes: [String], _ success: @escaping (_ trytes: [IotaTransaction]) -> Void, error: @escaping (Error) -> Void) {
		IotaAPIService.trytes(nodeAddress: self.address, hashes: hashes, success, error)
	}
	
	public func accountData(seed: String, _ success: @escaping (_ account: IotaAccount) -> Void, error: @escaping (Error) -> Void) {
		
		var account = IotaAccount()
		var index = 0
		var lastAddress = ""
		
		func findBalances() {
			IotaDebug("Getting balances")
			self.balances(addresses: account.addresses, { (balances) in
				self.IotaDebug("Got balances \(balances.count)")
				account.balance = balances.reduce(0, { (r, e) -> Int in return r+e.value })
				success(account)
			}) { (e) in
				error(e)
			}
		}
		
		func findTransactions() {
			let address = IotaAPIUtils.newAddress(seed: seed, security: 2, index: index, checksum: false)
			IotaDebug("Getting transactions")
			IotaAPIService.findTransactions(nodeAddress: self.address, addresses: [address], { (hashes) in
				self.IotaDebug("Got transactions \(hashes.count)")
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
	
	public func prepareTransfers(seed: String, security: Int, transfers: [IotaTransfer], remainder: String?, inputs: [String]?, validateInputs: Bool) -> [String]? {
		var bundle = IotaBundle()
		var signatureFragment: [String] = []
		var totalValue: UInt = 0
		var tag = ""
		
		for var transfer in transfers {
			if IotaChecksum.isValidChecksum(address: transfer.address) {
				transfer.address = IotaChecksum.removeChecksum(address: transfer.address)!
			}
			
			var signatureMessageLength = 1
			
			if transfer.message.count > IotaConstants.messageLength {
				signatureMessageLength += transfer.message.count / IotaConstants.messageLength
				
				var msgCopy = transfer.message
				
				while !msgCopy.isEmpty {
					var fragment = msgCopy.substring(from: 0, to: IotaConstants.messageLength)
					msgCopy = msgCopy.substring(from: IotaConstants.messageLength, to: msgCopy.count)
					fragment.rightPad(count: IotaConstants.messageLength, character: "9")
					signatureFragment.append(fragment)
				}
			}else {
				var fragment = transfer.message
				fragment.rightPad(count: IotaConstants.messageLength, character: "9")
				signatureFragment.append(fragment)
			}
			
			tag = transfer.tag
			tag.rightPad(count: IotaConstants.tagLength, character: "9")
			
			let timestamp = 1516116084//floor(Date().timeIntervalSince1970)
			bundle.addEntry(signatureMessageLength: signatureMessageLength, address: transfer.address, value: transfer.value, tag: tag, timestamp: UInt(timestamp))
			totalValue += transfer.value
		}
		
		if totalValue != 0 {
			//TODO
		}else{
			bundle.finalize(customCurl: nil)
			bundle.addTrytes(signatureFragments: signatureFragment)
			
			let trxb = bundle.transactions
			var bundleTrytes: [String] = []
			
			for trx in trxb {
				bundleTrytes.append(trx.trytes)
			}
			bundleTrytes.reverse()
			return bundleTrytes
		}
		return nil
	}
	
	fileprivate func IotaDebug(_ items: Any, separator: String = " ", terminator: String = "\n") {
		if self.debug { print("[IotaKit] \(items)", separator: separator, terminator: terminator) }
	}
}
