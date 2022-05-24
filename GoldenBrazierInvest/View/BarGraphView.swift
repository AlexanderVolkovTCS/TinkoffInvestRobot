//
//  BarGraphView.swift
//  Tinkoff2
//
//  Created by Никита Мелехин on 22.05.2022.
//

import UIKit
import Charts
import TinkoffInvestSDK

struct BarDescriptor {
	public var value: Int = 0
	public var label: String = ""
	public var color: UIColor = .cyan
}

class BarGraphView: UIView {
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
		chartView.chartDescription!.enabled = true

		chartView.legend.enabled = true
		chartView.rightAxis.enabled = true
		chartView.leftAxis.enabled = false
		chartView.xAxis.enabled = false

	}

	func setChartData(bars: [BarDescriptor]) {
		let data = CombinedChartData()
		data.barData = generateBarData(bars: bars)

		chartView.xAxis.axisMaximum = data.xMax + 1
		chartView.xAxis.axisMinimum = 0

		chartView.data = data
	}

	func generateBarSet(bar: BarDescriptor, id: Int) -> BarChartDataSet {
		let entries = [BarChartDataEntry(x: Double(id), y: Double(bar.value))]
		let set1 = BarChartDataSet(entries: entries, label: bar.label)
		set1.setColor(bar.color)
		set1.valueTextColor = bar.color.darker(by: 40) ?? .black
		set1.valueFont = .systemFont(ofSize: 10)
		set1.axisDependency = .left

		return set1
	}

	func generateBarData(bars: [BarDescriptor]) -> BarChartData {
		var sets: [BarChartDataSet] = []
		for i in 0..<bars.count {
			sets.append(generateBarSet(bar: bars[i], id: i))
		}

		let groupSpace = 0.00
		let barSpace = 0.00
		let barWidth = 1.0

		let data = BarChartData(dataSets: sets)
		data.barWidth = barWidth

		data.groupBars(fromX: 0, groupSpace: groupSpace, barSpace: barSpace)
		return data
	}
}
