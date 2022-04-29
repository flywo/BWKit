//
//  BWZone.swift
//  BWKit
//
//  Created by yuhua on 2020/3/11.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON


/// 防区内传感器
public class BWSensor: BWDevice {
    
    /// 布撤防状态
    public var state: String?
    
    public override func mapping(map: Map) {
        ID <- map["id"]
        state <- map["state"]
    }
    
    /// 将指定设备的信息给自己
    func transferToSelf(device: BWDevice) {
        attr = device.attr
        type = device.type
        ID = device.ID
        name = device.name
        hardVersion = device.hardVersion
        createTime = device.createTime
        mac = device.mac
        softVersion = device.softVersion
        model = device.model
        roomId = device.roomId
    }
    
    /// 描述
    public override var description: String {
        return "[id:\(ID ?? -1) state:\(state ?? "") attr:\(attr ?? "") type:\(type ?? "") name:\(name ?? "") roomId:\(roomId ?? -1) model:\(model ?? "")]"
    }
}

/// 防区
public class BWZone: Mappable, CustomStringConvertible {
    
    /// 防区需要刷新的回调，会把最新的防区列表通过回调返回
    public static var needRefresh: (([BWZone])->Void)?
    
    /// ID
    public var ID: Int?
    
    /// 名称
    public var name: String?
    
    /// 状态
    public var state: String?
    
    /// 创建时间
    public var createTime: String?
    
    /// 延时
    public var delay: Int?
    
    /// 传感器
    public var sensors: [BWSensor]?
    
    init() {
    }
    
    /// 忽略该方法
    public required init?(map: Map) {
    }
    
    /// 忽略该方法
    public func mapping(map: Map) {
        ID <- map["id"]
        name <- map["name"]
        state <- map["state"]
        createTime <- map["create_time"]
        delay <- map["delay"]
        sensors <- map["sensor_list"]
    }
    
    /// 描述
    public var description: String {
        return "[ID:\(ID ?? -1) name:\(name ?? "") state:\(state ?? "") createTime:\(createTime ?? "") delay:\(delay ?? -1) sensors:\(sensors ?? [])]"
    }
}

/// 操作
extension BWZone {
    
    /// 防区缓存
    struct ZoneCache {
        static var zones = [BWZone]()
    }
    
    /// 从网关查询防区，防区只能通过本方法获取，注意：本方法会缓存防区数据，若防区在本次登录没有修改，则会立即通过success回调返回数据。
    /// - Parameters:
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func QueryZone(timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ([BWZone])->Void = { _ in }, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询防区列表")
        if ZoneCache.zones.count == 4 {
            success(ZoneCache.zones.copyZone())
            return
        }
        
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        
        ZoneCache.zones.removeAll()
        guard let msg = ObjectMSG.gatewayZoneQuery() else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                guard let list = json["zone_list"].rawString() else {
                    fail(-1)
                    return
                }
                let zones = [BWZone](JSONString: list) ?? [BWZone]()
                zones.forEach { zone in
                    zone.sensors?.forEach {
                        if let device = BWDevice.query(deviceID: $0.ID ?? -1) {
                            $0.transferToSelf(device: device)
                        }
                    }
                }
                ZoneCache.zones.append(contentsOf: zones)
                if json["end"].intValue == 1 {
                    BWAppManager.shared.killDelayTime()
                    success(ZoneCache.zones.copyZone())
                }
            } else {
                /// 需要end字段的，需自行清除回调
                BWAppManager.shared.killDelayTime()
                BWAppManager.shared.msgTimeOut(msg: msg)
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 切换防区，返回切换后的防区
    /// - Parameters:
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func changeZone(timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ([BWZone])->Void = { _ in }, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("切换防区")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayZoneChange(zoneID: ID!) else {
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
                ZoneCache.zones.forEach {
                    if $0.ID == self.ID {
                        $0.state = "on"
                    } else {
                        $0.state = "off"
                    }
                }
                success(ZoneCache.zones.copyZone())
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 编辑防区
    /// - Parameters:
    ///   - name: 名称
    ///   - state: 状态，该参数一般设置，传自己的值就行，on开  off关
    ///   - delay: 延时执行时间
    ///   - sensors: 传感器状态
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func edit(name: String,
                     state: String,
                     delay: Int,
                     sensors: [BWSensor],
                     timeOut: TimeInterval = 8,
                     timeOutHandle: @escaping ()->Void = {},
                     success: @escaping ()->Void = {},
                     fail: @escaping (Int)->Void = { _ in }
                     ) {
        BWSDKLog.shared.debug("编辑防区")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let id = ID else {
            BWSDKLog.shared.error("编辑防区未设置id！")
            fail(-1)
            return
        }
        var zone = [String: Any]()
        zone["id"] = id
        zone["name"] = name
        zone["state"] = state
        zone["delay"] = delay
        zone["sensor_list"] = sensors.map { item -> [String: Any] in
            var sensor = [String: Any]()
            sensor["id"] = item.ID ?? -1
            sensor["state"] = item.state ?? "off"
            return sensor
        }
        guard let msg = ObjectMSG.gatewayZoneEdit(zone: zone) else {
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
}

extension Array where Element: BWZone {
    func copyZone() -> [BWZone] {
        var result = [BWZone]()
        forEach {
            let zone = BWZone()
            zone.ID = $0.ID
            zone.name = $0.name
            zone.state = $0.state
            zone.createTime = $0.createTime
            zone.delay = $0.delay
            zone.sensors = [BWSensor]()
            $0.sensors?.forEach { copySensor in
                let sensor = BWSensor()
                sensor.state = copySensor.state
                sensor.transferToSelf(device: copySensor)
                zone.sensors?.append(sensor)
            }
            result.append(zone)
        }
        return result
    }
}
