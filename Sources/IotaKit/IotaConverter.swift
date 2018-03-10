//
//  Converter.swift
//  IOTA
//
//  Created by Pasquale Ambrosini on 05/01/18.
//  Copyright © 2018 Pasquale Ambrosini. All rights reserved.
//

import Foundation

public class IotaConverter {
	
	static let radix = 3
	static let maxTritValue = (IotaConverter.radix - 1)/2
	static let minTritValue = -IotaConverter.maxTritValue
	
	static let highLongBits: UInt64 = 0xFFFFFFFFFFFFFFFF
	
	static let trytesAlphabet = Array("9ABCDEFGHIJKLMNOPQRSTUVWXYZ")

	static let alphabetTrits: [String: [Int]] = [
		"9": [ 0,  0,  0],
		"A": [ 1,  0,  0],
		"B": [-1,  1,  0],
		"C": [ 0,  1,  0],
		"D": [ 1,  1,  0],
		"E": [-1, -1,  1],
		"F": [ 0, -1,  1],
		"G": [ 1, -1,  1],
		"H": [-1,  0,  1],
		"I": [ 0,  0,  1],
		"J": [ 1,  0,  1],
		"K": [-1,  1,  1],
		"L": [ 0,  1,  1],
		"M": [ 1,  1,  1],
		"N": [-1, -1, -1],
		"O": [ 0, -1, -1],
		"P": [ 1, -1, -1],
		"Q": [-1,  0, -1],
		"R": [ 0,  0, -1],
		"S": [ 1,  0, -1],
		"T": [-1,  1, -1],
		"U": [ 0,  1, -1],
		"V": [ 1,  1, -1],
		"W": [-1, -1,  0],
		"X": [ 0, -1,  0],
		"Y": [ 1, -1,  0],
		"Z": [-1,  0,  0]
	]
	
	static let tritsAlphabet: [String: String] = [
		"000": "9",
		"100": "A",
		"-110": "B",
		"010": "C",
		"110": "D",
		"-1-11": "E",
		"0-11": "F",
		"1-11": "G",
		"-101": "H",
		"001": "I",
		"101": "J",
		"-111":"K",
		"011": "L",
		"111": "M",
		"-1-1-1": "N",
		"0-1-1": "O",
		"1-1-1": "P",
		"-10-1": "Q",
		"00-1": "R",
		"10-1": "S",
		"-11-1": "T",
		"01-1": "U",
		"11-1": "V",
		"-1-10": "W",
		"0-10": "X",
		"1-10": "Y",
		"-100": "Z"
	]
	static let trytesTrits: [[Int]] = [
		[ 0,  0,  0],
		[ 1,  0,  0],
		[-1,  1,  0],
		[ 0,  1,  0],
		[ 1,  1,  0],
		[-1, -1,  1],
		[ 0, -1,  1],
		[ 1, -1,  1],
		[-1,  0,  1],
		[ 0,  0,  1],
		[ 1,  0,  1],
		[-1,  1,  1],
		[ 0,  1,  1],
		[ 1,  1,  1],
		[-1, -1, -1],
		[ 0, -1, -1],
		[ 1, -1, -1],
		[-1,  0, -1],
		[ 0,  0, -1],
		[ 1,  0, -1],
		[-1,  1, -1],
		[ 0,  1, -1],
		[ 1,  1, -1],
		[-1, -1,  0],
		[ 0, -1,  0],
		[ 1, -1,  0],
		[-1,  0,  0]
	]
	
	static let tritsInATryte = 3
	static let tritsInAByte = 5
	
	
	public static func trytes(fromAsciiString input: String) -> String? {
		var trytes = ""
		
		for char in input {
			guard let unicode = char.unicodeScalars.first else { return nil }
			guard unicode.isASCII else { return nil }
			
			let firstValue = Int(unicode.value % 27)
			let secondValue = (Int(unicode.value) - firstValue) / 27
			let trytesValue = String(trytesAlphabet[firstValue]) + String(trytesAlphabet[secondValue])
			trytes += trytesValue
		}
		return trytes
	}
	
	public static func asciiString(fromTrytes inputTrytes: String) -> String? {
		guard IotaInputValidator.isTrytes(trytes: inputTrytes) else { return nil }
		guard inputTrytes.count % 2 == 0 else { return nil }
		
		var result = ""
		
		for i in stride(from: 0, to: inputTrytes.count, by: 2) {
			let charOne = inputTrytes.character(at: i)!
			let charTwo = inputTrytes.character(at: i+1)!
			
			guard let valueOne = trytesAlphabet.index(of: Character(charOne)) else { return nil }
			guard let valueTwo = trytesAlphabet.index(of: Character(charTwo)) else { return nil }
			
			let decimalValue = UInt8(valueOne + valueTwo * 27)
			result += String(UnicodeScalar(decimalValue))
		}
		
		return result
	}
	
	public static func string(fromTrits trits: [Int]) -> String {
		var result = ""
		for i in stride(from: 0, to: trits.count, by: 3) {
			let str = "\(trits[i])\(trits[i+1])\(trits[i+2])"
			result += tritsAlphabet[str]!
		}
		return result
	}
	
	public static func trits(fromString string: String) -> [Int] {
		var result: [Int] = []
		for i in string {
			result.append(contentsOf: alphabetTrits[String(i)]!)
		}
		return result
	}
	
	static func trits(trytes: String) -> [Int]? {
		var trits: [Int] = Array(repeating: 0, count: trytes.count*3)
		let input = Array(trytes)
		for i in 0..<input.count {
			guard let index = trytesAlphabet.index(of: input[i]) else { return nil }
			trits[i * 3] = trytesTrits[index][0]
			trits[i * 3 + 1] = trytesTrits[index][1]
			trits[i * 3 + 2] = trytesTrits[index][2]
		}
		
		return trits
	}
	
	static func trits(trytes: Int, length: Int) -> [Int] {
		var trits = self.trits(trytes: trytes)
		if trits.count < length {
			trits.append(contentsOf: Array(repeating: 0, count: length-trits.count))
			return trits
		}
		return trits.slice(from: 0, to: length)
	}
	
	static func trits(trytes: String, length: Int) -> [Int] {
		let trits = self.trits(fromString: trytes)
		var result = Array(trits.prefix(length))
		if result.count < length {
			result.append(contentsOf: repeatElement(0, count: length - result.count))
		}
		return result
	}
	
	static func trits(trytes: Int) -> [Int] {
		var trits: [Int] = []
		var absoluteValue = trytes < 0 ? -trytes : trytes;
		
		var position: Int = 0
		
		while absoluteValue > 0 {
			
			var remainder = absoluteValue % 3;
			absoluteValue = absoluteValue / 3;

			if (remainder > 1) {
				remainder = -1;
				absoluteValue += 1;
			}

			trits.insert(remainder, at: position);
			position += 1
		}
		if (trytes < 0) {

			for i in 0..<trits.count {
				trits[i] = -trits[i];
			}
		}
		return trits
	}
	
	static func trytes(trits: [Int]) -> String {
		return trytes(trits: trits, offset: 0, size: trits.count)
	}
	
	static func trytes(trits: [Int], offset: Int, size: Int) -> String {
		var trytes = ""
		let max = (size + tritsInATryte - 1) / tritsInATryte
		for i in stride(from: 0, to: max, by: 1) {
			var j = trits[offset + i * 3] + trits[offset + i * 3 + 1] * 3 + trits[offset + i * 3 + 2] * 9
			if j < 0 {
				j += trytesAlphabet.count
			}
			trytes += String(trytesAlphabet[j])
		}
		return trytes
	}
	
	static func longValue(_ trits: [Int]) -> Int64 {
		var value: Int64 = 0;
	
		for i in stride(from: trits.count - 1, to: -1, by: -1) {
			value = value*3 + Int64(trits[i])
		}
		return value;
	}
	
	static func increment(trits: inout [Int], size: Int) {
		for i in 0..<size {
			trits[i] += 1
			if trits[i] > IotaConverter.maxTritValue {
				trits[i] = IotaConverter.minTritValue
			}else{
				break
			}
		}
	}
}
