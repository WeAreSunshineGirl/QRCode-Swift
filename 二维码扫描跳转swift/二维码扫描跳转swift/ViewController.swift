//
//  ViewController.swift
//  二维码扫描跳转swift
//
//  Created by user on 16/11/8.
//  Copyright © 2016年 user. All rights reserved.
//

import UIKit
import AVFoundation
class ViewController: UIViewController {

    var scanView:STTScanView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.scanView?.start()
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.scanView?.stop()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    deinit{
        self.scanView?.stop()
    }
    @IBAction func zhijie(sender: AnyObject) {
        
        self.view.addSubview(self.scanV())
        self.scanView?.start()
    }
    
    @IBAction func tiaozhuan(sender: AnyObject) {
        
        self.scanView?.removeFromSuperview()
        
        let scanCodeController = STTScanCodeController()
        scanCodeController.scanDelegate = self
        self.navigationController?.pushViewController(scanCodeController, animated: true)
    }
    func scanV() -> STTScanView {
        if self.scanView == nil {
            self.scanView = STTScanView.scanViewShowInController(self)
        }
        return self.scanView!
    }
}
extension ViewController:STTScanCodeControllerDelegate,STTScanViewDelegate{
    func scanView(scanView: STTScanView, codeInfo: String) {
        guard  let url = NSURL(string: codeInfo) else{
            return
        }
        if UIApplication.sharedApplication().canOpenURL(url) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    func scanCodeController(scanCodeController: UIViewController, codeInfo: String) {
        guard  let url = NSURL(string: codeInfo) else{
            return
        }
        if UIApplication.sharedApplication().canOpenURL(url) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}
