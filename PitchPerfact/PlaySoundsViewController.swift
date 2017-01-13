//
//  PlaySoundsViewController.swift
//  PitchPerfact
//
//  Created by 김필환 on 2017. 1. 3..
//  Copyright © 2017년 김필환. All rights reserved.
//

import UIKit
import AVFoundation

class PlaySoundsViewController: UIViewController {
    
    @IBOutlet weak var snailButton: UIButton!
    @IBOutlet weak var chipmunkButton: UIButton!
    @IBOutlet weak var rabbitButton: UIButton!
    @IBOutlet weak var vaderButton: UIButton!
    @IBOutlet weak var echoButton: UIButton!
    @IBOutlet weak var reverbButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    var recordedAudioURL: URL!

    var audioFile:AVAudioFile!
    var audioEngine:AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    var stopTimer: Timer!
    var updateTimer: Timer!
    
    var rate:Float!
    var resumeTime:Float = 0
    var currentButtonType:ButtonType!
    
    enum ButtonType: Int {
        case slow = 0, fast, chipmunk, vader, echo, reverb
    }
    
    override func viewWillAppear(_ animated: Bool) {
        configureUI(.notPlaying)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudio()
    }

    
    // MARK: Actions
    
    @IBAction func playSoundForButton(_ sender: UIButton) {
        self.rate = nil
        currentButtonType = ButtonType(rawValue: sender.tag)!
        playSounds(buttonType: currentButtonType)
    }
    
    func playSounds(buttonType : ButtonType) {
        self.rate = nil
        switch(buttonType) {
        case .slow:
            self.rate=0.5
            playSound(rate: rate)
        case .fast:
            self.rate=1.5
            playSound(rate: rate)
        case .chipmunk:
            playSound(pitch: 1000)
        case .vader:
            playSound(pitch: -1000)
        case .echo:
            playSound(echo: true)
        case .reverb:
            playSound(reverb: true)
        }
        
        configureUI(.playing, rate: rate)
    }
    
    @IBAction func stopButtonPressed(_ sender: AnyObject) {
        stopAudio()
    }
    
    @IBAction func pause(_ sender: Any) {
        if let thePlayerNode: AVAudioPlayerNode = audioPlayerNode {
            if thePlayerNode.isPlaying {
                pauseAudio()
            } else {
                resumeTime = slider.value
                playSounds(buttonType: currentButtonType)
            }
        }
    }
    @IBAction func moveSoundTime(_ sender: UISlider) {
        let sliderValue = sender.value
        currentTimeLabel.text = "\(sliderValue)"
    }
    

}
