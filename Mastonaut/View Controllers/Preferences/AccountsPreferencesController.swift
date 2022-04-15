//
//  AccountsPreferencesController.swift
//  Mastonaut
//
//  Created by Bruno Philipe on 22.02.19.
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
import MastodonKit
import CoreTootin

class AccountsPreferencesController: BaseAccountsPreferencesViewController
{
	@IBOutlet private unowned var accountFiltersController: AccountFiltersController!

	@IBOutlet private weak var tabView: NSTabView!
	@IBOutlet private weak var avatarImageView: FileDropImageView!
	@IBOutlet private weak var headerImageView: FileDropImageView!

	@IBOutlet private weak var failurePlaceholderView: NSView!
	@IBOutlet private weak var failureMessageLabel: NSTextField!
	@IBOutlet private weak var failureMessageButton: NSButton!

	private unowned let accountsService = AppDelegate.shared.accountsService
	private unowned let instanceService = AppDelegate.shared.instanceService

	private var controlsState: ControlsState = .noAccountSelected
	{
		didSet { didChangeControlsState() }
	}

	var selectedAccountUUID: UUID?
	{
		get
		{
			return accounts?[bounded: tableView.selectedRow]?.uuid
		}

		set
		{
			if let uuid = newValue, let index = accounts?.firstIndex(where: { $0.uuid == uuid })
			{
				tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
			}
			else
			{
				tableView.selectRowIndexes(IndexSet(), byExtendingSelection: false)
			}
		}
	}

	private lazy var openPanel: NSOpenPanel = {
		let panel = NSOpenPanel()
		panel.allowsMultipleSelection = false
		panel.allowedFileTypes = AttachmentUploader.supportedImageTypes.map({ $0 as String })
		panel.message = 🔠("Select an image to upload.")
		panel.prompt = 🔠("Upload")
		return panel
	}()

	private lazy var attachmentUploader = AttachmentUploader(delegate: self)

	private var avatarMediaAttachment: MediaAttachment? = nil
	{
		didSet { selectedAccount?.hasPendingUploads = avatarMediaAttachment != nil || headerMediaAttachment != nil }
	}

	private var headerMediaAttachment: MediaAttachment? = nil
	{
		didSet { selectedAccount?.hasPendingUploads = avatarMediaAttachment != nil || headerMediaAttachment != nil }
	}

	// MARK: - Bindings

	@objc private(set) dynamic var selectedAccount: AccountBindingProxy? = nil
	{
		willSet
		{
			willChangeValue(for: \AccountsPreferencesController.canEdit)
		}

		didSet
		{
			didChangeValue(for: \AccountsPreferencesController.canEdit)
			AppDelegate.shared.updateAccountsMenu()
			canDelete = NSNumber(booleanLiteral: selectedAccountUUID != nil)
			accountFiltersController.setAccount(uuid: selectedAccountUUID)
		}
	}

	private var urlTaskFutures = Set<FutureTask>()
	{
		didSet { hasURLTask = !urlTaskFutures.isEmpty }
	}

	@objc private(set) dynamic var hasURLTask: Bool = false
	{
		willSet { willChangeValue(for: \AccountsPreferencesController.canEdit) }
		didSet { didChangeValue(for: \AccountsPreferencesController.canEdit) }
	}

	private var originalAvatarImage: NSImage? = nil
	@objc private(set) dynamic var avatarImage: NSImage? = nil

	private var originalHeaderImage: NSImage? = nil
	@objc private(set) dynamic var headerImage: NSImage? = nil

	@objc dynamic var canDelete: NSNumber = false
	@objc dynamic var canEdit: NSNumber
	{
		return (selectedAccount != nil && hasURLTask == false).numberValue
	}

	override func didSetAccounts()
	{
		selectedAccount = nil
		resetControls()
	}

	// MARK: View lifecycle

	override func viewDidLoad()
	{
		super.viewDidLoad()

		tableView.registerForDraggedTypes([.accountTableViewDragAndDropType])

		avatarImageView.allowedDropFileTypes = AttachmentUploader.supportedImageTypes
		headerImageView.allowedDropFileTypes = AttachmentUploader.supportedImageTypes

		didChangeControlsState()
	}

	func refreshAccountsListUI()
	{
		accounts = accountsService.authorizedAccounts
		tableView.deselectAll(nil)
		tableView.reloadData()
	}

	private func updateAccountImages(completion: @escaping () -> Void)
	{
		guard let account = selectedAccount?.account else
		{
			self.avatarImage = nil
			self.headerImage = nil
			self.originalAvatarImage = nil
			self.originalHeaderImage = nil
			return
		}

		let avatarImage: URL?
		let headerImage: URL?

		if let imageURL = account.avatarStaticURL, imageURL.path.contains("missing.png") == false {
			avatarImage = imageURL
		} else {
			avatarImage = nil
		}

		if let imageURL = account.headerStaticURL, imageURL.path.contains("missing.png") == false {
			headerImage = imageURL
		} else {
			headerImage = nil
		}

		resourceFetcher.fetchImages(with: [avatarImage, headerImage].compacted())
		{
			results in

			DispatchQueue.main.async
				{
					if let imageUrl = avatarImage, case .success(let image)? = results[imageUrl]
					{
						self.avatarImage = image
						self.originalAvatarImage = image
					}
					else
					{
						self.avatarImage = nil
						self.originalAvatarImage = nil
					}

					if let imageUrl = headerImage, case .success(let image)? = results[imageUrl]
					{
						self.headerImage = image
						self.originalHeaderImage = image
					}
					else
					{
						self.headerImage = nil
						self.originalHeaderImage = nil
					}

					completion()
				}
		}
	}

	private func prepareToChangeAccount(completion: @escaping (_ canceled: Bool) -> Void)
	{
		guard let accountProxy = selectedAccount else
		{
			completion(true)
			return
		}

		guard accountProxy.hasChanges.boolValue else
		{
			completion(false)
			return
		}

		confirmSaveOrDiscardChanges()
			{
				[weak self] result in

				switch result
				{
				case .save:
					self?.saveAccount()
						{
							error in

							guard let error = error else
							{
								completion(false)
								return
							}

							self?.showSaveErrorAlert(error: error)
							{
								tryAgain in

								if tryAgain
								{
									// Repeat process
									self?.prepareToChangeAccount(completion: completion)
								}
								else
								{
									self?.selectedAccount = AccountBindingProxy(
										account: accountProxy.account,
										instance: accountProxy.instance,
										authorizedAccount: accountProxy.authorizedAccount)
									completion(false)
								}
							}
						}

				case .discard:
					self?.discardChanges()
					completion(false)

				case .cancel:
					completion(true)
				}
			}
	}

	private func saveAccount(completion: @escaping (_ error: Errors?) -> Void)
	{
		guard !hasURLTask else {
			completion(.busy)
			return
		}

		guard
			let account = accounts?[bounded: tableView.selectedRow],
			let accountProxy = selectedAccount,
			let client = Client.create(for: account)
		else {
			completion(nil)
			return
		}

		let request = Accounts.updateCurrentUser(displayName: accountProxy.displayName,
												 note: accountProxy.note,
												 avatar: avatarMediaAttachment,
												 header: headerMediaAttachment,
												 locked: accountProxy.locked.boolValue,
												 bot: accountProxy.bot.boolValue,
												 fieldsAttributes: accountProxy.fieldsAttributes)

		let futurePromise = Promise<FutureTask>()
		let future = client.run(request, resumeImmediately: true)
		{
			[weak self, unowned accountsService, futurePromise] result in

			DispatchQueue.main.async
				{
					if let future = futurePromise.value
					{
						self?.urlTaskFutures.remove(future)
					}

					switch result
					{
					case .success(let updatedAccount, _):
						self?.selectedAccount = AccountBindingProxy(account: updatedAccount,
																	instance: accountProxy.instance,
																	authorizedAccount: account)

						account.updateLocalInfo(using: updatedAccount, instance: accountProxy.instance)
						account.accountPreferences?.managedObjectContext?.perform {
							account.accountPreferences?.customTootLengthLimit = accountProxy.customTootLengthLimit
						}

						self?.accounts = accountsService.authorizedAccounts
						self?.resetAvatarCaches(for: updatedAccount, uuid: self?.selectedAccountUUID)
						completion(nil)

					case .failure(let error):
						completion(.networkError(error))
					}
				}
		}

		futurePromise.value = future

		future.map { _ = urlTaskFutures.insert($0) }
	}

	private func resetAvatarCaches(for account: Account, uuid: UUID?)
	{
		let cache = AppDelegate.shared.avatarImageCache
		cache.resetCachedImage(account: account)

		guard let uuid = uuid else { return }

		(accounts?.first(where: { $0.uuid == uuid })).map { cache.resetCachedImage(account: $0) }
	}

	private func showSaveErrorAlert<T: UserDescriptionError>(error: T, completion: @escaping (_ tryAgain: Bool) -> Void)
	{
		guard let window = view.window else { return }

		let alert = NSAlert(style: .warning,
							title: 🔠("preferences.account.failedSave"),
							message: error.userDescription)

		alert.addButton(withTitle: 🔠("Try Again"))
		alert.addButton(withTitle: 🔠("Cancel"))

		alert.beginSheetModal(for: window)
		{
			response in

			switch response
			{
			case .alertFirstButtonReturn:
				completion(true)

			default:
				completion(false)
			}
		}
	}

	private func confirmSaveOrDiscardChanges(completion: @escaping (ModalAlertResult) -> Void)
	{
		guard let window = view.window else { return }

		let alert = NSAlert(style: .warning,
							title: 🔠("Unsaved changes"),
							message: 🔠("preferences.account.unsavedChanges"))

		alert.addButton(withTitle: 🔠("Save Changes"))
		alert.addButton(withTitle: 🔠("Discard Changes"))
		alert.addButton(withTitle: 🔠("Cancel"))

		alert.beginSheetModal(for: window)
		{
			response in

			switch response
			{
			case .alertFirstButtonReturn:
				completion(.save)

			case .alertSecondButtonReturn:
				completion(.discard)

			default:
				completion(.cancel)
			}
		}
	}

	private func handleNewAvatar(imageUrl: URL)
	{
		self.createMediaAttachment(with: imageUrl)
		{
			mediaAttachment in

			guard let (upload, attachment) = mediaAttachment else
			{
				return
			}

			self.avatarMediaAttachment = attachment

			upload.loadThumbnail()
				{
					image in DispatchQueue.main.async { [weak self] in
						self?.avatarImage = image
					}
				}
		}
	}

	private func handleNewHeader(imageUrl: URL)
	{
		self.createMediaAttachment(with: imageUrl)
		{
			mediaAttachment in

			guard let (upload, attachment) = mediaAttachment else
			{
				return
			}

			self.headerMediaAttachment = attachment

			upload.loadThumbnail()
				{
					image in DispatchQueue.main.async { [weak self] in
						self?.headerImage = image
					}
				}
		}
	}

	private func createMediaAttachment(with imageUrl: URL, completion: @escaping ((Upload, MediaAttachment)?) -> Void)
	{
		guard let upload = Upload(fileUrl: imageUrl, imageRestrainer: attachmentUploader.imageRestrainer) else
		{
			completion(nil)
			return
		}

		DispatchQueue.global(qos: .utility).async
			{
				let data: Data

				do { data = try upload.data() } catch
				{
					#if DEBUG
					NSLog("Failed parsing image data: \(error)")
					#endif
					completion(nil)
					return
				}

				let attachment = MediaAttachment.other(data,
													   fileExtension: upload.fileExtension,
													   mimeType: upload.mimeType)

				completion((upload, attachment))
			}
	}

	@available(*, deprecated)
	private func set(controlsState: ControlsState)
	{
		didChangeControlsState()
	}

	private func didChangeControlsState()
	{
		switch controlsState
		{
		case .available, .loading:
			tabView.isHidden = false
			failurePlaceholderView.isHidden = true

		default:
			tabView.isHidden = true
			failurePlaceholderView.isHidden = false
			failureMessageLabel.stringValue = controlsState.failureMessage
		}

		if let buttonTitle = controlsState.failureButtonTitle
		{
			failureMessageButton.title = buttonTitle
			failureMessageButton.isHidden = false
		}
		else
		{
			failureMessageButton.isHidden = true
		}
	}

	private func setCurrentAccount(_ account: AuthorizedAccount?)
	{
		guard let authorizedAccount = account else {
			resetControls()
			return
		}

		guard authorizedAccount.needsAuthorization == false else {
			controlsState = .accountNeedsAuthentication
			return
		}

		controlsState = .loading

		let futuresPromise = Promise<Set<FutureTask>>()

		func setErrorResult(_ error: Error?)
		{
			DispatchQueue.main.async
			{
				[weak self] in

				NSLog("Could not fetch account info: \(String(describing: error))")
				if let tasks = futuresPromise.value, !tasks.isEmpty
				{
					self?.urlTaskFutures.subtract(tasks)
				}

				self?.avatarImage = nil
				self?.headerImage = nil
				self?.canDelete = true

				if case ClientError.genericError(let networkError)? = error,
					(networkError as NSError).code == URLError.cancelled.rawValue
				{
					return
				}
				self?.controlsState = .couldNotLoadAccount
			}
		}

		guard let client = Client.create(for: authorizedAccount) else {
			setErrorResult(nil)
			return
		}

		let future = client.fetchAccountAndInstance()
		{
			[weak self] result in

			switch result
			{
			case .success((let account, let instance)):
				DispatchQueue.main.async
				{
					self?.selectedAccount = AccountBindingProxy(account: account, instance: instance,
																authorizedAccount: authorizedAccount)
					self?.controlsState = .available
					self?.updateAccountImages()
						{
							if let futures = futuresPromise.value, !futures.isEmpty
							{
								self?.urlTaskFutures.subtract(futures)
							}
						}
				}

			case .failure(let error):
				setErrorResult(error)
			}
		}

		futuresPromise.value = future
		_ = future.map { urlTaskFutures.insert($0) }
	}

	private func discardChanges()
	{
		guard let selectedAccount = selectedAccount else { return }

		self.selectedAccount = AccountBindingProxy(account: selectedAccount.account,
												   instance: selectedAccount.instance,
												   authorizedAccount: selectedAccount.authorizedAccount)
		avatarMediaAttachment = nil
		headerMediaAttachment = nil
		avatarImage = originalAvatarImage
		headerImage = originalHeaderImage
	}

	private func resetControls()
	{
		controlsState = .noAccountSelected
		avatarImage = nil
		headerImage = nil
		originalAvatarImage = nil
		originalHeaderImage = nil
		canDelete = false
	}

	fileprivate enum ModalAlertResult
	{
		case save
		case discard
		case cancel
	}

	enum Errors: UserDescriptionError
	{
		case busy
		case networkError(Error)

		var userDescription: String
		{
			switch self
			{
			case .busy: return 🔠("preferences.account.busy")
			case .networkError(let error): return error.localizedDescription
			}
		}
	}

	// MARK: - Table View Data Source

	func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool
	{
		guard let firstRowIndex = rowIndexes.first else
		{
			return false
		}

		pboard.declareTypes([.accountTableViewDragAndDropType], owner: self)
		pboard.setPropertyList(["rowIndex": firstRowIndex], forType: .accountTableViewDragAndDropType)

		return true
	}

	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
				   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation
	{
		guard
			(info.draggingSource as? NSTableView) == tableView,
			info.draggingPasteboard.propertyList(forType: .accountTableViewDragAndDropType) is [String: Int]
		else
		{
			return NSDragOperation()
		}

		tableView.setDropRow(row, dropOperation: .above)

		return .copy
	}

	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo,
				   row targetRow: Int, dropOperation: NSTableView.DropOperation) -> Bool
	{
		guard
			let propertyList = info.draggingPasteboard.propertyList(forType: .accountTableViewDragAndDropType),
			let sourceRow = (propertyList as? [String: Int])?["rowIndex"],
			let accounts = self.accounts,
			(0..<accounts.count).contains(sourceRow)
		else
		{
			return false
		}

		let droppedAccount = accounts[sourceRow]
		var finalRow = max(targetRow, 0)

		if finalRow > sourceRow
		{
			finalRow -= 1
		}

		tableView.beginUpdates()
		accountsService.set(sortOrder: finalRow, for: droppedAccount)
		AppDelegate.shared.saveContext()
		self.accounts = accountsService.authorizedAccounts
		tableView.removeRows(at: IndexSet(integer: sourceRow), withAnimation: .init())
		tableView.insertRows(at: IndexSet(integer: finalRow), withAnimation: .init())
		tableView.endUpdates()

		tableView.selectRowIndexes(IndexSet(integer: finalRow), byExtendingSelection: false)

		return true
	}

	// MARK: - Table View Delegate

	func tableViewSelectionDidChange(_ notification: Foundation.Notification)
	{
		selectedAccount = nil

		let row = tableView.selectedRow

		guard row >= 0 else
		{
			urlTaskFutures.forEach({ $0.task?.cancel() })
			urlTaskFutures.removeAll()
			resetControls()
			return
		}

		setCurrentAccount(accounts?[row])
	}

	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool
	{
		guard !hasURLTask, selectedAccount?.hasChanges != true else
		{
			prepareToChangeAccount()
				{
					[unowned self] didCancel in

					DispatchQueue.main.async
						{
							if !didCancel
							{
								self.tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
							}
						}
				}

			return false
		}

		return true
	}

	// MARK: - Helper Types

	private enum ControlsState
	{
		case available
		case loading
		case couldNotLoadAccount
		case accountNeedsAuthentication
		case noAccountSelected

		var failureMessage: String
		{
			switch self
			{
			case .available, .loading: return ""
			case .couldNotLoadAccount: return 🔠("preferences.account.couldNotLoad")
			case .accountNeedsAuthentication: return 🔠("preferences.account.login")
			case .noAccountSelected: return 🔠("preferences.account.noSelection")
			}
		}

		var failureButtonTitle: String?
		{
			switch self
			{
			case .available, .loading: return nil
			case .couldNotLoadAccount: return 🔠("Try Again")
			case .accountNeedsAuthentication: return 🔠("Log In")
			case .noAccountSelected: return nil
			}
		}
	}
}

// MARK: - Extensions

extension AccountsPreferencesController: AttachmentUploaderDelegate
{
	func attachmentUploader(_: AttachmentUploader, finishedUploading upload: Upload) {}
	func attachmentUploader(_: AttachmentUploader, updatedProgress progress: Double, for upload: Upload) {}
	func attachmentUploader(_: AttachmentUploader, produced error: AttachmentUploader.UploadError, for upload: Upload) {}
	func attachmentUploader(_: AttachmentUploader, updatedDescription: String?, for upload: Upload) {}
	func attachmentUploader(_: AttachmentUploader, failedUpdatingDescriptionFor upload: Upload, previousValue: String?) {}
}

extension AccountsPreferencesController
{
	@IBAction func saveChanges(_ sender: Any?)
	{
		saveAccount()
			{
				[unowned self] error in

				guard let error = error else
				{
					return
				}

				self.showSaveErrorAlert(error: error)
				{
					tryAgain in

					if tryAgain
					{
						// Repeat process
						self.saveChanges(sender)
					}
					else
					{
						self.discardChanges(sender)
					}
				}
			}
	}

	@IBAction func discardChanges(_ sender: Any?)
	{
		discardChanges()
	}

	@IBAction func clickedAvatarWell(_ sender: Any?)
	{
		guard let window = view.window else { return }

		if let imageUrl = (sender as? NSDraggingInfo)?.firstDraggedFileURL
		{
			handleNewAvatar(imageUrl: imageUrl)
		}
		else
		{
			openPanel.beginSheetModal(for: window)
			{
				[unowned self] response in

				guard response == .OK, let imageUrl = self.openPanel.url else { return }
				self.handleNewAvatar(imageUrl: imageUrl)
			}
		}
	}

	@IBAction func clickedHeaderWell(_ sender: Any?)
	{
		guard let window = view.window else { return }

		if let imageUrl = (sender as? NSDraggingInfo)?.firstDraggedFileURL
		{
			handleNewHeader(imageUrl: imageUrl)
		}
		else
		{
			openPanel.beginSheetModal(for: window)
			{
				response in

				guard response == .OK, let imageUrl = self.openPanel.url else { return }
				self.handleNewHeader(imageUrl: imageUrl)
			}
		}
	}

	@IBAction func removeAccount(_ sender: Any?)
	{
		guard let account = accounts?[bounded: tableView.selectedRow], let window = view.window else { return }

		let alert = NSAlert(style: .warning, title: 🔠("Attention"), message: 🔠("Removing this account will cause its credentials to be deleted. In order to use this account with Mastonaut in the future you will have to log in once again. Do you wish to proceed?"))

		alert.addButton(withTitle: 🔠("Remove Account"))
		alert.addButton(withTitle: 🔠("Cancel"))

		alert.beginSheetModal(for: window)
			{
				response in

				if response == .alertFirstButtonReturn, AppDelegate.shared.removeAccount(for: account.uuid)
				{
					self.refreshAccountsListUI()
					self.selectedAccount = nil
				}
			}
	}

	@IBAction func retryLoadingAccountInfo(_ sender: Any?)
	{
		switch controlsState
		{
		case .couldNotLoadAccount:
			guard let account = accounts?[bounded: tableView.selectedRow] else { return }
			setCurrentAccount(account)

		case .accountNeedsAuthentication:
			if let account = accounts?[bounded: tableView.selectedRow]
			{
				AppDelegate.shared.startAuthorizationRefresh(for: account)
			}
			else
			{
				tableView.deselectAll(nil)
			}

		default:
			break
		}
	}
}

private extension NSPasteboard.PasteboardType
{
	static let accountTableViewDragAndDropType = NSPasteboard.PasteboardType(rawValue: "app.mastonaut.mac.account.d&d")
}

/// Class that translates the Account struct into an Objective-C class that Cocoa bindings can be attached to.
@objc
class AccountBindingProxy: NSObject
{
	let account: Account
	let instance: Instance
	let authorizedAccount: AuthorizedAccount

	@objc dynamic var hasChanges: NSNumber {
		return (!modifiedValues.isEmpty || hasPendingUploads).numberValue
	}

	@objc private(set) dynamic var modifiedValues: [String: Any] = [:]
	{
		willSet { willChangeValue(for: \AccountBindingProxy.hasChanges) }
		didSet { didChangeValue(for: \AccountBindingProxy.hasChanges) }
	}

	var hasPendingUploads: Bool = false
	{
		willSet { willChangeValue(for: \AccountBindingProxy.hasChanges) }
		didSet { didChangeValue(for: \AccountBindingProxy.hasChanges) }
	}

	init(account: Account, instance: Instance, authorizedAccount: AuthorizedAccount) {
		self.account = account
		self.instance = instance
		self.authorizedAccount = authorizedAccount
	}

	@objc dynamic var customTootLengthLimit: NSNumber?
	{
		get {
			guard (modifiedValues["lengthLimit"] is NSNull) == false else { return nil }
			return (modifiedValues["lengthLimit"] as? NSNumber)
						?? authorizedAccount.accountPreferences?.customTootLengthLimit
		}
		set { modifiedValues["lengthLimit"] = newValue ?? NSNull() }
	}

	@objc dynamic var displayName: String
	{
		get { return (modifiedValues["displayName"] as? String) ?? account.displayName }
		set { modifiedValues["displayName"] = newValue }
	}

	@objc dynamic var note: String
	{
		get { return (modifiedValues["note"] as? String) ?? account.source?.note?.notEmpty ?? account.attributedNote.string }
		set { modifiedValues["note"] = newValue }
	}

	@objc dynamic var firstFieldName: String
	{
		get { return (modifiedValues["firstFieldName"] as? String) ?? account.name(for: .first) }
		set { modifiedValues["firstFieldName"] = newValue }
	}

	@objc dynamic var secondFieldName: String
	{
		get { return (modifiedValues["secondFieldName"] as? String) ?? account.name(for: .second) }
		set { modifiedValues["secondFieldName"] = newValue }
	}

	@objc dynamic var thirdFieldName: String
	{
		get { return (modifiedValues["thirdFieldName"] as? String) ?? account.name(for: .third) }
		set { modifiedValues["thirdFieldName"] = newValue }
	}

	@objc dynamic var fourthFieldName: String
	{
		get { return (modifiedValues["fourthFieldName"] as? String) ?? account.name(for: .fourth) }
		set { modifiedValues["fourthFieldName"] = newValue }
	}

	@objc dynamic var firstFieldValue: String
	{
		get { return (modifiedValues["firstFieldValue"] as? String) ?? account.value(for: .first) }
		set { modifiedValues["firstFieldValue"] = newValue }
	}

	@objc dynamic var secondFieldValue: String
	{
		get { return (modifiedValues["secondFieldValue"] as? String) ?? account.value(for: .second) }
		set { modifiedValues["secondFieldValue"] = newValue }
	}

	@objc dynamic var thirdFieldValue: String
	{
		get { return (modifiedValues["thirdFieldValue"] as? String) ?? account.value(for: .third) }
		set { modifiedValues["thirdFieldValue"] = newValue }
	}

	@objc dynamic var fourthFieldValue: String
	{
		get { return (modifiedValues["fourthFieldValue"] as? String) ?? account.value(for: .fourth) }
		set { modifiedValues["fourthFieldValue"] = newValue }
	}

	@objc dynamic var locked: NSNumber
	{
		get { return (modifiedValues["locked"] as? NSNumber) ?? account.locked.numberValue }
		set { modifiedValues["locked"] = newValue }
	}

	@objc dynamic var bot: NSNumber
	{
		get { return (modifiedValues["bot"] as? NSNumber) ?? account.bot?.numberValue ?? false.numberValue }
		set { modifiedValues["bot"] = newValue }
	}

	var fieldsAttributes: [MetadataField]
	{
		let names: [String] = [firstFieldName, secondFieldName, thirdFieldName, fourthFieldName]
		let values: [String] = [firstFieldValue, secondFieldValue, thirdFieldValue, fourthFieldValue]
		return zip(names, values).map({ MetadataField(name: $0.0, value: $0.1) })
	}
}

private extension Account
{
	func name(for field: MetadataFieldIdentifier) -> String
	{
		return source?.fields?[bounded: field.rawValue]?.name ?? fields?[bounded: field.rawValue]?.name ?? ""
	}

	func value(for field: MetadataFieldIdentifier) -> String
	{
		return source?.fields?[bounded: field.rawValue]?.value ?? fields?[bounded: field.rawValue]?.value ?? ""
	}

	enum MetadataFieldIdentifier: Int
	{
		case first = 0
		case second
		case third
		case fourth
	}
}

private extension Bool
{
	var numberValue: NSNumber
	{
		return NSNumber(value: self)
	}
}

private extension String
{
	var notEmpty: String?
	{
		return isEmpty ? nil : self
	}
}
