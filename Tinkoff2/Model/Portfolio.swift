//
//  Portfolio.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 22.05.2022.
//

import Foundation
import TinkoffInvestSDK
import Combine

class PortfolioData {
	let FigiToCurrency = [
		"usd": "BBG0013HGFT4",
		"eur": "BBG0013HJJ31",
	]

	public var positions: [String: PortfolioPosition] = [:]

	init () { }

	init(portfolioResp: PortfolioResponse) {
		for i in portfolioResp.positions {
			positions[i.figi] = i
		}
	}

	func getMoneyValue(currency: String) -> MoneyValue? {
		let fig = FigiToCurrency[currency]
		if fig == nil {
			return nil
		}

		if self.positions[fig!] == nil {
			return nil
		}

		var mv = MoneyValue()
		mv.units = self.positions[fig!]!.quantityLots.units
		mv.nano = self.positions[fig!]!.quantityLots.nano
		mv.currency = currency
		return mv
	}
}

class PortfolioLoader {
	init() {
	}

	init(profile: Account, callback: @escaping (PortfolioData) -> ()) {
		self.profile = profile
		self.callback = callback
	}
    
    func syncPortfolioWithTink() {}
    
    func getPortfolioCached() -> PortfolioData {
        return self.portfolioDataCached
    }

	func onDataLoaded(portfolioData: PortfolioData) {
        portfolioDataCached = portfolioData
        
		if self.callback == nil {
			return
		}

		DispatchQueue.main.async {
			self.callback!(portfolioData)
		}
	}

    var portfolioDataCached = PortfolioData()
	var profile: Account = Account()
	var callback: ((PortfolioData) -> ())? = nil
}


class EmuPortfolioLoader: PortfolioLoader {
	override init(profile: Account, callback: @escaping (PortfolioData) -> ()) {
		super.init(profile: profile, callback: callback)
        
		var pp = PortfolioPosition()
		pp.figi = "BBG0013HGFT4" // usd
		pp.quantityLots.units = 1000
		pp.quantityLots.nano = 0
        self.portfolioDataCached.positions[pp.figi] = pp
        
        syncPortfolioWithTink()
	}
    
    public override func syncPortfolioWithTink() {
        self.onDataLoaded(portfolioData: self.portfolioDataCached)
    }
}

class SandboxPortfolioLoader: PortfolioLoader {
	var cancellables = Set<AnyCancellable>()

	override init(profile: Account, callback: @escaping (PortfolioData) -> ()) {
		super.init(profile: profile, callback: callback)
		syncPortfolioWithTink()
	}
    
    public override func syncPortfolioWithTink() {
        GlobalBotConfig.sdk.sandboxService.getPortfolio(accountID: profile.id).sink { result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .finished:
                print("loaded")
            }
        } receiveValue: { portfolio in
            self.onDataLoaded(portfolioData: PortfolioData(portfolioResp: portfolio))
        }.store(in: &cancellables)
    }
}

class TinkoffPortfolioLoader: PortfolioLoader {
	var cancellables = Set<AnyCancellable>()

	override init(profile: Account, callback: @escaping (PortfolioData) -> ()) {
		super.init(profile: profile, callback: callback)
        syncPortfolioWithTink()
	}
    
    public override func syncPortfolioWithTink() {
        GlobalBotConfig.sdk.portfolioService.getPortfolio(accountID: profile.id).sink { result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .finished:
                print("loaded")
            }
        } receiveValue: { portfolio in
            self.onDataLoaded(portfolioData: PortfolioData(portfolioResp: portfolio))
        }.store(in: &cancellables)
    }
}
