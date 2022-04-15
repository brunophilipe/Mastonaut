//
//  URLSession+Initializers.swift
//  CoreTootin
//
//  Created by Bruno Philipe on 16.09.19.
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

public extension URLSessionConfiguration
{
	static let forClients: URLSessionConfiguration =
	{
		let configuration = URLSessionConfiguration.default
		configuration.httpMaximumConnectionsPerHost = ProcessInfo().activeProcessorCount * 2
		configuration.waitsForConnectivity = true
		return configuration
	}()

	static var forResources: URLSessionConfiguration =
	{
		let cachesURL = (try? FileManager.default.url(for: .cachesDirectory,
													  in: .userDomainMask,
													  appropriateFor: nil,
													  create: false))

		let cacheURL = cachesURL?.appendingPathComponent("Mastonaut/Resources", isDirectory: true)

		let configuration = URLSessionConfiguration.default
		configuration.requestCachePolicy = .returnCacheDataElseLoad
		configuration.httpMaximumConnectionsPerHost = ProcessInfo().activeProcessorCount * 2
		configuration.urlCache = URLCache(memoryCapacity: 268_435_456, // 256 MiB
										  diskCapacity: 2_147_483_648, // 2 GiB
										  diskPath: cacheURL?.path)

		return configuration
	}()
}
