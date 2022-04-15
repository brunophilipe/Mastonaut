//
//  AuthWindowController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 31.12.18.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2018 Bruno Philipe.
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
import WebKit
import MastodonKit

class AuthWindowController: NSWindowController
{
	@IBOutlet private var loadingIndicator: NSProgressIndicator!

	private var webView: WKWebView!

	override var windowNibName: NSNib.Name?
	{
		return "AuthWindowController"
	}

	func loadUrl(_ url: URL)
	{
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			NSWorkspace.shared.open(url)
		}
	}

	@IBAction func cancel(_ sender: Any?)
	{
		window?.dismissSheetOrClose(modalResponse: .cancel)
		AppDelegate.shared.resetAuthorizationState()
	}
}
