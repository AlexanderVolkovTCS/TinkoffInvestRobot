//
//  VisualizerView.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import SwiftUI

class VisualizerPageModel: ObservableObject {
	@Published var data: [Int]? = nil

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


struct VisualizerPageView: View {
	@ObservedObject var model: VisualizerPageModel

	let columns = [
        GridItem(.adaptive(minimum: 200))
	]

	var body: some View {
		VStack {
			ScrollView {
				LazyVGrid(columns: columns) {
					ForEach(0...9, id: \.self) { id in
                        GraphViewUI(model: model)
                            .frame(width: 100, height: 100)
					}
				}
			}
		}
	}
}
