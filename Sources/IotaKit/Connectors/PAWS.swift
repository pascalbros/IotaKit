//
//  PAWS.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/2018.
//

import Foundation

struct PAWSRequest: WebServices {
	
	fileprivate init() { }
	
	static func GET(data: Dictionary<String, Any>, destination: String, successHandler: @escaping (_ response: String) -> Void, errorHandler: @escaping (_ error: NSError) -> Void) {
		
		self.request(type: "GET", data: data, destination: destination, successHandler: successHandler, errorHandler: errorHandler)
	}
	
	static func POST(data: Dictionary<String, Any>, destination: String, successHandler: @escaping (_ response: String) -> Void, errorHandler: @escaping (_ error: NSError) -> Void) {
		
		self.request(type: "POST", data: data, destination: destination, successHandler: successHandler, errorHandler: errorHandler)
	}
	
	
	static func request(type: String, data: Dictionary<String, Any>, destination: String, successHandler: @escaping (_ response: String) -> Void, errorHandler: @escaping (_ error: NSError) -> Void){
		let request = NSMutableURLRequest(url: NSURL(string: destination as String)! as URL)
		request.httpMethod = type
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("1.4.1", forHTTPHeaderField: "X-IOTA-API-Version")
		
		var parameters = ""
		if let postString = data.toJson() {
			parameters = postString
		}
		
		request.httpBody = parameters.data(using: String.Encoding.utf8)
		let task = URLSession.shared.dataTask(with: request as URLRequest) {
			data, response, error in
			
			if let e = error {
				errorHandler(e as NSError)
			}else{
				
				let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
				
				if let r1 = response {
					if let r = r1 as? HTTPURLResponse {
						if r.statusCode != 200 {
							errorHandler(NSError(domain: "com.iotakit", code: r.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString!]))
							return
						}
					}
				}
				
				successHandler(responseString as String!);
			}
		}
		
		task.resume()
	}
}
