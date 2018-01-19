//
//  Utils.swift
//
//  Created by Pasquale Ambrosini on 07/01/18.
//

import Foundation

func arrayCopy<T>(src: [T], srcPos: Int, dest: inout [T], destPos: Int, length: Int) {
	dest[destPos..<(destPos+length)] = src[srcPos..<(srcPos+length)]
}

extension String {
	func substring(from: Int, to: Int) -> String {
		let start = index(startIndex, offsetBy: from)
		let end = index(start, offsetBy: to - from)
		return String(self[start ..< end])
	}
	
	mutating func rightPad(count: Int, character: Character) {
		if self.count >= count { return }
		for _ in self.count..<count {
			self.append(character)
		}
	}
	
	func rightPadded(count: Int, character: Character) -> String {
		var str = self
		if str.count >= count { return str }
		for _ in self.count..<count {
			str.append(character)
		}
		return str
	}
}

extension Array {
	func slice(from: Int, to: Int) -> Array {
		let start = index(0, offsetBy: from)
		let end = index(start, offsetBy: to - from)
		return Array(self[start..<end])
	}
}
