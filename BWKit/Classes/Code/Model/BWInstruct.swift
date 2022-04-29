//
//  BWInstruct.swift
//  BWKit
//
//  Created by yuhua on 2020/3/5.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON


/// 场景、定时、联动指令父类
public class BWInstruct: Mappable {
    
    /// 所属ID
    public var belongId: Int?
    
    /// ID
    public var ID: Int?
    
    /// 类型 0设备 1场景 2防区
    public var type: Int?
    
    /// 设备ID，类型为0设备是有
    public var deviceId: Int?
    
    /// 场景ID，类型为1场景时有
    public var sceneId: Int?
    
    /// 防区ID，类型为2防区时有
    public var zoneId: Int?
    
    /// 设备
    public var device: BWDevice?
    
    /// 场景
    public var scene: BWScene?
    
    /// 延时
    public var delay: Int?
    
    /// 控制状态
    public var deviceStatus: String?
    
    public init() {
        
    }
    
    /// 初始化
    init(ID: Int,
         type: Int,
         deviceId: Int,
         sceneId: Int,
         zoneId: Int,
         delay: Int,
         deviceStatus: String,
         belongId: Int) {
        self.ID = ID
        self.type = type
        self.deviceId = deviceId
        self.sceneId = sceneId
        self.zoneId = zoneId
        self.delay = delay
        self.deviceStatus = deviceStatus
        self.belongId = belongId
    }
    
    /// 忽略该方法
    public required init?(map: Map) {
    }
    
    /// 忽略该方法
    public func mapping(map: Map) {
        ID <- map["id"]
        type <- map["type"]
        deviceId <- map["device_id"]
        sceneId <- map["scene_id"]
        zoneId <- map["zone_id"]
        delay <- map["delay"]
        // 转换一下
        if let device_status = map["device_status"].currentValue {
            let json = JSON(device_status)
            deviceStatus = json.rawString(options: .fragmentsAllowed) ?? ""
        }
    }
    
    /// 描述
    public var description: String {
        return "[belongId:\(belongId ?? -1) ID:\(ID ?? -1) type:\(type ?? -1) deviceId:\(deviceId ?? -1) sceneId:\(sceneId ?? -1) zoneId:\(zoneId ?? -1) delay:\(delay ?? -1) deviceStatus:\(deviceStatus ?? "")]"
    }
}

/// 场景指令
public class BWSceneInstruct: BWInstruct {
    
}

/// 定时指令
public class BWTimerInstruct: BWInstruct {
    
}

/// 联动触发指令
public class BWLinkageInstruct: BWInstruct {
    
}

/// 联动条件
public class BWLinkageOrigin: Mappable {
    
    /// 设备ID
    public var deviceId: Int?
    
    /// 设备
    public var device: BWDevice?
    
    /// 条件 1等于 2小于 3大于 4小于等于 5大于等于
    public var condition: Int?
    
    /// 状态
    public var deviceStatus: String?
    
    /// 所属联动ID
    public var belongId: Int?
    
    public init() {
    }
    
    /// 初始化
    init(deviceId: Int,
         condition: Int,
         deviceStatus: String,
         belongId: Int) {
        self.deviceId = deviceId
        self.condition = condition
        self.deviceStatus = deviceStatus
        self.belongId = belongId
    }
    
    /// 忽略该方法
    public required init?(map: Map) {
    }
    
    /// 忽略该方法
    public func mapping(map: Map) {
        deviceId <- map["device_id"]
        condition <- map["condition"]
        // 转换一下
        if let device_status = map["device_status"].currentValue {
            let json = JSON(device_status)
            deviceStatus = json.rawString(options: .fragmentsAllowed) ?? ""
        }
    }
    
    /// 描述
    public var description: String {
        return "[deviceId:\(deviceId ?? -1) condition:\(condition ?? -1) deviceStatus:\(deviceStatus ?? "")]"
    }
}


/// 设备命令
public class BWDeviceCMD: Mappable {
    
    /// 所属ID
    public var belongId: Int?
    
    /// 名称
    public var name: String?
    
    /// 序号--红外
    public var index: Int?
    
    /// 是否学习--红外 0未学习  1已学习
    public var isStudy: Int?
    
    /// 控制命令--透传
    public var control: String?
    
    /// 反馈命令--透传
    public var back: String?
    
    /// 查询命令--透传
    public var query: String?
    
    /// 延时查询时间--透传，单位毫秒
    public var delay: Int?
    
    /// 是否高亮，UI界面使用，用于控制该命令所对应的按键是否是高亮显示。需外部自行设置。
    public var isOn: Bool = false
    
    /// 设备ID
    var deviceId: Int?
    
    /// 初始化
    init(belongId: Int,
         name: String,
         index: Int,
         isStudy: Int,
         control: String,
         back: String,
         query: String,
         delay: Int) {
        self.belongId = belongId
        self.name = name
        self.index = index
        self.isStudy = isStudy
        self.control = control
        self.back = back
        self.query = query
        self.delay = delay
    }
    
    public init() {
    }
    
    /// 忽略该方法
    public required init?(map: Map) {
    }
    
    /// 忽略该方法
    public func mapping(map: Map) {
        name <- map["name"]
        index <- map["index"]
        isStudy <- map["isstudy"]
        control <- map["control"]
        back <- map["back"]
        query <- map["query"]
        delay <- map["delay"]
        if map.mappingType == .fromJSON {
            if map["delay"].currentValue is String {
                delay = Int(map["delay"].currentValue as! String)
            }
        }
    }
    
    /// 描述
    public var description: String {
        return "[设备控制命令:\(name ?? "")]"
    }
    
    /// 查询设备命令，最终命令自行调用方法查看
    /// - Parameters:
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - deviceId: 设备ID
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func QueryCMD(timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, deviceId: Int, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询数据库设备控制命令列表")
        let cmds = BWDeviceCMD.query(deviceID: deviceId)
        if cmds.count > 0 {
            success()
            return
        }
        
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        
        guard let msg = ObjectMSG.gatewayDeviceCMDQuery(deviceID: deviceId) else {
            fail(-1)
            return
        }
        
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg) { json in
            if json["status"].intValue == 0 {
                guard let list = json["device"]["cmd_list"].rawString() else {
                    BWAppManager.shared.killDelayTime()
                    success()
                    return
                }
                let cmds = [BWDeviceCMD](JSONString: list)
                cmds?.forEach {
                    $0.belongId = deviceId
                }
                cmds?.save(dbName: BWAppManager.shared.loginGWDBName())
                if json["end"].intValue == 1 {
                    BWAppManager.shared.killDelayTime()
                    success()
                }
            } else {
                BWAppManager.shared.killDelayTime()
                fail(json["status"].intValue)
            }
        }
    }
    
    
    /// 红外控制命令发送学习，只有红外设备命令有效
    public func irLearn(deviceId: Int, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("发送红外学习")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        
        guard let msg = ObjectMSG.irLearn(deviceID: deviceId, name: name ?? "", index: index ?? 0) else {
            fail(-1)
            return
        }
        
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg) { json in
            if json["status"].intValue == 0 {
                success()
            } else {
                BWAppManager.shared.killDelayTime()
                fail(json["status"].intValue)
            }
        }
    }
    
    
    /// 控制命令进行控制，如果是数据透传命令，则先发送control，delay时间过后，发送query，需要根据设备deviceStatus回调来自行判断是否控制成功，success返回的只是消息发送成功。如果是红外，则发送index，根据success来判断是否成功。如果是背景音乐指令，判断逻辑同数据透传，需要根据deviceStatus回调来判断是否成功。
    /// - Parameters:
    ///   - deviceId: 设备ID
    ///   - timeOut: 超时，红外控制使用，数据透传忽略
    ///   - timeOutHandle: 超时，红外控制使用，透传忽略
    ///   - success: 透传忽略
    ///   - fail: 透传忽略
    public func control(deviceId: Int, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("发送命令:\(name ?? "")")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return
        }
        if BWDevice.query(deviceID: deviceId)?.type == ProductType.DataTransport.rawValue ||
            BWDevice.query(deviceID: deviceId)?.type == ProductType.BackgroundMusic.rawValue {
            BWDevice.dtResponse = { [weak self] ID, cmd in
                if deviceId == ID, self?.control?.contains(cmd) == true {
                    success()
                    BWDevice.dtResponse = nil
                }
            }
            sendDataMSG(deviceId: deviceId)
        } else if BWDevice.query(deviceID: deviceId)?.type == ProductType.IR.rawValue ||
            BWDevice.query(deviceID: deviceId)?.type == ProductType.AirCondition.rawValue {
            sendIRMSG(deviceId: deviceId, timeOut: timeOut, timeOutHandle: timeOutHandle, success: success, fail: fail)
        }
    }
    
    func sendIRMSG(deviceId: Int, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        guard let msg = ObjectMSG.deviceControl(deviceID: deviceId, deviceStatus: ["name": name ?? "", "index": index ?? 0]) else {
            return
        }
        BWSDKLog.shared.debug("发送控制:\(self)")
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg) { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                success()
            } else {
                fail(json["status"].intValue)
            }
        }
    }
    
    func sendDataMSG(deviceId: Int) {
        self.deviceId = deviceId
        if control?.isEmpty == false {
            sendControl()
            if query?.isEmpty == false {
                var delay: TimeInterval
                if let rawDelay = self.delay {
                    if rawDelay < 0 {
                        delay = 0
                    } else {
                        delay = TimeInterval(rawDelay)/1000.0
                    }
                } else {
                    delay = 0
                }
                BWSDKLog.shared.debug("命令延时:\(delay)")
                Timer.scheduledTimer(timeInterval: TimeInterval(delay), target: self, selector: #selector(sendQuery), userInfo: nil, repeats: false)
            }
        } else {
            if query?.isEmpty == false {
                sendQuery()
            }
        }
    }
    
    func sendControl() {
        if let control = control {
            let arr = control.components(separatedBy: "/")
            if arr.isEmpty {
                return
            }
            else if arr.count == 1 {
                guard let msg = ObjectMSG.deviceControl(deviceID: deviceId!, deviceStatus: ["cmd": arr.first!]) else {
                    return
                }
                BWSDKLog.shared.debug("发送控制:\(arr.first!)")
                BWAppManager.shared.sendMSG(msg: msg)
            } else {
                DispatchQueue.global().async {
                    var delay: TimeInterval
                    if let rawDelay = self.delay {
                        if TimeInterval(rawDelay) < 100 {
                            delay = 0.1
                        } else {
                            delay = TimeInterval(rawDelay)/1000.0
                        }
                    } else {
                        delay = 0.1
                    }
                    arr.forEach {
                        guard let msg = ObjectMSG.deviceControl(deviceID: self.deviceId!, deviceStatus: ["cmd": $0]) else {
                            return
                        }
                        BWSDKLog.shared.debug("分开发送命令:\($0)")
                        BWAppManager.shared.sendMSG(msg: msg)
                        Thread.sleep(forTimeInterval: delay)
                    }
                }
            }
        }
    }
    
    @objc func sendQuery() {
        guard let msg = ObjectMSG.deviceControl(deviceID: deviceId!, deviceStatus: ["cmd": query!]) else {
            return
        }
        BWSDKLog.shared.debug("发送查询:\(query ?? "")")
        BWAppManager.shared.sendMSG(msg: msg)
    }
}


