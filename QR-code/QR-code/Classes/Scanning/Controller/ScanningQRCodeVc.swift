//
//  ScanningQRCodeVc.swift
//
//  Created by zenghz on 2017/8/14.
//  Copyright © 2017年 Personal. All rights reserved.
//  二维码扫描

import UIKit

class ScanningQRCodeVc: UIViewController {

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
        
    }
}

// MARK: - 事件监听
extension ScanningQRCodeVc {
    
}

// MARK: - 请求数据
extension ScanningQRCodeVc {
    
}
