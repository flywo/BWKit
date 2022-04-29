//
//  BWMSG.swift
//  BWKit
//
//  Created by yuhua on 2020/5/19.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON


/// 消息
public class BWMSG: Mappable, Hashable {
    
    public static func == (lhs: BWMSG, rhs: BWMSG) -> Bool {
        return lhs.msg == rhs.msg && lhs.time == rhs.time
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(msg)
        hasher.combine(time)
    }
    
    /// 通过闭包通知页面，未读条数刷新，界面需要刷新显示未读消息条数，通过unreadAlarm、unreadDoor、unreadEvent读取各自未读数目
    public static var UnreadNeedRefresh: (()->Void)?
    
    /// 收到推送会调用该闭包，页面需要自行处理逻辑
    public static var ReceiveMSG: ((BWMSG)->Void)?
    
    /// ID
    public var Id: Int?
    
    /// 消息类型：事件、门锁、报警
    public var msgType: MSGType?
    
    /// 设备ID
    public var deviceId: Int?
    
    /// 设备属性
    public var deviceAttr: String?
    
    /// 报警类型--报警
    public var alarmType: Int?
    
    /// 消息内容
    public var msg: String?
    
    /// 消息发生时间
    public var time: String?
    
    /// 消息发生日期
    public var timeDay: String?
    
    /// 消息发生时分秒
    public var timeTime: String?
    
    /// 用户
    public var user: String?
    
    /// 事件类型--门锁
    public var event: Int?
    
    /// 事件类型--事件
    public var eventType: Int?
    
    /// 未读报警消息条数
    public static var unreadAlarm: Int = 0
    
    /// 未读门锁消息条数
    public static var unreadDoor: Int = 0
    
    /// 未读事件消息条数
    public static var unreadEvent: Int = 0
    
    public required init?(map: Map) {
    }
    
    public func mapping(map: Map) {
        Id <- map["id"]
        deviceId <- map["device_id"]
        deviceAttr <- map["device_attr"]
        alarmType <- map["alarm_type"]
        msg <- map["msg"]
        time <- map["time"]
        user <- map["user"]
        event <- map["event"]
        eventType <- map["event_type"]
        let arr = time?.components(separatedBy: " ")
        timeDay = arr?.first ?? ""
        timeTime = arr?.last ?? ""
    }
}


/// 操作
extension BWMSG {
    /// 消息类型
    public enum MSGType: String {
        /// 报警
        case alarm = "alarm_record"
        /// 门锁
        case door = "door_record"
        /// 事件
        case event = "event_record"
        /// 设备
        case device = "device_record"
    }
    
    /// 查询未读消息
    static func QueryUnread() {
        BWSDKLog.shared.debug("查询未读消息数目")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return
        }
        BWMSG.unreadAlarm = 0
        BWMSG.unreadDoor = 0
        BWMSG.unreadEvent = 0
        BWMSG.UnreadNeedRefresh?()
        guard let alarm = ObjectMSG.queryMSGUnread(type: MSGType.alarm.rawValue) else {
            return
        }
        guard let door = ObjectMSG.queryMSGUnread(type: MSGType.door.rawValue) else {
            return
        }
        guard let event = ObjectMSG.queryMSGUnread(type: MSGType.event.rawValue) else {
            return
        }
        BWAppManager.shared.sendMSG(msg: alarm) { json in
            if let num = json["message"]["num"].int {
                BWMSG.unreadAlarm = num
                BWMSG.UnreadNeedRefresh?()
            }
            BWAppManager.shared.sendMSG(msg: door) { json in
                if let num = json["message"]["num"].int {
                    BWMSG.unreadDoor = num
                    BWMSG.UnreadNeedRefresh?()
                }
                BWAppManager.shared.sendMSG(msg: event) { json in
                    if let num = json["message"]["num"].int {
                        BWMSG.unreadEvent = num
                        BWMSG.UnreadNeedRefresh?()
                    }
                }
            }
        }
    }
    
    
    /// 查询消息
    /// - Parameters:
    ///   - type: 消息类型
    ///   - begin: 查询消息开始的id
    ///   - count: 数目
    ///   - deviceId: 具体门锁消息带上门锁id
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，会多次调用该方法返回消息内容，界面需自行处理顺序与过滤重复消息
    ///   - fail: 失败
    public static func QueryMSG(type: MSGType,
                                begin: Int,
                                count: Int,
                                deviceId: Int?,
                                timeOut: TimeInterval = 8,
                                timeOutHandle: @escaping ()->Void = {},
                                success: @escaping ([BWMSG])->Void = { _ in },
                                fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询消息")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.queryMSG(type: type.rawValue, start: begin, count: count, deviceId: deviceId) else {
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
                guard let list = json["message"]["record_list"].rawString() else {
                    fail(-1)
                    return
                }
                let msgs = [BWMSG](JSONString: list) ?? [BWMSG]()
                success(msgs)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 设置已读消息
    /// - Parameters:
    ///   - type: 类型
    ///   - msgId: 已读消息id
    public static func SetReadMSG(type: MSGType,
                                  msgId: Int) {
        BWSDKLog.shared.debug("设置已读消息")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return
        }
        guard let msg = ObjectMSG.setMSGRead(type: type.rawValue, msgId: msgId) else {
            return
        }
        if type == .alarm {
            BWMSG.unreadAlarm = 0
        } else if type == .door {
            BWMSG.unreadDoor = 0
        } else if type == .event {
            BWMSG.unreadEvent = 0
        }
        BWAppManager.shared.sendMSG(msg: msg)
    }
}

