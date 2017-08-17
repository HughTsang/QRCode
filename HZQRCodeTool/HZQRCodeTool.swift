//
//  HZQRCodeTool.swift
//
//  Copyright © 2017年 zhz. All rights reserved.
//

import UIKit
import AVFoundation

typealias ScanResultBlock = ([String]) -> ()

fileprivate let borderImageName: String = "icon_qrcode_border"  // 扫描框 边框图片
fileprivate let scanLineImageName: String = "icon_qrcode_scanline_qrcode"// 扫描框 扫描冲击波图片

class HZQRCodeTool: NSObject {
    
    /// 单例
    static let shared = HZQRCodeTool()
    
    // MARK: - 属性
    /// 懒加载输入对象
    fileprivate lazy var input: AVCaptureInput? = {
        // 1.获取摄像头设备
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        // 2.把摄像头设备当做输入设备
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("没有摄像头或摄像头不可用!")
            return nil
        }
        return input
    }()
    /// 输出
    fileprivate lazy var output: AVCaptureMetadataOutput? = {
        let output = AVCaptureMetadataOutput()
        // 设置结果处理的代理
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        return output
    }()
    /// 会话
    fileprivate var session: AVCaptureSession = {
        let session = AVCaptureSession()
        // 如果二维码特别小, 需要设置该属性, 这个决定了视频输入每一帧图像质量的大小
        /*
         AVCaptureSessionPreset320x240
         AVCaptureSessionPreset352x288
         AVCaptureSessionPreset640x480
         AVCaptureSessionPreset960x540
         AVCaptureSessionPreset1280x720
         AVCaptureSessionPreset1920x1080
         */
        session.sessionPreset = "AVCaptureSessionPreset1920x1080"
        return session
    }()
    /// 预览图层
    fileprivate lazy var layer: AVCaptureVideoPreviewLayer = {
        guard let layer = AVCaptureVideoPreviewLayer(session: self.session) else {
            return AVCaptureVideoPreviewLayer()
        }
        return layer
    }()
    /// 是否绘制边框的标记
    fileprivate var isDrawCodeFrameFlag: Bool = false
    /// 扫描结果闭包
    fileprivate var scanResultBlock: ScanResultBlock?
    
    // MARK: - 扫描动画相关属性
    /// 扫描的View
    fileprivate weak var inView: UIView?
    /// 占位视图
    fileprivate lazy var scanView: UIView = { () -> UIView in
        let scanView = UIView()
        scanView.clipsToBounds = true
        return scanView
    }()
    /// 扫描框
    fileprivate lazy var scanBorderIv: UIImageView = { [weak self] () -> UIImageView in
        let imageView  = UIImageView()
        
        // 对图片进行区域保护,拉伸中间一个像素
        let image = self?.getImageFromBundle(imageName: borderImageName)
        let resizeImage = image?.stretchableImage(withLeftCapWidth: Int(image!.size.width * 0.5),
                                                  topCapHeight: Int(image!.size.height * 0.5))
        imageView.image = resizeImage
        return imageView
    }()
    /// 扫描背景
    fileprivate lazy var scanBackIv: UIImageView = { [weak self] () -> UIImageView in
        let imageView  = UIImageView()
        let image = self?.getImageFromBundle(imageName: scanLineImageName) ?? UIImage()
        imageView.image = image
        return imageView
    }()

}

// MARK: - 对外提供方法
extension HZQRCodeTool {
    
    /// 根据给定的字符串, 生成二维码图片
    ///
    /// - Parameters:
    ///   - input: 要转换的字符串
    ///   - center: 二维码中间的前置图片,不需要置为nil
    /// - Returns: 二维码图片
    class func generatorQRCode(input: String,
                               center: UIImage?) -> UIImage {
        
        // 1.创建二维码滤镜
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        // 1.1.回复滤镜默认设置
        filter?.setDefaults()
        
        // 2.设置滤镜输入数据
        let data = input.data(using: .utf8)
        // KVC
        filter?.setValue(data, forKey: "inputMessage")
        
        // 2.1.设置二维码的纠错率
        /*
         L水平: 7%的字码可被修正
         M水平: 15%的字码可被修正
         Q水平: 25%的字码可被修正
         H水平: 30%的字码可被修正
         */
        filter?.setValue("M", forKey: "inputCorrectionLevel")
        
        // 3.从二维码滤镜里面, 获取结果图片
        guard var image = filter?.outputImage else {
            print("生成失败")
            return UIImage()
        }
        
        // 3.1.图片处理
        let transform = CGAffineTransform.init(scaleX: 20, y: 20)
        image = image.applying(transform)
        
        var resultImage = UIImage(ciImage: image)
        
        // 3.2.前景图片
        if center != nil {
            
            resultImage = getNewImage(source: resultImage, center: center!)
        }
        
        return resultImage
    }
    
    /// 识别图片中的二维码
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - isDrawQRCodeFrame: 是否需要绘制描边框,默认为 false
    /// - Returns: 元祖(结果字符串组成的数组, 绘制好二维码边框的图片(如果不要求绘制,则返回原始图片))
    class func detectorQCodeImage(image: UIImage,
                                  isDrawQRCodeFrame: Bool = false) -> (resultStrs: [String], resultImage: UIImage) {
        
        guard let imageCi = CIImage(image: image) else {
            return ([], image)
        }
        
        // 1.开始识别
        // 1.1.创建一个二维码探测器
        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                  context: nil,
                                  options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
        
        // 1.2.直接探测二维码特征
        guard let features = detector?.features(in: imageCi) else {
            return ([], image)
        }
        
        // 存储处理好的图片
        var resultImage = image
        
        // 存储扫描结果数组
        var result = [String]()
        for feature in features {
            
            let qrFeature = feature as! CIQRCodeFeature
            result.append(qrFeature.messageString ?? "")
            //            print("messageString : \(String(describing: qrFeature.messageString))")
            //            print("bounds : \(qrFeature.bounds)")
            if isDrawQRCodeFrame == true {
                resultImage = drawFrame(image: resultImage, feature: qrFeature)
            }
        }
        
        return (result, resultImage)
    }
    
    /// 开始扫描, 视图消失, 最好调用endScan() 方法
    ///
    /// - Parameters:
    ///   - inView: 要识别的View
    ///   - isDrawCodeFrameFlag: 是否绘制边框的标记, 默认为false
    ///   - isSpecifyZoneIdentificationFlag: 是否指定区域识别
    ///   - resultBlock: 回调(结果字符串组成的数组)的Block
    func startScan(inView: UIView,
                   isDrawCodeFrameFlag: Bool = false,
                   isSpecifyZoneIdentificationFlag: Bool = false,
                   resultBlock: @escaping (_ resultStrs: [String]) -> ()) -> ()  {
        
        if session.isRunning == true {
            endScan()
            return
        }
        
        if isDrawCodeFrameFlag == true {
            removeFrameLayer()
        }
        
        // 1.保存闭包, 标志位, 显示的View
        self.inView = inView
        self.scanResultBlock = resultBlock
        self.isDrawCodeFrameFlag = isDrawCodeFrameFlag
        
        // 2.创建会话, 连接输入和输出
        if session.canAddInput(input) && session.canAddOutput(output) {
            session.addInput(input)
            session.addOutput(output)
        } else {
            return
        }
        
        // 3.设置二维码可以识别的码制 (设置识别的类型, 必须在输出添加到会话之后才可以设置,否则奔溃)
        output?.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        // 4.设置扫描的 兴趣区域(可不设置,默认全部区域可识别)
        // 如需设置,调用 setRectOfInterest(originRect:) 方法
        if isSpecifyZoneIdentificationFlag == true {
            setRectOfInterest(originRect: scanBackIv.frame)
        }
        
        // 5.添加视频预览图层(让用户可以看到界面, 不是必须添加的)
        if inView.layer.sublayers == nil {
            layer.frame = inView.layer.bounds
            inView.layer.insertSublayer(layer, at: 0)
        } else {
            let subLayers = inView.layer.sublayers!
            if !subLayers.contains(layer) {
                layer.frame = inView.layer.bounds
                inView.layer.insertSublayer(layer, at: 0)
            }
        }
        
        // 6.启动会话, 让输入开始采集数据, 输出对象 开始处理数据
        session.startRunning()
        
        // 7.执行扫描动画
        startScanAnimation()
    }
    
    /// 结束扫描
    func endScan() {
        // 结束会话
        session.stopRunning()
        
        // 移除输入和输出
        session.removeInput(input)
        session.removeOutput(output)
        
        // 恢复默认
        isDrawCodeFrameFlag = false
        scanResultBlock = nil
        
        // 移除扫描动画
        removeScanAnimation()
    }
}

// MARK: - 私有方法
extension HZQRCodeTool {
    
    /// 为生成的二维码 加上前景图片
    class fileprivate func getNewImage(source: UIImage, center: UIImage) -> UIImage {
        
        let size = source.size
        // 1.开启图片上下文
        UIGraphicsBeginImageContext(size)
        
        // 2.绘制大图片
        source.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // 3.绘制小图片
        let width: CGFloat = 100
        let height: CGFloat = 100
        let x: CGFloat = (size.width - width) * 0.5
        let y: CGFloat = (size.height - height) * 0.5
        center.draw(in: CGRect(x: x, y: y, width: width, height: height))
        
        // 4.取出结果图片
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // 5.关闭上下文
        UIGraphicsEndImageContext()
        
        // 6.返回结果
        return resultImage ?? source
    }
    
    /// 返回图片识别之后的图片 (标出识别了哪些二维码)
    class fileprivate func drawFrame(image: UIImage,
                                     feature: CIQRCodeFeature) -> UIImage {
        
        let size = image.size
        // 1.开启图形上下文
        UIGraphicsBeginImageContext(size)
        
        // 2.绘制大图片
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        // 3.转换坐标系(上下颠倒)
        // 反转坐标系(因为是别的二维码坐标是相对于图片的坐标, 坐标系是以, 左下角为0, 0, 所以需要上下翻转坐标系)
        let context = UIGraphicsGetCurrentContext()
        context?.scaleBy(x: 1, y: -1)
        context?.translateBy(x: 0, y: -size.height)
        
        // 4.绘制路径
        let bounds = feature.bounds
        let path = UIBezierPath(rect: bounds)
        path.lineWidth = 10
        UIColor.red.setStroke()
        path.stroke()
        
        // 5.取出结果图片
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // 6.关闭上下文
        UIGraphicsEndImageContext()
        
        // 7.返回结果
        return resultImage ?? image
    }
    
    /// 设置扫描的 兴趣区域(识别区域), 不设置则是全部区域扫描
    fileprivate func setRectOfInterest(originRect: CGRect) {
        
        // 设置扫描的 兴趣区域
        // 注意, 此处需要填的rect, 是以右上角为(0, 0), 也就是横屏状态
        // 值域范围: 0->1
        let bounds = UIScreen.main.bounds
        let x: CGFloat = originRect.minX / bounds.width
        let y: CGFloat = originRect.minY / bounds.height
        let width: CGFloat = originRect.width / bounds.width
        let height: CGFloat = originRect.height / bounds.height
        output?.rectOfInterest = CGRect(x: y, y: x, width: height, height: width)
    }
    
    fileprivate func getImageFromBundle(imageName: String) -> UIImage? {
    
        guard
            let bundlePath = Bundle.main.path(forResource: "HZQRCodeResource", ofType: "bundle") else {
            return nil
        }
        let imagePath = bundlePath.appending("/\(imageName)")
        let image = UIImage(contentsOfFile: imagePath)
        return image
    }
}

// MARK: - 扫描动画
extension HZQRCodeTool {

    /// 开启扫描动画
    fileprivate func startScanAnimation() {
        
        // 1.设置扫描动画UI
        setupAnimationUI()
        
        // 2.开启动画
        let height = scanBackIv.frame.height
        scanBackIv.frame.origin.y = -height
        
        UIView.animate(withDuration: 1.5, animations: { [weak self] () in
            
            UIView.setAnimationRepeatCount(MAXFLOAT)
            
            self?.scanBackIv.frame.origin.y = height
            
        }) { [weak self] (_) in
            
            self?.scanBackIv.frame.origin.y = -height
        }
        
    }

    /// 移除扫描动画
    fileprivate func removeScanAnimation() {
        
        scanBackIv.layer.removeAllAnimations()
    }
    
    /// 设置扫描动画界面
    fileprivate func setupAnimationUI() {
        
        guard
            let inView = inView else {
                return
        }
        
        var scanViewW: CGFloat = inView.frame.width * 0.6
        
        if inView.frame.width < 200 {
            scanViewW = inView.frame.width
        }
        
        scanView.frame = CGRect(x: 0, y: 0, width: scanViewW, height: scanViewW)
        scanView.center = inView.center
        scanBorderIv.frame = CGRect(x: 0, y: 0, width: scanViewW, height: scanViewW)
        scanBackIv.frame = CGRect(x: 0, y: -scanViewW, width: scanViewW, height: scanViewW)
        
        inView.addSubview(scanView)
        scanView.addSubview(scanBorderIv)
        scanView.addSubview(scanBackIv)
    }
}

// MARK: - 二维码扫描扩展类 AVCaptureMetadataOutputObjectsDelegate
extension HZQRCodeTool: AVCaptureMetadataOutputObjectsDelegate {
    
    // 当元数据输出对象, 识别处理好数据之后, 就会调用这个方法
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        if isDrawCodeFrameFlag == true {
            removeFrameLayer()
        }

        var resultStrs = [String]()
        // 遍历识别到的元数据信息
        for obj in metadataObjects {
            if (obj as AnyObject).isKind(of: AVMetadataMachineReadableCodeObject.self) {
                
                // 1.将扫描到二维码的坐标转换为我们能够识别的坐标
                let reusltObj = layer.transformedMetadataObject(for: obj as! AVMetadataObject)
                let qrCodeObj = reusltObj as! AVMetadataMachineReadableCodeObject
                
//                print(qrCodeObj.stringValue)
//                print(qrCodeObj.corners)
                
                // 2. 根据元数据对象, 绘制二维码边框
                if isDrawCodeFrameFlag == true {
                    drawFrame(qrCodeObj)
                }
                
                // 3. 获取结果
                resultStrs.append(qrCodeObj.stringValue)
            }
        }
        
        // 执行回调代码块
        scanResultBlock?(resultStrs)
        
        // 结束扫描
        endScan()
    }
    
    /// 添加识别框, 如果识别到多个, 则添加多个识别框
    fileprivate func drawFrame(_ qrCodeObj: AVMetadataMachineReadableCodeObject) {
        
        guard let corners = qrCodeObj.corners else {
            return
        }
        
        // 1.借助一个图形层来绘制
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 5
        
        // 2.根据四个点,创建一个路径
        let path = UIBezierPath()
        var index = 0
        for corner in corners {
            // qrCodeObj.corners 代表二维码的四个角, 但是,需要借助视频预览图层,转换成为我们需要的可以用的坐标
            let pointDict = corner as! CFDictionary
            guard let point = CGPoint.init(dictionaryRepresentation: pointDict) else {
                continue
            }
            
            // 第一个点
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
            
            index += 1
        }
        path.close()
        
        // 3.给图形图层的路径赋值,代表图层展示怎样的形状
        shapeLayer.path = path.cgPath
        
        // 4.直接添加图形图层到需要展示的图层
        layer.addSublayer(shapeLayer)
    }
    
    /// 移除识别框
    fileprivate func removeFrameLayer() {
        
        guard
            let subLayers = layer.sublayers
            else {
            return
        }
        
        for subLayer in subLayers {
            
            if subLayer.isKind(of: CAShapeLayer.self) {
                subLayer.removeFromSuperlayer()
            }
        }
    }
    
}
