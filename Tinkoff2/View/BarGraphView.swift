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
        chartView.chartDescription!.enabled = false

        chartView.legend.enabled = false
        chartView.rightAxis.enabled = true
        chartView.leftAxis.enabled = false
        chartView.xAxis.enabled = true

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
        var sets : [BarChartDataSet] = []
        for i in 0..<bars.count {
            sets.append(generateBarSet(bar: bars[i], id: i))
        }
        
        let groupSpace = 0.06
        let barSpace = 0.02 // x2 dataset
        let barWidth = 0.45 // x2 dataset
        // (0.45 + 0.02) * 2 + 0.06 = 1.00 -> interval per "group"
        
        let data = BarChartData(dataSets: sets)
        data.barWidth = barWidth
        
        // make this BarData object grouped
        data.groupBars(fromX: 0, groupSpace: groupSpace, barSpace: barSpace)
        
        return data
    }
}

extension UIColor {

    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
}
