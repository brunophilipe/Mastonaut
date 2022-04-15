//
//  AuthorizedAccountProviding.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 07.04.19.
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
import CoreTootin

protocol AuthorizedAccountProviding: AttributedLabelLinkHandler
{
	var currentAccount: AuthorizedAccount? { get }
	var currentInstance: Instance? { get }
	var attachmentPresenter: AttachmentPresenting { get }

	func composeReply(for status: Status, sender: Any?)
	func composeMention(userHandle: String, directMessage: Bool)
	func redraft(status: Status)

	func handle(linkURL: URL, knownTags: [Tag]?)

	func presentInSidebar(_ mode: SidebarModel)
}
