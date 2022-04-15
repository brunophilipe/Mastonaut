//
//  CustomEmojiPanelController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 29.05.19.
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

@objc protocol CustomEmojiSelectionHandler: AnyObject
{
	func customEmojiPanel(_: CustomEmojiPanelController, didSelectEmoji: EmojiAdapter)
}

class CustomEmojiPanelController: NSViewController
{
	@IBOutlet private unowned var collectionView: NSCollectionView!
	@IBOutlet private unowned var searchTextField: NSTextField!

	@IBOutlet weak var emojiSelectionHandler: CustomEmojiSelectionHandler?

	private var searchTermObserver: NSKeyValueObservation?
	private var reduceMotionObserver: NSObjectProtocol? = nil
	private var allEmoji: [CacheableEmoji] = []
	private var filteredEmoji: [CacheableEmoji]? = nil

	private var activeEmoji: [CacheableEmoji]
	{
		return filteredEmoji ?? allEmoji
	}

	@objc private dynamic var searchTerm: String = ""

	override func awakeFromNib()
	{
		super.awakeFromNib()

		collectionView.register(EmojiCollectionViewItem.self,
								forItemWithIdentifier: ReuseIdentifiers.emoji)

		reduceMotionObserver = NSAccessibility.observeReduceMotionPreference() {
			[weak self] in
			self?.didChangeReduceMotionPreference(shouldReduceMotion: NSAccessibility.shouldReduceMotion)
		}

		searchTermObserver = observe(\CustomEmojiPanelController.searchTerm, options: [.new, .old])
		{
			(controller, change) in
			controller.filterEmoji(using: change.newValue ?? "", previousSearchTerm: change.oldValue ?? "")
		}
	}

	func setEmoji(_ emoji: [CacheableEmoji])
	{
		self.filteredEmoji = nil
		self.allEmoji = emoji
		collectionView.reloadData()

		if !searchTerm.isEmpty
		{
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, searchTerm] in
				self?.filterEmoji(using: searchTerm, previousSearchTerm: "")
			}
		}
	}

	func didChangeReduceMotionPreference(shouldReduceMotion: Bool)
	{
		for item in collectionView.visibleItems()
		{
			(item as? EmojiCollectionViewItem)?.animates = !shouldReduceMotion
		}
	}

	private func reset()
	{
		assert(Thread.isMainThread)
		filteredEmoji = nil
		allEmoji.removeAll()
		collectionView.reloadData()
	}

	private func filterEmoji(using searchTerm: String, previousSearchTerm: String)
	{
		guard searchTerm.isEmpty == false else
		{
			guard let filteredEmoji = self.filteredEmoji else
			{
				return
			}

			let previouslyFiltered = Set(filteredEmoji)
			self.filteredEmoji = nil

			let indicesToInsert = allEmoji.indices(elementIsIncluded: { !previouslyFiltered.contains($0) })

			guard !indicesToInsert.isEmpty else { return }
			collectionView.animator().insertItems(at: IndexPath.set(items: indicesToInsert))

			return
		}

		if searchTerm.lowercased().hasPrefix(previousSearchTerm.lowercased())
		{
			var emojiToFilter = activeEmoji

			let indicesToRemove = emojiToFilter.removeAllReturningIndices(where: { !$0.matches(searchTerm) })
			guard !indicesToRemove.isEmpty else { return }
			self.filteredEmoji = emojiToFilter
			collectionView.animator().deleteItems(at: IndexPath.set(items: indicesToRemove))
		}
		else
		{
			let matching = allEmoji.filter({ $0.matches(searchTerm) })
			let matchingSet = Set(matching)

			var oldMatching = self.filteredEmoji ?? []
			let oldMatchingSet = Set(oldMatching)

			let indicesToInsert = matching.indices(elementIsIncluded: { !oldMatchingSet.contains($0) })
			let indicesToRemove = oldMatching.removeAllReturningIndices(where: { !matchingSet.contains($0) })

			guard (indicesToInsert.isEmpty && indicesToRemove.isEmpty) == false else { return }

			self.filteredEmoji = matching

			collectionView.animator().performBatchUpdates(
				{
					if !indicesToInsert.isEmpty
					{
						collectionView.insertItems(at: IndexPath.set(items: indicesToInsert))
					}

					if !indicesToRemove.isEmpty
					{
						collectionView.deleteItems(at: IndexPath.set(items: indicesToRemove))
					}
				})
		}
	}

	private enum ReuseIdentifiers
	{
		static let emoji = NSUserInterfaceItemIdentifier(rawValue: "emoji")
	}
}

extension CustomEmojiPanelController: NSCollectionViewDataSource
{
	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return activeEmoji.count
	}

	func collectionView(_ collectionView: NSCollectionView,
						itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem
	{
		let item = collectionView.makeItem(withIdentifier: ReuseIdentifiers.emoji, for: indexPath)
		return item
	}

	func collectionView(_ collectionView: NSCollectionView,
						willDisplay item: NSCollectionViewItem,
						forRepresentedObjectAt indexPath: IndexPath)
	{
		if let emojiItem = item as? EmojiCollectionViewItem
		{
			let emoji = activeEmoji[indexPath.item]
			let emojiHashValue = emoji.hashValue

			emojiItem.setEmojiTooltip(from: emoji)
			emojiItem.displayedItemHashValue = emojiHashValue

			AppDelegate.shared.customEmojiCache.cachedEmoji(with: emoji.url, fetchIfNeeded: true)
			{
				[weak emojiItem, weak self] emojiData in

				DispatchQueue.main.async
					{
						func setImage(in item: EmojiCollectionViewItem, data: Data?)
						{
							if let data = emojiData
							{
								item.setEmojiImage(from: data)
								item.animates = !NSAccessibility.shouldReduceMotion
							}
							else
							{
								item.imageView?.image = #imageLiteral(resourceName: "ellipsis.pdf")
							}
						}

						if let item = emojiItem, item.displayedItemHashValue == emojiHashValue
						{
							setImage(in: item, data: emojiData)
						}
						else if let index = self?.activeEmoji.firstIndex(where: { $0.hashValue == emojiHashValue }),
							let item = self?.collectionView.item(at: index) as? EmojiCollectionViewItem
						{
							setImage(in: item, data: emojiData)
						}
					}
			}
		}
	}
}

extension CustomEmojiPanelController: NSPopoverDelegate
{
	func popoverWillShow(_ notification: Foundation.Notification)
	{
		collectionView.visibleItems().forEach({ ($0 as? EmojiCollectionViewItem)?.animates = true })
	}

	func popoverDidClose(_ notification: Foundation.Notification)
	{
		collectionView.visibleItems().forEach({ ($0 as? EmojiCollectionViewItem)?.animates = false })
	}
}

extension CustomEmojiPanelController: NSCollectionViewDelegate
{
	func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>)
	{
		collectionView.deselectItems(at: indexPaths)

		guard let handler = emojiSelectionHandler, let emoji = (indexPaths.first?.item).map({ activeEmoji[$0] }) else
		{
			return
		}

		handler.customEmojiPanel(self, didSelectEmoji: EmojiAdapter(emoji))
	}
}

extension CustomEmojiPanelController: NavigationTextFieldDelegate
{
	func textField(_ textField: NavigationTextField, didStartNavigationModeFrom direction: NavigationTextField.Source)
	{
		guard !activeEmoji.isEmpty else { return }

		switch direction
		{
		case .bottom:
			collectionView.selectItems(at: IndexPath.set(items: [activeEmoji.index(before: activeEmoji.endIndex)]),
									   scrollPosition: [])

		case .top:
			collectionView.selectItems(at: IndexPath.set(items: [activeEmoji.startIndex]),
									   scrollPosition: [])
		}
	}

	func textFieldDidCancelNavigationMode(_ textField: NavigationTextField)
	{
		collectionView.deselectAll(textField)
	}

	func textFieldDidCommitNavigationMode(_ textField: NavigationTextField)
	{
		if let handler = emojiSelectionHandler,
			let emoji = collectionView.selectionIndexes.first.map({ activeEmoji[$0] })
		{
			handler.customEmojiPanel(self, didSelectEmoji: EmojiAdapter(emoji))
		}

		collectionView.deselectAll(textField)
	}

	func textField(_ textField: NavigationTextField, didNavigate direction: NavigationTextField.Direction)
	{
		let selectedIndex = collectionView.selectionIndexes.first ?? 0
		let itemsPerRow = collectionView.itemsPerRow
		let nextIndex: IndexSet.Element
		let scrollPostion: NSCollectionView.ScrollPosition

		switch direction
		{
		case .up where itemsPerRow > 0 && selectedIndex >= itemsPerRow:
			nextIndex = selectedIndex - itemsPerRow
			scrollPostion = [.top]
		case .down where itemsPerRow > 0 && selectedIndex < activeEmoji.count - itemsPerRow:
			nextIndex = selectedIndex + itemsPerRow
			scrollPostion = [.bottom]
		case .left where selectedIndex > 0:
			nextIndex = selectedIndex - 1
			scrollPostion = [.left, .top]
		case .right where selectedIndex < activeEmoji.count - 1:
			nextIndex = selectedIndex + 1
			scrollPostion = [.right, .bottom]
		default:
			return
		}

		collectionView.deselectAll(textField)

		let frameForItem = collectionView.frameForItem(at: nextIndex)
		if collectionView.visibleRect.contains(frameForItem)
		{
			// No need for scrolling
			collectionView.selectItems(at: IndexPath.set(items: [nextIndex]), scrollPosition: [])
		}
		else
		{
			collectionView.selectItems(at: IndexPath.set(items: [nextIndex]), scrollPosition: [scrollPostion])
		}
	}
}

extension CacheableEmoji: Comparable
{
	func matches(_ searchTerm: String) -> Bool
	{
		return shortcode.lowercased().contains(searchTerm.lowercased())
	}

	public static func < (lhs: CacheableEmoji, rhs: CacheableEmoji) -> Bool
	{
		return lhs.shortcode.localizedCaseInsensitiveCompare(rhs.shortcode) == .orderedAscending
	}

	public static func == (lhs: CacheableEmoji, rhs: CacheableEmoji) -> Bool
	{
		return lhs.shortcode == rhs.shortcode
	}
}

@objc class EmojiAdapter: NSObject
{
	let emoji: CacheableEmoji

	init(_ emoji: CacheableEmoji)
	{
		self.emoji = emoji
		super.init()
	}
}

private extension NSCollectionView
{
	var itemsPerRow: Int
	{
		guard let flowLayout = collectionViewLayout as? NSCollectionViewFlowLayout else { return 0 }
		let maxItemsPerRow = Int(frame.width / flowLayout.itemSize.width)
		let minItemsWidth = CGFloat(maxItemsPerRow) * flowLayout.itemSize.width

		if CGFloat(maxItemsPerRow - 1) * flowLayout.minimumInteritemSpacing + minItemsWidth > frame.width
		{
			return maxItemsPerRow - 1
		}
		else
		{
			return maxItemsPerRow
		}
	}
}
