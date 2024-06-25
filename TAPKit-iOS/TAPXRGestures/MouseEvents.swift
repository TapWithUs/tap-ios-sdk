//
//  MouseEvents.swift
//  TAPKitInternal
//
//  Created by Shahar Biran on 29/05/2024.
//  Copyright © 2024 Shahar Biran. All rights reserved.
//

import Foundation

enum MouseEventType {
    case cursor(vx:Int, vy:Int, ts:TimeInterval)
    case click(gesture:Int, ts:TimeInterval)
    
}

enum MouseEventsAction {
    case release
    case flick
    case press
    case drag
    case scroll(vy:Double)
}

protocol MouseEventsDelegate : class {
    func mouseEventsAction(_ action:MouseEventsAction)
    
}

class MouseEvents {
    
    private var prevGesture : XRGestureState
    private var gestureDuration : Int
    private var directionAggregator : Deque<(vx:Double, vy:Double)>
    private var motionAggregator : Deque<Double>
    private var meanDirection : (vx:Double, vy:Double)
    private var meanMotion : Double
    private var inFlick : Bool
    private var vy : Double
    private let flickMotionThreshold : Double = 10
    
    weak var delegate : MouseEventsDelegate?
    
    init() {
        self.inFlick = false
        self.meanDirection = (vx: 0, vy: 0)
        self.meanMotion = 0
        self.directionAggregator = Deque(len: 20)
        self.motionAggregator = Deque(len: 10)
        self.prevGesture = XRGestureState.none
        self.gestureDuration = 0
        self.vy = 0
    }
    
    private func norm(x:Double, y:Double) -> Double {
        return sqrt(pow(x, 2) + pow(y, 2))
    }
    
    private func getMeanDirection(_ v:[(vx:Double, vy:Double)]) -> (vx:Double, vy:Double) {
        var sumX : Double = 0
        var sumY : Double = 0
        v.forEach({ e in
            sumX = sumX + e.vx
            sumY = sumY + e.vy
        })
        return (vx: sumX/Double(v.count), vy: sumY/Double(v.count))
    }
    
    func dispatchAction(_ a:MouseEventsAction) {
        DispatchQueue.main.async {
            self.delegate?.mouseEventsAction(a)
        }
    }
    
    private func doFlick(mm:Double) -> Void {
        self.inFlick = true
        let delta = mm > 0 ? 1 : -1
        
    }
    
    func put(_ m : MouseEventType) {
        
        switch m {
        case .cursor(let vx, let vy, _):
            self.vy = Double(vy)
            self.directionAggregator.add((vx: Double(vx), vy: Double(vy)))
            self.motionAggregator.add(self.norm(x: Double(vx), y: Double(vy)))
            self.meanDirection = self.getMeanDirection(self.directionAggregator.all())
            self.meanMotion = self.motionAggregator.all().reduce(0,+) / Double(self.motionAggregator.all().count)
            break
        case .click(let gesture,_):
            if let g = XRGestureState(rawValue: gesture) {
                self.gestureDuration = self.gestureDuration + 1
                if self.prevGesture != g {
                    self.gestureDuration = 0
                    if g == .none {
                        self.dispatchAction(.release)
                        
                        if self.prevGesture == .thumb_middle && !self.inFlick {
                            if self.meanMotion > self.flickMotionThreshold {
                                self.meanMotion = self.meanMotion * ( self.meanDirection.vy < 0 ? 1.0 : -1.0 )
                            }
                        }
                    } else {
                        self.inFlick = false
                        if g == .thumb_middle {
                            self.dispatchAction(.release)
                        }
                    }
                    self.prevGesture = g

                }
                if self.gestureDuration == 1 && self.prevGesture == .thumb_finger {
                    self.dispatchAction(.press)
                }
                if gestureDuration > 2 && self.prevGesture == .thumb_middle {
                    self.dispatchAction(.scroll(vy: self.vy))
                }
            }
            break
            
        }
    
    }
}
