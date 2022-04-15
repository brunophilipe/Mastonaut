//
//  TrackingLayoutConstraint.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 01.04.19.
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

class TrackingLayoutConstraint: NSLayoutConstraint
{
	private var observations = [NSKeyValueObservation]()
	private var updateBlock: (() -> Void)?

	static func constraint(trackingMidXOf sourceView: NSView,
						   offset: CGFloat = 0,
						   targetView: NSView,
						   containerView: NSView,
						   targetAttribute: NSLayoutConstraint.Attribute,
						   containerAttribute: NSLayoutConstraint.Attribute) -> TrackingLayoutConstraint
	{
		return constraint(tracking: sourceView, tracker: { $0.midX }, offset: offset,
						  targetView: targetView, containerView: containerView,
						  targetAttribute: targetAttribute, containerAttribute: containerAttribute)
	}

	static func constraint(trackingMinXOf sourceView: NSView,
						   offset: CGFloat = 0,
						   targetView: NSView,
						   containerView: NSView,
						   targetAttribute: NSLayoutConstraint.Attribute,
						   containerAttribute: NSLayoutConstraint.Attribute) -> TrackingLayoutConstraint
	{
		return constraint(tracking: sourceView, tracker: { $0.minX }, offset: offset,
						  targetView: targetView, containerView: containerView,
						  targetAttribute: targetAttribute, containerAttribute: containerAttribute)
	}

	static func constraint(trackingMaxXOf sourceView: NSView,
						   offset: CGFloat = 0,
						   targetView: NSView,
						   containerView: NSView,
						   targetAttribute: NSLayoutConstraint.Attribute,
						   containerAttribute: NSLayoutConstraint.Attribute) -> TrackingLayoutConstraint
	{
		return constraint(tracking: sourceView, tracker: { $0.maxX }, offset: offset,
						  targetView: targetView, containerView: containerView,
						  targetAttribute: targetAttribute, containerAttribute: containerAttribute)
	}

	private static func constraint(tracking sourceView: NSView,
								   tracker: @escaping (NSRect) -> CGFloat,
								   offset: CGFloat = 0,
								   targetView: NSView,
								   containerView: NSView,
								   targetAttribute: NSLayoutConstraint.Attribute,
								   containerAttribute: NSLayoutConstraint.Attribute) -> TrackingLayoutConstraint
	{
		let constraint = TrackingLayoutConstraint(item: targetView, attribute: targetAttribute, relatedBy: .equal,
												  toItem: containerView, attribute: containerAttribute,
												  multiplier: 1.0, constant: 0.0)

		constraint.updateBlock =
			{
				[weak constraint, weak sourceView] in
				assert(Thread.isMainThread)
				guard let view = sourceView, let constraint = constraint else { return }
				constraint.constant = tracker(view.frame) + offset
			}

		constraint.observations.observe(sourceView, \.frame, sendInitial: true)
			{
				[weak constraint] (_, _) in constraint?.updateBlock?()
			}

		constraint.observations.observe(sourceView, \.superview, sendInitial: true)
			{
				[weak constraint] (_, _) in constraint?.updateBlock?()
			}

		return constraint
	}

	func updateConstraintTracking()
	{
		updateBlock?()
	}
}
