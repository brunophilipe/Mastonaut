//
//  PollViewController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 13.06.19.
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
import MastodonKit
import CoreTootin

class PollViewController: NSViewController
{
	@IBOutlet private unowned var stackView: NSStackView!

	@IBOutlet private unowned var voteControlsContainer: NSView!
	@IBOutlet private unowned var voteButton: NSButton!
	@IBOutlet private unowned var voteTaskIndicator: NSProgressIndicator!
	@IBOutlet private unowned var pollEndsOnLabel: NSTextField!
	@IBOutlet private unowned var pollEndingLabel: NSTextField!
	@IBOutlet private unowned var voteCountLabel: NSTextField!

	private typealias ViewSet = (container: NSView, indicator: NSProgressIndicator, ratio: NSTextField, title: NSTextField)

	override var nibName: NSNib.Name?
	{
		return "PollViewController"
	}

	private(set) var poll: Poll?

	private var indexSetValidator: ((IndexSet) -> Bool)!

	weak var delegate: PollViewControllerDelegate?

	private var selectedOptionIndexSet: IndexSet
	{
		let optionButtons = stackView.subviews.compactMap({ $0.tag >= 0 ? $0 as? NSButton : nil })
		return IndexSet(optionButtons.filter({ $0.state == .on }).map({ $0.tag }))
	}

	private let percentageNumberFormatter: NumberFormatter =
		{
			let formatter = NumberFormatter()
			formatter.numberStyle = .percent
			formatter.generatesDecimalNumbers = false
			return formatter
		}()

	override func viewDidLoad()
	{
		super.viewDidLoad()

		if let poll = poll
		{
			setViews(from: poll)
		}

		pollEndingLabel.formatter = RelativeDateFormatter.shared
	}

	func set(poll: Poll)
	{
		guard isViewLoaded else
		{
			self.poll = poll
			return
		}

		setViews(from: poll)
	}

	func setControlsEnabled(_ enabled: Bool)
	{
		voteTaskIndicator.setAnimating(!enabled)
		stackView.subviews.forEach({ ($0 as? NSControl)?.isEnabled = enabled })
	}

	func setHasActiveReloadTask(_ hasTask: Bool)
	{
		voteTaskIndicator.setAnimating(hasTask)
	}

	private func setViews(from poll: Poll)
	{
		let multiple = poll.multiple
		let shouldShowButtons = poll.expired == false && poll.voted == false

		indexSetValidator = { multiple ? $0.count > 0 : $0.count == 1 }
		voteControlsContainer.isHidden = !shouldShowButtons && poll.expiresAt == nil
		stackView.subviews.filter({ $0 is NSButton }).forEach({ $0.removeFromSuperview() })
		voteTaskIndicator.setAnimating(false)
		voteButton.isHidden = !shouldShowButtons
		voteButton.isEnabled = indexSetValidator?(selectedOptionIndexSet) ?? false

		if let endingTime = poll.expiresAt
		{
			pollEndingLabel.objectValue = endingTime
			pollEndsOnLabel.stringValue = endingTime < Date() ? 🔠("status.poll.ended") : 🔠("status.poll.ends")

			pollEndingLabel.isHidden = false
			pollEndsOnLabel.isHidden = false
		}
		else
		{
			pollEndsOnLabel.isHidden = true
			pollEndingLabel.isHidden = true
		}

		if poll.voted == true
		{
			voteCountLabel.stringValue = poll.votesCount == 1 ? 🔠("status.poll.vote")
															  : 🔠("status.poll.votes", poll.votesCount)
			voteCountLabel.isHidden = false
		} else {
			voteCountLabel.isHidden = true
		}

		while stackView.arrangedSubviews.count > 2 {
			stackView.arrangedSubviews.first?.removeFromSuperview()
		}

		for (index, option) in poll.options.enumerated()
		{
			guard index < 200 else { break }

			if shouldShowButtons
			{
				let button: NSButton

				if poll.multiple
				{
					button = .init(checkboxWithTitle: option.title, target: self, action: #selector(didPickOption(_:)))
				}
				else
				{
					button = .init(radioButtonWithTitle: option.title, target: self, action: #selector(didPickOption(_:)))
				}

				button.translatesAutoresizingMaskIntoConstraints = false
				button.title = option.title
				button.tag = index
				button.setContentHuggingPriority(.defaultHigh, for: .vertical)
				button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
				button.lineBreakMode = .byWordWrapping

				stackView.insertArrangedSubview(button, at: index)
			}
			else
			{
				let optionVotes = option.votesCount ?? 0
				let ratio = poll.votesCount > 0 ? Float(optionVotes) / Float(poll.votesCount) : 0
				let ratioString = percentageNumberFormatter.string(from: NSNumber(value: ratio)) ?? "--"

				let viewSet = PollOptionViewController()
				stackView.insertArrangedSubview(viewSet.view, at: index)

				viewSet.progressIndicator.doubleValue = Double(ratio) * 100
				viewSet.ratioLabel.stringValue = ratioString
				viewSet.titleLabel.stringValue = option.title
				viewSet.progressIndicator.toolTip = optionVotes == 1 ? 🔠("status.poll.vote")
																	 : 🔠("status.poll.votes", optionVotes)
			}
		}
	}

	@IBAction private func didPickOption(_ sender: Any?)
	{
		guard
			let optionIndex = (sender as? NSButton)?.tag, optionIndex >= 0,
			let validator = indexSetValidator
		else { return }

		voteButton.isEnabled = validator(selectedOptionIndexSet)
	}

	@IBAction private func didClickVote(_ sender: Any?)
	{
		let optionsIndexSet = selectedOptionIndexSet

		guard let delegate = delegate, let validator = indexSetValidator, validator(optionsIndexSet) else { return }

		setControlsEnabled(false)

		delegate.pollViewController(self, userDidVote: optionsIndexSet)
			{
				[weak self] poll in
				DispatchQueue.main.async
					{
						if let poll = poll
						{
							self?.set(poll: poll)
						}
						else
						{
							self?.setControlsEnabled(true)
						}
					}
			}
	}
}

protocol PollViewControllerDelegate: AnyObject
{
	func pollViewController(_ viewController: PollViewController,
							userDidVote optionIndexSet: IndexSet,
							completion: @escaping (Poll?) -> Void)
}

class PollOptionViewController: NSViewController {
	@IBOutlet var progressIndicator: NSProgressIndicator!
	@IBOutlet var ratioLabel: NSTextField!
	@IBOutlet var titleLabel: NSTextField!

	override var nibName: NSNib.Name? {
		return "PollResultItemView"
	}
}
