//
//  ConsoleView.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 22.05.2022.
//

import SwiftUI


struct ConsolePageView: View {
    @ObservedObject var model: VisualizerPageModel
    
    var body: some View {
        List {
            Text("Dashboard")
                .font(.largeTitle)
            DashboardView(model: model)
        }
        .listStyle(.plain)
    }
}

struct DashboardView: View {
    @ObservedObject var model: VisualizerPageModel
    
    var columns: [GridItem] = [
        GridItem(.adaptive(minimum: 160), spacing: 32),
        GridItem(.adaptive(minimum: 160), spacing: 32)
    ]
    
    var body: some View {
            LazyVGrid(
                columns: columns,
                alignment: .center,
                spacing: 16
            ) {
                SoldStockStatView(model: model)
                
            }
    }
}


struct SoldStockStatView: View {
    @ObservedObject var model: VisualizerPageModel
    
    var body: some View {
        VStack {
            Text("Sold/bought")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title)
            SoldStocksStatGraphViewUI(model: model)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 200)
            SoldStocksStatGraphViewUI(model: model)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 200)
        }
    }
}

struct SoldStocksStatGraphViewUI: UIViewRepresentable {
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



