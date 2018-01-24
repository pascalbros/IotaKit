//
//  WSUtils.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/2018.
//

import Foundation

extension Dictionary where Key == String {
	func toJson() -> String? {
		
		var jsonData: Data!
		do {
			jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
		}catch _ {
			return nil
		}
		
		return String(data: jsonData, encoding: .utf8)
	}
}

extension String {
	func jsonToObject() -> Any? {
		var jsonData: Any?
		do {
			jsonData = try JSONSerialization.jsonObject(with: self.data(using: .utf8)!, options: [])
		}catch _ {
			return nil
		}
		
		return jsonData
	}
}
