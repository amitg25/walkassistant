//
//  DrawingBoundingBoxView.swift
//  SSDMobileNet-CoreML
//
//  Created by GwakDoyoung on 04/02/2019.
//  Copyright © 2019 tucan9389. All rights reserved.
//

import UIKit
import Vision

class DrawingBoundingBoxView: UIView {
    
    static private var colors: [String: UIColor] = [:]
    
    public func labelColor(with label: String) -> UIColor {
        if let color = DrawingBoundingBoxView.colors[label] {
            return color
        } else {
            let color = UIColor(hue: .random(in: 0...1), saturation: 1, brightness: 1, alpha: 0.8)
            DrawingBoundingBoxView.colors[label] = color
            return color
        }
    }
    
    public var predictedObjects: [VNRecognizedObjectObservation] = [] {
        didSet {
            self.drawBoxs(with: predictedObjects)
            self.setNeedsDisplay()
        }
    }
    
    private var rects: [String:CGRect] = [:]
    
    func drawBoxs(with predictions: [VNRecognizedObjectObservation]) {
        subviews.forEach({ $0.removeFromSuperview() })
        
        self.rects = [:]
        
        for prediction in predictions {
            createLabelAndBox(prediction: prediction)
        }
    }
    
    func createLabelAndBox(prediction: VNRecognizedObjectObservation) {
        let labelString: String? = prediction.label
        let color: UIColor = labelColor(with: labelString ?? "N/A")
        
        let scale = CGAffineTransform.identity.scaledBy(x: bounds.width, y: bounds.height)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        let bgRect = prediction.boundingBox.applying(transform).applying(scale)
        
        let bgView = UIView(frame: bgRect)
        bgView.layer.borderColor = color.cgColor
        bgView.layer.borderWidth = 4
        bgView.backgroundColor = UIColor.clear
        addSubview(bgView)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        label.text = labelString ?? "N/A"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.black
        label.backgroundColor = color
        label.sizeToFit()
        label.frame = CGRect(x: bgRect.origin.x, y: bgRect.origin.y - label.frame.height,
                             width: label.frame.width, height: label.frame.height)
        addSubview(label)
        
        let labelKey = label.text!
        if rects[labelKey] != nil {
            let currRect = rects[labelKey]!
            let currArea = currRect.width * currRect.height
            let thisArea = bgRect.width * bgRect.height
            if currArea < thisArea {
                rects[labelKey] = bgRect
            }
        } else {
            rects[labelKey] = bgRect
        }
    }
    
    func process() -> String {
        
        var largest:CGFloat = 0.0
        var finalLabel = ""
        // figure out the largest area in map
        for (label, rect) in rects {
            let area = rect.width * rect.height
            if largest < area {
                largest = area
                finalLabel = label
            }
        }
        print("Label: \(finalLabel) area: \(largest)")
        return finalLabel
    }
}

extension VNRecognizedObjectObservation {
    var label: String? {
        return self.labels.first?.identifier
    }
}

extension CGRect {
    func toString(digit: Int) -> String {
        let xStr = String(format: "%.\(digit)f", origin.x)
        let yStr = String(format: "%.\(digit)f", origin.y)
        let wStr = String(format: "%.\(digit)f", width)
        let hStr = String(format: "%.\(digit)f", height)
        return "(\(xStr), \(yStr), \(wStr), \(hStr))"
    }
}
