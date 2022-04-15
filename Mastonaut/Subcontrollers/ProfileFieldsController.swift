//
//  ProfileFieldsController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 31.03.19.
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
import MastodonKit
import CoreTootin

class ProfileFieldsController: NSObject
{
	@IBOutlet private unowned var stackView: NSStackView!

	@IBOutlet private unowned var firstFieldNameLabel: NSTextField!
	@IBOutlet private unowned var secondFieldNameLabel: NSTextField!
	@IBOutlet private unowned var thirdFieldNameLabel: NSTextField!
	@IBOutlet private unowned var fourthFieldNameLabel: NSTextField!

	@IBOutlet private unowned var firstFieldValueLabel: AttributedLabel!
	@IBOutlet private unowned var secondFieldValueLabel: AttributedLabel!
	@IBOutlet private unowned var thirdFieldValueLabel: AttributedLabel!
	@IBOutlet private unowned var fourthFieldValueLabel: AttributedLabel!

	@IBOutlet private unowned var firstFieldContainerView: BackgroundView!
	@IBOutlet private unowned var secondFieldContainerView: BackgroundView!
	@IBOutlet private unowned var thirdFieldContainerView: BackgroundView!
	@IBOutlet private unowned var fourthFieldContainerView: BackgroundView!

	@IBOutlet private unowned var firstFieldCheckmarkButton: NSButton!
	@IBOutlet private unowned var secondFieldCheckmarkButton: NSButton!
	@IBOutlet private unowned var thirdFieldCheckmarkButton: NSButton!
	@IBOutlet private unowned var fourthFieldCheckmarkButton: NSButton!

	static let normalBackgroundColor: NSColor =
		{
			if #available(OSX 10.14, *) {
				return NSColor.alternatingContentBackgroundColors.last ?? .windowBackgroundColor
			} else {
				return .windowBackgroundColor
			}
		}()

	static let normalForegroundColor: NSColor = .labelColor
	static let verifiedForegroundColor: NSColor = .systemGreen

	private static let sharedParagraphStyle: NSParagraphStyle =
		{
			let paragraphStyle = NSParagraphStyle.default
			return paragraphStyle
		}()

	private static let nameLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
		.paragraphStyle: sharedParagraphStyle
	]

	private static let verifiedNameLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.systemGreen, .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
		.paragraphStyle: sharedParagraphStyle
	]

	private static let valueLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.labelColor, .font: NSFont.labelFont(ofSize: 13),
		.paragraphStyle: sharedParagraphStyle
	]

	private static let verifiedValueLabelAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.systemGreen, .font: NSFont.labelFont(ofSize: 13),
		.paragraphStyle: sharedParagraphStyle
	]

	private static let valueLabelLinkAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.safeControlTintColor, .font: NSFont.systemFont(ofSize: 13, weight: .medium),
		.paragraphStyle: sharedParagraphStyle
	]

	private static let valueLabelVerifiedLinkAttributes: [NSAttributedString.Key: AnyObject] = [
		.foregroundColor: NSColor.systemGreen, .font: NSFont.systemFont(ofSize: 13, weight: .medium),
		.paragraphStyle: sharedParagraphStyle
	]

	func set(account: Account?)
	{
		let fields: [VerifiableMetadataField] = account?.fields ?? []

		guard !fields.isEmpty else
		{
			stackView.isHidden = true
			return
		}

		stackView.isHidden = false

		let controls: [(container: BackgroundView, name: NSTextField, value: AttributedLabel, check: NSButton)] = [
			(firstFieldContainerView, firstFieldNameLabel, firstFieldValueLabel, firstFieldCheckmarkButton),
			(secondFieldContainerView, secondFieldNameLabel, secondFieldValueLabel, secondFieldCheckmarkButton),
			(thirdFieldContainerView, thirdFieldNameLabel, thirdFieldValueLabel, thirdFieldCheckmarkButton),
			(fourthFieldContainerView, fourthFieldNameLabel, fourthFieldValueLabel, fourthFieldCheckmarkButton)
		]

		for (index, controlSet) in controls.enumerated()
		{
			guard index < fields.count else
			{
				controlSet.container.isHidden = true
				continue
			}

			let field = fields[index]
			let isVerified = field.verification != nil

			controlSet.container.isHidden = false
			controlSet.name.stringValue = field.name

			if isVerified
			{
				controlSet.container.backgroundColor = NSColor(named: "VerifiedFieldBackground")!
				controlSet.name.textColor = ProfileFieldsController.verifiedForegroundColor

				controlSet.value.textColor = ProfileFieldsController.verifiedForegroundColor
				controlSet.value.linkTextAttributes = ProfileFieldsController.valueLabelVerifiedLinkAttributes
				controlSet.value.set(attributedStringValue: HTMLParsingService.shared.parse(HTML: field.value),
									 applyingAttributes: ProfileFieldsController.verifiedValueLabelAttributes,
									 applyingEmojis: account?.cacheableEmojis)
			}
			else
			{
				controlSet.container.backgroundColor = ProfileFieldsController.normalBackgroundColor
				controlSet.name.textColor = ProfileFieldsController.normalForegroundColor

				controlSet.value.textColor = ProfileFieldsController.normalForegroundColor
				controlSet.value.linkTextAttributes = ProfileFieldsController.valueLabelLinkAttributes
				controlSet.value.set(attributedStringValue: HTMLParsingService.shared.parse(HTML: field.value),
									 applyingAttributes: ProfileFieldsController.valueLabelAttributes,
									 applyingEmojis: account?.cacheableEmojis)
			}

			controlSet.name.isSelectable = true
			controlSet.value.selectableAfterFirstClick = true
			controlSet.check.isHidden = !isVerified
		}
	}

	func set(linkHandler: AttributedLabelLinkHandler)
	{
		let labels = [firstFieldValueLabel, secondFieldValueLabel, thirdFieldValueLabel, fourthFieldValueLabel]
		labels.forEach({ $0?.linkHandler = linkHandler })
	}
}

extension ProfileFieldsController: RichTextCapable
{
	func set(shouldDisplayAnimatedContents animates: Bool)
	{
		let labels = [firstFieldValueLabel!, secondFieldValueLabel!, thirdFieldValueLabel!, fourthFieldValueLabel!]
		labels.compactMap({ $0.animatedEmojiImageViews }).flatMap({ $0 }).forEach({ $0.animates = animates })
	}
}
