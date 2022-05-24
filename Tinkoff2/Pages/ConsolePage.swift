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
	@Environment(\.presentationMode) var presentation

	var body: some View {
		List {
			HStack {
				Text("Статистика")
					.font(.system(size: 32, weight: .bold, design: .default))
					.padding(16)
				Spacer()
				Image(systemName: "xmark.circle.fill")
					.foregroundColor(.gray)
					.onTapGesture {
					if self.model.dismissController != nil {
						self.model.dismissController!()
					}
				}
			}
			DashboardView(model: model)
			LoggerStatView(model: model)
		}
			.listStyle(.plain)
	}
}

struct DashboardView: View {
	@ObservedObject var model: VisualizerPageModel

	var columnsDouble: [GridItem] = [
		GridItem(.adaptive(minimum: 300), spacing: 32),
	]

	var columnsTriple: [GridItem] = [
		GridItem(.adaptive(minimum: 200), spacing: 32),
	]

	var body: some View {
		VStack {
			LazyVGrid(
				columns: columnsDouble,
				alignment: .center,
				spacing: 16
			) {
				BoughtInstrumentStatView(model: model)
				SoldInstrumentStatView(model: model)
			}
			LazyVGrid(
				columns: columnsTriple,
				alignment: .center,
				spacing: 16
			) {
				CompareRubsStatView(model: model)
				CompareUSDStatView(model: model)
				CompareEURStatView(model: model)
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
		uiView.setChartData(bars: [BarDescriptor(value: Int(self.model.stat.soldStocks), label: "Акции", color: SoftColorList[0]), BarDescriptor(value: Int(self.model.stat.soldEtfs), label: "Фонды", color: SoftColorList[1]), BarDescriptor(value: Int(self.model.stat.soldCurrency), label: "Валюта", color: SoftColorList[2])])
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

struct CompareRubsGraphViewUI: UIViewRepresentable {
	@ObservedObject var model: VisualizerPageModel

	func makeUIView(context: Context) -> BarGraphView {
		BarGraphView()
	}

	func updateUIView(_ uiView: BarGraphView, context: Context) {
		if self.model.activeStock == nil {
			return
		}
		uiView.setChartData(bars: [BarDescriptor(value: Int(self.model.stat.boughtProfitRub), label: "Куплено", color: SoftColorList[1]), BarDescriptor(value: Int(self.model.stat.soldProfitRub), label: "Продано", color: SoftColorList[2])])
	}
}

struct CompareRubsStatView: View {
	@ObservedObject var model: VisualizerPageModel

	var body: some View {
		VStack {
			Text("Рубль")
				.frame(maxWidth: .infinity, alignment: .leading)
				.font(.title3)
				.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
			DescriptionTextView(text: "Сравнение стоимости покупок и продаж в Рублях (RUB)")
				.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
			CompareRubsGraphViewUI(model: model)
				.frame(maxWidth: .infinity)
				.frame(minHeight: 200)
				.padding(16)
		}
	}
}

struct CompareUSDGraphViewUI: UIViewRepresentable {
	@ObservedObject var model: VisualizerPageModel

	func makeUIView(context: Context) -> BarGraphView {
		BarGraphView()
	}

	func updateUIView(_ uiView: BarGraphView, context: Context) {
		if self.model.activeStock == nil {
			return
		}
		uiView.setChartData(bars: [BarDescriptor(value: Int(self.model.stat.boughtProfitUSD), label: "Куплено", color: SoftColorList[1]), BarDescriptor(value: Int(self.model.stat.soldProfitUSD), label: "Продано", color: SoftColorList[2])])
	}
}

struct CompareUSDStatView: View {
	@ObservedObject var model: VisualizerPageModel

	var body: some View {
		VStack {
			Text("Доллар")
				.frame(maxWidth: .infinity, alignment: .leading)
				.font(.title3)
				.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
			DescriptionTextView(text: "Сравнение стоимости покупок и продаж в Долларах (USD)")
				.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
			CompareUSDGraphViewUI(model: model)
				.frame(maxWidth: .infinity)
				.frame(minHeight: 200)
				.padding(16)
		}
	}
}

struct CompareEURGraphViewUI: UIViewRepresentable {
	@ObservedObject var model: VisualizerPageModel

	func makeUIView(context: Context) -> BarGraphView {
		BarGraphView()
	}

	func updateUIView(_ uiView: BarGraphView, context: Context) {
		if self.model.activeStock == nil {
			return
		}
		uiView.setChartData(bars: [BarDescriptor(value: Int(self.model.stat.boughtProfitEUR), label: "Куплено", color: SoftColorList[1]), BarDescriptor(value: Int(self.model.stat.soldProfitEUR), label: "Продано", color: SoftColorList[2])])
	}
}

struct CompareEURStatView: View {
	@ObservedObject var model: VisualizerPageModel

	var body: some View {
		VStack {
			Text("Евро")
				.frame(maxWidth: .infinity, alignment: .leading)
				.font(.title3)
				.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
			DescriptionTextView(text: "Сравнение стоимости покупок и продаж в Евро (EUR)")
				.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
			CompareEURGraphViewUI(model: model)
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
