//
//  WSUtils.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/2018.
//

import Foundation

extension Dictionary where Key == String {
	func toJson() -> String? {
		
		var jsonData: NSData!
		do {
			jsonData = try JSONSerialization.data(withJSONObject: self, options: []) as NSData
		}catch _ {
			return nil
		}
		return NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue) as String?
		
	}
}

extension String {
	func jsonToObject() -> Any? {
		var jsonData: Any?
		do {
			jsonData = try JSONSerialization.jsonObject(with: (self as NSString).data(using: String.Encoding.utf8.rawValue)!, options: [])
		}catch _ {
			return nil
		}
		
		return jsonData
	}
}
