//
//  BWMSGManager.swift
//  BWKit
//
//  Created by yuhua on 2020/3/3.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON


/// MSG固定部分
/*
 from,to,token发送消息前需指定，若后续该字段不会变化，则无需每次都设置
 */
struct MSGFix {
    private static let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    static var num = 0
    private static var fix = "iOS"
    private static var random = ""
    static var from = ""
    static var to = ""
    static var token = ""
    static var appId = ""
    
    
    /// 创建msg_type的随机字母，初始化时调用
    static func creatRandom() {
        num = 0
        random = String([getRadomChar(), getRadomChar()])
    }
    
    /// 获得msg_type，创建消息时ObjectMSG使用
    ///
    /// - Returns: msg_type
    static func getRandomMSGID() -> String {
        num = (num + 1) % 1000
        return fix + random + String(format: "-%03d", num)
    }
    
    
    /// 获得分包时的msg_id
    static func getFixRandomMSGID() -> String {
        return fix + random + String(format: "-%03d", num)
    }
    
    
    /// 获得随机的两位字母
    ///
    /// - Returns: 随机两位字母
    private static func getRadomChar() -> Character {
        let index = Int(arc4random_uniform(UInt32(characters.count)))
        return characters[characters.index(characters.startIndex, offsetBy: index)]
    }
}


/// 消息类，包括服务器与网关消息
class ObjectMSG: StaticMappable {
    /// 固定属性
    var version = "0.1"
    var from: String? = MSGFix.from
    var to: String? = MSGFix.to
    var ID: String?
    var token: String? = MSGFix.token
    var appId: String? = MSGFix.appId
    /// 需指定的属性
    var msgClass: String?
    var msgName: String?
    /// 默认为get
    var type: String? = "get"
    /// 注册+密码登录+修改密码+查询是否注册+重置密码+网关绑定+网关解绑
    var user: [String: Any]?
    /// 查询设备
    var typeList: [[String: String]]?
    /// 场景
    var scene: [String: Any]?
    /// 查询场景
    var sceneList: [[String: Int]]?
    /// 查询定时
    var timerList: [[String: Int]]?
    /// 查询联动
    var linkageList: [[String: Int]]?
    /// 联动
    var linkage: [String: Any]?
    /// 网关
    var gateway: [String: Any]?
    /// 组网
    var networkInfo: [String: Int]?
    /// 查询防区
    var zoneList: [[String: Int]]?
    /// 查询设备控制指令&控制设备
    var device: [String: Any]?
    /// 查询升级状态时使用
    var devices: [Any]?
    /// 查询设备当前状态
    var deviceList: [[String: Int]]?
    /// 定时
    var timer: [String: Any]?
    /// 防区控制
    var zone: [String: Any]?
    /// 房间
    var room: [String: Any]?
    /// 删除房间
    var roomList: [[String: Int]]?
    /// 允许、禁止设备入网
    var time: Int?
    /// 分包
    var end: Int?
    /// 短信
    var sms: [String: Int]?
    /// 第三方登录
    var loginInfo: [String: Any]?
    /// 消息
    var message: [String: Any]?
    /// 同步时间
    var syncTime: String?
    /// 摄像机
    var info: [String: Any]?
    /// 快捷设置
    var infos: [[String: Any]]?
    /// 网关sn
    var sn: String?
    /// 推送设置
    var config: [String: Any]?
    
    /// 转换对象
    ///
    /// - Parameter map: map
    /// - Returns: 对象
    static func objectForMapping(map: Map) -> BaseMappable? {
        return ObjectMSG()
    }
    
    /// 数据迁移
    ///
    /// - Parameter map: 数据
    func mapping(map: Map) {
        if map.mappingType == .toJSON {
            if end == nil {
                ID = MSGFix.getRandomMSGID()
            } else {
                ID = MSGFix.getFixRandomMSGID()
            }
        }
        version <- map["api_version"]
        from <- map["from"]
        to <- map["to"]
        ID <- map["msg_id"]
        msgClass <- map["msg_class"]
        msgName <- map["msg_name"]
        token <- map["token"]
        appId <- map["appId"]
        type <- map["msg_type"]
        user <- map["user"]
        typeList <- map["type_list"]
        sceneList <- map["scene_list"]
        timerList <- map["timer_list"]
        linkageList <- map["linkage_list"]
        zoneList <- map["zone_list"]
        device <- map["device"]
        deviceList <- map["device_list"]
        zone <- map["zone"]
        timer <- map["timer"]
        room <- map["room"]
        roomList <- map["room_list"]
        linkage <- map["linkage"]
        scene <- map["scene"]
        time <- map["time"]
        end <- map["end"]
        sms <- map["sms"]
        loginInfo <- map["login_info"]
        gateway <- map["gateway"]
        message <- map["message"]
        syncTime <- map["time"]
        info <- map["info"]
        infos <- map["infos"]
        sn <- map["sn"]
        config <- map["config"]
        networkInfo <- map["network_info"]
        
        if map.mappingType == .toJSON, devices != nil {
            devices <- map["device"]
        }
    }
    
    
    /// 获得完整消息
    ///
    /// - Parameter msg: 消息内容
    /// - Returns: 完整消息
    static func getFullMSG(msg: String?) -> String? {
        guard let str = msg, let data = str.data(using: .utf8) else {
            return nil
        }
        return "@#$%" + String(format: "%04x", 8 + data.count) + str
    }
}


// MARK: - 消息生成
extension ObjectMSG {
    /////////////////////服务器////////////////////////
    
    /// 心跳
    static func serverHeart() -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.AppCommon
        msg.msgName = MSGString.AppHeartbeat
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 密码登录
    static func serverUserLogin(pwd: String, appId: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.AppAuth
        msg.msgName = MSGString.UserLogin
        msg.token = nil
        msg.user = ["user_pwd": pwd, "appId": appId]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// token登录
    static func serverTokenLogin() -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.AppAuth
        msg.msgName = MSGString.TokenLogin
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// bj登录
    static func BJTokenLogin() -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.AppAuth
        msg.msgName = MSGString.BJLogin
        msg.token = "\(MSGFix.from)010".md5()
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 验证码登录
    static func codeLogin(code: String, channelID: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.AppAuth
        msg.msgName = MSGString.SMSLogin
        msg.token = ""
        msg.user = ["sms_code": code, "channelID": channelID]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 获取验证码
    static func getCode(type: Int) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.AppAuth
        msg.msgName = MSGString.SendSMSCode
        msg.token = ""
        msg.sms = ["type": type]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 第三方登录
    static func thirdLogin(info: [String: Any], user: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.ThirdAuth
        msg.msgName = MSGString.ThirdAuthLogin
        msg.token = ""
        msg.loginInfo = info
        msg.user = user
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 第三方绑定
    static func thirdBind(info: [String: Any], user: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.ThirdAuth
        msg.msgName = MSGString.ThirdAuthBind
        msg.token = ""
        msg.loginInfo = info
        msg.user = user
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 重置密码
    static func resetPassword(user: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.AppAuth
        msg.msgName = MSGString.ResetPWD
        msg.token = ""
        msg.user = user
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 注册手机号
    static func register(user: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.AppAuth
        msg.msgName = MSGString.UserRegWithCode
        msg.token = ""
        msg.user = user
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 网关列表
    static func serverGwappQueryToken() -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWAppMgmt
        msg.msgName = MSGString.GWAppQueryToken
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 解绑网关
    static func gatewayUnbind(sn: String, pwd: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWAppMgmt
        msg.msgName = MSGString.GWAppUnbind
        msg.type = "set"
        msg.user = ["sn": sn, "user_pwd": pwd]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 退出网关
    static func gatewayUserQuit(sn: String, pwd: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWUserMgmt
        msg.msgName = MSGString.GWUserQuit
        msg.type = "set"
        msg.user = ["sn": sn, "user_pwd": pwd]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 绑定网关
    static func gatewayBind(sn: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWAppMgmt
        msg.msgName = MSGString.GWAppBind
        msg.type = "set"
        msg.user = ["sn": sn]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 查询用户列表
    static func gatewayUser(sn: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWUserMgmt
        msg.msgName = MSGString.GWUserList
        msg.gateway = ["sn": sn]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 权限转移
    static func gatewayUserTrans(pwd: String, sn: String, phone: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWUserMgmt
        msg.msgName = MSGString.GWSetAdmin
        msg.type = "set"
        msg.user = [
            "user_pwd": pwd,
            "sn": sn,
            "phone_num": phone
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 查询用户是否注册
    static func gatewayUserRegcheck(phone: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.AppAuth
        msg.msgName = MSGString.UserRegcheck
        msg.user = ["phone_num": phone]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 添加用户
    static func gatewayUserAdd(sn: String, phone: String, alias: String, timeStart: String, timeEnd: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWUserMgmt
        msg.msgName = MSGString.GWUserAdd
        msg.type = "set"
        msg.user = [
            "sn": sn,
            "phone_num": phone,
            "user_alias": alias,
            "valid_time_start": timeStart,
            "valid_time": timeEnd
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 添加设备用户
    static func gatewayDeviceUserAdd(sn: String, deviceId: String, alias: String, timeStart: String, timeEnd: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWUserMgmt
        msg.msgName = MSGString.GWDeviceUserAdd
        msg.type = "set"
        msg.user = [
            "sn": sn,
            "deviceId": deviceId,
            "user_alias": alias,
            "valid_time_start": timeStart,
            "valid_time": timeEnd
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 删除用户
    static func gatewayUserDel(pwd: String, sn: String, phone: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWUserMgmt
        msg.msgName = MSGString.GWUserDel
        msg.type = "set"
        msg.user = [
            "user_pwd": pwd,
            "sn": sn,
            "phone_num": phone
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 编辑用户
    static func gatewayUserEdit(sn: String, phone: String, alias: String, start: String, end: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWUserMgmt
        msg.msgName = MSGString.GWUserEdit
        msg.type = "set"
        msg.user = [
            "sn": sn,
            "phone_num": phone,
            "user_alias": alias,
            "valid_time_start": start,
            "valid_time": end
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 查询权限
    static func queryUserPermissions(phone: String) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.UserMgmt
        msg.msgName = MSGString.UserPermissionGet
        msg.user = [
            "phone_num": phone
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 设置权限
    static func setUserPermissions(phone: String, open: Int, list: [[String: Int]]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.UserMgmt
        msg.msgName = MSGString.UserPermissionSet
        msg.type = "set"
        msg.user = [
            "phone_num": phone,
            "permission": open,
            "device_list": list
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 设置权限wifi
    static func setUserWifiPermissions(sn: String, phone: String, list: [String]) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWUserMgmt
        msg.msgName = MSGString.UserWifiPermissionSet
        msg.type = "set"
        msg.user = [
            "sn": sn,
            "phone_num": phone,
            "device_list": list.map {
                return ["device_id": $0]
            }
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 获取权限wifi
    static func getUserWifiPermissions(sn: String, phone: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.GWUserMgmt
        msg.msgName = MSGString.UserWifiPermissionGet
        msg.type = "get"
        msg.user = [
            "sn": sn,
            "phone_num": phone
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 上传推送ID
    static func uploadPushID(id: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.AppAuth
        msg.msgName = MSGString.JPushRegidUpload
        msg.type = "set"
        msg.user = [
            "jpush_regid": id,
            "channelID": "030"
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 添加摄像头
    static func addCAM(info: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.CAMMgmt
        msg.msgName = MSGString.CAMAdd
        msg.type = "set"
        msg.info = info
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 编辑摄像机
    static func editCAM(info: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.CAMMgmt
        msg.msgName = MSGString.CAMEdit
        msg.type = "set"
        msg.info = info
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 删除摄像机
    static func deleteCAM(ID: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.CAMMgmt
        msg.msgName = MSGString.CAMDel
        msg.type = "set"
        msg.info = [
            "devId": ID
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 查询摄像头
    static func queryCAM(sn: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.CAMMgmt
        msg.msgName = MSGString.CAMQuery
        msg.type = "get"
        msg.info = ["sn": sn]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 查询消息设置
    static func queryPushSet(type: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.MsgMgmt
        msg.msgName = MSGString.MSGPushGetConfig
        msg.type = "get"
        msg.config = ["type": type]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 查询网关短信条数
    static func querySMSNumber(sn: String) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.MsgMgmt
        msg.msgName = MSGString.MSGPushGetSMSBalance
        msg.type = "get"
        msg.config = ["gatewaySn": sn]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 设置推送
    static func setPush(type: String, app: Int, sms: Int) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.MsgMgmt
        msg.msgName = MSGString.MSGPushSetConfig
        msg.type = "set"
        msg.config = ["type": type, "app": app, "sms": sms, "wechat": 0, "email": 0]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 快捷设备设置
    static func setQuickDevice(infos: [[String: Any]]) -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.QuickMgmt
        msg.msgName = MSGString.SetQuick
        msg.type = "set"
        msg.infos = infos
        msg.sn = BWAppManager.shared.loginGateway?.sn
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 快捷设备查询
    static func queryQuickDevice() -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.msgClass = MSGString.QuickMgmt
        msg.msgName = MSGString.QueryQuick
        msg.sn = BWAppManager.shared.loginGateway?.sn
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /////////////////////网关////////////////////////
    
    /// 网关心跳
    static func gatewayHeart() -> String? {
        if let sn = BWAppManager.shared.loginGateway?.sn {
            let msg = ObjectMSG()
            msg.to = sn
            msg.msgClass = MSGString.AppCommon
            msg.msgName = MSGString.AppHeartbeat
            msg.type = "ping"
            return getFullMSG(msg: msg.toJSONString())
        }
        return nil
    }
    
    /// 搜索网关
    static func searchGateway() -> String? {
        let msg = ObjectMSG()
        msg.to = ""
        msg.from = ""
        msg.token = nil
        msg.msgClass = MSGString.GatewayMgmt
        msg.msgName = MSGString.GatewayDiscover
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 局域网登录网关
    static func gatewayLocalUserLogin(sn: String, pwd: String, appID: String) -> String? {
        let msg = ObjectMSG()
        msg.to = sn
        msg.token = ""
        msg.msgClass = MSGString.UserMgmt
        msg.msgName = MSGString.UserLogin
        msg.user = ["user_pwd": pwd, "appId": appID]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    /// 登录网关
    static func gatewayUserLogin(sn: String) -> String? {
        let msg = ObjectMSG()
        msg.to = sn
        msg.msgClass = MSGString.UserMgmt
        msg.msgName = MSGString.UserLogin
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 消息
    /// 查询消息未读数目
    static func queryMSGUnread(type: String) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.MsgMgmt
        msg.msgName = MSGString.UnreadNumGet
        msg.message = [
            "type": type
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 查询消息
    static func queryMSG(type: String, start: Int, count: Int, deviceId: Int?) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.MsgMgmt
        msg.msgName = MSGString.MsgQuery
        msg.message = [
            "type": type,
            "begin": start,
            "count": count
        ]
        if let ID = deviceId {
            msg.message?["device_id"] = ID
        }
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 设置已读消息
    static func setMSGRead(type: String, msgId: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.MsgMgmt
        msg.msgName = MSGString.ReadMsgidSet
        msg.type = "set"
        msg.message = [
            "type": type,
            "id": msgId
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 版本
    /// 数据版本查询
    static func gatewayCfgVerQuery() -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.VersionMgmt
        msg.msgName = MSGString.CFGVerQuery
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 获取网关固件版本
    static func gatewayHardVerQuery() -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.VersionMgmt
        msg.msgName = MSGString.HardVerQuery
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 网关升级
    static func gatewayUpdate() -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.VersionMgmt
        msg.msgName = MSGString.RequestGWUpdate
        msg.type = "set"
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 协调器升级
    static func gatewayHubUpdate() -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.VersionMgmt
        msg.msgName = MSGString.RequestHubUpdate
        msg.type = "set"
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 设备升级
    static func gatewayDeviceUpdate(deviceID: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.VersionMgmt
        msg.msgName = MSGString.RequestDeviceUpdate
        msg.type = "set"
        msg.device = ["device_id": deviceID]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 查询设备升级状态
    static func gatewayDeviceUpdateQuery() -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.VersionMgmt
        msg.msgName = MSGString.QueryDeviceUpdateState
        msg.type = "set"
        msg.devices = []
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 取消设备升级
    static func gatewayDeviceUpdateCancal(deviceIDs: [Int]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.VersionMgmt
        msg.msgName = MSGString.CancelDeviceUpdate
        msg.type = "set"
        msg.devices = deviceIDs.map { ["device_id": $0] }
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 网关
    /// 设置设备入网时间
    static func gatewayNetOpen(time: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.GatewayMgmt
        msg.msgName = MSGString.ZBNetOpen
        msg.type = "set"
        msg.time = time
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 设置网关别名
    static func gatewayAlias(alias: [String: String]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.GatewayMgmt
        msg.msgName = MSGString.GWAliasSet
        msg.type = "set"
        msg.gateway = alias
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 组建网络
    static func gatewayNetwork(info: [String: Int]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.GatewayMgmt
        msg.msgName = MSGString.BuildNetwork
        msg.type = "set"
        msg.networkInfo = info
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 查询网关网络设置
    static func gatewayNetworkInfo() -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.GatewayMgmt
        msg.msgName = MSGString.NetworkGet
        msg.type = "get"
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 设置网关网络设置
    static func gatewaySetNetworkInfo(info: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.GatewayMgmt
        msg.msgName = MSGString.NetworkSet
        msg.type = "set"
        msg.gateway = info
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 设备
    /// 查询设备列表
    static func gatewayDeviceQuery(list: [[String: String]]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DeviceQuery
        msg.typeList = list ?? []
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 添加设备
    static func gatewayDeviceAdd(device: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DeviceAdd
        msg.type = "set"
        msg.device = device
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 删除设备
    static func gatewayDeviceDelete(list: [[String: Int]]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DeviceDel
        msg.type = "set"
        msg.deviceList = list
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 编辑设备
    static func gatewayDeviceEdit(device: [String: Any], listEnd: Bool? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DeviceEdit
        if let end = listEnd {
            msg.end = end ? 1 : 0
        }
        msg.type = "set"
        msg.device = device
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 查询设备控制指令
    static func gatewayDeviceCMDQuery(deviceID: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DeviceCMDQuery
        msg.device = ["device_id": deviceID]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 波特率查询
    static func gatewayDeviceBaudQuery(deviceID: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.BaudQuery
        msg.device = ["device_id": deviceID]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 波特率设置
    static func gatewayDeviceBaudSet(deviceID: Int, baud: Int, parity: Int, stop: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.BaudSet
        msg.type = "set"
        msg.device = ["device_id": deviceID, "baud": baud, "parity_bit": parity, "stop_bit": stop]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 查询温控器模式
    static func workmode(deviceID: Int, type: String) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.WorkModeGet
        msg.device = [
            "device_id": deviceID,
            "workmode": [
                "name": type
            ]
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 设置温控器模式
    static func setWorkmode(deviceID: Int, name: String, mode: String, point: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.WorkModeConfig
        msg.type = "set"
        if mode == "cool" {
            msg.device = [
                "device_id": deviceID,
                "workmode": [
                    "name": name,
                    "sys_mode": mode,
                    "coolpoint": point
                ]
            ]
        } else if mode == "heat" {
            msg.device = [
                "device_id": deviceID,
                "workmode": [
                    "name": name,
                    "sys_mode": mode,
                    "heatpoint": point
                ]
            ]
        } else {
            msg.device = [
                "device_id": deviceID,
                "workmode": [
                    "name": name,
                    "sys_mode": mode
                ]
            ]
        }
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 门锁用户查询
    static func doorLockUser(deviceId: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DLIdQuery
        msg.device = ["device_id": deviceId]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 门锁用户添加
    static func doorLockUserAdd(device: [String: Any]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DLIdAdd
        msg.type = "set"
        msg.device = device
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 门锁用户修改
    static func doorLockUserEdit(device: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DLIdEdit
        msg.type = "set"
        msg.device = device
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 删除门锁用户
    static func doorLockUserDel(device: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DLIdDel
        msg.type = "set"
        msg.device = device
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 门锁用户同步
    static func doorLockUserRefresh(deviceId: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DLIdSync
        msg.device = ["device_id": deviceId]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 设备绑定
    static func bind(deviceId: Int, bindId: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DeviceBind
        msg.type = "set"
        msg.device = ["deviceId": deviceId, "bind_deviceId": bindId]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 绑定查询
    static func bindQuery(deviceId: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DeviceBindQuery
        msg.device = ["deviceId": deviceId]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 发现XW设备
    static func findXWBG() -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.DiscoveryTCPDevice
        msg.type = "set"
        msg.device = [
            "device_type": "Xiangwang Background Music",
            "device_mode": "MU303"
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 连接XW设备
    static func connectXWBG(mac: String) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.ConnectTCPDevice
        msg.type = "set"
        msg.device = [
            "device_type": "Xiangwang Background Music",
            "mac": mac
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 绑定XW设备
    static func bindXWBG(attr: String, name: String, roomId: Int, mac: String) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.DeviceMgmt
        msg.msgName = MSGString.BindTCPDevice
        msg.type = "set"
        msg.device = [
            "device_type": "Xiangwang Background Music",
            "device_attr": attr,
            "device_name": name,
            "room_id": roomId,
            "mac": mac
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 场景
    /// 查询场景
    static func gatewaySceneQuery(list: [[String: Int]]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.SceneMgmt
        msg.msgName = MSGString.SceneQuery
        msg.sceneList = list ?? []
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 删除场景
    static func gatewaySceneDel(list: [[String: Int]]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.SceneMgmt
        msg.msgName = MSGString.SceneDel
        msg.type = "set"
        msg.sceneList = list ?? []
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 添加场景
    static func gatewaySceneAdd(scene: [String: Any]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.SceneMgmt
        msg.msgName = MSGString.SceneAdd
        msg.type = "set"
        msg.scene = scene
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 编辑场景
    static func gatewaySceneEdit(scene: [String: Any]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.SceneMgmt
        msg.msgName = MSGString.SceneEdit
        msg.type = "set"
        msg.scene = scene
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 执行场景
    static func gatewaySceneExe(scene: [String: Int]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.SceneMgmt
        msg.msgName = MSGString.SceneExe
        msg.type = "set"
        msg.scene = scene
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 定时
    /// 查询定时
    static func gatewayTimerQuery(list: [[String: Int]]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.TimerMgmt
        msg.msgName = MSGString.TimerQuery
        msg.timerList = list ?? []
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 删除定时
    static func gatewayTimerDel(list: [[String: Int]]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.TimerMgmt
        msg.msgName = MSGString.TimerDel
        msg.type = "set"
        msg.timerList = list ?? []
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 增加定时
    static func gatewayTimerAdd(timer: [String: Any]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.TimerMgmt
        msg.msgName = MSGString.TimerAdd
        msg.type = "set"
        msg.timer = timer
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 编辑定时
    static func gatewayTimerEdit(timer: [String: Any]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.TimerMgmt
        msg.msgName = MSGString.TimerEdit
        msg.type = "set"
        msg.timer = timer
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 联动
    /// 查询联动
    static func gatewayLinkageQuery(list: [[String: Int]]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.LinkageMgmt
        msg.msgName = MSGString.LinkageQuery
        msg.linkageList = list ?? []
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 添加联动
    static func gatewayLinkageAdd(linkage: [String: Any]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.LinkageMgmt
        msg.msgName = MSGString.LinkageAdd
        msg.type = "set"
        msg.linkage = linkage
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 删除联动
    static func gatewayLinkageDel(list: [[String: Int]]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.LinkageMgmt
        msg.msgName = MSGString.LinkageDel
        msg.type = "set"
        msg.linkageList = list ?? []
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 编辑联动
    static func gatewayLinkageEdit(linkage: [String: Any]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.LinkageMgmt
        msg.msgName = MSGString.LinkageEdit
        msg.type = "set"
        msg.linkage = linkage
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 房间
    /// 查询房间
    static func gatewayRoomQuery() -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.RoomMgmt
        msg.msgName = MSGString.RoomQuery
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 添加房间
    static func gatewayRoomAdd(room: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.RoomMgmt
        msg.msgName = MSGString.RoomAdd
        msg.type = "set"
        msg.room = room
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 删除房间
    static func gatewayRoomDel(list: [[String: Int]]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.RoomMgmt
        msg.msgName = MSGString.RoomDel
        msg.type = "set"
        msg.roomList = list ?? []
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 编辑房间
    static func gatewayRoomEdit(room: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.RoomMgmt
        msg.msgName = MSGString.RoomEdit
        msg.type = "set"
        msg.room = room
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 防区
    /// 查询防区
    static func gatewayZoneQuery(list: [[String: Int]]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.ZoneMgmt
        msg.msgName = MSGString.ZoneQuery
        msg.zoneList = list ?? []
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 切换防区
    static func gatewayZoneChange(zoneID: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.ZoneMgmt
        msg.msgName = MSGString.ZoneSwitch
        msg.type = "set"
        msg.zone = ["id": zoneID]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 防区编辑
    static func gatewayZoneEdit(zone: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.ZoneMgmt
        msg.msgName = MSGString.ZoneEdit
        msg.type = "set"
        msg.zone = zone
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 控制
    /// 查询设备状态
    static func deviceState(type: String? = nil, deviceIDs: [Int]? = nil) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.ControlMgmt
        msg.msgName = MSGString.DeviceStateGet
        if let type = type {
            msg.device = ["type": type]
        } else if let deviceIDS = deviceIDs {
            msg.deviceList = deviceIDS.map {
                return ["device_id": $0]
            }
        }
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 控制设备
    static func deviceControl(deviceID: Int, deviceStatus: [String: Any]) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.ControlMgmt
        msg.msgName = MSGString.DeviceControl
        msg.type = "set"
        msg.device = ["device_id": deviceID,
                      "device_status": deviceStatus]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// identify命令
    static func deviceIdentify(deviceID: Int, time: Int = 10) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.ControlMgmt
        msg.msgName = MSGString.Identify
        msg.type = "set"
        msg.device = ["device_id": deviceID,
                      "time": time]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 红外学习
    static func irLearn(deviceID: Int, name: String, index: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.ControlMgmt
        msg.msgName = MSGString.IRLearn
        msg.type = "set"
        msg.device = [
            "id": deviceID,
            "key": [
                "name": name,
                "index": index
            ]
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    /// 请求随机码
    static func doorLockRandom(deviceId: Int) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.ControlMgmt
        msg.msgName = MSGString.DoorlockRequestOpen
        msg.type = "set"
        msg.device = [
            "device_id": deviceId
        ]
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 用户
    /// 同步时间
    static func timeSync() -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.UserMgmt
        msg.msgName = MSGString.TimeSync
        msg.type = "set"
        msg.syncTime = Date().toString(format: "yyyy-MM-dd HH:mm:ss")
        return getFullMSG(msg: msg.toJSONString())
    }
    
    // MARK: 电量统计
    /// 查询用电记录
    static func power(deviceId: Int, type: String) -> String? {
        let msg = ObjectMSG()
        msg.msgClass = MSGString.PowerMgmt
        msg.msgName = MSGString.PowerRecordQuery
        let date = Date()
        if type == "hour" {
            msg.device = [
                "device_id": deviceId,
                "unit": type,
                "year": Int(date.toString(format: "yyyy")) ?? 0,
                "month": Int(date.toString(format: "MM")) ?? 0,
                "day": Int(date.toString(format: "dd")) ?? 0
            ]
        } else if type == "day" {
            msg.device = [
                "device_id": deviceId,
                "unit": type,
                "year": Int(date.toString(format: "yyyy")) ?? 0,
                "month": Int(date.toString(format: "MM")) ?? 0
            ]
        } else if type == "month" {
            msg.device = [
                "device_id": deviceId,
                "unit": type,
                "year": Int(date.toString(format: "yyyy")) ?? 0
            ]
        } else if type == "year" {
            msg.device = [
                "device_id": deviceId,
                "unit": type
            ]
        }
        return getFullMSG(msg: msg.toJSONString())
    }
}

// MARK: - 消息解析
extension ObjectMSG {
    
    /// 解析消息
    static func paraseMSG(msg: JSON) {
        // 类型
        switch msg["msg_class"].stringValue {
        case MSGString.DeviceMgmt:
            deviceMSG(msg: msg)
        case MSGString.ControlMgmt:
            controlMSG(msg: msg)
        case MSGString.ZoneMgmt:
            zoneMSG(msg: msg)
        case MSGString.TimerMgmt:
            timerMSG(msg: msg)
        case MSGString.SceneMgmt:
            sceneMSG(msg: msg)
        case MSGString.LinkageMgmt:
            linkageMSG(msg: msg)
        case MSGString.RoomMgmt:
            roomMSG(msg: msg)
        case MSGString.GatewayMgmt:
            gatewayMSG(msg: msg)
        case MSGString.VersionMgmt:
            gatewayVersion(msg: msg)
        default:
            otherMSG(msg: msg)
        }
    }
    
    /// 设备消息
    static func deviceMSG(msg: JSON) {
        /// 查询防区信息
        func queryZone() {
            BWZone.ZoneCache.zones.removeAll()
            guard let msg = ObjectMSG.gatewayZoneQuery() else {
                return
            }
            BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
                if json["status"].intValue == 0 {
                    guard let list = json["zone_list"].rawString() else {
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
                    BWZone.ZoneCache.zones.append(contentsOf: zones)
                    if json["end"].intValue == 1 {
                        BWZone.needRefresh?(BWZone.ZoneCache.zones.copyZone())
                    }
                }
            })
        }
        
        if msg["msg_name"].stringValue == MSGString.DeviceAdd {
            BWSDKLog.shared.debug("收到设备添加报告")
            if let raw = msg["device"].rawString() {
                if let device = BWDevice(JSONString: raw) {
                    let parent = BWDevice.query(deviceID: device.parentId ?? -1)
                    device.parentId = parent?.parentId
                    device.save()
                    let sort = BWDeviceSort()
                    sort.belongId = device.ID
                    sort.sortId = sortRebootId
                    sort.save()
                    let roomSort = BWDeviceRoomSort()
                    roomSort.belongId = device.ID
                    roomSort.sortId = sortRebootId
                    roomSort.save()
                    BWDevice.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.DeviceDel {
            BWSDKLog.shared.debug("收到设备删除报告")
            if let list = msg["device_list"].array {
                list.forEach {
                    if let ID = $0["device_id"].int {
                        
                        // 安防传感器，清除掉缓存
                        if let device = BWDevice.query(deviceID: ID), device.type == ProductType.IasZone.rawValue {
                            queryZone()
                        }
                        
                        func deleteWith(Id: Int) {
                            // 场景、定时、联动中同时删除该设备ID
                            BWSceneInstruct.delete(ID: Id)
                            BWTimerInstruct.delete(ID: Id)
                            BWLinkageOrigin.delete(ID: Id)
                            BWLinkageInstruct.delete(ID: Id)
                            // 删除排序
                            BWDeviceSort.delete(belongId: Id)
                            BWDeviceRoomSort.delete(belongId: Id)
                        }
                        
                        BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
                            // 透传红外，先删除子设备
                            if let device = BWDevice.query(deviceID: ID),
                                (device.attr == DeviceAttr.IR.rawValue || device.attr == DeviceAttr.DataTransport.rawValue) {
                                let subs = BWDevice.query(parentId: device.parentId ?? -1)
                                subs.forEach {
                                    deleteWith(Id: $0.ID ?? -1)
                                }
                                BWSDKLog.shared.debug("删除父和子设备，父设备ID:\(device.parentId ?? -1)")
                                BWDevice.delete(parentId: device.parentId ?? -1)
                            } else {
                                deleteWith(Id: ID)
                                BWSDKLog.shared.debug("删除子设备，子设备ID:\(ID)")
                                BWDevice.delete(ID: ID)
                            }
                        }
                    }
                }
                BWDevice.needRefresh?()
            }
        } else if msg["msg_name"].stringValue == MSGString.DeviceEdit {
            BWSDKLog.shared.debug("收到设备编辑报告")
            if let raw = msg["device"].rawString() {
                if let device = BWDevice(JSONString: raw) {
                    let dbDevice = BWDevice.query(deviceID: device.ID ?? -1)
                    if let id = device.roomId {
                        // 如果ID为-1，表示从房间删除
                        if id == -1 {
                            // 从房间移除，需要重置房间排序
                            BWSDKLog.shared.info("从房间移除设备，重置排序ID")
                            let sort = BWDeviceRoomSort()
                            sort.belongId = device.ID
                            sort.sortId = sortRebootId
                            sort.save()
                        }
                        // 如果ID为非-1，同时和当前房间不相等，则表示修改了房间
                        else if id != dbDevice?.roomId {
                            // 依旧需要重置房间排序
                            BWSDKLog.shared.info("设备从房间移动到另一个房间，重置排序ID")
                            let sort = BWDeviceRoomSort()
                            sort.belongId = device.ID
                            sort.sortId = sortRebootId
                            sort.save()
                        }
                    }
                    dbDevice?.name = device.name ?? dbDevice?.name
                    dbDevice?.attr = device.attr ?? dbDevice?.attr
                    dbDevice?.roomId = device.roomId ?? dbDevice?.roomId
                    dbDevice?.bindAlarm = device.bindAlarm ?? dbDevice?.bindAlarm
                    dbDevice?.bindCateye = device.bindCateye ?? dbDevice?.bindCateye
                    dbDevice?.typeId = device.typeId ?? dbDevice?.typeId
                    dbDevice?.acGatewayId = device.acGatewayId ?? dbDevice?.acGatewayId
                    dbDevice?.acOutSideId = device.acOutSideId ?? dbDevice?.acOutSideId
                    if let _ = device.cmds {
                        BWSDKLog.shared.debug("编辑了设备指令，清空本机指令。")
                        BWDeviceCMD.delete(belongID: device.ID ?? -1)
                    }
                    dbDevice?.update()
                    BWDevice.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.BindTCPDevice {
            BWSDKLog.shared.debug("收到TCP设备绑定报告")
            if let raw = msg["device"].rawString() {
                if let device = BWDevice(JSONString: raw) {
                    device.save()
                    let sort = BWDeviceSort()
                    sort.belongId = device.ID
                    sort.sortId = sortRebootId
                    sort.save()
                    let roomSort = BWDeviceRoomSort()
                    roomSort.belongId = device.ID
                    roomSort.sortId = sortRebootId
                    roomSort.save()
                    BWDevice.needRefresh?()
                    if let type = device.type, let rawType = ProductType(rawValue: type) {
                        BWDevice.QueryDeviceStatus(type: rawType)
                    }
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.DeviceReport {
            BWSDKLog.shared.debug("收到设备入网报告")
            if let raw = msg["device"].rawString() {
                if let device = BWDevice(JSONString: raw) {
                    device.isNew = true
                    device.save()
                    let sort = BWDeviceSort()
                    sort.belongId = device.ID
                    sort.sortId = sortRebootId
                    sort.save()
                    let roomSort = BWDeviceRoomSort()
                    roomSort.belongId = device.ID
                    roomSort.sortId = sortRebootId
                    roomSort.save()
                    BWDevice.needRefresh?()
                    BWDevice.deviceNetworkReport?(device)
                    if let type = device.type, let rawType = ProductType(rawValue: type) {
                        BWDevice.QueryDeviceStatus(type: rawType)
                    }
                    // 安防传感器，清除掉缓存
                    if device.type == ProductType.IasZone.rawValue {
                        queryZone()
                    }
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.DevInfoReport {
            BWSDKLog.shared.debug("收到设备信息报告")
            if let raw = msg["device"].rawString() {
                if let device = BWDevice(JSONString: raw) {
                    device.updateInfo()
                    BWDevice.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.DeviceQuery {
            BWSDKLog.shared.debug("收到设备查询response")
            let type_list = msg["type_list"].arrayValue
            type_list.forEach {
                if let list = $0["device_list"].rawString() {
                    let devices = [BWDevice](JSONString: list) ?? [BWDevice]()
                    devices.save(dbName: BWAppManager.shared.loginGWDBName())
                }
            }
            BWDevice.needRefresh?()
        } else if msg["msg_name"].stringValue == MSGString.DeviceCMDQuery {
            BWSDKLog.shared.debug("收到设备命令查询response")
            if let list = msg["device"]["cmd_list"].rawString(), let deviceId = msg["device"]["device_id"].int {
                let cmds = [BWDeviceCMD](JSONString: list)
                cmds?.forEach {
                    $0.belongId = deviceId
                }
                cmds?.save(dbName: BWAppManager.shared.loginGWDBName())
            }
            BWDevice.needRefresh?()
        } else if msg["msg_name"].stringValue == MSGString.DeviceBind {
            BWSDKLog.shared.debug("收到设备绑定报告")
            BWDevice.bindHandle?()
        } else if msg["msg_name"].stringValue == MSGString.DiscoveryTCPDevice {
            BWSDKLog.shared.debug("收到向往发现设备报告")
            if let device = msg["device"].dictionary, let status = msg["status"].int {
                BWDevice.xwHandle?(status, device["device_type"]?.string, device["mac"]?.string, device["ip"]?.string, device["port"]?.int)
            }
        } else if msg["msg_name"].stringValue == MSGString.UndefDLId {
            BWSDKLog.shared.debug("收到门锁用户未设置名称报告")
            if let device = msg["device"].dictionary,
                let deviceId = device["device_id"]?.int,
                let doorUserId = device["DL_id"]?.int,
                let type = device["type"]?.int {
                BWDevice.undefDoorUserOpen?(deviceId, doorUserId, type)
            }
        } else if msg["msg_name"].stringValue == MSGString.DLIdAdd {
            BWSDKLog.shared.debug("收到门锁用户添加报告")
            if let device = msg["device"].dictionary,
                let deviceId = device["device_id"]?.int,
                let doorUserId = device["DL_id"]?.int,
                let type = device["type"]?.int {
                BWDoorLockUser.addUser?(deviceId, doorUserId, type)
            }
        } else if msg["msg_name"].stringValue == MSGString.DLIdDel {
            BWSDKLog.shared.debug("收到门锁用户删除报告")
            if let device = msg["device"].dictionary,
                let deviceId = device["device_id"]?.int,
                let doorUserId = device["DL_id"]?.int,
                let type = device["type"]?.int{
                BWDoorLockUser.delUser?(deviceId, doorUserId, type)
            }
        } else {
            BWSDKLog.shared.debug("该消息无需处理")
        }
    }
    
    /// 房间消息
    static func roomMSG(msg: JSON) {
        if msg["msg_name"].stringValue == MSGString.RoomAdd {
            BWSDKLog.shared.debug("收到房间增加报告")
            if let raw = msg["room"].rawString() {
                if let room = BWRoom(JSONString: raw) {
                    room.save()
                    let sort = BWRoomSort()
                    sort.belongId = room.ID
                    sort.sortId = sortRebootId
                    sort.save()
                    BWRoom.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.RoomDel {
            BWSDKLog.shared.debug("收到房间删除报告")
            if let list = msg["room_list"].array {
                list.forEach {
                    if let ID = $0["id"].int {
                        BWRoom.delete(ID: ID)
                        BWRoomSort.delete(belongId: ID)
                    }
                }
                BWRoom.needRefresh?()
            }
        } else if msg["msg_name"].stringValue == MSGString.RoomEdit {
            BWSDKLog.shared.debug("收到房间编辑报告")
            if let raw = msg["room"].rawString() {
                if let room = BWRoom(JSONString: raw) {
                    BWRoom.delete(ID: room.ID ?? -1)
                    room.save()
                    BWRoom.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.RoomQuery {
            BWSDKLog.shared.debug("收到房间查询response")
            if let raw = msg["room_list"].rawString() {
                let rooms = [BWRoom](JSONString: raw) ?? [BWRoom]()
                rooms.save(dbName: BWAppManager.shared.loginGWDBName())
            }
            BWRoom.needRefresh?()
        } else {
            BWSDKLog.shared.debug("该消息无处理")
        }
    }
    
    /// 场景消息
    static func sceneMSG(msg: JSON) {
        if msg["msg_name"].stringValue == MSGString.SceneAdd {
            BWSDKLog.shared.debug("收到场景增加报告")
            if let raw = msg["scene"].rawString() {
                if let scene = BWScene(JSONString: raw) {
                    let sort = BWSceneSort()
                    sort.belongId = scene.ID
                    sort.sortId = sortRebootId
                    sort.save()
                    scene.save()
                    scene.instruct?.save(dbName: BWAppManager.shared.loginGWDBName())
                    BWScene.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.SceneDel {
            BWSDKLog.shared.debug("收到场景删除报告")
            if let list = msg["scene_list"].array {
                list.forEach {
                    if let ID = $0["id"].int {
                        BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
                            // 找出场景，然后删除场景对应的硬场景设备
                            let scene = BWScene.query(sceneID: ID)
                            if let deviceID = scene?.deviceId {
                                BWSDKLog.shared.debug("删除场景时同时删除设备:\(deviceID)")
                                BWDevice.delete(ID: deviceID)
                            }
                            BWSceneSort.delete(belongId: ID)
                            BWScene.delete(ID: ID)
                            // 场景、定时、联动中同时删除该场景ID
                            BWSceneInstruct.delete(sceneID: ID)
                            BWTimerInstruct.delete(sceneID: ID)
                            BWLinkageInstruct.delete(sceneID: ID)
                        }
                    }
                }
                BWScene.needRefresh?()
            }
        } else if msg["msg_name"].stringValue == MSGString.SceneEdit {
            BWSDKLog.shared.debug("收到场景编辑报告")
            if let raw = msg["scene"].rawString() {
                if let scene = BWScene(JSONString: raw) {
                    let dbScene = BWScene.query(sceneID: scene.ID ?? -1)
                    dbScene?.name = scene.name ?? dbScene?.name
                    dbScene?.roomId = scene.roomId ?? dbScene?.roomId
                    dbScene?.delay = scene.delay ?? dbScene?.delay
                    dbScene?.pictureId = scene.pictureId ?? dbScene?.pictureId
                    if let instructs = scene.instruct {
                        BWSDKLog.shared.debug("场景指令替换")
                        BWSceneInstruct.delete(belongID: scene.ID ?? -1)
                        instructs.save(dbName: BWAppManager.shared.loginGWDBName())
                    }
                    dbScene?.update()
                    BWScene.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.SceneQuery {
            BWSDKLog.shared.debug("收到场景查询response")
            if let list = msg["scene_list"].rawString() {
                let scenes = [BWScene](JSONString: list) ?? [BWScene]()
                scenes.save(dbName: BWAppManager.shared.loginGWDBName())
                scenes.forEach {
                    $0.instruct?.save(dbName: BWAppManager.shared.loginGWDBName())
                }
            }
            BWScene.needRefresh?()
        } else {
            BWSDKLog.shared.debug("该消息无需处理")
        }
    }
    
    /// 定时消息
    static func timerMSG(msg: JSON) {
        if msg["msg_name"].stringValue == MSGString.TimerAdd {
            BWSDKLog.shared.debug("收到定时增加报告")
            if let raw = msg["timer"].rawString() {
                if let timer = BWTimer(JSONString: raw) {
                    let sort = BWTimerSort()
                    sort.belongId = timer.ID
                    sort.sortId = sortRebootId
                    sort.save()
                    timer.save()
                    timer.instruct?.save(dbName: BWAppManager.shared.loginGWDBName())
                    BWTimer.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.TimerDel {
            BWSDKLog.shared.debug("收到定时删除报告")
            if let list = msg["timer_list"].array {
                list.forEach {
                    if let ID = $0["id"].int {
                        BWTimerSort.delete(belongId: ID)
                        BWTimer.delete(ID: ID)
                    }
                }
                BWTimer.needRefresh?()
            }
        } else if msg["msg_name"].stringValue == MSGString.TimerEdit {
            BWSDKLog.shared.debug("收到定时编辑报告")
            if let raw = msg["timer"].rawString() {
                if let timer = BWTimer(JSONString: raw) {
                    let dbTimer = BWTimer.query(ID: timer.ID ?? -1)
                    dbTimer?.name = timer.name ?? dbTimer?.name
                    dbTimer?.type = timer.type ?? dbTimer?.type
                    dbTimer?.state = timer.state ?? dbTimer?.state
                    dbTimer?.date = timer.date ?? dbTimer?.date
                    dbTimer?.time = timer.time ?? dbTimer?.time
                    dbTimer?.repeatType = timer.repeatType ?? dbTimer?.repeatType
                    if let instructs = timer.instruct {
                        BWSDKLog.shared.debug("定时指令替换")
                        BWTimerInstruct.delete(belongID: timer.ID ?? -1)
                        instructs.save(dbName: BWAppManager.shared.loginGWDBName())
                    }
                    dbTimer?.update()
                    BWTimer.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.TimerQuery {
            BWSDKLog.shared.debug("收到定时查询response")
            if let list = msg["timer_list"].rawString() {
                let timers = [BWTimer](JSONString: list) ?? [BWTimer]()
                timers.save(dbName: BWAppManager.shared.loginGWDBName())
                timers.forEach {
                    $0.instruct?.save(dbName: BWAppManager.shared.loginGWDBName())
                }
            }
            BWTimer.needRefresh?()
        } else {
            BWSDKLog.shared.debug("该消息无需处理")
        }
    }
    
    /// 防区消息
    static func zoneMSG(msg: JSON) {
        if msg["msg_name"].stringValue == MSGString.ZoneSwitch {
            BWSDKLog.shared.debug("收到防区切换报告")
            if let ID = msg["zone"]["id"].int {
                BWZone.ZoneCache.zones.forEach { $0.state = "off" }
                if let zone = BWZone.ZoneCache.zones.first(where: { $0.ID == ID }) {
                    zone.state = "on"
                }
                BWZone.needRefresh?(BWZone.ZoneCache.zones.copyZone())
            }
        } else if msg["msg_name"].stringValue == MSGString.ZoneEdit {
            BWSDKLog.shared.debug("收到防区编辑报告")
            let zone = msg["zone"]
            if let ID = zone["id"].int {
                if let cacheZone = BWZone.ZoneCache.zones.first(where: { $0.ID == ID }) {
                    if let delay = zone["delay"].int {
                        cacheZone.delay = delay
                    }
                    if let sensorString = zone["sensor_list"].rawString(), let sensors = [BWSensor](JSONString: sensorString) {
                        sensors.forEach {
                            if let device = BWDevice.query(deviceID: $0.ID ?? -1) {
                                $0.transferToSelf(device: device)
                            }
                        }
                        cacheZone.sensors = sensors
                    }
                }
                BWZone.needRefresh?(BWZone.ZoneCache.zones.copyZone())
            }
        } else {
            BWSDKLog.shared.debug("该消息无需处理")
        }
    }
    
    /// 联动消息
    static func linkageMSG(msg: JSON) {
        if msg["msg_name"].stringValue == MSGString.LinkageAdd {
            BWSDKLog.shared.debug("收到联动增加报告")
            if let raw = msg["linkage"].rawString() {
                if let linkage = BWLinkage(JSONString: raw) {
                    let sort = BWLinkageSort()
                    sort.belongId = linkage.ID
                    sort.sortId = sortRebootId
                    sort.save()
                    linkage.save()
                    linkage.linkageOrigin?.save(dbName: BWAppManager.shared.loginGWDBName())
                    linkage.linkInstruct?.save(dbName: BWAppManager.shared.loginGWDBName())
                    BWLinkage.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.LinkageDel {
            BWSDKLog.shared.debug("收到联动删除报告")
            if let list = msg["linkage_list"].array {
                list.forEach {
                    if let ID = $0["id"].int {
                        BWLinkage.delete(ID: ID)
                        BWLinkageSort.delete(belongId: ID)
                    }
                }
                BWLinkage.needRefresh?()
            }
        } else if msg["msg_name"].stringValue == MSGString.LinkageEdit {
            BWSDKLog.shared.debug("收到联动编辑报告")
            if let raw = msg["linkage"].rawString() {
                if let linkage = BWLinkage(JSONString: raw) {
                    let dbLinkage = BWLinkage.query(ID: linkage.ID ?? -1)
                    dbLinkage?.name = linkage.name ?? dbLinkage?.name
                    dbLinkage?.state = linkage.state ?? dbLinkage?.state
                    dbLinkage?.delay = linkage.delay ?? dbLinkage?.delay
                    dbLinkage?.mode = linkage.mode ?? dbLinkage?.mode
                    dbLinkage?.timer = linkage.timer ?? dbLinkage?.timer
                    if let origins = linkage.linkageOrigin {
                        BWSDKLog.shared.debug("联动条件替换")
                        BWLinkageOrigin.delete(belongID: linkage.ID ?? -1)
                        origins.save(dbName: BWAppManager.shared.loginGWDBName())
                    }
                    if let links = linkage.linkInstruct {
                        BWSDKLog.shared.debug("联动结果替换")
                        BWLinkageInstruct.delete(belongID: linkage.ID ?? -1)
                        links.save(dbName: BWAppManager.shared.loginGWDBName())
                    }
                    dbLinkage?.update()
                    BWLinkage.needRefresh?()
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.LinkageQuery {
            BWSDKLog.shared.debug("收到联动查询response")
            if let list = msg["linkage_list"].rawString() {
                let linkages = [BWLinkage](JSONString: list) ?? [BWLinkage]()
                linkages.save(dbName: BWAppManager.shared.loginGWDBName())
                linkages.forEach {
                    $0.linkInstruct?.save(dbName: BWAppManager.shared.loginGWDBName())
                    $0.linkageOrigin?.save(dbName: BWAppManager.shared.loginGWDBName())
                }
            }
            BWLinkage.needRefresh?()
        } else {
            BWSDKLog.shared.debug("该消息无需处理")
        }
    }
    
    /// 记录消息
    static func recordMSG(msg: JSON) {
        BWSDKLog.shared.debug("收到消息记录相关消息")
    }
    
    /// 控制消息
    static func controlMSG(msg: JSON) {
        if msg["msg_name"].stringValue == MSGString.DeviceStateReport {
            BWSDKLog.shared.debug("收到设备状态报告")
            let device = msg["device"]
            if let ID = device["device_id"].int {
                if let handle = BWDevice.openDoorHandle,
                    device["device_status"]["state"].string == "on" {
                    handle(ID, 0)
                    BWSDKLog.shared.debug("门锁开门需要处理该device_state_report消息")
                }
                BWDevice.deviceStatus[ID] = device["device_status"]
                BWDevice.stateRefresh?([ID])
                BWDevice.voiceControlStateRefresh?(ID)
                if let handle = BWDevice.xwSongListHandle, let songs = device["device_status"]["songlist"]["songs"].array {
                    var list = [BWDevice.XWSong]()
                    songs.forEach {
                        let name = $0["title"].string ?? ""
                        let sing = $0["artist"].string ?? ""
                        let id = $0["id"].int ?? 0
                        let duration = $0["duration"].int ?? 0
                        list.append(BWDevice.XWSong(name: name, sing: sing, id: id, duration: duration))
                    }
                    handle(ID, list)
                }
            }
        } else if msg["msg_name"].stringValue == MSGString.DeviceControl {
            if let cmd = msg["device"]["device_status"]["cmd"].string,
                let ID = msg["device"]["device_id"].int {
                BWSDKLog.shared.debug("收到透传命令response回复")
                BWDevice.dtResponse?(ID, cmd)
            } else {
                if let handle = BWDevice.openDoorHandle,
                    let ID = msg["device"]["device_id"].int,
                    let status = msg["status"].int {
                    handle(ID, status)
                    BWSDKLog.shared.debug("门锁开门需要处理该report消息")
                } else {
                    BWSDKLog.shared.debug("收到别的response/report回复，不处理")
                }
            }
        } else {
            BWSDKLog.shared.debug("该消息无需处理")
        }
    }
    
    /// 网关消息
    static func gatewayMSG(msg: JSON) {
        if msg["msg_name"].stringValue == MSGString.GWAliasSet {
            BWSDKLog.shared.debug("收到网关别名设置")
            if let alias = msg["gateway"]["alias"].string {
                BWAppManager.shared.loginGateway?.alias = alias
                BWAppManager.shared.loginGateway?.update(alias: alias)
                BWGateway.aliasHandle?()
                BWGateway.aliasHandle = nil
            }
        } else {
            BWSDKLog.shared.debug("该消息无需处理")
        }
    }
    
    /// 版本消息
    static func gatewayVersion(msg: JSON) {
        if msg["msg_name"].stringValue == MSGString.RequestGWUpdate {
            if let code = msg["update_state"].int {
                BWGateway.updateHandle?(code)
            }
        } else if msg["msg_name"].stringValue == MSGString.RequestHubUpdate {
            if let code = msg["update_state"].int {
                BWGateway.hubUpdateHandle?(code)
            }
        } else {
            BWSDKLog.shared.debug("该消息无需处理")
        }
    }
    
    /// 其它消息
    static func otherMSG(msg: JSON) {
        /// 强制离线
        if msg["msg_name"].stringValue == MSGString.ForceLogout {
            BWSDKLog.shared.debug("收到强制离线报告")
            if let code = msg["reason"].int, code == 101 || code == 105 || code == 106, let remove = BWGateway.removeFromGateway {
                if code == 101 || code == 106 {
                    BWGateway.delete(phone: BWAppManager.shared.username ?? "", sn: BWAppManager.shared.loginGateway?.sn ?? "")
                }
                BWSDKLog.shared.info("离线原因:\(code)")
                remove(code)
                return
            }
            BWAppManager.shared.disconnectServer()
            BWAppManager.shared.forceLogout?()
        }
        /// 消息推送
        else if msg["msg_name"].stringValue == MSGString.MsgReport {
            BWSDKLog.shared.debug("收到消息报告")
            if let type = msg["message"]["type"].string {
                if type == BWMSG.MSGType.alarm.rawValue {
                    BWMSG.unreadAlarm += 1
                } else if type == BWMSG.MSGType.door.rawValue {
                    BWMSG.unreadDoor += 1
                } else if type == BWMSG.MSGType.event.rawValue {
                    BWMSG.unreadEvent += 1
                }
                BWMSG.UnreadNeedRefresh?()
                if let str = msg["message"]["record"].rawString() {
                    if let msg = BWMSG.init(JSONString: str) {
                        msg.msgType = BWMSG.MSGType(rawValue: type)
                        BWMSG.ReceiveMSG?(msg)
                    }
                }
            }
        }
        else {
            BWSDKLog.shared.debug("收到其它的消息")
        }
    }
}

