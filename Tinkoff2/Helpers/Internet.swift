//
//  Internet.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import Foundation

func isConnectedToInternet() -> Bool {
	// Testing google.com, if not avail pretend that there is no Internet connection.
	let hostinfo = gethostbyname2("google.com", AF_INET6) //AF_INET6
	if hostinfo != nil {
		return true
	}
	return false
}
