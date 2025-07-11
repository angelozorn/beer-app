
import SwiftUI
import UIKit
import DGCharts    // ← not DGCharts

struct BarChartViewRepresentable: UIViewRepresentable {
  let entries: [BarChartDataEntry]
  let labels: [String]
  let dates: [Date]
  var onSelect: (Date) -> Void  // callback on bar tap
    
    func makeCoordinator() -> Coordinator {
            Coordinator(dates: dates, onSelect: onSelect)
        }

        class Coordinator: NSObject, ChartViewDelegate {
            let dates: [Date]
            let onSelect: (Date) -> Void
            init(dates: [Date], onSelect: @escaping (Date) -> Void) {
                self.dates = dates
                self.onSelect = onSelect
            }

            func chartValueSelected(_ chartView: ChartViewBase,
                                    entry: ChartDataEntry,
                                    highlight: Highlight) {
                let index = Int(highlight.x)
                guard index < dates.count else { return }
                onSelect(dates[index])
            }
        }


  func makeUIView(context: Context) -> BarChartView {
    let chart = BarChartView()
      chart.delegate = context.coordinator
      chart.chartDescription.enabled = false
      chart.legend.enabled = false
      chart.xAxis.labelPosition = .bottom
      chart.rightAxis.enabled = false

              // Optional Marker for values
      let marker = BalloonMarker(color: .darkGray,
                                  font: .systemFont(ofSize: 12),
                                  textColor: .white,
                                  insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
      marker.chartView = chart
      chart.marker = marker
    return chart
  }

  func updateUIView(_ uiView: BarChartView, context: Context) {
    let dataSet = BarChartDataSet(entries: entries, label: "")
    dataSet.colors = ChartColorTemplates.material()
    dataSet.valueTextColor = UIColor.white

    let data = BarChartData(dataSet: dataSet)
    data.barWidth = 0.8
    uiView.data = data

    uiView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
    uiView.xAxis.granularity = 1
    uiView.notifyDataSetChanged()
  }
}
