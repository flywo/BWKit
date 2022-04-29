//
//  BWScene.swift
//  BWKit
//
//  Created by yuhua on 2020/3/4.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON


/// 场景
public class BWScene: Mappable, Equatable {
    
    /// 场景数据有变动，需要刷新，UI界面需重新获取数据
    public static var needRefresh: (()->Void)?
    
    /// 场景ID
    public var ID: Int?
    
    /// 名称
    public var name: String?
    
    /// 房间
    public var roomId: Int?
    
    /// 场景类型 0软 1硬
    public var type: Int?
    
    /// 硬场景设备ID
    public var deviceId: Int?
    
    /// 创建时间
    public var createTime: String?
    
    /// 场景图片ID
    public var pictureId: Int?
    
    /// 延时
    public var delay: Int?
    
    /// 指令
    public var instruct: [BWSceneInstruct]?
    
    public init() {
    }
    
    /// 初始化
    init(ID: Int,
         name: String,
         roomId: Int,
         type: Int,
         deviceId: Int,
         createTime: String,
         delay: Int,
         pictureId: Int) {
        self.ID = ID
        self.name = name
        self.roomId = roomId
        self.type = type
        self.deviceId = deviceId
        self.createTime = createTime
        self.delay = delay
        self.pictureId = pictureId
    }
    
    /// 忽略该方法
    public required init?(map: Map) {
    }
    
    /// 忽略该方法
    public func mapping(map: Map) {
        ID <- map["id"]
        name <- map["name"]
        roomId <- map["room_id"]
        type <- map["type"]
        deviceId <- map["device_id"]
        createTime <- map["create_time"]
        delay <- map["delay"]
        instruct <- map["instruct_list"]
        pictureId <- map["picture_id"]
        instruct?.forEach {
            $0.belongId = ID
        }
    }
    
    /// 描述
    public var description: String {
        return "[id:\(ID ?? -1) name:\(name ?? "") roomId:\(roomId ?? -1) type:\(type ?? -1) deviceId:\(deviceId ?? -1) createTime:\(createTime ?? "") delay:\(delay ?? -1) instruct:\(instruct ?? []) pictureId:\(pictureId ?? 0)]"
    }
    
    /// 比较
    public static func == (lhs: BWScene, rhs: BWScene) -> Bool {
        return lhs.ID == rhs.ID
    }
}

/// 执行操作
extension BWScene {
    
    /// 是否有场景存在----用于首页判断场景是否为空
    public static func isEmpty() -> Bool {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return false
        }
        return BWScene.queryCount() == 0
    }
    
    /// 查询数据，内部使用
    static func QueryScene(success: @escaping (Int)->Void = { _ in }, fail: @escaping ()->Void = {}) {
        guard let msg = ObjectMSG.gatewaySceneQuery() else {
            fail()
            return
        }
        
        BWScene.clear()
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                guard let list = json["scene_list"].rawString() else {
                    success(1)
                    return
                }
                let scenes = [BWScene](JSONString: list) ?? [BWScene]()
                BWSDKLog.shared.debug("场景内容:\(scenes)")
                scenes.save(dbName: BWAppManager.shared.loginGWDBName())
                scenes.forEach {
                    $0.instruct?.save(dbName: BWAppManager.shared.loginGWDBName())
                }
                success(json["end"].intValue)
            } else {
                fail()
            }
        })
    }
    
    /// 删除场景
    /// - Parameters:
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func delScene(timeOut: TimeInterval = 8,
                         timeOutHandle: @escaping ()->Void = {},
                         success: @escaping ()->Void = {},
                         fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("删除场景")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let id = ID else {
            BWSDKLog.shared.error("删除场景未设置id！")
            fail(-1)
            return
        }
        var scene = [String: Int]()
        scene["id"] = id
        let sceleList = [scene]
        guard let msg = ObjectMSG.gatewaySceneDel(list: sceleList) else {
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
    
    /// 编辑场景
    /// - Parameters:
    ///   - name: 名称
    ///   - roomId: 房间ID
    ///   - pictureId: 图标ID
    ///   - delay: 延时，单位是毫秒
    ///   - insturcts: 指令列表
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功
    ///   - fail: 失败
    public func editScene(name: String,
                          roomId: Int,
                          pictureId: Int = 0,
                          delay: Int,
                          instructs: [BWSceneInstruct],
                          timeOut: TimeInterval = 8,
                          timeOutHandle: @escaping ()->Void = {},
                          success: @escaping ()->Void = {},
                          fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("编辑场景")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let id = ID else {
            BWSDKLog.shared.error("编辑场景未设置id！")
            fail(-1)
            return
        }
        var scene = [String: Any]()
        scene["id"] = id
        scene["name"] = name
        scene["room_id"] = roomId
        scene["delay"] = delay
        scene["picture_id"] = pictureId
        scene["instruct_list"] = instructs.map { item -> [String: Any] in
            var link = [String: Any]()
            link["type"] = item.type ?? 0
            if item.type == 1 {
                link["scene_id"] = item.scene?.ID ?? 0
                link["delay"] = item.delay ?? 0
            } else if item.type == 2 {
                link["zone_id"] = item.zoneId ?? 1
                link["delay"] = item.delay ?? 0
            } else {
                link["device_id"] = item.device?.ID ?? -1
                link["delay"] = item.delay ?? 0
                link["device_status"] = JSON(parseJSON: item.deviceStatus ?? "").dictionaryObject
            }
            return link
        }
        guard let msg = ObjectMSG.gatewaySceneEdit(scene: scene) else {
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
    
    
    /// 添加场景
    /// - Parameters:
    ///   - name: 名称
    ///   - roomId: 房间ID
    ///   - pictureId: 图标ID
    ///   - delay: 延时，单位是毫秒
    ///   - insturcts: 指令列表
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功
    ///   - fail: 失败
    public static func AddScene(name: String,
                                roomId: Int,
                                pictureId: Int = 0,
                                delay: Int,
                                instructs: [BWSceneInstruct],
                                timeOut: TimeInterval = 8,
                                timeOutHandle: @escaping ()->Void = {},
                                success: @escaping ()->Void = {},
                                fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("添加场景")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var scene = [String: Any]()
        scene["name"] = name
        scene["room_id"] = roomId
        scene["delay"] = delay
        scene["picture_id"] = pictureId
        scene["instruct_list"] = instructs.map { item -> [String: Any] in
            var link = [String: Any]()
            link["type"] = item.type ?? 0
            if item.type == 1 {
                link["scene_id"] = item.scene?.ID ?? 0
                link["delay"] = item.delay ?? 0
            } else if item.type == 2 {
                link["zone_id"] = item.zoneId ?? 1
                link["delay"] = item.delay ?? 0
            } else {
                link["device_id"] = item.device?.ID ?? -1
                link["delay"] = item.delay ?? 0
                link["device_status"] = JSON(parseJSON: item.deviceStatus ?? "").dictionaryObject
            }
            return link
        }
        guard let msg = ObjectMSG.gatewaySceneAdd(scene: scene) else {
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
    
    
    /// 执行场景
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func exe(timeOut: TimeInterval = 8,
                    timeOutHandle: @escaping ()->Void = {},
                    success: @escaping ()->Void = {},
                    fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("执行场景")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let ID = ID else {
            BWSDKLog.shared.error("该场景没有场景ID，无法执行！")
            fail(-1)
            return
        }
        let scene = ["id": ID]
        guard let msg = ObjectMSG.gatewaySceneExe(scene: scene) else {
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
