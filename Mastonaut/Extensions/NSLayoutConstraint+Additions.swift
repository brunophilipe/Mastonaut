//
//  NSLayoutConstraint+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 11.04.19.
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

extension NSLayoutConstraint
{
	func with(constant: CGFloat) -> Self
	{
		self.constant = constant
		return self
	}

	func with(priority: NSLayoutConstraint.Priority) -> Self
	{
		self.priority = priority
		return self
	}

	static func constraintsEmbedding(view: NSView, in parent: NSView, inset: NSSize = .zero) -> [NSLayoutConstraint]
	{
		return [
			view.leftAnchor.constraint(equalTo: parent.leftAnchor, constant: inset.width),
			parent.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: inset.height),
			parent.rightAnchor.constraint(equalTo: view.rightAnchor, constant: inset.width),
			view.topAnchor.constraint(equalTo: parent.topAnchor, constant: inset.height)
		]
	}
}
