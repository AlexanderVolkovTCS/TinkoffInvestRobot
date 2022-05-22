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

	@Published var stockData: [StockInfo] = []
    @Published var activeStock: StockInfo = StockInfo()
    @Published var onStockChange: ((StockInfo) -> ())? = nil

	init() { }
}


struct GraphViewUI: UIViewRepresentable {
	@ObservedObject var model: VisualizerPageModel

	func makeUIView(context: Context) -> GraphView {
		GraphView()
	}

	func updateUIView(_ uiView: GraphView, context: Context) {
        uiView.setChartData(candles: self.model.activeStock.candles)
	}
}

struct CardsView: View {
	@ObservedObject var model: VisualizerPageModel

	@ViewBuilder
	func waitView() -> some View {
		VStack {
			ProgressView()
				.progressViewStyle(CircularProgressViewStyle(tint: .indigo))

			Text("Fetching image...")
		}
	}

	var body: some View {
		ScrollView(.horizontal) {
			HStack {
				ForEach(0..<model.stockData.count, id: \.self) { id in
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(self.model.activeStock.instrument == model.stockData[id].instrument ? Color(white: 40/255, opacity: 0.1) : Color(white: 40/255, opacity: 0.0))
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: .infinity)
                        VStack {
                            AsyncImage(url: URL(string: "https://invest-brands.cdn-tinkoff.ru/\(model.stockData[id].instrument!.isin)x160.png")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 25))

                                case .failure:
                                    EmptyView()

                                case .empty:
                                    waitView()

                                @unknown default:
                                    EmptyView()
                                }
                            }

                            Text(model.stockData[id].instrument!.name)
                        }
                        .padding()
                    }
                    .onTapGesture {
                        self.model.onStockChange?(model.stockData[id])
                    }
				}
			}
		}
	}
}

struct VisualizerPageView: View {
	@ObservedObject var model: VisualizerPageModel

	let columns = [
		GridItem(.adaptive(minimum: 200))
	]

	var body: some View {
        if self.model.stockData.count == 0 {
            VStack {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                    .padding()
                Text("Setup bot on the panel")
            }
        } else {
		List {
            Section(header: CardsView(model: model)) {
                VStack {
                    Spacer(minLength: 16)
                    Text("График")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title)
                    Text("Отоброжается по 5мин")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                    GraphViewUI(model: model)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 400)
                    Spacer(minLength: 16)
                    InfoView(model: model)
                    
                    Spacer(minLength: 32)
                    Text("История сделок")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title)
                    
                    Spacer(minLength: 32)
                    Text("Логи бота")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title)
                }
			}
		}
			.listStyle(.plain)
        }
	}
}

struct InfoCellView: View {
    public var title1: String? = nil
    public var title2: String? = nil
    public var systemImage: String? = nil
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: Color(white: 200/255), radius: 10, x: 0, y: 0)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
            VStack {
                Image(systemName: systemImage ?? "info.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text(title2 ?? "")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                Text(title1 ?? "")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity, alignment: .leading)
            .compositingGroup()
            .padding(16)
        }
    }
}

struct InfoView: View {
    @ObservedObject var model: VisualizerPageModel
    
    var columns: [GridItem] = [
        GridItem(.adaptive(minimum: 160), spacing: 32),
        GridItem(.adaptive(minimum: 160), spacing: 32)
    ]

    var body: some View {
        VStack {
            Text("Информация")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title)
            
            LazyVGrid(
                columns: columns,
                alignment: .center,
                spacing: 16
            ) {
                InfoCellView(title1: self.model.activeStock.instrument?.countryOfRiskName, title2: "Страна", systemImage: "globe.europe.africa")
                InfoCellView(title1: self.model.activeStock.instrument?.exchange, title2: "Биржа", systemImage: "tag.circle")
                InfoCellView(title1: self.model.activeStock.instrument?.currency.uppercased(), title2: "Валюта", systemImage: "dollarsign.circle")
                InfoCellView(title1: self.model.activeStock.instrument?.ticker, title2: "Тикер", systemImage: "ticket")
                InfoCellView(title1: self.model.activeStock.instrument?.classCode, title2: "Класс", systemImage: "123.rectangle")
                InfoCellView(title1: self.model.activeStock.instrument?.isin, title2: "ISIN", systemImage: "number.circle")
            }
        }
    }
}

