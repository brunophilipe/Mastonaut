//
//  ISUMultiplierNumberFormatter.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 25.05.19.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2019 Bruno Philipe.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation

@IBDesignable
@objc class ISUMultiplierNumberFormatter: NumberFormatter
{
	static let orderedMultipliers: [Double] = [
//		1000000000000000000000000,
		1000000000000000000000,
		1000000000000000000,
		1000000000000000,
		1000000000000,
		1000000000,
		1000000,
		1000,
//		100,
//		10,
		1,
		0.1,
		0.01,
		0.001,
		0.000001,
		0.000000001,
		0.000000000001,
		0.000000000000001,
		0.000000000000000001,
		0.000000000000000000001,
//		0.000000000000000000000001
	]

	static let multiplierPrefixes: [String] = [
//		"Y",
		"Z",
		"E",
		"P",
		"T",
		"G",
		"M",
		"k",
//		"h",
//		"da",
		"",
		"d",
		"c",
		"m",
		"μ",
		"n",
		"p",
		"f",
		"a",
		"z",
//		"y"
	]

	@IBInspectable
	var unit: String = ""

	override func string(for anything: Any?) -> String?
	{
		if let number = anything as? Int
		{
			return string(from: NSNumber(value: number))
		}
		else
		{
			return super.string(for: anything)
		}
	}

	@objc override func string(from number: NSNumber) -> String?
	{
		let dividend: Double = number.doubleValue

		for (index, multiplier) in ISUMultiplierNumberFormatter.orderedMultipliers.enumerated()
		{
			if multiplier <= dividend
			{
				let prefix = ISUMultiplierNumberFormatter.multiplierPrefixes[index]
				let divided = dividend / multiplier

				if Double(Int(divided)) == divided
				{
					return "\(Int(divided))\(prefix)\(unit)"
				}
				else
				{
					return String(format: "%.1f%@%@", divided, prefix, unit)
				}
			}
		}

		return "\(number)"
	}
}
