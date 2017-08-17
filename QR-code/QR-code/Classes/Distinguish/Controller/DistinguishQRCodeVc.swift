//
//  DistinguishQRCodeVc.swift
//
//  Created by zenghz on 2017/8/14.
//  Copyright © 2017年 Personal. All rights reserved.
//  识别图中二维码

import UIKit
import Photos

class DistinguishQRCodeVc: UIViewController {

    // MARK: - 属性
    /// 二维码
    fileprivate lazy var sourceIv: UIImageView = UIImageView()
    
    /// 需要生成的内容
    fileprivate lazy var outputIv: UIImageView = UIImageView()
    
    /// 开始识别按钮
    fileprivate lazy var distinguishBtn: UIButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

// MARK: - 设置UI界面
extension DistinguishQRCodeVc {
    
    fileprivate func setupUI() {
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = .white
        
        sourceIv.frame = CGRect(x: (kScreenW - 200) * 0.5, y: 120, width: 200, height: 200)
        sourceIv.image = UIImage(named: "pic_QRCode2")
        sourceIv.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(DistinguishQRCodeVc.chooseImage))
        sourceIv.addGestureRecognizer(tap)
        
        outputIv.frame = CGRect(x: (kScreenW - 200) * 0.5, y: sourceIv.frame.maxY + 20, width: 200, height: 200)
        
        distinguishBtn.frame = CGRect(x: kScreenW - 100, y: kNavBarHeight + 20, width: 80, height: 30)
        distinguishBtn.setTitle("开始识别", for: .normal)
        distinguishBtn.addTarget(self, action: #selector(DistinguishQRCodeVc.distinguishBtnClicked), for: .touchUpInside)
        
        view.addSubview(sourceIv)
        view.addSubview(outputIv)
        view.addSubview(distinguishBtn)
    }
}

// MARK: - 事件监听
extension DistinguishQRCodeVc {
    
    /// 开始识别
    @objc fileprivate func distinguishBtnClicked() {
        
        // 1.获取需要识别的图片
        guard let image = sourceIv.image else {
            return
        }
        
        let result = HZQRCodeTool.detectorQCodeImage(image: image, isDrawQRCodeFrame: true)
        
        outputIv.image = result.resultImage
        
        var resultMessage = result.resultStrs.description
        
        if result.resultStrs.count == 0 {
            resultMessage = "未识别到二维码"
        }

        let alert = UIAlertController(title: "识别结果", message: resultMessage, preferredStyle: .alert)
        let action = UIAlertAction(title: "关闭", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
}
// MARK: - 图片选择
extension DistinguishQRCodeVc {
    
    /// 选择图片
    @objc fileprivate func chooseImage() {
    
        let sheet = UIAlertController(title: "选择图片", message: nil, preferredStyle: .actionSheet)
        
        let takePhoto = UIAlertAction(title: "拍照", style: .default, handler: { [weak self] (_) in
            self?.getImageFromPhotoLib(type: .camera)
        })
        let photoLib = UIAlertAction(title: "相册", style: .default, handler: { [weak self] (action) in
            self?.getImageFromPhotoLib(type: .photoLibrary)
        })
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        sheet.addAction(takePhoto)
        sheet.addAction(photoLib)
        sheet.addAction(cancel)
        
        present(sheet, animated: true, completion: nil)
    }
    
    /// 获取照片
    ///
    /// - Parameter type: 源
    private func getImageFromPhotoLib(type: UIImagePickerControllerSourceType) {
        
        switch type {
        case .camera:
            
            if UIImagePickerController.isSourceTypeAvailable(type) == false {
                print("您的手机没有摄像头或者摄像头不可用~")
                return
            }
            
            if cameraPermissions() == false {
                print("请在设置中打开摄像头权限")
                return
            }
            
            break
        case .photoLibrary:
            
            if photoLibraryPermissions() == false {
                print("请在设置中打开相册权限")
                return
            }
            
            break
        default:
            break
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = type
        self.present(picker, animated: true, completion: nil)
    }
    
    /// 判断相机权限
    ///
    /// - Returns: 有权限返回true，没权限返回false
    private func cameraPermissions() -> Bool{
        
        let authStatus: AVAuthorizationStatus =  AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if authStatus == .denied || authStatus == .restricted {
            return false
        } else {
            return true
        }
    }
    
    /// 判断相册权限
    ///
    /// - Returns: 有权限返回ture， 没权限返回false
    private func photoLibraryPermissions() -> Bool {
        
        let libraryStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        if libraryStatus == .denied || libraryStatus == .restricted {
            return false
        } else {
            return true
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension DistinguishQRCodeVc: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // 获取原图
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        picker.dismiss(animated: true) { [weak self] in
            
            self?.sourceIv.image = image
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        picker.dismiss(animated: true, completion: nil)
    }
    
}

