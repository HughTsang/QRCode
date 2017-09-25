//
//  GeneratorQRCodeVc.swift
//  QR-code
//
//  Created by zenghz on 2017/8/15.
//  Copyright © 2017年 zhz. All rights reserved.
//

import UIKit

class GeneratorQRCodeVc: UIViewController {

    // MARK: - 属性
    /// 生成的二维码
    fileprivate lazy var qrCodeIv: UIImageView = UIImageView()
    
    /// 需要生成的内容
    fileprivate lazy var inputTv: UITextView = UITextView()
    
    /// 生成按钮
    fileprivate lazy var buildBtn: UIButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
}

// MARK: - 设置UI界面
extension GeneratorQRCodeVc {
    
    fileprivate func setupUI() {
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = .white
        
        qrCodeIv.frame = CGRect(x: (kScreenW - 150) * 0.5, y: 120, width: 150, height: 150)
        qrCodeIv.backgroundColor = .cyan
        
        buildBtn.frame = CGRect(x: 20, y: qrCodeIv.frame.maxY + 5, width: view.frame.width - 40, height: 30)
        buildBtn.setTitle("立即生成", for: .normal)
        buildBtn.addTarget(self, action: #selector(GeneratorQRCodeVc.buildBtnClicked), for: .touchUpInside)
        
        inputTv.frame = CGRect(x: (kScreenW - 150) * 0.5, y: buildBtn.frame.maxY + 5, width: 150, height: 100)
        inputTv.backgroundColor = .cyan
        
        view.addSubview(qrCodeIv)
        view.addSubview(inputTv)
        view.addSubview(buildBtn)
        
        inputTv.text = "要生成的文字~~"
    }
    
}

// MARK: - 事件监听
extension GeneratorQRCodeVc {
    
    /// 点击生成二维码
    @objc fileprivate func buildBtnClicked() {
        
        view.endEditing(true)
        
        let str = inputTv.text ?? ""
        
        let image = HZQRCodeTool.generatorQRCode(input: str, center: UIImage(named: "icon_pig"))
        
        qrCodeIv.image = image
        
    }
    
    private func getNewImage(source: UIImage, center: UIImage) -> UIImage {
    
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
}
