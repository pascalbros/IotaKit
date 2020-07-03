//
//  IotaMultisig.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 07/03/18.
//

import Foundation

/// Multisignature Iota Client.
// swiftlint:disable file_length
public class IotaMultisig: IotaDebuggable {
	fileprivate let curl: CurlSource = CurlMode.kerl.create()
	fileprivate var signing: IotaSigning = IotaSigning(curl: CurlMode.kerl.create())
	fileprivate var iota: Iota

	/// Used to debug Iota messages, default `false`.
	public var debug = false {
		didSet {
			self.iota.debug = self.debug
		}
	}

	/// Initializer for Iota Client.
	///
	/// - Parameters:
	///   - node: A valid node URL.
	///   - port: A valid port.
	public init(node: String, port: UInt) {
		self.iota = Iota(node: node, port: port)
	}

	/// Initialized for Iota Client
	///
	/// - Parameter node: A valid node URL.
	public init(node: String) {
		self.iota = Iota(node: node)
	}

	/// Gets the account data.
	///
	/// - Parameters:
	///   - addresses: An Array of Iota Addresses.
	///   - findLastAddress: Find last address, default `true`.
	///   - requestTransactions: Request transactions, default `false`.
	///   - success: Success block.
	///   - error: Error block.
	///   - log: Log block, used to receive messages from Iota Client and updated the UI with useful messages.
	// swiftlint:disable function_body_length
	public func accountData(
		addresses: [String],
		findLastAddress: Bool = true,
		requestTransactions: Bool = false,
		_ success: @escaping (_ account: IotaAccount) -> Void,
		error: @escaping (Error) -> Void,
		log: ((_ log: IotaLog) -> Void)? = nil) {

		var account = IotaAccount()
		var index = 0

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
					} else {
						getInclusions()
					}
				}
				return
			}

			let hashes = account.addresses[index].transactions!.map { $0.hash }
			self.iota.latestInclusionStates(hashes: hashes, { (inclusions) in
				for i in 0..<account.addresses[index].transactions!.count {
					account.addresses[index].transactions![i].persistence = inclusions[i]
				}
				index += 1
				if index >= account.addresses.count {
					completeBalances()
				} else {
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
			} else {
				let addresses = account.addresses.map { $0.hash }
				self.iota.balances(addresses: addresses, { balances in
					for i in 0..<account.addresses.count {
						account.addresses[i].balance = balances[account.addresses[i].hash]
					}
					self.IotaDebug("Got balances \(balances.count)")
					account.balance = balances.reduce(0, { (val, rest) -> Int64 in return val+rest.value })
					success(account)
				}, error: { err in
					error(err)
				})
			}
		}

		func wereSpent() {
			IotaDebug("Getting spent status")
			log?(IotaLog(message: "Getting spent status"))
			let addresses = account.addresses.map { $0.hash }
			self.iota.wereAddressesSpentFrom(addresses: addresses, { (result) in
				for i in 0..<account.addresses.count {
					account.addresses[i].canSpend = !result[i]
				}
				findBalances(requestTransactions)
			}, error)
		}

		func findTransactions() {
			let address = addresses[index]

			IotaDebug("Getting transactions")
			log?(IotaLog(message: "Getting transactions from address \(index)"))
			self.iota.findTransactions(addresses: [address], { (hashes) in
				self.IotaDebug("Got transactions \(hashes.count)")
				if hashes.isEmpty {
					wereSpent()
				} else {
					if requestTransactions {
						self.IotaDebug("Getting trytes")
						self.iota.addressFromHash(address: address, { (resultAddress) in
							self.IotaDebug("Got trytes")
							var tempAddress = resultAddress
							tempAddress.index = index
							account.addresses.append(tempAddress)
							DispatchQueue.global(qos: .userInitiated).async {
								index += 1
								findTransactions()
							}
						}, error: error)
					} else { //Should never reach here
						let iotaAddress = IotaAddress(hash: address, transactions: nil, index: index, balance: nil)
						account.addresses.append(iotaAddress)
						DispatchQueue.global(qos: .userInitiated).async {
							index += 1
							findTransactions()
						}
					}
				}
			}, error: error)
		}

		func findTransactions(addresses: [String]) {
			IotaDebug("Getting transactions")
			log?(IotaLog(message: "Getting transactions from address \(index)"))
			self.iota.findTransactions(addresses: addresses, { (hashes) in
				self.IotaDebug("Got transactions \(hashes.count)")
				let tempAddresses = addresses.map { IotaAddress(hash: $0, transactions: nil, index: index, balance: nil) }
				if requestTransactions {
					self.IotaDebug("Getting trytes")
					self.iota.trytes(hashes: hashes, { (txs) in
						self.IotaDebug("Got trytes")
						account.addresses = IotaAPIUtils.mergeAddressesAndTransactions(addresses: tempAddresses, txs: txs)
						if account.addresses.last!.transactions == nil {
							account.addresses.removeLast()
							DispatchQueue.global(qos: .userInitiated).async { wereSpent() }
						} else {
							index = account.addresses.count
							DispatchQueue.global(qos: .userInitiated).async { findTransactions() }
						}
					}, error: error)
				} else {
					account.addresses = tempAddresses
					DispatchQueue.global(qos: .userInitiated).async {
						wereSpent()
					}
				}
			}, error: error)
		}

		if !findLastAddress && requestTransactions {
			DispatchQueue.global(qos: .userInitiated).async {
				findTransactions(addresses: addresses)
			}
		} else {
			findTransactions()
		}
	}

	/// Create the digest from Seed.
	///
	/// - Parameters:
	///   - seed: A valid Iota Seed
	///   - security: The security value.
	///   - index: The index.
	/// - Returns: Trytes String representing the digest.
	public func digest(seed: String, security: Int, index: Int) -> String {
		let key = self.signing.key(inSeed: IotaConverter.trits(trytes: seed, length: Curl.hashLength), index: index, security: security)
		return IotaConverter.trytes(trits: self.signing.digest(key: key))
	}

	/// Create an address from the digests.
	///
	/// - Parameter digests: A valid array of digests.
	/// - Returns: A valid IOTA Address.
	public func address(fromDigests digests: [String]) -> String {
		self.curl.reset()
		for digest in digests {
			let digestTrits = IotaConverter.trits(fromString: digest)
			_ = self.curl.absorb(trits: digestTrits)
		}

		var addressTrits: [Int] = Array(repeating: 0, count: Curl.hashLength)
		_ = self.curl.squeeze(trits: &addressTrits, offset: 0, length: Curl.hashLength)
		return IotaConverter.trytes(trits: addressTrits)
	}

	/// Create a Key from the Seed.
	///
	/// - Parameters:
	///   - seed: A valid Seed.
	///   - security: A security value.
	///   - index: A valid index value.
	/// - Returns: A key as String.
	public func key(seed: String, security: Int, index: Int) -> String {
		let tritsSeed = IotaConverter.trits(trytes: seed, length: Curl.hashLength)
		let key = self.signing.key(inSeed: tritsSeed, index: index, security: security)
		return IotaConverter.trytes(trits: key)
	}

	/// Validates an address using digests.
	///
	/// - Parameters:
	///   - address: An address.
	///   - digests: A valid Array of digests.
	/// - Returns: `true` if the address is valid, `false` otherwise.
	public func validate(address: String, digests: [String]) -> Bool {
		let digestsTrits = digests.map { IotaConverter.trits(fromString: $0) }
		return self.validate(address: address, digests: digestsTrits)
	}

	/// Validates an address using digests as Trits.
	///
	/// - Parameters:
	///   - address: An address.
	///   - digests: A valid Array of digests as Trits.
	/// - Returns: `true` if the address is valid, `false` otherwise.
	public func validate(address: String, digests: [[Int]]) -> Bool {
		self.curl.reset()

		for keyDigest in digests {
			_ = self.curl.absorb(trits: keyDigest)
		}

		var addressTrits: [Int] = Array(repeating: 0, count: Curl.hashLength)
		_ = self.curl.squeeze(trits: &addressTrits)

		return IotaConverter.trytes(trits: addressTrits) == address
	}

	/// Validates the signature for a IOTA Bundle
	///
	/// - Parameters:
	///   - signedBundle: A Iota Bundle.
	///   - inputAddress: The input address.
	/// - Returns: `true` if the address is valid, `false` otherwise.
	public func validateSignature(signedBundle: IotaBundle, inputAddress: String) -> Bool {
		return self.signing.validateSignature(signedBundle: signedBundle, inputAddress: inputAddress)
	}

	/// Prepares the transfers.
	///
	/// - Parameters:
	///   - securitySum: A security sum.
	///   - inputAddress: The input address.
	///   - remainderAddress: The remainder address.
	///   - transfers: An Array of `IotaTransfer`.
	///   - keys: An array of valid keys.
	///   - skipChecks: Skip checks. Default `false`.
	///   - success: The success block.
	///   - error: The error block.
	public func prepareTransfers(
		securitySum: Int,
		inputAddress: String,
		remainderAddress: String,
		transfers: [IotaTransfer],
		keys: [String], skipChecks: Bool = false,
		_ success: @escaping (_ bundle: IotaBundle) -> Void,
		error: @escaping (Error) -> Void) {

		self.initiateTransfers(
			securitySum: securitySum,
			inputAddress: inputAddress,
			remainderAddress: remainderAddress,
			transfers: transfers,
			skipChecks: skipChecks, { bundle in
			step1(bundle: bundle)
		}, error: error)

		func step1(bundle: IotaBundle) {
			var theBundle = bundle
			for key in keys {
				self.addSignature(bundle: &theBundle, inputAddress: inputAddress, keyTrytes: key)
			}

			success(theBundle)
		}
	}

	/// Attaches an address to Tangle.
	///
	/// - Parameters:
	///   - securitySum: A security sum.
	///   - address: A valid IOTA Address.
	///   - keys: A valid Array of keys.
	///   - success: The success block.
	///   - error: The error block.
	public func attachToTangle(
		securitySum: Int,
		address: String,
		keys: [String],
		_ success: @escaping (_ transactions: [IotaTransaction]) -> Void,
		error: @escaping (Error) -> Void) {

		let transfers = [IotaTransfer(address: address, value: 0, timestamp: nil, hash: nil, persistence: false)]
		let empty = "".rightPadded(count: 81, character: "9")
		self.prepareTransfers(securitySum: securitySum,
							  inputAddress: address,
							  remainderAddress: empty,
							  transfers: transfers,
							  keys: keys,
							  skipChecks: true, { bundle in
			continueWithBundle(bundle: bundle)
		}, error: error)

		func continueWithBundle(bundle: IotaBundle) {
			let trxb = bundle.transactions
			var bundleTrytes: [String] = []
			trxb.forEach({ bundleTrytes.append($0.trytes) })
			bundleTrytes.reverse()
			self.iota.sendTrytes(trytes: bundleTrytes, success, error: error)
		}
	}

	/// Sends transfers
	///
	/// - Parameters:
	///   - securitySum: A security sum.
	///   - inputAddress: The input address.
	///   - remainderAddress: The remainder address.
	///   - transfers: An Array of `IotaTransfer`.
	///   - keys: An array of keys.
	///   - skipChecks: Skip checks. Default `false`.
	///   - success: The success block.
	///   - error: The error block.
	public func sendTransfers(
		securitySum: Int,
		inputAddress: String,
		remainderAddress: String,
		transfers: [IotaTransfer],
		keys: [String],
		skipChecks: Bool = false,
		_ success: @escaping (_ transactions: [IotaTransaction]) -> Void,
		error: @escaping (Error) -> Void) {

		self.prepareTransfers(securitySum: securitySum,
							  inputAddress: inputAddress,
							  remainderAddress: remainderAddress,
							  transfers: transfers,
							  keys: keys,
							  skipChecks: skipChecks, { bundle in
			continueWithBundle(bundle: bundle)
		}, error: error)

		func continueWithBundle(bundle: IotaBundle) {
			let trxb = bundle.transactions
			var bundleTrytes: [String] = []

			for trx in trxb {
				bundleTrytes.append(trx.trytes)
			}
			bundleTrytes.reverse()
			self.iota.sendTrytes(trytes: bundleTrytes, success, error: error)
		}
	}

	/// Adds the signature to a `IotaBundle`.
	///
	/// - Parameters:
	///   - bundle: A `IotaBundle`, NB: as side effect, the `IotaBundle` object will be changed.
	///   - inputAddress: The input address.
	///   - keyTrytes: The Key Trites.
	public func addSignature( bundle: inout IotaBundle, inputAddress: String, keyTrytes: String) {
		let security = keyTrytes.count / IotaConstants.messageLength
		let key = IotaConverter.trits(fromString: keyTrytes)

		var numSignedTxs = 0

		for i in 0..<bundle.transactions.count {
			guard bundle.transactions[i].address == inputAddress else { continue }
			guard IotaInputValidator.isNinesTrytes(trytes: bundle.transactions[i].signatureFragments) else { numSignedTxs += 1; continue }
			let bundleHash = bundle.transactions[i].bundle

			let firstFragment = key.slice(from: 0, to: 6561)

			var normalizedBundleFragments: [[Int]] = Array(repeating: [0, 0, 0], count: 27)
			let normalizedBundleHash = bundle.normalizedBundle(bundleHash: bundleHash)

			for kValue in 0..<3 {
				normalizedBundleFragments[kValue] = normalizedBundleHash.slice(from: kValue*27, to: (kValue+1)*27)
			}

			let firstBundleFragment = normalizedBundleFragments[numSignedTxs % 3]

			let firstSignedFragment = self.signing.signatureFragment(normalizedBundleFragment: firstBundleFragment, keyFragment: firstFragment)

			bundle.transactions[i].signatureFragments = IotaConverter.trytes(trits: firstSignedFragment)

			for j in 1..<security {
				let nextFragment = key.slice(from: 6561*j, to: (j+1)*6561)
				let nextBundleFragment = normalizedBundleFragments[(numSignedTxs+j) % 3]
				let nextSignedFragment = self.signing.signatureFragment(normalizedBundleFragment: nextBundleFragment, keyFragment: nextFragment)
				if (i+j) >= bundle.transactions.count { continue }
				bundle.transactions[i+j].signatureFragments = IotaConverter.trytes(trits: nextSignedFragment)
			}
			break
		}
	}
}

extension IotaMultisig {

	internal func initiateTransfers(
		securitySum: Int,
		inputAddress: String,
		remainderAddress: String,
		transfers: [IotaTransfer],
		skipChecks: Bool = false,
		_ success: @escaping (_ bundle: IotaBundle) -> Void,
		error: @escaping (Error) -> Void) {
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
			} else {
				var fragment = transfer.message
				fragment.rightPad(count: IotaConstants.messageLength, character: "9")
				signatureFragments.append(fragment)
			}

			tag = transfer.tag
			tag.rightPad(count: IotaConstants.tagLength, character: "9")

			let timestamp = floor(Date().timeIntervalSince1970)
			bundle.addEntry(signatureMessageLength: signatureMessageLength,
							address: transfer.address,
							value: Int64(transfer.value),
							tag: tag,
							timestamp: UInt64(timestamp))
			totalValue += transfer.value
		}
		guard totalValue != 0 else {
			bundle.finalize(customCurl: self.curl.clone())
			bundle.addTrytes(signatureFragments: signatureFragments)
			success(bundle)
			return
		}
		self.iota.balances(addresses: [inputAddress], { (result) in
			var totalBalance = result.values.reduce(0, +)
			if skipChecks && totalBalance == 0 {
				totalBalance = Int64(totalValue)+1
			}
			if totalValue > totalBalance {
				error(IotaAPIError("Not enough balance"))
				return
			}
			continueWithBalance(totalBalance: UInt64(totalBalance))
		}, error: error)

		func continueWithBalance(totalBalance: UInt64) {
			IotaDebug("Continue with balance \(totalBalance)")
			let timestamp = floor(Date().timeIntervalSince1970)

			if totalBalance > 0 {
				let toSubtract = 0 - Int64(totalBalance)
				bundle.addEntry(signatureMessageLength: securitySum, address: inputAddress, value: toSubtract, tag: tag, timestamp: UInt64(timestamp))
			}

			if totalBalance > totalValue {
				let remainder = totalBalance - totalValue
				IotaDebug("Remainder to send back \(remainder)")
				bundle.addEntry(signatureMessageLength: 1, address: remainderAddress, value: Int64(remainder), tag: tag, timestamp: UInt64(timestamp))
			}
			bundle.finalize(customCurl: self.curl.clone())
			bundle.addTrytes(signatureFragments: signatureFragments)
			success(bundle)
		}
	}
}
