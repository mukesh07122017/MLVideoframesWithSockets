//
//  SocketClient.swift
//  MLSocketSDK
//
//  Created by Mahi Sharma on 06/11/21.
//

import Foundation
import Starscream
import SwiftProtobuf

/// Errors thrown by the client.
public enum ClientError: Error {
    case invalidURI
    case abnormalClosure
    case streamError
    case decodeError
    case unexpectedError(localizedDescription: String)
    case invalidArgument(reason: String)
}

/// The different type of movement analyses that can be performed by the API. Almost always KeyType.movement.
public enum KeyType {
    /// Key type for movement compounds.
    case exercise

    // Key type for a movement.
    case movement

    // Key type for a phase, a "subunit" of a movement.
    case phase

    // Key type for when no analysis is desired and just the inferred key points should be returned.
    case no
}

struct imageData: Codable {
    var payload: Data
    var height: Int
    var width: Int
    var exerciseID: String
    var prev_Angle: Int
    var stage: String
    var reps: Int
    var pTime: Double
}

open class SocketClient {
    internal var socket: WebSocket!
    internal var server = WebSocketServer()
    private let imageSizeMax = 15*1024

    
    
    /**
        A closure that is called when the client is closed. It receives the
        current client instance, the reason for the closure as a string and the
        closure code.
     */
    
      public var onClose: ((SocketClient) -> Void)?
    /**
        A closure that is called when an error occurs in the transmission.
        It receives the current client instance and the error that occurred.
    */
    public var onError: ((SocketClient,[String:AnyObject]) -> Void)?
    /**
        A closure that is called when an error response is received from the
        server. It receives the current client instance and the error response
        that was received.
    */
    public var onErrorResponse: ((SocketClient) -> Void)?
  
    /**
        A closure that is called when a new ImageResponse is received.
        The closure receives the current client instance and the message.
    */
    
    public var onImageResponse: ((SocketClient, FrameMetaData) -> Void)?
    
    /**
        A closure that is called when a new MetadataResponse is received.
        The closure receives the current client instance and the message.
    */
    public var onMetadataResponse: ((SocketClient, [String:AnyObject]) -> Void)?
    /**
        A closure that is called when a repetition is completed.
        The closure receives the current client instance and a repetition
        message containing the list of mistakes made during the repetition.
    */
    public var onRepetition: ((SocketClient, [String:AnyObject]) -> Void)?

    /// A closure that is called when the client is connected (ready).
    public var onReady: ((SocketClient) -> Void)?
    
    
    /// Public property that states whether the client is connected or not.
    public private(set) var isConnected: Bool = false
    
    public private(set) var isAuthenticate: Bool = false
    
    

    public init(uri: URL) throws {
        var request = URLRequest(url: uri)
        request.timeoutInterval = 40
        self.socket = WebSocket(request: request)
        self.socket.onEvent = self.onSocketEvent

        
    }
    /**
        Connects the client to the  API.
     */
    public func connect() {
        self.socket.connect()
    }
    
    public func Disconnect() {
        self.socket.disconnect()
    }
   
    
    /**
    Handler for all websocket events.

    - Parameters:
        - event: The event that occured.
    */
    internal func onSocketEvent(event: WebSocketEvent) {
        switch event {
        case .binary( _):
           // print("hfhfhfhfh1111111")
            break
        case .text(let data):
            self.onMessageHandler(datastring: data)
            break
        case .reconnectSuggested( _):
            break
        case .connected(_):
            self.onReady?(self)
            self.isConnected = true
            break
        case .disconnected(let reason, let code):
            isConnected = false
           // print("websocket is disconnected: \(reason) with code: \(code)")
            //print("hfhfhfhfh")
            self.onClose?(self)
            self.isConnected = false
            break
        case .error(let error):
            
            print(error.debugDescription)
           // print("gcgccgcgcg\(String(describing: error))")
            self.isConnected = false
            let dic = ["error": "Connection reset by peer"] as [String:AnyObject]
            self.onError?(self, dic)
            break
        default:
            break
        }
    }

  
    
    
    private func onMessageHandler(datastring: String) {
        
       // print("json ====>\(datastring)") // use the json here
       
        let data = datastring.data(using: .utf8)!
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as?  [String:AnyObject]
            {
                let dic = jsonArray as [String:AnyObject]
                if (dic["status"] as? String == "connected") {
                    self.isConnected = true
                    self.onMetadataResponse?(self, dic)
                }
                else if (dic["status"] as? String == "Excercise id not exists") {
                    self.isAuthenticate = false
                    let dic = ["error": "Excercise id not exists"] as [String:AnyObject]
                      self.onError?(self, dic)
                }
                else if (dic["status"] as? Int == 1) {
                    self.isAuthenticate = true
                    self.isConnected = true
                    var objMeetingInfoModel = FrameMetaData()
                    print(">>>> Response dict \(dic)")
                    objMeetingInfoModel = objMeetingInfoModel.getFrameMetaDataWith(dict: dic )
                    self.onImageResponse?(
                        self, objMeetingInfoModel)
                }
                else if (dic["status"] as? NSNumber == 1) {
                    self.isAuthenticate = true
                    print(">>>> Response dict \(dic)")
                    var objMeetingInfoModel = FrameMetaData()
                    objMeetingInfoModel = objMeetingInfoModel.getFrameMetaDataWith(dict: dic )
                    self.onImageResponse?(
                        self, objMeetingInfoModel)
                    
                }
                else{
                   // print("jgjgjgjgjgjjgjbad json")
                    self.isAuthenticate = false
                }
            }
            else {
                print("bad json")
            }
        } catch let error as NSError {
            print("bad json")
            print(error)
        }

    }
    
    

   

    /**
    Sends an image to the  API endpoint.
    - Parameter image: The image as data.
    - Remark: Note that the underlying buffer must contain the image data in JPEG format.
    */
    public func sendImage(image: Data,height:Int, width:Int,prevAngle:Int, exerciseID:String,stage:String,reps:Int,pTime : Double) throws {
        if (image.count > imageSizeMax) {
            throw ClientError.invalidArgument(reason: "Image data larger than 15kB!")
        }
            let imgData = imageData(
                payload: image, height: height, width: width, exerciseID: exerciseID, prev_Angle: prevAngle, stage: stage, reps: reps, pTime: pTime
            )
            let encoder = JSONEncoder()
            if let jsonData = try? encoder.encode(imgData) {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                   // print(jsonString)
                    self.socket.write(string: jsonString)
                }
            }
        
       
        
    }

    /**
    Sends an image to the  API endpoint.

    - Parameter image: The image as UInt8 array.
    - Remark: Note that the image data needs to be in JPEG format.
    */
    public func sendImage(image: [UInt8],height:Int, width:Int,prevAngle:Int, exerciseID:String, stage:String,reps:Int, pTime : Double) throws {
        
        try sendImage(image: image.data, height: height, width: width, prevAngle: prevAngle, exerciseID: exerciseID, stage: stage, reps: reps, pTime: pTime)
        
        
        //try sendImage(image: image.data)
    }

    /**
        Closes the client and the underlying socket.
    */
    public func close() {
        self.socket.disconnect(closeCode: 1000)
    }

    /**
    Creates connected input and output streams
    */
    private func createStreams() throws -> (InputStream, OutputStream) {
        var inputOrNil: InputStream? = nil
        var outputOrNil: OutputStream? = nil
        Stream.getBoundStreams(withBufferSize: imageSizeMax, inputStream: &inputOrNil, outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            throw ClientError.streamError
        }
        return (input, output)
    }
    
}



/// Private extensions to the Data structure for convenience.
private extension Data {
    // Interpret data as an array of bytes..
    var bytes: [UInt8] {
        return [UInt8](self)
    }

    // Convenience constructor that allows the creation of a Data object
    // from a stream.
    init(reading input: InputStream) throws {
        self.init()
        input.open()
        defer {
            input.close()
        }

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if read < 0 {
                //Stream error occured
                throw input.streamError!
            } else if read == 0 {
                //EOF
                break
            }
            self.append(buffer, count: read)
        }
    }
}

/// Private extension to UInt8 arrays
private extension Array where Element == UInt8 {
    // Interpret an array of bytes as a Data object.
    var data: Data {
        return Data(self)
    }
}
