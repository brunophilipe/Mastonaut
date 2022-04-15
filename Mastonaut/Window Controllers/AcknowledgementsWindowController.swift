//
//  AcknowledgementsWindowController.swift
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

import Cocoa

class AcknowledgementsWindowController: NSWindowController
{
	@IBOutlet private var textView: NSTextView!

	override var windowNibName: NSNib.Name?
	{
		return "AcknowledgementsWindowController"
	}

	override func windowDidLoad()
	{
		super.windowDidLoad()

		DispatchQueue.global(qos: .userInitiated).async
		{
			[weak textView] in

			let acknowledgements = Acknowledgements.load(plist: "Pods-Mastonaut-acknowledgements")
			let acknowledgementsString = acknowledgements?.makeAttributedString()

			DispatchQueue.main.async
			{
				guard let textView = textView, let string = acknowledgementsString else
				{
					return
				}

				textView.textStorage?.setAttributedString(string)
			}
		}
	}

}

private extension Acknowledgements
{
	static let titleAttributes: [NSAttributedString.Key: Any] = [
		.font: NSFont.systemFont(ofSize: 18, weight: .semibold),
		.foregroundColor: NSColor.labelColor
	]

	static let textAttributes: [NSAttributedString.Key: Any] = [
		.font: NSFont.systemFont(ofSize: 14, weight: .regular),
		.foregroundColor: NSColor.labelColor
	]

	func makeAttributedString() -> NSAttributedString
	{
		let string = NSMutableAttributedString()

		for entry in entries
		{
			if !entry.title.isEmpty
			{
				string.append(NSAttributedString(string: "\(entry.title)\n\r",
												 attributes: Acknowledgements.titleAttributes))
			}

			if !entry.text.isEmpty
			{
				string.append(NSAttributedString(string: "\(entry.text)\n\r",
												 attributes: Acknowledgements.textAttributes))
			}
		}

		return string
	}
}
