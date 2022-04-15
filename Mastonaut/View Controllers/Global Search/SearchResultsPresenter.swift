//
//  SearchResultsPresenter.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 30.06.19.
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

protocol SearchResultsPresenter: NSViewController
{
	var delegate: SearchResultsPresenterDelegate? { get set }

	func set(results: ResultsType, instance: Instance)
}

protocol SearchResultsPresenterDelegate: AnyObject
{
	func searchResultsPresenter(_ presenter: SearchResultsPresenter, userDidSelect selection: SearchResultSelection?)
	func searchResultsPresenter(_ presenter: SearchResultsPresenter, userDidDoubleClick selection: SearchResultSelection)
}

enum SearchResultSelection: Equatable
{
	case account(Account)
	case status(Status)
	case tag(String)

	static func == (lhs: SearchResultSelection, rhs: SearchResultSelection) -> Bool
	{
		switch (lhs, rhs)
		{
		case (.account(let a1), .account(let a2)):
			return a1.id == a2.id

		case (.status(let s1), .status(let s2)):
			return s1.id == s2.id

		case (.tag(let t1), .tag(let t2)):
			return t1 == t2

		default:
			return false
		}
	}
}
