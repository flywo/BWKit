//
//  BWUDP.swift
//  BWKit
//
//  Created by yuhua on 2020/3/18.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import SwiftyJSON


class BWUDP: NSObject {
    
    /// udp客户端
    var udpClient: GCDAsyncUdpSocket?
    
    /// 搜索成功的回调
    var handle: ((String)->Void)?
    
    /// 消息
    var msg: Data!
    
    /// 间隔
    var space: TimeInterval!
    
    /// 初始化
    init(space: TimeInterval) {
        super.init()
        self.space = space
        udpClient = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global())
        try? udpClient?.bind(toPort: 7102)
        try? udpClient?.enableBroadcast(true)
        try? udpClient?.receiveOnce()
    }
    
    /// 开始搜索，请勿重复调用
    func startSerach(searchResult: @escaping (String)->Void, msg: String) {
        BWSDKLog.shared.debug("开始局域网搜索:\(msg)")
        self.msg = msg.data(using: .utf8)
        handle = searchResult
        sendMSG()
    }
    
    /// 停止搜索
    @objc func stopSearch() {
        BWSDKLog.shared.info("停止局域网搜索")
        udpClient?.setDelegate(nil, delegateQueue: nil)
        udpClient?.close()
        udpClient = nil
        handle = nil
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    /// 发送搜索方法
    @objc func sendMSG() {
        BWSDKLog.shared.info("搜索消息已发送")
        udpClient?.send(msg, toHost: "255.255.255.255", port: 7103, withTimeout: 4, tag: 0)
        perform(#selector(sendMSG), with: self, afterDelay: space)
    }
}


extension BWUDP: GCDAsyncUdpSocketDelegate {
    
    /// 收到udp消息
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        objc_sync_enter(self)
        let str = String(data: data, encoding: .utf8)
        BWSDKLog.shared.info("udp接收到消息，开始解析")
        if let str = str , str.count > 8 {
            let start = str.index(str.startIndex, offsetBy: 8)
            let end = str.endIndex
            let result = str[start ..< end]
            handle?(String(result))
        }
        try? sock.receiveOnce()
        BWSDKLog.shared.info("udp消息解析完毕")
        objc_sync_exit(self)
    }
}
