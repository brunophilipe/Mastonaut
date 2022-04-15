//
//  CoverView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 15.02.19.
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
import CoreTootin

class CoverView: BorderView
{
	private var didInstallLabel: Bool = false

	init(backgroundColor: NSColor, textColor: NSColor = .labelColor, message: String)
	{
		super.init(frame: .zero)
		setUp(backgroundColor: backgroundColor,
			  textColor: textColor,
			  message: message)
	}

	override init(frame frameRect: NSRect)
	{
		super.init(frame: frameRect)
		setUp()
	}

	required init?(coder decoder: NSCoder)
	{
		super.init(coder: decoder)
		setUp()
	}

	private func setUp(backgroundColor: NSColor = #colorLiteral(red: 0.8316226602, green: 0.8316226602, blue: 0.8316226602, alpha: 1),
					   textColor: NSColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8470588235),
					   message: String? = nil)
	{
		translatesAutoresizingMaskIntoConstraints = false
		self.borderRadius = 4.0
		self.backgroundColor = backgroundColor

		DispatchQueue.main.async { self.delayedSetUp(message: message, textColor: textColor) }
	}

	private func delayedSetUp(message: String?, textColor: NSColor)
	{
		let label = NSTextField(labelWithString: message ?? "")
		label.translatesAutoresizingMaskIntoConstraints = false
		label.lineBreakMode = .byWordWrapping
		label.maximumNumberOfLines = 0
		label.alignment = .center
		label.textColor = textColor
		label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
		label.setContentHuggingPriority(.defaultLow, for: .horizontal)
		label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		label.setContentCompressionResistancePriority(.defaultHigh + 1, for: .vertical)
		addSubview(label)

		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
			trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12),
			centerYAnchor.constraint(equalTo: label.centerYAnchor),
			bottomAnchor.constraint(greaterThanOrEqualTo: label.bottomAnchor),
			label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor)
		])
	}
}
