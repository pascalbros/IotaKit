//
//  Signing.swift
//  IOTA
//
//  Created by Pasquale Ambrosini on 06/01/18.
//  Copyright © 2018 Pasquale Ambrosini. All rights reserved.
//

import Foundation
import Dispatch

class IotaSigning {
	
	static let KEY_LENGTH = 6561
	static let HASH_LENGTH = Curl.hashLength
	
	fileprivate let curl: CurlSource
	
	init(curl: CurlSource) {
		self.curl = curl
	}
	
	func key(inSeed: [Int], index: Int, security: Int) -> [Int] {
		curl.reset()
		if security < 1 {
			fatalError("INVALID_SECURITY_LEVEL_INPUT_ERROR")
		}
		
		var seed = inSeed.map { $0 }
		
		for _ in 0..<index {
			for j in 0..<seed.count {
				seed[j] += 1
				if seed[j] > 1 {
					seed[j] = -1
				}else {
					break
				}
			}
		}
		
		_ = curl.absorb(trits: seed, offset: 0, length: seed.count)
		_ = curl.squeeze(trits: &seed, offset: 0, length: seed.count)
		curl.reset()
		_ = curl.absorb(trits: seed, offset: 0, length: seed.count)
		
		var key: [Int] = Array(repeating: 0, count: security * IotaSigning.HASH_LENGTH * 27)
		var buffer: [Int] = Array(repeating: 0, count: seed.count)
		var offset = 0
		var s = security
		while s > 0 {
			s -= 1
			for _ in 0..<27 {
				_ = curl.squeeze(trits: &buffer, offset: 0, length: seed.count)
				arrayCopy(src: buffer, srcPos: 0, dest: &key, destPos: offset, length: IotaSigning.HASH_LENGTH)
				offset += IotaSigning.HASH_LENGTH
			}
		}
		return key
	}
	
	
	func digest(key: [Int], multithreaded: Bool = false) -> [Int] {
		let security = key.count/IotaSigning.KEY_LENGTH
		let threadsCount = ProcessInfo.processInfo.activeProcessorCount
		let canUseMultithread = threadsCount >= security
		if !multithreaded || threadsCount == 1 || security == 1 || !canUseMultithread {
			return _digest(key: key)
		}else{
			return _digestMultithreaded(key: key)
		}
	}
	
	func _digest(key: [Int]) -> [Int] {
		curl.reset()
		let security = key.count/IotaSigning.KEY_LENGTH
		var digests: [Int] = Array(repeating: 0, count: security * IotaSigning.HASH_LENGTH)
		var keyFragment: [Int] = Array(repeating: 0, count: IotaSigning.KEY_LENGTH)
		
		for i in 0..<security {
			arrayCopy(src: key, srcPos: i*IotaSigning.KEY_LENGTH, dest: &keyFragment, destPos: 0, length: IotaSigning.KEY_LENGTH)
			for j in 0..<27 {
				for _ in 0..<26 {
					_ = curl.absorb(trits: keyFragment, offset: j*IotaSigning.HASH_LENGTH, length: IotaSigning.HASH_LENGTH)
					_ = curl.squeeze(trits: &keyFragment, offset: j*IotaSigning.HASH_LENGTH, length: IotaSigning.HASH_LENGTH)
					curl.reset()
				}
			}
			_ = curl.absorb(trits: keyFragment, offset: 0, length: keyFragment.count)
			_ = curl.squeeze(trits: &digests, offset: i*IotaSigning.HASH_LENGTH, length: IotaSigning.HASH_LENGTH)
			curl.reset()
		}
		return digests
	}
	
	func _digestMultithreaded(key: [Int]) -> [Int] {
		
		curl.reset()
		let threadQueue = DispatchQueue(label: "threadQueue", attributes: .concurrent)
		let concurrentQueue = DispatchQueue(label: "barrierQueue", attributes: .concurrent)
		let security = key.count/IotaSigning.KEY_LENGTH
		var digests: [Int] = Array(repeating: 0, count: security * IotaSigning.HASH_LENGTH)
		var reachedSecurity = 0
		
		func copyDigest(array: [Int], index: Int) {
			concurrentQueue.sync(flags: .barrier) {
				arrayCopy(src: array, srcPos: 0, dest: &digests, destPos: index*IotaSigning.HASH_LENGTH, length: array.count)
			}
		}
		func getDigest() -> [Int] {
			var result: [Int]!
			concurrentQueue.sync {
				result = digests
			}
			return result
		}
		
		func onDigest(index i: Int) {
			
			var digest: [Int] = Array(repeating: 0, count: IotaSigning.HASH_LENGTH)
			var keyFragment: [Int] = Array(repeating: 0, count: IotaSigning.KEY_LENGTH)
			let c = self.curl.clone()
			c.reset()
			arrayCopy(src: key, srcPos: i*IotaSigning.KEY_LENGTH, dest: &keyFragment, destPos: 0, length: IotaSigning.KEY_LENGTH)
			for j in 0..<27 {
				for _ in 0..<26 {
					_ = c.absorb(trits: keyFragment, offset: j*IotaSigning.HASH_LENGTH, length: IotaSigning.HASH_LENGTH)
					_ = c.squeeze(trits: &keyFragment, offset: j*IotaSigning.HASH_LENGTH, length: IotaSigning.HASH_LENGTH)
					c.reset()
				}
			}
			_ = c.absorb(trits: keyFragment, offset: 0, length: keyFragment.count)
			_ = c.squeeze(trits: &digest, offset: 0, length: IotaSigning.HASH_LENGTH)
			c.reset()
			copyDigest(array: digest, index: i)
			reachedSecurity += 1
		}
		
		for i in 0..<security {
			threadQueue.async {
				onDigest(index: i)
			}
		}
		while reachedSecurity < security {
			Thread.sleep(forTimeInterval: 0.01)
		}
		return getDigest()
	}
	
	func digest(normalizedBundleFragment: [Int], signatureFragment: [Int]) -> [Int] {
		curl.reset()
		let jCurl: CurlSource = CurlMode.kerl.create()
		var buffer: [Int] = Array(repeating: 0, count: IotaSigning.HASH_LENGTH)
		
		for i in 0..<27 {
			buffer = signatureFragment.slice(from: i * IotaSigning.HASH_LENGTH, to: (i + 1) * IotaSigning.HASH_LENGTH)
			for _ in stride(from: normalizedBundleFragment[i] + 13, to: 0, by: -1) {
				jCurl.reset()
				_ = jCurl.absorb(trits: buffer)
				_ = jCurl.squeeze(trits: &buffer)
			}
			_ = curl.absorb(trits: buffer)
		}
		_ = curl.squeeze(trits: &buffer)
		
		return buffer
	}
	
	func validateSignature(expectedAddress: String, signatureFragments: [String], bundleHash: String) -> Bool {
		
		let bundle = IotaBundle()
		
		var normalizedBundleFragments: [[Int]] = Array(repeating: Array(repeating: 0, count: 27), count: 3)
		let normalizedBundlHash = bundle.normalizedBundle(bundleHash: bundleHash)
		
		for i in 0..<3 {
			normalizedBundleFragments[i] = normalizedBundlHash.slice(from: i * 27, to: (i + 1) * 27)
		}
		
		var digests: [Int] = Array(repeating: 0, count: signatureFragments.count * IotaSigning.HASH_LENGTH)
		
		for i in 0..<signatureFragments.count {
			let digestBuffer = self.digest(normalizedBundleFragment: normalizedBundleFragments[i % 3], signatureFragment: IotaConverter.trits(fromString: signatureFragments[i]))
			arrayCopy(src: digestBuffer, srcPos: 0, dest: &digests, destPos: i * IotaSigning.HASH_LENGTH, length: IotaSigning.HASH_LENGTH)
		}
		let address = IotaConverter.trytes(trits: self.address(digests: digests))
		return expectedAddress == address
		
	}
	
	func validateSignature(signedBundle: IotaBundle, inputAddress: String) -> Bool {
		var bundleHash = ""
		var signatureFragments: [String] = []
		
		for trx in signedBundle.transactions {
			guard trx.address == inputAddress else { continue }
			bundleHash = trx.bundle
			
			let signatureFragment = trx.signatureFragments
			if IotaInputValidator.isNinesTrytes(trytes: signatureFragment) {
				break
			}
			signatureFragments.append(signatureFragment)
		}
		return validateSignature(expectedAddress: inputAddress, signatureFragments: signatureFragments, bundleHash: bundleHash)
	}
	
	func address(digests: [Int]) -> [Int] {
		curl.reset()
		var address: [Int] = Array(repeating: 0, count: IotaSigning.HASH_LENGTH)
		_ = curl.absorb(trits: digests)
		_ = curl.squeeze(trits: &address)
		return address
	}
	
	func signatureFragment(normalizedBundleFragment: [Int], keyFragment: [Int]) -> [Int] {
		self.curl.reset()
		var signatureFragment = keyFragment.map { $0 }
		for i in 0..<27 {
			for _ in 0..<(13 - normalizedBundleFragment[i]) {
				self.curl.reset()
				_ = self.curl.absorb(trits: signatureFragment, offset: i*IotaSigning.HASH_LENGTH, length: IotaSigning.HASH_LENGTH)
				_ = self.curl.squeeze(trits: &signatureFragment, offset: i*IotaSigning.HASH_LENGTH, length: IotaSigning.HASH_LENGTH)
			}
		}
		return signatureFragment
	}
}

