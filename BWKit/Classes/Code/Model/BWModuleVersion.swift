//
//  BWModuleVersion.swift
//  BWKit
//
//  Created by yuhua on 2020/3/4.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper


/// 数据版本
class BWModuleVersion: Mappable {
    
    /// 模块
    var module: String?
    
    /// 版本
    var version: Int?
    
    /// 初始化
    init(module: String, version: Int) {
        self.module = module
        self.version = version
    }
    
    /// 忽略该方法
    required init?(map: Map) {
    }
    
    /// 忽略该方法
    func mapping(map: Map) {
        module <- map["module"]
        version <- map["version"]
    }
    
    /// 描述
    var description: String {
        return "[module:\(module ?? "") version:\(version ?? -1)]"
    }
}

/// 执行操作
extension BWModuleVersion {
    
    /// 查询数据版本，内部使用
    static func QueryModuleVersion(success: @escaping ([BWModuleVersion])->Void = { _ in }, fail: @escaping (Int)->Void = { _ in}) {
        guard let msg = ObjectMSG.gatewayCfgVerQuery() else {
            fail(-1)
            return
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                guard let list = json["version_info"].rawString() else {
                    success([])
                    return
                }
                let modules = [BWModuleVersion](JSONString: list) ?? [BWModuleVersion]()
                success(modules)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
}
