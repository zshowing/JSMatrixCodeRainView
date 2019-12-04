//
//  JSMatrixCodeRainView.swift
//  matrixCodeRain
//
//  Created by Shuo Zhang on 2016/9/30.
//  Copyright © 2016年 Jon Showing. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
//import CoreMotion

fileprivate class PingThread: Thread{
    var pingTaskIsRunning = false
    var semaphore = DispatchSemaphore(value: 0)
    override func main(){
        while !self.isCancelled{
            pingTaskIsRunning = true
            DispatchQueue.main.async {
                self.pingTaskIsRunning = false
                self.semaphore.signal()
            }
            Thread.sleep(forTimeInterval: 1/30.0)
            if pingTaskIsRunning {
                NSLog("Delayed!")
            }
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
}

fileprivate struct JSMatrixConstants {
    static let maxGlowLength: Int = 3 // Characters
    static let minTrackLength: Int = 8 // Characters
    static let maxTrackLength: Int = 40 // Characters
    static let charactersSpacing: CGFloat = 0.0 // pixel
    static let characterChangeRate = 0.9
    static let firstDropShowTime = 2.0 // Time between the First drop and the later
    
    // Configurable
    static let speed: TimeInterval = 0.15 // Seconds that new character pop up
    static let newTrackComingLap: TimeInterval = 0.4
    static let tracksSpacing: Int = 5
}

fileprivate class JSMatrixTrack: Hashable, Equatable {
    var glowLength: Int
    var fadeLength: Int
    var totalLength: Int
    var positionY: Int{
        didSet{
            if positionY > totalLength {
                topY += (positionY - oldValue)
            }
        }
    }
    var trackNum: Int
    var positionX: CGFloat{
        return CGFloat(trackNum) * (JSMatrixDataSource.characterSize.width + 2.0)
    }
    var hashValue: Int{
        return trackNum
    }
    var topY: Int = 0
    weak var layer: JSMatrixTrackLayer?
    weak var datasource: JSMatrixDataSource?
    var timer: Timer?
    
    static func ==(lhs: JSMatrixTrack, rhs: JSMatrixTrack) -> Bool{
        return lhs.trackNum == rhs.trackNum
    }
    
    func getBrightness(currentTopY: Int, currentBottomY: Int) -> CGFloat{
        let index = currentBottomY - currentTopY - 1
        let rawData = 1 - CGFloat(index) / CGFloat(totalLength) // index = 0 is the brightest case
        if index < glowLength {
            return rawData * 1.2
        }else if index > totalLength - fadeLength{
            return rawData * 0.4
        }else{
            return rawData
        }
    }
    
    init(length: Int, trackNum _trackNum: Int) {
        self.positionY = 0
        self.totalLength = length
        self.trackNum = _trackNum
        
        glowLength = Int(arc4random_uniform(UInt32(min(JSMatrixConstants.maxGlowLength, length))))
        let fadeLengthRange = length - glowLength
        fadeLength = Int(arc4random_uniform(UInt32(fadeLengthRange)))
        
        timer = Timer.scheduledTimer(timeInterval: JSMatrixDataSource.sharedDataSource.speed, target: self, selector: #selector(self.drop), userInfo: nil, repeats: true)
    }
    
    @objc func drop(){
        self.positionY += 1
        if self.topY >= JSMatrixDataSource.maxNum{
            self.layer?.removeFromSuperlayer()
            timer?.invalidate()
        }else{
            self.layer?.drawAsync()
        }
    }
}

fileprivate class JSMatrixDataSource{
    static let sharedDataSource: JSMatrixDataSource = JSMatrixDataSource()
    
    static let trackNum: Int = Int(ceilf(Float(UIScreen.main.bounds.width / JSMatrixDataSource.characterSize.width)))
    static let maxNum: Int = Int(ceilf(Float(UIScreen.main.bounds.height / JSMatrixDataSource.characterSize.height)))
    
    static let characterSet = "abcdefghijklmnopqrstuvwxzyABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"
    static let characterSize = "T".size(withAttributes: convertToOptionalNSAttributedStringKeyDictionary(JSMatrixDataSource.getBrightnessAttributes(brightness: 1.0)))
    static func getCharacter() -> String{
        let randomNum = Int(arc4random_uniform(UInt32(characterSet.characters.count)))
        let randomIndex = characterSet.index(characterSet.startIndex, offsetBy: randomNum)
        return String(characterSet[randomIndex])
    }
    static func getBrightnessAttributes(brightness: CGFloat) -> [String: Any]{
        return [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.init(hue: 127.0/360.0, saturation: 97.0/100.0, brightness: brightness, alpha: 1.0),
                convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont(name: "Matrix Code NFI", size: 17)!,
                convertFromNSAttributedStringKey(NSAttributedString.Key.shadow): {
                    let shadow = NSShadow()
                    shadow.shadowBlurRadius = 2.0
                    shadow.shadowColor = UIColor.init(white: 1.0, alpha: brightness)
                    shadow.shadowOffset = CGSize.zero
                    return shadow
                    }()]
    }
    
    var characters: [[String]] = []
    var currentTracks: Set<JSMatrixTrack> = Set()
    
    var speed: TimeInterval = JSMatrixConstants.speed
    var newTrackComingLap: TimeInterval = JSMatrixConstants.newTrackComingLap
    var trackSpacing: Int = JSMatrixConstants.tracksSpacing
    
    init() {
        for _ in 0..<JSMatrixDataSource.trackNum{
            var track: [String] = []
            for _ in 0..<JSMatrixDataSource.maxNum{
                track.append(JSMatrixDataSource.getCharacter())
            }
            characters.append(track)
        }
        
        Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(self.changeCharacter), userInfo: nil, repeats: true)
    }
    
    public func addTrack(track: JSMatrixTrack){
        currentTracks.insert(track)
    }
    
    public func removeTrack(track: JSMatrixTrack){
        currentTracks.remove(track)
    }
    
    public func getAvailiableTracks() -> [Int]{
        var availiableTracks: [Int] = [Int](0...JSMatrixDataSource.trackNum)
        for track in currentTracks{
            if track.topY > JSMatrixDataSource.sharedDataSource.trackSpacing{ // All the track have been shown(and the gap is enough), new ones is free to go from above
                continue
            }else{
                availiableTracks = availiableTracks.filter({ (trackNum) -> Bool in
                    if trackNum == track.trackNum{
                        return false
                    }
                    return true
                })
            }
        }
        return availiableTracks
    }
    
    @objc func changeCharacter(){
        for track in 0..<JSMatrixDataSource.trackNum{
            if arc4random_uniform(10) < UInt32(JSMatrixConstants.characterChangeRate * 10){
                let randomNum = Int(arc4random_uniform(UInt32(JSMatrixDataSource.maxNum)))
                let randomIndex = characters.index(0, offsetBy: randomNum)
                characters[track][randomIndex] = JSMatrixDataSource.getCharacter()
            }
        }
    }
}

fileprivate protocol JSMatrixTrackGeneratorDataSource: class{
    func availiableTracks() -> [Int]
}
fileprivate protocol JSMatrixTrackGeneratorDelegate: class {
    func didGeneratedNewTrack(newTrack: JSMatrixTrack)
}

fileprivate class JSMatrixTrackGenerator{
    weak var delegate: JSMatrixTrackGeneratorDelegate?
    weak var datasource: JSMatrixTrackGeneratorDataSource?
    
    func getTrack() -> JSMatrixTrack{
        if let availableTracks = datasource?.availiableTracks(){
            let randomNum = Int(arc4random_uniform(UInt32(availableTracks.count - 1)))
            let track = JSMatrixTrack(length: Int(arc4random_uniform(UInt32(JSMatrixDataSource.maxNum - JSMatrixConstants.minTrackLength))) + JSMatrixConstants.minTrackLength,
                                      trackNum: availableTracks[randomNum])
            return track
        }else{
            return JSMatrixTrack(length: Int(arc4random_uniform(UInt32(JSMatrixDataSource.maxNum - JSMatrixConstants.minTrackLength))) + JSMatrixConstants.minTrackLength,
                                 trackNum: 0)
        }
    }
    
    func getTrack(trackNumber: Int) -> JSMatrixTrack {
        return JSMatrixTrack(length: Int(arc4random_uniform(UInt32(JSMatrixDataSource.maxNum - JSMatrixConstants.minTrackLength))) + JSMatrixConstants.minTrackLength,
                             trackNum: trackNumber)
    }
    
    func begin(){
        Timer.scheduledTimer(timeInterval: JSMatrixDataSource.sharedDataSource.newTrackComingLap, target: self, selector: #selector(self.produceTrack), userInfo: nil, repeats: true)
    }
    
    @objc func produceTrack(){
        self.delegate?.didGeneratedNewTrack(newTrack: self.getTrack())
    }
}

fileprivate class JSMatrixTrackLayer: CALayer {
    var track: JSMatrixTrack
    
    init(track _track: JSMatrixTrack) {
        track = _track
        
        super.init()
        
        self.contentsScale = UIScreen.main.scale
        
        self.drawsAsynchronously = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func drawAsync() {
        
        let track = self.track
        DispatchQueue.global().async {
            let size = self.bounds.size
            UIGraphicsBeginImageContext(size)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let createdContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            
            if let context = createdContext{
                context.saveGState()
                
                let positionY: Int = track.positionY
                var topY: Int = track.topY
                
                if let col = track.datasource?.characters[track.trackNum]{
                    var range = 0..<positionY // track have not fully shown
                    if positionY > track.totalLength {
                        if positionY < JSMatrixDataSource.maxNum{ // track have fully shown
                            range = topY..<min(topY + track.totalLength, JSMatrixDataSource.maxNum)
                        }else{ // track is truncted at bottom
                            range = topY..<JSMatrixDataSource.maxNum
                        }
                    }
                    for characterIndex in range{
                        let character = col[characterIndex]
                        
                        character.draw(in: CGRect(origin: CGPoint(x:0, y: CGFloat(topY) * JSMatrixDataSource.characterSize.height), size: JSMatrixDataSource.characterSize),
                                       withAttributes: convertToOptionalNSAttributedStringKeyDictionary(JSMatrixDataSource.getBrightnessAttributes(brightness: track.getBrightness(currentTopY: topY, currentBottomY: positionY))))
                        topY += 1
                    }
                }
                context.restoreGState()
                self.render(in: context)
                let resultImage = UIGraphicsGetImageFromCurrentImageContext();
                DispatchQueue.main.async {
                    if let image = resultImage{
                        self.contents = image.cgImage
                    }
                }
            }
            UIGraphicsEndImageContext()
        }
        
    }
}

class JSMatrixCodeRainView: UIView, JSMatrixTrackGeneratorDataSource, JSMatrixTrackGeneratorDelegate {
    fileprivate lazy var datasource: JSMatrixDataSource = JSMatrixDataSource.sharedDataSource
    fileprivate lazy var generator: JSMatrixTrackGenerator = {
        $0.delegate = self
        $0.datasource = self
        return $0
    }(JSMatrixTrackGenerator())
    fileprivate lazy var containerLayer: CALayer = {
        $0.frame = self.bounds//.insetBy(dx: -200, dy: -200)
        $0.zPosition = -CGFloat.greatestFiniteMagnitude + 1
        $0.drawsAsynchronously = true
        return $0
    }(CALayer())
//    fileprivate let pingThread = PingThread()
    
    @IBInspectable var speed: CGFloat = CGFloat(JSMatrixConstants.speed){
        didSet{
            datasource.speed = TimeInterval(speed)
        }
    }
    @IBInspectable var newTrackComingLap: CGFloat = CGFloat(JSMatrixConstants.newTrackComingLap){
        didSet{
            datasource.newTrackComingLap = TimeInterval(newTrackComingLap)
        }
    }
    @IBInspectable var trackSpacing: Int = JSMatrixConstants.tracksSpacing{
        didSet{
            datasource.trackSpacing = trackSpacing
        }
    }
    
//    lazy var displayLink: CADisplayLink = CADisplayLink(target: self, selector: #selector(self.update))
    
//    lazy var motionManager = CMMotionManager()
//    var originRad: CGFloat?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.black
        self.layer.addSublayer(containerLayer)
        
//        pingThread.start()
        
//        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
//        
//        if motionManager.isDeviceMotionAvailable{
//            motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryZVertical)
//        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.backgroundColor = UIColor.black
        self.layer.addSublayer(containerLayer)
        
//        pingThread.start()
        
//        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        
//        if motionManager.isDeviceMotionAvailable{
//            motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryZVertical)
//        }
    }
    
//    @objc func update(){
//        if let quat = motionManager.deviceMotion?.attitude.quaternion{
//            let realRoll = atan2(2 * (quat.x * quat.y + quat.z * quat.w), 1 - 2 * (pow(quat.y, 2.0) + pow(quat.z, 2.0)))
//            //            let realPitch = atan2(2 * (quat.x * quat.w + quat.y * quat.z), 1 - 2 * (pow(quat.z, 2.0) + pow(quat.w, 2.0)))
//            //            if originRad == nil{
//            //                originRad = CGFloat(realPitch)
//            //            }
//            
//            var rollTransform = CATransform3DIdentity
//            rollTransform.m43 = (-1) / 500
//            rollTransform = CATransform3DRotate(rollTransform, CGFloat(realRoll), 0, 1, 0)
//            //            var pitchTransform = CATransform3DIdentity
//            //            pitchTransform.m43 = (-1) / 500
//            //            pitchTransform = CATransform3DRotate(pitchTransform, originRad! - CGFloat(realPitch), 1, 0, 0)
//            //            let concatTransform = CATransform3DConcat(rollTransform, pitchTransform)
//            self.containerLayer.transform = rollTransform
//        }
//    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        let track = generator.getTrack(trackNumber: JSMatrixDataSource.trackNum / 2)
        self.didGeneratedNewTrack(newTrack: track)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + JSMatrixConstants.firstDropShowTime) {
            self.generator.begin()
        }
    }
    
    fileprivate func availiableTracks() -> [Int] {
        return datasource.getAvailiableTracks()
    }
    
    fileprivate func didGeneratedNewTrack(newTrack: JSMatrixTrack) {
        newTrack.datasource = datasource
        datasource.addTrack(track: newTrack)
        let layer = JSMatrixTrackLayer(track: newTrack)
        layer.frame = CGRect(origin: CGPoint(x: newTrack.positionX, y: 0),
                             size: CGSize(width: JSMatrixDataSource.characterSize.width, height: UIScreen.main.bounds.height))
        containerLayer.addSublayer(layer)
        layer.drawAsync()
        newTrack.layer = layer
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
