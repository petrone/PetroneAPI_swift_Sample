//
//  ViewController.swift
//  test2
//
//  Created by Byrobot on 2017. 8. 10..
//  Copyright © 2017년 Byrobot. All rights reserved.
//

import UIKit
import PetroneAPI

class ViewController: UIViewController, JoypadProtocol, PetroneProtocol {
    @IBOutlet weak var btnScan: UIButton?
    @IBOutlet weak var btnCommand: UIButton?
    @IBOutlet weak var btnEmergency: UIButton?
    @IBOutlet weak var txtPosition: UILabel?
    @IBOutlet weak var viewPetroneMode: UIView?
    @IBOutlet weak var activityScan: UIActivityIndicatorView?
    
    var timer = Timer()
    var arrayBLE: Array<UIButton> = Array<UIButton>()
    var isScanning: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Petrone.instance.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onCommand() {
        if Petrone.instance.isReadyForStart() {
            Petrone.instance.takeOff()
        } else {
            Petrone.instance.landing()
        }
    }
    
    @IBAction func onSelectMode(sender: AnyObject) {
        switch sender.tag! {
        case 1:
            Petrone.instance.changeMode(mode: PetroneMode.Flight)
            self.btnCommand?.isHidden = false
            self.btnEmergency?.isHidden = false
        case 2:
            Petrone.instance.changeMode(mode: PetroneMode.FlightNoGuard)
            self.btnCommand?.isHidden = false
            self.btnEmergency?.isHidden = false
        default:
            Petrone.instance.changeMode(mode: PetroneMode.Drive)
        }
        
        
        let padleft : Joypad = Joypad(frame:CGRect(x:1, y:self.view.frame.size.height-210, width:200, height:200))
        padleft.delegate = self
        padleft.tag = 1
        let padright : Joypad = Joypad(frame:CGRect(x:self.view.frame.size.width-210, y:self.view.frame.size.height-210, width:200, height:200))
        padright.delegate = self
        padright.tag = 2
        self.view.addSubview(padleft)
        self.view.addSubview(padright)
        
        txtPosition?.text = "\(positionLeft.x),\(positionLeft.y) | \(positionRight.x),\(positionRight.y)"
        
        self.viewPetroneMode?.isHidden = true
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self,   selector: (#selector(ViewController.updateControl)), userInfo: nil, repeats: true)
    }
    
    @IBAction func onEmergency() {
        Petrone.instance.emergencyStop()
    }
    
    @IBAction func onStartBLE() {
        if !isScanning {
            activityScan?.startAnimating()
            btnScan?.setTitle("Stop", for: UIControlState.normal)
            Petrone.instance.onScan()
            runTimer()
            isScanning = true
        } else {
            activityScan?.stopAnimating()
            btnScan?.setTitle("Scan", for: UIControlState.normal)
            Petrone.instance.onStopScan()
            if self.timer != nil {
                self.timer.invalidate()
            }
            
            self.arrayBLE.forEach { (droneButton) in
                droneButton.removeFromSuperview()
            }
            
            self.arrayBLE.removeAll()
            
            isScanning = false
        }
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(ViewController.updateScan)), userInfo: nil, repeats: true)
    }
    
    @objc func updateControl() {
        DispatchQueue.main.async {
            if( Petrone.instance.isPairing ) {
                self.frameCounter += 1
                
                if self.frameCounter % 10 == 0 {
                    Petrone.instance.requestState()
                    self.frameCounter = 0
                }
                
                if Petrone.instance.status != nil {
                    switch (Petrone.instance.status?.mode)! {
                    case PetroneMode.Flight, PetroneMode.FlightNoGuard, PetroneMode.FlightFPV :
                        Petrone.instance.control(throttle: Int8(self.positionLeft.y), yaw: Int8(self.positionLeft.x), roll: Int8(self.positionRight.x), pitch: Int8(self.positionRight.y))
                    default:
                        Petrone.instance.control(forward: Int8(self.positionLeft.y), leftRight: Int8(self.positionRight.x))
                    }
                }
            }
        }
    }
    
    @objc func updateScan() {
        var count:Int = 0
        
        Petrone.instance.petroneList.forEach { (petronInfo) in
            if (count + 1) > arrayBLE.count {
                let newButton = UIButton(type: UIButtonType.custom)
                newButton.frame = CGRect(x: self.view.frame.size.width/2-100, y:CGFloat(100+count*35), width: 200, height: 30 )
                newButton.setBackgroundImage(UIImage(named:"button_white"), for: UIControlState.normal)
                newButton.setTitleColor(UIColor.black, for: UIControlState.normal)
                newButton.setTitle(String(format: "%@ %d", petronInfo.value.name!, petronInfo.value.rssi.intValue), for: UIControlState.normal)
                newButton.tag = count
                newButton.addTarget(self, action: #selector(pressConnect(sender:)), for: UIControlEvents.touchUpInside)
                self.view.addSubview(newButton)
                arrayBLE.insert(newButton, at: count)
            } else {
                let buttonButton = arrayBLE[count]
                buttonButton.setTitle(String(format: "%@ %d", petronInfo.value.name!, petronInfo.value.rssi.intValue), for: UIControlState.normal)
            }
            
            count += 1
        }
    }
    
    @objc func pressConnect(sender: UIButton!) {
        var count:Int = 0
        Petrone.instance.petroneList.forEach { (petronInfo) in
            if count == sender.tag {
                Petrone.instance.onConnect( petronInfo.value.uuid! )
            }
            
            count += 1
        }
    }
    
    var positionLeft:CGPoint = CGPoint.zero
    var positionRight:CGPoint = CGPoint.zero
    
    func control(_ joypad: Joypad, update position: CGPoint) {
        switch joypad.tag {
        case 1:
            self.positionLeft = position
        case 2:
            self.positionRight = position
        default:
            NSLog("Unknown controller")
        }
        
        txtPosition?.text = "\(positionLeft.x),\(positionLeft.y) | \(positionRight.x),\(positionRight.y)"
    }
    
    var frameCounter:UInt8 = 0
    
    func petrone(_ petroneController: PetroneController, didConnect complete: String) {
        timer.invalidate()
        
        Petrone.instance.requestState()
        
        self.activityScan?.stopAnimating()
        self.btnScan?.setTitle("Scan", for: UIControlState.normal)
        self.arrayBLE.forEach { (droneButton) in
            droneButton.removeFromSuperview()
        }
        
        self.arrayBLE.removeAll()
        self.btnScan?.isHidden = true
        
        self.isScanning = false
        self.viewPetroneMode?.isHidden = false
    }
    
    func petrone(_ disconnectedReason:String ) {
        self.btnScan?.isHidden = false
        self.viewPetroneMode?.isHidden = true
        timer.invalidate()
        
        for child in self.view.subviews {
            if child.isKind(of: Joypad.self) {
                child.removeFromSuperview()
            }
        }
    }
    
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone response: UInt8) {
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone status: PetroneStatus) {
        switch status.mode {
        case PetroneMode.Flight, PetroneMode.FlightNoGuard, PetroneMode.FlightFPV :
            if status.modeFlight != PetroneModeFlight.Ready {
                btnCommand?.setTitle("Landing", for: UIControlState.normal)
            } else {
                btnCommand?.setTitle("Take off", for: UIControlState.normal)
            }
        default:
            btnCommand?.isHidden = true
            btnEmergency?.isHidden = true
        }
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone trim: PetroneTrim) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone trimFlight: PetroneTrimFlight) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone trimDrive: PetroneTrimDrive) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone attitude: PetroneAttitude) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone gyroBias: PetroneGyroBias) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone flightCount: PetroneCountFlight) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone driveCount: PetroneCountDrive) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone motor: PetroneImuRawAndAngle) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone motor: PetronePressure) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone motor: PetroneImageFlow) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone motor: PetroneMotor) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone temperature: PetroneTemperature) {
        
    }
    
    func petrone(_ petroneController: PetroneController, recvFromPetrone range: PetroneRange) {
        
    }
    
}

