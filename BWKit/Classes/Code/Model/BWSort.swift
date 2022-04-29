//
//  BWSort.swift
//  BWKit
//
//  Created by yuhua on 2020/3/23.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import SQLite

// 排序重置号
let sortRebootId = 5000

protocol BWSortProtocol {
    var sortId: Int? { get set }
    var belongId: Int? { get set }
    static var tableName: String { get }
    @discardableResult static func creatTable(dbName: String) -> Bool
    @discardableResult func save(or: OnConflict) -> Bool
    @discardableResult static func delete(belongId: Int) -> Bool
    @discardableResult static func clear() -> Bool
}

extension BWSortProtocol {
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName,
                                              tableName: tableName) {
            $0.column(DBColumn.belongId, primaryKey: true)
            $0.column(DBColumn.sortId)
        }
    }
    /// 删除指定ID排序信息
    @discardableResult static func delete(belongId: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.belongId == belongId)
    }
    /// 清空排序
    @discardableResult static func clear() -> Bool {
        return BWDBManager.shared.clearTable(dbName: BWAppManager.shared.loginGWDBName(),
                                             tableName: tableName)
    }
}

/// 设备排序
class BWDeviceSort: BWSortProtocol {
    
    var sortId: Int?
    
    var belongId: Int?
    
    static var tableName: String = "deviceSort"
    
    /// 保存，默认覆盖保存
    @discardableResult func save(or: OnConflict = .replace) -> Bool {
        return BWDBManager.shared.insertTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWDeviceSort.tableName,
                                              values: [DBColumn.belongId <- belongId ?? -1,
                                                       DBColumn.sortId <- sortId ?? -1
        ], or: or)
    }
    static func query(dbName: String) -> [BWDeviceSort] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                let sort = BWDeviceSort()
                sort.sortId = $0[DBColumn.sortId]
                sort.belongId = $0[DBColumn.belongId]
                return sort
            }
        } else {
            return []
        }
    }
}
// 设备房间排序
class BWDeviceRoomSort: BWSortProtocol {
    
    var sortId: Int?
    
    var belongId: Int?
    
    static var tableName: String = "roomDeviceSort"
    
    /// 保存，默认覆盖保存
    @discardableResult func save(or: OnConflict = .replace) -> Bool {
        return BWDBManager.shared.insertTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWDeviceRoomSort.tableName,
                                              values: [DBColumn.belongId <- belongId ?? -1,
                                                       DBColumn.sortId <- sortId ?? -1
        ], or: or)
    }
    static func query(dbName: String) -> [BWDeviceRoomSort] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                let sort = BWDeviceRoomSort()
                sort.sortId = $0[DBColumn.sortId]
                sort.belongId = $0[DBColumn.belongId]
                return sort
            }
        } else {
            return []
        }
    }
}
// 房间排序
class BWRoomSort: BWSortProtocol {
    
    var sortId: Int?
    
    var belongId: Int?
    
    static var tableName: String = "roomSort"
    
    /// 保存，默认覆盖保存
    @discardableResult func save(or: OnConflict = .replace) -> Bool {
        return BWDBManager.shared.insertTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWRoomSort.tableName,
                                              values: [DBColumn.belongId <- belongId ?? -1,
                                                       DBColumn.sortId <- sortId ?? -1
        ], or: or)
    }
    static func query(dbName: String) -> [BWRoomSort] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                let sort = BWRoomSort()
                sort.sortId = $0[DBColumn.sortId]
                sort.belongId = $0[DBColumn.belongId]
                return sort
            }
        } else {
            return []
        }
    }
}
// 联动排序
class BWLinkageSort: BWSortProtocol {
    
    var sortId: Int?
    
    var belongId: Int?
    
    static var tableName: String = "linkageSort"
    
    /// 保存
    @discardableResult func save(or: OnConflict = .replace) -> Bool {
        return BWDBManager.shared.insertTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWLinkageSort.tableName,
                                              values: [DBColumn.belongId <- belongId ?? -1,
                                                       DBColumn.sortId <- sortId ?? -1
        ], or: or)
    }
    static func query(dbName: String) -> [BWLinkageSort] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                let sort = BWLinkageSort()
                sort.sortId = $0[DBColumn.sortId]
                sort.belongId = $0[DBColumn.belongId]
                return sort
            }
        } else {
            return []
        }
    }
}
// 场景排序
class BWSceneSort: BWSortProtocol {
    
    var sortId: Int?
    
    var belongId: Int?
    
    static var tableName: String = "sceneSort"
    
    /// 保存
    @discardableResult func save(or: OnConflict = .replace) -> Bool {
        return BWDBManager.shared.insertTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWSceneSort.tableName,
                                              values: [DBColumn.belongId <- belongId ?? -1,
                                                       DBColumn.sortId <- sortId ?? -1
        ], or: or)
    }
    static func query(dbName: String) -> [BWSceneSort] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                let sort = BWSceneSort()
                sort.sortId = $0[DBColumn.sortId]
                sort.belongId = $0[DBColumn.belongId]
                return sort
            }
        } else {
            return []
        }
    }
}
// 定时排序
class BWTimerSort: BWSortProtocol {
    
    var sortId: Int?
    
    var belongId: Int?
    
    static var tableName: String = "timerSort"
    
    /// 保存
    @discardableResult func save(or: OnConflict = .replace) -> Bool {
        return BWDBManager.shared.insertTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWTimerSort.tableName,
                                              values: [DBColumn.belongId <- belongId ?? -1,
                                                       DBColumn.sortId <- sortId ?? -1
        ], or: or)
    }
    static func query(dbName: String) -> [BWTimerSort] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                let sort = BWTimerSort()
                sort.sortId = $0[DBColumn.sortId]
                sort.belongId = $0[DBColumn.belongId]
                return sort
            }
        } else {
            return []
        }
    }
}
