//
//  NoInsetsTableView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 04.07.20.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2020 Bruno Philipe.
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

class NoInsetsTableView: NSTableView {
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		if #available(OSX 11.0, *), let clipView = enclosingScrollView?.contentView {
			clipView.automaticallyAdjustsContentInsets = false
			clipView.contentInsets.top = -6
			clipView.contentInsets.left = -6
			clipView.contentInsets.right = -6
		}
	}
}
