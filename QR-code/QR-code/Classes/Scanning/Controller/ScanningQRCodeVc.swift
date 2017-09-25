//
//  ScanningQRCodeVc.swift
//
//  Created by zenghz on 2017/8/14.
//  Copyright © 2017年 Personal. All rights reserved.
//  二维码扫描

import UIKit

class ScanningQRCodeVc: UIViewController {
    
    let qrCodeTool: HZQRCodeTool = HZQRCodeTool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

// MARK: - 设置UI界面
extension ScanningQRCodeVc {
    
    fileprivate func setupUI() {
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = .white
        navigationItem.title = "轻点屏幕 开始扫描"
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // 开启摄像头扫描
        startScanning()
    }
    
}

// MARK: - 开始扫描
extension ScanningQRCodeVc {
    
    fileprivate func startScanning() {

        qrCodeTool.startScan(inView: view,
                                      isDrawCodeFrameFlag: true)
        { [weak self] (resultStrs) in
            
            var resultMessage = resultStrs.description
            
            if resultStrs.count == 0 {
                resultMessage = "未识别到二维码"
            }
            
            let alert = UIAlertController(title: "识别结果", message: resultMessage, preferredStyle: .alert)
            let action = UIAlertAction(title: "关闭", style: .cancel, handler: nil)
            alert.addAction(action)
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
}
