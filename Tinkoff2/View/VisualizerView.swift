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

	@Published var figiData: [Instrument] = []

	init() { }
}


struct GraphViewUI: UIViewRepresentable {
	@ObservedObject var model: VisualizerPageModel

	func makeUIView(context: Context) -> GraphView {
		GraphView()
	}

	func updateUIView(_ uiView: GraphView, context: Context) {
		uiView.setChartData()
	}
}

struct ToolView: View {
	@ObservedObject var model: VisualizerPageModel

	var body: some View {
		VStack {
			Text("Tsla")

		}
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
				ForEach(0..<model.figiData.count, id: \.self) { id in
					VStack {
						AsyncImage(url: URL(string: "https://invest-brands.cdn-tinkoff.ru/\(model.figiData[id].isin)x160.png")) { phase in
							switch phase {
							case .success(let image):
								image
									.resizable()
									.aspectRatio(contentMode: .fit)
									.frame(width: 50, height: 50)
									.clipShape(RoundedRectangle(cornerRadius: 25))

							case .failure(let error):
								Text(error.localizedDescription)

							case .empty:
								waitView()

							@unknown default:
								EmptyView()
							}
						}

						Text(model.figiData[id].name)
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
		List {
			Section(header: CardsView(model: model)) {
				ForEach(1..<40) { index in
					Text("Row #\(index)")
				}
			}
		}
			.listStyle(.plain)
	}
}
