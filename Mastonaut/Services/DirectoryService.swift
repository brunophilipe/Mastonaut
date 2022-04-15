//
//  DirectoryService.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 25.05.19.
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

struct DirectoryService
{
	private let directoryUrl = URL(string: "https://mastonaut.app/instances/cached_fetch.php")!
	private let urlSession: URLSession

	init(urlSession: URLSession)
	{
		self.urlSession = urlSession
	}

	func fetch(completion: @escaping (Result<[Instance], FetchError>) -> Void)
	{
		let request = URLRequest(url: directoryUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
		let task = urlSession.dataTask(with: request) { (data, response, error) in

			if let error = error as NSError?
			{
				completion(.failure(.networkError(error)))
			}
			else if let httpResponse = response as? HTTPURLResponse, !(200..<400).contains(httpResponse.statusCode)
			{
				completion(.failure(FetchError.badStatus(httpResponse.statusCode)))
			}
			else if let data = data
			{
				do
				{
					let jsonDecoder = JSONDecoder()
					jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase

					completion(.success(try jsonDecoder.decode(InstancesPayload.self, from: data).instances))
				}
				catch let error as DecodingError
				{
					completion(.failure(.parseError(error)))
				}
				catch
				{
					completion(.failure(.unknownError))
				}
			}
			else
			{
				completion(.failure(.emptyResponse))
			}
		}

		task.resume()
	}

	class Instance: NSObject, Codable
	{
		let id: String
		let name: String
		let uptime: Double
		let version: String?
		let users: String
		let statuses: String
		let info: Info

		struct Info: Codable
		{
			let shortDescription: String
			let prohibitedContent: [String]
			let categories: [String]
		}
	}

	enum FetchError: LocalizedError
	{
		case networkError(NSError)
		case parseError(DecodingError)
		case badStatus(Int)
		case unknownError
		case emptyResponse
	}

	private struct InstancesPayload: Codable
	{
		let instances: [Instance]
	}
}
