//
//  ViewController.swift
//  BoseTest
//
//  Created by Carl Ekman on 2019-09-08.
//  Copyright © 2019 TrySwift. All rights reserved.
//

import UIKit
import BoseWearable
import AVFoundation

class DeviceViewController: UIViewController {

    var token: ListenerToken?
    private let sensorDispatch = SensorDispatch(queue: .main)

    var session: WearableDeviceSession! {
        didSet {
            session?.delegate = self
        }
    }

    // AV AUDIO SESSION ********* ********* ********* ********* *********
    private var audioEngine = AVAudioEngine()
    private var audioEnvironment = AVAudioEnvironmentNode()
    private var audioPlayer = AVAudioPlayerNode()

    // Constants
    struct Constants {
        static let AUDIO_FILE_NAME      = "scat-song"
        static let AUDIO_FILE_NAME_EXT  = "m4a"
    }

    @IBOutlet weak var buttonText: UIButton!
    @IBOutlet weak var yawText: UILabel!
    @IBOutlet weak var pitchText: UILabel!
    private var yawOffset: Double?


    override func viewDidLoad() {
        super.viewDidLoad()
        sensorDispatch.handler = self
        setupAudioEnvironment()
        setupNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        configureSensors()
        configureGestures()
        listenForWearableEvents()
    }

    func configureSensors() {
        session.device?.configureSensors { config in
            config.disableAll()
            config.enable(sensor: .gameRotation, at: ._20ms)
        }
    }

    func configureGestures() {
        session.device?.configureGestures { config in
            config.enableAll()
        }
    }

    func listenForWearableEvents(){
        token = session.device?.addEventListener(queue: .main) { [weak self] event in
            self?.wearableDeviceEvent(event)
        }
    }

    // sensor wearable device event
    func wearableDeviceEvent(_ event: WearableDeviceEvent) {
        switch event {
        case .didResumeWearableSensorService:
            print("did resume sensor service")
        case .didFailToWriteSensorConfiguration(let error):
            print("did fail to write sensor config", error)
        case .didReceiveSensorData(let data):
            print("did receive sensor data", data )
        default:
            break
        }
    }

    @IBAction func startStopPlayerPressed(_ sender: Any) {
        toggleAudio()
    }

    func toggleAudio() {
        if !audioPlayer.isPlaying {
            startPlaying()

        } else {
            stopPlaying()
        }
    }

    func setupAudioEnvironment() {
        // Configure the audio session
        let avSession = AVAudioSession.sharedInstance()
        do {

            try avSession.setCategory(AVAudioSession.Category.playback, options: [.mixWithOthers] )

        } catch let error as NSError {
            print("Error setting AVAudioSession category: \(error.localizedDescription)\n")
        }

        // Configure audio buffer sizes
        let bufferDuration: TimeInterval = 0.005; // 5ms buffer duration
        try? avSession.setPreferredIOBufferDuration(bufferDuration)

        let desiredNumChannels = 2
        if avSession.maximumOutputNumberOfChannels >= desiredNumChannels {
            do {
                try avSession.setPreferredOutputNumberOfChannels(desiredNumChannels)
            } catch let error as NSError {
                print("Error setting PreferredOuputNumberOfChannels: \(error.localizedDescription)")
            }
        }
        do {
            try avSession.setActive(true)
        } catch let error as NSError {
            print("Error setting session active: \(error.localizedDescription)\n")
        }

        // Configure the audio environment, initialize the listener to start at 0, facing front.
        audioEnvironment.listenerPosition  = AVAudioMake3DPoint(0, 0, 0)
        audioEnvironment.listenerAngularOrientation = AVAudioMake3DAngularOrientation(0.0, 0.0, -5.0)
        audioEngine.attach(audioEnvironment)

        // Configure the audio engine
        let hardwareSampleRate = audioEngine.outputNode.outputFormat(forBus: 0).sampleRate
        guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareSampleRate, channels: 2) else { return }
        audioEngine.connect(audioEnvironment, to: audioEngine.outputNode, format: audioFormat)
        audioEnvironment.renderingAlgorithm = .HRTFHQ


        // Configure the audio player
        audioEngine.attach(audioPlayer)
        audioPlayer.position = AVAudio3DPoint(x: 0.0, y: 0.0, z: -5.0)
        if let audioFileURL = Bundle.main.url(forResource: Constants.AUDIO_FILE_NAME, withExtension: Constants.AUDIO_FILE_NAME_EXT) {
            do {
                // Open the audio file
                let audioFile = try AVAudioFile(forReading: audioFileURL, commonFormat: AVAudioCommonFormat.pcmFormatFloat32, interleaved: false)

                // Loop the audio playback upon completion - reschedule the same file
                func loopCompletionHandler() {
                    audioPlayer.scheduleFile(audioFile, at: nil, completionHandler: loopCompletionHandler)
                }

                audioEngine.connect(audioPlayer, to: audioEnvironment, format: audioFile.processingFormat)

                // Schedule the file for playback, see 'scheduleBuffer' for sceduling indivdual AVAudioBuffer/AVAudioPCMBuffer
                audioPlayer.scheduleFile(audioFile, at: nil, completionHandler: loopCompletionHandler)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }

    //  Setup notifications for AVAudioSession events
    func setupNotifications() {
        // Interruption handler
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)

        // Route change handler
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)

        // Media services reset handler
        NotificationCenter.default.addObserver(self, selector: #selector(handleMediaServicesReset), name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
    }

    // Handle an audio device interruption (i.e. phone call, music playing, etc...)
    @objc func handleInterruption(notification: Notification) {
        print("handle interruption notification audio/phonecall")
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        if type == .began {
            // Interruption began, take appropriate actions
            stopPlaying()
            print("Audio playback interrupted")
        }
        else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    startPlaying()
                    print("Audio playback resumed")
                } else {
                    stopPlaying()
                    print("Audio playback stopped")
                }
            }
        }
    }

    // Handle a audio route change
    @objc func handleRouteChange(notification: Notification) {
        print("Audio route changed")
    }

    @objc private func handleMediaServicesReset(_ notification: NSNotification) {
        // setupAudioEnvironment()
        stopPlaying()
        print("Media services have been reset")
    }

    // Stop playing
    func stopPlaying() {
        if(audioEngine.isRunning || audioPlayer.isPlaying) {
            audioEngine.stop()
            audioPlayer.stop()
        }
        DispatchQueue.main.async {
            self.buttonText.setTitle("Start Playing", for: .normal)
        }
    }

    // Start playing
    func startPlaying() {
        do {
            // Reset the current head direction
            yawOffset = nil
            try audioEngine.start()
            audioPlayer.play()
        } catch {
            print("this is an error with start playing", error)
        }

        DispatchQueue.main.async {
            self.buttonText.setTitle("Stop Playing", for: .normal)
        }
    }
}

//Mark: WearableDeviceSessionDelegate
extension DeviceViewController: WearableDeviceSessionDelegate {
    func sessionDidOpen(_ session: WearableDeviceSession) {
        // put something
    }

    func session(_ session: WearableDeviceSession, didCloseWithError error: Error?) {
        print(error!, "error did close with error")
    }

    func session(_ session: WearableDeviceSession, didFailToOpenWithError error: Error?) {
        print(error!, "did fail to open with error")
    }
}

//Mark: SensorDispatchHandler
extension DeviceViewController: SensorDispatchHandler {
    func receivedGameRotation(quaternion: Quaternion, timestamp: SensorTimestamp) {
        print(yawOffset as Any, "this is yawoffset")

        //   rad -> deg
        func degrees(fromRadians radians: Double) -> Double {
            return radians * 180.0 / .pi
        }

        // If needed, use the current yaw as the offset so the sound direction is directly in front
        if yawOffset == nil {
            yawOffset = degrees(fromRadians: quaternion.zRotation)
        }
        var yaw = Float(degrees(fromRadians: quaternion.zRotation) - yawOffset!)

        //Wrap around whatever the offset could have done, to bring the angle back in range.
        while yaw < -180.0 {
            yaw += 360.0
        }

        while yaw > 180 {
            yaw -= 360
        }

        let pitch = Float(degrees(fromRadians: quaternion.xRotation))
        let roll = Float(degrees(fromRadians: quaternion.yRotation))

        yawText.text = "Yaw: \(Int(yaw))"
//        pitchText.text = "Pitch: \(Int(pitch))"

        // Update the listerner position in space
        audioEnvironment.listenerAngularOrientation = AVAudioMake3DAngularOrientation(yaw, pitch, roll)

        let foo = min(abs(min((pitch - 100), 70) / 70), 1)
        pitchText.text = "Volume: \(foo)"
        audioPlayer.volume = foo
    }

    func receivedGesture(type: GestureType, timestamp: SensorTimestamp) {
        if type == .input {
            toggleAudio()
        }
    }
}
