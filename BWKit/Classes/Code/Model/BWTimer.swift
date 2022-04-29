//
//  BWTimer.swift
//  BWKit
//
//  Created by yuhua on 2020/3/4.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON

/// 定时
public class BWTimer: Mappable {
    
    /// 定时数据有变动，需要刷新，UI界面需重新获取数据
    public static var needRefresh: (()->Void)?
    
    /// ID
    public var ID: Int?
    
    /// 名称
    public var name: String?
    
    /// 类型 0 单次 1重复
    public var type: Int?
    
    /// 状态 on 开启 off 关闭
    public var state: String?
    
    /// 日期
    public var date: String?
    
    /// 时间
    public var time: String?
    
    /// 重复 0x01111111 6543217
    public var repeatType: Int?
    
    /// 创建时间
    public var createTime: String?
    
    /// 指令
    public var instruct: [BWTimerInstruct]?
    
    public init() {
    }
    
    /// 初始化
    init(ID: Int,
         name: String,
         type: Int,
         state: String,
         date: String,
         time: String,
         repeatType: Int,
         createTime: String) {
        self.ID = ID
        self.name = name
        self.type = type
        self.state = state
        self.date = date
        self.time = time
        self.repeatType = repeatType
        self.createTime = createTime
    }
    
    /// 忽略该方法
    public required init?(map: Map) {
    }
    
    /// 忽略该方法
    public func mapping(map: Map) {
        ID <- map["id"]
        name <- map["name"]
        type <- map["type"]
        state <- map["state"]
        date <- map["date"]
        time <- map["time"]
        repeatType <- map["repeat"]
        createTime <- map["create_time"]
        instruct <- map["instruct_list"]
        instruct?.forEach {
            $0.belongId = ID
        }
    }
    
    /// 描述
    public var description: String {
        return "[id:\(ID ?? -1) name:\(name ?? "") type:\(type ?? -1) state:\(state ?? "") date:\(date ?? "") time:\(time ?? "") repeat:\(repeatType ?? -1) createTime:\(createTime ?? "") instruct:\(instruct ?? [])]"
    }
}

/// 执行操作
extension BWTimer {
    
    /// 查询数据，内部使用
    static func QueryTimer(success: @escaping (Int)->Void = { _ in }, fail: @escaping ()->Void = {}) {
        guard let msg = ObjectMSG.gatewayTimerQuery() else {
            fail()
            return
        }
        
        BWTimer.clear()
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                guard let list = json["timer_list"].rawString() else {
                    success(1)
                    return
                }
                let timers = [BWTimer](JSONString: list) ?? [BWTimer]()
                BWSDKLog.shared.debug("定时内容:\(timers)")
                timers.save(dbName: BWAppManager.shared.loginGWDBName())
                timers.forEach {
                    $0.instruct?.save(dbName: BWAppManager.shared.loginGWDBName())
                }
                success(json["end"].intValue)
            } else {
                fail()
            }
        })
    }
    
    /// 删除定时
    /// - Parameters:
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func delTimer(timeOut: TimeInterval = 8,
                         timeOutHandle: @escaping ()->Void = {},
                         success: @escaping ()->Void = {},
                         fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("删除定时")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let id = ID else {
            BWSDKLog.shared.error("删除定时未设置id！")
            fail(-1)
            return
        }
        var timer = [String: Int]()
        timer["id"] = id
        let timerList = [timer]
        guard let msg = ObjectMSG.gatewayTimerDel(list: timerList) else {
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
    
    /// 开启关闭定时
    /// - Parameters:
    ///   - open: 开启或者关闭
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func timerOpen(open: Bool,
                          timeOut: TimeInterval = 8,
                          timeOutHandle: @escaping ()->Void = {},
                          success: @escaping ()->Void = {},
                          fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("编辑定时")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let id = ID else {
            BWSDKLog.shared.error("编辑定时未设置id！")
            fail(-1)
            return
        }
        var timer = [String: Any]()
        timer["id"] = id
        timer["state"] = open ? "on" : "off"
        guard let msg = ObjectMSG.gatewayTimerEdit(timer: timer) else {
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
    
    /// 编辑定时
    /// - Parameters:
    ///   - name: 名称
    ///   - type: 类型， 0 单次   1 重复
    ///   - state: 状态， on 开启   off 关闭
    ///   - date: 日期，1990-11-11
    ///   - time: 时间，12:20
    ///   - repeatType: 重复周期，0x0111111 对应 6543217
    ///   - instructs: 指令
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func editTimer(name: String,
                          type: Int,
                          state: String,
                          date: String,
                          time: String,
                          repeatType: Int,
                          instructs: [BWTimerInstruct],
                          timeOut: TimeInterval = 8,
                          timeOutHandle: @escaping ()->Void = {},
                          success: @escaping ()->Void = {},
                          fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("编辑定时")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let id = ID else {
            BWSDKLog.shared.error("编辑定时未设置id！")
            fail(-1)
            return
        }
        var timer = [String: Any]()
        timer["id"] = id
        timer["name"] = name
        timer["type"] = type
        timer["state"] = state
        timer["date"] = date
        timer["time"] = time
        timer["repeat"] = repeatType
        timer["instruct_list"] = instructs.map { item -> [String: Any] in
            var link = [String: Any]()
            link["type"] = item.type ?? 0
            if item.type == 1 {
                link["scene_id"] = item.scene?.ID ?? 0
                link["delay"] = item.delay ?? 0
            } else {
                link["device_id"] = item.device?.ID ?? -1
                link["delay"] = item.delay ?? 0
                link["device_status"] = JSON(parseJSON: item.deviceStatus ?? "").dictionaryObject
            }
            return link
        }
        guard let msg = ObjectMSG.gatewayTimerEdit(timer: timer) else {
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
    
    
    /// 添加定时
    /// - Parameters:
    ///   - name: 名称
    ///   - type: 类型， 0 单次   1 重复
    ///   - state: 状态， on 开启   off 关闭
    ///   - date: 日期，1990-11-11
    ///   - time: 时间，12:20
    ///   - repeatType: 重复周期，0x0111111 对应 6543217
    ///   - instructs: 指令
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func AddTimer(name: String,
                                type: Int,
                                state: String,
                                date: String,
                                time: String,
                                repeatType: Int,
                                instructs: [BWTimerInstruct],
                                timeOut: TimeInterval = 8,
                                timeOutHandle: @escaping ()->Void = {},
                                success: @escaping ()->Void = {},
                                fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("添加定时")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var timer = [String: Any]()
        timer["name"] = name
        timer["type"] = type
        timer["state"] = state
        timer["date"] = date
        timer["time"] = time
        timer["repeat"] = repeatType
        timer["instruct_list"] = instructs.map { item -> [String: Any] in
            var link = [String: Any]()
            link["type"] = item.type ?? 0
            if item.type == 1 {
                link["scene_id"] = item.scene?.ID ?? 0
                link["delay"] = item.delay ?? 0
            } else {
                link["device_id"] = item.device?.ID ?? -1
                link["delay"] = item.delay ?? 0
                link["device_status"] = JSON(parseJSON: item.deviceStatus ?? "").dictionaryObject
            }
            return link
        }
        guard let msg = ObjectMSG.gatewayTimerAdd(timer: timer) else {
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
