//
//  NSView+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 16.02.19.
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

extension NSView
{
	func setHidden(_ shouldHide: Bool, animated: Bool)
	{
		if isHidden == shouldHide
		{
			// Nothing to do
			return
		}

		guard animated else
		{
			isHidden = shouldHide
			return
		}

		if !shouldHide, isHidden
		{
			isHidden = false
		}

		NSAnimationContext.runAnimationGroup({ _ in self.animator().alphaValue = shouldHide ? 0.0 : 1.0 },
											 completionHandler: { self.isHidden = shouldHide })
	}

	/// Hides a view without changing the `isHidden` property. Caution: if `isHidden` is already `true`, then
	/// this method does nothing.
	func setInvisible(_ shouldHide: Bool, animated: Bool)
	{
		guard !isHidden else { return }
		animator().alphaValue = shouldHide ? 0.0 : 1.0
	}

	func firstParentViewInsideSplitView() -> NSView {
		findSuperview { $0?.superview?.className == "NSSplitView" } ?? self
	}
}
