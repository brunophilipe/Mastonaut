//
//  AccountsPlaceholderController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 11.03.19.
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
import SVGKit
import CoreTootin

class AccountsPlaceholderController: NSViewController
{
	@IBOutlet private weak var imageView: NSImageView!
	@IBOutlet private weak var collectionView: NSCollectionView!

	@IBOutlet private weak var collectionViewWidthConstraint: NSLayoutConstraint!

	private unowned let accountsService = AppDelegate.shared.accountsService

	private var svgSourceCode: String? = nil
	private var effectiveAppearanceObserver: NSObjectProtocol? = nil
	private var accountsCountObserver: NSKeyValueObservation? = nil

	private lazy var resourcesFetcher = ResourcesFetcher(urlSession: AppDelegate.shared.resourcesUrlSession)

	private var accounts: [AuthorizedAccount]
	{
		return accountsService.authorizedAccounts
	}

	private var collectionViewLayout: NSCollectionViewFlowLayout
	{
		return collectionView.collectionViewLayout as! NSCollectionViewFlowLayout
	}

	override func awakeFromNib()
	{
		super.awakeFromNib()

		guard
			let svgUrl = Bundle.main.url(forResource: "accounts", withExtension: "svg"),
			let svgSourceCode = try? String(contentsOf: svgUrl)
		else { return }

		self.svgSourceCode = svgSourceCode

		effectiveAppearanceObserver = view.observe(\NSView.effectiveAppearance)
			{
				[weak self] (view, change) in

				self?.updatePlaceholderImage()
			}

		accountsCountObserver = accountsService.observe(\.authorizedAccountsCount)
			{
				[weak self] (service, _) in

				self?.collectionView.reloadData()
			}

		collectionView.register(AccountAvatarItem.self, forItemWithIdentifier: ItemIdentifier.avatar)

		let count = accounts.count
		collectionViewWidthConstraint.constant = collectionViewLayout.horizontalContentSize(for: count)
	}

	private func updatePlaceholderImage()
	{
		guard
			let tintColor = NSColor.safeControlTintColor.rgbHexString,
			let tintedSource = svgSourceCode?.replacingOccurrences(of: "#A1B2C3", with: tintColor),
			let svgImage = SVGKImage.make(fromSVGSourceCode: tintedSource)
		else { return }

		imageView.image = svgImage.nsImage
	}

	struct ItemIdentifier
	{
		static let avatar = NSUserInterfaceItemIdentifier("avatarItem")
	}
}

extension AccountsPlaceholderController: NSCollectionViewDataSource
{
	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return accounts.count
	}

	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem
	{
		let item = collectionView.makeItem(withIdentifier: ItemIdentifier.avatar, for: indexPath)

		if let avatarItem = item as? AccountAvatarItem
		{
			let account = accounts[indexPath.item]
			avatarItem.set(account: account, index: indexPath.item)
			avatarItem.set(avatar: #imageLiteral(resourceName: "missing"))

			if let avatarUrl = account.avatarURL
			{
				resourcesFetcher.fetchImage(with: avatarUrl)
					{
						[weak self] result in

						guard case .success(let image) = result else { return }

						DispatchQueue.main.async
							{
								(self?.collectionView?.item(at: indexPath) as? AccountAvatarItem)?.set(avatar: image)
							}
					}
			}
		}

		return item
	}
}

extension AccountsPlaceholderController: NSCollectionViewDelegate
{
	func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>)
	{
		guard let indexPath = indexPaths.first else { return }

		if let timelinesWindowController = view.window?.windowController as? TimelinesWindowController
		{
			timelinesWindowController.currentUser = accounts[indexPath.item].uuid
			timelinesWindowController.updateUserPopUpButton()
		}
	}
}

private extension NSCollectionViewFlowLayout
{
	func horizontalContentSize(for itemCount: Int) -> CGFloat
	{
		if itemCount <= 0 {
			return 0
		}

		let floatCount = CGFloat(itemCount)
		return itemSize.width * floatCount + minimumInteritemSpacing * (floatCount - 1) + sectionInset.horizontal
	}

}

private extension NSEdgeInsets
{
	var horizontal: CGFloat
	{
		return left + right
	}
}
