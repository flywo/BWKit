//
//  BWAppManager.swift
//  BWKit
//
//  Created by yuhua on 2020/3/3.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import SwiftyJSON

/// SDK版本
public let BWSDKVersion = "1.0.0"

/// APP的当前状态
public enum BWAppState {
    /// 未登录
    case NoLogin
    /// 已登录服务器
    case LoginServer
    /// 已登录网关--使用服务器
    case LoginGatewayUseServer
    /// 已登录网关-- 使用本地连接
    case LoginGatewayUseLocal
}

/// AppManager
public class BWAppManager {
    
    /// 单例
    public static let shared = BWAppManager()
    
    /// 用户
    public internal(set) var username: String?
    
    /// APP状态
    public internal(set) var appState = BWAppState.NoLogin
    
    /// 服务器管理
    var serverSocket: BWNetwork?
    
    /// 局域网管理
    var localSocket: BWNetwork?
    
    /// udp
    var udpSocket: BWUDP?
    
    /// 心跳管理
    var heart: BWHeart?
    
    /// 当前登录网关
    public internal(set) var loginGateway: BWGateway?
    
    /// 被强制离线，本账号在异地登录时，会被强制离线，此时，会调用本闭包，界面需处理返回登录页等操作。SDK内部会自动调用disconnectServer方法断开连接，无需手动调用。但初始化方法initManager任需自行调用一次。
    public var forceLogout: (()->Void)?
    
    /// 断开连接后，会调用本闭包，界面需自行判断处理。
    public var disconnect: (()->Void)?
    
    /// 操作计时器
    var timer: Timer?
    
    /// 搜索计时器
    var udpTime: Timer?
    
    /// 公共数据库
    let commonDB = "common.db"
    
    /// IP地址，请在连接前设置
    public var host = "www.baiweismartlife.com"
    
    /// 端口号，请在连接前设置
    public var port = 17030
    
    /// 获取当前token
    public func currentToken() -> String {
        return MSGFix.token
    }
    
    /// 初次使用SDK或者调用disconnectServer方法后，都必须要调用该方法初始化一次
    public func initManager(appId: String) {
        BWSDKLog.shared.info("初始化SDK")
        // 构建msgid随机字符
        MSGFix.creatRandom()
        MSGFix.appId = appId
        // 连接公共数据库
        BWDBManager.shared.connectDB(dbName: commonDB)
        // 判断数据库是否需更新
        BWDBManager.shared.judgeDB(checkDB: commonDB)
        // 创建网关表
        BWGateway.creatTable(dbName: commonDB)
    }
    
    /// 已登录网关的数据库名称，没有则返回""
    func loginGWDBName() -> String {
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("当前未登录网关，无法获取数据库名称！")
            return ""
        }
        return BWAppManager.shared.loginGateway!.dbName()
    }
    
    /// 检查服务器连接，调用本方法前提是调用过连接服务器方法。
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 连接成功会执行
    ///   - fail: 失败执行
    public func checkServerConnect(timeOut: TimeInterval = 8,
                                   timeOutHandle: @escaping ()->Void = {},
                                   connected: ()->Void = {},
                                   success: @escaping ()->Void = {},
                                   fail: ()->Void = {}) {
        BWSDKLog.shared.debug("检查服务器连接")
        if serverSocket?.tcpClient?.isConnected == true {
            connected()
        } else {
            connectServer(timeOut: timeOut, timeOutHandle: timeOutHandle, success: success, fail: fail)
        }
    }
    
    
    /// 连接本地网关
    /// - Parameters:
    ///   - host: IP地址
    ///   - port: 端口号
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func connectLocal(host: String, port: Int, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: ()->Void = {}) {
        BWSDKLog.shared.debug("连接本地网关")
        localSocket?.disconnectServer()
        localSocket = BWNetwork()
        localSocket?.isLocal = true
        localSocket?.needEndMSGName = [MSGString.DeviceQuery,
                                       MSGString.SceneQuery,
                                       MSGString.TimerQuery,
                                       MSGString.LinkageQuery,
                                       MSGString.RoomQuery,
                                       MSGString.ZoneQuery,
                                       MSGString.DeviceStateGet,
                                       MSGString.DeviceCMDQuery,
                                       MSGString.MsgQuery,
                                       MSGString.DLIdQuery,
                                       MSGString.RequestGWUpdate,
                                       MSGString.RequestHubUpdate]
        localSocket!.host = host
        localSocket!.port = UInt16(port)
        buildDelayTime(time: timeOut) {
            self.localSocket?.connectHandle = nil
            timeOutHandle()
        }
        localSocket?.msgReceiveHandle = { json in
            ObjectMSG.paraseMSG(msg: json)
        }
        localSocket?.checkMSG = { json in
            // 第三方登录排除
            if (json["msg_name"].string == MSGString.ThirdAuthBind || json["msg_name"].string == MSGString.ThirdAuthLogin), json["msg_class"].string == MSGString.ThirdAuth {
                return true
            }
            // 获取验证码、注册、找回密码接口需要排除掉
            if (json["msg_name"].string == MSGString.SendSMSCode || json["msg_name"].string == MSGString.UserRegWithCode || json["msg_name"].string == MSGString.ResetPWD), json["msg_class"].string == MSGString.AppAuth {
                return true
            }
            // 判断是否是发给自己的消息
            if let to = json["to"].string, to != BWAppManager.shared.username {
                BWSDKLog.shared.warning("已登录用户:\(BWAppManager.shared.username ?? "")，消息发给:\(to)，不是已登录用户的消息，被丢弃!")
                return false
            }
            // 判断消息from是否为空，为空则表示服务器消息
            if let from = json["from"].string, !from.isEmpty, from != BWAppManager.shared.loginGateway?.sn {
                // 登录网关消息比较特殊，需排除掉
                if json["msg_name"].string == MSGString.UserLogin, json["msg_class"].string == MSGString.UserMgmt {
                    return true
                }
                // 根据是否登录网关显示不同打印
                if BWAppManager.shared.loginGateway == nil {
                    BWSDKLog.shared.warning("还未登录网关，消息来自:\(from)，不处理该消息，被丢弃!")
                } else {
                    BWSDKLog.shared.warning("已登录网关:\(BWAppManager.shared.loginGateway?.sn ?? "")，消息来自:\(from)，不是已登录网关的消息，被丢弃!")
                }
                return false
            }
            return true
        }
        localSocket?.disconnectHandle = { [weak self] in
            self?.disconnectServer()
            self?.initManager(appId: MSGFix.appId)
            self?.disconnect?()
        }
        localSocket!.creatSocketConnectServer(success: { [weak self] in
            self?.killDelayTime()
            success()
        }, fail: { [weak self] in
            self?.killDelayTime()
            fail()
        })
    }
    
    /// 连接服务器
    /// - Parameters:
    ///   - host: 域名/IP
    ///   - port: 端口
    ///   - timeOut: 超时时间，默认8秒
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func connectServer(host: String? = nil, port: Int? = nil, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: ()->Void = {}) {
        BWSDKLog.shared.debug("连接服务器")
        serverSocket?.disconnectServer()
        serverSocket = BWNetwork()
        serverSocket?.needEndMSGName = [MSGString.DeviceQuery,
                                        MSGString.SceneQuery,
                                        MSGString.TimerQuery,
                                        MSGString.LinkageQuery,
                                        MSGString.RoomQuery,
                                        MSGString.ZoneQuery,
                                        MSGString.DeviceStateGet,
                                        MSGString.DeviceCMDQuery,
                                        MSGString.MsgQuery,
                                        MSGString.DLIdQuery]
        serverSocket!.host = host ?? self.host
        serverSocket!.port = UInt16(port ?? self.port)
        buildDelayTime(time: timeOut) {
            self.serverSocket?.connectHandle = nil
            timeOutHandle()
        }
        serverSocket?.msgReceiveHandle = { json in
            ObjectMSG.paraseMSG(msg: json)
        }
        serverSocket?.checkMSG = { json in
            // 第三方登录排除
            if (json["msg_name"].string == MSGString.ThirdAuthBind || json["msg_name"].string == MSGString.ThirdAuthLogin), json["msg_class"].string == MSGString.ThirdAuth {
                return true
            }
            // 获取验证码、注册、找回密码接口需要排除掉
            if (json["msg_name"].string == MSGString.SendSMSCode || json["msg_name"].string == MSGString.UserRegWithCode || json["msg_name"].string == MSGString.ResetPWD), json["msg_class"].string == MSGString.AppAuth {
                return true
            }
            // 判断是否是发给自己的消息
            if let to = json["to"].string, to != BWAppManager.shared.username {
                BWSDKLog.shared.warning("已登录用户:\(BWAppManager.shared.username ?? "")，消息发给:\(to)，不是已登录用户的消息，被丢弃!")
                return false
            }
            // 判断消息from是否为空，为空则表示服务器消息
            if let from = json["from"].string, !from.isEmpty, from != BWAppManager.shared.loginGateway?.sn {
                // 登录网关消息比较特殊，需排除掉
                if json["msg_name"].string == MSGString.UserLogin, json["msg_class"].string == MSGString.UserMgmt {
                    return true
                }
                // 根据是否登录网关显示不同打印
                if BWAppManager.shared.loginGateway == nil {
                    BWSDKLog.shared.warning("还未登录网关，消息来自:\(from)，不处理该消息，被丢弃!")
                } else {
                    BWSDKLog.shared.warning("已登录网关:\(BWAppManager.shared.loginGateway?.sn ?? "")，消息来自:\(from)，不是已登录网关的消息，被丢弃!")
                }
                return false
            }
            return true
        }
        serverSocket?.disconnectHandle = { [weak self] in
            if self?.appState != .LoginGatewayUseLocal {
                self?.disconnectServer()
                self?.initManager(appId: MSGFix.appId)
                self?.disconnect?()
            }
        }
        serverSocket!.creatSocketConnectServer(success: { [weak self] in
            self?.killDelayTime()
            success()
        }, fail: { [weak self] in
            self?.killDelayTime()
            fail()
        })
    }
    
    /// 断开服务，调用该方法后，必须再次调用初始化方法一次，SDK才能继续正常使用
    public func disconnectServer() {
        BWSDKLog.shared.info("断开网络连接")
        // Network
        serverSocket?.disconnectServer()
        localSocket?.disconnectServer()
        // DB
        BWDBManager.shared.disconnectAllDB()
        // MSG
        MSGFix.from = ""
        MSGFix.to = ""
        MSGFix.token = ""
        // gw messge
        BWMSG.unreadAlarm = 0
        BWMSG.unreadDoor = 0
        BWMSG.unreadEvent = 0
        // Device
        BWDevice.deviceStatus.removeAll()
        BWDevice.quickDevices = nil
        BWDevice.wifiPermission = nil
        // Zone
        BWZone.ZoneCache.zones.removeAll()
        // AppManager
        appState = .NoLogin
        username = nil
        loginGateway = nil
        serverSocket = nil
        localSocket = nil
        timer?.invalidate()
        timer = nil
        heart?.stopHeart()
        heart = nil
    }
            
    /// 发送消息
    /// - Parameters:
    ///   - msg: 自己组装的消息内容
    ///   - backHandle: 回调
    public func send(msg: String, backHandle: ((String)->Void)?) {
        sendMSG(msg: msg) {
            backHandle?($0.rawString() ?? "")
        }
    }
    
    /// 发送消息，内部使用
    func sendMSG(msg: String, backHandle: ((JSON)->Void)? = nil) {
        if appState == .LoginGatewayUseLocal {
            localSocket?.sendMSG(msg: msg, backHandle: backHandle)
            return
        }
        serverSocket?.sendMSG(msg: msg, backHandle: backHandle)
    }
    
    
    /// 清除指定消息的回调，如果使用send方法发送消息，请务必调用本方法清除回调。调用时机自行判断。
    /// - Parameter msg: 消息内容
    public func msgTimeOut(msg: String) {
        let json = JSON.init(parseJSON: String(msg.suffix(from: msg.index(msg.startIndex, offsetBy: 8))))
        if let key = json["msg_id"].string {
            if appState == .LoginGatewayUseLocal {
                localSocket?.removeHandle(msgID: key)
                return
            }
            serverSocket?.removeHandle(msgID: key)
        }
    }
    
    /// 移除所有消息的回调
    public func removeAllHandle() {
        serverSocket?.removeAllHandle()
        localSocket?.removeAllHandle()
    }
    
    /// 局域网搜索
    func startSearchGateway(searchTime: TimeInterval = 10, searchSpace: TimeInterval = 2, searchResult: @escaping (BWGateway)->Void) {
        guard let msg = ObjectMSG.searchGateway() else {
            return
        }
        stopSearch()
        buildUDPDelayTime(time: searchTime) { [weak self] in
            self?.stopSearch()
        }
        udpSocket = BWUDP(space: searchSpace)
        udpSocket?.startSerach(searchResult: { str in
            let json = JSON(parseJSON: str)
            BWSDKLog.shared.debug("搜索到网关:\(json["gateway"]["sn"].string ?? "") \(json["gateway"]["alias"].string ?? "") \(json["gateway"]["ip"].string ?? "") \(json["gateway"]["port"].int ?? -1)")
            if let raw = json["gateway"].rawString(), let gateway = BWGateway(JSONString: raw) {
                DispatchQueue.main.async {
                    searchResult(gateway)
                }
            }
        }, msg: msg)
    }
    
    /// 停止搜索
    func stopSearch() {
        killUDPDelayTime()
        udpSocket?.stopSearch()
        udpSocket = nil
    }
}


extension BWAppManager {
    
    /// 检查是否已经连接服务器
    func checkConnect() -> Bool {
        if let server = serverSocket, let connect = server.tcpClient?.isConnected, connect {
            return true
        }
        BWSDKLog.shared.error("没有连接服务器，请先连接！")
        return false
    }
    
    
    /// 获取验证码
    /// - Parameters:
    ///   - phone: 手机号
    ///   - type: 验证码类型：1注册  2登录  4忘记密码
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func getCode(phone: String, type: Int, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("获取验证码:\(type)")
        if checkConnect() {
            MSGFix.from = phone
            guard let msg = ObjectMSG.getCode(type: type) else {
                fail(-1)
                return
            }
            /// 发送消息时创建
            buildDelayTime(time: timeOut) {
                /// 超时后清除回调
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
            sendMSG(msg: msg) { json in
                /// 无需end字段的消息直接关闭定时
                self.killDelayTime()
                if json["status"].intValue == 0 {
                    success()
                } else {
                    fail(json["status"].intValue)
                }
            }
        } else {
            fail(-1)
        }
    }
    
    
    /// 注册手机号
    /// - Parameters:
    ///   - phone: 手机号
    ///   - smsCode: 验证码
    ///   - userPwd: 用户密码
    ///   - channelId: 频道ID，参照协议
    ///   - appId: APPID，参照协议
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func register(phone: String, smsCode: String, userPwd: String, channelId: String = "030", appId: String = "010", timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("注册用户")
        if checkConnect() {
            MSGFix.from = phone
            var user = [String: Any]()
            user["channelID"] = channelId
            user["appId"] = appId
            user["sms_code"] = smsCode
            user["user_pwd"] = userPwd
            guard let msg = ObjectMSG.register(user: user) else {
                fail(-1)
                return
            }
            /// 发送消息时创建
            buildDelayTime(time: timeOut) {
                /// 超时后清除回调
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
            sendMSG(msg: msg) { json in
                /// 无需end字段的消息直接关闭定时
                self.killDelayTime()
                if json["status"].intValue == 0 {
                    success()
                } else {
                    fail(json["status"].intValue)
                }
            }
        } else {
            fail(-1)
        }
    }
    
    /// 重置密码
    /// - Parameters:
    ///   - phone: 手机号
    ///   - smsCode: 验证码
    ///   - userPwd: 用户密码
    ///   - channelId: 频道ID，参照协议
    ///   - appId: APPID，参照协议
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public func resetPassword(phone: String, smsCode: String, userPwd: String, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("重置密码")
        if checkConnect() {
            MSGFix.from = phone
            var user = [String: Any]()
            user["code"] = smsCode
            user["new_pwd"] = userPwd
            guard let msg = ObjectMSG.resetPassword(user: user) else {
                fail(-1)
                return
            }
            /// 发送消息时创建
            buildDelayTime(time: timeOut) {
                /// 超时后清除回调
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
            sendMSG(msg: msg) { json in
                /// 无需end字段的消息直接关闭定时
                self.killDelayTime()
                if json["status"].intValue == 0 {
                    success()
                } else {
                    fail(json["status"].intValue)
                }
            }
        } else {
            fail(-1)
        }
    }
    
    
    /// 第三方登录，微信，支付宝，QQ，APPLE
    /// - Parameters:
    ///   - type: 登录类型，1微信 2QQ 3支付宝  4APPLE
    ///   - code: code
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，已绑定，则返回参数1，2，1表示手机号，2表示token，若未绑定，则返回参数3，返回ticket，后续绑定使用。
    ///   - fail: 失败
    public func thirdLogin(type: Int, code: String, channelId: String = "030", appId: String = "010", timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping (String?, String?, String?)->Void = { (_, _, _) in }, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("第三方登录")
        if checkConnect() {
            MSGFix.from = ""
            var info = [String: Any]()
            if type == 1 {
                info["type"] = 1
                info["wechat_info"] = ["code": code]
            } else if type == 2 {
                info["type"] = 2
                info["qq_info"] = ["code": code]
            } else if type == 3 {
                info["type"] = 3
                info["alipay_info"] = ["code": code]
            } else if type == 4 {
                info["type"] = 4
                info["apple_info"] = ["code": code]
            }
            var user = [String: Any]()
            user["channelID"] = channelId
            user["appId"] = appId
            guard let msg = ObjectMSG.thirdLogin(info: info, user: user) else {
                fail(-1)
                return
            }
            /// 发送消息时创建
            buildDelayTime(time: timeOut) {
                /// 超时后清除回调
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
            sendMSG(msg: msg) { json in
                /// 无需end字段的消息直接关闭定时
                self.killDelayTime()
                if json["status"].intValue == 0 {
                    if let phone = json["result"]["phone"].string, !phone.isEmpty {
                        MSGFix.from = phone
                        if let token = json["result"]["token"].string, !token.isEmpty {
                            MSGFix.token = token
                            self.username = phone
                            self.appState = .LoginServer
                            BWAppManager.shared.heart = BWHeart()
                        }
                        success(phone, json["result"]["token"].string, nil)
                    } else {
                        success(nil, nil, json["result"]["ticket"].string)
                    }
                } else {
                    fail(json["status"].intValue)
                }
            }
        } else {
            fail(-1)
        }
    }
    
    
    /// 第三方绑定
    /// - Parameters:
    ///   - type: 类型，1微信 2QQ 3支付宝
    ///   - ticket: 标识
    ///   - phone: 手机号
    ///   - pwd: 密码
    ///   - channelId: 频道ID
    ///   - appId: APPID
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，参数1手机号，参数2token
    ///   - fail: 失败
    public func thirdBind(type: Int, ticket: String, phone: String, pwd: String, channelId: String = "030", appId: String = "010", timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping (String?, String?)->Void = { (_, _) in }, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("第三方绑定")
        if checkConnect() {
            MSGFix.from = ""
            var info = [String: Any]()
            info["type"] = type
            info["ticket"] = ticket
            var user = [String: Any]()
            user["phone"] = phone
            user["user_pwd"] = pwd
            user["channelID"] = channelId
            user["appId"] = appId
            guard let msg = ObjectMSG.thirdBind(info: info, user: user) else {
                fail(-1)
                return
            }
            /// 发送消息时创建
            buildDelayTime(time: timeOut) {
                /// 超时后清除回调
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
            sendMSG(msg: msg) { json in
                /// 无需end字段的消息直接关闭定时
                self.killDelayTime()
                if json["status"].intValue == 0 {
                    if let phone = json["result"]["phone"].string {
                        MSGFix.from = phone
                        if let token = json["result"]["token"].string, !token.isEmpty {
                            MSGFix.token = token
                            self.username = phone
                            self.appState = .LoginServer
                            BWAppManager.shared.heart = BWHeart()
                        }
                        success(phone, json["result"]["token"].string)
                    } else {
                        success(nil, nil)
                    }
                } else {
                    fail(json["status"].intValue)
                }
            }
        } else {
            fail(-1)
        }
    }
    
    
    /// 验证码登录
    /// - Parameters:
    ///   - username: 用户
    ///   - code: 验证码
    ///   - timeOut: 超时
    ///   - timeOutHandle: 回调
    ///   - success: 回调
    ///   - fail: 回调
    public func codeLogin(username: String, code: String, channelID: String = "030", timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping (String)->Void = { _ in }, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("验证码登录服务器")
        if checkConnect() {
            MSGFix.from = username
            self.username = username
            guard let msg = ObjectMSG.codeLogin(code: code, channelID: channelID) else {
                fail(-1)
                return
            }
            /// 发送消息时创建
            buildDelayTime(time: timeOut) {
                /// 超时后清除回调
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
            sendMSG(msg: msg) { json in
                /// 无需end字段的消息直接关闭定时
                self.killDelayTime()
                if json["status"].intValue == 0 {
                    MSGFix.token = json["result"]["token"].string ?? MSGFix.token
                    self.appState = .LoginServer
                    BWAppManager.shared.heart = BWHeart()
                    success(MSGFix.token)
                } else {
                    fail(json["status"].intValue)
                }
            }
        } else {
            fail(-1)
        }
    }
    
    /// 密码登录服务器
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    ///   - timeOut: 超时时间，默认8秒
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - success: 成功回调，同时返回服务器token，需自行保存，下次登录可使用token登录服务器
    ///   - fail: 失败回调
    public func loginServer(username: String, password: String, appId: String = "010", timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping (String)->Void = { _ in }, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("密码登录服务器")
        if checkConnect() {
            MSGFix.from = username
            self.username = username
            guard let msg = ObjectMSG.serverUserLogin(pwd: password, appId: appId) else {
                fail(-1)
                return
            }
            /// 发送消息时创建
            buildDelayTime(time: timeOut) {
                /// 超时后清除回调
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
            sendMSG(msg: msg) { json in
                /// 无需end字段的消息直接关闭定时
                self.killDelayTime()
                if json["status"].intValue == 0 {
                    MSGFix.token = json["result"]["token"].string ?? MSGFix.token
                    self.appState = .LoginServer
                    BWAppManager.shared.heart = BWHeart()
                    success(MSGFix.token)
                } else {
                    fail(json["status"].intValue)
                }
            }
        } else {
            fail(-1)
        }
    }
    
    /// token登录服务器
    /// - Parameters:
    ///   - username: 用户名
    ///   - token: 上次登录获得的token
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func loginServer(username: String, token: String, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("token登录服务器")
        if checkConnect() {
            MSGFix.from = username
            MSGFix.token = token
            self.username = username
            guard let msg = ObjectMSG.serverTokenLogin() else {
                fail(-1)
                return
            }
            /// 发送消息时创建
            buildDelayTime(time: timeOut) {
                /// 超时后清除回调
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
            sendMSG(msg: msg) { json in
                /// 无需end字段的消息直接关闭定时
                self.killDelayTime()
                if json["status"].intValue == 0 {
                    self.appState = .LoginServer
                    BWAppManager.shared.heart = BWHeart()
                    success()
                } else {
                    fail(json["status"].intValue)
                }
            }
        } else {
            fail(-1)
        }
    }
    
    /// 比集登录服务器
    /// - Parameters:
    ///   - username: 用户名
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public func BJLoginServer(username: String, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping (String)->Void = { _ in }, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("比集登录服务器")
        if checkConnect() {
            MSGFix.from = username
            self.username = username
            guard let msg = ObjectMSG.BJTokenLogin() else {
                fail(-1)
                return
            }
            /// 发送消息时创建
            buildDelayTime(time: timeOut) {
                /// 超时后清除回调
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
            sendMSG(msg: msg) { json in
                /// 无需end字段的消息直接关闭定时
                self.killDelayTime()
                if json["status"].intValue == 0 {
                    MSGFix.token = json["result"]["token"].string ?? MSGFix.token
                    self.appState = .LoginServer
                    BWAppManager.shared.heart = BWHeart()
                    success(MSGFix.token)
                } else {
                    fail(json["status"].intValue)
                }
            }
        } else {
            fail(-1)
        }
    }
    
    
    /// 上传推送ID
    /// - Parameters:
    ///   - pushId: 推送ID
    ///   - success: 成功
    ///   - fail: 失败
    public func uploadPushID(pushId: String,
                             success: @escaping ()->Void = {},
                             fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("上传推送ID")
        if checkConnect() {
            guard let msg = ObjectMSG.uploadPushID(id: pushId) else {
                fail(-1)
                return
            }
            sendMSG(msg: msg) { json in
                if json["status"].intValue == 0 {
                    success()
                } else {
                    fail(json["status"].intValue)
                }
            }
        } else {
            fail(-1)
        }
    }
    
    /// 构建延时操作
    func buildDelayTime(time: TimeInterval, delayBlock: @escaping ()->Void) {
        BWSDKLog.shared.debug("开启超时，超时时间:\(time)")
        if timer != nil {
            BWSDKLog.shared.warning("重复开启超时，先关闭以前的超时!")
            killDelayTime()
        }
        timer = Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(delay), userInfo: delayBlock, repeats: false)
    }
    
    /// 延时执行
    @objc func delay() {
        BWSDKLog.shared.debug("执行超时")
        if let block = timer?.userInfo, let closure = block as? ()->Void {
            closure()
        }
        timer?.invalidate()
        timer = nil
    }
    
    /// 清除延时
    func killDelayTime() {
        BWSDKLog.shared.debug("清除超时")
        timer?.invalidate()
        timer = nil
    }
    
    /// 构建延时操作
    func buildUDPDelayTime(time: TimeInterval, delayBlock: @escaping ()->Void) {
        BWSDKLog.shared.debug("开启udp超时，超时时间:\(time)")
        if udpTime != nil {
            BWSDKLog.shared.warning("重复开启udp超时，先关闭以前的超时!")
            killUDPDelayTime()
        }
        udpTime = Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(delayUDP), userInfo: delayBlock, repeats: false)
    }
    
    /// 延时执行
    @objc func delayUDP() {
        BWSDKLog.shared.debug("执行udp超时")
        if let block = udpTime?.userInfo, let closure = block as? ()->Void {
            closure()
        }
        udpTime?.invalidate()
        udpTime = nil
    }
    
    /// 清除延时
    func killUDPDelayTime() {
        BWSDKLog.shared.debug("清除udp超时")
        udpTime?.invalidate()
        udpTime = nil
    }
}
