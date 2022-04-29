//
//  BWBaseModelEx.swift
//  BWKit
//
//  Created by yuhua on 2020/3/4.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import SQLite


/// 数据库字段
struct DBColumn {
    // 网关
    static let phone = Expression<String>("phone")
    static let sn = Expression<String>("sn")
    static let alias = Expression<String>("alias")
    static let privilege = Expression<Int>("privilege")
    // 数据版本
    static let module = Expression<String>("module")
    static let version = Expression<Int>("version")
    // 设备
    static let attr = Expression<String>("attr")
    static let type = Expression<String>("type")
    static let ID = Expression<Int>("ID")
    static let name = Expression<String>("name")
    static let hardVersion = Expression<String>("hardVersion")
    static let createTime = Expression<String>("createTime")
    static let mac = Expression<String>("mac")
    static let softVersion = Expression<String>("softVersion")
    static let model = Expression<String>("model")
    static let roomId = Expression<Int>("roomId")
    static let isNew = Expression<Bool>("isNew")
    // 场景
    static let deviceId = Expression<Int>("deviceId")
    static let delay = Expression<Int>("delay")
    static let intType = Expression<Int>("type")
    static let pictureId = Expression<Int>("pictureId")
    // 定时
    static let state = Expression<String>("state")
    static let date = Expression<String>("date")
    static let time = Expression<String>("time")
    static let repeatType = Expression<Int>("repeat")
    // 联动
    static let mode = Expression<Int>("mode")
    static let timer = Expression<String>("timer")
    // 房间
    // 指令
    static let belongId = Expression<Int>("belongId")
    static let sceneId = Expression<Int>("sceneId")
    static let zoneId = Expression<Int>("zoneId")
    static let deviceStatus = Expression<String>("deviceStatus")
    static let condition = Expression<Int>("condition")
    // 绑定报警器
    static let bindAlarm = Expression<Int>("bindAlarm")
    // 绑定猫眼
    static let bindCateye = Expression<String>("bindCateye")
    // 设备指令
    static let index = Expression<Int>("index")
    static let isStudy = Expression<Int>("isStudy")
    static let control = Expression<String>("control")
    static let back = Expression<String>("back")
    static let query = Expression<String>("query")
    // 父设备
    static let parentId = Expression<Int>("parentId")
    static let typeId = Expression<String>("typeId")
    // 排序
    static let sortId = Expression<Int>("sortId")
    // 空调网关分机号
    static let acGatewayId = Expression<Int>("acgateway_id")
    // 空调网关外机号
    static let acOutSideId = Expression<Int>("acoutside_id")
    
    // 老数据库字段
    static let oldCamName = Expression<String>("name")
    static let oldCamDID = Expression<String>("camID")
    static let oldCamUser = Expression<String>("userName")
    static let oldCamPwd = Expression<String>("userPwd")
    static let oldCamSNPhone = Expression<String>("sn_phone")
}


// MARK: 网关
/// 网关数据操作
extension BWGateway: BWBaseModelProtocol {
    
    /// 表名
    static let tableName = "gateway"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.phone)
            $0.column(DBColumn.sn)
            $0.column(DBColumn.alias)
            $0.column(DBColumn.privilege)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.commonDB)
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWGateway.tableName, values: [
            DBColumn.phone <- phone ?? "",
            DBColumn.sn <- sn ?? "",
            DBColumn.alias <- alias ?? "",
            DBColumn.privilege <- privilege ?? -1
        ])
    }
    
    /// 更新网关别名数据
    @discardableResult func update(alias: String) -> Bool {
        return BWDBManager.shared.updateTable(dbName: BWAppManager.shared.commonDB,
                                              tableName: BWGateway.tableName,
                                              filter: DBColumn.sn == BWAppManager.shared.loginGateway?.sn ?? "",
                                              values: [DBColumn.alias <- alias])
    }
    
    /// 查询当前登录用户本地网关数据----从数据库中查询
    @discardableResult public static func query() -> [BWGateway] {
        BWSDKLog.shared.debug("查询数据库网关列表")
        return query(dbName: BWAppManager.shared.commonDB) as! [BWGateway]
    }
    
    /// 查询指定用户网关数据
    @discardableResult public static func query(phone: String) -> [BWGateway] {
        BWSDKLog.shared.debug("查询数据库用户\(phone)网关列表")
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.commonDB, tableName: tableName, filter: DBColumn.phone == phone) {
            return values.map {
                BWGateway(phone: $0[DBColumn.phone],
                          sn: $0[DBColumn.sn],
                          alias: $0[DBColumn.alias],
                          privilege: $0[DBColumn.privilege])
            }
        } else {
            return []
        }
    }
    
    /// 查询当前登录用户下所有数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName, filter: DBColumn.phone == BWAppManager.shared.username ?? "") {
            return values.map {
                BWGateway(phone: $0[DBColumn.phone],
                          sn: $0[DBColumn.sn],
                          alias: $0[DBColumn.alias],
                          privilege: $0[DBColumn.privilege])
            }
        } else {
            return []
        }
    }
    
    /// 通过sn查找网关
    @discardableResult static func query(sn: String) -> BWGateway? {
        if let value = BWDBManager.shared.querySingle(dbName: BWAppManager.shared.commonDB,
                                                      tableName: tableName,
                                                      filter1: DBColumn.sn == sn,
                                                      filter2: DBColumn.phone == BWAppManager.shared.username ?? "") {
            return BWGateway(phone: value[DBColumn.phone],
                             sn: value[DBColumn.sn],
                             alias: value[DBColumn.alias],
                             privilege: value[DBColumn.privilege])
        } else {
            return nil
        }
    }
    
    /// 检查该网关是否已经被当前登录用户绑定----从数据库中查询
    @discardableResult public func isExit() -> Bool {
        BWSDKLog.shared.debug("查询网关是否在数据库中存在")
        if let _ = BWGateway.query(sn: sn ?? "") {
            return true
        }
        return false
    }
    
    /// 根据主键删除数据，网关不需要该删除方式
    @discardableResult func delete(dbName: String) -> Bool {
        return false
    }
    
    /// 删除该手机下所有网关
    @discardableResult static func delete(phone: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.commonDB,
                                              tableName: tableName,
                                              filter: DBColumn.phone == phone)
    }
    
    /// 删除该手机下指定网关
    @discardableResult static func delete(phone: String, sn: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.commonDB,
                                              tableName: tableName,
                                              filter1: DBColumn.phone == phone,
                                              filter2: DBColumn.sn == sn)
    }
    
    /// 构建网关数据库
    static func createGatewayDB(dbName: String) {
        BWDBManager.shared.connectDB(dbName: dbName)
        BWModuleVersion.creatTable(dbName: dbName)
        BWDevice.creatTable(dbName: dbName)
        BWScene.creatTable(dbName: dbName)
        BWTimer.creatTable(dbName: dbName)
        BWLinkage.creatTable(dbName: dbName)
        BWRoom.creatTable(dbName: dbName)
        BWSceneInstruct.creatTable(dbName: dbName)
        BWTimerInstruct.creatTable(dbName: dbName)
        BWLinkageInstruct.creatTable(dbName: dbName)
        BWLinkageOrigin.creatTable(dbName: dbName)
        BWDeviceCMD.creatTable(dbName: dbName)
        BWDeviceSort.creatTable(dbName: dbName)
        BWDeviceRoomSort.creatTable(dbName: dbName)
        BWRoomSort.creatTable(dbName: dbName)
        BWLinkageSort.creatTable(dbName: dbName)
        BWSceneSort.creatTable(dbName: dbName)
        BWTimerSort.creatTable(dbName: dbName)
        BWDBManager.shared.sortOldOrderData(dbName: dbName)
    }
}


// MARK: 版本
/// 数据版本数据操作
extension BWModuleVersion: BWBaseModelProtocol {
    
    /// 表名
    static let tableName = "module"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.module, primaryKey: true)
            $0.column(DBColumn.version)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWModuleVersion.tableName, values: [
            DBColumn.module <- module ?? "",
            DBColumn.version <- version ?? -1
        ])
    }
    
    /// 查询数据
    @discardableResult static func query() -> [BWModuleVersion] {
        return query(dbName: BWAppManager.shared.loginGWDBName()) as! [BWModuleVersion]
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                BWModuleVersion(module: $0[DBColumn.module],
                                version: $0[DBColumn.version])
            }
        } else {
            return []
        }
    }
    
    /// 版本信息不需要该方法
    @discardableResult func delete(dbName: String) -> Bool {
        return false
    }
}


// MARK: 设备
/// 设备数据操作
extension BWDevice: BWBaseModelProtocol {
    
    /// 表名
    static let tableName = "device"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.ID, primaryKey: true)
            $0.column(DBColumn.attr)
            $0.column(DBColumn.type)
            $0.column(DBColumn.name)
            $0.column(DBColumn.hardVersion)
            $0.column(DBColumn.createTime)
            $0.column(DBColumn.mac)
            $0.column(DBColumn.softVersion)
            $0.column(DBColumn.model)
            $0.column(DBColumn.roomId)
            $0.column(DBColumn.bindAlarm)
            $0.column(DBColumn.bindCateye)
            $0.column(DBColumn.parentId)
            $0.column(DBColumn.typeId)
            $0.column(DBColumn.isNew)
            $0.column(DBColumn.acGatewayId)
            $0.column(DBColumn.acOutSideId)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        // 保存排序
        let sort = BWDeviceSort()
        sort.belongId = ID
        sort.sortId = sortRebootId
        sort.save(or: .ignore)
        // 保存房间排序
        let roomSort = BWDeviceRoomSort()
        roomSort.belongId = ID
        roomSort.sortId = sortRebootId
        roomSort.save(or: .ignore)
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWDevice.tableName, values: [
            DBColumn.ID <- ID ?? -1,
            DBColumn.attr <- attr ?? "",
            DBColumn.type <- type ?? "",
            DBColumn.name <- name ?? "",
            DBColumn.hardVersion <- hardVersion ?? "",
            DBColumn.createTime <- createTime ?? "",
            DBColumn.mac <- mac ?? "",
            DBColumn.softVersion <- softVersion ?? "",
            DBColumn.model <- model ?? "",
            DBColumn.roomId <- roomId ?? -1,
            DBColumn.bindAlarm <- bindAlarm ?? -1,
            DBColumn.bindCateye <- bindCateye ?? "",
            DBColumn.parentId <- parentId ?? -1,
            DBColumn.typeId <- typeId ?? "",
            DBColumn.isNew <- isNew,
            DBColumn.acGatewayId <- acGatewayId ?? -1,
            DBColumn.acOutSideId <- acOutSideId ?? -1
        ])
    }
    
    /// 转移row成device
    static func ChangeRowToDevice(row: Row) -> BWDevice {
        return BWDevice(attr: row[DBColumn.attr],
                        type: row[DBColumn.type],
                        ID: row[DBColumn.ID],
                        name: row[DBColumn.name],
                        hardVersion: row[DBColumn.hardVersion],
                        createTime: row[DBColumn.createTime],
                        mac: row[DBColumn.mac],
                        softVersion: row[DBColumn.softVersion],
                        model: row[DBColumn.model],
                        roomId: row[DBColumn.roomId],
                        bindAlarm: row[DBColumn.bindAlarm],
                        bindCateye: row[DBColumn.bindCateye],
                        parentId: row[DBColumn.parentId],
                        typeId: row[DBColumn.typeId],
                        isNew: row[DBColumn.isNew],
                        acGatewayId: row[DBColumn.acGatewayId],
                        acOutSideId: row[DBColumn.acOutSideId])
    }
    
    /// 查询所有数据----数据库
    @discardableResult public static func queryAllDevice() -> [BWDevice] {
        BWSDKLog.shared.debug("查询数据库设备列表")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        return queryNoDTIR(dbName: BWAppManager.shared.loginGWDBName()) as! [BWDevice]
    }
    
    /// 查询所有数据，指定需要类型----数据库---新增
    /// - Parameters:
    ///   - types: 类型，空表示所有
    ///   - roomID: 房间ID，-1表示所有设备
    /// - Returns: 结果
    @discardableResult public static func queryAllDevice(types: [ProductType], roomID: Int) -> [BWDevice] {
        BWSDKLog.shared.debug("查询数据库设备列表，限制类型：\(types)")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        return queryNoDTIR(dbName: BWAppManager.shared.loginGWDBName(), types: types, roomID: roomID) as! [BWDevice]
    }
    
    
    /// 查询所有数据
    /// - Parameter handle: 通过回调返回
    public static func queryAllDevice(handle: @escaping ([BWDevice])->Void) {
        DispatchQueue.global().async {
            let devices = queryAllDevice()
            DispatchQueue.main.async {
                handle(devices)
            }
        }
    }
    
    
    /// 查询所有数据，types为空，表示查询所有---新增
    /// - Parameters:
    ///   - types: 要查询的类型，空表示所有可显示类型
    ///   - roomID: 房间ID，-1表示所有设备
    ///   - handle: 回调
    public static func queryAllDevice(types: [ProductType], roomID: Int, handle: @escaping ([BWDevice])->Void) {
        DispatchQueue.global().async {
            let devices = queryAllDevice(types: types, roomID: roomID)
            DispatchQueue.main.async {
                handle(devices)
            }
        }
    }
    
    
    /// 查询可设置权限设备列表
    public static func queryPermissionDevice() -> [BWDevice] {
        BWSDKLog.shared.debug("查询数据库可设置权限设备列表")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        return queryNoDTIRPermissionDevice(dbName: BWAppManager.shared.loginGWDBName()) as! [BWDevice]
    }
    
    /// 查询灯光遥控器能绑定的设备---灯光遥控器使用
    @discardableResult public static func queryLight() -> [BWDevice] {
        BWSDKLog.shared.debug("查询灯光")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        return query(type: .OnOffLight) + query(type: .OnOffOutput) + query(type: .MainsPowerOutlet)
    }
    
    /// 查询窗帘能绑定的设备---窗帘遥控器使用
    @discardableResult public static func queryCurtain() -> [BWDevice] {
        BWSDKLog.shared.debug("查询窗帘")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        return query(type: .WindowCoveringDevice)
    }
    
    /// 查询设备，过滤掉本体设备
    @discardableResult static func queryNoDTIR(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName,
                                                      tableName: tableName,
                                                      filter1: DBColumn.attr != DeviceAttr.IR.rawValue,
                                                      filter2: DBColumn.attr != DeviceAttr.DataTransport.rawValue,
                                                      filter3: DBColumn.attr != DeviceAttr.ACGatewayFather.rawValue,
                                                      filter4: DBColumn.attr != DeviceAttr.OnOffSwitch.rawValue,
                                                      filter5: DBColumn.attr != DeviceAttr.SceneController.rawValue,
                                                      filter6: DBColumn.attr != DeviceAttr.SoundAndLightAlarm.rawValue,
                                                      filter7: DBColumn.attr != DeviceAttr.WindowCoverController.rawValue,
                                                      joinTable: BWDeviceSort.tableName,
                                                      joinTableOn: DBColumn.belongId == Table(tableName)[DBColumn.ID],
                                                      sort: DBColumn.sortId) {
            return values.map {
                let device = BWDevice.ChangeRowToDevice(row: $0)
                if let roomID = device.roomId, roomID != -1, let roomName = BWRoom.query(ID: roomID)?.name {
                    device.roomName = roomName
                }
                return device
            }
        } else {
            return []
        }
    }
    
    /// 查询设备，过滤掉本体设备，同时指定要查询的类型和房间
    @discardableResult static func queryNoDTIR(dbName: String, types: [ProductType], roomID: Int) -> [BWBaseModelProtocol] {
        var filters = [
            DBColumn.attr != DeviceAttr.IR.rawValue,
            DBColumn.attr != DeviceAttr.DataTransport.rawValue,
            DBColumn.attr != DeviceAttr.ACGatewayFather.rawValue,
            DBColumn.attr != DeviceAttr.OnOffSwitch.rawValue,
            DBColumn.attr != DeviceAttr.SceneController.rawValue,
            DBColumn.attr != DeviceAttr.SoundAndLightAlarm.rawValue,
            DBColumn.attr != DeviceAttr.WindowCoverController.rawValue
        ]
        if !types.isEmpty {
            var or = Expression<Bool>(DBColumn.type == types.first!.rawValue)
            types[1 ..< types.count].forEach {
                or = or || Expression<Bool>(DBColumn.type == $0.rawValue)
            }
            filters.append(or)
        }
        if roomID != -1 {
            filters.append(DBColumn.roomId == roomID)
        }
        if let values = BWDBManager.shared.queryTable(dbName: dbName,
                                                      tableName: tableName,
                                                      filters: filters,
                                                      joinTable: BWDeviceSort.tableName,
                                                      joinTableOn: DBColumn.belongId == Table(tableName)[DBColumn.ID],
                                                      sort: DBColumn.sortId) {
            return values.map {
                let device = BWDevice.ChangeRowToDevice(row: $0)
                if let roomID = device.roomId, roomID != -1, let roomName = BWRoom.query(ID: roomID)?.name {
                    device.roomName = roomName
                }
                return device
            }
        } else {
            return []
        }
    }
    
    /// 查询权限设备，过滤掉本体设备
    @discardableResult static func queryNoDTIRPermissionDevice(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName,
                                                      tableName: tableName,
                                                      filters: [
                                                        /// 场景
                                                        DBColumn.attr != DeviceAttr.SceneController.rawValue,
                                                        /// 安防
                                                        DBColumn.attr != DeviceAttr.MotionSensor.rawValue,
                                                        DBColumn.attr != DeviceAttr.GasSensor.rawValue,
                                                        DBColumn.attr != DeviceAttr.FireSensor.rawValue,
                                                        DBColumn.attr != DeviceAttr.WaterSensor.rawValue,
                                                        DBColumn.attr != DeviceAttr.ContactSensor.rawValue,
                                                        DBColumn.attr != DeviceAttr.BoundarySensor.rawValue,
                                                        DBColumn.attr != DeviceAttr.DangerButton.rawValue,
                                                        DBColumn.attr != DeviceAttr.SoundAlarm.rawValue,
                                                        DBColumn.attr != DeviceAttr.LightAlarm.rawValue,
                                                        DBColumn.attr != DeviceAttr.SoundAndLightAlarm.rawValue,
                                                        /// 遥控器
                                                        DBColumn.attr != DeviceAttr.OnOffSwitch.rawValue,
                                                        DBColumn.attr != DeviceAttr.WindowCoverController.rawValue,
                                                        /// 父设备
                                                        DBColumn.attr != DeviceAttr.IR.rawValue,
                                                        DBColumn.attr != DeviceAttr.DataTransport.rawValue,
                                                        DBColumn.attr != DeviceAttr.ACGatewayFather.rawValue,
                                                      ],
                                                      joinTable: BWDeviceSort.tableName,
                                                      joinTableOn: DBColumn.belongId == Table(tableName)[DBColumn.ID],
                                                      sort: DBColumn.sortId) {
            return values.map {
                let device = BWDevice.ChangeRowToDevice(row: $0)
                if let roomID = device.roomId, roomID != -1, let roomName = BWRoom.query(ID: roomID)?.name {
                    device.roomName = roomName
                }
                return device
            }
        } else {
            return []
        }
    }
    
    
    /// 查询联动条件可用设备，界面需自行判断哪些设备是可以多选，哪些是单选
    @discardableResult public static func queryLinkageCondition() -> [BWDevice] {
        BWSDKLog.shared.debug("查询数据库联动条件设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        var result = [BWDevice]()
        BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
            result.append(contentsOf: BWDevice.query(type: .IasZone))
            result.append(contentsOf: BWDevice.query(type: .AirBox))
            result.append(contentsOf: BWDevice.query(type: .ZigbeeIO_I))
            result.append(contentsOf: BWDevice.query(type: .DoorLock))
            result.append(contentsOf: BWDevice.query(type: .TemperatureHumiditySensor))
            result.append(contentsOf: BWDevice.query(type: .Thermostat))
            result.append(contentsOf: BWDevice.query(type: .FloorHeatController))
            result.append(contentsOf: BWDevice.query(type: .NewWindController, model: "HV332", isModelEqual: false))
            result.append(contentsOf: BWDevice.query(type: .ACGateway, attr: .CentralAirCondition))
        }
        return result
    }
    
    /// 查询联动可执行设备，界面需自行判断哪些设备是可以多选，哪些是单选，需自行判断设备所属房间，由于某些特殊情况，可能会有房间ID存在，但是房间不存在的情况，所以，界面在判断其余设备时，需把这些设备放入其余设备中。
    @discardableResult public static func queryLinkageExeDevice() -> [BWDevice] {
        BWSDKLog.shared.debug("查询数据库联动结果设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        var result = [BWDevice]()
        BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
            result.append(contentsOf: BWDevice.query(type: .OnOffLight))
            result.append(contentsOf: BWDevice.query(type: .DimmableLight))
            result.append(contentsOf: BWDevice.query(type: .OnOffOutput))
            result.append(contentsOf: BWDevice.query(type: .WindowCoveringDevice))
            result.append(contentsOf: BWDevice.query(type: .MainsPowerOutlet))
            result.append(contentsOf: BWDevice.query(type: .AirCondition))
            result.append(contentsOf: BWDevice.query(type: .IR, attr: .IR, isAttrEqual: false))
            result.append(contentsOf: BWDevice.query(type: .DataTransport, attr: .DataTransport, isAttrEqual: false))
            result.append(contentsOf: BWDevice.query(type: .ZigbeeIO_O))
            result.append(contentsOf: BWDevice.query(type: .BackgroundMusic))
            result.append(contentsOf: BWDevice.query(type: .XWBackgroundMusic))
            result.append(contentsOf: BWDevice.query(type: .WindowLock))
            result.append(contentsOf: BWDevice.query(type: .Thermostat))
            result.append(contentsOf: BWDevice.query(type: .FloorHeatController))
            result.append(contentsOf: BWDevice.query(type: .NewWindController))
            result.append(contentsOf: BWDevice.query(type: .ACGateway, attr: .CentralAirCondition))
        }
        return result
    }
    
    /// 查询所有数据----分类好的数据，依次：照明、遮阳、智能门窗、电源、家电、暖通、安防、环境、门禁、接口、情景，没有数据的项目，内容为0
    @discardableResult public static func queryHandleTypeDevice() -> [[BWDevice]] {
        BWSDKLog.shared.debug("查询数据库设备列表--分组整理")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        var zms = [BWDevice]()
        var zys = [BWDevice]()
        var znmcs = [BWDevice]()
        var dys = [BWDevice]()
        var jds = [BWDevice]()
        var nts = [BWDevice]()
        var afs = [BWDevice]()
        var hjs = [BWDevice]()
        var mjs = [BWDevice]()
        var jks = [BWDevice]()
        var qjs = [BWDevice]()
        BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
            // 照明
            zms.append(contentsOf: BWDevice.query(type: .OnOffLight))
            zms.append(contentsOf: BWDevice.query(type: .DimmableLight))
            zms.append(contentsOf: BWDevice.query(type: .OnOffSwitch))
            // 窗帘
            zys.append(contentsOf: BWDevice.query(type: .WindowCoveringDevice))
            zys.append(contentsOf: BWDevice.query(type: .WindowCoveringController))
            // 智能门窗
            znmcs.append(contentsOf: BWDevice.query(type: .WindowLock))
            // 电源
            dys.append(contentsOf: BWDevice.query(type: .MainsPowerOutlet))
            dys.append(contentsOf: BWDevice.query(type: .OnOffOutput))
            // 家电
            jds.append(contentsOf: BWDevice.query(type: .AirCondition))
            jds.append(contentsOf: BWDevice.query(type: .IR, attr: .IR))
            jds.append(contentsOf: BWDevice.query(type: .BackgroundMusic))
            // 安防
            afs.append(contentsOf: BWDevice.query(type: .IasZone))
            afs.append(contentsOf: BWDevice.query(type: .WarningDevice))
            // 环境
            hjs.append(contentsOf: BWDevice.query(type: .AirBox))
            hjs.append(contentsOf: BWDevice.query(type: .AirQualitySensor))
            hjs.append(contentsOf: BWDevice.query(type: .HCHOSensor))
            hjs.append(contentsOf: BWDevice.query(type: .LightSensor))
            hjs.append(contentsOf: BWDevice.query(type: .TemperatureSensor))
            hjs.append(contentsOf: BWDevice.query(type: .TemperatureHumiditySensor))
            // 接口
            jks.append(contentsOf: BWDevice.query(type: .ZigbeeIO_I))
            jks.append(contentsOf: BWDevice.query(type: .ZigbeeIO_O))
            jks.append(contentsOf: BWDevice.query(type: .DataTransport, attr: .DataTransport))
            // 门锁
            mjs.append(contentsOf: BWDevice.query(type: .DoorLock))
            // 暖通
            nts.append(contentsOf: BWDevice.query(type: .Thermostat))
            nts.append(contentsOf: BWDevice.query(type: .FloorHeatController))
            nts.append(contentsOf: BWDevice.query(type: .NewWindController))
            nts.append(contentsOf: BWDevice.query(type: .ACGateway, attr: .ACGatewayFather))
            // 情景
            qjs.append(contentsOf: BWDevice.query(type: .SceneSelector))
            qjs.append(contentsOf: BWDevice.query(type: .RemoteController))
        }
        return [zms, zys, znmcs, dys, jds, nts, afs, hjs, mjs, jks, qjs]
    }
    
    /// 查询所有门锁
    @discardableResult public static func queryDoor() -> [BWDevice] {
        BWSDKLog.shared.debug("查询门锁总数")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        return BWDevice.query(type: .DoorLock)
    }
    
    /// 查询所有设备总数
    @discardableResult public static func queryTotalDeviceNumber() -> Int {
        BWSDKLog.shared.debug("查询数据库设备总数")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return 0
        }
        return BWDBManager.shared.queryTableTotal(dbName: BWAppManager.shared.loginGWDBName(),
                                                  tableName: tableName,
                                                  filter1: DBColumn.type != ProductType.XWBackgroundMusic.rawValue,
                                                  filter2: DBColumn.type != ProductType.Camera.rawValue,
                                                  filter3: DBColumn.type != ProductType.Cateye.rawValue,
                                                  distinct: DBColumn.parentId)
    }
    
    /// 查询所有指定属性数据
    @discardableResult static func query(attr: DeviceAttr) -> [BWDevice] {
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.attr == attr.rawValue) {
            return values.map {
                BWDevice.ChangeRowToDevice(row: $0)
            }
        } else {
            return []
        }
    }
    
    /// 查询所有指定类型数据
    @discardableResult static func query(type: ProductType) -> [BWDevice] {
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.type == type.rawValue) {
            return values.map {
                BWDevice.ChangeRowToDevice(row: $0)
            }
        } else {
            return []
        }
    }
    
    /// 查询指定类型设备
    @discardableResult public static func query(deviceType: ProductType) -> [BWDevice] {
        BWSDKLog.shared.debug("查询指定类型设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        return query(type: deviceType)
    }
    
    /// 查询指定attr类型设备
    @discardableResult public static func query(deviceAttr: DeviceAttr) -> [BWDevice] {
        BWSDKLog.shared.debug("查询指定属性设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        return query(attr: deviceAttr)
    }
    
    /// 查询所有指定类型+model数据
    @discardableResult static func query(type: ProductType, model: String, isModelEqual: Bool = true) -> [BWDevice] {
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter1: DBColumn.type == type.rawValue,
                                                      filter2: isModelEqual ? DBColumn.model == model : DBColumn.model != model) {
            return values.map {
                BWDevice.ChangeRowToDevice(row: $0)
            }
        } else {
            return []
        }
    }
    
    /// 查询所有指定类型+属性数据
    @discardableResult static func query(type: ProductType, attr: DeviceAttr, isAttrEqual: Bool = true) -> [BWDevice] {
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter1: DBColumn.type == type.rawValue,
                                                      filter2: isAttrEqual ? DBColumn.attr == attr.rawValue : DBColumn.attr != attr.rawValue) {
            return values.map {
                BWDevice.ChangeRowToDevice(row: $0)
            }
        } else {
            return []
        }
    }
    
    /// 查询所有指定类型+属性+父ID数据
    @discardableResult static func query(type: ProductType, attr: DeviceAttr, isAttrEqual: Bool = true, parenId: Int) -> [BWDevice] {
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter1: DBColumn.type == type.rawValue,
                                                      filter2: isAttrEqual ? DBColumn.attr == attr.rawValue : DBColumn.attr != attr.rawValue,
                                                      filter3: DBColumn.parentId == parenId) {
            return values.map {
                BWDevice.ChangeRowToDevice(row: $0)
            }
        } else {
            return []
        }
    }
    
    /// 通过父ID查询设备
    @discardableResult static func query(parentId: Int) -> [BWDevice] {
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.parentId == parentId) {
            return values.map {
                BWDevice.ChangeRowToDevice(row: $0)
            }
        } else {
            return []
        }
    }
    
    /// 查询有多少类型
    @discardableResult static func queryType() -> [ProductType] {
        return BWDBManager.shared.queryField(dbName: BWAppManager.shared.loginGWDBName(),
                                             tableName: tableName,
                                             fieldName: DBColumn.type).map {
                                                if let type = ProductType.init(rawValue: $0) {
                                                    return type
                                                } else {
                                                    return .Unknown
                                                }
        }
    }
    
    /// 透传和红外设备，通过自己查找出父设备，其余设备返回nil
    @discardableResult public func queryFatherDevice() -> BWDevice? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let value = BWDBManager.shared.querySingle(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: BWDevice.tableName,
                                                      filter1: DBColumn.parentId == parentId ?? -1,
                                                      filter2: DBColumn.attr == type ?? "") {
            return BWDevice.ChangeRowToDevice(row: value)
        } else {
            return nil
        }
    }
    
    /// 查询子设备--透传、红外、空调网关能够通过该方法查找该设备的子设备，其余设备调用返回空
    @discardableResult public func querySubDevice() -> [BWDevice] {
        BWSDKLog.shared.debug("查询子设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        if type == ProductType.DataTransport.rawValue, let ID = parentId {
            return BWDevice.query(type: .DataTransport, attr: .DataTransport, isAttrEqual: false, parenId: ID)
        } else if type == ProductType.IR.rawValue, let ID = parentId {
            return BWDevice.query(type: .IR, attr: .IR, isAttrEqual: false, parenId: ID)
        } else if type == ProductType.ACGateway.rawValue, let ID = parentId {
            return BWDevice.query(type: .ACGateway, attr: .CentralAirCondition, parenId: ID)
        }
        return []
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName,
                                                      tableName: tableName,
                                                      joinTable: BWDeviceSort.tableName,
                                                      joinTableOn: DBColumn.belongId == Table(tableName)[DBColumn.ID],
                                                      sort: DBColumn.sortId) {
            return values.map {
                BWDevice.ChangeRowToDevice(row: $0)
            }
        } else {
            return []
        }
    }
    
    
    /// 查询指定房间ID的设备总数
    /// - Parameter roomId: 房间ID，-1表示查询所有设备总数
    @discardableResult public static func queryDeviceNumber(roomId: Int) -> Int {
        BWSDKLog.shared.debug("查询数据库指定房间ID:\(roomId)的设备总数")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return 0
        }
        if roomId == -1 {
            return BWDBManager.shared.queryTableTotal(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter1: DBColumn.attr != DeviceAttr.IR.rawValue,
                                                      filter2: DBColumn.attr != DeviceAttr.DataTransport.rawValue,
                                                      filter3: DBColumn.attr != DeviceAttr.ACGatewayFather.rawValue,
                                                      filter4: DBColumn.attr != DeviceAttr.OnOffSwitch.rawValue,
                                                      filter5: DBColumn.attr != DeviceAttr.SceneController.rawValue,
                                                      filter6: DBColumn.attr != DeviceAttr.SoundAndLightAlarm.rawValue,
                                                      filter7: DBColumn.attr != DeviceAttr.WindowCoverController.rawValue
            )
        }
        return BWDBManager.shared.queryTableTotal(dbName: BWAppManager.shared.loginGWDBName(),
                                                  tableName: tableName,
                                                  filter1: DBColumn.roomId == roomId,
                                                  filter2: DBColumn.attr != DeviceAttr.IR.rawValue,
                                                  filter3: DBColumn.attr != DeviceAttr.DataTransport.rawValue,
                                                  filter4: DBColumn.attr != DeviceAttr.ACGatewayFather.rawValue,
                                                  filter5: DBColumn.attr != DeviceAttr.OnOffSwitch.rawValue,
                                                  filter6: DBColumn.attr != DeviceAttr.SceneController.rawValue,
                                                  filter7: DBColumn.attr != DeviceAttr.SoundAndLightAlarm.rawValue,
                                                  filter8: DBColumn.attr != DeviceAttr.WindowCoverController.rawValue
//                                                  filter4: DBColumn.attr != DeviceAttr.Cateye.rawValue
        )
    }
    
    /// 查找指定房间ID的设备----数据库
    /// - Parameter roomID: 房间ID
    /// - Parameter isEqual: 条件是等于还是不等于，即使该房间设备，或者不是该房间设备，房间管理时用，默认查询该房间设备
    @discardableResult public static func query(roomID: Int, isEqual: Bool = true) -> [BWDevice] {
        BWSDKLog.shared.debug("查询数据库指定房间ID:\(roomID)的所有设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter1: isEqual ? DBColumn.roomId == roomID : DBColumn.roomId != roomID,
                                                      filter2: DBColumn.attr != DeviceAttr.IR.rawValue,
                                                      filter3: DBColumn.attr != DeviceAttr.DataTransport.rawValue,
                                                      filter4: DBColumn.attr != DeviceAttr.ACGatewayFather.rawValue,
                                                      filter5: DBColumn.attr != DeviceAttr.OnOffSwitch.rawValue,
                                                      filter6: DBColumn.attr != DeviceAttr.SceneController.rawValue,
                                                      filter7: DBColumn.attr != DeviceAttr.SoundAndLightAlarm.rawValue,
                                                      filter8: DBColumn.attr != DeviceAttr.WindowCoverController.rawValue,
//                                                      filter9: DBColumn.attr != DeviceAttr.Cateye.rawValue,
                                                      joinTable: BWDeviceRoomSort.tableName,
                                                      joinTableOn: DBColumn.belongId == Table(tableName)[DBColumn.ID],
                                                      sort: DBColumn.sortId) {
            return values.map {
                let device = BWDevice.ChangeRowToDevice(row: $0)
                if let roomID = device.roomId, roomID != -1, let roomName = BWRoom.query(ID: roomID)?.name {
                    device.roomName = roomName
                }
                return device
            }
        } else {
            return []
        }
    }
    
    /// 查询指定房间ID的设备
    /// - Parameters:
    ///   - roomID: 房间ID
    ///   - isEqual: 条件
    ///   - handle: 返回设备
    public static func query(roomID: Int, isEqual: Bool = true, handle: @escaping ([BWDevice])->Void) {
        DispatchQueue.global().async {
            let devices = query(roomID: roomID, isEqual: isEqual)
            DispatchQueue.main.async {
                handle(devices)
            }
        }
    }
    
    /// 查询单个设备----数据库
    /// - Parameter deviceID: 设备ID
    @discardableResult public static func query(deviceID: Int) -> BWDevice? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let value = BWDBManager.shared.querySingle(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.ID == deviceID) {
            return BWDevice.ChangeRowToDevice(row: value)
        } else {
            return nil
        }
    }
    
    /// 通过mac地址查询设备
    @discardableResult static func query(mac: String) -> BWDevice? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let value = BWDBManager.shared.querySingle(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.mac == mac) {
            return BWDevice.ChangeRowToDevice(row: value)
        } else {
            return nil
        }
    }
    
    /// 更新设备
    @discardableResult func update() -> Bool {
        return BWDBManager.shared.updateTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWDevice.tableName,
                                              filter: DBColumn.ID == ID ?? -1,
                                              values: [
                                                DBColumn.name <- name ?? "",
                                                DBColumn.attr <- attr ?? "",
                                                DBColumn.roomId <- roomId ?? -1,
                                                DBColumn.bindAlarm <- bindAlarm ?? -1,
                                                DBColumn.bindCateye <- bindCateye ?? "",
                                                DBColumn.typeId <- typeId ?? "",
                                                DBColumn.isNew <- false])
    }
    
    /// 更新猫眼房间
    @discardableResult static func UpdateCateyeRoom(nid: String, roomId: Int) -> Bool {
        return BWDBManager.shared.updateTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.mac == nid,
                                              values: [
                                                DBColumn.roomId <- roomId
        ])
    }
    
    /// 更新设备版本信息
    @discardableResult func updateInfo() -> Bool {
        return BWDBManager.shared.updateTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWDevice.tableName,
                                              filter: DBColumn.ID == ID ?? -1,
                                              values: [
                                                DBColumn.softVersion <- softVersion ?? "",
                                                DBColumn.hardVersion <- hardVersion ?? "",
                                                DBColumn.model <- model ?? "",
                                                DBColumn.mac <- mac ?? ""])
    }
    
    /// 清空设备
    @discardableResult static func clear() -> Bool {
        return BWDevice.clearTable(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据ID删除设备，由于指令设置了外键，所以指令也会被删除
    @discardableResult static func delete(ID: Int) -> Bool {
        let dbName = BWAppManager.shared.loginGWDBName()
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: tableName,
                                              filter: DBColumn.ID == ID)
    }
    
    /// 删除某一类型设备
    @discardableResult static func delete(type: ProductType) ->Bool {
        let dbName = BWAppManager.shared.loginGWDBName()
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: tableName,
                                              filter: DBColumn.type == type.rawValue)
    }
    
    /// 根据父ID删除设备
    @discardableResult static func delete(parentId: Int) -> Bool {
        let dbName = BWAppManager.shared.loginGWDBName()
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: tableName,
                                              filter: DBColumn.parentId == parentId)
    }
    
    /// 删除自己
    @discardableResult func delete() -> Bool {
        return delete(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据主键删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: BWDevice.tableName,
                                              filter: DBColumn.ID == ID ?? -1)
    }
}


// MARK: 场景
/// 场景数据操作
extension BWScene: BWBaseModelProtocol {
    
    /// 表名
    static let tableName = "scene"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.ID, primaryKey: true)
            $0.column(DBColumn.name)
            $0.column(DBColumn.createTime)
            $0.column(DBColumn.roomId)
            $0.column(DBColumn.intType)
            $0.column(DBColumn.deviceId)
            $0.column(DBColumn.delay)
            $0.column(DBColumn.pictureId)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        let sort = BWSceneSort()
        sort.belongId = ID
        sort.sortId = sortRebootId
        sort.save(or: .ignore)
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWScene.tableName, values: [
            DBColumn.ID <- ID ?? -1,
            DBColumn.name <- name ?? "",
            DBColumn.createTime <- createTime ?? "",
            DBColumn.roomId <- roomId ?? -1,
            DBColumn.intType <- type ?? -1,
            DBColumn.deviceId <- deviceId ?? -1,
            DBColumn.delay <- delay ?? -1,
            DBColumn.pictureId <- pictureId ?? 0
        ])
    }
    
    /// 查询所有场景数据----数据库
    @discardableResult public static func query() -> [BWScene] {
        BWSDKLog.shared.debug("查询数据库场景列表")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        let scenes = query(dbName: BWAppManager.shared.loginGWDBName()) as! [BWScene]
        scenes.forEach {
            // 查出所有指令
            $0.instruct = BWSceneInstruct.query(sceneID: $0.ID!)
            // 查出指令对应的设备或场景
            $0.instruct?.forEach { instruct in
                if instruct.type == 0 {
                    instruct.device = BWDevice.query(deviceID: instruct.deviceId!)
                } else {
                    instruct.scene = BWScene.query(sceneID: instruct.sceneId!)
                }
            }
        }
        return scenes
    }
    
    /// 查询单个场景，通过设备ID
    @discardableResult public static func query(deviceId: Int) -> BWScene? {
        BWSDKLog.shared.debug("通过deviceid查询数据库场景")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let value = BWDBManager.shared.querySingle(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.deviceId == deviceId) {
            let scene = BWScene(ID: value[DBColumn.ID],
                                name: value[DBColumn.name],
                                roomId: value[DBColumn.roomId],
                                type: value[DBColumn.intType],
                                deviceId: value[DBColumn.deviceId],
                                createTime: value[DBColumn.createTime],
                                delay: value[DBColumn.delay],
                                pictureId: value[DBColumn.pictureId])
            // 查出所有指令
            scene.instruct = BWSceneInstruct.query(sceneID: scene.ID!)
            // 查出指令对应的设备或场景
            scene.instruct?.forEach { instruct in
                if instruct.type == 0 {
                    instruct.device = BWDevice.query(deviceID: instruct.deviceId!)
                } else {
                    instruct.scene = BWScene.query(sceneID: instruct.sceneId!)
                }
            }
            return scene
        }
        return nil
    }
    
    /// 检查场景是否存在
    /// - Parameter sceneName: 场景名
    @discardableResult public static func checkSceneExist(sceneName: String) -> Bool {
        BWSDKLog.shared.debug("查询场景是否存在")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return false
        }
        let count = BWDBManager.shared.queryTableTotal(dbName: BWAppManager.shared.loginGWDBName(),
                                                       tableName: tableName,
                                                       filter: DBColumn.name == sceneName)
        BWSDKLog.shared.debug("查询到场景 \(sceneName) 个数:\(count)")
        return count != 0
    }
    
    /// 查询场景
    /// - Parameter handle: 返回
    public static func query(handle: @escaping ([BWScene])->Void) {
        DispatchQueue.global().async {
            let scenes = query()
            DispatchQueue.main.async {
                handle(scenes)
            }
        }
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName,
                                                      tableName: tableName,
                                                      joinTable: BWSceneSort.tableName,
                                                      joinTableOn: DBColumn.belongId == Table(tableName)[DBColumn.ID],
                                                      sort: DBColumn.sortId) {
            return values.map {
                BWScene(ID: $0[DBColumn.ID],
                        name: $0[DBColumn.name],
                        roomId: $0[DBColumn.roomId],
                        type: $0[DBColumn.intType],
                        deviceId: $0[DBColumn.deviceId],
                        createTime: $0[DBColumn.createTime],
                        delay: $0[DBColumn.delay],
                        pictureId: $0[DBColumn.pictureId])
            }
        } else {
            return []
        }
    }
    
    /// 查询指定房间场景
    @discardableResult public static func query(roomId: Int) -> [BWScene] {
        BWSDKLog.shared.debug("查询数据库房间\(roomId)内场景列表")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.roomId == roomId) {
            return values.map {
                BWScene(ID: $0[DBColumn.ID],
                        name: $0[DBColumn.name],
                        roomId: $0[DBColumn.roomId],
                        type: $0[DBColumn.intType],
                        deviceId: $0[DBColumn.deviceId],
                        createTime: $0[DBColumn.createTime],
                        delay: $0[DBColumn.delay],
                        pictureId: $0[DBColumn.pictureId])
            }
        } else {
            return []
        }
    }
    
    /// 查询单个场景，如需同时查询指令，则设置queryInstruct为true
    @discardableResult public static func query(sceneID: Int, queryInstruct: Bool = false) -> BWScene? {
        BWSDKLog.shared.debug("查询数据库单个场景")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let value = BWDBManager.shared.querySingle(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.ID == sceneID) {
            if queryInstruct == false {
                return BWScene(ID: value[DBColumn.ID],
                               name: value[DBColumn.name],
                               roomId: value[DBColumn.roomId],
                               type: value[DBColumn.intType],
                               deviceId: value[DBColumn.deviceId],
                               createTime: value[DBColumn.createTime],
                               delay: value[DBColumn.delay],
                               pictureId: value[DBColumn.pictureId])
            } else {
                let scene = BWScene(ID: value[DBColumn.ID],
                                    name: value[DBColumn.name],
                                    roomId: value[DBColumn.roomId],
                                    type: value[DBColumn.intType],
                                    deviceId: value[DBColumn.deviceId],
                                    createTime: value[DBColumn.createTime],
                                    delay: value[DBColumn.delay],
                                    pictureId: value[DBColumn.pictureId])
                // 查出所有指令
                scene.instruct = BWSceneInstruct.query(sceneID: scene.ID!)
                // 查出指令对应的设备或场景
                scene.instruct?.forEach { instruct in
                    if instruct.type == 0 {
                        instruct.device = BWDevice.query(deviceID: instruct.deviceId!)
                    } else if instruct.type == 1 {
                        instruct.scene = BWScene.query(sceneID: instruct.sceneId!)
                    }
                }
                return scene
            }
        } else {
            return nil
        }
    }
    
    /// 查询场景总数量
    @discardableResult static func queryCount() -> Int {
        return BWDBManager.shared.queryCount(dbName: BWAppManager.shared.loginGWDBName(),
                                             tableName: tableName)
    }
    
    /// 清空场景
    @discardableResult static func clear() -> Bool {
        // 同时要清空场景的指令
        BWSceneInstruct.clear()
        return BWScene.clearTable(dbName: BWAppManager.shared.loginGWDBName())
    }
    
      /// 根据ID删除场景，由于指令设置了外键，所以指令也会被删除
      @discardableResult static func delete(ID: Int) -> Bool {
          return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                tableName: tableName,
                                                filter: DBColumn.ID == ID)
      }
      
      /// 更新场景
      @discardableResult func update() -> Bool {
          return BWDBManager.shared.updateTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                tableName: BWScene.tableName,
                                                filter: DBColumn.ID == ID ?? -1,
                                                values: [
                                                  DBColumn.name <- name ?? "",
                                                  DBColumn.roomId <- roomId ?? -1,
                                                  DBColumn.delay <- delay ?? -1,
                                                  DBColumn.pictureId <- pictureId ?? 0])
      }
    
    
    /// 删除自己
    @discardableResult func delete() -> Bool {
        return delete(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据主键删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: BWScene.tableName,
                                              filter: DBColumn.ID == ID ?? -1)
    }
}


// MARK: 定时
/// 定时数据操作
extension BWTimer: BWBaseModelProtocol {
    
    /// 表名
    static let tableName = "timer"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.ID, primaryKey: true)
            $0.column(DBColumn.name)
            $0.column(DBColumn.intType)
            $0.column(DBColumn.state)
            $0.column(DBColumn.date)
            $0.column(DBColumn.time)
            $0.column(DBColumn.repeatType)
            $0.column(DBColumn.createTime)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        let sort = BWTimerSort()
        sort.belongId = ID
        sort.sortId = sortRebootId
        sort.save(or: .ignore)
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWTimer.tableName, values: [
            DBColumn.ID <- ID ?? -1,
            DBColumn.name <- name ?? "",
            DBColumn.intType <- type ?? -1,
            DBColumn.state <- state ?? "",
            DBColumn.date <- date ?? "",
            DBColumn.time <- time ?? "",
            DBColumn.repeatType <- repeatType ?? -1,
            DBColumn.createTime <- createTime ?? "",
        ])
    }
    
    /// 检查定时是否存在
    /// - Parameter timeName: 定时名
    @discardableResult public static func checkTimeExist(timeName: String) -> Bool {
        BWSDKLog.shared.debug("查询定时是否存在")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return false
        }
        let count = BWDBManager.shared.queryTableTotal(dbName: BWAppManager.shared.loginGWDBName(),
                                                       tableName: tableName,
                                                       filter: DBColumn.name == timeName)
        BWSDKLog.shared.debug("查询到定时 \(timeName) 个数:\(count)")
        return count != 0
    }
    
    /// 查询所有定时数据----数据库
    @discardableResult public static func query() -> [BWTimer] {
        BWSDKLog.shared.debug("查询数据库定时列表")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        let timers = query(dbName: BWAppManager.shared.loginGWDBName()) as! [BWTimer]
        timers.forEach {
            // 查出所有指令
            $0.instruct = BWTimerInstruct.query(timerID: $0.ID!)
            // 查出指令对应设备或场景
            $0.instruct?.forEach { instruct in
                if instruct.type == 0 {
                    instruct.device = BWDevice.query(deviceID: instruct.deviceId!)
                } else {
                    instruct.scene = BWScene.query(sceneID: instruct.sceneId!)
                }
            }
        }
        return timers
    }
    
    
    /// 查询定时
    /// - Parameter handle: 回调
    public static func query(handle: @escaping ([BWTimer])->Void) {
        DispatchQueue.global().async {
            let timers = query()
            DispatchQueue.main.async {
                handle(timers)
            }
        }
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName,
                                                      tableName: tableName,
                                                      joinTable: BWTimerSort.tableName,
                                                      joinTableOn: DBColumn.belongId == Table(tableName)[DBColumn.ID],
                                                      sort: DBColumn.sortId) {
            return values.map {
                BWTimer(ID: $0[DBColumn.ID],
                        name: $0[DBColumn.name],
                        type: $0[DBColumn.intType],
                        state: $0[DBColumn.state],
                        date: $0[DBColumn.date],
                        time: $0[DBColumn.time],
                        repeatType: $0[DBColumn.repeatType],
                        createTime: $0[DBColumn.createTime])
            }
        } else {
            return []
        }
    }
    
    /// 通过ID查询单个定时信息
    @discardableResult public static func query(ID: Int, queryInstruct: Bool = false) -> BWTimer? {
        BWSDKLog.shared.debug("查询数据库单个定时")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let value = BWDBManager.shared.querySingle(dbName: BWAppManager.shared.loginGWDBName(),
                                       tableName: tableName,
                                       filter: DBColumn.ID == ID) {
            if queryInstruct == false {
                return BWTimer(ID: value[DBColumn.ID],
                               name: value[DBColumn.name],
                               type: value[DBColumn.intType],
                               state: value[DBColumn.state],
                               date: value[DBColumn.date],
                               time: value[DBColumn.time],
                               repeatType: value[DBColumn.repeatType],
                               createTime: value[DBColumn.createTime])
            } else {
                let timer = BWTimer(ID: value[DBColumn.ID],
                                    name: value[DBColumn.name],
                                    type: value[DBColumn.intType],
                                    state: value[DBColumn.state],
                                    date: value[DBColumn.date],
                                    time: value[DBColumn.time],
                                    repeatType: value[DBColumn.repeatType],
                                    createTime: value[DBColumn.createTime])
                // 查出所有指令
                timer.instruct = BWTimerInstruct.query(timerID: timer.ID!)
                // 查出指令对应设备或场景
                timer.instruct?.forEach { instruct in
                    if instruct.type == 0 {
                        instruct.device = BWDevice.query(deviceID: instruct.deviceId!)
                    } else {
                        instruct.scene = BWScene.query(sceneID: instruct.sceneId!)
                    }
                }
                return timer
            }
        } else {
            return nil
        }
    }
    
    /// 清空定时
    @discardableResult static func clear() -> Bool {
        // 同时要清空定时的指令
        BWTimerInstruct.clear()
        return BWTimer.clearTable(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据ID删除定时，由于指令设置了外键，所以指令也会被删除
    @discardableResult static func delete(ID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWTimer.tableName,
                                              filter: DBColumn.ID == ID)
    }
    
    /// 更新定时
    @discardableResult func update() -> Bool {
        return BWDBManager.shared.updateTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWTimer.tableName,
                                              filter: DBColumn.ID == ID ?? -1,
                                              values: [
                                                DBColumn.name <- name ?? "",
                                                DBColumn.intType <- type ?? -1,
                                                DBColumn.state <- state ?? "",
                                                DBColumn.date <- date ?? "",
                                                DBColumn.time <- time ?? "",
                                                DBColumn.repeatType <- repeatType ?? -1])
    }
    
    /// 删除自己
    @discardableResult func delete() -> Bool {
        return delete(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据主键删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: BWTimer.tableName,
                                              filter: DBColumn.ID == ID ?? -1)
    }
}


// MARK: 联动
/// 联动数据操作
extension BWLinkage: BWBaseModelProtocol {
    
    /// 表名
    static let tableName = "linkage"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.ID, primaryKey: true)
            $0.column(DBColumn.name)
            $0.column(DBColumn.state)
            $0.column(DBColumn.mode)
            $0.column(DBColumn.timer)
            $0.column(DBColumn.delay)
            $0.column(DBColumn.createTime)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        let sort = BWLinkageSort()
        sort.belongId = ID
        sort.sortId = sortRebootId
        sort.save(or: .ignore)
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWLinkage.tableName, values: [
            DBColumn.ID <- ID ?? -1,
            DBColumn.name <- name ?? "",
            DBColumn.state <- state ?? "",
            DBColumn.mode <- mode ?? -1,
            DBColumn.timer <- timer ?? "",
            DBColumn.delay <- delay ?? -1,
            DBColumn.createTime <- createTime ?? ""
        ])
    }
    
    /// 检查联动是否存在
     /// - Parameter linkageName: 联动名
     @discardableResult public static func checkLinkageExist(linkageName: String) -> Bool {
         BWSDKLog.shared.debug("查询联动是否存在")
         if BWAppManager.shared.loginGateway == nil {
             BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
             return false
         }
         let count = BWDBManager.shared.queryTableTotal(dbName: BWAppManager.shared.loginGWDBName(),
                                                        tableName: tableName,
                                                        filter: DBColumn.name == linkageName)
         BWSDKLog.shared.debug("查询到联动 \(linkageName) 个数:\(count)")
         return count != 0
     }
    
    /// 查询所有联动数据----数据库
    @discardableResult public static func query() -> [BWLinkage] {
        BWSDKLog.shared.debug("查询数据库联动列表")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        let linkages = query(dbName: BWAppManager.shared.loginGWDBName()) as! [BWLinkage]
        linkages.forEach {
            // 查出所有条件
            $0.linkageOrigin = BWLinkageOrigin.query(linkageID: $0.ID!)
            // 查出所有条件设备
            $0.linkageOrigin?.forEach { origin in
                origin.device = BWDevice.query(deviceID: origin.deviceId!)
            }
            // 查出所有指令
            $0.linkInstruct = BWLinkageInstruct.query(linkageID: $0.ID!)
            // 查出指令对应的设备或场景
            $0.linkInstruct?.forEach { instruct in
                if instruct.type == 0 {
                    instruct.device = BWDevice.query(deviceID: instruct.deviceId!)
                } else {
                    instruct.scene = BWScene.query(sceneID: instruct.sceneId!)
                }
            }
        }
        return linkages
    }
    
    
    /// 查询联动
    /// - Parameter handle: 回调
    public static func query(handle: @escaping ([BWLinkage])->Void) {
        DispatchQueue.global().async {
            let linkages = query()
            DispatchQueue.main.async {
                handle(linkages)
            }
        }
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName,
                                                      tableName: tableName,
                                                      joinTable: BWLinkageSort.tableName,
                                                      joinTableOn: DBColumn.belongId == Table(tableName)[DBColumn.ID],
                                                      sort: DBColumn.sortId) {
            return values.map {
                BWLinkage(ID: $0[DBColumn.ID],
                          name: $0[DBColumn.name],
                          state: $0[DBColumn.state],
                          mode: $0[DBColumn.mode],
                          timer: $0[DBColumn.timer],
                          delay: $0[DBColumn.delay],
                          createTime: $0[DBColumn.createTime])
            }
        } else {
            return []
        }
    }
    
    /// 通过ID查询单个联动信息，包含内部设备信息----外部使用
    @discardableResult public static func query(linkageID: Int) -> BWLinkage? {
        BWSDKLog.shared.debug("查询数据库单个联动信息:\(linkageID)")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let value = BWDBManager.shared.querySingle(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.ID == linkageID) {
            let linkage = BWLinkage(ID: value[DBColumn.ID],
                                     name: value[DBColumn.name],
                                     state: value[DBColumn.state],
                                     mode: value[DBColumn.mode],
                                     timer: value[DBColumn.timer],
                                     delay: value[DBColumn.delay],
                                     createTime: value[DBColumn.createTime])
            // 查出所有条件
            linkage.linkageOrigin = BWLinkageOrigin.query(linkageID: linkage.ID!)
            // 查出所有条件设备
            linkage.linkageOrigin?.forEach { origin in
                origin.device = BWDevice.query(deviceID: origin.deviceId!)
            }
            // 查出所有指令
            linkage.linkInstruct = BWLinkageInstruct.query(linkageID: linkage.ID!)
            // 查出指令对应的设备或场景
            linkage.linkInstruct?.forEach { instruct in
                if instruct.type == 0 {
                    instruct.device = BWDevice.query(deviceID: instruct.deviceId!)
                } else {
                    instruct.scene = BWScene.query(sceneID: instruct.sceneId!)
                }
            }
            return linkage
        } else {
            return nil
        }
    }
    
    /// 通过ID查询单个联动信息----内部使用
    @discardableResult static func query(ID: Int) -> BWLinkage? {
        if let value = BWDBManager.shared.querySingle(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.ID == ID) {
            return BWLinkage(ID: value[DBColumn.ID],
                             name: value[DBColumn.name],
                             state: value[DBColumn.state],
                             mode: value[DBColumn.mode],
                             timer: value[DBColumn.timer],
                             delay: value[DBColumn.delay],
                             createTime: value[DBColumn.createTime])
        } else {
            return nil
        }
    }
    
    /// 清空联动
    @discardableResult static func clear() -> Bool {
        // 同时要清空联动的指令
        BWLinkageInstruct.clear()
        BWLinkageOrigin.clear()
        return BWLinkage.clearTable(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据ID删除联动，由于指令设置了外键，所以指令也会被删除
    @discardableResult static func delete(ID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.ID == ID)
    }
    
    /// 更新联动
    @discardableResult func update() -> Bool {
        return BWDBManager.shared.updateTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: BWLinkage.tableName,
                                              filter: DBColumn.ID == ID ?? -1,
                                              values: [
                                                DBColumn.name <- name ?? "",
                                                DBColumn.state <- state ?? "",
                                                DBColumn.mode <- mode ?? -1,
                                                DBColumn.timer <- timer ?? "",
                                                DBColumn.delay <- delay ?? -1])
    }
    
    /// 删除自己
    @discardableResult func delete() -> Bool {
        return delete(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据主键删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: BWLinkage.tableName,
                                              filter: DBColumn.ID == ID ?? -1)
    }
}


// MARK: 房间
/// 房间数据操作
extension BWRoom: BWBaseModelProtocol {
    
    /// 表名
    static let tableName = "room"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.ID, primaryKey: true)
            $0.column(DBColumn.name)
            $0.column(DBColumn.createTime)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        let sort = BWRoomSort()
        sort.belongId = ID
        sort.sortId = sortRebootId
        sort.save(or: .ignore)
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWRoom.tableName, values: [
            DBColumn.ID <- ID ?? -1,
            DBColumn.name <- name ?? "",
            DBColumn.createTime <- createTime ?? "",
        ])
    }
    
    /// 房间ID
    public typealias BWSDKRoomID = Int
    /// 排序ID
    public typealias BWSDKSortID = Int
    
    /// 查询所有房间排序ID，当所有设备也纳入排序时，需要查询出排序ID，其中房间ID为-1的房间时所有设备，自行进行排序，排序ID为5000则表示为默认排序。
    public static func QueryRoomSortedId() -> [BWSDKRoomID: BWSDKSortID] {
        BWSDKLog.shared.debug("查询房间排序ID")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return [:]
        }
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: BWRoomSort.tableName) {
            var result = [BWSDKRoomID: BWSDKSortID]()
            values.forEach {
                result[$0[DBColumn.belongId]] = $0[DBColumn.sortId]
            }
            return result
        } else {
            return [:]
        }
    }
    
    /// 查询指定房间所有设备的类型
    public static func QueryRoomDeviceTypes(roomID: Int) -> [String] {
        BWSDKLog.shared.debug("查询房间设备类型")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        var filters = DBColumn.attr != DeviceAttr.IR.rawValue &&
            DBColumn.attr != DeviceAttr.DataTransport.rawValue &&
            DBColumn.attr != DeviceAttr.ACGatewayFather.rawValue &&
            DBColumn.attr != DeviceAttr.OnOffSwitch.rawValue &&
            DBColumn.attr != DeviceAttr.SceneController.rawValue &&
            DBColumn.attr != DeviceAttr.SoundAndLightAlarm.rawValue &&
            DBColumn.attr != DeviceAttr.WindowCoverController.rawValue
        if roomID != -1 {
            filters = filters && (DBColumn.roomId == roomID)
        }
        return BWDBManager.shared.queryField(dbName: BWAppManager.shared.loginGWDBName(),
                                             tableName: BWDevice.tableName,
                                             fieldName: DBColumn.type,
                                             filter: filters)
    }
    
    /// 检查房间是否存在
    /// - Parameter roomName: 房间名
    @discardableResult public static func checkRoomExist(roomName: String) -> Bool {
        BWSDKLog.shared.debug("查询房间是否存在")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return false
        }
        let count = BWDBManager.shared.queryTableTotal(dbName: BWAppManager.shared.loginGWDBName(),
                                                  tableName: tableName,
                                                  filter: DBColumn.name == roomName)
        BWSDKLog.shared.debug("查询到房间 \(roomName) 个数:\(count)")
        return count != 0
    }
    
    /// 查询所有房间数据----数据库
    @discardableResult public static func query() -> [BWRoom] {
        BWSDKLog.shared.debug("查询数据库房间列表")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        return query(dbName: BWAppManager.shared.loginGWDBName()) as! [BWRoom]
    }
    
    
    /// 查询所有房间
    /// - Parameter handle: 回调
    public static func query(handle: @escaping ([BWRoom])->Void) {
        DispatchQueue.global().async {
            let rooms = query()
            DispatchQueue.main.async {
                handle(rooms)
            }
        }
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName,
                                                      tableName: tableName,
                                                      joinTable: BWRoomSort.tableName,
                                                      joinTableOn: DBColumn.belongId == Table(tableName)[DBColumn.ID],
                                                      sort: DBColumn.sortId) {
            return values.map {
                BWRoom(ID: $0[DBColumn.ID],
                       name: $0[DBColumn.name],
                       createTime: $0[DBColumn.createTime])
            }
        } else {
            return []
        }
    }
    
    /// 通过房间ID查找房间----数据库
    /// - Parameter ID: 房间ID
    @discardableResult public static func query(ID: Int) -> BWRoom? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let value = BWDBManager.shared.querySingle(dbName: BWAppManager.shared.loginGWDBName(),
                                                       tableName: tableName,
                                                       filter: DBColumn.ID == ID) {
            return BWRoom(ID: value[DBColumn.ID],
                          name: value[DBColumn.name],
                          createTime: value[DBColumn.createTime])
        } else {
            return nil
        }
    }
    
    /// 清空房间
    @discardableResult static func clear() -> Bool {
        return BWRoom.clearTable(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据ID删除房间
    @discardableResult static func delete(ID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.ID == ID)
    }
    
    /// 删除自己
    @discardableResult func delete() -> Bool {
        return delete(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据主键删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: BWRoom.tableName,
                                              filter: DBColumn.ID == ID ?? -1)
    }
}

// MARK: 指令
extension BWSceneInstruct: BWBaseModelProtocol {
    /// 表名
    static let tableName = "sceneInstruct"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.ID)
            $0.column(DBColumn.belongId)
            $0.column(DBColumn.intType)
            $0.column(DBColumn.deviceId)
            $0.column(DBColumn.sceneId)
            $0.column(DBColumn.zoneId)
            $0.column(DBColumn.delay)
            $0.column(DBColumn.deviceStatus)
            $0.foreignKey(DBColumn.belongId, references: Table(BWScene.tableName), DBColumn.ID, delete: .cascade)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWSceneInstruct.tableName, values: [
            DBColumn.belongId <- belongId ?? -1,
            DBColumn.ID <- ID ?? -1,
            DBColumn.intType <- type ?? -1,
            DBColumn.deviceId <- deviceId ?? -1,
            DBColumn.sceneId <- sceneId ?? -1,
            DBColumn.zoneId <- zoneId ?? -1,
            DBColumn.delay <- delay ?? -1,
            DBColumn.deviceStatus <- deviceStatus ?? "",
        ])
    }
    
    /// 查询所有数据
    @discardableResult static func query() -> [BWSceneInstruct] {
        return query(dbName: BWAppManager.shared.loginGWDBName()) as! [BWSceneInstruct]
    }
    
    /// 查询指定场景ID指令
    @discardableResult static func query(sceneID: Int) -> [BWSceneInstruct] {
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.belongId == sceneID) {
            return values.map {
                BWSceneInstruct(ID: $0[DBColumn.ID],
                                type: $0[DBColumn.intType],
                                deviceId: $0[DBColumn.deviceId],
                                sceneId: $0[DBColumn.sceneId],
                                zoneId: $0[DBColumn.zoneId],
                                delay: $0[DBColumn.delay],
                                deviceStatus: $0[DBColumn.deviceStatus],
                                belongId: $0[DBColumn.belongId])
            }
        } else {
            return []
        }
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                BWSceneInstruct(ID: $0[DBColumn.ID],
                                type: $0[DBColumn.intType],
                                deviceId: $0[DBColumn.deviceId],
                                sceneId: $0[DBColumn.sceneId],
                                zoneId: $0[DBColumn.zoneId],
                                delay: $0[DBColumn.delay],
                                deviceStatus: $0[DBColumn.deviceStatus],
                                belongId: $0[DBColumn.belongId])
            }
        } else {
            return []
        }
    }
    
    /// 清空场景指令
    @discardableResult static func clear() -> Bool {
        return clearTable(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 删除指定场景ID的指令
    @discardableResult static func delete(belongID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.belongId == belongID)
    }
    
    /// 通过设备ID删除自己
    @discardableResult static func delete(ID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.deviceId == ID)
    }
    
    /// 通过场景ID删除自己
    @discardableResult static func delete(sceneID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.sceneId == sceneID)
    }
    
    /// 删除自己
    @discardableResult func delete() -> Bool {
        return delete(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据主键删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: BWSceneInstruct.tableName,
                                              filter: DBColumn.ID == ID ?? -1)
    }
}

extension BWTimerInstruct: BWBaseModelProtocol {
    /// 表名
    static let tableName = "timerInstruct"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.ID)
            $0.column(DBColumn.belongId)
            $0.column(DBColumn.intType)
            $0.column(DBColumn.deviceId)
            $0.column(DBColumn.sceneId)
            $0.column(DBColumn.zoneId)
            $0.column(DBColumn.delay)
            $0.column(DBColumn.deviceStatus)
            $0.foreignKey(DBColumn.belongId, references: Table(BWTimer.tableName), DBColumn.ID, delete: .cascade)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWTimerInstruct.tableName, values: [
            DBColumn.belongId <- belongId ?? -1,
            DBColumn.ID <- ID ?? -1,
            DBColumn.intType <- type ?? -1,
            DBColumn.deviceId <- deviceId ?? -1,
            DBColumn.sceneId <- sceneId ?? -1,
            DBColumn.zoneId <- zoneId ?? -1,
            DBColumn.delay <- delay ?? -1,
            DBColumn.deviceStatus <- deviceStatus ?? ""
        ])
    }
    
    /// 查询所有数据
    @discardableResult static func query() -> [BWTimerInstruct] {
        return query(dbName: BWAppManager.shared.loginGWDBName()) as! [BWTimerInstruct]
    }
    
    /// 查询指定定时ID指令
    @discardableResult static func query(timerID: Int) -> [BWTimerInstruct] {
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.belongId == timerID) {
            return values.map {
                BWTimerInstruct(ID: $0[DBColumn.ID],
                                type: $0[DBColumn.intType],
                                deviceId: $0[DBColumn.deviceId],
                                sceneId: $0[DBColumn.sceneId],
                                zoneId: $0[DBColumn.zoneId],
                                delay: $0[DBColumn.delay],
                                deviceStatus: $0[DBColumn.deviceStatus],
                                belongId: $0[DBColumn.belongId])
            }
        } else {
            return []
        }
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                BWTimerInstruct(ID: $0[DBColumn.ID],
                                type: $0[DBColumn.intType],
                                deviceId: $0[DBColumn.deviceId],
                                sceneId: $0[DBColumn.sceneId],
                                zoneId: $0[DBColumn.zoneId],
                                delay: $0[DBColumn.delay],
                                deviceStatus: $0[DBColumn.deviceStatus],
                                belongId: $0[DBColumn.belongId])
            }
        } else {
            return []
        }
    }
    
    /// 清空定时指令
    @discardableResult static func clear() -> Bool {
        return clearTable(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 删除指定定时ID的指令
    @discardableResult static func delete(belongID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.belongId == belongID)
    }
    
    /// 通过设备ID删除自己
    @discardableResult static func delete(ID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.deviceId == ID)
    }
    
    /// 通过场景ID删除自己
    @discardableResult static func delete(sceneID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.sceneId == sceneID)
    }
    
    /// 删除自己
    @discardableResult func delete() -> Bool {
        return delete(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据主键删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: BWTimerInstruct.tableName,
                                              filter: DBColumn.ID == ID ?? -1)
    }
}

extension BWLinkageInstruct: BWBaseModelProtocol {
    /// 表名
    static let tableName = "linkageInstruct"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.ID)
            $0.column(DBColumn.belongId)
            $0.column(DBColumn.intType)
            $0.column(DBColumn.deviceId)
            $0.column(DBColumn.sceneId)
            $0.column(DBColumn.zoneId)
            $0.column(DBColumn.delay)
            $0.column(DBColumn.deviceStatus)
            $0.foreignKey(DBColumn.belongId, references: Table(BWLinkage.tableName), DBColumn.ID, delete: .cascade)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWLinkageInstruct.tableName, values: [
            DBColumn.belongId <- belongId ?? -1,
            DBColumn.ID <- ID ?? -1,
            DBColumn.intType <- type ?? -1,
            DBColumn.deviceId <- deviceId ?? -1,
            DBColumn.sceneId <- sceneId ?? -1,
            DBColumn.zoneId <- zoneId ?? -1,
            DBColumn.delay <- delay ?? -1,
            DBColumn.deviceStatus <- deviceStatus ?? "",
        ])
    }
    
    /// 查询所有数据
    @discardableResult static func query() -> [BWLinkageInstruct] {
        return query(dbName: BWAppManager.shared.loginGWDBName()) as! [BWLinkageInstruct]
    }
    
    /// 查询指定联动ID指令
    @discardableResult static func query(linkageID: Int) -> [BWLinkageInstruct] {
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.belongId == linkageID) {
            return values.map {
                BWLinkageInstruct(ID: $0[DBColumn.ID],
                                  type: $0[DBColumn.intType],
                                  deviceId: $0[DBColumn.deviceId],
                                  sceneId: $0[DBColumn.sceneId],
                                  zoneId: $0[DBColumn.zoneId],
                                  delay: $0[DBColumn.delay],
                                  deviceStatus: $0[DBColumn.deviceStatus],
                                  belongId: $0[DBColumn.belongId])
            }
        } else {
            return []
        }
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                BWLinkageInstruct(ID: $0[DBColumn.ID],
                                  type: $0[DBColumn.intType],
                                  deviceId: $0[DBColumn.deviceId],
                                  sceneId: $0[DBColumn.sceneId],
                                  zoneId: $0[DBColumn.zoneId],
                                  delay: $0[DBColumn.delay],
                                  deviceStatus: $0[DBColumn.deviceStatus],
                                  belongId: $0[DBColumn.belongId])
            }
        } else {
            return []
        }
    }
    
    /// 清空联动指令
    @discardableResult static func clear() -> Bool {
        return clearTable(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 删除指定联动ID的指令
    @discardableResult static func delete(belongID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.belongId == belongID)
    }
    
    /// 通过设备ID删除自己
    @discardableResult static func delete(ID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.deviceId == ID)
    }
    
    /// 通过场景ID删除自己
    @discardableResult static func delete(sceneID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.sceneId == sceneID)
    }
    
    /// 删除自己
    @discardableResult func delete() -> Bool {
        return delete(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据主键删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: BWLinkageInstruct.tableName,
                                              filter: DBColumn.ID == ID ?? -1)
    }
}

extension BWLinkageOrigin: BWBaseModelProtocol {
    
    /// 表名
    static let tableName = "linkageOrigin"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.deviceId)
            $0.column(DBColumn.belongId)
            $0.column(DBColumn.condition)
            $0.column(DBColumn.deviceStatus)
            $0.foreignKey(DBColumn.belongId, references: Table(BWLinkage.tableName), DBColumn.ID, delete: .cascade)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWLinkageOrigin.tableName, values: [
            DBColumn.deviceId <- deviceId ?? -1,
            DBColumn.condition <- condition ?? -1,
            DBColumn.deviceStatus <- deviceStatus ?? "",
            DBColumn.belongId <- belongId ?? -1
        ])
    }
    
    /// 查询所有数据
    @discardableResult static func query() -> [BWLinkageOrigin] {
        return query(dbName: BWAppManager.shared.loginGWDBName()) as! [BWLinkageOrigin]
    }
    
    /// 查询指定联动ID指令
    @discardableResult static func query(linkageID: Int) -> [BWLinkageOrigin] {
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.belongId == linkageID) {
            return values.map {
                BWLinkageOrigin(deviceId: $0[DBColumn.deviceId],
                                condition: $0[DBColumn.condition],
                                deviceStatus: $0[DBColumn.deviceStatus],
                                belongId: $0[DBColumn.belongId])
            }
        } else {
            return []
        }
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                BWLinkageOrigin(deviceId: $0[DBColumn.deviceId],
                                condition: $0[DBColumn.condition],
                                deviceStatus: $0[DBColumn.deviceStatus],
                                belongId: $0[DBColumn.belongId])
            }
        } else {
            return []
        }
    }
    
    /// 清空条件
    @discardableResult static func clear() -> Bool {
        return BWLinkageOrigin.clearTable(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 删除指定联动ID的指令
    @discardableResult static func delete(belongID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.belongId == belongID)
    }
    
    /// 通过设备ID删除自己
    @discardableResult static func delete(ID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.deviceId == ID)
    }
    
    /// 删除自己
    @discardableResult func delete() -> Bool {
        return delete(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 根据主键删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: dbName,
                                              tableName: BWLinkageOrigin.tableName,
                                              filter: DBColumn.deviceId == deviceId ?? -1)
    }
}


extension BWDeviceCMD: BWBaseModelProtocol {
    
    /// 表名
    static let tableName = "deviceCMD"
    
    /// 创建表
    @discardableResult static func creatTable(dbName: String) -> Bool {
        return BWDBManager.shared.createTable(dbName: dbName, tableName: tableName) {
            $0.column(DBColumn.belongId)
            $0.column(DBColumn.name)
            $0.column(DBColumn.index)
            $0.column(DBColumn.isStudy)
            $0.column(DBColumn.control)
            $0.column(DBColumn.back)
            $0.column(DBColumn.query)
            $0.column(DBColumn.delay)
            $0.foreignKey(DBColumn.belongId, references: Table(BWDevice.tableName), DBColumn.ID, delete: .cascade)
        }
    }
    
    /// 保存数据，如果已存在，则是更新数据。
    @discardableResult func save() -> Bool {
        return save(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 保存数据，如果数据主键存在，则是更新数据。
    @discardableResult func save(dbName: String) -> Bool {
        return BWDBManager.shared.insertTable(dbName: dbName, tableName: BWDeviceCMD.tableName, values: [
            DBColumn.belongId <- belongId ?? -1,
            DBColumn.name <- name ?? "",
            DBColumn.index <- index ?? -1,
            DBColumn.isStudy <- isStudy ?? -1,
            DBColumn.control <- control ?? "",
            DBColumn.back <- back ?? "",
            DBColumn.query <- query ?? "",
            DBColumn.delay <- delay ?? -1
        ])
    }
    
    /// 查询所有数据
    @discardableResult static func query() -> [BWDeviceCMD] {
        return query(dbName: BWAppManager.shared.loginGWDBName()) as! [BWDeviceCMD]
    }
    
    /// 查询指定设备ID指令
    @discardableResult public static func query(deviceID: Int) -> [BWDeviceCMD] {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        if let values = BWDBManager.shared.queryTable(dbName: BWAppManager.shared.loginGWDBName(),
                                                      tableName: tableName,
                                                      filter: DBColumn.belongId == deviceID) {
            return values.map {
                BWDeviceCMD(belongId: $0[DBColumn.belongId],
                            name: $0[DBColumn.name],
                            index: $0[DBColumn.index],
                            isStudy: $0[DBColumn.isStudy],
                            control: $0[DBColumn.control],
                            back: $0[DBColumn.back],
                            query: $0[DBColumn.query],
                            delay: $0[DBColumn.delay])
            }
        } else {
            return []
        }
    }
    
    /// 查询数据
    @discardableResult static func query(dbName: String) -> [BWBaseModelProtocol] {
        if let values = BWDBManager.shared.queryTable(dbName: dbName, tableName: tableName) {
            return values.map {
                BWDeviceCMD(belongId: $0[DBColumn.belongId],
                            name: $0[DBColumn.name],
                            index: $0[DBColumn.index],
                            isStudy: $0[DBColumn.isStudy],
                            control: $0[DBColumn.control],
                            back: $0[DBColumn.back],
                            query: $0[DBColumn.query],
                            delay: $0[DBColumn.delay])
            }
        } else {
            return []
        }
    }
    
    /// 清空指令
    @discardableResult static func clear() -> Bool {
        return BWDeviceCMD.clearTable(dbName: BWAppManager.shared.loginGWDBName())
    }
    
    /// 删除指定设备ID的指令
    @discardableResult static func delete(belongID: Int) -> Bool {
        return BWDBManager.shared.deleteTable(dbName: BWAppManager.shared.loginGWDBName(),
                                              tableName: tableName,
                                              filter: DBColumn.belongId == belongID)
    }
    
    /// 根据主键删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        return false
    }
}
