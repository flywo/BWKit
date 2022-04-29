//
//  BWDoorLockUser.swift
//  BWKit
//
//  Created by yuhua on 2020/5/27.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON


public class BWDoorLockUser: Mappable {

    /// ID
    public var ID: Int?
    
    /// 类型 1密码 2指纹 4卡
    public var type: Int?
    
    /// 名称
    public var name: String?
    
    /// 有效时间，空无限制
    public var validDate: Int?
    
    /// 有效次数，空无限制
    public var validCount: Int?
    
    public init() {
    }
    
    public required init?(map: Map) {
    }
    
    public func mapping(map: Map) {
        ID <- map["DL_id"]
        type <- map["type"]
        name <- map["name"]
        validDate <- map["valid_date"]
        validCount <- map["valid_count"]
    }
    
    /// 门锁端删除用户回调，设备ID，门锁ID，用户类型
    public static var delUser: ((Int, Int, Int)->Void)?
    
    /// 门锁端添加用户回调，设备ID，门锁ID，用户类型
    public static var addUser: ((Int, Int, Int)->Void)?
    
    /// 编辑用户回调，设备ID，门锁ID，用户类型，门锁名称
    public static var editUser: ((Int, Int, Int, String)->Void)?
    
    /// 查询门锁用户
    /// - Parameters:
    ///   - deviceId: 门锁ID
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func Query(deviceId: Int,
                             timeOut: TimeInterval = 8,
                             timeOutHandle: @escaping ()->Void = {},
                             success: @escaping ([BWDoorLockUser])->Void = { _ in },
                             fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询门锁用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.doorLockUser(deviceId: deviceId) else {
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
                if let idsStr = json["device"]["ids"].rawString(), let users = [BWDoorLockUser].init(JSONString: idsStr) {
                    success(users)
                    return
                }
                fail(-1)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 添加门锁用户
    /// - Parameters:
    ///   - deviceId: 门锁ID
    ///   - type: 类型，1主用户 4普通哦用户 8挟持用户 12临时用户
    ///   - pwd: 密码
    ///   - time: 到期时间
    ///   - count: 开门次数
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，返回用户ID
    ///   - fail: 失败
    public static func Add(deviceId: Int,
                           type: Int,
                           pwd: String,
                           time: Date? = nil,
                           name: String,
                           count: Int? = nil,
                           timeOut: TimeInterval = 8,
                           timeOutHandle: @escaping ()->Void = {},
                           success: @escaping (Int)->Void = { _ in },
                           fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("添加门锁用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var device = [String: Any]()
        device["device_id"] = deviceId
        device["type"] = 1
        device["permi"] = type
        device["name"] = name
        device["pwd"] = pwd.encryptDoorLockPWD()
        if let time = time, type == 12 {
            let second = time.timeIntervalSince1970 - Date().timeIntervalSince1970
            if second > 0 {
                device["second"] = Int(second)
                device["valid_date"] = Int(time.timeIntervalSince1970)
            }
        }
        if let count = count, type == 12 {
            device["valid_count"] = count
        }
        guard let msg = ObjectMSG.doorLockUserAdd(device: device) else {
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
                if let ID = json["device"]["DL_id"].int {
                    success(ID)
                    return
                }
                fail(-1)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 编辑门锁用户
    /// - Parameters:
    ///   - name: 用户名称，只能修改名称
    ///   - deviceID: 设备ID
    ///   - DLID: 门锁ID
    ///   - type: 类型，1密码 2指纹 4卡
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func Edit(name: String,
                            deviceID: Int,
                            DLID: Int,
                            type: Int,
                            timeOut: TimeInterval = 8,
                            timeOutHandle: @escaping ()->Void = {},
                            success: @escaping ()->Void = {},
                            fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("编辑门锁用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var device = [String: Any]()
        device["device_id"] = deviceID
        device["type"] = type
        device["DL_id"] = DLID
        device["name"] = name
        guard let msg = ObjectMSG.doorLockUserEdit(device: device) else {
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
                BWDoorLockUser.editUser?(deviceID, DLID, type, name)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 删除门锁用户
    /// - Parameters:
    ///   - deviceId: 设备ID
    ///   - DLID: 用户ID
    ///   - type: 类型
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func Del(deviceID: Int,
                           DLID: Int,
                           type: Int,
                           timeOut: TimeInterval = 8,
                           timeOutHandle: @escaping ()->Void = {},
                           success: @escaping ()->Void = {},
                           fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("删除门锁用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var device = [String: Any]()
        device["device_id"] = deviceID
        device["type"] = type
        device["DL_id"] = DLID
        guard let msg = ObjectMSG.doorLockUserDel(device: device) else {
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
    
    /// 删除门锁指定类型所有用户
    /// - Parameters:
    ///   - deviceId: 设备ID
    ///   - type: 类型
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func Del(deviceID: Int,
                           type: Int,
                           timeOut: TimeInterval = 8,
                           timeOutHandle: @escaping ()->Void = {},
                           success: @escaping ()->Void = {},
                           fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("删除门锁类型用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var device = [String: Any]()
        device["device_id"] = deviceID
        device["type"] = type
        guard let msg = ObjectMSG.doorLockUserDel(device: device) else {
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
    
    /// 通知网关刷新门锁用户，发送该消息后，请等待至少40秒钟后再查询用户列表。否则可能会出现缺失的情况。
    /// - Parameters:
    ///   - deviceID: 设备ID
    public static func Refresh(deviceID: Int) {
        BWSDKLog.shared.debug("同步门锁用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return
        }
        guard let msg = ObjectMSG.doorLockUserRefresh(deviceId: deviceID) else {
            return
        }
        BWAppManager.shared.sendMSG(msg: msg)
    }
}
