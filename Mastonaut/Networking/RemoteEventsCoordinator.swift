//
//  RemoteEventsCoordinator.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 19.08.19.
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
import Starscream

protocol ReceiverRef
{
	var streamIdentifier: RemoteEventsCoordinator.StreamIdentifier { get }
}

class RemoteEventsCoordinator: NSObject
{
	static let shared = RemoteEventsCoordinator()

	private let operationQueue = DispatchQueue(label: "remote-events-coordinator-queue")

	private var streamReceiverMap: [StreamIdentifier: Set<AnyRemoteEventsReceiver>] = [:]
	{
		willSet { willChangeValue(for: \.totalReceiverCount) }
		didSet { didChangeValue(for: \.totalReceiverCount) }
	}

	private var streamListenerMap: [StreamIdentifier: TaggedRemoteEventsListener] = [:]
	{
		willSet { willChangeValue(for: \.listenerCount) }
		didSet { didChangeValue(for: \.listenerCount) }
	}

	@objc dynamic var listenerCount: Int
	{
		return streamListenerMap.count
	}

	@objc dynamic var totalReceiverCount: Int
	{
		return streamReceiverMap.values.reduce(0, { $0 + $1.count })
	}

	func add<T: RemoteEventsReceiver>(receiver: T, for streamIdentifier: StreamIdentifier) -> ReceiverRef
	{
		return operationQueue.sync {
			var receivers = self.streamReceiverMap[streamIdentifier] ?? []
			let receiver = AnyRemoteEventsReceiver(receiver, stream: streamIdentifier)
			receivers.insert(receiver)
			debugLog("Creating receiver: \(receiver.hashValue) \(receiver.description)")
			self.streamReceiverMap[streamIdentifier] = receivers
			self.createListenerIfNeeded(for: streamIdentifier, notifyingReceiverOtherwise: receiver)
			return receiver
		}
	}

	func addExisting(receiver receiverReference: ReceiverRef)
	{
		guard let receiver = receiverReference as? AnyRemoteEventsReceiver else { return }

		operationQueue.async {
			if self.streamReceiverMap[receiver.streamIdentifier]?.contains(receiver) != true
			{
				var receivers = self.streamReceiverMap[receiver.streamIdentifier] ?? []
				receivers.insert(receiver)
				debugLog("Re-adding receiver: \(receiver.hashValue) \(receiver.description)")
				self.streamReceiverMap[receiver.streamIdentifier] = receivers
				self.createListenerIfNeeded(for: receiver.streamIdentifier, notifyingReceiverOtherwise: receiver)
			}

			if let listener = self.streamListenerMap[receiver.streamIdentifier], !listener.isSocketConnected
			{
				listener.reconnect()
			}
		}
	}

	func remove(receiver receiverReference: ReceiverRef)
	{
		guard let receiver = receiverReference as? AnyRemoteEventsReceiver else { return }

		operationQueue.sync {
			guard var receivers = self.streamReceiverMap[receiver.streamIdentifier] else { return }
			receivers.remove(receiver)
			debugLog("Removing receiver: \(receiver.hashValue) \(receiver.description)")
			self.streamReceiverMap[receiver.streamIdentifier] = receivers
			self.removeListenerIfNeeded(for: receiver.streamIdentifier)
		}
	}

	func reconnectListener(for receiverReference: ReceiverRef)
	{
		guard let receiver = receiverReference as? AnyRemoteEventsReceiver else { return }

		if let listener = self.streamListenerMap[receiver.streamIdentifier], !listener.isSocketConnected
		{
			listener.reconnect()
		}
	}

	private func createListenerIfNeeded(for streamIdentifier: StreamIdentifier,
										notifyingReceiverOtherwise receiver: AnyRemoteEventsReceiver)
	{
		if let listener = streamListenerMap[streamIdentifier]
		{
			if listener.isSocketConnected
			{
				receiver.remoteEventsCoordinator(streamIdentifierDidConnect: streamIdentifier)
			}
		}
		else
		{
			let listener = TaggedRemoteEventsListener(baseUrl: streamIdentifier.baseURL,
													  accessToken: streamIdentifier.accessToken,
													  streamIdentifier: streamIdentifier,
													  delegate: self)

			streamListenerMap[streamIdentifier] = listener

			listener.set(stream: streamIdentifier.stream)
		}
	}

	private func removeListenerIfNeeded(for streamIdentifier: StreamIdentifier)
	{
		if streamReceiverMap[streamIdentifier] == nil || streamReceiverMap[streamIdentifier]?.count == 0
		{
			streamListenerMap[streamIdentifier]?.disconnect()
			streamListenerMap.removeValue(forKey: streamIdentifier)
		}
	}

	struct StreamIdentifier: Hashable
	{
		let baseURL: URL
		let accessToken: String
		let stream: RemoteEventsListener.Stream
	}
}

protocol RemoteEventsReceiver: AnyObject, Hashable
{
	typealias StreamIdentifier = RemoteEventsCoordinator.StreamIdentifier

	func remoteEventsCoordinator(streamIdentifierDidConnect: StreamIdentifier)
	func remoteEventsCoordinator(streamIdentifierDidDisconnect: StreamIdentifier)
	func remoteEventsCoordinator(streamIdentifier: StreamIdentifier, didHandleEvent: ClientEvent)
	func remoteEventsCoordinator(streamIdentifier: StreamIdentifier, parserProducedError: Error)
}

extension RemoteEventsCoordinator: RemoteEventsListenerDelegate
{
	func remoteEventsListenerDidConnect(_ remoteEventsListener: RemoteEventsListener)
	{
		guard let streamIdentifier = (remoteEventsListener as? TaggedRemoteEventsListener)?.streamIdentifier else
		{
			return
		}

		streamReceiverMap[streamIdentifier]?.forEach({
			$0.remoteEventsCoordinator(streamIdentifierDidConnect: streamIdentifier)
		})
	}

	func remoteEventsListenerDidDisconnect(_ remoteEventsListener: RemoteEventsListener, error: Error?)
	{
		guard let streamIdentifier = (remoteEventsListener as? TaggedRemoteEventsListener)?.streamIdentifier else
		{
			return
		}

		if let webSocketError = error as? WSError, webSocketError.code == 404
		{
			// Not found. Means the instance doesn't support streaming.
			return
		}

		streamReceiverMap[streamIdentifier]?.forEach({
			$0.remoteEventsCoordinator(streamIdentifierDidDisconnect: streamIdentifier)
		})
	}

	func remoteEventsListener(_ remoteEventsListener: RemoteEventsListener, didHandleEvent event: ClientEvent)
	{
		guard let streamIdentifier = (remoteEventsListener as? TaggedRemoteEventsListener)?.streamIdentifier else
		{
			return
		}

		streamReceiverMap[streamIdentifier]?.forEach({
			$0.remoteEventsCoordinator(streamIdentifier: streamIdentifier, didHandleEvent: event)
		})
	}

	func remoteEventsListener(_ remoteEventsListener: RemoteEventsListener, parserProducedError error: Error)
	{
		guard let streamIdentifier = (remoteEventsListener as? TaggedRemoteEventsListener)?.streamIdentifier else
		{
			return
		}

		streamReceiverMap[streamIdentifier]?.forEach({
			$0.remoteEventsCoordinator(streamIdentifier: streamIdentifier, didProduceError: error)
		})
	}
}

private struct AnyRemoteEventsReceiver: Hashable, ReceiverRef
{
	typealias StreamIdentifier = RemoteEventsCoordinator.StreamIdentifier

	let streamIdentifier: StreamIdentifier
	let description: String

	private let eventHandler: (StreamIdentifier, ClientEvent) -> Void
	private let errorHandler: (StreamIdentifier, Error) -> Void
	private let didConnectHandler: (StreamIdentifier) -> Void
	private let didDisconnectHandler: (StreamIdentifier) -> Void
	private let subjectHashValueHandler: (inout Hasher) -> Void

	init<T: RemoteEventsReceiver>(_ receiver: T, stream: StreamIdentifier)
	{
		self.streamIdentifier = stream
		self.description = (receiver as? NSObject)?.description ?? String(describing: receiver)

		self.eventHandler = { [weak receiver] in
			assert(receiver != nil)
			receiver?.remoteEventsCoordinator(streamIdentifier: $0, didHandleEvent: $1)
		}
		self.errorHandler = { [weak receiver] in
			assert(receiver != nil)
			receiver?.remoteEventsCoordinator(streamIdentifier: $0, parserProducedError: $1)
		}
		self.didConnectHandler = { [weak receiver] in
			assert(receiver != nil)
			receiver?.remoteEventsCoordinator(streamIdentifierDidConnect: $0)
		}
		self.didDisconnectHandler = { [weak receiver] in
			assert(receiver != nil)
			receiver?.remoteEventsCoordinator(streamIdentifierDidDisconnect: $0)
		}
		self.subjectHashValueHandler = { [weak receiver] hasher in
			assert(receiver != nil)
			receiver.map { hasher.combine($0) }
		}
	}

	func hash(into hasher: inout Hasher)
	{
		subjectHashValueHandler(&hasher)
	}

	static func == (lhs: AnyRemoteEventsReceiver, rhs: AnyRemoteEventsReceiver) -> Bool
	{
		/// We are too far removed from the actual type to do anything more useful here.
		return lhs.hashValue == rhs.hashValue
	}

	func remoteEventsCoordinator(streamIdentifierDidConnect streamIdentifier: StreamIdentifier)
	{
		self.didConnectHandler(streamIdentifier)
	}

	func remoteEventsCoordinator(streamIdentifierDidDisconnect streamIdentifier: StreamIdentifier)
	{
		self.didDisconnectHandler(streamIdentifier)
	}

	func remoteEventsCoordinator(streamIdentifier: StreamIdentifier, didHandleEvent event: ClientEvent)
	{
		self.eventHandler(streamIdentifier, event)
	}

	func remoteEventsCoordinator(streamIdentifier: StreamIdentifier, didProduceError error: Error)
	{
		self.errorHandler(streamIdentifier, error)
	}
}

private class TaggedRemoteEventsListener: RemoteEventsListener
{
	typealias StreamIdentifier = RemoteEventsCoordinator.StreamIdentifier

	let streamIdentifier: StreamIdentifier

	init(baseUrl: URL, accessToken: String, streamIdentifier: StreamIdentifier, delegate: RemoteEventsListenerDelegate)
	{
		self.streamIdentifier = streamIdentifier
		super.init(baseUrl: baseUrl, accessToken: accessToken, delegate: delegate)
	}
}

private func debugLog(_ message: String)
{
	#if DEBUG
	NSLog(message)
	#endif
}
