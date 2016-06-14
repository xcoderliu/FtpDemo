//
//  ViewController.swift
//  FtpDemo
//
//  Created by liuzhimin on 6/3/16.
//  Copyright © 2016 liuzhimin. All rights reserved.
//

import UIKit

class ViewController: UIViewController,NSURLSessionDelegate,NSURLSessionTaskDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        LZMFtpUpload.sharedInstance().userName = "errorreport"
        LZMFtpUpload.sharedInstance().userPwd = "fastmeeting"
        
        LZMFtpUpload.sharedInstance().startSendFile("ftp://er.fsmeeting.com/iOSTest/", (NSBundle.mainBundle().pathForResource("HstDevices12", ofType: ".zip")!))
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { 
            while (LZMFtpUpload.sharedInstance().isSending()) {
                usleep(2000);
            }
            dispatch_async(dispatch_get_main_queue(), { 
                LZMFtpUpload.sharedInstance().startSendFile("ftp://er.fsmeeting.com/iOSTest/", (NSBundle.mainBundle().pathForResource("HstDevices13", ofType: ".zip")!))
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

