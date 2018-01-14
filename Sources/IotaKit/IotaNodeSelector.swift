//
//  IotaNodeSelector.swift
//  IotaKit
//
//  Created by Pasquale Ambrosini on 14/01/2018.
//

import Foundation


struct IotaNode: Codable {
	
	let health: Int
	let load: Int
	let address: String
	let port: String
	
	var fullAddress: String {
		return "\(address):\(port)"
	}
	
	init(from decoder: Decoder) throws {
		
		let values = try decoder.container(keyedBy: CodingKeys.self)
		if let health = try? values.decode(Int.self, forKey: .health) {
			self.health = health
		}else { self.health = 0 }
		if let load = try? values.decode(Int.self, forKey: .load) {
			self.load = load
		}else { self.load = 999999999 }
		
		self.port = try values.decode(String.self, forKey: .port)
		
		let additionalValues = try decoder.container(keyedBy: AdditionalInfoKeys.self)
		
		self.address = try additionalValues.decode(String.self, forKey: .address)
	}
	
	fileprivate enum AdditionalInfoKeys: String, CodingKey {
		case address = "node"
	}
}

struct IotaNodeSelector {
	static func bestNode(_ success: @escaping (_ nodes: [IotaNode]) -> Void, error: @escaping (_ error: IotaAPIError) -> Void) {
		let url = "https://iota.dance/data/node-stats"
		PAWSRequest.GET(data: [:], destination: url, successHandler: { (r) in
			
			if var a = try? JSONDecoder().decode([IotaNode].self, from: r.data(using: .utf8)!) {
				a.sort(by: { (n1, n2) -> Bool in
					if n1.health == n2.health {
						return n1.load < n2.load
					}
					return n1.health > n2.health
				})
				success(a)
			}
		}) { (e) in
			error(IotaAPIError(e.localizedDescription))
		}
	}
}
