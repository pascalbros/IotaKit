//
//  PAWS.swift
//  iotakit
//
//  Created by Pasquale Ambrosini on 10/01/2018.
//

import Foundation

struct PAWSRequest: WebServices {
	fileprivate static let defaultTimeout = 60
	fileprivate init() { }
	
	static func GET(destination: String, timeout: Int = defaultTimeout, successHandler: @escaping (_ response: String) -> Void, errorHandler: @escaping (_ error: Error) -> Void) {
		
		self.getRequest(destination: destination, successHandler: successHandler, errorHandler: errorHandler)
	}
	
	static func POST(data: Dictionary<String, Any>, destination: String, timeout: Int = defaultTimeout, successHandler: @escaping (_ response: String) -> Void, errorHandler: @escaping (_ error: Error) -> Void) {
		
		self.request(type: "POST", data: data, destination: destination, timeout: timeout, successHandler: successHandler, errorHandler: errorHandler)
	}
	
	static func getRequest(destination: String, successHandler: @escaping (_ response: String) -> Void, errorHandler: @escaping (_ error: Error) -> Void) {
		guard let url = URL(string: destination) else { errorHandler(IotaAPIError("Malformed URL")); return }
		URLSession.shared.dataTask(with: url) { (data, response, error) in
			if error != nil {
				errorHandler(IotaAPIError(error!.localizedDescription))
			}
			
			guard let data = data else { return }
			successHandler(String(data: data, encoding: .utf8)!)
		}.resume()
	}
	
	
	static func request(type: String, data: Dictionary<String, Any>, destination: String, timeout: Int, successHandler: @escaping (_ response: String) -> Void, errorHandler: @escaping (_ error: Error) -> Void){
		var request = URLRequest(url: URL(string: destination)!)
		request.httpMethod = type
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("1.4.1", forHTTPHeaderField: "X-IOTA-API-Version")
		request.timeoutInterval = TimeInterval(timeout)
		var parameters = ""
		if let postString = data.toJson() {
			parameters = postString
		}
		
		request.httpBody = parameters.data(using: String.Encoding.utf8)
		let task = URLSession.shared.dataTask(with: request as URLRequest) {
			data, response, error in
			
			if let e = error {
				errorHandler(e)
			}else{
				
				let responseString = String(data: data!, encoding: .utf8)
				
				if let r1 = response {
					if let r = r1 as? HTTPURLResponse {
						if r.statusCode != 200 {
							errorHandler(IotaAPIError("Code:\(r.statusCode) \(responseString ?? "")"))
							return
						}
					}
				}
				
				successHandler(responseString!);
			}
		}
		
		task.resume()
	}
}
