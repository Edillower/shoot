//
//  AVCamPreviewView.swift
//  jre
//
//  Created by Joey Van Gundy on 3/26/16.
//  Copyright © 2016 Joe Van Gundy. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


class AVCamPreviewView: UIView{
    
    var session: AVCaptureSession? {
        get{
            return (self.layer as! AVCaptureVideoPreviewLayer).session;
        }
        set(session){
            
            (self.layer as! AVCaptureVideoPreviewLayer).session = session;
            (self.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravityResizeAspectFill
        }
    };
    
    
    
    override class var layerClass :AnyClass{
        return AVCaptureVideoPreviewLayer.self;
    }
}
