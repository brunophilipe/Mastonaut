//
//  ComposerPollViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 23.06.19.
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

class ComposerPollViewController: NSViewController, InitialKeyViewProviding
{
	@IBOutlet private unowned var stackView: NSStackView!
	@IBOutlet private unowned var choiceCountPopUpButton: NSPopUpButton!
	@IBOutlet private unowned var durationPopUpButton: NSPopUpButton!

	weak var nextKeyView: NSView?
	{
		didSet
		{
			options.last?.titleTextField.nextKeyView = nextKeyView
		}
	}

	private var options: [OptionViewSet] = ["", ""]
	{
		willSet { willChangeValue(for: \.canRemoveOptions); willChangeValue(for: \.canAddOptions) }
		didSet { didChangeValue(for: \.canRemoveOptions); didChangeValue(for: \.canAddOptions) }
	}

	@objc dynamic var canAddOptions: Bool
	{
		return options.count < 4
	}

	@objc dynamic var canRemoveOptions: Bool
	{
		return options.count > 2
	}

	@objc dynamic var allOptionsAreValid: Bool = false

	@objc dynamic var isDirty: Bool = false

	override func awakeFromNib()
	{
		super.awakeFromNib()

		installInitialOptionViews()

		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .full

		let intervals: [TimeInterval] = [300, 1800, 3600, 21600, 86400, 259200, 604800]
		durationPopUpButton.menu?.setItems(intervals.map({ NSMenuItem(formatter.string(from: $0), object: $0) }))
	}

	var initialKeyView: NSView?
	{
		return options.first?.titleTextField
	}

	var optionTitles: [String]
	{
		get { return options.map({ $0.titleTextField.stringValue }) }
		set { reset(options: newValue) }
	}

	var pollDuration: TimeInterval
	{
		return durationPopUpButton.selectedItem?.representedObject as? TimeInterval ?? 300
	}

	var multipleChoice: Bool
	{
		return choiceCountPopUpButton.selectedItem?.representedObject as? Bool ?? false
	}

	func reset()
	{
		self.reset(options: ["", ""])
	}

	private func reset(options: [String])
	{
		(0..<self.options.count).forEach({ _ in removeOption(at: 0) })
		self.options = options.map({ OptionViewSet(title: $0) })
		installInitialOptionViews()
	}

	private func installInitialOptionViews()
	{
		for (index, option) in options.enumerated()
		{
			install(option: option, at: index, animated: false)
		}
	}

	private func install(option: OptionViewSet, at index: Int, animated: Bool = true)
	{
		let stackView: NSStackView = animated ? self.stackView.animator() : self.stackView

		stackView.insertArrangedSubview(option.container, at: index)

		option.removeButton.bind(.enabled, to: self, withKeyPath: "canRemoveOptions", options: nil)
		option.removeButton.target = self

		if index > 0
		{
			options[index - 1].titleTextField.nextKeyView = option.titleTextField
		}

		option.titleTextField.nextKeyView = nextKeyView
		option.titleTextField.delegate = self

		updateAllOptionsAreValid()
		updateIsDirty()
	}

	private func removeOption(at index: Int)
	{
		let option = options.remove(at: index)
		option.titleTextField.previousKeyView?.nextKeyView = option.titleTextField.nextKeyView
		option.container.animator().removeFromSuperview()

		updateAllOptionsAreValid()
		updateIsDirty()
	}

	private func checkAllOptionTitlesValid() -> Bool
	{
		for option in options
		{
			if option.titleTextField.stringValue.isEmpty { return false }
		}

		return true
	}

	private func updateAllOptionsAreValid()
	{
		let allOptionsAreValid = checkAllOptionTitlesValid()
		if allOptionsAreValid != self.allOptionsAreValid
		{
			self.allOptionsAreValid = allOptionsAreValid
		}
	}

	private func checkIsDirty() -> Bool
	{
		for option in options
		{
			if option.titleTextField.stringValue.isEmpty == false { return true }
		}

		return false
	}

	private func updateIsDirty()
	{
		let isDirty = checkIsDirty()
		if isDirty != self.isDirty
		{
			self.isDirty = isDirty
		}
	}

	@IBAction private func addOption(_ sender: Any?)
	{
		guard canAddOptions else { return }

		let newOption = OptionViewSet(title: "")
		let newOptionIndex = options.count
		options.append(newOption)

		install(option: newOption, at: newOptionIndex)
	}

	@IBAction func removeOption(_ sender: Any?)
	{
		guard canRemoveOptions, let button = sender as? NSButton else { return }
		guard let index = options.firstIndex(where: { $0.removeButton === button }) else { return }

		removeOption(at: index)
	}

	class OptionViewSet: NSObject, ExpressibleByStringLiteral
	{
		typealias StringLiteralType = String

		let container: NSStackView
		unowned let titleTextField: NSTextField
		unowned let removeButton: NSButton

		var title: String
		{
			return titleTextField.stringValue
		}

		init(title: String = "")
		{
			let titleTextField = NSTextField(string: title)
			titleTextField.translatesAutoresizingMaskIntoConstraints = false
			titleTextField.bezelStyle = .roundedBezel
			titleTextField.drawsBackground = true
			titleTextField.backgroundColor = .textBackgroundColor
			titleTextField.placeholderString = 🔠("Poll Option Title")

			let removeButton = NSButton(image: NSImage(named: NSImage.removeTemplateName)!,
										target: nil,
										action: #selector(ComposerPollViewController.removeOption(_:)))
			removeButton.translatesAutoresizingMaskIntoConstraints = false
			removeButton.imagePosition = .imageLeading
			removeButton.bezelStyle = .texturedRounded
			removeButton.title = 🔠("Remove")

			container = NSStackView(views: [titleTextField, removeButton])
			container.translatesAutoresizingMaskIntoConstraints = false
			container.orientation = .horizontal

			self.titleTextField = titleTextField
			self.removeButton = removeButton

			super.init()
		}

		required convenience init(stringLiteral value: String)
		{
			self.init(title: value)
		}
	}
}

extension ComposerPollViewController: NSTextFieldDelegate
{
	func controlTextDidChange(_ obj: Notification)
	{
		updateAllOptionsAreValid()
		updateIsDirty()
	}
}
