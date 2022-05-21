//
//  VisualizationViewController.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 20.05.2022.
//

import Foundation

import UIKit
import Combine
import TinkoffInvestSDK
import Charts

class VisualizationViewController: UIViewController {
    let padding = 16.0
    
    var candleView : CandleStickChartView? = nil
    
    var cancellables = Set<AnyCancellable>()
    var sdk = TinkoffInvestSDK(tokenProvider: DefaultTokenProvider(token: "t.JXmm55rH0MxmzpuuoGJrAvREeKzBy6Vf4vhkHDL1tbbhtHoI6yO83b2d70gHfzBuY1yLk2KNZzlT0B8vYsQIxg"), sandbox: DefaultTokenProvider(token: "t.JXmm55rH0MxmzpuuoGJrAvREeKzBy6Vf4vhkHDL1tbbhtHoI6yO83b2d70gHfzBuY1yLk2KNZzlT0B8vYsQIxg"))
    
    var orderSub : OrderSubscriber? = nil
    
    func onBotStart(_ info: BotConfig) {
        print(info.account.id)
    }
    
    @objc
    func onModeChange(_ sender: UISegmentedControl) {
        // Should uninitilize everything here and reinit data sources.
        self.orderSub?.cancel()
        
        switch sender.selectedSegmentIndex {
        case 0:
            self.orderSub = EmuOrderSubscriber(figi: "TSLA", callback: processOrderbook)
        case 1, 2:
            self.orderSub = TinkoffOrderSubscriber(figi: "TSLA", callback: processOrderbook)
        default:
            abort()
        }
        print("selected \(sender.selectedSegmentIndex)")
    }
    
    func setDataCount(_ count: Int, range: UInt32) {
        let yVals1 = (0..<count).map { (i) -> CandleChartDataEntry in
            let mult = range + 1
            let val = Double(arc4random_uniform(40) + mult)
            let high = Double(arc4random_uniform(9) + 8)
            let low = Double(arc4random_uniform(9) + 8)
            let open = Double(arc4random_uniform(6) + 1)
            let close = Double(arc4random_uniform(6) + 1)
            let even = i % 2 == 0
            
            return CandleChartDataEntry(x: Double(i), shadowH: val + high, shadowL: val - low, open: even ? val + open : val - open, close: even ? val - close : val + close, icon: nil)
        }
        
        let set1 = CandleChartDataSet(entries: yVals1, label: "Data Set")
        set1.axisDependency = .left
        set1.setColor(UIColor(white: 80/255, alpha: 1))
        set1.drawIconsEnabled = false
        set1.shadowColor = .darkGray
        set1.shadowWidth = 0.7
        set1.decreasingColor = UIColor(red: 242, green: 122, blue: 84)
        set1.decreasingFilled = false
        set1.increasingColor = UIColor(red: 122, green: 242, blue: 84)
        set1.increasingFilled = false
        set1.neutralColor = .blue
        
        let data = CandleChartData(dataSet: set1)
        self.candleView?.data = data
    }
    

    
//  Роботы на "стакане"
//
//  Робот отслеживает "стакан". Если лотов в заявках на покупку больше, чем в лотах на продажу в определенное количество раз, то робот покупает инструмент по рыночной цене, в противном случае – продает, сразу выставляя поручение в обратную сторону, но с определенным процентом прибыли.
    
    // buyMarketPrice выставляет заявку на покупку акции по рыночной цене.
    func buyMarketPrice(figi :String) {
        var req = PostOrderRequest()
        
        req.accountID = "номер брокерского счета"
        req.orderID = UUID().uuidString
        req.quantity = 1
        req.direction = OrderDirection.buy
        req.figi = figi
        req.orderType = OrderType.market
        // Не передаем price, так как продаем по рыночной цене
        
        self.sdk.sandboxService.postOrder(request: req)
        // TODO: await result
    }
    
    func getAveragePriceOfFigiOnAccount(figi: String, accountID: String) {
        sdk.portfolioService.getPortfolio(accountID: accountID).sink { result in
          switch result {
          case .failure(let error):
              print(error.localizedDescription)
          case .finished:
              print("did finish loading getPortfolio")
          }
        } receiveValue: { portfolio in
            for position in portfolio.positions {
                print("quantity =", position.quantity)
                print("current price = ", position.currentPrice)
                print("current price = ", position.averagePositionPrice)
            }
        }.store(in: &cancellables)
    }
    
    // buyMarketPrice выставляет заявку на продажу акции с учетом определенного процента прибыли.
    func sellWithProfit() {
        
    }
    
    func processOrderbook(orderbook: OrderBookData) {
        // Расчет количества лотов в заявках на покупку и продажу.
        var countBuy: Int64 = 0
        for bid in orderbook.bids {
            countBuy += bid.quantity
        }
        
        var countSell: Int64 = 0
        for ask in orderbook.asks {
            countSell += ask.quantity
        }
        
        print("buy = ", countBuy)
        print("sell = ", countSell)
        
        // Перевес в количестве заявок на покупку.
        if countBuy > countSell {
            print("more buy, need to buy more!")
            return
        }
        
        // Перевес в количестве заявок на продажу.
        if (countSell > countBuy) {
            print("more sell, need to sell some!")
            return
        }
        
        // Ничего не делаем, если нет значимого перевеса.
    }
    
    // subscirbeToOrderBook подписывает на получение информации по стакану с глубиной 20.
    // ответ асинхронно приходит в "case .orderbook" как только состояние стакана изменится.
    // BBG000BBJQV0 - figi of Nvidia
//    func subscirbeToOrderBook() {
//        self.sdk.marketDataServiceStream.subscribeToOrderBook(figi: "BBG000BBJQV0", depth: 20).sink { result in
//           print(result)
//        } receiveValue: { result in
//           switch result.payload {
//           case .orderbook(let orderbook):
//               self.processOrderbook(orderbook: orderbook)
//           default:
//               print("dai \(result.payload)")
//               break
//           }
//        }.store(in: &cancellables)
//    }
    
    // TODO:
    // may be use OrdersStreamService for visualizer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        print(isConnectedToInternet())
//        subscirbeToOrderBook()
        
        self.candleView = CandleStickChartView()
        self.candleView!.chartDescription?.enabled = false
        
        self.candleView!.dragEnabled = true
        self.candleView!.setScaleEnabled(true)
        self.candleView!.maxVisibleCount = 200
        self.candleView!.pinchZoomEnabled = true
        
        self.candleView!.legend.horizontalAlignment = .right
        self.candleView!.legend.verticalAlignment = .top
        self.candleView!.legend.orientation = .vertical
        self.candleView!.legend.drawInside = false
        self.candleView!.legend.font = UIFont(name: "HelveticaNeue-Light", size: 10)!
        
        self.candleView!.leftAxis.labelFont = UIFont(name: "HelveticaNeue-Light", size: 10)!
        self.candleView!.leftAxis.spaceTop = 0.3
        self.candleView!.leftAxis.spaceBottom = 0.3
        self.candleView!.leftAxis.axisMinimum = 0
        
        self.candleView!.rightAxis.enabled = false
        
        self.candleView!.xAxis.labelPosition = .bottom
        self.candleView!.xAxis.labelFont = UIFont(name: "HelveticaNeue-Light", size: 10)!
        
        self.candleView!.translatesAutoresizingMaskIntoConstraints = false
        let candleViewHC1 = NSLayoutConstraint(item: self.candleView!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: view.safeAreaInsets.top + self.padding)
        let candleViewHC2 = NSLayoutConstraint(item: self.candleView!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
        let candleViewHC3 = NSLayoutConstraint(item: self.candleView!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 0.5, constant: 0)
        view.addSubview(self.candleView!)
        view.addConstraints([candleViewHC1, candleViewHC2, candleViewHC3])
        
        setDataCount(50, range: 30)
        
        
        
//        self.sdk.userService.getAccounts().sink { result in
//            switch result {
//            case .failure(let error):
//                print(error.localizedDescription)
//            case .finished:
//                print(result)
//                print("did finish loading getPortfolio")
//            default:
//                print(result)
//            }
//          } receiveValue: { portfolio in
//            print(portfolio)
//          }.store(in: &cancellables)
        
//        self.sdk.userService.getAccounts().sink { result in
//            switch result {
//            case .failure(let error):
//                print(error.localizedDescription)
//            case .finished:
//                print(result)
//                print("did finish loading getPortfolio")
//            default:
//                print(result)
//            }
//          } receiveValue: { portfolio in
//            print(portfolio)
//          }.store(in: &cancellables)
        
//        self.sdk.userService.getAccounts().flatMap {
//            self.sdk.portfolioService.getPortfolio(accountID: $0.accounts.first!.id)
//        }.sink { result in
//          switch result {
//          case .failure(let error):
//              print(error.localizedDescription)
//          case .finished:
//              print("did finish loading getPortfolio")
//          }
//        } receiveValue: { portfolio in
//          print(portfolio)
//        }.store(in: &cancellables)
        
//        self.sdk.marketDataServiceStream.subscribeToCandels(figi: "BBG00ZKY1P71", interval: .oneMinute).sink { result in
//           print(result)
//        } receiveValue: { result in
//           switch result.payload {
//           case .trade(let trade):
//              print(trade.price.asAmount)
//           default:
//               print("dai \(result.payload)")
//               break
//           }
//        }.store(in: &cancellables)
        
//        self.sdk.marketDataServiceStream.subscribeToOrderBook(figi: "BBG00ZKY1P71", depth: 20).sink { result in
//           print(result)
//        } receiveValue: { result in
//           switch result.payload {
//           case .trade(let trade):
//              print(trade.price.asAmount)
//           default:
//               print("dai \(result.payload)")
//               break
//           }
//        }.store(in: &cancellables)
        
        
//        self.sdk.marketDataServiceStream.subscribeToOrderBook(figi: "BBG00ZKY1P71", depth: 20).sink(receiveCompletion: <#T##((Subscribers.Completion<RPCError>) -> Void)##((Subscribers.Completion<RPCError>) -> Void)##(Subscribers.Completion<RPCError>) -> Void#>, receiveValue: <#T##((MarketDataResponse) -> Void)##((MarketDataResponse) -> Void)##(MarketDataResponse) -> Void#>)
        
//        for i in cancellables {
//            print(i.cancel())
//        }
    }


}


extension UIColor {
   convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}
