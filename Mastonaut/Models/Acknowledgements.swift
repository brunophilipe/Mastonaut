//
//  Acknowledgements.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 08.02.19.
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

struct Acknowledgements: Codable
{
	let entries: [Entry]

	enum CodingKeys: String, CodingKey
	{
		case entries = "PreferenceSpecifiers"
	}

	struct Entry: Codable
	{
		let title: String
		let text: String

		enum CodingKeys: String, CodingKey
		{
			case title = "Title"
			case text = "FooterText"
		}
	}
}

extension Acknowledgements
{
	static func load(plist: String) -> Acknowledgements?
	{
		guard
			let plistUrl = Bundle.main.url(forResource: plist, withExtension: "plist"),
			let plistData: Data = try? Data(contentsOf: plistUrl)
		else
		{
			return nil
		}

		do
		{
			return try PropertyListDecoder().decode(Acknowledgements.self, from: plistData)
		}
		catch
		{
			NSLog("Error: \(error)")
			return nil
		}
	}
}

