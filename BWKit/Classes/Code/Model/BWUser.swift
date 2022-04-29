//
//  BWUser.swift
//  BWKit
//
//  Created by yuhua on 2020/5/14.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON
import AVFoundation

/// 网关用户
public class BWUser: Mappable {
    
    /// 手机号
    public var phone: String?
    
    /// 别名
    public var alias: String?
    
    /// 类型 1普通用户  0管理员
    public var privilege: Int?
    
    /// 有效时间开始日期
    public var validStart: String?
    
    /// 有效时间结束时间
    public var validEnd: String?
    
    /// 创建时间
    public var createTime: String?
    
    public init() {
    }
    
    public required init?(map: Map) {
    }
    
    public func mapping(map: Map) {
        phone <- map["phone_num"]
        alias <- map["user_alias"]
        privilege <- map["privilege"]
        validStart <- map["valid_time_start"]
        validEnd <- map["valid_time"]
        createTime <- map["create_time"]
    }
}

/// 操作
extension BWUser {
    
    /// 查询当前网关用户列表
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func Query(timeOut: TimeInterval = 8,
                             timeOutHandle: @escaping ()->Void = {},
                             success: @escaping ([BWUser])->Void = { _ in },
                             fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询用户列表")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayUser(sn: BWAppManager.shared.loginGateway?.sn ?? "") else {
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
                guard let list = json["users"].rawString() else {
                    fail(-1)
                    return
                }
                let users = [BWUser](JSONString: list) ?? [BWUser]()
                success(users)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 转移权限
    /// - Parameters:
    ///   - pwd: 主用户密码
    ///   - toUserPhone: 转移给指定的用户
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func Transform(pwd: String,
                                 toUserPhone: String,
                                 timeOut: TimeInterval = 8,
                                 timeOutHandle: @escaping ()->Void = {},
                                 success: @escaping ()->Void = {},
                                 fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("用户转移权限")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayUserTrans(pwd: pwd, sn: BWAppManager.shared.loginGateway!.sn!, phone: toUserPhone) else {
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
    
    
    /// 检查手机号是否注册
    /// - Parameters:
    ///   - phone: 待检查手机号
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，true已经注册，false没注册
    ///   - fail: 失败
    public static func CheckUserRegister(phone: String,
                                         timeOut: TimeInterval = 8,
                                         timeOutHandle: @escaping ()->Void = {},
                                         success: @escaping (Bool)->Void = { _ in },
                                         fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("检查用户是否注册")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayUserRegcheck(phone: phone) else {
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
                success(json["user"]["registered"].int == 1 ? true : false)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 添加用户
    /// - Parameters:
    ///   - phone: 用户
    ///   - alias: 别名
    ///   - startTime: 开始时间，为nil时，表示永久有效
    ///   - endTime: 结束时间，为nil时，表示永久有效
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func Add(phone: String,
                           alias: String,
                           startTime: Date?,
                           endTime: Date?,
                           timeOut: TimeInterval = 8,
                           timeOutHandle: @escaping ()->Void = {},
                           success: @escaping ()->Void = {},
                           fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("添加用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayUserAdd(sn: BWAppManager.shared.loginGateway!.sn!,
                                                 phone: phone,
                                                 alias: alias,
                                                 timeStart: startTime?.toString(format: "yyyy-MM-dd HH:mm:ss") ?? "",
                                                 timeEnd: endTime?.toString(format: "yyyy-MM-dd HH:mm:ss") ?? "") else {
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
    
    
    public static func AddDeviceUser(deviceId: String,
                                     alias: String,
                                     startTime: Date?,
                                     endTime: Date?,
                                     timeOut: TimeInterval = 16,
                                     timeOutHandle: @escaping ()->Void = {},
                                     success: @escaping ()->Void = {},
                                     fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("添加设备用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayDeviceUserAdd(sn: BWAppManager.shared.loginGateway!.sn!,
                                                       deviceId: deviceId,
                                                       alias: alias,
                                                       timeStart: startTime?.toString(format: "yyyy-MM-dd HH:mm:ss") ?? "",
                                                       timeEnd: endTime?.toString(format: "yyyy-MM-dd HH:mm:ss") ?? "") else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                var device = [String: Any]()
                device["product_type"] = ProductType.HESBackgroundMusic.rawValue
                device["device_attr"] = DeviceAttr.HuaErSiBMusic.rawValue
                device["device_name"] = alias
                device["SN"] = deviceId
                guard let msg = ObjectMSG.gatewayDeviceAdd(device: device) else {
                    BWAppManager.shared.killDelayTime()
                    fail(-1)
                    return
                }
                BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
                    BWAppManager.shared.killDelayTime()
                    if json["status"].intValue == 0 {
                        success()
                    } else {
                        fail(json["status"].intValue)
                    }
                })
            } else {
                BWAppManager.shared.killDelayTime()
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 删除用户
    /// - Parameters:
    ///   - pwd: 密码
    ///   - phone: 删除用户
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func Del(pwd: String,
                           phone: String,
                           timeOut: TimeInterval = 8,
                           timeOutHandle: @escaping ()->Void = {},
                           success: @escaping ()->Void = {},
                           fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("删除用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayUserDel(pwd: pwd,
                                                 sn: BWAppManager.shared.loginGateway!.sn!,
                                                 phone: phone) else {
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
    
    
    /// 删除华尔思用户
    /// - Parameters:
    ///   - pwd: 密码
    ///   - phone: 删除用户
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func DelHES(pwd: String,
                              phone: String,
                              timeOut: TimeInterval = 16,
                              timeOutHandle: @escaping ()->Void = {},
                              success: @escaping ()->Void = {},
                              fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("删除华尔思用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayUserDel(pwd: pwd,
                                                 sn: BWAppManager.shared.loginGateway!.sn!,
                                                 phone: phone) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                let model = BWDevice.query(mac: phone)
                var device = [String: Int]()
                device["device_id"] = model?.ID ?? -1
                let deviceList = [device]
                guard let msg = ObjectMSG.gatewayDeviceDelete(list: deviceList) else {
                    BWAppManager.shared.killDelayTime()
                    fail(-1)
                    return
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
            } else {
                BWAppManager.shared.killDelayTime()
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 编辑用户
    /// - Parameters:
    ///   - phone: 手机号
    ///   - alias: 别名
    ///   - startTime: 开始时间，格式：2019-01-01 08:00:00
    ///   - endTime: 结束时间，格式同上
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func Edit(phone: String,
                            alias: String,
                            startTime: String,
                            endTime: String,
                            timeOut: TimeInterval = 8,
                            timeOutHandle: @escaping ()->Void = {},
                            success: @escaping ()->Void = {},
                            fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("编辑用户")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayUserEdit(sn: BWAppManager.shared.loginGateway!.sn!,
                                                  phone: phone,
                                                  alias: alias,
                                                  start: startTime,
                                                  end: endTime) else {
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
    
    
    /// 查询用户权限
    /// - Parameters:
    ///   - phone: 用户
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，返回权限是否开启及有权限设备
    ///   - fail: 失败
    public static func QueryPermission(phone: String,
                                       timeOut: TimeInterval = 8,
                                       timeOutHandle: @escaping ()->Void = {},
                                       success: @escaping ((Bool, [Int]))->Void = { _ in },
                                       fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询用户权限")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.queryUserPermissions(phone: phone) else {
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
                if let open = json["user"]["permission"].int {
                    let list = json["user"]["device_list"].array?.map { device -> Int in
                        device["device_id"].int ?? -1
                    } ?? []
                    success((open==1, list))
                }
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 查询权限，内部使用，会先去查询权限，然后再去服务器查询wifi设备
    /// - Parameter next: 继续下一步动作
    static func QueryPermission(next: @escaping ()->Void) {
        BWSDKLog.shared.debug("内部查询用户权限")
        guard let msg = ObjectMSG.queryUserPermissions(phone: BWAppManager.shared.username ?? "") else {
            next()
            return
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                if let open = json["user"]["permission"].int, open == 1 {
                    BWSDKLog.shared.debug("内部获取用户权限WIFI")
                    guard let msg = ObjectMSG.getUserWifiPermissions(sn: BWAppManager.shared.loginGateway?.sn ?? "", phone: BWAppManager.shared.username ?? "") else {
                        next()
                        return
                    }
                    BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
                        if json["status"].intValue == 0 {
                            if let arr = json["user"]["device_list"].array {
                                BWDevice.wifiPermission = arr.map { $0["device_id"].string ?? "" }
                                if BWDevice.wifiPermission == nil {
                                    BWDevice.wifiPermission = []
                                }
                            }
                        }
                        next()
                    })
                } else {
                    next()
                }
            } else {
                next()
            }
        })
    }
    
    
    /// 设置设备权限
    /// - Parameters:
    ///   - phone: 用户
    ///   - open: 是否打开
    ///   - IDs: 有权限设备ID
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func SetPermission(phone: String,
                                     open: Bool,
                                     IDs: [Int],
                                     timeOut: TimeInterval = 8,
                                     timeOutHandle: @escaping ()->Void = {},
                                     success: @escaping ()->Void = {},
                                     fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("设置用户权限")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.setUserPermissions(phone: phone, open: open ? 1 : 0, list: IDs.map { id -> [String: Int] in
            ["device_id": id]
        }) else {
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
    
    
    /// 设置wifi设备的权限
    /// - Parameters:
    ///   - phone: 手机号
    ///   - list: 设备id列表
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func SetWifiDevicePermission(phone: String,
                                               list: [String],
                                               timeOut: TimeInterval = 8,
                                               timeOutHandle: @escaping ()->Void = {},
                                               success: @escaping ()->Void = {},
                                               fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("设置用户权限WIFI")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.setUserWifiPermissions(sn: BWAppManager.shared.loginGateway?.sn ?? "", phone: phone, list: list) else {
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
    
    /// 获取wifi设备的权限
    /// - Parameters:
    ///   - phone: 手机号
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func GetWifiDevicePermission(phone: String,
                                               timeOut: TimeInterval = 8,
                                               timeOutHandle: @escaping ()->Void = {},
                                               success: @escaping ([String])->Void = { _ in },
                                               fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("获取用户权限WIFI")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.getUserWifiPermissions(sn: BWAppManager.shared.loginGateway?.sn ?? "", phone: phone) else {
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
                if let arr = json["user"]["device_list"].array {
                    success(arr.map { $0["device_id"].string ?? "" })
                } else {
                    success([])
                }
            } else {
                fail(json["status"].intValue)
            }
        })
    }
}
