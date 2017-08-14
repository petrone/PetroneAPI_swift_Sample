//
//  ViewController.swift
//  PetroneOpenCVExample
//
//  Created by Byrobot on 2017. 8. 11..
//  Copyright © 2017년 Byrobot. All rights reserved.
//

import UIKit

import PetroneAPI

class ViewController: UIViewController {
    @IBOutlet weak var imageFPV: UIImageView?
    private var videoStream:FFMpegWrapper = FFMpegWrapper()
    private var cvWrapper:OpenCVWrapper = OpenCVWrapper()
    private var timer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        videoStream.onConnect()
        timer = Timer.scheduledTimer(timeInterval: 1.0/30, target: self,   selector: (#selector(ViewController.updateVideo)), userInfo: nil, repeats: true)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func updateVideo() {
        DispatchQueue.main.async {
            if self.videoStream.isConnected() {
                self.videoStream.decodeFrame()
                self.imageFPV?.image = self.cvWrapper.getFeature(self.videoStream.getFrame())
            }
        }
    }
}

