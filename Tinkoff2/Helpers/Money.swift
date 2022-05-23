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

func cast_money(mv: MoneyValue) -> Float64 {
    return Float64(mv.units) + Float64(mv.nano) / 1e9
}
