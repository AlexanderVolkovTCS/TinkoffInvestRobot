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

class VisualizationViewController: UIViewController {
    let padding = 16.0
    
    var cancellables = Set<AnyCancellable>()
    var sdk = TinkoffInvestSDK(tokenProvider: DefaultTokenProvider(token: "t."), sandbox: DefaultTokenProvider(token: ""))
    
    func isConnectedToInternet() -> Bool {
        let hostname = "google.com"
        let hostinfo = gethostbyname2(hostname, AF_INET6)//AF_INET6
        if hostinfo != nil {
            return true // internet available
          }
         return false // no internet
    }
    
    @objc
    func buttonClicked(_ sender: AnyObject?) {
        
    }
    
    @objc
    func onModeChange(_ sender: UISegmentedControl) {
        print("selected \(sender.selectedSegmentIndex)")
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
    
    // buyMarketPrice выставляет заявку на продажу акции с учетом определенного процента прибыли.
    func sellWithProfit() {
        
    }
    
    func processOrderbook(orderbook: OrderBook) {
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
    // BBG000BBJQV0 - figi of Nvidea
    func subscirbeToOrderBook() {
        self.sdk.marketDataServiceStream.subscribeToOrderBook(figi: "BBG000BBJQV0", depth: 20).sink { result in
           print(result)
        } receiveValue: { result in
           switch result.payload {
           case .orderbook(let orderbook):
               self.processOrderbook(orderbook: orderbook)
           default:
               print("dai \(result.payload)")
               break
           }
        }.store(in: &cancellables)
    }
    
    // TODO:
    // may be use OrdersStreamService for visualizer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let header = UIView()
        header.backgroundColor = UIColor(red: 231, green: 240, blue: 250)
        header.translatesAutoresizingMaskIntoConstraints = false
        let headerHC1 = NSLayoutConstraint(item: header, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
        let headerHC2 = NSLayoutConstraint(item: header, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
        let headerHC3 = NSLayoutConstraint(item: header, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: view.safeAreaInsets.top + 100)
        view.addSubview(header)
        view.addConstraints([headerHC1, headerHC2, headerHC3])
        
        let headerLabel = UILabel()
        headerLabel.text = "Visualizer"
        headerLabel.textColor = .black
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        let headerLabelHC1 = NSLayoutConstraint(item: headerLabel, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: -self.padding)
        let headerLabelHC2 = NSLayoutConstraint(item: headerLabel, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left + self.padding)
        let headerLabelHC3 = NSLayoutConstraint(item: headerLabel, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
        header.addSubview(headerLabel)
        header.addConstraints([headerLabelHC1, headerLabelHC2, headerLabelHC3])
        
        let modePicker = UISegmentedControl()
        modePicker.insertSegment(withTitle: "Sandbox", at: 0, animated: false)
        modePicker.insertSegment(withTitle: "Real", at: 1, animated: false)
        modePicker.selectedSegmentIndex = 0
        modePicker.addTarget(self, action: "onModeChange:", for: .valueChanged)
        modePicker.translatesAutoresizingMaskIntoConstraints = false
        let modePickerHC1 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: view.safeAreaInsets.left + self.padding)
        let modePickerHC2 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: header, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: self.padding)
        let modePickerHC3 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 256)
        let modePickerHC4 = NSLayoutConstraint(item: modePicker, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 30)
        view.addSubview(modePicker)
        view.addConstraints([modePickerHC1, modePickerHC2, modePickerHC3, modePickerHC4])
        
        
        print(isConnectedToInternet())
        subscirbeToOrderBook()
        
        
        
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
