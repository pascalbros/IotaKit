//: Playground - noun: a place where people can play

import Cocoa
import PlaygroundSupport
import IotaKit

let iota = Iota(node: "http://localhost", port: 14265)

iota.nodeInfo({ (result) in
	print(result)
}) { (error) in
	print(error)
}

PlaygroundPage.current.needsIndefiniteExecution = true
