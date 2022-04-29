//
//  BWHeart.swift
//  BWKit
//
//  Created by yuhua on 2020/4/17.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation


class BWHeart: NSObject {
    
    /// 最后一次收到消息时间
    var lastReceiveMSGTime: Date?
    
    override init() {
        super.init()
        DispatchQueue.main.async {
            self.perform(#selector(self.sendHeart), with: nil, afterDelay: 60)
        }
    }
    
    /// 发送心跳消息
    @objc func sendHeart() {
        if let last = lastReceiveMSGTime {
            let since = Date().timeIntervalSince(last)
            BWSDKLog.shared.debug("距离上一次收到消息:\(since)")
            if since >= 180 {
                BWSDKLog.shared.debug("超过180秒未收到心跳，判断与服务器断开连接，重新连接")
                BWAppManager.shared.disconnectServer()
                BWAppManager.shared.initManager(appId: MSGFix.appId)
                BWAppManager.shared.disconnect?()
                return
            }
        }
        if BWAppManager.shared.appState == .LoginGatewayUseLocal {
            // 发送心跳
            guard let msg = ObjectMSG.gatewayHeart() else {
                return
            }
            BWSDKLog.shared.debug("发送心跳")
            BWAppManager.shared.sendMSG(msg: msg)
            self.perform(#selector(sendHeart), with: nil, afterDelay: 60)
            return
        }
        // 发送心跳
        guard let msg = ObjectMSG.serverHeart() else {
            return
        }
        BWSDKLog.shared.debug("发送心跳")
        BWAppManager.shared.sendMSG(msg: msg)
        self.perform(#selector(sendHeart), with: nil, afterDelay: 60)
    }
    
    /// 停止心跳发送
    func stopHeart() {
        DispatchQueue.main.async {
            BWSDKLog.shared.debug("停止心跳")
            self.lastReceiveMSGTime = nil
            NSObject.cancelPreviousPerformRequests(withTarget: self)
        }
    }
    
    /// 接收到消息
    func receiveMSG() {
        DispatchQueue.main.async {
            BWSDKLog.shared.debug("重置心跳")
            self.lastReceiveMSGTime = Date()
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.perform(#selector(self.sendHeart), with: nil, afterDelay: 60)
        }
    }
}

