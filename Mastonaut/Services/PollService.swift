//
//  PollService.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 17.06.19.
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

struct PollService
{
	let client: ClientType

	func voteOn(poll: Poll, options: IndexSet, completion: @escaping (Swift.Result<Poll, Errors>) -> Void)
	{
		guard !options.isEmpty && (poll.multiple || options.count == 1) else
		{
			completion(.failure(.invalidOptionsCount))
			return
		}

		client.run(Polls.vote(pollID: poll.id, optionIndices: options))
		{
			result in

			switch result
			{
			case .failure(ClientError.badStatus(statusCode: let status)):
				completion(.failure(.serverError(info: "Bad Status: \(status)")))

			case .failure(let error):
				completion(.failure(.serverError(info: error.localizedDescription)))

			case .success(let poll, _):
				completion(.success(poll))
			}
		}
	}

	func poll(pollID: String, completion: @escaping (Swift.Result<Poll, Errors>) -> Void)
	{
		client.run(Polls.poll(id: pollID))
		{
			result in

			switch result
			{
			case .failure(ClientError.badStatus(statusCode: let status)):
				completion(.failure(.serverError(info: "Bad Status: \(status)")))

			case .failure(let error):
				completion(.failure(.serverError(info: error.localizedDescription)))

			case .success(let poll, _):
				completion(.success(poll))
			}
		}
	}

	enum Errors: Error, UserDescriptionError
	{
		case invalidOptionsCount
		case serverError(info: String)

		var userDescription: String
		{
			switch self
			{
			case .invalidOptionsCount:
				return 🔠("Invalid number of choices provided")

			case .serverError(let info):
				return 🔠("Server error: \(info)")
			}
		}
	}
}
