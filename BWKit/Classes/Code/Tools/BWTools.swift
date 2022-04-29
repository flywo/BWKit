//
//  BWTools.swift
//  BWKit
//
//  Created by yuhua on 2020/3/3.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation
import SQLite
import Alamofire
import CryptoSwift


extension Substring {
    /// 转成string
    var string: String {
        return String(self)
    }
}

extension String {
    
    /// 十六进制字符串转数字
    func toIntValue() -> Int {
        var len: UInt32 = 0
        Scanner(string: self).scanHexInt32(&len)
        return Int(len)
    }
    
    /// 十六进制字符串转对应data
    func hexStrToData() -> Data {
        let data = Array<UInt8>(hex: self)
        return Data(data)
    }
    
    func offset(by distance: Int) -> String.Index? {
        return index(startIndex, offsetBy: distance, limitedBy: endIndex)
    }
    subscript(range: Range<Int>) -> Substring? {
        guard let left = offset(by: range.lowerBound) else { return nil }
        guard let right = index(left, offsetBy: range.upperBound - range.lowerBound,
                                limitedBy: endIndex) else { return nil }
        return self[left..<right]
    }
    /// 获得子字符串
    func substring(from: Int?, length: Int) -> String? {
        guard length > 0 else {
            return nil
        }
        let start = from ?? 0
        let end = min(count, max(0, start) + length)
        guard start < end else {
            return nil
        }
        return self[start..<end]?.string
    }
    
    /// 加密门锁开门密码
    /// - Parameter random: 添加用户时不需要输入随机数，开锁需要
    func encryptDoorLockPWD(random: String = "") -> String {
        return BWAES128.aes128Encryption(self, random: random, key: "9290648675218438")
    }
    
    /// 加密字符串
    func encryptString() -> String {
        do {
            let aes = try AES(key: "45ac9ba1c63f2a7b", iv: "ffb9de7d4154249b")
            let result = try aes.encrypt(Array(self.utf8))
            return result.toBase64() ?? ""
        } catch let error {
            BWSDKLog.shared.error("加密出错:\(error.localizedDescription)")
            return ""
        }
    }
    
    /// 解密字符串
    func decryptString() -> String {
        do {
            let result = try self.decryptBase64ToString(cipher: AES(key: "45ac9ba1c63f2a7b", iv: "ffb9de7d4154249b"))
            return result
        } catch let error {
            BWSDKLog.shared.error("解密出错:\(error.localizedDescription)")
            return ""
        }
    }
}

extension Date {
    /// 转换成时间字符串
    /// - Parameter format: 格式，如yyyy-MM-dd HH:mm:ss
    func toString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

public extension Array where Element: BWScene {
    /// 保存排序
    @discardableResult func saveSort() -> Bool {
        BWSDKLog.shared.debug("批量保存场景排序")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return false
        }
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
            for (index, item) in enumerated() {
                let sort = BWSceneSort()
                sort.belongId = item.ID
                sort.sortId = index
                sort.save()
            }
            BWScene.needRefresh?()
        }
    }
}

public extension Array where Element: BWTimer {
    /// 保存排序
    @discardableResult func saveSort() -> Bool {
        BWSDKLog.shared.debug("批量保存定时排序")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return false
        }
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
            for (index, item) in enumerated() {
                let sort = BWTimerSort()
                sort.belongId = item.ID
                sort.sortId = index
                sort.save()
            }
            BWTimer.needRefresh?()
        }
    }
}

public extension Array where Element: BWLinkage {
    /// 保存排序
    @discardableResult func saveSort() -> Bool {
        BWSDKLog.shared.debug("批量保存联动排序")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return false
        }
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
            for (index, item) in enumerated() {
                let sort = BWLinkageSort()
                sort.belongId = item.ID
                sort.sortId = index
                sort.save()
            }
            BWLinkage.needRefresh?()
        }
    }
}

public extension Array where Element: BWRoom {
    /// 保存排序
    @discardableResult func saveSort() -> Bool {
        BWSDKLog.shared.debug("批量保存房间排序")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return false
        }
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
            for (index, item) in enumerated() {
                let sort = BWRoomSort()
                sort.belongId = item.ID
                sort.sortId = index
                sort.save()
            }
            BWRoom.needRefresh?()
        }
    }
}

public extension Array where Element: BWDevice {
    /// 保存排序
    @discardableResult func saveSort() -> Bool {
        BWSDKLog.shared.debug("批量保存设备整体排序")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return false
        }
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
            for (index, item) in enumerated() {
                let sort = BWDeviceSort()
                sort.belongId = item.ID
                sort.sortId = index
                sort.save()
            }
            BWDevice.needRefresh?()
        }
    }
    
    /// 保存房间内设备排序
    @discardableResult func saveRoomSort() -> Bool {
        BWSDKLog.shared.debug("批量保存设备房间内的排序")
        if BWAppManager.shared.loginGateway == nil {
            BWSDKLog.shared.error("没有登录网关，登录网关后再执行该操作！")
            return false
        }
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: BWAppManager.shared.loginGWDBName()) {
            for (index, item) in enumerated() {
                let sort = BWDeviceRoomSort()
                sort.belongId = item.ID
                sort.sortId = index
                sort.save()
            }
            BWDevice.needRefresh?()
        }
    }
}

extension Array where Element: BWDevice {
    
    /// 批量插入设备数据
    @discardableResult func save(dbName: String, type: String) -> Bool {
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: dbName) {
            forEach {
                $0.type = type
                $0.save(dbName: dbName)
            }
        }
    }
}

extension Array where Element: BWBaseModelProtocol {
    
    /// 批量插入数据
    @discardableResult func save(dbName: String) -> Bool {
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: dbName) {
            forEach {
                $0.save(dbName: dbName)
            }
        }
    }
    
    /// 批量删除数据
    @discardableResult func delete(dbName: String) -> Bool {
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: dbName) {
            forEach {
                $0.delete(dbName: dbName)
            }
        }
    }
}


extension Array where Element: BWSortProtocol {
    /// 批量插入数据
    @discardableResult func save(dbName: String) -> Bool {
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: dbName) {
            forEach {
                $0.save(or: .replace)
            }
        }
    }
}


extension Array where Element == Int {
    
    /// 批量删除以数组内数据作为主键的数据
    @discardableResult func delete(dbName: String, tableName: String) -> Bool {
        if isEmpty {
            return true
        }
        return BWDBManager.shared.transaction(dbName: dbName) {
            forEach {
                BWDBManager.shared.deleteTable(dbName: dbName, tableName: tableName, filter: Expression<Int>("id") == $0)
            }
        }
    }
}

public class BWDTCMDFile {
    
    /// 透传文件路径
    static let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/BW/DT/"
    
    /// 获得透传文件列表
    public static func GetDTFileList() -> [String] {
        if let paths = try? FileManager.default.contentsOfDirectory(atPath: filePath) {
            return paths.map {
                $0.replacingOccurrences(of: filePath, with: "").replacingOccurrences(of: "&&++", with: "/")
            }.filter {
                if $0.contains(".") {
                    return true
                } else {
                    return false
                }
            }
        } else {
            return []
        }
    }
    
    /// 获得透传文件内容--原始内容
    /// - Parameter fileName: 请使用GetDTFileList方法获取到的名称
    public static func GetDTFileStringContent(fileName: String) -> String? {
        if fileName.isEmpty {
            return nil
        }
        do {
            return try String(contentsOfFile: filePath + fileName.replacingOccurrences(of: "/", with: "&&++"), encoding: .utf8)
        } catch let error {
            BWSDKLog.shared.debug("读取透传文件发生错误:\(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获得透传文件内容
    /// - Parameter fileName: 请使用GetDTFileList方法获取到的名称
    public static func GetDTFileContent(fileName: String) -> [BWDeviceCMD]? {
        if fileName.isEmpty {
            return nil
        }
        do {
            let content = try String(contentsOfFile: filePath + fileName.replacingOccurrences(of: "/", with: "&&++"), encoding: .utf8)
            return [BWDeviceCMD](JSONString: content)
        } catch let error {
            BWSDKLog.shared.debug("读取透传文件发生错误:\(error.localizedDescription)")
            return nil
        }
    }
    
    /// 下载透传文件，下载成功后自行调用GetDTFileList方法读取列表查看
    public static func DownloadDTFile(fileURLString: String,
                                      timeOut: TimeInterval = 8,
                                      timeOutHandle: @escaping ()->Void = {},
                                      success: @escaping ()->Void = {},
                                      fail: @escaping ()->Void = {}) {
        if let change = fileURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: change) {
            let request = Alamofire.request(url).responseData { response in
                BWAppManager.shared.killDelayTime()
                if response.error != nil {
                    BWSDKLog.shared.error("下载文件出错:\(response.error?.localizedDescription ?? "")")
                    fail()
                } else {
                    if let data = response.data {
                        WriteStringToFile(str: String(data: data, encoding: .utf8) ?? "", fileURLString: fileURLString)
                    } else {
                        WriteStringToFile(str: "", fileURLString: fileURLString)
                    }
                    success()
                }
            }
            BWAppManager.shared.buildDelayTime(time: timeOut) {
                request.cancel()
                timeOutHandle()
            }
        } else {
            BWSDKLog.shared.error("下载文件，URL出错！")
            fail()
        }
    }
    
    /// 写入文字到指定文件
    static func WriteStringToFile(str: String, fileURLString: String) {
        let rootPath = fileURLString.components(separatedBy: "root").last
        let fileName = rootPath?.replacingOccurrences(of: "/", with: "&&++")
        BWSDKLog.shared.debug("写入到文件中:\(fileName ?? "")")
        var isDirectory: ObjCBool = true
        if !FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) {
            BWSDKLog.shared.debug("路径不存在，创建：\(filePath)")
            try? FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
        }
        if let name = fileName {
            try? FileManager.default.removeItem(atPath: filePath + name)
            do {
                try str.write(toFile: filePath + name, atomically: true, encoding: .utf8)
            } catch let error {
                BWSDKLog.shared.error("写入文件发生错误:\(error.localizedDescription)")
            }
        }
    }
    
    /// 删除透传文件
    public static func RemoveDTFile(fileName: String) {
        if fileName.isEmpty {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: filePath + fileName.replacingOccurrences(of: "/", with: "&&++"))
        } catch let error {
            BWSDKLog.shared.debug("删除透传文件发生错误:\(error.localizedDescription)")
        }
    }
}


/// 原子锁
@propertyWrapper
struct Atomic<Value> {
    private var value: Value
    private let lock = NSLock()
    init(wrappedValue value: Value) {
        self.value = value
    }
    var wrappedValue: Value {
      get { return load() }
      set { store(newValue: newValue) }
    }
    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
    mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
