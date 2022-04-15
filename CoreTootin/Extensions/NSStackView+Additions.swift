//
//  NSStackView+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 13.02.19.
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

public extension NSStackView
{
	func setArrangedSubview(_ subview: NSView, hidden: Bool, animated: Bool, completion: (() -> Void)? = nil)
	{
		guard animated else
		{
			subview.isHidden = hidden
			completion?()
			return
		}

		NSAnimationContext.runAnimationGroup(
			{
				[weak superview] context in

				context.allowsImplicitAnimation = true
				context.duration = 0.25
				subview.isHidden = hidden
				superview?.layoutSubtreeIfNeeded()
			}, completionHandler: completion)
	}
}
