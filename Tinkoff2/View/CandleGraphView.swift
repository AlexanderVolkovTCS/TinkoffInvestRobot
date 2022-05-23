//
//  ProfileView.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import UIKit
import Charts
import TinkoffInvestSDK

class CandleGraphView: UIView {
	fileprivate var chartView: CombinedChartView = CombinedChartView()

	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		chartView = CombinedChartView()
		chartView.translatesAutoresizingMaskIntoConstraints = false
		let swUIViewHC1 = NSLayoutConstraint(item: chartView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0)
		let swUIViewHC2 = NSLayoutConstraint(item: chartView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
		let swUIViewHC3 = NSLayoutConstraint(item: chartView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
		let swUIViewHC4 = NSLayoutConstraint(item: chartView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0)
		addSubview(chartView)
		addConstraints([swUIViewHC1, swUIViewHC2, swUIViewHC3, swUIViewHC4])

		chartView.dragEnabled = false
		chartView.doubleTapToZoomEnabled = false
		chartView.drawBarShadowEnabled = false
		chartView.highlightFullBarEnabled = false
		chartView.autoScaleMinMaxEnabled = false
		chartView.chartDescription!.enabled = false

		chartView.legend.enabled = false
		chartView.rightAxis.enabled = true
		chartView.leftAxis.enabled = false
		chartView.xAxis.enabled = false
	}

	func setChartData(candles: [CandleData], rsi: [Float64]) {
		let data = CombinedChartData()
        data.lineData = generateLineData(candles: candles, rsi: rsi)
        data.candleData = generateCandleData(candles: candles)

		chartView.xAxis.axisMaximum = data.xMax + 1
		chartView.xAxis.axisMinimum = 0

		chartView.data = data
	}

	func generateCandleData(candles: [CandleData]) -> CandleChartData {
		var entries: [CandleChartDataEntry] = []

        let start = max(candles.count - GlobalBotConfig.algoConfig.rsiPeriod, 0)
		let padding = GlobalBotConfig.algoConfig.rsiPeriod - min(candles.count, GlobalBotConfig.algoConfig.rsiPeriod)
		for i in start..<candles.count {
			let candle = candles[i]
			entries.append(CandleChartDataEntry(x: Double(padding + i - start), shadowH: candle.high.asDouble(), shadowL: candle.low.asDouble(), open: candle.open.asDouble(), close: candle.close.asDouble()))
		}

		let set = CandleChartDataSet(entries: entries, label: "Candle DataSet")
		set.increasingColor = UIColor(rgb: 0xacd1af)
		set.increasingFilled = true
		set.decreasingColor = UIColor(rgb: 0xff6961)
		set.decreasingFilled = true
		set.shadowColor = UIColor(white: 230 / 255, alpha: 1.0)
		set.drawValuesEnabled = false

		return CandleChartData(dataSet: set)
	}
    
    func generateLineData(candles: [CandleData], rsi: [Float64])-> LineChartData {
        let candlesStart = max(candles.count - GlobalBotConfig.algoConfig.rsiPeriod, 0)
        var maxCandle: Double = 0.0001
        var minCandle: Double = 1000000.0
        for i in candlesStart..<candles.count {
            let candle = candles[i]
            maxCandle = max(maxCandle, candle.high.asDouble())
            minCandle = min(minCandle, candle.low.asDouble())
        }
        
        let rsiStart = max(rsi.count - GlobalBotConfig.algoConfig.rsiPeriod, 0)
        let rsiPadding = GlobalBotConfig.algoConfig.rsiPeriod - min(rsi.count, GlobalBotConfig.algoConfig.rsiPeriod)
        let entries = (rsiStart..<rsi.count).map { (i) -> ChartDataEntry in
            let myY = rsi[i]
            let newY = (myY / 100.0) * (maxCandle - minCandle) + minCandle
            return ChartDataEntry(x: Double(rsiPadding + i - rsiStart), y: newY)
        }
        
        let set = LineChartDataSet(entries: entries, label: "RSI")
        let clr = UIColor(red: 180/255, green: 215/255, blue: 254/255, alpha: 0.8)
        set.setColor(clr)
        set.lineWidth = 2.5
        set.setCircleColor(clr)
        set.circleRadius = 3
        set.circleHoleRadius = 2.5
        set.fillColor = UIColor(red: 240/255, green: 238/255, blue: 70/255, alpha: 1)
        set.mode = .cubicBezier
        set.drawValuesEnabled = false
        set.axisDependency = .left
        
        return LineChartData(dataSet: set)
    }
}

extension Quotation {
	func asDouble() -> Double {
		return Double(self.units) + (Double(self.nano) / 1e9);
	}
}
