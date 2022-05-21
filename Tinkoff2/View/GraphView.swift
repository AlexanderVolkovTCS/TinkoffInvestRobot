//
//  ProfileView.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 21.05.2022.
//

import UIKit
import Charts

class GraphView: UIView {
	let ITEM_COUNT = 10
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
        
        print(bounds)

		chartView.dragEnabled = false
		chartView.doubleTapToZoomEnabled = false
		chartView.drawBarShadowEnabled = false
		chartView.highlightFullBarEnabled = false
		chartView.autoScaleMinMaxEnabled = false
		chartView.chartDescription!.enabled = false

		chartView.legend.enabled = false
		chartView.rightAxis.enabled = false
		chartView.leftAxis.enabled = false
		chartView.xAxis.enabled = false

		self.updateChartData()
	}

	public func updateChartData() {
		self.setChartData()
	}

	func setChartData() {
		let data = CombinedChartData()
		data.lineData = generateLineData()
		data.candleData = generateCandleData()

		chartView.xAxis.axisMaximum = data.xMax + 1
		chartView.xAxis.axisMinimum = data.xMin - 1

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

	func generateLineData() -> LineChartData {
		let set1 = genLine((0..<ITEM_COUNT).map { (i) -> ChartDataEntry in
				return ChartDataEntry(x: Double(i) + 1, y: Double(95))
			})

		let set2 = genLine((0..<ITEM_COUNT).map { (i) -> ChartDataEntry in
				return ChartDataEntry(x: Double(i) + 1, y: Double(5))
			})

		let set3 = genLine((0..<ITEM_COUNT).map { (i) -> ChartDataEntry in
				return ChartDataEntry(x: Double(i) + 1, y: 50)
			})


		return LineChartData(dataSets: [set1, set2, set3])
	}


//    func generateScatterData() -> ScatterChartData {
//        let entries = stride(from: 0.0, to: Double(ITEM_COUNT), by: 0.5).map { (i) -> ChartDataEntry in
//            return ChartDataEntry(x: i+0.25, y: Double(arc4random_uniform(10) + 55))
//        }
//
//        let set = ScatterChartDataSet(entries: entries, label: "Scatter DataSet")
//        set.colors = ChartColorTemplates.material()
//        set.scatterShapeSize = 4.5
//        set.drawValuesEnabled = false
//        set.valueFont = .systemFont(ofSize: 10)
//
//        return ScatterChartData(dataSet: set)
//    }

	func generateCandleData() -> CandleChartData {
		let entries = stride(from: 0, to: ITEM_COUNT, by: 1).map { (i) -> CandleChartDataEntry in
			return CandleChartDataEntry(x: Double(i + 1), shadowH: 100, shadowL: 0, open: 50, close: Double(arc4random_uniform(100)))
		}

		let set = CandleChartDataSet(entries: entries, label: "Candle DataSet")
		set.increasingColor = UIColor(rgb: 0xacd1af)
		set.increasingFilled = true
		set.decreasingColor = UIColor(rgb: 0xff6961)
		set.decreasingFilled = true
		set.shadowColor = UIColor(white: 1.0, alpha: 1.0)
		set.drawValuesEnabled = false

		return CandleChartData(dataSet: set)
	}
}
