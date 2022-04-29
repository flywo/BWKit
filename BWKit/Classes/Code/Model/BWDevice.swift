//
//  BWDevice.swift
//  BWKit
//
//  Created by yuhua on 2020/3/4.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON


/// 设备--总类，所有子设备均集成自该类
public class BWDevice: Mappable, Equatable {
    
    /// 向往音乐歌曲列表
    public struct XWSong {
        /// 名字
        public let name: String
        /// 演唱者
        public let sing: String
        /// 歌曲ID
        public let id: Int
        /// 歌曲长度
        public let duration: Int
    }
    
    /// 设备数据有变动，需要刷新，UI界面需重新获取数据
    public static var needRefresh: (()->Void)?
    
    /// 新设备入网报告，此回调用于单个设备添加时获取新设备，在设备列表添加时，无需该回调
    public static var deviceNetworkReport: ((BWDevice)->Void)?
    
    /// 设备绑定报告，遥控器绑定设备成功时的回调
    static var bindHandle: (()->Void)?
    
    /// 数据透传命令response回复，id，cmd，如果需要处理response，则需要在该闭包中处理。
    static var dtResponse: ((Int, String)->Void)?
    
    /// 搜索向往背景音乐的回调
    static var xwHandle: ((Int, String?, String?, String?, Int?)->Void)?
    
    /// 向往背景音乐歌曲列表返回的回调，参数1：设备ID       参数2：歌曲列表信息
    public static var xwSongListHandle: ((Int, [XWSong])->Void)?
    
    /// 门锁开锁回调，id, status
    static var openDoorHandle: ((Int, Int)->Void)?
    
    /// 未命名门锁用户开门，设备ID  用户ID  用户类型
    public static var undefDoorUserOpen: ((Int, Int, Int)->Void)?
    
    /// 快捷列表查询完毕的回调，可通过quickDevices拿到列表
    public static var quickQuerySuccess: (()->Void)?
    
    /// 快捷设备列表
    public static var quickDevices: [BWDevice]?
    
    /// wifi设备权限列表
    public static var wifiPermission: [String]?
    
    /// 设备状态
    static var deviceStatus = [Int: JSON]()
    
    /// 设备属性
    public var attr: String?
    
    /// 设备类型
    public var type: String?
    
    /// 设备id
    public var ID: Int?
    
    /// 父id
    public var parentId: Int?
    
    /// 红外码库
    public var typeId: String?
    
    /// 设备名称
    public var name: String?
    
    /// 硬件版本
    public var hardVersion: String?
    
    /// 创建时间
    public var createTime: String?
    
    /// 设备MAC
    public var mac: String?
    
    /// 软件版本
    public var softVersion: String?
    
    /// 编号
    public var model: String?
    
    /// 房间ID
    public var roomId: Int?
    
    /// 房间name
    public var roomName: String?
    
    /// 绑定报警器
    public var bindAlarm: Int?
    
    /// 绑定猫眼
    public var bindCateye: String?
    
    /// 命令列表
    public var cmds: [BWDeviceCMD]?
    
    /// 是否是新入网设备
    public var isNew: Bool = false
    
    /// 空调设备的网关分机号ID
    public var acGatewayId: Int?
    
    /// 空调网关的室外机ID
    public var acOutSideId: Int?
    
    /// 设备有状态更新，需自行实现该闭包，实现界面实时更新，通过闭包传入的设备ID找到子设备，然后通过该设备属性获取更新后的状态。
    public static var stateRefresh: (([Int])->Void)?
    
    /// 设备有状态更新，用于百微APP语音控制界面状态报告。效果同stateRefresh
    public static var voiceControlStateRefresh: ((Int)->Void)?
    
    public init() {
    }
    
    /// 初始化
    init(attr: String,
         type: String,
         ID: Int,
         name: String,
         hardVersion: String,
         createTime: String,
         mac: String,
         softVersion: String,
         model: String,
         roomId: Int,
         bindAlarm: Int = -1,
         bindCateye: String = "",
         parentId: Int = -1,
         typeId: String = "",
         isNew: Bool = false,
         acGatewayId: Int = -1,
         acOutSideId: Int = -1) {
        self.attr = attr
        self.type = type
        self.ID = ID
        self.name = name
        self.hardVersion = hardVersion
        self.createTime = createTime
        self.mac = mac
        self.softVersion = softVersion
        self.model = model
        self.roomId = roomId
        self.bindAlarm = bindAlarm
        self.bindCateye = bindCateye
        self.parentId = parentId
        self.typeId = typeId
        self.isNew = isNew
        self.acGatewayId = acGatewayId
        self.acOutSideId = acOutSideId
    }
    
    /// 忽略该方法
    public required init?(map: Map) {
    }
    
    /// 忽略该方法
    public func mapping(map: Map) {
        attr <- map["device_attr"]
        type <- map["product_type"]
        ID <- map["device_id"]
        name <- map["device_name"]
        hardVersion <- map["hard_ver"]
        createTime <- map["create_time"]
        mac <- map["mac"]
        softVersion <- map["soft_ver"]
        model <- map["model"]
        roomId <- map["room_id"]
        bindAlarm <- map["bind_alarm"]
        bindCateye <- map["bind_cateye"]
        cmds <- map["cmd_list"]
        parentId <- map["product_id"]
        typeId <- map["type_id"]
        acGatewayId <- map["acgateway_id"]
        acOutSideId <- map["acoutside_id"]
//        if attr == DeviceAttr.ACGatewaySub.rawValue, acGatewayId == -1 {
//            attr = DeviceAttr.ACGatewayFather.rawValue
//        }
        if parentId == nil {
            parentId <- map["parent_id"]
        }
        if ID == nil, attr == DeviceAttr.XiangwangBackgroundMusic.rawValue {
            ID <- map["deviceId"]
            type <- map["device_type"]
        }
        cmds?.forEach {
            $0.belongId = ID
        }
    }
    
    /// 描述
    public var description: String {
        return "[id:\(ID ?? -1) attr:\(attr ?? "") type:\(type ?? "") name:\(name ?? "") roomId:\(roomId ?? -1) model:\(model ?? "") bindAlarm:\(bindAlarm ?? -1) bindCateye:\(bindCateye ?? "") parentId:\(parentId ?? -1) typeId:\(typeId ?? "")]"
    }
    
    /// 比较
    public static func == (lhs: BWDevice, rhs: BWDevice) -> Bool {
        return lhs.ID == rhs.ID
    }
}

/// 执行操作
extension BWDevice {
    
    /// 查询数据，内部使用
    static func QueryDevice(success: @escaping (Int)->Void = { _ in }, fail: @escaping ()->Void = {}) {
        guard let msg = ObjectMSG.gatewayDeviceQuery() else {
            fail()
            return
        }
        
        /// 猫眼摄像机先摘出来
        let cateyes = BWCateye.queryCateye()
        let cams = BWCamera.queryCAM()
        BWDeviceCMD.clear()
        BWDevice.clear()
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 || json["status"].intValue == 502 {
                let type_list = json["type_list"].arrayValue
                type_list.forEach {
                    if let list = $0["device_list"].rawString(), let type = $0["product_type"].string {
                        let devices = [BWDevice](JSONString: list) ?? [BWDevice]()
                        devices.save(dbName: BWAppManager.shared.loginGWDBName(), type: type)
                    }
                }
                /// 将猫眼摄像机放回去
                cateyes.forEach {
                    $0.save()
                }
                cams.forEach {
                    $0.save()
                }
                success(json["end"].intValue)
            } else {
                /// 将猫眼摄像机放回去
                cateyes.forEach {
                    $0.save()
                }
                cams.forEach {
                    $0.save()
                }
                fail()
            }
        })
    }
    
    /// 查询所有设备状态，内部使用
    static func QueryDeviceStatus() {
        let types = BWDevice.queryType()
        BWSDKLog.shared.debug("一共有设备类型:\(types)")
        types.forEach {
            QueryDeviceStatus(type: $0)
        }
    }
    
    /// 查询指定类型设备状态，内部使用
    static func QueryDeviceStatus(type: ProductType) {
        guard let msg = ObjectMSG.deviceState(type: type.rawValue) else {
            return
        }
        BWAppManager.shared.sendMSG(msg: msg) { json in
            if json["status"].intValue == 0 {
                let devices = json["device_list"].arrayValue
                var IDs = [Int]()
                devices.forEach {
                    let ID = $0["device_id"].intValue
                    let state = $0["device_status"]
                    IDs.append(ID)
                    BWDevice.deviceStatus[ID] = state
                }
                stateRefresh?(IDs)
            }
        }
    }
    
    
    /// 删除设备
    /// - Parameters:
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func delDevice(timeOut: TimeInterval = 8,
                          timeOutHandle: @escaping ()->Void = {},
                          success: @escaping ()->Void = {},
                          fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("删除设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let id = ID else {
            BWSDKLog.shared.error("删除设备未设置id！")
            fail(-1)
            return
        }
        var device = [String: Int]()
        device["device_id"] = id
        let deviceList = [device]
        guard let msg = ObjectMSG.gatewayDeviceDelete(list: deviceList) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                ObjectMSG.paraseMSG(msg: json)
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 添加设备
    /// - Parameters:
    ///   - type: 类型
    ///   - attr: 属性
    ///   - name: 名称
    ///   - parentId: 父ID
    ///   - roomId: 房间ID
    ///   - typeId: 类型----红外码库控制时指定，其余时候忽略就行
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func AddDevice(type: ProductType,
                                 attr: DeviceAttr,
                                 name: String,
                                 parentId: Int,
                                 roomId: Int,
                                 typeId: String = "", timeOut: TimeInterval = 8,
                                 timeOutHandle: @escaping ()->Void = {},
                                 success: @escaping ()->Void = {},
                                 fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("添加设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var device = [String: Any]()
        device["product_type"] = type.rawValue
        device["device_attr"] = attr.rawValue
        device["device_name"] = name
        device["parent_id"] = parentId
        device["room_id"] = roomId
        device["type_id"] = typeId
        guard let msg = ObjectMSG.gatewayDeviceAdd(device: device) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                ObjectMSG.paraseMSG(msg: json)
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 对设备进行设置，如不在方法中传入数据，则使用调用本方法设备的数据设置值(除命令列表除外，命令列表需通过方法指定)。
    /// - Parameters:
    ///   - name: 名称
    ///   - attr: 属性，不设置则为原来的属性
    ///   - roomId: 房间ID
    ///   - bindCateye: 绑定的猫眼ID，门锁可设置，其余设备无效
    ///   - typeId: 红外码库ID，红外设备可设置，其余设备无效
    ///   - insideId: 内机地址
    ///   - outsideId: 外机地址
    ///   - cmdList: 命令列表，红外、数据透传设备可设置，其余设备无效
    ///   - breakLength: 分包长度
    ///   - timeOut: 超时时间，如果传入了命令列表，则超时时间为分包发送的间隔时间，80条命令分一个包。
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - cmdListProgress: 分包发送时会触发该回调，参数1 分包总数   参数2 发送进度
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func setDeviceAttributes(name: String? = nil,
                                    attr: DeviceAttr? = nil,
                                    roomId: Int? = nil,
                                    bindCateye: String? = nil,
                                    typeId: String? = nil,
                                    insideId: Int? = nil,
                                    outsideId: Int? = nil,
                                    cmdList: [BWDeviceCMD]? = nil,
                                    breakLength: Int = 80,
                                    timeOut: TimeInterval = 8,
                                    timeOutHandle: @escaping ()->Void = {},
                                    cmdListProgress: @escaping (Int, Int)->Void = { _, _ in },
                                    success: @escaping ()->Void = {},
                                    fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("编辑设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var device = [String: Any]()
        device["device_id"] = ID
        device["device_name"] = name ?? self.name
        device["device_attr"] = attr ?? self.attr
        device["room_id"] = roomId ?? self.roomId
        device["bind_alarm"] = bindAlarm == -1 ? nil : bindAlarm
        device["bind_cateye"] = bindCateye ?? (self.bindCateye == "" ? nil : self.bindCateye)
        device["type_id"] = typeId ?? (self.typeId == "" ? nil : self.typeId)
        if let insideId = insideId {
            device["acgateway_id"] = insideId
        }
        if let outsideId = outsideId {
            device["acoutside_id"] = outsideId
        }
        if let cmdList = cmdList {
            let total = cmdList.count/breakLength + (cmdList.count%breakLength == 0 ? 0 : 1)
            var current = 0
            BWAppManager.shared.serverSocket?.needEndMSGName.append(MSGString.DeviceEdit)
            MSGFix.num = (MSGFix.num + 1) % 1000
            separateSendMSG(deviceDic: device,
                            cmdList: cmdList,
                            length: breakLength,
                            timeOut: timeOut,
                            timeOutHandle: timeOutHandle,
                            cmdListOneSucess: {
                                current += 1
                                BWSDKLog.shared.debug("分包发送成功进度:\(current)/\(total)")
                                cmdListProgress(total, current)
                                
            },
                            success: success,
                            fail: fail)
            return
        }
        // 避免某些特殊情况，导致没有被移除出现异常。
        BWAppManager.shared.serverSocket?.needEndMSGName.removeAll { $0 == MSGString.DeviceEdit }
        guard let msg = ObjectMSG.gatewayDeviceEdit(device: device) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                ObjectMSG.paraseMSG(msg: json)
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 分包发送
    func separateSendMSG(deviceDic: [String: Any],
                         cmdList: [BWDeviceCMD],
                         length: Int = 80,
                         timeOut: TimeInterval = 8,
                         timeOutHandle: @escaping ()->Void = {},
                         cmdListOneSucess: @escaping ()->Void = {},
                         success: @escaping ()->Void = {},
                         fail: @escaping (Int)->Void = { _ in }) {
        var device = [String: Any]()
        device["device_id"] = deviceDic["device_id"]
        device["device_name"] = deviceDic["device_name"]
        device["device_attr"] = deviceDic["device_attr"]
        device["room_id"] = deviceDic["room_id"]
        device["bind_alarm"] = deviceDic["bind_alarm"]
        device["bind_cateye"] = deviceDic["bind_cateye"]
        device["type_id"] = deviceDic["type_id"]
        if cmdList.count <= length {
            device["cmd_list"] = cmdList.toJSON()
        } else {
            device["cmd_list"] = Array(cmdList[0..<length]).toJSON()
        }
        
        guard let msg = ObjectMSG.gatewayDeviceEdit(device: device, listEnd: cmdList.count <= length) else {
            BWAppManager.shared.serverSocket?.needEndMSGName.removeAll { $0 == MSGString.DeviceEdit }
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            BWAppManager.shared.serverSocket?.needEndMSGName.removeAll { $0 == MSGString.DeviceEdit }
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { [weak self] json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                ObjectMSG.paraseMSG(msg: json)
                if json["end"].int == 1 {
                    BWAppManager.shared.serverSocket?.needEndMSGName.removeAll { $0 == MSGString.DeviceEdit }
                    success()
                } else {
                    cmdListOneSucess()
                    self?.separateSendMSG(deviceDic: deviceDic,
                                          cmdList: Array(cmdList[length..<cmdList.count]),
                                          length: length,
                                          timeOut: timeOut,
                                          timeOutHandle: timeOutHandle,
                                          cmdListOneSucess: cmdListOneSucess,
                                          success: success,
                                          fail: fail)
                }
            } else {
                BWAppManager.shared.serverSocket?.needEndMSGName.removeAll { $0 == MSGString.DeviceEdit }
                fail(-1)
            }
        })
    }
    
    /// 添加空调网关分机设备
    /// - Parameters:
    ///   - name: 设备名称
    ///   - parentId: 空调网关ID
    ///   - roomId: 房间ID
    ///   - insideId: 室内机ID
    ///   - outsideId: 室外机ID
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func AddNewACGateway(name: String,
                                       parentId: Int,
                                       roomId: Int,
                                       insideId: Int,
                                       outsideId: Int,
                                       timeOut: TimeInterval = 8,
                                       timeOutHandle: @escaping ()->Void = {},
                                       success: @escaping ()->Void = {},
                                       fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("添加空调网关设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var device = [String: Any]()
        device["product_type"] = ProductType.ACGateway.rawValue
        device["device_attr"] = DeviceAttr.CentralAirCondition.rawValue
        device["device_name"] = name
        device["parent_id"] = parentId
        device["room_id"] = roomId
        device["acgateway_id"] = insideId
        device["acoutside_id"] = outsideId
        guard let msg = ObjectMSG.gatewayDeviceAdd(device: device) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                ObjectMSG.paraseMSG(msg: json)
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 添加空调网关分机设备
    /// - Parameters:
    ///   - name: 设备名称
    ///   - parentId: 空调网关ID
    ///   - roomId: 房间ID
    ///   - gatewayId: 分机ID
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func AddACGateway(name: String,
                                    parentId: Int,
                                    roomId: Int,
                                    gatewayId: Int,
                                    timeOut: TimeInterval = 8,
                                    timeOutHandle: @escaping ()->Void = {},
                                    success: @escaping ()->Void = {},
                                    fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("添加空调网关设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var device = [String: Any]()
        device["product_type"] = ProductType.ACGateway.rawValue
        device["device_attr"] = DeviceAttr.ACGatewaySub.rawValue
        device["device_name"] = name
        device["parent_id"] = parentId
        device["room_id"] = roomId
        device["acgateway_id"] = gatewayId
        guard let msg = ObjectMSG.gatewayDeviceAdd(device: device) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                ObjectMSG.paraseMSG(msg: json)
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 查询波特率
    /// - Parameters:
    ///   - deviceId: ID
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调，返回值：1 波特率     2 校验位     3 停止位
    ///   - fail: 失败回调
    public static func QueryDeviceBaud(deviceId: Int,
                                       timeOut: TimeInterval = 8,
                                       timeOutHandle: @escaping ()->Void = {},
                                       success: @escaping (Int, Int, Int)->Void = { (_, _, _) in },
                                       fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询波特率")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayDeviceBaudQuery(deviceID: deviceId) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                if let device = json["device"].dictionary {
                    success(device["baud"]?.int ?? 0, device["parity_bit"]?.int ?? 0, device["stop_bit"]?.int ?? 0)
                    return
                }
                fail(-1)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 设置波特率
    /// - Parameters:
    ///   - deviceId: 设备ID
    ///   - baud: 波特率
    ///   - parity: 校验位
    ///   - stop: 停止位
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func SetDeviceBaud(deviceId: Int,
                                     baud: Int,
                                     parity: Int,
                                     stop: Int,
                                     timeOut: TimeInterval = 8,
                                     timeOutHandle: @escaping ()->Void = {},
                                     success: @escaping ()->Void = {},
                                     fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询波特率")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayDeviceBaudSet(deviceID: deviceId, baud: baud, parity: parity, stop: stop) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 设备确认命令，发送该命令给设备，设备会闪烁
    /// - Parameters:
    ///   - time: 闪烁时间
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func identify(time: Int = 10,
                         timeOut: TimeInterval = 8,
                         timeOutHandle: @escaping ()->Void = {},
                         success: @escaping ()->Void = {},
                         fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("发送Identify命令:\(name ?? "")")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.deviceIdentify(deviceID: ID ?? -1, time: time) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    public enum CurtainState: String {
        case ON = "on"
        case OFF = "off"
        case STOP = "stop"
    }
    
    
    /// 搜索向往音乐
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，状态、类型、MAC、IP、PORT
    ///   - fail: 失败
    public static func SearchXWBG(timeOut: TimeInterval = 8,
                                  timeOutHandle: @escaping ()->Void = {},
                                  success: @escaping (Int, String?, String?, String?, Int?)->Void = { _,_,_,_,_ in},
                                  fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询向往背景音乐")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.findXWBG() else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWDevice.xwHandle = {
            BWAppManager.shared.killDelayTime()
            success($0, $1, $2, $3, $4)
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue != 0 {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 绑定向往背景音乐
    /// - Parameters:
    ///   - name: 名称
    ///   - mac: Mac
    ///   - roomId: 房间ID
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func BindXWBG(name: String,
                                mac: String,
                                roomId: Int,
                                timeOut: TimeInterval = 8,
                                timeOutHandle: @escaping ()->Void = {},
                                success: @escaping ()->Void = {},
                                fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("绑定向往背景音乐")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.bindXWBG(attr: "XwBMusic", name: name, roomId: roomId, mac: mac) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                ObjectMSG.paraseMSG(msg: json)
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 连接向往背景音乐
    /// - Parameters:
    ///   - mac: 背景音乐mac地址
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func ConnectXWBG(mac: String,
                                   timeOut: TimeInterval = 8,
                                   timeOutHandle: @escaping ()->Void = {},
                                   success: @escaping ()->Void = {},
                                   fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("连接向往背景音乐")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.connectXWBG(mac: mac) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWDevice.xwHandle = nil
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 查询电量统计，带电量统计设备可查询
    /// - Parameters:
    ///   - type: 类型，hour小时查询  day按天查询  month按月查询  year按年查询
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，返回   类型:值，值需要/1000
    ///   - fail: 失败
    public func queryPower(type: String,
                           timeOut: TimeInterval = 8,
                           timeOutHandle: @escaping ()->Void = {},
                           success: @escaping ([Int: Double])->Void = { _ in},
                           fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询电量统计")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.power(deviceId: ID ?? -1, type: type) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                if let records = json["device"]["records"].array {
                    var result = [Int: Double]()
                    records.forEach {
                        if type == "hour", let key = $0["hour"].int, let value = $0["value"].double {
                            result[key] = value
                        } else if type == "day", let key = $0["day"].int, let value = $0["value"].double {
                            result[key] = value
                        } else if type == "month", let key = $0["month"].int, let value = $0["value"].double {
                            result[key] = value
                        } else if type == "year", let key = $0["year"].int, let value = $0["value"].double {
                            result[key] = value
                        }
                    }
                    success(result)
                    return
                }
                success([:])
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 查询设备绑定
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，附带上被绑定设备ID，-1表示没有设备
    ///   - fail: 失败
    public func queryBind(timeOut: TimeInterval = 8,
                          timeOutHandle: @escaping ()->Void = {},
                          success: @escaping (Int)->Void = { _ in },
                          fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询设备绑定关系")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.bindQuery(deviceId: ID ?? -1) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                if let deviceId = json["device"]["bind_deviceId"].int {
                    success(deviceId)
                } else {
                    success(-1)
                }
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 绑定设备
    /// - Parameters:
    ///   - deviceId: 待绑定的设备
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func bind(deviceId: Int,
                     timeOut: TimeInterval = 8,
                     timeOutHandle: @escaping ()->Void = {},
                     success: @escaping ()->Void = {},
                     fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("设备绑定")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.bind(deviceId: ID ?? -1, bindId: deviceId) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            BWDevice.bindHandle = nil
            timeOutHandle()
        }
        BWDevice.bindHandle = {
            BWAppManager.shared.killDelayTime()
            success()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue != 0 {
                BWDevice.bindHandle = nil
                BWAppManager.shared.killDelayTime()
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 控制窗帘设备
    /// - Parameters:
    ///   - state: 控制窗帘的状态
    ///   - level: 控制窗帘进度：0--100
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - success: 成功
    ///   - fail: 失败
    public func controlOnOffStop(state: CurtainState? = nil,
                                 level: Int? = nil,
                                 timeOut: TimeInterval = 8,
                                 timeOutHandle: @escaping ()->Void = {},
                                 success: @escaping ()->Void = {},
                                 fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制设备状态")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var status = [String: Any]()
        status["state"] = state?.rawValue
        status["level"] = level
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: status) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 向往控制类型
    public enum XWControlType: String {
        /// 播放
        case Play = "play"
        /// 查询信息
        case Info = "getdeviceinfo"
        /// 静音
        case Mute = "mute"
        /// 电源
        case Power = "power"
        /// 退出
        case Exit = "exit"
        /// 音量
        case Volume = "volume"
        /// 音效
        case Effect = "effect"
        /// 音源
        case Source = "source"
        /// 模式
        case Mode = "mode"
        /// 进度
        case Progress = "progreess"
        /// 播放歌曲ID
        case SongID = "songid"
        /// 歌曲列表
        case SongList = "getsonglist"
        /// 歌曲信息
        case SongInfo = "querysonginfo"
        /// 搜索在线音乐
        case QuerySong = "querysongonline"
    }
    
    
    /// 控制向往b背景音乐
    /// - Parameters:
    ///   - type: 类型
    ///   - value: 值
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func controlXWBG(type: XWControlType,
                            value: Any,
                            timeOut: TimeInterval = 8,
                            timeOutHandle: @escaping ()->Void = {},
                            success: @escaping ()->Void = {},
                            fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制向往背景音乐")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var status = [String: Any]()
        switch type {
        case .Info:
            status = [type.rawValue: (value as? String) ?? "on"]
        case .Power:
            status = [type.rawValue: (value as? String) ?? "on"]
        case .Play:
            status = [type.rawValue: (value as? String) ?? "on"]
        case .Volume:
            status = [type.rawValue: (value as? String) ?? "0"]
        case .Mute:
            status = [type.rawValue: (value as? Int) ?? 1]
        case .Source:
            status = [type.rawValue: (value as? String) ?? "local"]
        case .Mode:
            status = [type.rawValue: (value as? String) ?? "cycle"]
        case .QuerySong:
            status = [type.rawValue: (value as? String) ?? ""]
        case .SongList:
            status = [type.rawValue: (value as? String) ?? "on"]
        case .SongID:
            status = [type.rawValue: (value as? String) ?? "0"]
        case .Progress:
            status = [type.rawValue: (value as? Int) ?? 0]
        default:
            status = [:]
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: status) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 控制开关设备开关
    /// - Parameters:
    ///   - on: 控制开关，true开  false关
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - fail: 失败
    public func controlOnOffState(on: Bool,
                                  timeOut: TimeInterval = 8,
                                  timeOutHandle: @escaping ()->Void = {},
                                  success: @escaping ()->Void = {},
                                  fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制设备状态")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: ["state": on ? "on" : "off"]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 控制电机反转
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func controlReverse(timeOut: TimeInterval = 8,
                               timeOutHandle: @escaping ()->Void = {},
                               success: @escaping ()->Void = {},
                               fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制电机反转")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: ["reverse": "on"]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 控制工作模式
    /// - Parameters:
    ///   - model: 工作模式，恒温0  离家1  节能2     hv354 -> 3离家模式 4防冻模式 5正常模式
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - fail: 失败
    public func controlWorkModel(model: Int,
                                 timeOut: TimeInterval = 8,
                                 timeOutHandle: @escaping ()->Void = {},
                                 success: @escaping ()->Void = {},
                                 fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制温控器工作模式")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var work = "normal"
        if model == 0 {
            work = "constant"
        } else if model == 1 {
            work = "leave_home"
        }
            // hv354
        else if model == 3 {
            work = "leave_home"
        } else if model == 4 {
            work = "constant"
        } else if model == 5 {
            work = "normal"
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: ["work_mode": work]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 控制模式
    /// - Parameters:
    ///   - model: 模式：0送风  1制冷  2制热  3地暖  4双制热  5送风地暖     hv351 -> 2表示开机       空调网关 -> 6除湿 7送风
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - fail: 失败
    public func controlSysModel(model: Int,
                                timeOut: TimeInterval = 8,
                                timeOutHandle: @escaping ()->Void = {},
                                success: @escaping ()->Void = {},
                                fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制温控器模式")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var sys = "fan_only"
        if model == 1 {
            sys = "cool"
        } else if model == 2 {
            sys = "heat"
        } else if model == 3 {
            sys = "floor_heating_only"
        } else if model == 4 {
            sys = "floor_heating_air"
        } else if model == 5 {
            sys = "fan_heating"
        } else if model == 6 {
            sys = "dehumidify"
        } else if model == 7 {
            sys = "wind"
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: ["sys_mode": sys]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 空调网关控制风速
    /// - Parameters:
    ///   - model: 风速：0超低   1低   2中  3高   4超高
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - fail: 失败
    public func acgControlFanModel(model: Int,
                                   timeOut: TimeInterval = 8,
                                   timeOutHandle: @escaping ()->Void = {},
                                   success: @escaping ()->Void = {},
                                   fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制空调网关风速")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var fan = "ll"
        if model == 1 {
            fan = "l"
        } else if model == 2 {
            fan = "m"
        } else if model == 3 {
            fan = "h"
        } else if model == 4 {
            fan = "hh"
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: ["wind_level": fan]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 控制风速
    /// - Parameters:
    ///   - model: 风速：0低速  1中速  2高速  3自动    hv355 -> 4关机
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - fail: 失败
    public func controlFanModel(model: Int,
                                timeOut: TimeInterval = 8,
                                timeOutHandle: @escaping ()->Void = {},
                                success: @escaping ()->Void = {},
                                fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制温控器风速")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var fan = "auto"
        if model == 0 {
            fan = "low"
        } else if model == 1 {
            fan = "medium"
        } else if model == 2 {
            fan = "high"
        }
        // hv355
        else if model == 4 {
            fan = "off"
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: ["fan_mode": fan]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 控制童锁，温控器使用
    /// - Parameters:
    ///   - on: 是否开启，true打开   false关闭
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - fail: 失败
    public func controlLock(on: Bool,
                            timeOut: TimeInterval = 8,
                            timeOutHandle: @escaping ()->Void = {},
                            success: @escaping ()->Void = {},
                            fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制童锁")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: ["lock_mode": on ? "on" : "off"]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 关闭温控器，只有关闭
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - fail: 失败
    public func controlPowerOff(timeOut: TimeInterval = 8,
                                timeOutHandle: @escaping ()->Void = {},
                                success: @escaping ()->Void = {},
                                fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制温控器关")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: ["sys_mode": "off"]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 控制温度，温控器使用，sdk自动判断发送制冷温度还是制热温度，传入正常温度，比如26度，传26即可
    /// - Parameters:
    ///   - value: 温度
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - fail: 失败
    public func controlTemp(value: Int,
                            timeOut: TimeInterval = 8,
                            timeOutHandle: @escaping ()->Void = {},
                            success: @escaping ()->Void = {},
                            fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制温控器温度")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var status = [String: Any]()
        if sysMode() == "cool" {
            status["coolpoint"] = value * 100
        } else {
            status["heatpoint"] = value * 100
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: status) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 老门锁开锁，只有在门锁唤醒情况下能够开锁
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - fail: 失败
    public func openDoor(timeOut: TimeInterval = 8,
                         timeOutHandle: @escaping ()->Void = {},
                         success: @escaping ()->Void = {},
                         fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("老门锁开锁")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        if isSleep() != false {
            BWSDKLog.shared.error("请先唤醒门锁后，再发生开门指令！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: ["state": "on"]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 打开新门锁
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，只能表示命令已经发送出去，但是最终是否控制成功，需要通过stateRefresh回调获得。
    ///   - fail: 失败
    public func openNewDoor(pwd: String,
                            timeOut: TimeInterval = 20,
                            timeOutHandle: @escaping ()->Void = {},
                            success: @escaping ()->Void = {},
                            fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("新门锁开锁")
        BWDevice.openDoorHandle = nil
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        let ID = self.ID ?? -1
        guard let msg = ObjectMSG.doorLockRandom(deviceId: ID) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            BWDevice.openDoorHandle = nil
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                if let code = json["device"]["random_code"].string {
                    guard let msg = ObjectMSG.deviceControl(deviceID: ID, deviceStatus: ["state": "on", "pwd": pwd.encryptDoorLockPWD(random: code)]) else {
                        BWAppManager.shared.killDelayTime()
                        BWDevice.openDoorHandle = nil
                        return fail(-1)
                    }
                    BWDevice.openDoorHandle = { deviceId, status in
                        if deviceId == ID {
                            if status == 0 {
                                success()
                            } else {
                                fail(status)
                            }
                            BWDevice.openDoorHandle = nil
                        }
                    }
                    BWAppManager.shared.sendMSG(msg: msg) { json in
                        BWAppManager.shared.killDelayTime()
                        if json["status"].intValue == 0 {
//                            success()
                        } else {
                            fail(json["status"].intValue)
                            BWDevice.openDoorHandle = nil
                        }
                    }
                } else {
                    BWAppManager.shared.killDelayTime()
                    fail(-1)
                }
            } else {
                BWAppManager.shared.killDelayTime()
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 获取温控器模式设置
    /// - Parameters:
    ///   - type: 类型，leave_home离家  constant恒温
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func thermostatWorkmode(type: String,
                                   timeOut: TimeInterval = 8,
                                   timeOutHandle: @escaping ()->Void = {},
                                   success: @escaping ([String : Any])->Void = { _ in },
                                   fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询温控器模式")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.workmode(deviceID: ID ?? -1, type: type) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0, let workmode = json["device"]["workmode"].dictionaryObject {
                success(workmode)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 设置温控器工作模式
    /// - Parameters:
    ///   - modeName: 模式名称：leave_home离家    constant恒温
    ///   - mode: 工作模式 cool制冷  heat制热  fan_only送风
    ///   - point: 制冷制热时温度，x100，比如16度，传1600
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func thermostatWorkmodeSet(modeName: String,
                                      mode: String,
                                      point: Int? = nil,
                                      timeOut: TimeInterval = 8,
                                      timeOutHandle: @escaping ()->Void = {},
                                      success: @escaping ()->Void = {},
                                      fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("设置温控器模式")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.setWorkmode(deviceID: ID ?? -1, name: modeName, mode: mode, point: point ?? 5) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 华尔思控制类型
    public enum HESControlAction: String {
        /// 当前状态
        case Status = "status"
        /// 收藏
        case Collect = "collect"
        /// 取消收藏
        case UnCollect = "unCollect"
        /// 播放
        case Play = "play"
        /// 切换播放模式
        case Mode = "mode"
        /// 修改音量
        case Volume = "volume"
        /// 切换音源
        case Source = "source"
        /// 设置播放进度
        case Progress = "progress"
        /// 播放歌曲列表
        case ListPlay = "listPlay"
        /// 播放本地歌曲列表
        case PlayLocal = "playLocal"
        /// 获取播放列表
        case PlayList = "playList"
        /// 获取本地列表
        case LocalList = "localList"
        /// 获取收藏列表
        case CollectList = "collectList"
        /// 搜索
        case Search = "search"
    }
    
    
    /// 华尔思控制命令
    /// - Parameters:
    ///   - action: 命令类型
    ///   - value: 命令值
    ///   - index: 歌曲下标
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func controlHESBG(action: HESControlAction,
                             value: Any? = nil,
                             index: Int? = nil,
                             timeOut: TimeInterval = 8,
                             timeOutHandle: @escaping ()->Void = {},
                             success: @escaping ()->Void = {},
                             fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("控制华尔思背景音乐")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var status: [String: Any] = ["action": action.rawValue]
        switch action {
        case .Status, .PlayList, .LocalList, .CollectList:
            break
        case .Collect, .UnCollect, .Play, .Mode, .Volume, .Source, .Progress, .Search:
            status["value"] = value ?? ""
        case .ListPlay:
            status["value"] = value ?? ""
            status["index"] = index ?? 0
        case .PlayLocal:
            status["value"] = value ?? 0
        }
        guard let msg = ObjectMSG.deviceControl(deviceID: ID ?? -1, deviceStatus: status) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    // MARK: 摄像机
    /// 保存摄像机到数据库
    static func saveCam(did: String,
                        user: String,
                        pwd: String,
                        name: String,
                        roomID: Int) {
        let device = BWDevice()
        device.ID = did.hash
        device.mac = did
        device.type = ProductType.Camera.rawValue
        device.attr = DeviceAttr.Camera.rawValue
        device.roomId = roomID
        device.name = name
        device.hardVersion = user
        device.softVersion = pwd
        BWSDKLog.shared.debug("将摄像机整理成特殊device插入：\(device)")
        device.save()
    }
    
    /// 添加摄像机
    /// - Parameters:
    ///   - did: 摄像机ID
    ///   - user: 账号
    ///   - pwd: 密码
    ///   - name: 名称
    ///   - roomID: 房间，没房间传-1
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func CAMAdd(did: String,
                              user: String,
                              pwd: String,
                              name: String,
                              roomID: Int,
                              timeOut: TimeInterval = 8,
                              timeOutHandle: @escaping ()->Void = {},
                              success: @escaping ()->Void = {},
                              fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("添加摄像机")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.addCAM(info: [
            "type": 1,
            "sn": BWAppManager.shared.loginGateway?.sn ?? "",
            "devId": did,
            "devUsername": user,
            "devPwd": pwd,
            "devName": name,
            "roomId": roomID
        ]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                saveCam(did: did, user: user, pwd: pwd, name: name, roomID: roomID)
                // 插入排序信息
                let sort = BWDeviceSort()
                sort.belongId = did.hash
                sort.sortId = sortRebootId
                sort.save()
                let roomSort = BWDeviceRoomSort()
                roomSort.belongId = did.hash
                roomSort.sortId = sortRebootId
                roomSort.save()
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 编辑摄像机
    /// - Parameters:
    ///   - did: 摄像机ID
    ///   - user: 账号
    ///   - pwd: 密码
    ///   - name: 名称
    ///   - roomID: 房间，没房间传-1
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func CAMEdit(did: String,
                               user: String,
                               pwd: String,
                               name: String,
                               roomID: Int,
                               timeOut: TimeInterval = 8,
                               timeOutHandle: @escaping ()->Void = {},
                               success: @escaping ()->Void = {},
                               fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("编辑摄像机")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.editCAM(info: [
            "type": 1,
            "sn": BWAppManager.shared.loginGateway?.sn ?? "",
            "devId": did,
            "devUsername": user,
            "devPwd": pwd,
            "devName": name,
            "roomId": roomID
        ]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                let dbDevice = BWDevice.query(deviceID: did.hash)
                // 如果ID为-1，表示从房间删除
                if roomID == -1 {
                    // 从房间移除，需要重置房间排序
                    BWSDKLog.shared.info("从房间移除设备，重置排序ID")
                    let sort = BWDeviceRoomSort()
                    sort.belongId = did.hash
                    sort.sortId = sortRebootId
                    sort.save()
                }
                // 如果ID为非-1，同时和当前房间不相等，则表示修改了房间
                else if roomID != dbDevice?.roomId {
                    // 依旧需要重置房间排序
                    BWSDKLog.shared.info("设备从房间移动到另一个房间，重置排序ID")
                    let sort = BWDeviceRoomSort()
                    sort.belongId = did.hash
                    sort.sortId = sortRebootId
                    sort.save()
                }
                saveCam(did: did, user: user, pwd: pwd, name: name, roomID: roomID)
                BWDevice.needRefresh?()
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 删除摄像机
    /// - Parameters:
    ///   - did: 摄像机ID
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func CAMDel(did: String,
                              timeOut: TimeInterval = 8,
                              timeOutHandle: @escaping ()->Void = {},
                              success: @escaping ()->Void = {},
                              fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("删除摄像机")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.deleteCAM(ID: did) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                BWDevice.delete(ID: did.hash)
                BWDeviceSort.delete(belongId: did.hash)
                BWDeviceRoomSort.delete(belongId: did.hash)
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 从服务器查询摄像机，该接口一般不需要自己调用。除非需要手动更新服务器摄像机列表时，否则都不需要调用该方法。
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func CAMQuery(timeOut: TimeInterval = 8,
                                timeOutHandle: @escaping ()->Void = {},
                                success: @escaping ()->Void = {},
                                fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询摄像机")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.queryCAM(sn: BWAppManager.shared.loginGateway?.sn ?? "") else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                BWCamera.removeAllCam()
                if let cams = json["data"].array {
                    BWCateye.RoomCache.removeAll()
                    cams.forEach { cam in
                        if BWDevice.wifiPermission == nil {
                            saveJSON(cam: cam)
                        } else {
                            let list = BWDevice.wifiPermission ?? []
                            let devId = cam["devId"].string ?? ""
                            if list.contains(devId) {
                                saveJSON(cam: cam)
                            }
                        }
                    }
                }
                BWDevice.needRefresh?()
                BWCamera.cameraNeedRefresh?()
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 不带延时的查询
    static func NoDelayQuery() {
        BWSDKLog.shared.debug("不带延时查询摄像机")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return
        }
        guard let msg = ObjectMSG.queryCAM(sn: BWAppManager.shared.loginGateway?.sn ?? "") else {
            return
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                BWCamera.removeAllCam()
                if let cams = json["data"].array {
                    BWCateye.RoomCache.removeAll()
                    cams.forEach { cam in
                        if BWDevice.wifiPermission == nil {
                            saveJSON(cam: cam)
                        } else {
                            let list = BWDevice.wifiPermission ?? []
                            let devId = cam["devId"].string ?? ""
                            if list.contains(devId) {
                                saveJSON(cam: cam)
                            }
                        }
                    }
                }
                BWDevice.needRefresh?()
                BWCamera.cameraNeedRefresh?()
                if BWAppManager.shared.loginGateway != nil {
                    BWDBManager.shared.transferOldDB(sn: BWAppManager.shared.loginGateway!.sn!, user: BWAppManager.shared.username!)
                }
                QueryQuickDeviceNoDelay()
            }
        })
    }
    
    static func saveJSON(cam: JSON) {
        if cam["type"].int == 5 {
            let did = cam["devId"].string ?? ""
            let roomId = cam["roomId"].int ?? -1
            BWCateye.RoomCache[did] = roomId
            BWDevice.UpdateCateyeRoom(nid: did, roomId: roomId)
        } else {
            let did = cam["devId"].string ?? ""
            let roomId = cam["roomId"].int ?? -1
            let name = cam["devName"].string ?? ""
            let user = cam["devUsername"].string ?? ""
            let pwd = cam["devPwd"].string ?? ""
            saveCam(did: did, user: user, pwd: pwd, name: name, roomID: roomId)
            // 保存排序
            let sort = BWDeviceSort()
            sort.belongId = did.hash
            sort.sortId = sortRebootId
            sort.save(or: .ignore)
            // 保存房间排序
            let roomSort = BWDeviceRoomSort()
            roomSort.belongId = did.hash
            roomSort.sortId = sortRebootId
            roomSort.save(or: .ignore)
        }
    }
    
    /// 设置快捷设备
    public static func SetQuickDevice(devices: [BWDevice],
                                      timeOut: TimeInterval = 8,
                                      timeOutHandle: @escaping ()->Void = {},
                                      success: @escaping ()->Void = {},
                                      fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("设置快捷设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var infos = [[String: Any]]()
        devices.forEach {
            if $0.type == ProductType.Camera.rawValue {
                infos.append(["productType": "BwCamera", "thirdUid": $0.mac ?? ""])
            } else if $0.type == ProductType.DoorLock.rawValue {
                infos.append(["productType": "Door Lock", "deviceId": $0.ID ?? -1])
            } else if $0.attr == DeviceAttr.ContactSensor.rawValue {
                infos.append(["productType": "ContactS", "deviceId": $0.ID ?? -1])
            }
        }
        guard let msg = ObjectMSG.setQuickDevice(infos: infos) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                quickDevices = devices
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 查询快捷设备，一般无需自行调用，如感觉快捷列表数据不正常的情况下，可查询看看
    public static func QueryQuickDevice(timeOut: TimeInterval = 8,
                                        timeOutHandle: @escaping ()->Void = {},
                                        success: @escaping ([BWDevice])->Void = { _ in },
                                        fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询快捷设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.queryQuickDevice() else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                var result = [BWDevice]()
                if let infos = json["infos"].array {
                    infos.forEach {
                        if $0["productType"].string == "BwCamera", let sn = $0["thirdUid"].string, let device = BWDevice.query(mac: sn) {
                            result.append(device)
                        } else if $0["productType"].string == "Door Lock", let ID = $0["deviceId"].int, let device = BWDevice.query(deviceID: ID) {
                            result.append(device)
                        } else if $0["productType"].string == "ContactS", let ID = $0["deviceId"].int, let device = BWDevice.query(deviceID: ID) {
                            result.append(device)
                        }
                    }
                }
                quickDevices = result
                success(result)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 查询快捷设备，无超时计时
    static func QueryQuickDeviceNoDelay() {
        BWSDKLog.shared.debug("无超时查询快捷设备")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return
        }
        guard let msg = ObjectMSG.queryQuickDevice() else {
            return
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                var result = [BWDevice]()
                if let infos = json["infos"].array {
                    infos.forEach {
                        if $0["productType"].string == "BwCamera", let sn = $0["thirdUid"].string, let device = BWDevice.query(mac: sn) {
                            result.append(device)
                        } else if $0["productType"].string == "Door Lock", let ID = $0["deviceId"].int, let device = BWDevice.query(deviceID: ID) {
                            result.append(device)
                        } else if $0["productType"].string == "ContactS", let ID = $0["deviceId"].int, let device = BWDevice.query(deviceID: ID) {
                            result.append(device)
                        }
                    }
                }
                quickDevices = result
                quickQuerySuccess?()
            }
        })
    }
    
    /// 数据透传设备获得report的cmd值，只有数据透传、背景音乐调用本方法有效，其余设备返回空字符串
    public func cmd() -> String {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return ""
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let cmd = json["cmd"].string {
                return cmd
            }
        }
        return ""
    }
    
    /// 温度，返回：nil表示未获取到  -1表示默认值  具体值表示具体温度，需要 /100 才是正常温度
    public func temp() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID!] {
            if let temp = json["temp"].int {
                return temp
            } else {
                return -1
            }
        }
        return nil
    }
    
    /// 空调网关温度
    public func acgTemp() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID!] {
            if let temp = json["curr_temp"].int {
                return temp
            } else {
                return -1
            }
        }
        return nil
    }
    
    /// 湿度，/100
    public func hum() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID!] {
            if let hum = json["hum"].int {
                return hum
            } else {
                return -1
            }
        }
        return nil
    }
    
    /// 二氧化碳
    public func co2() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID!] {
            if let co2 = json["co2"].int {
                return co2
            } else {
                return -1
            }
        }
        return nil
    }
    
    /// 甲醛，/100
    public func hcho() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID!] {
            if let hcho = json["hcho"].int {
                return hcho
            } else {
                return -1
            }
        }
        return nil
    }
    
    /// pm2.5，/10
    public func pm() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID!] {
            if let pm = json["pm25"].int {
                return pm
            } else {
                return -1
            }
        }
        return nil
    }
    
    /// 是否报警，只有安防设备有效，返回：true报警 false正常 nil未知
    public func isAlarm() -> Bool? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID!] {
            if let status = json["status"].string, status == "on" {
                return true
            } else {
                return false
            }
        }
        return nil
    }
    
    /// 是否睡眠，老门锁需要判断，新门锁无需判断
    public func isSleep() -> Bool? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID!] {
            if let status = json["wake"].int, status == 0 {
                return true
            } else {
                return false
            }
        }
        return nil
    }
    
    /// 获取开关状态，只有具有开关状态的设备有效，返回：true开  false关  nil表示离线
    public func onOffState() -> Bool? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let state = json["state"].string {
                if state == "on" {
                    return true
                } else if state == "off" {
                    return false
                }
            }
        }
        return nil
    }
    
    /// 获取在线离线状态，true 在线   false 离线  nil 未获取到
    public func onlineState() -> Bool? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let state = json["state"].string {
                if state == "offline" {
                    return false
                } else {
                    return true
                }
            }
        }
        return nil
    }
    
    /// 获取进度值
    public func levelValue() -> Int {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return 0
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let level = json["level"].int {
                return level
            }
        }
        return 0
    }
    
    /// 获取当前电量统计值，最终显示需要/1000
    public func power() -> Int {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return 0
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let power = json["power"].int {
                return power
            }
        }
        return 0
    }
    
    /// sysmode，温控器使用，模式，heat制热  cool制冷  fan_only送风  floor_heating_only地暖  floor_heating_air双制热 fan_heating送风地暖
    /// 空调网关，wind通风  dehumidify除湿
    /// 354温控器，off关机  heat开机
    public func sysMode() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let mode = json["sys_mode"].string {
                return mode
            }
        }
        return nil
    }
    
    /// fanmode，温控器使用，风速，low低速  medium中速  high高速  auto自动
    public func fanMode() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let fan = json["fan_mode"].string {
                return fan
            }
        }
        return nil
    }
    
    /// 空调网关风速
    public func acgFanMode() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let fan = json["wind_level"].string {
                return fan
            }
        }
        return nil
    }
    
    /// heatpoint，温控器使用，制热温度，/100是正常温度
    public func heatpoint() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let point = json["heatpoint"].int {
                return point
            }
        }
        return nil
    }
    
    /// coolpoint，温控器使用，制冷温度，/100是正常温度
    public func coolpoint() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let point = json["coolpoint"].int {
                return point
            }
        }
        return nil
    }
    
    /// 童锁，温控器使用，off表示关闭，on表示打开童锁
    public func lockModel() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let lock = json["lock_mode"].string {
                return lock
            }
        }
        return nil
    }
    
    /// 工作模式，温控器使用，leave_home离家  constant恒温  normal节能
    public func workModel() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let work = json["work_mode"].string {
                return work
            }
        }
        return nil
    }
    
    /// 音源
    public func xwSource() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let source = json["source"].string {
                return source
            }
        }
        return nil
    }
    
    /// 音量
    public func xwVolume() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let volume = json["volume"].string {
                return volume
            }
        }
        return nil
    }
    
    /// 模式
    public func xwMode() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let mode = json["mode"].string {
                return mode
            }
        }
        return nil
    }
    
    /// 电源
    public func xwPower() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let power = json["power"].string {
                return power
            }
        }
        return nil
    }
    
    /// 歌曲播放进度，毫秒，需/1000
    public func xwProgreess() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let progreess = json["progreess"].int {
                return progreess
            }
        }
        return nil
    }
    
    /// 播放
    public func xwPlay() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let play = json["play"].string {
                return play
            }
        }
        return nil
    }
    
    /// 歌曲名称
    public func xwSongName() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let name = json["songInfo"]["title"].string {
                return name
            }
        }
        return nil
    }
    
    /// 歌曲长度，毫秒，需/1000
    public func xwSongLong() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let duration = json["songInfo"]["duration"].int {
                return duration
            }
        }
        return nil
    }
    
    /// 歌曲歌手
    public func xwSongArtist() -> String? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1] {
            if let artist = json["songInfo"]["artist"].string {
                return artist
            }
        }
        return nil
    }
    
    /// 华尔思数据模型
    public struct HESModel {
        public let isLocal: Bool?//是否本地音乐
        public let localPath: String?//本地路径
        public let singerId: String?//歌手ID
        public let musicId: String?//歌曲ID
        public let musicName: String?//歌曲名
        public let singerName: String?//歌手名
        public let picUrl: String?//图片地址
        public let lrcUrl: String?//歌词地址
        public let bmp: String?//歌曲BMP（每一分钟的节拍数量）
        public let listenUrl: String?//标清试听地址
        public let hqListenUrl: String?//高清试听地址
        public let sqListenUrl: String?//无损试听地址
        public var isCollection: String?//是否收藏
        public let isCpAuth: String?//是否CP授权 1已授权 0未授权
        public let songAuthorName: String?//曲作者名
        public let lyricAuthorName: String?//词作者
        public let albumNames: [String]?//专辑名称列表
        public let length: Int?//歌曲时长
        public let language: String?//歌曲语种
        public let albumsId: String?//专辑ID
        public let musicSource: String?//歌曲来源 1垂
        public var volume: Int?//音量
        public let mode: Int?//播放模式
        
        /// 将model转字典
        public func toDic() -> [String: Any] {
            let length = length ?? 0
            let h = length/(60*60)
            let m = (length - h*60*60)/60
            let s = length%60
            return [
                "isLocal": isLocal ?? false,
                "localPath": localPath ?? "",
                "singerId": singerId ?? "",
                "musicId": musicId ?? "",
                "musicName": musicName ?? "",
                "singerName": singerName ?? "",
                "picUrl": picUrl ?? "",
                "lrcUrl": lrcUrl ?? "",
                "bmp": bmp ?? "",
                "listenUrl": listenUrl ?? "",
                "hqListenUrl": hqListenUrl ?? "",
                "sqListenUrl": sqListenUrl ?? "",
                "isCollection": isCollection ?? "",
                "isCpAuth": isCpAuth ?? "",
                "songAuthorName": songAuthorName ?? "",
                "lyricAuthorName": lyricAuthorName ?? "",
                "albumNames": albumNames ?? "",
                "length": "\(String(format: "%02d", h)):\(String(format: "%02d", m)):\(String(format: "%02d", s))",
                "language": language ?? "",
                "albumsId": albumsId ?? "",
                "musicSource": musicSource ?? "",
            ]
        }
        
        /// 解析json
        static func parseJSON(json: JSON) -> HESModel {
            let model = json
            let length = model["length"].string ?? ""
            var number = 0
            if length.contains(":") {
                let value = length.isEmpty ? "00:04:30" : length
                let arr = value.components(separatedBy: ":")
                if arr.count == 3 {
                    number += (Int(arr[0]) ?? 0)*60*60
                    number += (Int(arr[1]) ?? 0)*60
                    number += (Int(arr[2]) ?? 0)
                }
            } else {
                number = (Int(length) ?? 0)/1000
            }
            if number <= 0 {
                number = 4*60 + 30
            }
            return HESModel(isLocal: model["isLocal"].bool,
                            localPath: model["localPath"].string,
                            singerId: model["singerId"].string,
                            musicId: model["musicId"].string,
                            musicName: model["musicName"].string,
                            singerName: model["singerName"].string,
                            picUrl: model["picUrl"].string,
                            lrcUrl: model["lrcUrl"].string,
                            bmp: model["bmp"].string,
                            listenUrl: model["listenUrl"].string,
                            hqListenUrl: model["hqListenUrl"].string,
                            sqListenUrl: model["sqListenUrl"].string,
                            isCollection: model["isCollection"].string,
                            isCpAuth: model["isCpAuth"].string,
                            songAuthorName: model["songAuthorName"].string,
                            lyricAuthorName: model["lyricAuthorName"].string,
                            albumNames: model["albumNames"].array?.map { $0.string ?? "" },
                            length: number,
                            language: model["language"].string,
                            albumsId: model["albumsId"].string,
                            musicSource: model["musicSource"].string,
                            volume: json["volume"].int,
                            mode: json["mode"].int
            )
        }
    }
    /// 播放数据
    public func hesDataModel() -> HESModel? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1], json["action"].string == "status" {
            return BWDevice.HESModel.parseJSON(json: JSON.init(parseJSON: json["value"].string ?? ""))
        }
        return nil
    }
    
    /// 播放进度
    public func hesProgress() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1], json["action"].string == "playProgress" {
            return (json["value"].int ?? 0)/1000
        }
        return nil
    }
    
    /// 播放模式
    public func hesMode() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1], json["action"].string == "mode" {
            return json["value"].int
        }
        return nil
    }
    
    /// 播放音源
    public func hesSource() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1], json["action"].string == "source" {
            return json["value"].int
        }
        return nil
    }
    
    /// 播放状态
    public func hesPlayStatus() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1], json["action"].string == "play" {
            return json["value"].int
        }
        return nil
    }
    
    /// 播放音量
    public func hesVolume() -> Int? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1], json["action"].string == "volume" {
            return json["value"].int
        }
        return nil
    }
    
    /// 播放列表
    public func hesPlayList() -> [HESModel]? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1], json["action"].string == "playList" {
            let list = JSON.init(parseJSON: json["value"].string ?? "")
            return list.array?.map {
                BWDevice.HESModel.parseJSON(json: $0)
            }
        }
        return nil
    }
    
    /// 本地列表
    public func hesLocalList() -> [HESModel]? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1], json["action"].string == "localList" {
            let list = JSON.init(parseJSON: json["value"].string ?? "")
            return list.array?.map {
                BWDevice.HESModel.parseJSON(json: $0)
            }
        }
        return nil
    }
    
    /// 播放列表
    public func hesCollectList() -> [HESModel]? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1], json["action"].string == "collectList" {
            let list = JSON.init(parseJSON: json["value"].string ?? "")
            return list.array?.map {
                BWDevice.HESModel.parseJSON(json: $0)
            }
        }
        return nil
    }
    
    /// 搜索列表
    public func hesSearchList() -> [HESModel]? {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let json = BWDevice.deviceStatus[ID ?? -1], json["action"].string == "search" {
            let list = JSON.init(parseJSON: json["value"].string ?? "")
            return list.array?.map {
                BWDevice.HESModel.parseJSON(json: $0)
            }
        }
        return nil
    }
}

/// WIFI背景音乐
public class BWWifiBackgroundMusic: BWDevice {
    
    /// 设备转移成WIFI背景音乐设备
    static func Transfer(device: BWDevice) -> BWWifiBackgroundMusic {
        return BWWifiBackgroundMusic(attr: device.attr!,
                                     type: device.type!,
                                     ID: device.ID!,
                                     name: device.name!,
                                     hardVersion: device.hardVersion!,
                                     createTime: device.createTime!,
                                     mac: device.mac!,
                                     softVersion: device.softVersion!,
                                     model: device.model!,
                                     roomId: device.roomId!,
                                     parentId: device.parentId!)
    }
    
    /// 获取所有wifi背景音乐
    public static func queryWifiBM() -> [BWWifiBackgroundMusic] {
        BWSDKLog.shared.debug("查询WIFI背景音乐")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        let devices = BWDevice.query(type: .XWBackgroundMusic)
        return devices.map {
            Transfer(device: $0)
        }
    }
}


/// 摄像机
public class BWCamera: BWDevice {
    
    /// 登录用户名
    public var userName: String?
    
    /// 登录密码
    public var pwd: String?
    
    /// 摄像机更新回调
    public static var cameraNeedRefresh: (()->Void)?
    
    /// 老摄像机转移回调，从老数据库中转移摄像机时会触发该回调，安装过3.1版本app的情况下，需要处理该回调。否则可以忽略该回调。
    public static var oldCameraTransfer: ((BWCamera)->Void)?
    
    /// 设备转移成摄像机
    static func Transfer(device: BWDevice) -> BWCamera {
        let cam = BWCamera(attr: device.attr ?? "",
                           type: device.type ?? "",
                           ID: device.ID ?? -1,
                           name: device.name ?? "",
                           hardVersion: "",
                           createTime: device.createTime ?? "",
                           mac: device.mac ?? "",
                           softVersion: "",
                           model: device.model ?? "",
                           roomId: device.roomId ?? -1,
                           parentId: device.parentId ?? -1)
        cam.userName = device.hardVersion!
        cam.pwd = device.softVersion!
        return cam
    }
    
    /// 获取摄像机
    public static func queryCAM() -> [BWCamera] {
        BWSDKLog.shared.debug("查询摄像机")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        let devices = BWDevice.query(type: .Camera)
        return devices.map {
            Transfer(device: $0)
        }
    }
    
    /// 获取单个摄像机
    public static func querySingleCAM(ID: Int) -> BWCamera? {
        BWSDKLog.shared.debug("查询单个摄像机")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let device = BWDevice.query(deviceID: ID) {
            return Transfer(device: device)
        }
        return nil
    }
    
    /// 删除所有摄像机
    static func removeAllCam() {
        BWSDKLog.shared.debug("清空摄像机")
        BWDevice.delete(type: .Camera)
    }
}


public class BWCateye: BWDevice {
    
    /// 房间缓存   sn : roomId
    static var RoomCache = [String: Int]()
    
    /// 猫眼bid
    public var bid: String?
    
    /// 猫眼角色id
    public var role: Int?
    
    /// 上传猫眼房间给服务器
    /// - Parameters:
    ///   - did: 猫眼ID
    ///   - roomID: 房间ID
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func CateyeAdd(did: String,
                                 roomID: Int,
                                 timeOut: TimeInterval = 8,
                                 timeOutHandle: @escaping ()->Void = {},
                                 success: @escaping ()->Void = {},
                                 fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("上传猫眼房间给服务器")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.addCAM(info: [
            "type": 5,
            "sn": BWAppManager.shared.loginGateway?.sn ?? "",
            "devId": did,
            "devUsername": "",
            "devPwd": "",
            "devName": "",
            "roomId": roomID
        ]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                // 如果ID为-1，表示从房间删除
                if roomID == -1 {
                    // 从房间移除，需要重置房间排序
                    BWSDKLog.shared.info("从房间移除猫眼，重置排序ID")
                    let sort = BWDeviceRoomSort()
                    sort.belongId = did.hash
                    sort.sortId = sortRebootId
                    sort.save()
                }
                // 如果ID为非-1，同时和当前房间不相等，则表示修改了房间
                else if let old = BWCateye.RoomCache[did], roomID != old {
                    // 依旧需要重置房间排序
                    BWSDKLog.shared.info("猫眼从房间\(old)移动到另一个房间\(roomID)，重置排序ID")
                    let sort = BWDeviceRoomSort()
                    sort.belongId = did.hash
                    sort.sortId = sortRebootId
                    sort.save()
                }
                BWCateye.RoomCache[did] = roomID
                BWDevice.UpdateCateyeRoom(nid: did, roomId: roomID)
                BWDevice.needRefresh?()
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 将猫眼房间从服务器删除
    public static func CateyeDel(did: String,
                                 timeOut: TimeInterval = 8,
                                 timeOutHandle: @escaping ()->Void = {},
                                 success: @escaping ()->Void = {},
                                 fail: @escaping (Int)->Void = { _ in }) {
        BWCamera.CAMDel(did: did, timeOut: timeOut, timeOutHandle: timeOutHandle, success:
            {
                BWCateye.RoomCache.removeValue(forKey: did)
                success()
        }, fail: fail)
    }
    
    /// 单个猫眼保存
    public static func save(nid: String, bid: String, name: String, role: Int) {
        BWSDKLog.shared.debug("保存单个猫眼")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return
        }
        
        if BWDevice.wifiPermission == nil {
            let device = BWDevice()
            device.ID = nid.hash
            device.mac = nid
            device.type = ProductType.Cateye.rawValue
            device.attr = DeviceAttr.Cateye.rawValue
            device.name = name.isEmpty ? "智能猫眼" : name
            device.hardVersion = bid
            device.bindAlarm = role
            device.roomId = RoomCache[nid] ?? -1
            BWSDKLog.shared.debug("将猫眼整理成特殊device插入：\(device)")
            device.save()
        } else {
            let list = BWDevice.wifiPermission ?? []
            if list.contains(nid) {
                let device = BWDevice()
                device.ID = nid.hash
                device.mac = nid
                device.type = ProductType.Cateye.rawValue
                device.attr = DeviceAttr.Cateye.rawValue
                device.name = name.isEmpty ? "智能猫眼" : name
                device.hardVersion = bid
                device.bindAlarm = role
                device.roomId = RoomCache[nid] ?? -1
                BWSDKLog.shared.debug("将猫眼整理成特殊device插入：\(device)")
                device.save()
            }
        }
    }
    
    /// 清空所有猫眼
    public static func removeAllCateye() {
        BWSDKLog.shared.debug("清空猫眼")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return
        }
        BWDevice.delete(type: .Cateye)
    }
    
    /// 获取所有猫眼
    public static func queryCateye() -> [BWCateye] {
        BWSDKLog.shared.debug("查询猫眼")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return []
        }
        let devices = BWDevice.query(type: .Cateye)
        return devices.map {
            Transfer(device: $0)
        }
    }
    
    /// 设备转移成猫眼
    static func Transfer(device: BWDevice) -> BWCateye {
        let cateye = BWCateye(attr: device.attr!,
                              type: device.type!,
                              ID: device.ID!,
                              name: device.name!,
                              hardVersion: "",
                              createTime: device.createTime!,
                              mac: device.mac!,
                              softVersion: device.softVersion!,
                              model: device.model!,
                              roomId: device.roomId!,
                              parentId: device.parentId!)
        cateye.bid = device.hardVersion
        cateye.role = device.bindAlarm
        return cateye
    }
    
    /// 获取单个猫眼
    public static func querySingle(ID: Int) -> BWCateye? {
        BWSDKLog.shared.debug("查询单个猫眼")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return nil
        }
        if let device = BWDevice.query(deviceID: ID) {
            return Transfer(device: device)
        }
        return nil
    }
    
    /// 删除猫眼
    public static func deleteCateye(ID: Int) {
        BWSDKLog.shared.debug("删除单个猫眼")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return
        }
        BWDevice.delete(ID: ID)
        BWDeviceSort.delete(belongId: ID)
        BWDeviceRoomSort.delete(belongId: ID)
    }
}
