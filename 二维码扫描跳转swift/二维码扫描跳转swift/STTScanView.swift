//
//  STTScanView.swift
//  二维码扫描跳转swift
//
//  Created by user on 16/11/8.
//  Copyright © 2016年 user. All rights reserved.
//

import UIKit
import AVFoundation
//扫描成功 发送通知（在代理实现的情况下发送）
let STTSuccessScanQRCodeNotification = "STTSuccessScanQRCodeNotification"
//通知传递数据只能够存储二维码信息的关键字
let STTScanQRCodeMessageKey = "STTScanQRCodeMessageKey"

let SCANSPCEOFFSET:CGFloat = 0.15
let REMINDTEXT = "将二维码条码放入框即可自动扫描"
let SCREENBOUNDS = UIScreen.mainScreen().bounds
let SCREENWIDTH = CGRectGetWidth(UIScreen.mainScreen().bounds)
let SCREENHEIGHT = CGRectGetHeight(UIScreen.mainScreen().bounds)


@objc protocol STTScanViewDelegate:NSObjectProtocol {
    func scanView(scanView:STTScanView,codeInfo:String)
}

//二维码、条形码扫描视图
class STTScanView: UIView {
    
    //扫描回调代理
    weak var delegate:STTScanViewDelegate?
    
//    var session:AVCaptureSession?
//    var inputt:AVCaptureDeviceInput?
//    var outputt:AVCaptureMetadataOutput?
//    var scanViewLayerr:AVCaptureVideoPreviewLayer?
//    
//    var maskLayerr:CAShapeLayer?
//    var shadowLayerr:CAShapeLayer?
//    var scanRectLayerr:CAShapeLayer?
//    
//    var scanRectt:CGRect?
//    var remindd:UILabel?
    
  var timer:NSTimer?
    
   class func scanViewShowInController(controller:UIViewController)-> STTScanView?{
        guard let vc = controller as UIViewController! else{
            return nil
        }
        let  scanView:STTScanView = STTScanView(frame: UIScreen.mainScreen().bounds)

//        if let ds = vc as? STTScanViewDelegate{
//            scanView.delegate = ds
//        }
    if vc.conformsToProtocol(STTScanViewDelegate.self as Protocol) {
        scanView.delegate = vc as? STTScanViewDelegate
    }//用这个方法需要在协议方法 前 加上@objc
    
        return scanView

    }
    
    override init(frame: CGRect) {
        
        super.init(frame: SCREENBOUNDS)
        self.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
        self.layer.addSublayer(self.scanViewLayerr)
        self.setupIODevice()
        self.setupScanRect()
        self.addSubview(self.remindd)
        self.layer.masksToBounds = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 //停止视频会话
    func stop(){
        self.sessionn.stopRunning()
        
    }
    //开始视频会话
    func start() {
        self.sessionn.startRunning()
    }
    //释放前停止会话
    deinit{
        self.stop()
    }
    //会话对象
   private lazy var sessionn:AVCaptureSession = {
    
   let  session = AVCaptureSession()
    session.sessionPreset = AVCaptureSessionPresetHigh
    
//    self.setupIODevice()
    
   return session
        
    }()
    //视频输入设备
    private lazy var inputt:AVCaptureDeviceInput = {
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let input = try? AVCaptureDeviceInput(device: device)
        return input!
    }()
    //视频输出对象
    private lazy var outputt:AVCaptureMetadataOutput = {
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self as AVCaptureMetadataOutputObjectsDelegate, queue: dispatch_get_main_queue())
        return output
    }()
    //扫描视图
    private lazy var scanViewLayerr:AVCaptureVideoPreviewLayer = {
         let scanViewLayer = AVCaptureVideoPreviewLayer(session: self.sessionn)

        scanViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill

        scanViewLayer.frame = self.bounds

        return scanViewLayer
    }()
    //遮掩层
    private lazy var maskLayerr:CAShapeLayer = {
        var maskLayer = CAShapeLayer()
        maskLayer = self.generateMaskLayerWithRect(SCREENBOUNDS, exceptRect: self.scanRectt)
        return maskLayer
    }()
    //阴影层
    private lazy var shadowLayerr:CAShapeLayer = {
        let shadowLayer = CAShapeLayer()
        shadowLayer.path = UIBezierPath(rect: self.bounds).CGPath
        shadowLayer.fillColor = UIColor(white: 0, alpha: 0.75).CGColor
        shadowLayer.mask = self.maskLayerr
        return shadowLayer
    }()
    //扫描框
    private lazy var scanRectLayerr:CAShapeLayer = {
        var scanRect:CGRect = self.scanRectt
        scanRect.origin.x -= 1
        scanRect.origin.y -= 1
        scanRect.size.width += 2
        scanRect.size.height += 2
        let scanRectLayer = CAShapeLayer()
        scanRectLayer.path = UIBezierPath(rect: scanRect).CGPath
        scanRectLayer.fillColor = UIColor.clearColor().CGColor
        scanRectLayer.strokeColor = UIColor.orangeColor().CGColor
        return scanRectLayer
    
    }()
    //扫描范围
    private lazy var scanRectt:CGRect = {
        var scanRect:CGRect = CGRectZero
        
        if CGRectEqualToRect(scanRect, CGRectZero){
            let rectOfInterest:CGRect = self.outputt.rectOfInterest
            let yOffset:CGFloat = rectOfInterest.size.width - rectOfInterest.origin.x
            let xOffset:CGFloat = 1 - 2 * SCANSPCEOFFSET
            scanRect = CGRectMake(rectOfInterest.origin.y * SCREENWIDTH, rectOfInterest.origin.x * SCREENHEIGHT, xOffset * SCREENWIDTH, yOffset*SCREENHEIGHT)
            
        }
        return scanRect
    }()
    //提示文本
    private lazy var remindd:UILabel = {
        var textRect:CGRect = self.scanRectt
        textRect.origin.y += CGRectGetHeight(textRect) + 20
        textRect.size.height = 25
        let remind = UILabel(frame: textRect)
        remind.font = UIFont.systemFontOfSize(15 * SCREENWIDTH / 375)
        remind.textColor = UIColor.whiteColor()
        remind.textAlignment = .Center
        remind.text = REMINDTEXT
        remind.backgroundColor = UIColor.clearColor()
        return remind
        
    }()
    
    //扫描绿线
    private lazy var QRCodeLine:UIView = {
        var QRCodeLine = UIView(frame: CGRect(x: self.scanRectt.origin.x + 1, y: self.scanRectt.origin.y, width: self.scanRectt.size.width - 1, height: 2))
        QRCodeLine.backgroundColor = UIColor.greenColor()
        
        
        
        // 先让基准线运动一次，避免定时器的时差
        UIView.animateWithDuration(1.2, animations: {
            QRCodeLine.frame = CGRect(x: self.scanRectt.origin.x + 1, y: CGRectGetMaxY(self.scanRectt), width: self.scanRectt.size.width - 1, height: 2)
        })
        
        self.performSelector(#selector(createTimer), withObject: nil, afterDelay: 0.4)
        return QRCodeLine
        
    }()
    //

//
}


extension STTScanView{
    
    
    
    func createTimer() {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.1, target: self, selector: #selector(moveUpAndDownLine), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        if self.timer?.valid == true {
            timer?.invalidate()
            timer = nil
        }
    }
    
    
    func moveUpAndDownLine() {
        let YY:CGFloat = self.QRCodeLine.frame.origin.y
        if YY != CGRectGetMaxY(self.scanRectt) {
            UIView.animateWithDuration(1.2, animations: {
                self.QRCodeLine.frame = CGRect(x: self.scanRectt.origin.x + 1, y: CGRectGetMaxY(self.scanRectt), width: self.scanRectt.size.width - 1, height: 2)
            })
            
        }else{
            UIView.animateWithDuration(1.2, animations: {
                self.QRCodeLine.frame = CGRect(x: self.scanRectt.origin.x + 1, y:self.scanRectt.origin.y, width: self.scanRectt.size.width - 1, height: 2)
            })
            
        }
        
    }

    
   //配置输入输出设置
    func setupIODevice() {
        if (self.sessionn.canAddInput(self.inputt) == true) {
            self.sessionn.addInput(self.inputt)
        }
        if (self.sessionn.canAddOutput(self.outputt) == true) {
            self.sessionn.addOutput(self.outputt)
            self.outputt.metadataObjectTypes = [AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode128Code]
        }
    }
    //生成空缺部分的rect的layer
    func generateMaskLayerWithRect(rect:CGRect,exceptRect:CGRect) -> CAShapeLayer {
        let maskLayer = CAShapeLayer()
        if !CGRectContainsRect(rect, exceptRect) {
            return maskLayer
        }else if (CGRectEqualToRect(rect, CGRectZero)){
            maskLayer.path = UIBezierPath(rect: rect).CGPath
            return maskLayer;
        }
        
        let boundsInitX: CGFloat = rect.minX
        let boundsInitY: CGFloat = rect.minY
        let boundsWidth: CGFloat = rect.width
        let boundsHeight: CGFloat = rect.height
        let minX: CGFloat = exceptRect.minX
        let maxX: CGFloat = exceptRect.maxX
        let minY: CGFloat = exceptRect.minY
        let maxY: CGFloat = exceptRect.maxY
        let width: CGFloat = exceptRect.width
        //添加路径
        let path = UIBezierPath(rect: CGRect(x: boundsInitX, y: boundsInitY, width: minX, height: boundsHeight))
        path.appendPath(UIBezierPath(rect: CGRectMake(minX, boundsInitY, width, minY)))
        path.appendPath(UIBezierPath(rect: CGRectMake(maxX, boundsInitY, boundsWidth - maxX, boundsHeight)))
        path.appendPath(UIBezierPath(rect: CGRectMake(minX, maxY, width, boundsHeight - maxY)))
        
        maskLayer.path = path.CGPath
        return maskLayer

    }
    
    
    
    
    //配置扫描范围
    func setupScanRect() {
        let size:CGFloat = SCREENWIDTH * 1 - 2 * SCANSPCEOFFSET
        let minY:CGFloat = (SCREENHEIGHT - size) * 0.5 / SCREENHEIGHT
        let maxY:CGFloat = (SCREENHEIGHT + size) * 0.5 / SCREENHEIGHT
        self.outputt.rectOfInterest = CGRectMake(minY, SCANSPCEOFFSET, maxY, 1 - SCANSPCEOFFSET * 2)
        self.layer.addSublayer(self.shadowLayerr)
        self.layer.addSublayer(self.scanRectLayerr)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.stop()
        self.stopTimer()
        self.removeFromSuperview()
    }
    
    
}

extension STTScanView:AVCaptureMetadataOutputObjectsDelegate{
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if metadataObjects.count>0 {
            self.stop()
            
            let metadataObject:AVMetadataMachineReadableCodeObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if ((self.delegate?.respondsToSelector(#selector(STTScanViewDelegate.scanView(_:codeInfo:)))) == true )  {
                self.delegate?.scanView(self, codeInfo: metadataObject.stringValue)
                self.stopTimer()
                self.removeFromSuperview()
            }//用这个需要在 协议之前加上 @objc
            
//            if let dc = delegate?.scanView  {
//                dc(self, codeInfo: metadataObject.stringValue)
//                self.removeFromSuperview()
//                
//            }
            else{
                NSNotificationCenter.defaultCenter().postNotificationName(STTSuccessScanQRCodeNotification, object: self, userInfo: [STTScanQRCodeMessageKey:metadataObject.stringValue])
            }
            
//            if self.delegate.respondsToSelector(Selector("scanView:codeInfo:")) {

//            self.delegate?.respondsToSelector(<#T##aSelector: Selector##Selector#>)

        }
    }
}







