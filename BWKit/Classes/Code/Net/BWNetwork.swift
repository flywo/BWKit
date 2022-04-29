//
//  BWNet.swift
//  BWKit
//
//  Created by yuhua on 2020/3/3.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import SwiftyJSON


/// 网络类
class BWNetwork: NSObject {
    
    /// 网络队列
    private let queue = DispatchQueue.global()
    
    /// 回调存储字典
    @Atomic private var handleClosure = [String: (JSON)->Void]()
    
    /// 缓存数据
    private var data = Data()
    
    /// 是否是局域网socket
    var isLocal = false
    
    /// 开始解析消息前检查消息，返回true，表示该消息继续解析，否则丢弃掉该消息，默认都解析
    var checkMSG: ((JSON)->Bool) = { _ in
        return true
    }
    
    /// 断开连接后的操作
    var disconnectHandle: (()->Void)?
    
    /// 连接成功后的操作
    var connectHandle: (()->Void)?
    
    /// tcp客户端
    var tcpClient: GCDAsyncSocket?
    
    /// 消息接收后处理
    var msgReceiveHandle: ((JSON) -> Void)?
    
    /// 服务器host
    var host: String?
    
    /// 服务器端口
    var port: UInt16?
    
    /// 需要判断end的消息
    var needEndMSGName = [String]()
    
    /// 清除回调
    func removeHandle(msgID: String) {
        if handleClosure.removeValue(forKey: msgID) != nil {
            BWSDKLog.shared.info("\(isLocal ? "(local)" : "")\(msgID)回调被主动移除")
        }
    }
    
    /// 清除所有回调
    func removeAllHandle() {
        handleClosure.removeAll()
        BWSDKLog.shared.debug("\(isLocal ? "(local)" : "")所有回调被移除:\(handleClosure.keys)")
    }
    
    /// 断开连接
    func disconnectServer() {
        tcpClient?.setDelegate(nil, delegateQueue: nil)
        tcpClient?.disconnect()
        tcpClient = nil
        removeAllHandle()
        connectHandle = nil
        disconnectHandle = nil
        msgReceiveHandle = nil
    }
    
    /// 创建连接
    func creatSocketConnectServer(success: @escaping ()->Void = {}, fail: ()->Void = {}) {
        tcpClient = GCDAsyncSocket(delegate: self, delegateQueue: queue)
        do {
            connectHandle = success
            BWSDKLog.shared.info("\(isLocal ? "(local)" : "")开始连接:\(self.host!) \(self.port!)")
            try tcpClient?.connect(toHost: self.host!, onPort: self.port!, withTimeout: 10)
        } catch let err {
            BWSDKLog.shared.error("\(isLocal ? "(local)" : "")连接\(self.host!)发生错误:\(err.localizedDescription)")
            fail()
        }
    }
    
    /// 发送消息
    ///
    /// - Parameters:
    ///   - msg: 消息内容
    ///   - backHandle: 消息成功后回调
    func sendMSG(msg: String, backHandle: ((JSON)->Void)?) {
        BWSDKLog.shared.debug("\(isLocal ? "(local)" : "")发送消息给\(self.host!):\(msg)")
        guard tcpClient != nil else {
            BWSDKLog.shared.error("\(isLocal ? "(local)" : "")尚未连接:\(self.host!)")
            return
        }
        guard let encrypt = ObjectMSG.getFullMSG(msg: port == 17070 ? String(msg.suffix(from: msg.index(msg.startIndex, offsetBy: 8))).encryptString() : String(msg.suffix(from: msg.index(msg.startIndex, offsetBy: 8)))) else {
            BWSDKLog.shared.error("\(isLocal ? "(local)" : "")消息加密发生错误:\(self.host!)")
            return
        }
        let data = encrypt.data(using: .utf8)
        guard let content = data else {
            BWSDKLog.shared.error("\(isLocal ? "(local)" : "")数据转换发生错误:\(self.host!)")
            return
        }
        tcpClient?.write(content, withTimeout: 8, tag: 0)
        if let back = backHandle {
            let json = JSON.init(parseJSON: String(msg.suffix(from: msg.index(msg.startIndex, offsetBy: 8))))
            let key = json["msg_id"].string
            if let backKey = key {
                BWSDKLog.shared.debug("增加回调:\(backKey)")
                handleClosure[backKey] = back
            }
        }
    }
    
    /// 解析数据
    private func parseMSG() {
        if self.data.isEmpty {
            return
        }
        let head = "@#$%".data(using: .utf8)!
        if self.data.count > 8 , head == self.data[self.data.startIndex ..< self.data.index(self.data.startIndex, offsetBy: 4)] {
            let lenData = self.data[self.data.index(self.data.startIndex, offsetBy: 4) ..< self.data.index(self.data.startIndex, offsetBy: 8)]
            let lenStr = String(data: lenData, encoding: .utf8)
            var len: UInt32 = 0
            Scanner(string: lenStr!).scanHexInt32(&len)
            if Int(len) > self.data.count {
                return
            }
            let msg = self.data[self.data.index(self.data.startIndex, offsetBy: 8) ..< self.data.index(self.data.startIndex, offsetBy: Int(len))]
            let result = port == 17070 ? String(data: msg, encoding: .utf8)?.decryptString() : String(data: msg, encoding: .utf8)
            guard let raw = result else {
                return
            }
            BWSDKLog.shared.debug("\(isLocal ? "(local)" : "")取出数据:\(raw)")
            
            let json = JSON.init(parseJSON: raw)
            if checkMSG(json) {
                let key = json["msg_id"].string
                let msgName = json["msg_name"].string
                if let backKey = key, let back = handleClosure[backKey] {
                    DispatchQueue.main.async {
                        BWSDKLog.shared.info("\(self.isLocal ? "(local)" : "")该消息触发回调:\(backKey)")
                        back(json)
                    }
                    if let name = msgName, needEndMSGName.contains(name) {
                        if let end = json["end"].int, end == 1 {
                            removeHandle(msgID: backKey)
                        }
                    } else {
                        removeHandle(msgID: backKey)
                    }
                }else {
                    if let closure = msgReceiveHandle {
                        DispatchQueue.main.async {
                            BWSDKLog.shared.info("\(self.isLocal ? "(local)" : "")该消息为主动收到消息:\(key ?? "") -> \(msgName ?? "")")
                            closure(json)
                        }
                    } else {
                        BWSDKLog.shared.debug("\(isLocal ? "(local)" : "")有消息未被处理:\(raw)")
                    }
                }
            }
            
            self.data.removeSubrange(0..<Int(len))
            if !self.data.isEmpty {
                BWSDKLog.shared.info("\(isLocal ? "(local)" : "")继续解析消息")
                parseMSG()
            }
        }
    }
}


// MARK: - GCDAsyncSocketDelegate
extension BWNetwork: GCDAsyncSocketDelegate {
    
    /// 连接成功
    ///
    /// - Parameters:
    ///   - sock: 连接成功的socket
    ///   - host: 连接成功的host
    ///   - port: 连接成功的port
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        sock.readData(withTimeout: -1, tag: 0)
        BWSDKLog.shared.info("\(isLocal ? "(local)" : "")连接成功:\(host) \(port)")
        DispatchQueue.main.async {
            self.connectHandle?()
        }
    }
    
    /// 断开连接
    ///
    /// - Parameters:
    ///   - sock: 断开连接的socket
    ///   - err: 发生的错误
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        BWSDKLog.shared.error("\(isLocal ? "(local)" : "")断开连接:\(host!) \(port!) \(err?.localizedDescription ?? "")")
        DispatchQueue.main.async {
            self.disconnectHandle?()
        }
    }
    
    /// 消息发送成功
    ///
    /// - Parameters:
    ///   - sock: 发送的socket
    ///   - tag: 消息的标签
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        BWSDKLog.shared.info("\(isLocal ? "(local)" : "")消息发送成功")
    }
    
    /// 发送消息的进度
    ///
    /// - Parameters:
    ///   - sock: 发送的socket
    ///   - partialLength: 进度
    ///   - tag: 消息的标签
    func socket(_ sock: GCDAsyncSocket, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        BWSDKLog.shared.info("\(isLocal ? "(local)" : "")消息进度:\(partialLength)")
    }
    
    /// 消息超时
    ///
    /// - Parameters:
    ///   - sock: 发送的scoket
    ///   - tag: 消息的标签
    ///   - elapsed: 用时
    ///   - length: 完成长度
    /// - Returns: 返回继续等待时间
    func socket(_ sock: GCDAsyncSocket, shouldTimeoutWriteWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        BWSDKLog.shared.error("\(isLocal ? "(local)" : "")发送消息超时")
        return -1
    }
    
    /// 接收消息成功
    ///
    /// - Parameters:
    ///   - sock: 接收的socket
    ///   - data: 接收到的数据
    ///   - tag: 消息的标签
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        objc_sync_enter(self)
        BWSDKLog.shared.info("\(isLocal ? "(local)" : "")接收到消息，开始解析")
        self.data.append(data)
        parseMSG()
        BWAppManager.shared.heart?.receiveMSG()
        sock.readData(withTimeout: -1, tag: 0)
        BWSDKLog.shared.info("\(isLocal ? "(local)" : "")消息解析完毕")
        objc_sync_exit(self)
    }
    
    /// 接收消息的进度
    ///
    /// - Parameters:
    ///   - sock: 接收的socket
    ///   - partialLength: 进度
    ///   - tag: 消息的标签
    func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        BWSDKLog.shared.info("\(isLocal ? "(local)" : "")接收消息进度:\(partialLength)")
    }
}
