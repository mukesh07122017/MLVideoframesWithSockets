//
//  VisualizerView.swift
//  MLSocketSDK
//
//  Created by Mahi Sharma on 25/11/21.
//

import Foundation
import UIKit
import MLSocketSDK

/** Visualizer class that draws the skeleton. Can be initialized by code or directly added to the
	storyboard on top of the preview image view. */
class VisualizerView : UIView {
	let coordinates:[(Int, Int)] = [(3,1),(1,0),(0,2),(2,4),(5,7),(5,6),(7,9),(8,10),
									(6,8),(5,11),(6,12),(11,13),(11,12),(12,14),(13,15),(14,16)]
	// Coordinated to connect the corresponding points in the point array.
	var points: [HumanCoordinates] = []
	var imgWidth: Double!
	var scaleX: CGFloat!
	var scaleY: CGFloat!
	let threshold: Double = 0.3
	// Set the threshold for the confidence score here.
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.backgroundColor = UIColor.init(white: 0.0, alpha: 0.0)
		// Sets background transparent, when initialized by code.
	}
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func draw(_ rect: CGRect) {
		if !points.isEmpty {
			if let context = UIGraphicsGetCurrentContext() {
				for connector in coordinates {
                    if (points[connector.0].score! > threshold) && (points[connector.1].score! > threshold) {
                        let x1 = imgWidth - (points[connector.0].x! * Double(scaleX))
                        let y1 = points[connector.0].y! * Double(scaleY)
                        let x2 = imgWidth - (points[connector.1].x! * Double(scaleX))
                        let y2 = points[connector.1].y! * Double(scaleY)
						context.setStrokeColor(UIColor.white.cgColor)
						context.setLineWidth(2)
						context.beginPath()
						context.move(to: CGPoint(x: x1, y: y1))
						context.addLine(to: CGPoint(x: x2, y: y2))
						context.strokePath()
						// Draws the points and connects the lines, while
						// scaling the values back up and flipping the
						// points horizontally to match the mirrored preview.
					}
				}
			}
			points = []
		}
	}
	
	func setPoints(pointsArray:[HumanCoordinates], xScale:CGFloat, yScale:CGFloat, imgWidth:CGFloat) {
		self.points = pointsArray
		self.scaleX = xScale
		self.scaleY = yScale
		self.imgWidth = Double(imgWidth)
		// Preview width is passed in, to flip the points horizontally.
	}
}

