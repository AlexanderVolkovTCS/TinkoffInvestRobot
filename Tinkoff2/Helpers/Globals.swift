//
//  Globals.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 22.05.2022.
//

import Foundation

struct Globals {
    static public let AppName = "niml-tinkoff-invest-bot"
    static public let SecureTokenKey = AppName + ".token"
    // Количество retry запросов при возникновении ошибок с сетью / в работе с Tinkoff API
    static public let MaxRetryAttempts = 10
}
