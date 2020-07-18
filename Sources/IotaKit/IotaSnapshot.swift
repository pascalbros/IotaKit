//
//  IotaSnapshot.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 18/07/2020.
//

import Foundation

public struct IotaTransitionResult {
	var addressIndex: Int
	var totalAmount: UInt64
}

public class IotaTransition: IotaDebuggable {
	public var debug: Bool = false

	init() { }

	public func checkAddresses(
		_ iota: Iota,
		seed: String,
		startAddressIndex: Int = 0,
		currentAmount: UInt64 = 0,
		result: @escaping (IotaTransitionResult) -> Void,
		error: @escaping (Error) -> Void) {

		_checkAddresses(iota,
						seed: seed,
						startAddressIndex: startAddressIndex,
						addressesToCheck: 10,
						currentAmount: currentAmount,
						result: result,
						error: error)
	}

	fileprivate func _checkAddresses(
		_ iota: Iota,
		seed: String,
		startAddressIndex: Int = 0,
		addressesToCheck: Int = 10,
		currentAmount: UInt64 = 0,
		result: @escaping (IotaTransitionResult) -> Void,
		error: @escaping (Error) -> Void) {

		let addresses = (startAddressIndex..<startAddressIndex+addressesToCheck).map({ IotaAPIUtils.newAddress(seed: seed, index: $0, checksum: false) })
		iota.balancesArray(addresses: addresses, { res in
			let balance = res.reduce(into: 0) { $0 += $1.balance }
			if balance == 0 {
				result(IotaTransitionResult(addressIndex: startAddressIndex+res.count, totalAmount: 0))
				return
			}
			
			for i in res.indices.reversed() {
				if res[i].balance > 0 {
					result(IotaTransitionResult(addressIndex: startAddressIndex+i+1, totalAmount: 0))
					return
				}
			}
			fatalError("Error in _checkAddresses, should never reach here")
		}, error: error)
	}
}
