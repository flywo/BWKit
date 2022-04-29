//
//  BWDBManager.swift
//  BWKit
//
//  Created by yuhua on 2020/3/3.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import SQLite

/// 数据库版本，奇数:只需清除网关数据库即可  偶数:还需清除公共数据库
let dbVersion = 17

/// 数据库版本管理
extension Connection {
    var userVersion: Int {
        get {
            if let num = try? scalar("PRAGMA user_version"), let result = num as? Int64 {
                return Int(result)
            }
            return 0
        }
        set {
            _ = try? run("PRAGMA user_version = \(newValue)")
        }
    }
}

// db manager
class BWDBManager {
    /// 单例
    static let shared = BWDBManager()
    
    /// 数据库存放位置
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/BW/db"
    
    /// 所有已连接数据库
    var dbs = [String: Connection]()
    
    /// 将老数据库排序数据存入新数据库，完毕后删除掉老数据库
    func sortOldOrderData(dbName: String) {
        let oldName = "old" + dbName
        let oldPath = path + "/" + oldName
        if !FileManager.default.fileExists(atPath: oldPath) {
            BWSDKLog.shared.debug("不存在老数据库，不需要转移排序数据")
            return
        }
        connectDB(dbName: oldName)
        BWDeviceSort.query(dbName: oldName).save(dbName: dbName)
        BWDeviceRoomSort.query(dbName: oldName).save(dbName: dbName)
        BWRoomSort.query(dbName: oldName).save(dbName: dbName)
        BWLinkageSort.query(dbName: oldName).save(dbName: dbName)
        BWSceneSort.query(dbName: oldName).save(dbName: dbName)
        BWTimerSort.query(dbName: oldName).save(dbName: dbName)
        BWSDKLog.shared.debug("老数据库排序转移完毕")
        disconnectDB(dbName: oldName)
        forceRemoveDB(name: oldName)
    }
    
    /// 连接数据库
    @discardableResult func connectDB(dbName: String, temp: Bool = false) -> Bool {
        if temp {
            if let db = try? Connection() {
                BWSDKLog.shared.info("连接临时数据库:\(dbName)")
                try? db.execute("PRAGMA foreign_keys = ON;")
                dbs[dbName] = db
                return true
            } else {
                BWSDKLog.shared.error("连接临时数据库失败:\(dbName)")
                return false
            }
        } else {
            if !FileManager.default.fileExists(atPath: path) {
                BWSDKLog.shared.error("数据库文件夹不存在，先创建")
                try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            }
            let dbPath = path + "/" + dbName
            BWSDKLog.shared.info("数据库路径:\(dbPath)")
            if let db = try? Connection(dbPath) {
                try? db.execute("PRAGMA foreign_keys = ON;")
                BWSDKLog.shared.info("连接数据库:\(dbName)")
                dbs[dbName] = db
                return true
            } else {
                BWSDKLog.shared.error("连接数据库失败:\(dbName)")
                return false
            }
        }
    }
    
    /// 判断数据库是否需要更新
    /// - Parameter checkDB: 检查的哪个数据库信息
    func judgeDB(checkDB: String) {
        if let db = dbs[checkDB] {
            if dbVersion != db.userVersion {
                if db.userVersion == 0 {
                    BWSDKLog.shared.info("本地没有旧的数据库，无需更新")
                    db.userVersion = dbVersion
                    return
                }
                if dbVersion % 2 == 0 {
                    BWSDKLog.shared.info("公共数据库和网关数据库需要更新")
                    removeAllDB()
                    BWSDKLog.shared.info("重新连接公共数据库")
                    connectDB(dbName: checkDB)
                    if let db = dbs[checkDB] {
                        db.userVersion = dbVersion
                    }
                } else {
                    BWSDKLog.shared.info("网关数据库需要更新")
                    removeGatewayDB()
                    db.userVersion = dbVersion
                }
            } else {
                BWSDKLog.shared.info("本地数据库已是最新版本，无需更新")
            }
        }
    }
    
    /// 断开所有数据库
    func disconnectAllDB() {
        BWSDKLog.shared.info("断开所有数据库")
        dbs.removeAll()
    }
    
    /// 断开指定数据库
    func disconnectDB(dbName: String) {
        BWSDKLog.shared.info("断开数据库:\(dbName)")
        dbs.removeValue(forKey: dbName)
    }
    
    /// 从磁盘中删除删除数据库，临时数据库请勿调用该方法
    func removeDB(names: [String]) {
        names.forEach {
            guard $0.hasSuffix("db") else {
                BWSDKLog.shared.info("\($0)不是数据库文件，保留！")
                return
            }
            guard !$0.contains("old") else {
                BWSDKLog.shared.info("\($0)不是最新数据库文件，保留！")
                return
            }
            if dbs.keys.contains($0) {
                disconnectDB(dbName: $0)
            }
            let dbPath = path + "/" + $0
//            BWSDKLog.shared.info("删除数据库:\(dbPath)")
//            try? FileManager.default.removeItem(atPath: dbPath)
            // 修改老数据库名称，前面添加old字段，主要是数据库里面的排序不能删除，否则会出现排序没有了的情况
            let newPath = path + "/old" + $0
            BWSDKLog.shared.info("修改数据库名称:\(dbPath) -> \(newPath)")
            try? FileManager.default.moveItem(atPath: dbPath, toPath: newPath)
        }
    }
    
    /// 强制删除数据库
    func forceRemoveDB(name: String) {
        let dbPath = path + "/" + name
        BWSDKLog.shared.info("强制删除数据库:\(dbPath)")
        try? FileManager.default.removeItem(atPath: dbPath)
    }
    
    /// 删除所有数据库
    func removeAllDB() {
        removeDB(names: [BWAppManager.shared.commonDB])
        removeGatewayDB()
    }
    
    /// 删除网关数据库
    func removeGatewayDB() {
        if let paths = try? FileManager.default.contentsOfDirectory(atPath: path) {
            var dbNames = paths.map {
                $0.replacingOccurrences(of: path + "/", with: "")
            }
            dbNames.removeAll {
                $0.contains(BWAppManager.shared.commonDB)
            }
            removeDB(names: dbNames)
        }
    }
    
    /// 创建表
    @discardableResult func createTable(dbName: String, tableName: String, createBlock: (TableBuilder)->Void) -> Bool {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let _ = try? db.run(dbModel.create(ifNotExists: true, block: createBlock)) {
                BWSDKLog.shared.info("创建表成功:\(dbName) -> \(tableName)")
                return true
            } else {
                BWSDKLog.shared.info("表已经存在:\(dbName) -> \(tableName)")
                return false
            }
        }
        BWSDKLog.shared.error("创建表失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return false
    }
    
    /// 插入单个数据，如果主键存在，则会替换数据。该方法可用作更新数据。
    @discardableResult func insertTable(dbName: String, tableName: String, values: [Setter], or: OnConflict = .replace) -> Bool {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            do {
                let _ = try db.run(dbModel.insert(or: or, values))
                return true
            } catch let error {
                BWSDKLog.shared.error("插入数据失败:\(dbName) -> \(tableName) error:\(error)")
                return false
            }
        }
        BWSDKLog.shared.error("插入数据失败:\(dbName) -> 数据库未连接")
        return false
    }
    
    /// 更新单个数据
    @discardableResult func updateTable(dbName: String, tableName: String, filter: Expression<Bool>, values: [Setter]) -> Bool {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            do {
                let _ = try db.run(dbModel.filter(filter).update(values))
                return true
            } catch let error {
                BWSDKLog.shared.error("更新数据失败:\(dbName) -> \(tableName) error:\(error)")
                return false
            }
        }
        BWSDKLog.shared.error("更新数据失败:\(dbName) -> 数据库未连接")
        return false
    }
    
    /// 批量操作(包括增删改查等)数据，批量操作数据指定的数据库与内部操作指定的数据库，需是同一数据库。
    @discardableResult func transaction(dbName: String, operate: ()throws->Void) -> Bool {
        if let db = dbs[dbName] {
            do {
                BWSDKLog.shared.info("批量操作开始...")
                try db.transaction(.deferred, block: operate)
                BWSDKLog.shared.info("批量操作完成")
                return true
            } catch let error {
                BWSDKLog.shared.error("批量操作数据失败:\(dbName) \(error.localizedDescription)")
                return false
            }
        }
        BWSDKLog.shared.error("批量操作数据失败:\(dbName) -> 数据库未连接")
        return false
    }
    
    /// 查询总数
    func queryTableTotal(dbName: String, tableName: String) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.count) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--指定int字段不重复
    func queryTableTotal(dbName: String, tableName: String, distinct: Expression<Int>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.select(distinct.distinct.count)) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加过滤条件
    func queryTableTotal(dbName: String, tableName: String, filter: Expression<Bool>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter).count) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加过滤条件，同时指定int字段不重复
    func queryTableTotal(dbName: String, tableName: String, filter: Expression<Bool>, distinct: Expression<Int>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter).select(distinct.distinct.count)) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加2个过滤条件
    func queryTableTotal(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter1).filter(filter2).count) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加2个过滤条件，同时指定int字段不重复
    func queryTableTotal(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, distinct: Expression<Int>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter1).filter(filter2).select(distinct.distinct.count)) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加3个过滤条件
    func queryTableTotal(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter1).filter(filter2).filter(filter3).count) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加3个过滤条件，同时指定int字段不重复
    func queryTableTotal(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, distinct: Expression<Int>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter1).filter(filter2).filter(filter3).select(distinct.distinct.count)) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加5个过滤条件
    func queryTableTotal(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, filter5: Expression<Bool>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter1).filter(filter2).filter(filter3).filter(filter4).filter(filter5).count) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加6个过滤条件
    func queryTableTotal(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, filter5: Expression<Bool>, filter6: Expression<Bool>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter1).filter(filter2).filter(filter3).filter(filter4).filter(filter5).filter(filter6).count) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加7个过滤条件
    func queryTableTotal(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, filter5: Expression<Bool>, filter6: Expression<Bool>, filter7: Expression<Bool>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter1).filter(filter2).filter(filter3).filter(filter4).filter(filter5).filter(filter6).filter(filter7).count) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加8个过滤条件
    func queryTableTotal(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, filter5: Expression<Bool>, filter6: Expression<Bool>, filter7: Expression<Bool>, filter8: Expression<Bool>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter1).filter(filter2).filter(filter3).filter(filter4).filter(filter5).filter(filter6).filter(filter7).filter(filter8).count) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查询总数--增加9个过滤条件
    func queryTableTotal(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, filter5: Expression<Bool>, filter6: Expression<Bool>, filter7: Expression<Bool>, filter8: Expression<Bool>, filter9: Expression<Bool>) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let count = try? db.scalar(dbModel.filter(filter1).filter(filter2).filter(filter3).filter(filter4).filter(filter5).filter(filter6).filter(filter7).filter(filter8).filter(filter9).count) {
                return count
            } else {
                BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询总数失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 查找所有数据
    func queryTable(dbName: String, tableName: String) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let models = try? db.prepare(dbModel) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找所有数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            if let models = try? db.prepare(dbModel.join(.leftOuter, joinModel, on: joinTableOn).order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定1过滤条件数据
    func queryTable(dbName: String, tableName: String, filter: Expression<Bool>) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let models = try? db.prepare(dbModel.filter(filter)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定1过滤条件数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, filter: Expression<Bool>, joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            if let models = try? db.prepare(dbModel.join(.leftOuter, joinModel, on: joinTableOn).filter(filter).order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定2过滤条件数据
    func queryTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let models = try? db.prepare(dbModel.filter(filter1).filter(filter2)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定2过滤条件数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            if let models = try? db.prepare(dbModel.join(.leftOuter, joinModel, on: joinTableOn).filter(filter1).filter(filter2).order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定3过滤条件数据
    func queryTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let models = try? db.prepare(dbModel.filter(filter1).filter(filter2).filter(filter3)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定3过滤条件数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            if let models = try? db.prepare(dbModel.join(.leftOuter, joinModel, on: joinTableOn).filter(filter1).filter(filter2).filter(filter3).order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定4过滤条件数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            if let models = try? db.prepare(dbModel.join(.leftOuter, joinModel, on: joinTableOn).filter(filter1).filter(filter2).filter(filter3).filter(filter4).order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定5过滤条件数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, filter5: Expression<Bool>, joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            if let models = try? db.prepare(dbModel.join(.leftOuter, joinModel, on: joinTableOn).filter(filter1).filter(filter2).filter(filter3).filter(filter4).filter(filter5).order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定6过滤条件数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, filter5: Expression<Bool>, filter6: Expression<Bool>, joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            if let models = try? db.prepare(dbModel.join(.leftOuter, joinModel, on: joinTableOn).filter(filter1).filter(filter2).filter(filter3).filter(filter4).filter(filter5).filter(filter6).order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定7过滤条件数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, filter5: Expression<Bool>, filter6: Expression<Bool>, filter7: Expression<Bool>, joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            if let models = try? db.prepare(dbModel.join(.leftOuter, joinModel, on: joinTableOn).filter(filter1).filter(filter2).filter(filter3).filter(filter4).filter(filter5).filter(filter6).filter(filter7).order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定8过滤条件数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, filter5: Expression<Bool>, filter6: Expression<Bool>, filter7: Expression<Bool>, filter8: Expression<Bool>, joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            if let models = try? db.prepare(dbModel.join(.leftOuter, joinModel, on: joinTableOn).filter(filter1).filter(filter2).filter(filter3).filter(filter4).filter(filter5).filter(filter6).filter(filter7).filter(filter8).order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定9过滤条件数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>, filter3: Expression<Bool>, filter4: Expression<Bool>, filter5: Expression<Bool>, filter6: Expression<Bool>, filter7: Expression<Bool>, filter8: Expression<Bool>, filter9: Expression<Bool>, joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            if let models = try? db.prepare(dbModel.join(.leftOuter, joinModel, on: joinTableOn).filter(filter1).filter(filter2).filter(filter3).filter(filter4).filter(filter5).filter(filter6).filter(filter7).filter(filter8).filter(filter9).order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定N个滤条件数据，并且根据排序表进行排序
    func queryTable(dbName: String, tableName: String, filters: [Expression<Bool>], joinTable: String, joinTableOn: Expression<Bool>, sort: Expressible) -> AnySequence<Row>? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            let joinModel = Table(joinTable)
            var sql = dbModel.join(.leftOuter, joinModel, on: joinTableOn)
            filters.forEach {
                sql = sql.filter($0)
            }
            if let models = try? db.prepare(sql.order(sort)) {
                return models
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找指定的字段有多少值，会去重
    func queryField(dbName: String, tableName: String, fieldName: Expression<String>) -> [String] {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let fields = try? db.prepare(dbModel.select(distinct: fieldName)) {
                return fields.map {
                    $0[fieldName]
                }
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return []
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return []
    }
    
    /// 查找指定的字段有多少值，增加一个过滤条件，会去重
    func queryField(dbName: String, tableName: String, fieldName: Expression<String>, filter: Expression<Bool>) -> [String] {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let fields = try? db.prepare(dbModel.filter(filter).select(distinct: fieldName)) {
                return fields.map {
                    $0[fieldName]
                }
            } else {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName)")
                return []
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return []
    }
    
    
    
    /// 查找单个数据
    func querySingle(dbName: String, tableName: String, filter: Expression<Bool>) -> Row? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            do {
                let row = try db.pluck(dbModel.filter(filter))
                return row
            } catch let error {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> \(error.localizedDescription)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查找单个数据
    func querySingle(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>) -> Row? {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            do {
                let row = try db.pluck(dbModel.filter(filter1).filter(filter2))
                return row
            } catch let error {
                BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> \(error.localizedDescription)")
                return nil
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return nil
    }
    
    /// 查询数据个数
    func queryCount(dbName: String, tableName: String) -> Int {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            do {
                let count = try db.scalar(dbModel.count)
                return count
            } catch let error {
                BWSDKLog.shared.error("查询数据数量失败:\(dbName) -> \(tableName) -> \(error.localizedDescription)")
                return 0
            }
        }
        BWSDKLog.shared.error("查询数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return 0
    }
    
    /// 删除数据
    @discardableResult func deleteTable(dbName: String, tableName: String, filter: Expression<Bool>) -> Bool {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let _ = try? db.run(dbModel.filter(filter).delete()) {
                return true
            } else {
                BWSDKLog.shared.error("删除数据失败:\(dbName) -> \(tableName)")
                return false
            }
        }
        BWSDKLog.shared.error("删除数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return false
    }
    
    /// 根据2个条件删除数据
    @discardableResult func deleteTable(dbName: String, tableName: String, filter1: Expression<Bool>, filter2: Expression<Bool>) -> Bool {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let _ = try? db.run(dbModel.filter(filter1).filter(filter2).delete()) {
                return true
            } else {
                BWSDKLog.shared.error("删除数据失败:\(dbName) -> \(tableName)")
                return false
            }
        }
        BWSDKLog.shared.error("删除数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return false
    }
    
    /// 清空表中所有数据
    @discardableResult func clearTable(dbName: String, tableName: String) -> Bool {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let row = try? db.run(dbModel.delete()) {
                BWSDKLog.shared.info("清空数据成功\(row):\(dbName) -> \(tableName)")
                return true
            } else {
                BWSDKLog.shared.error("清空数据失败:\(dbName) -> \(tableName)")
                return false
            }
        }
        BWSDKLog.shared.error("清空数据失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return false
    }
    
    /// 删除指定表
    @discardableResult func dropTable(dbName: String, tableName: String) -> Bool {
        if let db = dbs[dbName] {
            let dbModel = Table(tableName)
            if let _ = try? db.run(dbModel.drop()) {
                BWSDKLog.shared.info("删除表成功:\(dbName) -> \(tableName)")
                return true
            } else {
                BWSDKLog.shared.error("删除表失败:\(dbName) -> \(tableName)")
                return false
            }
        }
        BWSDKLog.shared.error("删除表失败:\(dbName) -> \(tableName) -> 数据库未连接")
        return false
    }
}


extension BWDBManager {
    
    /// 转移老数据库数据
    func transferOldDB(sn: String, user: String) {
        let oldDBPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/BWDatabase/BWDatabase.sqlite"
        if FileManager.default.fileExists(atPath: oldDBPath) {
            BWSDKLog.shared.debug("存在3.1数据库")
            if let oldDB = try? Connection(oldDBPath) {
                let dbModel = Table("BWCamera")
                if let models = try? oldDB.prepare(dbModel.filter(DBColumn.oldCamSNPhone == sn+user)) {
                    models.forEach {
                        let cam = BWDevice()
                        cam.mac = $0[DBColumn.oldCamDID]
                        cam.ID = (cam.mac ?? "").hash
                        cam.type = ProductType.Camera.rawValue
                        cam.attr = DeviceAttr.Camera.rawValue
                        cam.name = $0[DBColumn.oldCamName]
                        cam.hardVersion = $0[DBColumn.oldCamUser]
                        cam.softVersion = $0[DBColumn.oldCamPwd]
                        BWSDKLog.shared.debug("将老数据库相机信息上传服务器:\(sn+user) -> \(cam)")
                        guard let msg = ObjectMSG.addCAM(info: [
                            "type": 1,
                            "sn": sn,
                            "devId": cam.mac ?? "",
                            "devUsername": cam.hardVersion ?? "",
                            "devPwd": cam.softVersion ?? "",
                            "devName": cam.name ?? "",
                            "roomId": -1
                        ]) else {
                            return
                        }
                        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
                            if json["status"].intValue == 0 {
                                cam.save()
                                // 插入排序信息
                                let sort = BWDeviceSort()
                                sort.belongId = cam.ID ?? -1
                                sort.sortId = sortRebootId
                                sort.save()
                                let roomSort = BWDeviceRoomSort()
                                roomSort.belongId = cam.ID ?? -1
                                roomSort.sortId = sortRebootId
                                roomSort.save()
                                do {
                                    try oldDB.run(dbModel.filter(DBColumn.oldCamSNPhone == sn+user).filter(DBColumn.oldCamDID == cam.mac ?? "").delete())
                                    BWSDKLog.shared.debug("老数据库相机信息上传服务器成功，删除掉老数据:\(sn+user) -> \(cam)")
                                } catch let err {
                                    BWSDKLog.shared.debug("老数据库相机信息上传服务器成功，删除掉老数据失败:\(err.localizedDescription)")
                                }
                                BWDevice.needRefresh?()
                                BWCamera.oldCameraTransfer?(BWCamera.Transfer(device: cam))
                            }
                        })
                    }
                }
            }
        }
    }
}

