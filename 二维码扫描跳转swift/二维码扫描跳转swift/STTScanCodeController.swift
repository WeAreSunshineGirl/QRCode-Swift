//
//  STTScanCodeController.swift
//  二维码扫描跳转swift
//
//  Created by user on 16/11/10.
//  Copyright © 2016年 user. All rights reserved.
//

import UIKit


 protocol STTScanCodeControllerDelegate:NSObjectProtocol {
    func scanCodeController(scanCodeController:UIViewController,codeInfo:String)
}

class STTScanCodeController: UIViewController {

    weak var scanDelegate:STTScanCodeControllerDelegate?
    
    var scanView:STTScanView?
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        self.scanView = STTScanView.scanViewShowInController(self)
        self.view.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(self.scanView!)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.scanView?.start()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.scanView?.stop()
    }
    
    
    deinit{
        self.scanView?.stop()
    }
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}

extension STTScanCodeController:STTScanViewDelegate{
    func scanView(scanView: STTScanView, codeInfo: String) {

        if let de = scanDelegate?.scanCodeController {
            de(self, codeInfo: codeInfo)
        }
//
//        if (scanDelegate?.respondsToSelector(#selector(STTScanCodeControllerDelegate.scanCodeController(_:codeInfo:)))) == true {
//              scanDelegate?.scanCodeController(self, codeInfo: codeInfo)
//        }//用这个需要在 协议之前加上 @objc
        
        else{
            NSNotificationCenter.defaultCenter().postNotificationName(STTSuccessScanQRCodeNotification, object: self, userInfo: [STTScanQRCodeMessageKey:codeInfo])
        }
    }
}
