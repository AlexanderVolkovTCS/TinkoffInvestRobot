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
	let ITEM_COUNT = 30
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
		chartView.xAxis.enabled = true

	}

	func setChartData(candles: [CandleData]) {
		let data = CombinedChartData()
//		data.lineData = generateLineData()
		data.candleData = generateCandleData(candles: candles)

		chartView.xAxis.axisMaximum = data.xMax + 1
		chartView.xAxis.axisMinimum = 0

		chartView.data = data
	}

	func genLine(_ entries: [ChartDataEntry]) -> LineChartDataSet {
		let lineSet = LineChartDataSet(entries: entries, label: "")

		lineSet.setColor(UIColor(rgb: 0x0))
		lineSet.lineWidth = 2
		lineSet.setCircleColor(UIColor(rgb: 0x0))
		lineSet.circleRadius = 1
		lineSet.circleHoleRadius = 0
		lineSet.fillColor = UIColor(rgb: 0x0)
		lineSet.mode = .cubicBezier
		lineSet.drawValuesEnabled = false
		lineSet.valueFont = .systemFont(ofSize: 10)
		lineSet.valueTextColor = UIColor(rgb: 0x0)

		lineSet.axisDependency = .left

		return lineSet
	}

//	func generateLineData() -> LineChartData {
//		let set1 = genLine((0..<ITEM_COUNT).map { (i) -> ChartDataEntry in
//				return ChartDataEntry(x: Double(i) + 1, y: Double(95))
//			})
//
//		let set2 = genLine((0..<ITEM_COUNT).map { (i) -> ChartDataEntry in
//				return ChartDataEntry(x: Double(i) + 1, y: Double(5))
//			})
//
//		let set3 = genLine((0..<ITEM_COUNT).map { (i) -> ChartDataEntry in
//				return ChartDataEntry(x: Double(i) + 1, y: 50)
//			})
//
//
//		return LineChartData(dataSets: [set1, set2, set3])
//	}

	func generateCandleData(candles: [CandleData]) -> CandleChartData {
		var entries: [CandleChartDataEntry] = []

		let start = max(candles.count - 30, 0)
		let padding = 30 - min(candles.count, 30)
		for i in start..<candles.count {
			let candle = candles[i]
			entries.append(CandleChartDataEntry(x: Double(padding + i), shadowH: candle.high.asDouble(), shadowL: candle.low.asDouble(), open: candle.open.asDouble(), close: candle.close.asDouble()))
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
}

extension Quotation {
	func asDouble() -> Double {
		return Double(self.units) + (Double(self.nano) / 1e9);
	}
}
