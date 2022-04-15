//
//  RelativeDateFormatter.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 31.12.18.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2018 Bruno Philipe.
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

import Cocoa
import CoreTootin

final class RelativeDateFormatter: DateFormatter
{
	static let shared: RelativeDateFormatter = {
		let formatter = RelativeDateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .short
		formatter.doesRelativeDateFormatting = true
		return formatter
	}()
	
	override func string(for object: Any?) -> String?
	{
		guard let date = object as? Date else
		{
			return super.string(for: object)
		}

		let components = calendar.dateComponents([.second, .minute, .hour, .day, .weekOfYear, .month, .year],
												 from: date, to: Date())

		guard let seconds = components.second else { return nil }

		if seconds >= 0
		{
			if let year = components.year, year >= 2 { return 🔠("%@ years ago", year) }
			if let year = components.year, year >= 1 { return 🔠("Last year") }
			if let month = components.month, month >= 2 { return 🔠("%@ months ago", month) }
			if let month = components.month, month >= 1 { return 🔠("Last month") }
			if let week = components.weekOfYear, week >= 2 { return 🔠("%@ weeks ago", week) }
			if let week = components.weekOfYear, week >= 1 { return 🔠("Last week") }
			if let day = components.day, day >= 2 { return 🔠("%@ days ago", day) }
			if let day = components.day, day >= 1 { return 🔠("Yesterday") }
			if let hour = components.hour, hour >= 2 { return 🔠("%@ hours ago", hour) }
			if let hour = components.hour, hour >= 1 { return 🔠("An hour ago") }
			if let minute = components.minute, minute >= 2 { return 🔠("%@ minutes ago", minute) }
			if let minute = components.minute, minute >= 1 { return 🔠("A minute ago") }
			if let second = components.second, second >= 3 { return 🔠("%@ seconds ago", second) }

			return 🔠("Just now")
		}
		else
		{
			if let year = components.year.map({ abs($0) }), year > 1 { return 🔠("In %@ years", abs(year)) }
			if let year = components.year.map({ abs($0) }), year == 1 { return 🔠("Next year") }
			if let month = components.month.map({ abs($0) }), month > 1 { return 🔠("In %@ months", abs(month)) }
			if let month = components.month.map({ abs($0) }), month == 1 { return 🔠("Next month") }
			if let week = components.weekOfYear.map({ abs($0) }), week > 1 { return 🔠("In %@ weeks", abs(week)) }
			if let week = components.weekOfYear.map({ abs($0) }), week == 1 { return 🔠("Next week") }
			if let day = components.day.map({ abs($0) }), day > 1 { return 🔠("In %@ days", abs(day)) }
			if let day = components.day.map({ abs($0) }), day == 1 { return 🔠("Tomorrow") }
			if let hour = components.hour.map({ abs($0) }), hour > 1 { return 🔠("In %@ hours", abs(hour)) }
			if let hour = components.hour.map({ abs($0) }), hour == 1 { return 🔠("In an hour") }
			if let minute = components.minute.map({ abs($0) }), minute > 1 { return 🔠("In %@ minutes", abs(minute)) }
			if let minute = components.minute.map({ abs($0) }), minute == 1 { return 🔠("In a minute") }
			if let second = components.second.map({ abs($0) }), second > 3 { return 🔠("In %@ seconds", second) }

			return 🔠("In moments")
		}
	}
}

extension DateFormatter
{
	static let longDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.timeStyle = .long
		formatter.dateStyle = .long
		return formatter
	}()
}
