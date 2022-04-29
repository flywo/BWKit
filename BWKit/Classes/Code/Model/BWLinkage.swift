//
//  BWLinkage.swift
//  BWKit
//
//  Created by yuhua on 2020/3/4.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON


/// 联动
public class BWLinkage: Mappable {
    
    /// 联动数据有变动，需要刷新，UI界面需重新获取数据
    public static var needRefresh: (()->Void)?
    
    /// id
    public var ID: Int?
    
    /// 名称
    public var name: String?
    
    /// 状态
    public var state: String?
    
    /// 时间设置是否打开，0关闭 1打开
    public var mode: Int?
    
    /// 时间设置
    public var timer: String?
    
    /// 延时
    public var delay: Int?
    
    /// 创建时间
    public var createTime: String?
    
    /// 指令
    public var linkInstruct: [BWLinkageInstruct]?
    
    /// 条件
    public var linkageOrigin: [BWLinkageOrigin]?
    
    /// 初始化
    init(ID: Int,
         name: String,
         state: String,
         mode: Int,
         timer: String,
         delay: Int,
         createTime: String) {
        self.ID = ID
        self.name = name
        self.state = state
        self.mode = mode
        self.timer = timer
        self.delay = delay
        self.createTime = createTime
    }
    
    public init() {
    }
    
    /// 忽略该方法
    public required init?(map: Map) {
    }
    
    /// 忽略该方法
    public func mapping(map: Map) {
        ID <- map["id"]
        name <- map["name"]
        state <- map["state"]
        mode <- map["mode"]
        delay <- map["delay"]
        createTime <- map["create_time"]
        linkInstruct <- map["link"]
        linkageOrigin <- map["origin"]
        linkInstruct?.forEach {
            $0.belongId = ID
        }
        linkageOrigin?.forEach {
            $0.belongId = ID
        }
        // 转换一下
        if let timerObject = map["timer"].currentValue {
            let json = JSON(timerObject)
            timer = json.rawString(options: .fragmentsAllowed) ?? ""
        }
    }
    
    /// 描述
    public var description: String {
        return "[id:\(ID ?? -1) name:\(name ?? "") state:\(state ?? "") mode:\(mode ?? -1) timer:\(timer ?? "") delay:\(delay ?? -1) createTime:\(createTime ?? "") linkInstruct:\(linkInstruct ?? []) linkageOrigin:\(linkageOrigin ?? [])]"
    }
}

/// 执行操作
extension BWLinkage {
    
    /// 查询数据，内部使用
    static func QueryLinkage(success: @escaping (Int)->Void = { _ in }, fail: @escaping ()->Void = {}) {
        guard let msg = ObjectMSG.gatewayLinkageQuery() else {
            fail()
            return
        }
        
        BWLinkage.clear()
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                guard let list = json["linkage_list"].rawString() else {
                    success(1)
                    return
                }
                let linkages = [BWLinkage](JSONString: list) ?? [BWLinkage]()
                BWSDKLog.shared.debug("联动内容:\(linkages)")
                linkages.save(dbName: BWAppManager.shared.loginGWDBName())
                linkages.forEach {
                    $0.linkInstruct?.save(dbName: BWAppManager.shared.loginGWDBName())
                    $0.linkageOrigin?.save(dbName: BWAppManager.shared.loginGWDBName())
                }
                success(json["end"].intValue)
            } else {
                fail()
            }
        })
    }
    
    
    /// 删除联动
    /// - Parameters:
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func delLinkage(timeOut: TimeInterval = 8,
                           timeOutHandle: @escaping ()->Void = {},
                           success: @escaping ()->Void = {},
                           fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("删除联动")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let id = ID else {
            BWSDKLog.shared.error("删除联动未设置id！")
            fail(-1)
            return
        }
        var linkage = [String: Int]()
        linkage["id"] = id
        let linkageList = [linkage]
        guard let msg = ObjectMSG.gatewayLinkageDel(list: linkageList) else {
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
    
    
    /// 编辑联动
    /// - Parameters:
    ///   - onlySetState: 是否只是设置开关状态，如果为true，则必须传入state，并且只有state有效。如果为false，则随意传，不传则使用原来的值。
    ///   - name: 名称
    ///   - state: 开关状态
    ///   - timerOpen: 是否打开时间段设置，1打开，0关闭。只允许传入这两个值和nil，勿传别的值。
    ///   - timerType: 时间类型，0一次 1重复
    ///   - timerStartDate: 开始日期，如：2019-01-01
    ///   - timerEndDate: 结束日期，如：2019-01-01
    ///   - timerStartTime: 开始时间，如08:40
    ///   - timerEndTime: 结束时间，如09:45
    ///   - timerRepeat: 重复规则， 01111111 对应 0 6543217
    ///   - delay: 延时执行时间
    ///   - origin: 联动条件
    ///   - link: 联动结果
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func editLinkage(onlySetState: Bool = true,
                            name: String? = nil,
                            state: String? = nil,
                            timerOpen: Int? = nil,
                            timerType: Int = 0,
                            timerStartDate: String = "",
                            timerEndDate: String = "",
                            timerStartTime: String = "",
                            timerEndTime: String = "",
                            timerRepeat: Int = 0,
                            delay: Int? = nil,
                            origins: [BWLinkageOrigin]? = nil,
                            links: [BWLinkageInstruct]? = nil,
                            timeOut: TimeInterval = 8,
                            timeOutHandle: @escaping ()->Void = {},
                            success: @escaping ()->Void = {},
                            fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("编辑联动")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let id = ID else {
            BWSDKLog.shared.error("编辑联动未设置id！")
            fail(-1)
            return
        }
        var linkage = [String: Any]()
        linkage["id"] = id
        if onlySetState {
            guard let state = state else {
                BWSDKLog.shared.error("只设置开关状态，但未设置状态值！")
                fail(-1)
                return
            }
            linkage["state"] = state
        } else {
            linkage["name"] = (name ?? self.name) ?? ""
            linkage["state"] = (state ?? self.state) ?? "on"
            linkage["mode"] = (timerOpen ?? self.mode) ?? 0
            if linkage["mode"] as? Int != 0 {
                if timerType == 1 {
                    linkage["timer"] = [
                        "type": timerType,
                        "start_time": timerStartTime,
                        "end_time": timerEndTime,
                        "repeat": timerRepeat
                    ]
                } else {
                    linkage["timer"] = [
                        "type": timerType,
                        "start_date": timerStartDate,
                        "end_date": timerEndDate,
                        "start_time": timerStartTime,
                        "end_time": timerEndTime,
                    ]
                }
            }
            linkage["delay"] = (delay ?? self.delay) ?? 0
            linkage["origin"] = origins?.map { item -> [String: Any] in
                var origin = [String: Any]()
                origin["device_id"] = item.device?.ID ?? -1
                origin["condition"] = item.condition ?? 0
                origin["device_status"] = JSON(parseJSON: item.deviceStatus ?? "").dictionaryObject
                return origin
            } ?? []
            linkage["link"] = links?.map { item -> [String: Any] in
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
            } ?? []
        }
        guard let msg = ObjectMSG.gatewayLinkageEdit(linkage: linkage) else {
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
    
    
    /// 添加联动
    /// - Parameters:
    ///   - name: 名称
    ///   - state: 状态：on开启  off关闭
    ///   - timerOpen: 时间设置是否开启：0关闭 1开启
    ///   - timerType: 时间类型，0一次 1重复
    ///   - timerStartDate: 开始日期，如：2019-01-01
    ///   - timerEndDate: 结束日期，如：2019-01-01
    ///   - timerStartTime: 开始时间，如08:40
    ///   - timerEndTime: 结束时间，如09:45
    ///   - timerRepeat: 重复规则， 01111111 对应 0 6543217
    ///   - delay: 联动延时
    ///   - origin: 联动添加
    ///   - link: 联动结果
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func AddLinkage(name: String,
                                  state: String = "on",
                                  timerOpen: Int = 0,
                                  timerType: Int = 0,
                                  timerStartDate: String = "",
                                  timerEndDate: String = "",
                                  timerStartTime: String = "",
                                  timerEndTime: String = "",
                                  timerRepeat: Int = 0,
                                  delay: Int = 0,
                                  origins: [BWLinkageOrigin] = [],
                                  links: [BWLinkageInstruct] = [],
                                  timeOut: TimeInterval = 8,
                                  timeOutHandle: @escaping ()->Void = {},
                                  success: @escaping ()->Void = {},
                                  fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("编辑联动")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var linkage = [String: Any]()
        linkage["name"] = name
        linkage["state"] = state
        linkage["mode"] = timerOpen
        if linkage["mode"] as? Int != 0 {
            if timerType == 1 {
                linkage["timer"] = [
                    "type": timerType,
                    "start_time": timerStartTime,
                    "end_time": timerEndTime,
                    "repeat": timerRepeat
                ]
            } else {
                linkage["timer"] = [
                    "type": timerType,
                    "start_date": timerStartDate,
                    "end_date": timerEndDate,
                    "start_time": timerStartTime,
                    "end_time": timerEndTime,
                ]
            }
        }
        linkage["delay"] = delay
        linkage["origin"] = origins.map { item -> [String: Any] in
            var origin = [String: Any]()
            origin["device_id"] = item.device?.ID ?? -1
            origin["condition"] = item.condition ?? 0
            origin["device_status"] = JSON(parseJSON: item.deviceStatus ?? "").dictionaryObject
            return origin
        }
        linkage["link"] = links.map { item -> [String: Any] in
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
        guard let msg = ObjectMSG.gatewayLinkageAdd(linkage: linkage) else {
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
