//
//  HoverView.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 19.02.19.
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

public class HoverView: BorderView
{
	private var hoverTrackingArea: NSTrackingArea? = nil

	public required init?(coder: NSCoder)
	{
		super.init(coder: coder)

		updateHoverTrackingArea()
	}

	private func updateHoverTrackingArea()
	{
		if let oldTrackingArea = hoverTrackingArea
		{
			removeTrackingArea(oldTrackingArea)
		}

		let trackingArea = NSTrackingArea(rect: bounds,
										  options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited],
										  owner: self,
										  userInfo: nil)

		addTrackingArea(trackingArea)
		hoverTrackingArea = trackingArea
	}

	public override var frame: NSRect
	{
		didSet
		{
			updateHoverTrackingArea()
		}
	}
}

public class CallbackHoverView: HoverView
{
	public var mouseEntered: (() -> Void)? = nil
	public var mouseExited: (() -> Void)? = nil

	public override func mouseEntered(with event: NSEvent)
	{
		super.mouseEntered(with: event)

		mouseEntered?()
	}

	public override func mouseExited(with event: NSEvent)
	{
		super.mouseExited(with: event)

		mouseExited?()
	}
}
