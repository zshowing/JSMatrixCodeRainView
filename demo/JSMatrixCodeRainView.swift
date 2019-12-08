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

fileprivate struct JSMatrixConstants {
    static let maxGlowLength: Int = 3 // Characters
    static let minTrackLength: Int = 8 // Characters
    static let maxTrackLength: Int = 40 // Characters
    static let charactersSpacing: CGFloat = 0.0 // pixel
    static let characterChangeRate = 0.9
    static let firstDropShowTime = 1.0 // Time between the First drop and the later
    
    // Configurable
    static let speed: TimeInterval = 0.1 // Seconds that new character pop up
    static let newTrackComingLap: TimeInterval = 3
    static let tracksSpacing: Int = 5
}

fileprivate class JSMatrixTrack {
    var glowLength: Int = 0
    var fadeLength: Int = 0
    var totalLength: Int{
        didSet{
            self.glowLength = Int(arc4random_uniform(UInt32(min(JSMatrixConstants.maxGlowLength, totalLength))))
            let fadeLengthRange = totalLength - glowLength
            self.fadeLength = Int(arc4random_uniform(UInt32(fadeLengthRange)))
        }
    }
    var layer: JSMatrixTrackLayer
    var characters: [String]
    
    func setupPulse(length: Int) {
        self.layer.setupPulse(length: self.totalLength, fadeLength: self.fadeLength)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(JSMatrixDataSource.maxNum + length) * JSMatrixDataSource.sharedDataSource.speed + Double(arc4random_uniform(UInt32(JSMatrixConstants.newTrackComingLap))) , execute: {
            self.totalLength = Int(arc4random_uniform(UInt32(JSMatrixDataSource.maxNum - JSMatrixConstants.minTrackLength))) + JSMatrixConstants.minTrackLength
            self.setupPulse(length: self.totalLength)
        })
    }
    
    @objc func changeCharacter(){
        if arc4random_uniform(10) < UInt32(JSMatrixConstants.characterChangeRate * 10){
            let randomIndex = Int(arc4random_uniform(UInt32(self.characters.count)))
            self.layer.updateCharacter(JSMatrixDataSource.getCharacter(), atIndex: randomIndex)
        }
    }
    
    init(layer _layer: JSMatrixTrackLayer, length _length: Int, characters _characters: [String]) {
        self.layer = _layer
        self.characters = _characters
        self.totalLength = _length
        
        Timer.scheduledTimer(timeInterval: 0.5, target: self,
                             selector: #selector(self.changeCharacter),
                             userInfo: nil, repeats: true)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + JSMatrixConstants.firstDropShowTime + Double(arc4random_uniform(UInt32(JSMatrixDataSource.trackNum))) + Double(arc4random_uniform(UInt32(JSMatrixDataSource.sharedDataSource.newTrackComingLap)))) {
            self.setupPulse(length: self.totalLength)
        }
    }
}

fileprivate class JSMatrixDataSource{
    static let sharedDataSource: JSMatrixDataSource = JSMatrixDataSource()
    
    /// Max track number
    static let trackNum: Int = Int(ceilf(Float(UIScreen.main.bounds.width / JSMatrixDataSource.characterSize.width)))
    
    /// Max character number vertically
    static let maxNum: Int = Int(ceilf(Float(UIScreen.main.bounds.height / JSMatrixDataSource.characterSize.height)))
    
    /// Character set.
    private static let characterSet = "abcdefghijklmnopqrstuvwxzyABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"
    
    /// Character size.
    static let characterSize = "T".size(withAttributes: JSMatrixDataSource.getBrightnessAttributes(brightness: 1.0))
    
    /// Get One character.
    static func getCharacter() -> String{
        let randomNum = Int(arc4random_uniform(UInt32(characterSet.count)))
        let randomIndex = characterSet.index(characterSet.startIndex, offsetBy: randomNum)
        return String(characterSet[randomIndex])
    }
    
    /// Get characters for the given length.
    static func getCharacter(length: Int) -> [String]{
        var charArray: [String] = []
        for _ in 0..<length {
            charArray.append(getCharacter())
        }
        return charArray
    }
    
    /// A wrapper for the NSAttributedString attributes.
    static func getBrightnessAttributes(brightness: CGFloat) -> [NSAttributedString.Key: Any]{
        return [NSAttributedString.Key.foregroundColor: UIColor.init(hue: 127.0/360.0, saturation: 97.0/100.0, brightness: brightness, alpha: 1.0),
                NSAttributedString.Key.font: UIFont(name: "Matrix Code NFI", size: 17)!,
                NSAttributedString.Key.shadow: {
                    let shadow = NSShadow()
                    shadow.shadowBlurRadius = 2.0
                    shadow.shadowColor = UIColor.init(white: 1.0, alpha: brightness)
                    shadow.shadowOffset = CGSize.zero
                    return shadow
                    }()]
    }
    
    var characters: [[String]] = []
    var tracks: [JSMatrixTrack] = []
    
    var speed: TimeInterval = JSMatrixConstants.speed
    var newTrackComingLap: TimeInterval = JSMatrixConstants.newTrackComingLap
    var trackSpacing: Int = JSMatrixConstants.tracksSpacing
    
    func addTrack(track: JSMatrixTrack) {
        tracks.append(track)
    }
    
    init() {
        for _ in 0..<(JSMatrixDataSource.trackNum + 1){
            var track: [String] = []
            for _ in 0..<JSMatrixDataSource.maxNum{
                track.append(JSMatrixDataSource.getCharacter())
            }
            characters.append(track)
        }
        
        Timer.scheduledTimer(timeInterval: 0.02, target: self,
                             selector: #selector(self.changeCharacter),
                             userInfo: nil, repeats: true)
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

fileprivate class JSMatrixTrackLayer: CALayer {
    var trackNum: Int
    lazy var layers: Array<CATextLayer> = []
    
    required init(trackNum _trackNum: Int) {
        self.trackNum = _trackNum
        
        super.init()
        
        self.frame = CGRect(origin: CGPoint(x: CGFloat(_trackNum) * (JSMatrixDataSource.characterSize.width + 2.0), y: 0),
                            size: CGSize(width: JSMatrixDataSource.characterSize.width, height: UIScreen.main.bounds.height))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCharacters(characters: [String]) {
        for i in 0..<characters.count{
            let layer = CATextLayer()
            let attrString = NSAttributedString(string: characters[i],
                                                attributes: JSMatrixDataSource.getBrightnessAttributes(brightness: 1))
            layer.string = attrString
            layer.frame = CGRect(origin: CGPoint(x: 0, y: CGFloat(i) * JSMatrixDataSource.characterSize.height),
                                 size: CGSize(width: self.frame.size.width,
                                              height: JSMatrixDataSource.characterSize.height))
            layer.opacity = 0
            self.layers.append(layer)
            self.addSublayer(layer)
        }
    }
    
    func updateCharacter(_ character: String, atIndex index: Int) {
        let layer = self.layers[index]
        layer.string = NSAttributedString(string: character,
                                          attributes: JSMatrixDataSource.getBrightnessAttributes(brightness: 1))
    }
    
    func setupPulse(length: Int, fadeLength: Int) {
        // length = duration / speed -> duration = length * speed
        for (index, layer) in layers.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * JSMatrixDataSource.sharedDataSource.speed) {
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.duration = Double(length) * JSMatrixDataSource.sharedDataSource.speed
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.fromValue = 1
                animation.toValue = 0
                animation.beginTime = CACurrentMediaTime()
                animation.isRemovedOnCompletion = false
                layer.add(animation, forKey: "opacity")
            }
        }
    }
}

class JSMatrixCodeRainView: UIView {
    fileprivate lazy var datasource: JSMatrixDataSource = JSMatrixDataSource.sharedDataSource
    
    fileprivate lazy var containerLayer: CALayer = {
        $0.frame = self.bounds//.insetBy(dx: -200, dy: -200)
        return $0
    }(CALayer())
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.black
        self.layer.addSublayer(containerLayer)
        self.fillTracks()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.backgroundColor = UIColor.black
        self.layer.addSublayer(containerLayer)
        self.fillTracks()
    }
    
    func fillTracks() {
        for i in 0..<JSMatrixDataSource.trackNum{
            let layer = JSMatrixTrackLayer(trackNum: i)
            let characters = JSMatrixDataSource.getCharacter(length: JSMatrixDataSource.maxNum)
            layer.setupCharacters(characters: characters)
            containerLayer.addSublayer(layer)
            let newTrack = JSMatrixTrack(layer: layer,
                                         length: Int(arc4random_uniform(UInt32(JSMatrixDataSource.maxNum - JSMatrixConstants.minTrackLength))) + JSMatrixConstants.minTrackLength,
                                         characters: characters)
            JSMatrixDataSource.sharedDataSource.addTrack(track: newTrack)
        }
    }
    
}
