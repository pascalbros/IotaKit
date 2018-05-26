//
//  Iota.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/2018.
//

import Foundation
import Dispatch

/// Iota Class Instance.
public class Iota: IotaDebuggable {
	
	fileprivate let APIServices: IotaAPIServices.Type = IotaAPIService.self
	fileprivate let curl: CurlSource = CurlMode.kerl.create()
	
	/// Spam address used for promote.
	public static let spamTransfer = IotaTransfer(address: "".rightPadded(count: 81, character: "9"))
	
	/// Spam Seed used for promote.
	public static let spamSeed = "".rightPadded(count: 81, character: "9")
	
	/// Address of the host.
	public fileprivate(set) var address: String = ""
	
	/// Debug variable, setting it to `true`, will enable the debug logging. Default `false`.
	public var debug = false
	
	/// Local PoW instance, setting it to `nil` will delegate the PoW to the node.
	public var localPoW: IotaLocalPoW? = CPearlDiver()

	/// Initializer for Iota class with automatic node selection.
	///
	/// - Parameters:
	///   - prefersHTTPS: Setting it to `true`, HTTPS nodes will be preferred.
	///   - onReady: On ready block.
	public init(prefersHTTPS: Bool = false, _ onReady: @escaping (Iota?) -> Void) {
		IotaNodeSelector.bestNode(prefersHTTPS: prefersHTTPS, { (node) in
			self.address = node.fullAddress
			onReady(self)
		}) { (error) in
			onReady(nil)
		}
	}
	
	/// Initializer for Iota class.
	///
	/// - Parameters:
	///   - node: Node address without port.
	///   - port: Port for the specified node address
	public init(node: String, port: UInt) {
		self.address = node.appending(":").appending(String(port))
	}
	
	/// Initializer for Iota class
	///
	/// - Parameter node: Full node address Ex:`http://localhost:14700`
	public init(node: String) {
		self.address = node
	}
	
	/// Returns information about the connected node.
	///
	/// - Parameters:
	///   - success: Success block.
	///   - error: Error block.
	public func nodeInfo(_ success: @escaping ([String: Any]) -> Void, error: @escaping (Error) -> Void) {
		APIServices.nodeInfo(nodeAddress: self.address, success, error)
	}
	
	/// Returns the confirmed balance of the requested addresses.
	///
	/// - Parameters:
	///   - addresses: List of addresses.
	///   - success: Success block.
	///   - error: Error block.
	public func balances(addresses: [String], _ success: @escaping (_ balances: [String: Int64]) -> Void, error: @escaping (Error) -> Void) {
		APIServices.balances(nodeAddress: self.address, addresses: addresses, success, error)
	}
	
	/// Find the transactions which match the specified addresses.
	///
	/// - Parameters:
	///   - addresses: List of addresses.
	///   - success: Success block.
	///   - error: Error block.
	public func findTransactions(addresses: [String], _ success: @escaping (_ hashes: [String]) -> Void, error: @escaping (Error) -> Void) {
		APIServices.findTransactions(nodeAddress: self.address, type: .addresses, query: addresses, success, error)
	}
	
	/// Find the transactions which match the specified bundles.
	///
	/// - Parameters:
	///   - bundles: List of bundles.
	///   - success: Success block.
	///   - error: Error block.
	public func findTransactions(bundles: [String], _ success: @escaping (_ hashes: [String]) -> Void, error: @escaping (Error) -> Void) {
		APIServices.findTransactions(nodeAddress: self.address, type: .bundles, query: bundles, success, error)
	}
	
	/// Returns the raw transaction data (trytes) of a specific transaction. These trytes can then be easily converted into the actual transaction object. See IotaTransaction.
	///
	/// - Parameters:
	///   - hashes: List of transaction hashes.
	///   - success: Success block.
	///   - error: Error block.
	public func trytes(hashes: [String], _ success: @escaping (_ trytes: [IotaTransaction]) -> Void, error: @escaping (Error) -> Void) {
		APIServices.trytes(nodeAddress: self.address, hashes: hashes, success, error)
	}
	
	/// returns the addresses, transfers, inputs and balance that are associated and have been used with your account (seed). This function is useful in getting all the relevant information of your account.
	///
	/// - Parameters:
	///   - seed: The Seed.
	///   - minimumNumberOfAddresses: The minimum number of addresses associated to the seed, setting it to `true` will be useful in order to speed up the process, by requesting all the addresses balance and transactions in batch.
	///   - security: The security level (1-3).
	///   - requestTransactions: Setting it to `true`, all the transactions associated to the addresses will be requested and returned. If you don't need it, set it to `false`.
	///   - success: Success block.
	///   - error: Error block.
	///   - log: Log block.
	public func accountData(seed: String, minimumNumberOfAddresses: Int = 0, security: Int = 2, requestTransactions: Bool = false, _ success: @escaping (_ account: IotaAccount) -> Void, error: @escaping (Error) -> Void, log: ((_ log: IotaLog) -> Void)? = nil) {
		
		var account = IotaAccount()
		var index = 0
		var lastAddress = ""
		
		func completeBalances() {
			findBalances(false)
		}
		
		func getInclusions() {
			if account.addresses.isEmpty {
				completeBalances()
				return
			}
			
			guard account.addresses[index].transactions != nil else {
				DispatchQueue.main.async {
					index += 1
					if index >= account.addresses.count {
						completeBalances()
					}else{
						getInclusions()
					}
				}
				return
			}
			
			let hashes = account.addresses[index].transactions!.map { $0.hash }
			self.latestInclusionStates(hashes: hashes, { (inclusions) in
				for i in 0..<account.addresses[index].transactions!.count {
					account.addresses[index].transactions![i].persistence = inclusions[i]
				}
				index += 1
				if index >= account.addresses.count {
					completeBalances()
				}else{
					getInclusions()
				}
			}, error)
		}
		
		func findBalances(_ requestTxs: Bool) {
			IotaDebug("Getting balances")
			log?(IotaLog(message: "Getting balances"))
			if requestTxs {
				index = 0
				getInclusions()
			}else{
				let addresses = account.addresses.map { $0.hash }
				self.balances(addresses: addresses, { (balances) in
					for i in 0..<account.addresses.count {
						account.addresses[i].balance = balances[account.addresses[i].hash]
					}
					self.IotaDebug("Got balances \(balances.count)")
					account.balance = balances.reduce(0, { (r, e) -> Int64 in return r+e.value })
					success(account)
				}) { (e) in
					error(e)
				}
			}
		}
		
		func wereSpent() {
			IotaDebug("Getting spent status")
			log?(IotaLog(message: "Getting spent status"))
			let addresses = account.addresses.map { $0.hash }
			APIServices.wereAddressesSpentFrom(nodeAddress: self.address, addresses: addresses, { (result) in
				for i in 0..<account.addresses.count {
					account.addresses[i].canSpend = !result[i]
				}
				findBalances(requestTransactions)
			}, error)
		}
		
		func findTransactions() {
			let address = IotaAPIUtils.newAddress(seed: seed, security: security, index: index, checksum: false, curl: self.curl.clone())
			
			IotaDebug("Getting transactions")
			log?(IotaLog(message: "Getting transactions from address \(index)"))
			APIServices.findTransactions(nodeAddress: self.address, type: .addresses, query: [address], { (hashes) in
				self.IotaDebug("Got transactions \(hashes.count)")
				
				func continueWithRequest() {
					if requestTransactions {
						self.IotaDebug("Getting trytes")
						self.addressFromHash(address: address, { (resultAddress) in
							self.IotaDebug("Got trytes")
							var tempAddress = resultAddress
							tempAddress.index = index
							account.addresses.append(tempAddress)
							DispatchQueue.global(qos: .userInitiated).async {
								index += 1
								findTransactions()
							}
						}, error: error)
					}else{ //Should never reach here
						let iotaAddress = IotaAddress(hash: address, transactions: nil, index: index, balance: nil)
						account.addresses.append(iotaAddress)
						DispatchQueue.global(qos: .userInitiated).async {
							index += 1
							findTransactions()
						}
					}
				}
				
				//Let's iterate one last time on the next address to see if it has been spent
				if hashes.count == 0 {
					self.APIServices.wereAddressesSpentFrom(nodeAddress: self.address, addresses: [address], { (spent) in
						if spent.first! {
							continueWithRequest()
						}else{
							wereSpent()
						}
						
					}, error)
					return
				}else {
					continueWithRequest()
				}
			}, error)
		}
		
		func findTransactions(addresses: [String]) {
			IotaDebug("Getting transactions")
			log?(IotaLog(message: "Getting transactions from address \(index)"))
			APIServices.findTransactions(nodeAddress: self.address, type: .addresses, query: addresses, { (hashes) in
				self.IotaDebug("Got transactions \(hashes.count)")
				let tempAddresses = addresses.map { IotaAddress(hash: $0, transactions: nil, index: index, balance: nil) }
				if requestTransactions {
					self.IotaDebug("Getting trytes")
					self.APIServices.trytes(nodeAddress: self.address, hashes: hashes, { (txs) in
						self.IotaDebug("Got trytes")
						account.addresses = IotaAPIUtils.mergeAddressesAndTransactions(addresses: tempAddresses, txs: txs)
						if account.addresses.last!.transactions == nil {
							account.addresses.removeLast()
							DispatchQueue.global(qos: .userInitiated).async { wereSpent() }
						}else{
							index = account.addresses.count
							DispatchQueue.global(qos: .userInitiated).async { findTransactions() }
						}
					}, error)
				}else{
					account.addresses = tempAddresses
					DispatchQueue.global(qos: .userInitiated).async {
						wereSpent()
					}
				}
			}, error)
		}
		
		if minimumNumberOfAddresses > 1 && requestTransactions {
			DispatchQueue.global(qos: .userInitiated).async {
				var addresses: [String] = []
				for i in 0...minimumNumberOfAddresses { addresses.append(IotaAPIUtils.newAddress(seed: seed, index: i, checksum: false)) }
				findTransactions(addresses: addresses)
			}
		}else{
			findTransactions()
		}
	}
	
	/// Attaches the specified address to the Tangle by doing Proof of Work.
	///
	/// - Parameters:
	///   - seed: The Seed.
	///   - index: The index of the address.
	///   - security: The security level.
	///   - success: Success block.
	///   - error: Error block.
	public func attachToTangle(seed: String, index: Int, security: Int = 2, _ success: @escaping (_ transfer: IotaTransaction) -> Void, error: @escaping (Error) -> Void) {
		let address = IotaAPIUtils.newAddress(seed: seed, security: security, index: index, checksum: false, curl: self.curl.clone())
		self.attachToTangle(seed: seed, address: address, security: security, success, error: error)
	}
	
	/// Wrapper function that basically does prepareTransfers, as well as attachToTangle and finally, it broadcasts and stores the transactions locally.
	///
	/// - Parameters:
	///   - seed: The Seed.
	///   - security: The security level.
	///   - depth: Number of bundles to go back to determine the transactions for approval, leave it as default.
	///   - minWeightMagnitude: Minimum weight magnitude, leave it as default.
	///   - transfers: List of IotaTransfers.
	///   - inputs: List of IotaInputs, by setting it to null, the proper inputs will be taken automatically.
	///   - remainderAddress: The remainder address, by setting it to `null`, a new address will be generated and used as remainder.
	///   - reference: Hash of transaction to start random-walk from, used to make sure the tips returned reference a given transaction in their past, leave it as default.
	///   - success: Success block.
	///   - error: Error block.
	public func sendTransfers(seed: String, security: Int = 2, depth: Int = 10, minWeightMagnitude: Int = IotaConstants.mwm, transfers: [IotaTransfer], inputs: [IotaInput]?, remainderAddress: String?, reference: String? = nil, _ success: @escaping (_ transactions: [IotaTransaction]) -> Void, error: @escaping (Error) -> Void) {
		self.prepareTransfers(seed: seed, security: security, transfers: transfers, remainder: remainderAddress, inputs: inputs, validateInputs: false, { (trytes) in
			self.IotaDebug("Sending trytes")
			self.sendTrytes(trytes: trytes, reference: reference, { (trxs) in
				success(trxs)
			}, error: error)
		}, error: error)
	}
	
	/// Takes a tail transaction hash as input, gets the bundle associated with the transaction and then replays the bundle by attaching it to the tangle.
	///
	/// - Parameters:
	///   - tx: Transaction hash, has to be tail.
	///   - depth: Number of bundles to go back to determine the transactions for approval, leave it as default.
	///   - minWeightMagnitude: Minimum weight magnitude, leave it as default.
	///   - success: Success block.
	///   - error: Error block.
	public func replayBundle(tx: String, depth: Int = 10, minWeightMagnitude: Int = IotaConstants.mwm, _ success: @escaping (_ transactions: [IotaTransaction]) -> Void, error: @escaping (Error) -> Void) {
		
		func sendTrytes(bundleTrytes: [String]) {
			self.sendTrytes(trytes: bundleTrytes, { (trxs) in
				success(trxs)
			}, error: error)
		}
		
		var bundleTrytes: [String] = []
		
		self.bundle(tx: tx, { (txs) in
			let bundle = IotaBundle(transactions: txs, length: txs.count)
			for trx in bundle.transactions {
				bundleTrytes.append(trx.trytes)
			}
			bundleTrytes.reverse()
			sendTrytes(bundleTrytes: bundleTrytes)
		}, error: error)
	}
	
	/// Returns the bundle with the specified where the specified tx hash belongs to.
	///
	/// - Parameters:
	///   - tx: The transaction hash, has to be the tail.
	///   - success: Success block.
	///   - error: Error block.
	public func bundle(tx: String, _ success: @escaping (_ transactions: [IotaTransaction]) -> Void, error: @escaping (Error) -> Void) {
		
		func continueWithBundle(bundle b: IotaBundle) {
			var bundle = b
			var totalSum: Int64 = 0
			let bundleHash = bundle.transactions.first!.bundle
			
			self.curl.reset()
			
			var signaturesToValidate: [IotaSignature] = []
			
			for i in 0..<bundle.transactions.count {
				let trx = bundle.transactions[i]
				let bundleValue = trx.value
				totalSum += bundleValue
				
				if i != trx.currentIndex {
					error(IotaAPIError("Invalid bundle"))
					return
				}
				
				let trxTrytes = trx.trytes.substring(from: 2187, to: 2187+162)
				
				_ = self.curl.absorb(trits: IotaConverter.trits(fromString: trxTrytes))
				if bundleValue < 0 {
					let address = trx.address
					var signature = IotaSignature(address: address, signatureFragments: [trx.signatureFragments])
					for y in i+1..<bundle.transactions.count {
						let newBundleTx = bundle.transactions[y]
						
						if newBundleTx.address == address && newBundleTx.value == 0 {
							if signature.signatureFragments.index(of: newBundleTx.signatureFragments) == nil {
								signature.signatureFragments.append(newBundleTx.signatureFragments)
							}
						}
					}
					signaturesToValidate.append(signature)
				}
			}
			
			if totalSum != 0 {
				error(IotaAPIError("Invalid bundle sum"))
				return
			}
			var bundleFromTrxs: [Int] = Array(repeating: 0, count: Curl.hashLength)
			_ = self.curl.squeeze(trits: &bundleFromTrxs)
			let bundleFromTxString = IotaConverter.trytes(trits: bundleFromTrxs)
			
			if bundleFromTxString != bundleHash {
				error(IotaAPIError("Invalid bundle hash"))
				return
			}
			bundle.length = bundle.transactions.count
			if bundle.transactions.last!.currentIndex != bundle.transactions.last!.lastIndex {
				error(IotaAPIError("Invalid bundle"))
				return
			}
			
			for aSignaturesToValidate in signaturesToValidate {
				let signatureFragments = aSignaturesToValidate.signatureFragments
				let address = aSignaturesToValidate.address
				let isValidSignature = IotaSigning(curl: self.curl.clone()).validateSignature(expectedAddress: address, signatureFragments: signatureFragments, bundleHash: bundleHash)
				if !isValidSignature {
					error(IotaAPIError("Invalid signature"))
					return
				}
			}
			success(bundle.transactions)
		}
		
		if !IotaInputValidator.isHash(hash: tx) {
			return
		}
		
		self.traverseBundle(trunkTx: tx, bundleHash: nil, bundle: IotaBundle(), { (bundle) in
			continueWithBundle(bundle: bundle)
		}, error: error)
	}
	
	/// Returns all the transactions associated to the specified address.
	///
	/// - Parameters:
	///   - address: The address hash.
	///   - success: Success block.
	///   - error: Error block.
	public func transactionsFromAddress(address: String, _ success: @escaping (_ transactions: [IotaTransaction]) -> Void, error: @escaping (Error) -> Void) {
		func getTrytes(hashes: [String]) {
			self.trytes(hashes: hashes, { (txs) in
				success(txs)
			}, error: error)
		}
		
		self.findTransactions(addresses: [address], { (hashes) in
			getTrytes(hashes: hashes)
		}, error: error)
	}
	
	/// Returns the tail transaction from a transaction.
	///
	/// - Parameters:
	///   - tx: The requested tail transaction.
	///   - success: Success block.
	///   - error: Error block.
	public func tailFromTransaction(tx: IotaTransaction, _ success: @escaping (_ tail: IotaTransaction) -> Void, error: @escaping (Error) -> Void) {
		
		
		self.findTransactions(bundles: [tx.bundle], { (bundle) in
			self.trytes(hashes: bundle, { (txs) in
				let groups = IotaAPIUtils.groupTxsByBundle(txs)
				for group in groups {
					for t in group {
						if t == tx {
							success(group.sorted { $0.currentIndex < $1.currentIndex }.first!)
							return
						}
					}
				}
				error(IotaAPIError("Bundle not found"))
			}, error: error)
		}, error: error)
	}
	
	/// Returns an IotaAddress instance, filled with all the transactions.
	///
	/// - Parameters:
	///   - address: The address hash.
	///   - success: Success block.
	///   - error: Error block.
	public func addressFromHash(address: String, _ success: @escaping (_ transactions: IotaAddress) -> Void, error: @escaping (Error) -> Void) {
		self.transactionsFromAddress(address: address, { (txs) in
			let result = IotaAddress(hash: address, transactions: txs, index: nil, balance: nil)
			success(result)
		}, error: error)
	}
	
	/// Get the inclusion states of a set of transactions. This is for determining if a transaction was accepted and confirmed by the network or not.
	///
	/// - Parameters:
	///   - hashes: List of transactions hashes you want to get the inclusion state for.
	///   - success: Success block.
	///   - error: Error block.
	public func latestInclusionStates(hashes: [String], _ success: @escaping (([Bool]) -> Void), _ error: @escaping (Error) -> Void) {
		APIServices.latestInclusionStates(nodeAddress: self.address, hashes: hashes, success, error)
	}
	
	/// Check if a list of addresses was ever spent from, in the current epoch, or in previous epochs.
	///
	/// - Parameters:
	///   - addresses: List of addresses to check if they were ever spent from.
	///   - success: Success block.
	///   - error: Error block.
	public func wereAddressesSpentFrom(addresses: [String], _ success: @escaping (([Bool]) -> Void), _ error: @escaping (Error) -> Void) {
		APIServices.wereAddressesSpentFrom(nodeAddress: self.address, addresses: addresses, success, error)
	}
	
	/// Checks if a bundle is promotable by checking the tx tail of the bundle.
	///
	/// - Parameters:
	///   - tail: The tail transaction hash.
	///   - success: Success block.
	///   - error: Error block.
	public func isPromotable(tail: String, _ success: @escaping ((Bool) -> Void), _ error: @escaping (Error) -> Void) {
		if !IotaInputValidator.isHash(hash: tail) { success(false); return }
		IotaDebug("Checking consistency")
		APIServices.checkConsistency(nodeAddress: self.address, hashes: [tail], success, error)
	}
	
	/// Promotes a transaction by spamming the network (convenience method).
	///
	/// - Parameters:
	///   - hash: Transaction hash, has to be tail.
	///   - transactions: List of transfers.
	///   - depth: Number of bundles to go back to determine the transactions for approval, leave it as default.
	///   - minWeightMagnitude: Minimum weight magnitude, leave it as default.
	///   - delayInSeconds: Delay in seconds between spams.
	///   - numberOfPromotes: Number of spams to add on top of the transaction (default 4).
	///   - success: Success block.
	///   - error: Error block.
	public func promoteTransaction(hash: String, transactions: [IotaTransfer] = [Iota.spamTransfer], depth: Int = 10, minWeightMagnitude: Int = IotaConstants.mwm, delayInSeconds: UInt = 0, numberOfPromotes: Int = 4, _ success: @escaping (_ tail: String) -> Void, error: @escaping (Error) -> Void) {
		
		self.trytes(hashes: [hash], { (txs) in
			self.promoteTransaction(txs.first!, success, error: error)
		}, error: error)
	}
	
	/// Promotes a transaction by spamming the network.
	///
	/// - Parameters:
	///   - tx: The transaction.
	///   - transactions: List of transfers.
	///   - depth: Number of bundles to go back to determine the transactions for approval, leave it as default.
	///   - minWeightMagnitude: Minimum weight magnitude, leave it as default.
	///   - delayInSeconds: Delay in seconds between spams.
	///   - numberOfPromotes: Number of spams to add on top of the transaction (default 4).
	///   - success: Success block.
	///   - error: Error block.
	public func promoteTransaction(_ tx: IotaTransaction, transactions: [IotaTransfer] = [Iota.spamTransfer], depth: Int = 10, minWeightMagnitude: Int = IotaConstants.mwm, delayInSeconds: UInt = 0, numberOfPromotes: Int = 4, _ success: @escaping (_ tail: String) -> Void, error: @escaping (Error) -> Void) {
		
		func promote(theTX: IotaTransaction) {
			self.promote(tail: theTX.hash, success, error: error)
		}
		if tx.currentIndex == 0 {
			promote(theTX: tx)
		}else{
			self.tailFromTransaction(tx: tx, { (tail) in
				promote(theTX: tail)
			}, error: error)
		}
	}
	
	/// Promotes a transaction by spamming the network (convenience method).
	///
	/// - Parameters:
	///   - tail: The tail transaction hash.
	///   - transactions: List of transfers.
	///   - depth: Number of bundles to go back to determine. the transactions for approval, leave it as default.
	///   - minWeightMagnitude: Minimum weight magnitude, leave it as default.
	///   - delayInSeconds: Delay in seconds between spams.
	///   - numberOfPromotes: Number of spams to add on top of the transaction (default 4).
	///   - success: Success block.
	///   - error: Error block.
	public func promote(tail: String, transactions: [IotaTransfer] = [Iota.spamTransfer], depth: Int = 10, minWeightMagnitude: Int = IotaConstants.mwm, delayInSeconds: UInt = 0, numberOfPromotes: Int = 4, _ success: @escaping (_ tail: String) -> Void, error: @escaping (Error) -> Void) {
		self.isPromotable(tail: tail, { (result) in
			if result {
				self._promote(tail: tail, numberOfPromotes: numberOfPromotes, success, error: error)
			}else {
				error(IotaAPIError("Tx is not promotable"))
			}
		}, error)
	}
	
	/// Wrapper function that does attachToTangle and finally, it broadcasts and stores the transactions.
	///
	/// - Parameters:
	///   - trytes: List of trytes.
	///   - depth: Number of bundles to go back to determine the transactions for approval, leave it as default.
	///   - minWeightMagnitude: Minimum weight magnitude, leave it as default.
	///   - reference: Hash of transaction to start random-walk from, used to make sure the tips returned reference a given transaction in their past, leave it as default.
	///   - success: Success block.
	///   - error: Error block.
	public func sendTrytes(trytes: [String], depth: Int = 10, minWeightMagnitude: Int = IotaConstants.mwm, reference: String? = nil, _ success: @escaping (_ transactions: [IotaTransaction]) -> Void, error: @escaping (Error) -> Void) {
		
		//4
		func toTxs(trytes t: [String]) {
			IotaDebug("Converting to transactions")
			let trx = t.map { IotaTransaction(trytes: $0) }
			success(trx)
		}
		
		//3
		func store(trytes t: [String]) {
			IotaDebug("Storing trytes")
			APIServices.storeTransactions(nodeAddress: self.address, trytes: t, {
				toTxs(trytes: t)
			}, error)
		}
		
		//2
		func broadcast(trytes t: [String]) {
			IotaDebug("Broadcasting trytes")
			APIServices.broadcastTransactions(nodeAddress: self.address, trytes: t, {
				store(trytes: t)
			}, error)
		}
		
		//1
		func attach(trunkTx: String, branchTx: String) {
			IotaDebug("Attaching to tangle (PoW)")
			self.attachToTangle(trunkTx: trunkTx, branchTx: branchTx, minWeightMagnitude: minWeightMagnitude, trytes: trytes, { (t) in
				broadcast(trytes: t)
			}, error: error)
		}
		
		//0
		IotaDebug("Getting TXs to approve")
		APIServices.transactionsToApprove(nodeAddress: self.address, depth: depth, reference: reference, { (txs) in
			attach(trunkTx: txs.trunkTx, branchTx: txs.branchTx)
		}) { (e) in
			error(e)
		}
	}
}
















//Internal functions
extension Iota {
	
	internal func _promote(tail: String, transactions: [IotaTransfer] = [Iota.spamTransfer], depth: Int = 10, minWeightMagnitude: Int = IotaConstants.mwm, delayInSeconds: UInt = 0, index: Int = 0, numberOfPromotes: Int, _ success: @escaping (_ tail: String) -> Void, error: @escaping (Error) -> Void) {
		if index == numberOfPromotes {
			success(tail)
			return
		}
		IotaDebug("Promoting \(index+1)/\(numberOfPromotes)")
		self.sendTransfers(seed: Iota.spamSeed, security: 2, depth: depth, minWeightMagnitude: minWeightMagnitude, transfers: [Iota.spamTransfer], inputs: nil, remainderAddress: nil, reference: tail, { (tx) in
			self.IotaDebug("Promoted, tx:\(tx.first?.hash ?? "")")
			self._promote(tail: tail, index: index + 1, numberOfPromotes: numberOfPromotes, success, error: error)
		}, error: error)
	}
	
	internal func traverseBundle(trunkTx: String, bundleHash: String?, bundle: IotaBundle, _ success: @escaping (_ transfer: IotaBundle) -> Void, error: @escaping (Error) -> Void) {
		var bh = bundleHash
		var tt = trunkTx
		var theBundle = IotaBundle(transactions: bundle.transactions, length: bundle.length)
		self.trytes(hashes: [trunkTx], { (txs) in
			guard let trx = txs.first else { error(IotaAPIError("Invalid response")); return }
			guard trx.trytes.count > 0 else { error(IotaAPIError("Invalid bundle")); return }
			guard !trx.bundle.isEmpty else { error(IotaAPIError("Invalid bundle")); return }
			
			if bh == nil {
				bh = trx.bundle
			}
			
			if bh! != trx.bundle {
				success(bundle)
				return
			}
			
			if trx.lastIndex == 0 && trx.currentIndex == 0 {
				success(IotaBundle(transactions: [trx], length: 1))
				return
			}
			
			tt = trx.trunkTransaction
			theBundle.transactions.append(trx)
			DispatchQueue.global(qos: .userInitiated).async {
				self.traverseBundle(trunkTx: tt, bundleHash: bh, bundle: theBundle, success, error: error)
			}
			
		}, error: error)
	}
	
	internal func attachToTangle(seed: String, address: String, security: Int = 2, _ success: @escaping (_ transfer: IotaTransaction) -> Void, error: @escaping (Error) -> Void) {
		let transfers = [IotaTransfer(address: address, value: 0, timestamp: nil, hash: nil, persistence: false)]
		self.sendTransfers(seed: seed, security: security, transfers: transfers, inputs: nil, remainderAddress: "", { (txs) in
			guard let tx1 = txs.first else {
				error(IotaAPIError("Network error, tx not received"))
				return
			}
			success(tx1)
		}, error: error)
	}
	
	internal func prepareTransfers(seed: String, security: Int, transfers: [IotaTransfer], remainder: String?, inputs: [IotaInput]?, validateInputs: Bool, _ success: @escaping (_ transfers: [String]) -> Void, error: @escaping (Error) -> Void) {
		var bundle = IotaBundle()
		var signatureFragments: [String] = []
		var totalValue: UInt64 = 0
		var tag = ""
		
		IotaDebug("Preparing transfers")
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
					signatureFragments.append(fragment)
				}
			}else {
				var fragment = transfer.message
				fragment.rightPad(count: IotaConstants.messageLength, character: "9")
				signatureFragments.append(fragment)
			}
			
			tag = transfer.tag
			tag.rightPad(count: IotaConstants.tagLength, character: "9")
			
			let timestamp = floor(Date().timeIntervalSince1970)
			bundle.addEntry(signatureMessageLength: signatureMessageLength, address: transfer.address, value: Int64(transfer.value), tag: tag, timestamp: UInt64(timestamp))
			totalValue += transfer.value
		}
		if totalValue != 0 {
			if inputs != nil && inputs!.isEmpty {
				if !validateInputs {
					self.addRemainder(seed: seed, security: security, inputs: inputs!, bundle: bundle, tag: tag, totalValue: Int64(totalValue), remainderAddress: remainder, signatureFragment: signatureFragments, success, error: error)
					return
				}
				//TODO Validate inputs
				error(IotaAPIError("Not implemented yet"))
				return
			}else{
				self.inputs(seed: seed, security: security, threshold: totalValue, canDoubleSpend: false, { (resultInputs) in
					var remainderAddress = remainder
					if remainder == nil {
						remainderAddress = IotaAPIUtils.newAddress(seed: seed, security: security, index: resultInputs.accountAddresses.count, checksum: false, curl: self.curl.clone())
					}
					self.addRemainder(seed: seed, security: security, inputs: resultInputs.inputs, bundle: bundle, tag: tag, totalValue: Int64(totalValue), remainderAddress: remainderAddress, signatureFragment: signatureFragments, success, error: error)
				}, error: error)
			}
			return
		}else{
			bundle.finalize(customCurl: nil)
			bundle.addTrytes(signatureFragments: signatureFragments)
			
			let trxb = bundle.transactions
			var bundleTrytes: [String] = []
			
			for trx in trxb {
				bundleTrytes.append(trx.trytes)
			}
			bundleTrytes.reverse()
			success(bundleTrytes)
			return
		}
		//error(IotaAPIError("Invalid inputs"))
	}
	
	typealias InputsAndAddresses = (inputs: [IotaInput], accountAddresses: [IotaAddress])
	internal func inputs(seed: String, security: Int, threshold: UInt64, canDoubleSpend: Bool = false, _ success: @escaping (_ inputs: InputsAndAddresses) -> Void, error: @escaping (Error) -> Void) {
		
		self.accountData(seed: seed, security: security, requestTransactions: true, { (account) in
			guard let filteredAddresses = self.filterAddresses(account.addresses, amountToReach: threshold, canDoubleSpend: canDoubleSpend) else {
				error(IotaAPIError("Not enough balance"))
				return
			}
			var inputs: [IotaInput] = []
			for i in 0..<filteredAddresses.addresses.count {
				let a = filteredAddresses.addresses[i]
				let input = IotaInput(address: a.hash, balance: a.balance!, keyIndex: a.index!, security: security)
				inputs.append(input)
			}
			success((inputs: inputs, accountAddresses: account.addresses))
		}, error: error)
	}
	
	internal func filterAddresses(_ addresses: [IotaAddress], amountToReach: UInt64, canDoubleSpend: Bool = false) -> (addresses: [IotaAddress], balance: UInt)? {
		let filteredAddresses = addresses.filter { (a) -> Bool in
			let balance = a.balance! > 0
			let doubleSpend = canDoubleSpend ? true : a.canSpend!
			return balance && doubleSpend
		}
		
		var currentValue: UInt = 0
		var resultAddresses: [IotaAddress] = []
		for a in filteredAddresses {
			currentValue += UInt(a.balance!)
			resultAddresses.append(a)
			if currentValue >= amountToReach {
				break
			}
		}
		
		if currentValue >= amountToReach {
			return (addresses: resultAddresses, balance:currentValue)
		}else{
			return nil
		}
		
	}
	
	public func attachToTangle(trunkTx: String, branchTx: String, minWeightMagnitude: Int, trytes: [String], _ success: @escaping (_ trytes: [String]) -> Void, error: @escaping (Error) -> Void) {
		
		guard IotaInputValidator.isHash(hash: trunkTx) && IotaInputValidator.isHash(hash: branchTx) else {
			error(IotaAPIError("Invalid inputs"))
			return
		}
		
		if let localPow = self.localPoW {
			var resultTrytes: [String] = []
			var previousTransaction: String! = nil
			
			DispatchQueue.global(qos: .userInitiated).async {
				for t in trytes {
					var txn = IotaTransaction(trytes: t)
					txn.trunkTransaction = previousTransaction == nil ? trunkTx : previousTransaction
					txn.branchTransaction = previousTransaction == nil ? branchTx : trunkTx
					if txn.tag.isEmpty /*|| Set(txn.tag).isSubset(of: ["9"])*/ {
						//txn.tag = txn.obsoleteTag
						txn.tag = "".rightPadded(count: 27, character: "9")
					}
					txn.attachmentTimestamp = UInt64(Date().timeIntervalSince1970*1000)
					txn.attachmentTimestampLowerBound = 0
					txn.attachmentTimestampUpperBound = 3_812_798_742_493
					resultTrytes.append(localPow.performPoW(trytes: txn.trytes, minWeightMagnitude: minWeightMagnitude))
					previousTransaction = IotaTransaction(trytes: resultTrytes.last!).hash
				}
				success(resultTrytes)
			}
		}else{
			APIServices.attachToTangle(nodeAddress: self.address, trunkTx: trunkTx, branchTx: branchTx, minWeightMagnitude: minWeightMagnitude, trytes: trytes, { (resultTrytes) in
				success(resultTrytes)
			}, { (e) in
				error(e)
			})
		}
	}
	
	internal func newAddress(seed: String, security: Int, index: Int, checksum: Bool, total: Int, returnAll: Bool, _ success: @escaping (_ addresses: [String]) -> Void, error: @escaping (Error) -> Void) {
		
		var allAddresses: [String] = []
		
		if total != 0 {
			for i in index..<(index+total) {
				allAddresses.append(IotaAPIUtils.newAddress(seed: seed, security: security, index: i, checksum: checksum, curl: self.curl.clone()))
			}
			if !returnAll {
				allAddresses = [allAddresses.last!]
			}
			return success(allAddresses)
		}
		
		self.accountData(seed: seed, security: security, { (account) in
			let newAddress = IotaAPIUtils.newAddress(seed: seed, security: security, index: account.addresses.count, checksum: checksum, curl: self.curl.clone())
			allAddresses = account.addresses.map { $0.hash }
			allAddresses.append(newAddress)
			if !returnAll {
				allAddresses = [allAddresses.last!]
			}
			success(allAddresses)
		}, error: error)
	}
	
	internal func addRemainder(seed: String, security: Int, inputs: [IotaInput], bundle b: IotaBundle, tag: String, totalValue: Int64, remainderAddress: String?, signatureFragment: [String], _ success: @escaping (_ addresses: [String]) -> Void, error: @escaping (Error) -> Void) {
		var bundle = b
		var totalTransferValue = totalValue
		
		let inputsTotal = inputs.reduce(0) { (r, i) -> Int64 in return r+i.balance }
		if inputsTotal < totalTransferValue {
			error(IotaAPIError("Not enough balance"))
			return
		}
		
		for i in 0..<inputs.count {
			let thisBalance = inputs[i].balance
			let toSubtract = 0 - thisBalance
			let timestamp = Date().timeIntervalSince1970
			bundle.addEntry(signatureMessageLength: security, address: inputs[i].address, value: toSubtract, tag: tag, timestamp: UInt64(timestamp))
			
			if thisBalance >= totalTransferValue {
				let remainder = thisBalance - totalTransferValue
				
				if remainder > 0 && remainderAddress != nil {
					bundle.addEntry(signatureMessageLength: 1, address: remainderAddress!, value: remainder, tag: tag, timestamp: UInt64(timestamp))
					success(IotaAPIUtils.signInputs(seed: seed, inputs: inputs, bundle: bundle, signatureFragments: signatureFragment, curl: self.curl.clone()))
				}else if remainder > 0 {
					
					self.newAddress(seed: seed, security: security, index: 0, checksum: false, total: 0, returnAll: false, { (addresses) in
						bundle.addEntry(signatureMessageLength: 1, address: addresses.last!, value: remainder, tag: tag, timestamp: UInt64(timestamp))
						success(IotaAPIUtils.signInputs(seed: seed, inputs: inputs, bundle: bundle, signatureFragments: signatureFragment, curl: self.curl.clone()))
					}, error: error)
				}else if remainder == 0 {
					success(IotaAPIUtils.signInputs(seed: seed, inputs: inputs, bundle: bundle, signatureFragments: signatureFragment, curl: self.curl.clone()))
				}else {
					error(IotaAPIError("Invalid remainder address"))
				}
				return
			}else {
				totalTransferValue -= thisBalance
			}
		}
	}
}
