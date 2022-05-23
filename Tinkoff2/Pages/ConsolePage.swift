//
//  ConsoleView.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 22.05.2022.
//

import SwiftUI

let SoftColorList = [
	UIColor(red: 180, green: 215, blue: 254),
	UIColor(red: 160, green: 218, blue: 179),
	UIColor(red: 250, green: 135, blue: 129),
]

struct ConsolePageView: View {
	@ObservedObject var model: VisualizerPageModel

	var body: some View {
		List {
			Text("Консоль")
				.font(.system(size: 36, weight: .bold, design: .default))
				.padding(16)
			DashboardView(model: model)
			LoggerStatView(model: model)
		}
			.listStyle(.plain)
	}
}

struct DashboardView: View {
	@ObservedObject var model: VisualizerPageModel

	var columns: [GridItem] = [
		GridItem(.adaptive(minimum: 300), spacing: 32),
	]

	var body: some View {
		VStack {
			LazyVGrid(
				columns: columns,
				alignment: .center,
				spacing: 16
			) {
				BoughtInstrumentStatView(model: model)
				SoldInstrumentStatView(model: model)
			}
		}
	}
}

struct BoughtInstrumentGraphViewUI: UIViewRepresentable {
	@ObservedObject var model: VisualizerPageModel

	func makeUIView(context: Context) -> BarGraphView {
		BarGraphView()
	}

	func updateUIView(_ uiView: BarGraphView, context: Context) {
		if self.model.activeStock == nil {
			return
		}
        uiView.setChartData(bars: [BarDescriptor(value: Int(self.model.stat.boughtStocks), label: "Акции", color: SoftColorList[0]), BarDescriptor(value: Int(self.model.stat.boughtETCs), label: "Фонды", color: SoftColorList[1]), BarDescriptor(value: Int(self.model.stat.boughtCurrency), label: "Валюта", color: SoftColorList[2])])
	}
}

struct BoughtInstrumentStatView: View {
	@ObservedObject var model: VisualizerPageModel

	var body: some View {
		VStack {
			Text("Инструментов куплено")
				.frame(maxWidth: .infinity, alignment: .leading)
				.font(.title3)
				.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
			DescriptionTextView(text: "Сравнение")
				.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
			BoughtInstrumentGraphViewUI(model: model)
				.frame(maxWidth: .infinity)
				.frame(minHeight: 200)
				.padding(16)
		}
	}
}

struct SoldInstrumentGraphViewUI: UIViewRepresentable {
	@ObservedObject var model: VisualizerPageModel

	func makeUIView(context: Context) -> BarGraphView {
		BarGraphView()
	}

	func updateUIView(_ uiView: BarGraphView, context: Context) {
		if self.model.activeStock == nil {
            return
		}
        uiView.setChartData(bars: [BarDescriptor(value: Int(self.model.stat.soldStocks), label: "Акции", color: SoftColorList[0]), BarDescriptor(value: Int(self.model.stat.soldETCs), label: "Фонды", color: SoftColorList[1]), BarDescriptor(value: Int(self.model.stat.soldCurrency), label: "Валюта", color: SoftColorList[2])])
	}
}

struct SoldInstrumentStatView: View {
	@ObservedObject var model: VisualizerPageModel

	var body: some View {
		VStack {
			Text("Инструментов продано")
				.frame(maxWidth: .infinity, alignment: .leading)
				.font(.title3)
				.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
			DescriptionTextView(text: "Сравнение")
				.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
			SoldInstrumentGraphViewUI(model: model)
				.frame(maxWidth: .infinity)
				.frame(minHeight: 200)
				.padding(16)
		}
	}
}

struct LoggerStatView: View {
	@ObservedObject var model: VisualizerPageModel

	var body: some View {
        VStack {
            Text("Логи")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title3)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            GeometryReader {
                geometry in
                ScrollView {
                    ForEach(0..<model.logger.content.count, id: \.self) { id in
                        Text(model.logger.content[id])
                            .font(Font.monospaced(Font.system(size: 12))())
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                    .frame(
                    minWidth: geometry.size.width,
                    idealWidth: geometry.size.width,
                    maxWidth: geometry.size.width,
                    minHeight: geometry.size.height,
                    idealHeight: geometry.size.height,
                    maxHeight: .infinity,
                    alignment: .topLeading)
            }
            .frame(minHeight: 200)
        }
        .padding(16)
	}
}
