//
//  BWGateway.swift
//  BWKit
//
//  Created by yuhua on 2020/3/4.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import ObjectMapper


/// 网关
public class BWGateway: Mappable, Equatable {
    
    /// 网关数据有变动，需要刷新，UI界面需重新获取数据
    public static var needRefresh: (()->Void)?
    
    /// 被网关强制离线，离线原因：101 用户已被删除 105 用户过期 106 家庭被解散
    public static var removeFromGateway: ((Int)->Void)?
    
    /// 网关升级回调
    static var updateHandle: ((Int)->Void)?
    
    /// 协调器升级回调
    static var hubUpdateHandle: ((Int)->Void)?
    
    /// 修改网关名称回调
    static var aliasHandle: (()->Void)?
    
    /// phone
    public var phone: String?
    
    /// sn
    public var sn: String?
    
    /// 别名
    public var alias: String?
    
    /// 权限 1子用户 0主用户
    public var privilege: Int?
    
    /// 状态 1在线 0离线
    public var online: Int = 0
    
    /// ip -- 局域网搜索到的网关有该属性
    public var ip: String?
    
    /// port -- 局域网搜索到的网关有该属性
    public var port: Int?
    
    /// 是否是小网关，为nil表示未知
    public var isLowGW: Bool?
    
    /// 网关版本，只有登录网关过后有数值
    public var version: String?
    
    /// 协调器版本，只有登录网关过后有数值
    public var coorVersion: String?
    
    /// 协调器通道号，只有登录网关过后有数值
    public var coorChannel: String?
    
    /// 协调器MAC地址，只有登录网关过后有数值
    public var coorMAC: String?
    
    /// 协调器型号
    public var coorModel: String?
    
    /// 初始化
    init(phone: String, sn: String, alias: String, privilege: Int) {
        self.phone = phone
        self.sn = sn
        self.alias = alias
        self.privilege = privilege
    }
    
    /// 忽略该方法
    public required init?(map: Map) {
    }
    
    /// 忽略该方法
    public func mapping(map: Map) {
        sn <- map["sn"]
        alias <- map["alias"]
        privilege <- map["privilege"]
        online <- map["online"]
        ip <- map["ip"]
        port <- map["port"]
    }
    
    /// 描述
    public var description: String {
        return "[phone:\(phone ?? "") sn:\(sn ?? "") alias:\(alias ?? "") privilege:\(privilege ?? -1) online:\(online) ip:\(ip ?? "") port:\(port ?? -1)]"
    }
    
    /// 网关数据库名
    func dbName() -> String {
        return BWAppManager.shared.username! + sn! + ".db"
    }
    
    /// 比较
    public static func == (lhs: BWGateway, rhs: BWGateway) -> Bool {
        return lhs.sn == rhs.sn
    }
}

/// 执行操作
extension BWGateway {
    
    
    /// 开始搜索网关，请勿多次重复调用该方法，重新调用该方法前，务必先停止搜索。
    /// - Parameters:
    ///   - searchTime: 搜索时间
    ///   - searchTime: 搜索间隔
    ///   - searchResult: 结果，会一个一个通过该闭包返回，需自行处理
    public static func StartSerach(searchTime: TimeInterval = 10, searchSpace: TimeInterval = 2, searchResult: @escaping (BWGateway)->Void) {
        BWSDKLog.shared.debug("开启搜索网关")
        BWAppManager.shared.startSearchGateway(searchTime: searchTime, searchSpace: searchSpace, searchResult: searchResult)
    }
    
    
    /// 停止搜索网关
    public static func StopSearch() {
        BWSDKLog.shared.debug("停止搜索网关")
        BWAppManager.shared.stopSearch()
    }
    
    /// 从服务器获取网关列表，本指令只有登录服务器成功后才能获取
    /// - Parameters:
    ///   - timeOutOn: 超时是否开启，默认开启
    ///   - timeOut: 超时时间，请设置成和UI界面一样的时间
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - success: 成功回调，回调会把网关列表传回来
    ///   - fail: 失败回调
    public static func GetGatewayList(timeOutOn: Bool = true, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ([BWGateway])->Void = { _ in }, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询网关列表")
        if BWAppManager.shared.appState == .NoLogin {
            BWSDKLog.shared.error("没有登录服务器，登录服务器后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.serverGwappQueryToken() else {
            fail(-1)
            return
        }
        if timeOutOn {
            BWAppManager.shared.buildDelayTime(time: timeOut) {
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if timeOutOn {
                BWAppManager.shared.killDelayTime()
            }
            if json["status"].intValue == 0 {
                guard let list = json["gateway_list"].rawString() else {
                    success([])
                    return
                }
                let gateways = [BWGateway](JSONString: list) ?? [BWGateway]()
                let phone = json["to"].string ?? ""
                gateways.forEach {
                    $0.phone = phone
                }
                BWGateway.delete(phone: phone)
                gateways.save(dbName: BWAppManager.shared.commonDB)
                success(gateways)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 登录本地网关
    /// - Parameters:
    ///   - gateway: 网关
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func LoginLocal(gateway: BWGateway, user: String, pwd: String, appID: String = "010", timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("局域网登录网关:\(gateway.sn ?? "")")
        guard let sn = gateway.sn else {
            BWSDKLog.shared.error("该网关没有SN号！")
            fail(-1)
            return
        }
        MSGFix.from = user
        BWAppManager.shared.username = user
        guard let msg = ObjectMSG.gatewayLocalUserLogin(sn: sn, pwd: pwd, appID: appID) else {
            fail(-1)
            return
        }
        let status = BWAppManager.shared.appState
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.appState = status
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.appState = .LoginGatewayUseLocal
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                MSGFix.to = sn
                MSGFix.token = json["user"]["token"].string ?? MSGFix.token
                BWAppManager.shared.loginGateway = gateway
                BWGateway.createGatewayDB(dbName: gateway.dbName())
                if json["user"]["need_sync_time"].int == 1, let msg = ObjectMSG.timeSync() {
                    BWSDKLog.shared.info("同步手机当前时间给网关")
                    BWAppManager.shared.sendMSG(msg: msg)
                }
                BWAppManager.shared.heart = BWHeart()
                success()
            } else {
                BWAppManager.shared.appState = status
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 登录指定网关，本指令只有登录服务器成功后能调用
    /// - Parameters:
    ///   - gateway: 登录的网关
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func LoginGateway(gateway: BWGateway, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("登录网关:\(gateway.sn ?? "")")
        if BWAppManager.shared.appState == .NoLogin {
            BWSDKLog.shared.error("没有登录服务器，登录服务器后再执行该操作！")
            fail(-1)
            return
        }
        guard let sn = gateway.sn else {
            BWSDKLog.shared.error("该网关没有SN号！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayUserLogin(sn: sn) else {
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
                MSGFix.to = sn
                BWAppManager.shared.appState = .LoginGatewayUseServer
                BWAppManager.shared.loginGateway = gateway
                BWGateway.createGatewayDB(dbName: gateway.dbName())
                if json["user"]["need_sync_time"].int == 1, let msg = ObjectMSG.timeSync() {
                    BWSDKLog.shared.info("同步手机当前时间给网关")
                    BWAppManager.shared.sendMSG(msg: msg)
                }
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 切换网关，请在已经具体登录到某个网关后，再使用该方法切换网关。
    /// - Parameters:
    ///   - gateway: 网关
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - success: 成功
    ///   - fail: 失败
    public static func ChangeGateway(gateway: BWGateway, timeOut: TimeInterval = 8, timeOutHandle: @escaping ()->Void = {}, success: @escaping ()->Void = {}, fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("切换网关:\(gateway.sn ?? "")")
        guard let old = BWAppManager.shared.loginGateway else {
            BWSDKLog.shared.error("还没有登录网关，无法切换，请使用登录方法登录!")
            fail(-1)
            return
        }
        LoginGateway(gateway: gateway, timeOut: timeOut, timeOutHandle: {
            // 恢复原网关数据
            MSGFix.to = old.sn ?? ""
            timeOutHandle()
        }, success: {
            // 清除原网关数据
            BWDBManager.shared.disconnectDB(dbName: old.dbName())
            BWDevice.deviceStatus.removeAll()
            BWDevice.quickDevices = nil
            BWDevice.wifiPermission = nil
            BWZone.ZoneCache.zones.removeAll()
            // 调用回调，告诉UI数据需要刷新
            BWDevice.needRefresh?()
            BWScene.needRefresh?()
            BWTimer.needRefresh?()
            BWLinkage.needRefresh?()
            BWRoom.needRefresh?()
            BWZone.needRefresh?([])
            success()
        }) {
            // 恢复原网关数据
            MSGFix.to = old.sn ?? ""
            fail($0)
        }
    }
    
    /// 从当前已登录的网关中退出登录，注意，只是退出登录的网关，并没有和服务器断开，并且只有已经登录后调用此方法才会有效。
    public static func LogoutGateway() {
        BWSDKLog.shared.debug("退出网关:\(BWAppManager.shared.loginGateway?.sn ?? "")")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return
        }
        BWSDKLog.shared.info("从当前网关登出，网关:\(BWAppManager.shared.loginGateway!)")
        BWAppManager.shared.appState = .LoginServer
        BWDBManager.shared.disconnectDB(dbName: BWAppManager.shared.loginGWDBName())
        BWAppManager.shared.loginGateway = nil
        MSGFix.to = ""
        BWDevice.deviceStatus.removeAll()
        BWDevice.quickDevices = nil
        BWDevice.wifiPermission = nil
        BWZone.ZoneCache.zones.removeAll()
        // gw messge
        BWMSG.unreadAlarm = 0
        BWMSG.unreadDoor = 0
        BWMSG.unreadEvent = 0
    }
    
    /// 查询网关下设备相关信息，本指令只有登录网关成功后才能调用，更新完毕后，自行调用需要的模型去查询对应数据。
    /// - Parameters:
    ///   - forceUpdate: 强制更新，默认为false
    ///   - downloadProgress: 下载进度，依次：设备->场景->定时->联动->房间 0->1->2->3->4，下载开始时，会通过该闭包返回下载的下标。
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调，超时不会触发fail回调，请注意
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func QueryGatewayDevice(forceUpdate: Bool = false,
                                          downloadProgress: @escaping (Int)->Void = { _ in },
                                          timeOut: TimeInterval = 30,
                                          timeOutHandle: @escaping ()->Void = {},
                                          success: @escaping ()->Void = {},
                                          fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询网关设备----远端")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        
        
        /// 查询摄像机
        func QueryCam() {
            BWDevice.NoDelayQuery()
        }
        
        /// 查询网关是大网关还是小网关
        func QueryGatewayVersion() {
            BWGateway.HardVerQuery(delay: false, success: {
                if $0 == "gateway" {
                    BWAppManager.shared.loginGateway?.version = $1
                    if $1.lowercased().contains("lgw") {
                        BWSDKLog.shared.info("当前网关是小网关")
                        BWAppManager.shared.loginGateway?.isLowGW = true
                    } else {
                        BWSDKLog.shared.info("当前网关是大网关")
                        BWAppManager.shared.loginGateway?.isLowGW = false
                    }
                }
                if $0 == "coordinator" {
                    BWAppManager.shared.loginGateway?.coorVersion = $1
                }
                if $0 == "mac" {
                    BWAppManager.shared.loginGateway?.coorMAC = $1
                }
                if $0 == "channel" {
                    BWAppManager.shared.loginGateway?.coorChannel = $1
                }
                if $0 == "model" {
                    BWAppManager.shared.loginGateway?.coorModel = $1
                }
            })
        }
        
        /// 更新房间，内部使用
        func UpdateRoom(oldModule: [BWModuleVersion], newModule: [BWModuleVersion]) {
            let oldRoom = oldModule.first { $0.module == "room" }
            let newRoom = newModule.first { $0.module == "room" }
            if oldRoom == nil || oldRoom?.version != newRoom?.version {
                BWSDKLog.shared.info("房间列表需要更新:新版本\(newRoom?.version ?? -1) 老版本\(oldRoom?.version ?? -1)")
                downloadProgress(4)
                BWRoom.QueryRoom(success: {
                    if $0 == 1 {
                        BWSDKLog.shared.info("房间列表更新完毕")
                        newRoom?.save()
                        BWAppManager.shared.removeAllHandle()
                        BWAppManager.shared.killDelayTime()
                        success()
                        QueryCam()
                        BWRoom.needRefresh?()
                        QueryGatewayVersion()
                        BWDevice.QueryDeviceStatus()
                        BWMSG.QueryUnread()
                    }
                })
            } else {
                BWSDKLog.shared.info("房间列表已是最新")
                BWAppManager.shared.removeAllHandle()
                BWAppManager.shared.killDelayTime()
                success()
                QueryCam()
                BWRoom.needRefresh?()
                QueryGatewayVersion()
                BWDevice.QueryDeviceStatus()
                BWMSG.QueryUnread()
            }
        }
        /// 更新联动，内部使用
        func UpdateLinkage(oldModule: [BWModuleVersion], newModule: [BWModuleVersion]) {
            let oldLinkage = oldModule.first { $0.module == "linkage" }
            let newLinkage = newModule.first { $0.module == "linkage" }
            if oldLinkage == nil || oldLinkage?.version != newLinkage?.version {
                BWSDKLog.shared.info("联动列表需要更新:新版本\(newLinkage?.version ?? -1) 老版本\(oldLinkage?.version ?? -1)")
                downloadProgress(3)
                BWLinkage.QueryLinkage(success: {
                    if $0 == 1 {
                        BWSDKLog.shared.info("联动列表更新完毕")
                        newLinkage?.save()
                        BWLinkage.needRefresh?()
                        UpdateRoom(oldModule: oldModule, newModule: newModule)
                    }
                })
            } else {
                BWSDKLog.shared.info("联动列表已是最新")
                BWLinkage.needRefresh?()
                UpdateRoom(oldModule: oldModule, newModule: newModule)
            }
        }
        /// 更新定时，内部使用
        func UpdateTimer(oldModule: [BWModuleVersion], newModule: [BWModuleVersion]) {
            let oldTimer = oldModule.first { $0.module == "timer" }
            let newTimer = newModule.first { $0.module == "timer" }
            if oldTimer == nil || oldTimer?.version != newTimer?.version {
                BWSDKLog.shared.info("定时列表需要更新:新版本\(newTimer?.version ?? -1) 老版本\(oldTimer?.version ?? -1)")
                downloadProgress(2)
                BWTimer.QueryTimer(success: {
                    if $0 == 1 {
                        BWSDKLog.shared.info("定时列表更新完毕")
                        newTimer?.save()
                        BWTimer.needRefresh?()
                        UpdateLinkage(oldModule: oldModule, newModule: newModule)
                    }
                })
            } else {
                BWSDKLog.shared.info("定时列表已是最新")
                BWTimer.needRefresh?()
                UpdateLinkage(oldModule: oldModule, newModule: newModule)
            }
        }
        /// 更新场景，内部使用
        func UpdateScene(oldModule: [BWModuleVersion], newModule: [BWModuleVersion]) {
            let oldScene = oldModule.first { $0.module == "scene" }
            let newScene = newModule.first { $0.module == "scene" }
            if oldScene == nil || oldScene?.version != newScene?.version {
                BWSDKLog.shared.info("场景列表需要更新:新版本\(newScene?.version ?? -1) 老版本\(oldScene?.version ?? -1)")
                downloadProgress(1)
                BWScene.QueryScene(success: {
                    if $0 == 1 {
                        BWSDKLog.shared.info("场景列表更新完毕")
                        newScene?.save()
                        BWScene.needRefresh?()
                        UpdateTimer(oldModule: oldModule, newModule: newModule)
                    }
                })
            } else {
                BWSDKLog.shared.info("场景列表已是最新")
                BWScene.needRefresh?()
                UpdateTimer(oldModule: oldModule, newModule: newModule)
            }
        }
        /// 更新设备，内部使用
        func UpdateDevice(oldModule: [BWModuleVersion], newModule: [BWModuleVersion]) {
            let oldDevice = oldModule.first { $0.module == "device" }
            let newDevice = newModule.first { $0.module == "device" }
            if oldDevice == nil || oldDevice?.version != newDevice?.version {
                BWSDKLog.shared.info("设备列表需要更新:新版本\(newDevice?.version ?? -1) 老版本\(oldDevice?.version ?? -1)")
                downloadProgress(0)
                BWDevice.QueryDevice(success: {
                    if $0 == 1 {
                        BWSDKLog.shared.info("设备列表更新完毕")
                        newDevice?.save()
                        BWDevice.needRefresh?()
                        UpdateScene(oldModule: oldModule, newModule: newModule)
                    }
                })
            } else {
                BWSDKLog.shared.info("设备列表已是最新")
                BWDevice.needRefresh?()
                UpdateScene(oldModule: oldModule, newModule: newModule)
            }
        }
        
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.removeAllHandle()
            timeOutHandle()
        }
        if forceUpdate {
            BWDevice.deviceStatus.removeAll()
            BWDevice.quickDevices = nil
            BWDevice.wifiPermission = nil
            BWZone.ZoneCache.zones.removeAll()
            BWModuleVersion.clearTable(dbName: BWAppManager.shared.loginGWDBName())
        }
        BWUser.QueryPermission {
            BWModuleVersion.QueryModuleVersion(success: { modules in
                let oldModules = BWModuleVersion.query()
                UpdateDevice(oldModule: oldModules, newModule: modules)
            }, fail: {
                BWAppManager.shared.killDelayTime()
                fail($0)
            })
        }
    }

    
    /// 设置组网时间
    /// - Parameters:
    ///   - time: 组网的时间，设置0表示关闭组网，最大255
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败谁的
    public static func NetOpen(time: Int = 0,
                               timeOut: TimeInterval = 8,
                               timeOutHandle: @escaping ()->Void = {},
                               success: @escaping (Int)->Void = { _ in },
                               fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("设置组网:\(time)")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayNetOpen(time: time) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0, let time = json["time"].int {
                success(time)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    

    /// 设置网关别名
    /// - Parameters:
    ///   - alias: 别名
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func SetAlias(alias: String,
                                timeOut: TimeInterval = 8,
                                timeOutHandle: @escaping ()->Void = {},
                                success: @escaping ()->Void = {},
                                fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("设置别名:\(alias)")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayAlias(alias: ["alias": alias]) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        aliasHandle = success
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                ObjectMSG.paraseMSG(msg: json)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// zigbee组网
    /// - Parameters:
    ///   - mode: 选择通道的方式，0自动，1手动
    ///   - channel: mode=1，手动时，需要传入channel的值
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func BuildZigbeeNetwork(mode: Int,
                                          channel: Int = 19,
                                          timeOut: TimeInterval = 8,
                                          timeOutHandle: @escaping ()->Void = {},
                                          success: @escaping ()->Void = {},
                                          fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("zigbee组网")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        var info = [String: Int]()
        info["mode"] = mode
        if mode == 1 {
            info["signal_channel"] = channel
        }
        guard let msg = ObjectMSG.gatewayNetwork(info: info) else {
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
    
    
    /// 当前用户解绑当前网关，如果是子用户，是退出，主用户，则是解绑。界面需自行判断
    /// - Parameters:
    ///   - pwd: 密码
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时时间
    ///   - success: 成功
    ///   - fail: 失败
    public func quitGateway(pwd: String,
                            timeOut: TimeInterval = 8,
                            timeOutHandle: @escaping ()->Void = {},
                            success: @escaping ()->Void = {},
                            fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("退出/解绑该网关:\(self)")
        if BWAppManager.shared.appState == .NoLogin {
            BWSDKLog.shared.error("没有登录服务器，登录服务器后再执行该操作！")
            fail(-1)
            return
        }
        guard let sn = sn else {
            BWSDKLog.shared.error("该网关没有SN号！")
            fail(-1)
            return
        }
        guard let msg = privilege == 1 ? ObjectMSG.gatewayUserQuit(sn: sn, pwd: pwd) : ObjectMSG.gatewayUnbind(sn: sn, pwd: pwd) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { [weak self] json in
            BWAppManager.shared.killDelayTime()
            if json["status"].intValue == 0 {
                BWGateway.delete(phone: BWAppManager.shared.username ?? "", sn: self?.sn ?? "")
                success()
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 绑定网关
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时时间
    ///   - success: 成功
    ///   - fail: 失败
    public func bindGateway(timeOut: TimeInterval = 8,
                            timeOutHandle: @escaping ()->Void = {},
                            success: @escaping ()->Void = {},
                            fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("绑定网关:\(self)")
        if BWAppManager.shared.appState == .NoLogin {
            BWSDKLog.shared.error("没有登录服务器，登录服务器后再执行该操作！")
            fail(-1)
            return
        }
        guard let sn = sn else {
            BWSDKLog.shared.error("该网关没有SN号！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayBind(sn: sn) else {
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
    
    
    /// 绑定网关
    /// - Parameters:
    ///   - sn: SN
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 是吧
    public static func BindGateway(sn: String,
                                   timeOut: TimeInterval = 8,
                                   timeOutHandle: @escaping ()->Void = {},
                                   success: @escaping ()->Void = {},
                                   fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("绑定网关:\(self)")
        if BWAppManager.shared.appState == .NoLogin {
            BWSDKLog.shared.error("没有登录服务器，登录服务器后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayBind(sn: sn) else {
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
    
    
    /// 版本查询
    /// - Parameters:
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   -  delay: 是否超时
    ///   - success: 成功，参数1 版本分类     参数2 版本信息，会调多次调用成功回调，自行处理
    ///   - fail: 失败
    public static func HardVerQuery(timeOut: TimeInterval = 8,
                                    timeOutHandle: @escaping ()->Void = {},
                                    delay: Bool = true,
                                    success: @escaping (String, String)->Void = { (_, _) in },
                                    fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("版本查询")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayHardVerQuery() else {
            fail(-1)
            return
        }
        if delay {
            BWAppManager.shared.buildDelayTime(time: timeOut) {
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if delay {
                BWAppManager.shared.killDelayTime()
            }
            if json["status"].intValue == 0, let infos = json["version_info"].array {
                infos.forEach {
                    success($0["module"].string ?? "", $0["version"].string ?? "")
                    if let mac = $0["mac"].string {
                        success("mac", mac)
                    }
                    if let channel = $0["channel"].string {
                        success("channel", channel)
                    }
                    if let model = $0["model"].string {
                        success("model", model)
                    }
                }
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 请求网关升级，如果网关可以升级，则会直接开始升级
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，请通过
    ///      升级代码：
    ///     0 无需升级
    ///     1 发现新版，开始下载
    ///     2 估计下载完毕，网关开始升级
    ///      -1 下载固件失败
    ///      -2 下载估计完毕，MD5检验失败
    ///      1001 协调器未组网，不用升级
    ///   - fail: 失败
    public static func Update(timeOut: TimeInterval = 8,
                              timeOutHandle: @escaping ()->Void = {},
                              delay: Bool = true,
                              success: @escaping (Int)->Void = { _ in },
                              fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("请求网关升级")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayUpdate() else {
            fail(-1)
            return
        }
        BWGateway.updateHandle = success
        if delay {
            BWAppManager.shared.buildDelayTime(time: timeOut) {
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if delay {
                BWAppManager.shared.killDelayTime()
            }
            if json["status"].intValue == 0 {
                ObjectMSG.paraseMSG(msg: json)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 请求协调器升级，如果协调器可以升级，则会直接开始升级
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，请通过
    ///     升级代码：
    ///     0 无需升级
    ///     1 发现新版，开始下载
    ///     2 估计下载完毕，网关开始升级
    ///     -1 下载固件失败
    ///     -2 下载估计完毕，MD5检验失败
    ///     201 升级成功
    ///     202 升级失败
    ///     1001 协调器未组网
    ///     1002 协调器正在组网
    ///   - fail: 失败
    public static func HubUpdate(timeOut: TimeInterval = 8,
                                 timeOutHandle: @escaping ()->Void = {},
                                 delay: Bool = true,
                                 success: @escaping (Int)->Void = { _ in },
                                 fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("请求协调器升级")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayHubUpdate() else {
            fail(-1)
            return
        }
        BWGateway.hubUpdateHandle = success
        if delay {
            BWAppManager.shared.buildDelayTime(time: timeOut) {
                BWAppManager.shared.msgTimeOut(msg: msg)
                timeOutHandle()
            }
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            if delay {
                BWAppManager.shared.killDelayTime()
            }
            if json["status"].intValue == 0 {
                ObjectMSG.paraseMSG(msg: json)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 请求设备升级
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，请通过
    ///     升级代码：
    ///0—表示当前版本已是最新版本，不需要升级
    ///1—发现最新版本，固件升级进行中
    ///2—有设备正在升级，请稍等
    ///3---设备不在线无法升级
    ///4---网关没接外网设备无法升级
    ///5---固件md5校验成功
    ///6--设备固件升级成功
    ///-1---升级失败
    ///-2---固件md5校验失败
    ///-3---网关flash已经占满，无法升级更多设备
    ///-4---下载设备固件失败
    ///   - fail: 失败
    public static func DeviceUpdate(deviceID: Int,
                                    timeOut: TimeInterval = 8,
                                    timeOutHandle: @escaping ()->Void = {},
                                    success: @escaping (Int)->Void = { _ in },
                                    fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("请求设备升级")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayDeviceUpdate(deviceID: deviceID) else {
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
                success(json["update_state"].int ?? -1)
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    /// 新请求设备升级
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，请通过
    ///     升级代码：
    ///1—等待升级
    ///2—正在升级
    ///3---取消升级
    public static func NewDeviceUpdate(deviceID: Int,
                                       timeOut: TimeInterval = 8,
                                       timeOutHandle: @escaping ()->Void = {},
                                       success: @escaping (Int)->Void = { _ in },
                                       fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("请求设备升级")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayDeviceUpdate(deviceID: deviceID) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if let devices = json["device"].array {
                var state = -1
                for device in devices {
                    if device["device_id"].int == deviceID {
                        state = device["update_state"].int ?? 0
                        break
                    }
                }
                state == -1 ? fail(-1) : success(state)
            } else {
                fail(-1)
            }
        })
    }
    
    /// 查询设备升级状态
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，请通过
    ///     升级代码：
    ///1—等待升级
    ///2—正在升级
    ///3---取消升级
    public static func QueryDeviceUpdate(timeOut: TimeInterval = 8,
                                         timeOutHandle: @escaping ()->Void = {},
                                         success: @escaping ([Int: Int])->Void = { _ in },
                                         fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询设备升级状态")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayDeviceUpdateQuery() else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if let devices = json["device"].array {
                var result = [Int: Int]()
                for device in devices {
                    if let id = device["device_id"].int, let state = device["update_state"].int {
                        result[id] = state
                    }
                }
                success(result)
            } else {
                fail(-1)
            }
        })
    }
    
    /// 取消设备升级
    /// - Parameters:
    ///   - deviceIDs: 设备ID
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功
    ///   - fail: 失败
    public static func CancelDeviceUpdate(deviceIDs: [Int],
                                          timeOut: TimeInterval = 8,
                                          timeOutHandle: @escaping ()->Void = {},
                                          success: @escaping ([Int: Int])->Void = { _ in },
                                          fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("取消设备升级")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayDeviceUpdateCancal(deviceIDs: deviceIDs) else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: timeOut) {
            BWAppManager.shared.msgTimeOut(msg: msg)
            timeOutHandle()
        }
        BWAppManager.shared.sendMSG(msg: msg, backHandle: { json in
            BWAppManager.shared.killDelayTime()
            if let devices = json["device"].array {
                var result = [Int: Int]()
                for device in devices {
                    if let id = device["device_id"].int, let state = device["update_state"].int {
                        result[id] = state
                    }
                }
                success(result)
            } else {
                fail(-1)
            }
        })
    }
    
    /// 设置推送
    /// - Parameters:
    ///   - type: 类型，Alert  报警      Lock  门锁     Event  事件
    ///   - app: 1开启    0关闭
    ///   - sms: 同上
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func setPush(type: String,
                               app: Int,
                               sms: Int,
                               timeOut: TimeInterval = 8,
                               timeOutHandle: @escaping ()->Void = {},
                               success: @escaping ()->Void = {},
                               fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("推送设置")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.setPush(type: type, app: app, sms: sms) else {
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
    
    /// 获取推送设置
    /// - Parameters:
    ///   - timeOut: 超时
    ///   - timeOutHandle: 超时
    ///   - success: 成功，参数对应：安防(app开关,短信开关),门锁(app开关,短信开关),事件(app开关,短信开关),短信剩余
    ///   - fail: 失败
    public static func getPushSet(timeOut: TimeInterval = 20,
                                  timeOutHandle: @escaping ()->Void = {},
                                  success: @escaping ((Int, Int), (Int, Int), (Int, Int), Int)->Void = { _, _, _, Int in },
                                  fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询推送设置")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let alert = ObjectMSG.queryPushSet(type: "Alert") else {
            fail(-1)
            return
        }
        guard let lock = ObjectMSG.queryPushSet(type: "Lock") else {
            fail(-1)
            return
        }
        guard let event = ObjectMSG.queryPushSet(type: "Event") else {
            fail(-1)
            return
        }
        guard let sms = ObjectMSG.querySMSNumber(sn: BWAppManager.shared.loginGateway?.sn ?? "") else {
            fail(-1)
            return
        }
        BWAppManager.shared.buildDelayTime(time: 20) {
            BWAppManager.shared.msgTimeOut(msg: alert)
            BWAppManager.shared.msgTimeOut(msg: lock)
            BWAppManager.shared.msgTimeOut(msg: event)
            BWAppManager.shared.msgTimeOut(msg: sms)
            timeOutHandle()
        }
        var alertSet = (0, 0)
        var lockSet = (0, 0)
        var eventSet = (0, 0)
        var smsNumber = 0
        
        func send(msg: String, type: Int, next: @escaping ()->Void) {
            BWAppManager.shared.sendMSG(msg: msg) { json in
                if json["status"].intValue == 0 {
                    if let appSet = json["config"]["app"].int, let smsSet = json["config"]["sms"].int {
                        if type == 0 {
                            alertSet = (appSet, smsSet)
                        } else if type == 1 {
                            lockSet = (appSet, smsSet)
                        } else if type == 2 {
                            eventSet = (appSet, smsSet)
                        }
                    }
                    if type == 3, let num = json["config"]["smsbalance"].int {
                        smsNumber = num
                    }
                    next()
                } else {
                    BWAppManager.shared.killDelayTime()
                    fail(json["status"].intValue)
                }
            }
        }
        
        send(msg: alert, type:0) {
            send(msg: lock, type:1) {
                send(msg: event, type:2) {
                    send(msg: sms, type:3) {
                        BWAppManager.shared.killDelayTime()
                        success(alertSet, lockSet, eventSet, smsNumber)
                    }
                }
            }
        }
    }
    
    
    /// 查询网关网络设置
    /// - Parameters:
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时回调
    ///   - success: 成功回调
    ///   - fail: 失败回调
    public static func getNetworkInfo(timeOut: TimeInterval = 8,
                                      timeOutHandle: @escaping ()->Void = {},
                                      success: @escaping (Int, String, Int, String, String, String)->Void = {_, _, _, _, _, _ in},
                                      fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("查询网关网络设置")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        guard let msg = ObjectMSG.gatewayNetworkInfo() else {
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
                let info = json["gateway"]
                success(
                    info["net_mode"].int ?? 0,
                    info["ip"].string ?? "",
                    info["port"].int ?? 0,
                    info["netmask"].string ?? "",
                    info["gateway"].string ?? "",
                    info["dns"].string ?? ""
                )
            } else {
                fail(json["status"].intValue)
            }
        })
    }
    
    
    /// 设置网关网络
    /// - Parameters:
    ///   - mode: 模式 0动态 1静态
    ///   - port: 端口
    ///   - ip: IP
    ///   - gateway: 网关
    ///   - mask: 子网掩码
    ///   - dns: DNS
    ///   - timeOut: 超时时间
    ///   - timeOutHandle: 超时
    ///   - success: 成功
    ///   - fail: 失败
    public static func setNetworkInfo(mode: Int,
                                      port: Int,
                                      ip: String,
                                      gateway: String,
                                      mask: String,
                                      dns: String,
                                      timeOut: TimeInterval = 8,
                                      timeOutHandle: @escaping ()->Void = {},
                                      success: @escaping ()->Void = {},
                                      fail: @escaping (Int)->Void = { _ in }) {
        BWSDKLog.shared.debug("设置网关网络设置")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            fail(-1)
            return
        }
        let info: [String: Any] = [
            "net_mode": mode,
            "ip": ip,
            "port": port,
            "netmask": mask,
            "gateway": gateway,
            "dns": dns
        ]
        guard let msg = ObjectMSG.gatewaySetNetworkInfo(info: info) else {
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
}

