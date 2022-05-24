//
//  MacaLog.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 22.05.2022.
//

import Foundation
import Logging

class MacaLog {
	private var logger = Logger(label: "niml-tinkoff-invest-bot")
	var content: LinkedList<String> = LinkedList()

	init() { }

	func info(_ str: String) {
		logger.info(Logger.Message(stringLiteral: str))

		let date = Date()
		let df = DateFormatter()
		df.dateFormat = "[yyyy-MM-dd HH:mm:ss] "
		let dateString = df.string(from: date)
		content.insert(dateString + str, at: 0)
		if content.count > 128 {
			content.removeLast()
		}
	}
    
    func debug(_ str: String) {
        logger.debug(Logger.Message(stringLiteral: str))
    }
}
