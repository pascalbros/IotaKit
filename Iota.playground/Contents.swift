//: Playground - noun: a place where people can play

import Cocoa
import PlaygroundSupport
import IotaKit

let useTestNet = true
var nodeAddress = "http://iotanode.party:14265"

if useTestNet {
	nodeAddress = "https://testnet140.tangle.works"
}

let iota = Iota(node: nodeAddress)
let seed = "FOWOCCYJILZYRVCMDKWOMWHMFB9KGGBNVXJSAXRBQJJOSIC9XQIYAFJSZPSPKYXWGAH9DRQSBY9PAGHUA"
iota.debug = true

func accountData(iota: Iota, seed: String) {
	iota.accountData(seed: seed, { (account) in
		print(account)
    }, error: { (error) in
		print(error)
	})
}

accountData(iota: iota, seed: seed)

PlaygroundPage.current.needsIndefiniteExecution = true
