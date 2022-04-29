//
//  BWBaseModelProtocol.swift
//  BWKit
//
//  Created by yuhua on 2020/3/3.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import SQLite

protocol BWBaseModelProtocol: CustomStringConvertible {
    
    /// 表名
    static var tableName: String { get }
    
    /// 创建数据库表，需指定数据库。
    @discardableResult static func creatTable(dbName: String) -> Bool
    
    /// 保存数据，需指定数据库。
    @discardableResult func save(dbName: String) -> Bool
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol]
    
    /// 删除数据
    @discardableResult func delete(dbName: String) -> Bool
    
    /// 清空表
    @discardableResult static func clearTable(dbName: String) -> Bool
    
    /// 删除表
    @discardableResult static func dropTable(dbName: String) -> Bool
}


extension BWBaseModelProtocol {
    
    /// 清空表
    @discardableResult static func clearTable(dbName: String) -> Bool {
        return BWDBManager.shared.clearTable(dbName: dbName, tableName: tableName)
    }
    
    /// 删除表
    @discardableResult static func dropTable(dbName: String) -> Bool {
        return BWDBManager.shared.dropTable(dbName: dbName, tableName: tableName)
    }
}

