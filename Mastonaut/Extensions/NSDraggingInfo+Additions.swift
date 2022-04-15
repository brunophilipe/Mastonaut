//
//  NSDraggingInfo+Additions.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 27.02.19.
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

extension NSDraggingInfo
{
	var firstDraggedFileURL: URL?
	{
		return draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])?.first as? URL
	}

	var draggedFileUrls: [URL]?
	{
		return draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]
	}

	var draggedImages: [NSImage]?
	{
		return draggingPasteboard.readObjects(forClasses: [NSImage.self], options: [:]) as? [NSImage]
	}
}
