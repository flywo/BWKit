//
//  BWKitLog.swift
//  BWKit
//
//  Created by yuhua on 2020/3/3.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import SwiftyBeaver


public class BWSDKLog {
    
    /// 单例
    public static let shared = BWSDKLog()
    
    let log = SwiftyBeaver.self
    
    /// 日志文件夹
    let logPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/BW/log/"
    
    /// 是否开启打印
    public var logEnable = true
    
    init() {
        /// 控制台输出
        let console = ConsoleDestination()
        console.format = "$DHH:mm:ss$d $C$L$c: $M"
        log.addDestination(console)
        
        /// 文件输出
        let file = FileDestination()
        let path = logPath + Date().toString(format: "yyyy-MM-dd") + ".log"
        file.format = "$DHH:mm:ss$d $C$L$c: $M"
        file.logFileURL = URL(fileURLWithPath: path)
        log.addDestination(file)
        
        log.info("---------------------初始化BWSDK---------------------")
        log.info("log日志路径:\(path)")
        
        // 只保留2个日志文件
        let fileNames = getLogList()
        if fileNames.count > 2 {
            fileNames[2..<fileNames.count].forEach {
                try? FileManager.default.removeItem(atPath: getLogFilePath(name: $0))
            }
        }
    }
    
    /// 获得日志打印列表
    public func getLogList() -> [String] {
        if let paths = try? FileManager.default.contentsOfDirectory(atPath: logPath) {
            return paths.map {
                $0.replacingOccurrences(of: logPath, with: "")
            }.sorted {
                $0 > $1
            }
        } else {
            return []
        }
    }
    
    /// 获得日志文件路径
    public func getLogFilePath(name: String) -> String {
        return logPath + name
    }
    
    /// 正常打印
    public func verbose(_ message: Any) {
        guard logEnable else {
            return
        }
        log.verbose(message)
    }
    
    /// 调试
    public func debug(_ message: Any) {
        guard logEnable else {
            return
        }
        log.debug(message)
    }
    
    /// 信息
    public func info(_ message: Any) {
        guard logEnable else {
            return
        }
        log.info(message)
    }
    
    /// 警告
    public func warning(_ message: Any) {
        guard logEnable else {
            return
        }
        log.warning(message)
    }
    
    /// 错误
    public func error(_ message: Any) {
        guard logEnable else {
            return
        }
        log.error(message)
    }
}
