//
//  BotMode.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import Foundation

public enum BotMode {
	case Emu
	case Sandbox
	case Tinkoff

	static func fromIndex(_ id: Int) -> BotMode {
		switch id {
		case 0:
			return .Emu
		case 1:
			return .Sandbox
		case 2:
			return .Tinkoff
		default:
			return .Emu
		}
	}

	static func descriptionFor(_ mode: BotMode) -> String {
		switch mode {
		case .Emu:
			return "This is 1"
		case .Sandbox:
			return "This is 2"
		case .Tinkoff:
			return "This is 3 tinkoff"
		}
	}
}


