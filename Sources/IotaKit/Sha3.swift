/*
Copyright Soramitsu Co., Ltd. 2016 All Rights Reserved.
http://soramitsu.co.jp

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


import Foundation
#if COCOAPODS
import IotaKit.sha3
#else
import sha3
#endif

class PASHA3 {
	
	var context: UnsafeMutablePointer<sha3_context>!
	
	init() {
		self.reset()
	}
	
	deinit {
		self.close()
	}
	
	func reset() {
		if self.context != nil {
			self.context.deallocate()
		}
		self.context = UnsafeMutablePointer<sha3_context>.allocate(capacity: 1)
		sha3_Init384(&context.pointee);
	}
	
	func close() {
		if self.context != nil {
			self.context.deallocate()
			self.context = nil
		}
	}
	
	func update(withBytes bytes: [UInt8]) {
		sha3_Update(&self.context.pointee, bytes, bytes.count)
	}
	
	func finalize() -> [UInt8] {
		var out: [UInt8] = Array(repeating: 0, count: Int(self.context.pointee.numOutputBytes))
		sha3_Finalize(&self.context.pointee, &out)
		return out
	}
}

fileprivate func sha3_384(message:String) -> String{
    var out: Array<UInt8> = Array(repeating: 0, count: 48)
    let messageArray:Array<UInt8> = Array<UInt8>(message.utf8)
    sha3_384(messageArray, messageArray.count, &out)
    let hash = byteToHexString(hashByte: out)
    return hash
}

fileprivate func byteToHexString(hashByte:Array<UInt8>) -> String {
    var result: String = ""
    result = hashByte.map{String(format: "%02x", $0)}.joined(separator: "")
    return result
}
