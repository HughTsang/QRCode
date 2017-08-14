//
//  CommonKeys.swift
//  公用常量

import Foundation
import UIKit


// MARK: - UI布局相关常量
let kGap: CGFloat = 10
let kNavBarHeight: CGFloat = 64
let kTabBatHeight: CGFloat = 49

let kScreenW: CGFloat = UIScreen.main.bounds.width
let kScreenH: CGFloat = UIScreen.main.bounds.height

let CellIdentifier = "CellIdentifier"


// MARK: - 通知常量
extension Notification.Name {
    
    /// 轮播图移除定时器
    public static let kBannerViewRemoveTimer: Notification.Name = Notification.Name(rawValue: "kBannerViewRemoveTimer")
    
    
}
