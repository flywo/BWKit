//
//  BWRoom.swift
//  BWKit
//
//  Created by yuhua on 2020/3/4.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper


/// 房间
public class BWRoom: Mappable {
    
    /// 房间数据有变动，需要刷新，UI界面需重新获取数据
    public static var needRefresh: (()->Void)?
    
    /// 房间ID
    public var ID: Int?
    
    /// 房间名称
    public var name: String?
    
    /// 创建时间
    public var createTime: String?
    
    /// 初始化
    public init(ID: Int,
                name: String,
                createTime: String) {
        self.ID = ID
        self.name = name
        self.createTime = createTime
    }
    
    /// 忽略该方法
    public required init?(map: Map) {
    }
    
    /// 忽略该方法
    public func mapping(map: Map) {
        ID <- map["id"]
        name <- map["name"]
        createTime <- map["create_time"]
    }
    
    /// 描述
    public var description: String {
        return "[id:\(ID ?? -1) name:\(name ?? "") createTime:\(createTime ?? "")]"
    }
}

/// 执行操作
extension BWRoom {
    
    /// 查询数据，内部使用
    static func QueryRoom(success: @escaping (Int)->Void = { _ in }, fail: @escaping ()->Void = {}) {
        guard let msg = ObjectMSG.gatewayRoomQuery() else {
            fail()
            return
        }
        
        BWRoom.clear()
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if json["status"].intValue == 0 {
                guard let list = json["room_list"].rawString() else {
                    success(1)
                    return
                }
                let rooms = [BWRoom](JSONString: list) ?? [BWRoom]()
                rooms.save(dbName: BWAppManager.shared.loginGWDBName())
                success(json["end"].intValue)
            } else {
                fail()
            }
        })
    }
    
    /// 对房间进行设置
    /// - Parameters:
    ///   - name: 房间名
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功
    ///   - fail: 失败
    public func setRoomAttributes(name: String? = nil,
                                  timeOut: TimeInterval = 8,
                                  timeOutHandle: @escaping ()->Void = {},
                                  success: @escaping ()->Void = {},
                                  fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("编辑房间")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var room = [String: Any]()
        room["id"] = ID
        room["name"] = name ?? self.name
        guard let msg = ObjectMSG.gatewayRoomEdit(room: room) else {
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
    
    
    /// 删除房间
    /// - Parameters:
    ///   - id: 房间ID
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功
    ///   - fail: 失败
    public func delRoom(timeOut: TimeInterval = 8,
                        timeOutHandle: @escaping ()->Void = {},
                        success: @escaping ()->Void = {},
                        fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("删除房间")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let id = ID else {
            BWSDKLog.shared.error("删除房间未设置id！")
            fail(-1)
            return
        }
        var room = [String: Int]()
        room["id"] = id
        let roomList = [room]
        guard let msg = ObjectMSG.gatewayRoomDel(list: roomList) else {
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
    
    /// 添加房间
    /// - Parameters:
    ///   - name: 房间名
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功
    ///   - fail: 失败
    public static func AddRoom(name: String? = nil,
                               timeOut: TimeInterval = 8,
                               timeOutHandle: @escaping ()->Void = {},
                               success: @escaping ()->Void = {},
                               fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("添加房间")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let name = name, !name.isEmpty else {
            BWSDKLog.shared.error("房间未设置名称！")
            fail(-1)
            return
        }
        var room = [String: Any]()
        room["name"] = name
        guard let msg = ObjectMSG.gatewayRoomAdd(room: room) else {
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
