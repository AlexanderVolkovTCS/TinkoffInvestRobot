//
//  TokenStorage.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 22.05.2022.
//

import KeychainAccess
import SwiftUI


public class TokenStorage: ObservableObject {
	@Published public var token: String?

	init() {
		self.token = get()
	}

	init(callback: @escaping () -> ()) {
		self.onTokenChange = callback
		self.token = get()
	}

	public func save(token: String) {
		self.keychain[Globals.SecureTokenKey] = token
		self.token = token
		if (self.onTokenChange) != nil {
			self.onTokenChange!()
		}
	}

	public func remove() {
		self.keychain[Globals.SecureTokenKey] = nil
		self.token = nil
		if (self.onTokenChange) != nil {
			self.onTokenChange!()
		}
	}

	public func get() -> String? {
		return keychain[Globals.SecureTokenKey]
	}

	private var onTokenChange: (() -> ())? = nil
	private let keychain = Keychain(service: Globals.AppName)
}

