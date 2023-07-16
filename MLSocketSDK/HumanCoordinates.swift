//
//  HumanCoordinates.swift
//  MLSocketSDK
//
//  Created by Mahi Sharma on 25/11/21.
//

import Foundation


//
//{"keypoints": [[192.70440101623535, 172.06280708312988, 0.498623788356781], [164.60735321044922, 211.59260272979736, 0.4698735773563385], [157.00168132781982, 152.0030379295349, 0.6373220086097717], [226.74144744873047, 258.0782675743103, 0.5432517528533936], [194.77375030517578, 130.6999683380127, 0.545688271522522], [381.9118881225586, 285.36948680877686, 0.1325085461139679], [350.93213081359863, 67.25268959999084, 0.10670551657676697], [383.6997413635254, 287.4357748031616, 0.04762265086174011], [351.93471908569336, 46.22853755950928, 0.05170571804046631], [380.7656478881836, 282.8929281234741, 0.05834072828292847], [276.4999008178711, 118.29578161239624, 0.03174754977226257], [451.1820602416992, 278.03735733032227, 0.13771557807922363], [445.7635974884033, 264.6681761741638, 0.09156125783920288], [194.130220413208, 221.25627994537354, 0.1033211350440979], [294.0066719055176, 51.784712076187134, 0.040162891149520874], [235.6717014312744, 125.73015689849854, 0.03474193811416626], [287.86173820495605, 57.864840030670166, 0.03425857424736023]], "angle": 8.010709326681377, "reps": false, "corr_1": true, "corr_2": true, "corr_3": false, "status": 1}



open class FrameMetaData {
    
    public var PointsArray = [HumanCoordinates]()
    public var reps: Int? = 0
    public var corr_1: Bool? = false
    public var corr_2: Bool? = false
    public var corr_3: Bool? = false
    public var prevAngle:Int? = 0
    public var errorMsgForcorr_1:String? = ""
    public var errorMsgForcorr_2:String? = ""
    public var errorMsgForcorr_3:String? = ""
    public var stage:String? = ""
    public var pTime:Double? = 0
    /// The confidence of the estimation.
    public var score: Double? = 0
    public var aVelocity: Double? = 0
    
    public init() {}
    
    public func getFrameMetaDataWith(dict:[String:AnyObject]) -> FrameMetaData{
        
        if let aVelocity = dict["aVelocity"] as? NSNumber{
            self.aVelocity = Double(truncating: aVelocity)
        }
        if let pTime = dict["pTime"] as? NSNumber{
            self.pTime = Double(truncating: pTime)
        }
        if let angle = dict["angle"] as? NSNumber{
            self.prevAngle = Int(truncating: angle)
        }
        if let angle = dict["angle"] as? Int{
            self.prevAngle = angle
        }
        if let stage = dict["stage"] as? String{
            self.stage = stage
        }
        if let angle = dict["angle"] as? Double{
            self.prevAngle = Int(angle)
        }
       
        if let reps = dict["reps"] as? NSNumber{
            self.reps = Int(truncating: reps)
        }
        if let reps = dict["reps"] as? Int{
            self.reps = reps
        }
        
        if let corr_1 = dict["corr_1"] as? Bool{
           self.corr_1 = corr_1
            if corr_1 == true {
                errorMsgForcorr_1 = "Please display the required body parts in front of the camera for the respective exercise"
            }
            
        }
        if let corr_2 = dict["corr_2"] as? Bool{
           self.corr_2 = corr_2
            if corr_2 == true {
                errorMsgForcorr_2 = "Please face camera sideways"
            }
        }
        if let corr_3 = dict["corr_3"] as? Bool{
           self.corr_3 = corr_3
            if corr_3 == true {
                errorMsgForcorr_3 = "Range of motion interrupted"
            }
        }
        if let data = dict["keypoints"] as? [AnyObject]{
            if(data.count > 0){
                for devicedif in data{
                var objMeetingInfoModel = HumanCoordinates()
                objMeetingInfoModel = objMeetingInfoModel.getPointsWith(dict: devicedif as! [AnyObject])
                   PointsArray.append(objMeetingInfoModel)
                }
        }
       
        
    }
        return self
    }
    
}



open class HumanCoordinates {

    /// The x-axis coordinate.
    public var x: Double? = 0

    /// The y-axis coordinate.
    public var y: Double? = 0

    /// The z-axis coordinate.
    public let z: Double? = 0

    /// The confidence of the estimation.
    public var score: Double? = 0
    
   // [192.70440101623535, 172.06280708312988, 0.498623788356781]
    
  
    /**
    Creates a new point from cartesian coordinates.
    - Parameters:
        - index 1 : The x-axis coordinate.
        - index 0 : The y-axis coordinate.
        - index 2 : The confidence of the estimation.
    */
    
    public init() {}
    
    
    public func getPointsWith(dict:[AnyObject]) -> HumanCoordinates{
      
         if let xpoint = dict[1] as? NSNumber{
            self.x = Double(truncating: xpoint)
         }
         if let xpoint = dict[1] as? Double{
            self.x = xpoint
         }
        if let ypoint = dict[0] as? NSNumber{
           self.y = Double(truncating:ypoint)
        }
        if let ypoint = dict[0] as? Double{
           self.y = ypoint
        }
        
        if let score = dict[2] as? NSNumber{
           self.score = Double(truncating: score)
        }
        if let score = dict[2] as? Double{
           self.score = score
        }
      
         return self
      }
}




