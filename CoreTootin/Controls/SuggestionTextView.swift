//
//  SuggestionTextView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 10.06.19.
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

import AppKit

open class SuggestionTextView: NSTextView
{
	public weak var suggestionsProvider: SuggestionTextViewSuggestionsProvider? = nil

	public weak var imagesProvider: SuggestionWindowImagesProvider?
	{
		get { return suggestionWindowController.imagesProvider }
		set { suggestionWindowController.imagesProvider = newValue }
	}

	public private(set) lazy var suggestionWindowController = SuggestionWindowController()

	private var lastSuggestionRequestId: UUID?

	public override func moveUp(_ sender: Any?)
	{
		guard suggestionWindowController.isWindowVisible else
		{
			super.moveUp(sender)
			return
		}

		suggestionWindowController.selectPrevious(sender)
	}

	public override func moveDown(_ sender: Any?)
	{
		guard suggestionWindowController.isWindowVisible else
		{
			super.moveDown(sender)
			return
		}

		suggestionWindowController.selectNext(sender)
	}

	public override func cancelOperation(_ sender: Any?)
	{
		guard suggestionWindowController.isWindowVisible else
		{
			return
		}

		dismissSuggestionsWindow()
	}
	
	open func textStorage(_ textStorage: NSTextStorage,
						  didProcessEditing editedMask: NSTextStorageEditActions,
						  range editedRange: NSRange,
						  changeInLength delta: Int)
	{
		guard
			undoManager?.isUndoing != true,
			editedMask.contains(.editedCharacters)
		else { return }

		DispatchQueue.main.async
			{
				self.dispatchSuggestionsFetch()
			}
	}

	public func dispatchSuggestionsFetch()
	{
		SuggestionTextView.cancelPreviousPerformRequests(withTarget: self,
														 selector: #selector(reallyDispatchSuggestionsFetch),
														 object: nil)

		perform(#selector(reallyDispatchSuggestionsFetch), with: nil, afterDelay: 0.33)
	}

	public func dismissSuggestionsWindow()
	{
		suggestionWindowController.close()
	}

	public func insertCurrentlySelectedSuggestion()
	{
		suggestionWindowController.insertSelectedSuggestion()
		dismissSuggestionsWindow()
	}

	// MARK: Private Stuff

	@objc private func reallyDispatchSuggestionsFetch()
	{
		let selection = selectedRange()
		let string = self.string

		guard
			selection.length == 0,
			let provider = suggestionsProvider,
			let (mention, range) = string.mentionUpTo(index: selection.location)
		else
		{
			dismissSuggestionsWindow()
			return
		}

		let requestId = UUID()
		lastSuggestionRequestId = requestId

		provider.suggestionTextView(self, suggestionsForMention: mention)
		{
			[weak self] suggestions in

			guard !suggestions.isEmpty else
			{
				DispatchQueue.main.async { self?.dismissSuggestionsWindow() }
				return
			}

			DispatchQueue.main.async
				{
					guard self?.lastSuggestionRequestId == requestId else { return }
					self?.showSuggestionsWindow(with: suggestions, mentionRange: range)
				}
		}
	}

	private func showSuggestionsWindow(with suggestions: [Suggestion], mentionRange: NSRange)
	{
		guard
			mentionRange.upperBound <= (textStorage?.length ?? 0),
			let window = self.window,
			let layoutManager = self.layoutManager,
			let textContainer = self.textContainer
		else
		{
			dismissSuggestionsWindow()
			return
		}

		let glyphRange = layoutManager.glyphRange(forCharacterRange: mentionRange, actualCharacterRange: nil)
		let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
		let offsetRect = convert(rect.offsetBy(dx: textContainerInset.width, dy: textContainerInset.height), to: nil)
		let screenRect = window.convertToScreen(offsetRect)

		suggestionWindowController.set(suggestions: suggestions)
		suggestionWindowController.showWindow(nil)

		suggestionWindowController.insertSuggestionBlock =
			{
				[weak self] suggestion in
				guard let self = self else { return }
				self.replaceCharacters(in: mentionRange, with: "\(suggestion.text) ")
			}

		suggestionWindowController.positionWindow(under: screenRect)
	}
}

@objc public protocol SuggestionTextViewSuggestionsProvider: AnyObject
{
	func suggestionTextView(_ textView: SuggestionTextView,
							suggestionsForMention: String,
							completion: @escaping ([Suggestion]) -> Void)
}

@objc public protocol Suggestion {
	var text: String { get }
	var imageUrl: URL? { get }
	var displayName: String { get }
}

private extension NSString
{
	func mentionUpTo(index: Int) -> (mention: String, range: NSRange)?
	{
		guard length > 0, index <= length else { return nil }

		var previous＠CharacterIndex: Int? = nil
		let charset＠ = NSCharacterSet(charactersIn: "@")

		for charIndex in (0..<index).reversed()
		{
			let char = character(at: charIndex)

			if (CharacterSet.whitespacesAndNewlines as NSCharacterSet).characterIsMember(char)
			{
				if let ＠CharacterIndex = previous＠CharacterIndex
				{
					let mentionRange = NSMakeRange(＠CharacterIndex, index - ＠CharacterIndex)
					let mention = substring(with: mentionRange)
					return (mention, mentionRange)
				}

				// Found an empty space character before an `@` character
				return nil
			}
			else if charset＠.characterIsMember(char), index - charIndex > 1
			{
				if previous＠CharacterIndex != nil
				{
					let mentionRange = NSMakeRange(charIndex, index - charIndex)
					let mention = substring(with: mentionRange)
					return (mention, mentionRange)
				}

				previous＠CharacterIndex = charIndex
			}
		}

		if let ＠CharacterIndex = previous＠CharacterIndex
		{
			let mentionRange = NSMakeRange(＠CharacterIndex, index - ＠CharacterIndex)
			let mention = substring(with: mentionRange)
			return (mention, mentionRange)
		}

		// We never found an `@` character...
		return nil
	}
}
