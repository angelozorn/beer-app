//
//  BalloonMarker.swift
//  Beer-Tracker-App
//
//  Created by Angelo Zorn on 6/24/25.
//

import UIKit
import DGCharts   // not DGCharts

open class BalloonMarker: MarkerImage {
    public var color: UIColor
    public var arrowSize = CGSize(width: 15, height: 11)
    public var font: UIFont
    public var textColor: UIColor
    public var insets: UIEdgeInsets
    public var minimumSize = CGSize()

    private var label: String = ""
    private var _labelSize: CGSize = .zero
    private var _markerSize: CGSize = .zero          // renamed from _size
    private var _paragraphStyle: NSMutableParagraphStyle?
    private var _drawAttributes = [NSAttributedString.Key: Any]()

    public init(color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets) {
        self.color = color
        self.font = font
        self.textColor = textColor
        self.insets = insets
        super.init()

        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        _paragraphStyle?.alignment = .center
    }

    open override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        let size = self.size
        return CGPoint(x: -size.width / 2, y: -size.height)
    }

    open override func draw(context: CGContext, point: CGPoint) {
        guard let chart = chartView else { return }
        let offset = offsetForDrawing(atPoint: point)
        let rect = CGRect(
            origin: CGPoint(x: point.x + offset.x, y: point.y + offset.y),
            size: _markerSize
        )

        context.saveGState()
        context.setFillColor(color.cgColor)
        context.beginPath()
        context.addRect(rect)
        context.fillPath()

        if _labelSize.width > 0 {
            let labelRect = rect.inset(by: insets)
            UIGraphicsPushContext(context)
            label.draw(in: labelRect, withAttributes: _drawAttributes)
            UIGraphicsPopContext()
        }
        context.restoreGState()
    }

    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        label = String(format: "%g", entry.y)

        _drawAttributes.removeAll()
        _drawAttributes[.font] = font
        _drawAttributes[.paragraphStyle] = _paragraphStyle
        _drawAttributes[.foregroundColor] = textColor

        _labelSize = label.size(withAttributes: _drawAttributes)
        _markerSize.width = _labelSize.width + insets.left + insets.right
        _markerSize.height = _labelSize.height + insets.top + insets.bottom

        if _markerSize.width < minimumSize.width {
            _markerSize.width = minimumSize.width
        }
        if _markerSize.height < minimumSize.height {
            _markerSize.height = minimumSize.height
        }
    }

    // MARK: – Match the mutable `size` property in MarkerImage
    open override var size: CGSize {
        get { _markerSize }
        set { _markerSize = newValue }
    }
}
