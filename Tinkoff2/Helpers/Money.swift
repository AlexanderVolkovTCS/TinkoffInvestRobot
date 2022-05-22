//
//  Money.swift
//  Tinkoff2
//
//  Created by Слава Пачков on 22.05.2022.
//

import Foundation
import TinkoffInvestSDK

func cast_money(quotation: Quotation) -> Float64 {
    return Float64(quotation.units) + Float64(quotation.nano) / 1e9
}
