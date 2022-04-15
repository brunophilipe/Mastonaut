//
//  SidebarTitleViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 01.10.19.
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

class SidebarTitleViewController: NSViewController
{
	@IBOutlet unowned var leftSideButton: NSButton!
	@IBOutlet unowned var titleLabel: NSTextField!
	@IBOutlet unowned var subtitleLabel: NSTextField!

	private var observations: [NSKeyValueObservation] = []

	static let standaloneTitleAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 13, weight: .semibold)
	]

	static let titleAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 11, weight: .semibold)
	]

	static let subtitleAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 11, weight: .regular)
	]

	var titleMode: SidebarTitleMode = .none
	{
		willSet { cleanupBindlableState() }
		didSet { updateViews() }
	}

	override var nibName: NSNib.Name?
	{
		return "SidebarTitleViewController"
	}

	init(sidebarTitleMode: SidebarTitleMode = .none)
	{
		titleMode = sidebarTitleMode
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder)
	{
		titleMode = .none
		super.init(coder: coder)
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		updateViews()
	}

	private func cleanupBindlableState()
	{
		guard isViewLoaded else { return }

		observations.removeAll()
		leftSideButton.action = nil
		leftSideButton.target = nil
	}

	private func updateViews()
	{
		guard isViewLoaded else { return }

		switch titleMode
		{
		case .none, .button(_, .none):
			titleLabel.stringValue = ""
			titleLabel.isHidden = true
			subtitleLabel.stringValue = ""
			subtitleLabel.isHidden = true

		case .subtitle(let title, let subtitle), .button(_, .subtitle(let title, let subtitle)):
			let attrTitle = title.applyingAttributes(Self.titleAttributes)
			let attrSubtitle = subtitle.applyingAttributes(Self.subtitleAttributes)

			titleLabel.attributedStringValue = attrTitle
			titleLabel.isHidden = false
			titleLabel.installEmojiSubviews(using: attrTitle)
			subtitleLabel.attributedStringValue = attrSubtitle
			subtitleLabel.isHidden = false
			subtitleLabel.installEmojiSubviews(using: attrSubtitle)

		case .title(let title), .button(_, .title(let title)):
			let attrTitle = title.applyingAttributes(Self.standaloneTitleAttributes)

			titleLabel.attributedStringValue = attrTitle
			titleLabel.isHidden = false
			titleLabel.installEmojiSubviews(using: attrTitle)
			subtitleLabel.stringValue = ""
			subtitleLabel.isHidden = true
			subtitleLabel.removeAllEmojiSubviews()

		case .button(_, .button(_, _)):
			fatalError("You fucking bastard")
		}

		if case .button(let buttonStateBindable, _) = titleMode
		{
			leftSideButton.isHidden = false
			leftSideButton.action = #selector(SidebarTitleButtonStateBindable.didClickButton(_:))
			leftSideButton.target = buttonStateBindable

			observations.observe(buttonStateBindable, \.icon, sendInitial: true)
			{
				[unowned self] (_, change) in

				if let image = change.newValue
				{
					self.leftSideButton.image = image
				}
			}

			observations.observe(buttonStateBindable, \.accessibilityLabel, sendInitial: true)
			{
				[unowned self] (_, change) in

				if let label = change.newValue
				{
					self.leftSideButton.setAccessibilityLabel(label)
				}
			}

			observations.observe(buttonStateBindable, \.accessibilityTitle, sendInitial: true)
			{
				[unowned self] (_, change) in

				if let title = change.newValue
				{
					self.leftSideButton.setAccessibilityTitle(title)
				}
			}
		}
		else
		{
			leftSideButton.isHidden = true
		}
	}

}
