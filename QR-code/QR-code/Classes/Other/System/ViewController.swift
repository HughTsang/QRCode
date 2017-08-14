//
//  ViewController.swift
//  27-QR-code
//
//  Created by zenghz on 2017/8/14.
//  Copyright © 2017年 Personal. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    fileprivate lazy var table: UITableView = { [weak self] () -> UITableView in
        
        let table = UITableView(frame: CGRect(x: 0, y: kNavBarHeight, width: kScreenW, height: kScreenH - kNavBarHeight),
                                style: .plain)
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView(frame: CGRect.zero)
        table.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        return table
    }()
    
    fileprivate var listArray: [String] = ["二维码生成", "二维码扫描", "读取图片二维码"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        view.backgroundColor = UIColor.white
        
        view.addSubview(table)
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) 
        cell.textLabel?.text = listArray[indexPath.row]
        cell.textLabel?.textColor = .blue
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0: // 二维码生成
            let buildVc = BuildQRCodeVc()
            buildVc.navigationItem.title = listArray[indexPath.row]
            navigationController?.pushViewController(buildVc, animated: true)
            break
        case 1: // 二维码扫描
            let scanningVc = ScanningQRCodeVc()
            scanningVc.navigationItem.title = listArray[indexPath.row]
            navigationController?.pushViewController(scanningVc, animated: true)
            break
        case 2: // 读取图片二维码
            let distinguishVc = DistinguishQRCodeVc()
            distinguishVc.navigationItem.title = listArray[indexPath.row]
            navigationController?.pushViewController(distinguishVc, animated: true)
            break
        default:
            break
        }
    }
    
}

