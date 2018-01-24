//
//  IotaNodeSelector.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 14/01/2018.
//

import Foundation
import Dispatch

struct IotaNode: Codable {
	
	let health: Int = 0
	let load: Int = 0
	let fullAddress: String
	let isOnline: Bool
	
	init(from decoder: Decoder) throws {
		let additionalValues = try decoder.container(keyedBy: AdditionalInfoKeys.self)
		
		self.fullAddress = try additionalValues.decode(String.self, forKey: .host)
		self.isOnline = Int(try additionalValues.decode(String.self, forKey: .online))! == 1 ? true : false
	}
	
//	init(from decoder: Decoder) throws {
//
//		let values = try decoder.container(keyedBy: CodingKeys.self)
//		if let health = try? values.decode(Int.self, forKey: .health) {
//			self.health = health
//		}else { self.health = 0 }
//		if let load = try? values.decode(Int.self, forKey: .load) {
//			self.load = load
//		}else { self.load = 999999999 }
//
//		self.port = try values.decode(String.self, forKey: .port)
//
//		let additionalValues = try decoder.container(keyedBy: AdditionalInfoKeys.self)
//
//		self.address = try additionalValues.decode(String.self, forKey: .address)
//	}
	
	fileprivate enum AdditionalInfoKeys: String, CodingKey {
		case address = "node"
		case host = "host"
		case online = "online"
	}
}

struct IotaNodeSelector {
	
	static func bestNode(prefersHTTPS: Bool, _ success: @escaping (_ node: IotaNode) -> Void, error: @escaping (_ error: IotaAPIError) -> Void) {
		
		func testNode(n: [IotaNode], index: Int = 0) {
			//print("testing \(n[index].fullAddress)")
			let iota = Iota(node: n[index].fullAddress)
			iota.nodeInfo({ (nodeInfo) in
				success(n[index])
			}) { (e) in
				let next = index + 1
				if next < n.count {
					DispatchQueue.global(qos: .userInitiated).async {
						testNode(n: n, index: next)
					}
				}
			}
		}
		
		self.bestNodes(prefersHTTPS: prefersHTTPS, { (nodes) in
			testNode(n: nodes)
		}, error: error)
	}
	
	static func bestNodes(prefersHTTPS: Bool, _ success: @escaping (_ nodes: [IotaNode]) -> Void, error: @escaping (_ error: IotaAPIError) -> Void) {
		
		//let url = "https://iota.dance/data/node-stats"
		let url = "https://iotanode.host/node_table.json"
		
		PAWSRequest.GET(destination: url, successHandler: { (r) in

			if var a = try? JSONDecoder().decode([IotaNode].self, from: r.data(using: .utf8)!) {
				a = a.filter({ (node) -> Bool in
					return node.isOnline
				})

				if prefersHTTPS {
					a = a.filter({ (node) -> Bool in
						return node.fullAddress.hasPrefix("https")
					})
				}
				success(a)
			}else{
				error(IotaAPIError("Malformed JSON"))
			}
		}) { (e) in
			error(e as! IotaAPIError)
		}
	}
}
