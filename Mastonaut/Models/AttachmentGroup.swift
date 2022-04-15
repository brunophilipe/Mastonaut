//
//  AttachmentGroup.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 18.02.19.
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
import MastodonKit

protocol AttachmentGroupType: AnyObject
{
	var attachments: [Attachment] { get }
	var attachmentCount: Int { get }

	func preview(for attachment: Attachment) -> NSImage?
	func set(preview: NSImage, for attachment: Attachment)
}

class AttachmentGroup: AttachmentGroupType
{
	let attachments: [Attachment]

	fileprivate var previewMap = [String: NSImage]()

	var attachmentCount: Int
	{
		return attachments.count
	}

	init(attachments: [Attachment])
	{
		self.attachments = attachments
	}

	fileprivate init(attachments: [Attachment], previews: [String: NSImage])
	{
		self.attachments = attachments
		previewMap = previews
	}

	func preview(for attachment: Attachment) -> NSImage?
	{
		return previewMap[attachment.id]
	}

	func set(preview: NSImage, for attachment: Attachment)
	{
		previewMap[attachment.id] = preview
	}
}

class IndexedAttachmentGroup: AttachmentGroupType
{
	private let attachmentGroup: AttachmentGroup

	var currentIndex: Array<Attachment>.Index

	var attachments: [Attachment]
	{
		return attachmentGroup.attachments
	}

	var attachmentCount: Int
	{
		return attachmentGroup.attachmentCount
	}

	fileprivate init(attachmentGroup: AttachmentGroup, initialIndex: Array<Attachment>.Index)
	{
		self.attachmentGroup = attachmentGroup
		self.currentIndex = initialIndex
	}

	func preview(for attachment: Attachment) -> NSImage?
	{
		return attachmentGroup.preview(for: attachment)
	}

	func set(preview: NSImage, for attachment: Attachment)
	{
		attachmentGroup.set(preview: preview, for: attachment)
	}
}

extension AttachmentGroup
{
	func asIndexedGroup(initialIndex: Array<Attachment>.Index) -> IndexedAttachmentGroup
	{
		return IndexedAttachmentGroup(attachmentGroup: self, initialIndex: initialIndex)
	}
}
