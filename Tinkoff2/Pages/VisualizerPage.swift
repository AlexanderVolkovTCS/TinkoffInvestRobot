//
//  VisualizerView.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import SwiftUI
import TinkoffInvestSDK

class VisualizerPageModel: ObservableObject {
	@Published var data: [Int]? = nil

    @Published var currentMode: BotMode = .Tinkoff;
    
    @Published var stockData: [StockInfo] = []
    @Published var activeStock: StockInfo? = nil
	@Published var onStockChange: ((StockInfo) -> ())? = nil
    
    @Published var tradingSchedule: [String:TradingSchedule] = [:]

	@Published var portfolioData: PortfolioData = PortfolioData()

	@Published var isWaitingForAccountData: Bool = false

	@Published var logger: MacaLog = MacaLog()
    
    @Published var stat: MacaStat = MacaStat()

	init() { }
}

struct VisualizerPageView: View {
	@ObservedObject var model: VisualizerPageModel

	let columns = [
		GridItem(.adaptive(minimum: 200))
	]
    
    func exchangeIsOpened() -> Bool {
        if self.model.currentMode == .Emu {
            return true
        }
        
        if self.model.activeStock == nil {
            return false
        }
        
        if self.model.tradingSchedule[self.model.activeStock!.instrument.exchange] == nil {
            return true
        }
        
        let ex = self.model.tradingSchedule[self.model.activeStock!.instrument.exchange]!
        if ex.days.count < 1 {
            return false
        }
        
        return ex.days[0].startTime.timeIntervalSince1970 <= Date().timeIntervalSince1970 && Date().timeIntervalSince1970 <= ex.days[0].endTime.timeIntervalSince1970
    }

	var body: some View {
		if self.model.isWaitingForAccountData {
			VStack {
				ProgressView()
					.padding()
				Text("Запускаем Бота")
			}
		} else if self.model.stockData.count == 0 {
			VStack {
				Image(systemName: "hand.draw")
					.font(.system(size: 60))
					.foregroundColor(.gray)
					.padding()
				Text("Проведите от левого края, чтобы открыть меню натройки бота")
			}
		} else {
			List {
                Section(header: CardsView(model: model)) {
					VStack {
						if self.model.activeStock != nil {
                            if exchangeIsOpened() {
                                Spacer(minLength: 16)
                                ShortStat(model: model)
                                
                                Spacer(minLength: 16)
                                CandleGraph(model: model)

                                Spacer(minLength: 16)
                                RSIGraph(model: model)
                            } else {
                                Image(systemName: "clock")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                    .frame(alignment: .center)
                                Text("Биржа закрыта")
                            }
                            Spacer(minLength: 16)
                            InfoView(model: model)
                            
                            if exchangeIsOpened() {
                                Spacer(minLength: 32)
                                TableView(model: model)
                            }
						} else {
							EmptyView()
						}
					}
				}
			}
				.listStyle(.plain)
		}
	}
}

struct ShortStat: View {
    @ObservedObject var model: VisualizerPageModel
    @Environment(\.colorScheme) var colorScheme

    var columns: [GridItem] = [
        GridItem(.adaptive(minimum: 120), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 50 / 255) : Color(white: 240 / 255))
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
            LazyVGrid(
                columns: columns,
                alignment: .center,
                spacing: 16
            ) {
                VStack {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("Куплено".uppercased())
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .padding(EdgeInsets(top: 0, leading: -1, bottom: 0, trailing: 0))
                    }
                    Text(String(format: "%.2f", self.model.activeStock!.boughtTotalPrice) + self.model.activeStock!.instrument.sign())
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .padding(EdgeInsets(top: 3, leading: 0, bottom: 0, trailing: 0))
                }
                VStack {
                    HStack {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("Продано".uppercased())
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .padding(EdgeInsets(top: 0, leading: -1, bottom: 0, trailing: 0))
                    }
                    Text(String(format: "%.2f", self.model.activeStock!.soldTotalPrice) + self.model.activeStock!.instrument.sign())
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .padding(EdgeInsets(top: 3, leading: 0, bottom: 0, trailing: 0))
                }
                VStack {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("Куплено ".uppercased() + "(шт.)")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .padding(EdgeInsets(top: 0, leading: -1, bottom: 0, trailing: 0))
                    }
                    Text(String(self.model.activeStock!.boughtCount))
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .padding(EdgeInsets(top: 3, leading: 0, bottom: 0, trailing: 0))
                }
                VStack {
                    HStack {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("Продано ".uppercased() + "(шт.)")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .padding(EdgeInsets(top: 0, leading: -1, bottom: 0, trailing: 0))
                    }
                    Text(String(self.model.activeStock!.soldCount))
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .padding(EdgeInsets(top: 3, leading: 0, bottom: 0, trailing: 0))
                }
                VStack {
                    HStack {
                        Image(systemName: "percent")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("Прибыль ".uppercased())
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .padding(EdgeInsets(top: 0, leading: -1, bottom: 0, trailing: 0))
                    }
                    Text(String(format: "%.2f", self.model.activeStock!.profitPercentage) + "%")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .padding(EdgeInsets(top: 3, leading: 0, bottom: 0, trailing: 0))
                }
            }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
    }
}


struct CandleGraph: View {
    @ObservedObject var model: VisualizerPageModel
    public var operation: OrderInfo? = nil

    var body: some View {
        VStack {
            GraphViewUI(model: model)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 300)
            Text("Отображены свечи в интервале \(model.currentMode == .Emu ? "5" : "1") минут")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(EdgeInsets(top: 2, leading: 16, bottom: 8, trailing: 16))
        }
    }
}

struct RSIGraph: View {
    @ObservedObject var model: VisualizerPageModel
    public var operation: OrderInfo? = nil

    var body: some View {
        VStack {
            Spacer(minLength: 16)

            Text("Значение RSI")
                .font(.system(size: 24, weight: .bold, design: .default))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 1, trailing: 16))
            DescriptionTextView(text: "График индикатора технического анализа, определяющий силу тренда и вероятность его смены.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 2, leading: 16, bottom: 8, trailing: 16))
            

            Spacer(minLength: 16)

            VStack {
                RSIGraphViewUI(model: model)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 300)
            }
        }
    }
}

struct GraphViewUI: UIViewRepresentable {
	@ObservedObject var model: VisualizerPageModel

	func makeUIView(context: Context) -> CandleGraphView {
		CandleGraphView()
	}

	func updateUIView(_ uiView: CandleGraphView, context: Context) {
		if self.model.activeStock == nil {
            uiView.setChartData(candles: [])
			return
		}
        uiView.setChartData(candles: self.model.activeStock!.candles)
	}
}

struct RSIGraphViewUI: UIViewRepresentable {
    @ObservedObject var model: VisualizerPageModel

    func makeUIView(context: Context) -> RSIGraphView {
        RSIGraphView()
    }

    func updateUIView(_ uiView: RSIGraphView, context: Context) {
        if self.model.activeStock == nil {
            uiView.setChartData(rsi: [])
            return
        }
        uiView.setChartData(rsi: self.model.activeStock!.rsi)
    }
}

struct CardsView: View {
	@ObservedObject var model: VisualizerPageModel
	@Environment(\.colorScheme) var colorScheme

	@ViewBuilder
	func waitView() -> some View {
		VStack {
			ProgressView()
			Text("Загрузка")
		}
	}

	var body: some View {
		ScrollView(.horizontal) {
			HStack {
				ForEach(0..<model.stockData.count, id: \.self) { id in
					ZStack {
						RoundedRectangle(cornerRadius: 16)
							.fill(self.model.activeStock!.instrument == model.stockData[id].instrument ? (colorScheme == .light ? Color(white: 40 / 255, opacity: 0.1) : Color(white: 180 / 255, opacity: 0.1)) : Color(white: 40 / 255, opacity: 0.0))
							.frame(maxWidth: .infinity)
							.frame(maxHeight: .infinity)
						HStack {
							AsyncImage(url: URL(string: model.stockData[id].instrument.instrumentType == "share" ?
								"https://invest-brands.cdn-tinkoff.ru/\(model.stockData[id].instrument.isin)x160.png"
								: model.stockData[id].instrument.instrumentType == "etf" ?
								"https://invest-brands.cdn-tinkoff.ru/\(model.stockData[id].instrument.ticker)x160.png"
								: model.stockData[id].instrument.instrumentType == "currency" ?
								"https://invest-brands.cdn-tinkoff.ru/\(model.stockData[id].instrument.ticker.prefix(3))x160.png"
								: "https://invest-brands.cdn-tinkoff.ru/\(model.stockData[id].instrument.isin)x160.png"
								)) { phase in
								switch phase {
								case .success(let image):
									image
										.resizable()
										.aspectRatio(contentMode: .fit)
										.frame(width: 30, height: 30)
										.clipShape(RoundedRectangle(cornerRadius: 25))

								case .failure:
									EmptyView()

								case .empty:
									waitView()

								@unknown default:
									EmptyView()
								}
							}
                            Text(model.stockData[id].instrument.name)
						}
							.padding()
                        if model.stockData[id].hasUpdates {
                            VStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.red)
                                    .position(x: 20, y: -20)
                                    .frame(width: 10, height: 10, alignment: .leading)
                            }
                        }
					}
						.onTapGesture {
						self.model.onStockChange?(model.stockData[id])
					}
				}
			}
		}
	}
}

struct InfoCellView: View {
    public var title1: String? = nil
    public var title2: String? = nil
	public var systemImage: String? = nil
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 16)
				.fill(colorScheme == .dark ? Color(white: 50 / 255) : Color(white: 240 / 255))
				.frame(maxWidth: .infinity)
				.frame(maxHeight: .infinity)
			VStack {
				Image(systemName: systemImage ?? "info.circle")
					.font(.system(size: 30))
					.foregroundColor(.gray)
					.frame(maxWidth: .infinity, alignment: .leading)
				Spacer()
				Text(title2 ?? "")
                    .font(.system(size: 14, weight: .thin, design: .default))
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
				Text(title1 ?? "")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .frame(maxWidth: .infinity, alignment: .leading)
			}
				.frame(height: 120)
				.frame(maxWidth: .infinity, alignment: .leading)
				.compositingGroup()
				.padding(16)
		}
	}
}

struct InfoView: View {
	@ObservedObject var model: VisualizerPageModel

	var columns: [GridItem] = [
		GridItem(.adaptive(minimum: 120), spacing: 16),
		GridItem(.adaptive(minimum: 120), spacing: 16)
	]

	var body: some View {
		VStack {
			LazyVGrid(
				columns: columns,
				alignment: .center,
				spacing: 16
			) {
                if model.currentMode != .Sandbox && model.portfolioData.positions[model.activeStock!.instrument.figi] != nil {
					InfoCellView(title1: String(model.portfolioData.positions[model.activeStock!.instrument.figi]!.quantity.units), title2: "В портфеле", systemImage: "bag.circle")
				}
                if model.activeStock!.instrument.countryOfRiskName != "" {
                    InfoCellView(title1: model.activeStock!.instrument.countryOfRiskName, title2: "Страна", systemImage: "globe.europe.africa")
                }
                if model.activeStock!.instrument.exchange != "" {
                    InfoCellView(title1: model.activeStock!.instrument.exchange, title2: "Биржа", systemImage: "tag.circle")
                }
                if model.activeStock!.instrument.currency != "" {
                    InfoCellView(title1: model.activeStock!.instrument.currency.uppercased(), title2: "Валюта", systemImage: "dollarsign.circle")
                }
                if model.activeStock!.instrument.ticker != "" {
                    InfoCellView(title1: model.activeStock!.instrument.ticker, title2: "Тикер", systemImage: "ticket")
                }
                if model.activeStock!.instrument.classCode != "" {
                    InfoCellView(title1: model.activeStock!.instrument.classCode, title2: "Класс", systemImage: "123.rectangle")
                }
                if model.activeStock!.instrument.isin != "" {
                    InfoCellView(title1: model.activeStock!.instrument.isin, title2: "ISIN", systemImage: "number.circle")
                }
			}
		}
	}
}

struct TableCellView: View {
	public var operation: OrderInfo? = nil

	var body: some View {
        if operation != nil {
            HStack {
                if operation!.type == .SoldRequest || operation!.type == .BoughtRequest {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    if operation!.type == .SoldRequest {
                        Text("Заявка на продажу \(operation!.count) инструмента(ов)")
                    } else {
                        Text("Заявка на покупку \(operation!.count) инструмента(ов)")
                    }
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    if operation!.type == .Sold {
                        Text("Продажа исполнена \(operation!.count) инструмента(ов) за \(operation!.price.asString())")
                    } else {
                        Text("Покупка исполнена \(operation!.count) инструмента(ов) за \(operation!.price.asString())")
                    }
                }
                Text(operation!.timeStr)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
        } else {
            EmptyView()
        }
	}
}

struct TableView: View {
	@ObservedObject var model: VisualizerPageModel

	var body: some View {
		VStack {
            Text("История сделок")
                .font(.system(size: 24, weight: .bold, design: .default))
                .frame(maxWidth: .infinity, alignment: .leading)
            DescriptionTextView(text: "Отображены 10 последних сделок, совершенных Ботом.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
			Spacer()
            if model.activeStock!.operations.count > 0 {
                VStack(
                    alignment: .center,
                    spacing: 16
                ) {
                    ForEach(0..<model.activeStock!.operations.count, id: \.self) { id in
                        TableCellView(operation: model.activeStock!.operations[id])
                    }
                }
            } else {
                Text("Сделок пока нет")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
            }
		}
	}
}

