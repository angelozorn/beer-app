//
//  PieChartViewRepresentable.swift
//  Beer-Tracker-App
//
//  Created by Angelo Zorn on 6/24/25.
//
import SwiftUI
import DGCharts
import UIKit// the danielgindi/Charts module

struct PieChartViewRepresentable: UIViewRepresentable {
  let entries: [PieChartDataEntry]
  let colors: [UIColor]
  var onSelect: (String) -> Void
  
    func makeCoordinator() -> Coordinator {
            Coordinator(onSelect: onSelect)
        }

        class Coordinator: NSObject, ChartViewDelegate {
            let onSelect: (String) -> Void
            init(onSelect: @escaping (String) -> Void) {
                self.onSelect = onSelect
            }

            func chartValueSelected(_ chartView: ChartViewBase,
                                    entry: ChartDataEntry,
                                    highlight: Highlight) {
                guard let pieEntry = entry as? PieChartDataEntry,
                      let label = pieEntry.label else { return }
                onSelect(label)
            }
        }

  func makeUIView(context: Context) -> PieChartView {
    let chart = PieChartView()
    chart.delegate = context.coordinator
    chart.holeRadiusPercent = 0.4
    chart.legend.enabled = true
    chart.chartDescription.enabled = false
      
      let marker = BalloonMarker(color: UIColor.darkGray,
                                         font: .systemFont(ofSize: 12),
                                         textColor: .white,
                                         insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
              marker.chartView = chart
              chart.marker = marker
      
    return chart
  }

  func updateUIView(_ uiView: PieChartView, context: Context) {
    let dataSet = PieChartDataSet(entries: entries, label: "")
    dataSet.colors = colors
    dataSet.entryLabelColor = UIColor.white
    dataSet.valueTextColor = UIColor.white
    uiView.data = PieChartData(dataSet: dataSet)
    uiView.notifyDataSetChanged()
  }
}
