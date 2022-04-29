//
//  BWMusicParse.swift
//  BWKit
//
//  Created by yuhua on 2020/4/13.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation


public class BWMusicParse {
    
    /// 类型
    public enum MusicCMDType {
        /// 开关 -> bool
        case ON
        /// 音源 -> int       0 aux1     1 fm      2 sd卡   3 aux2   4 蓝牙     其余未知
        case Source
        /// 音量 -> int
        case Volume
        /// 播放 -> bool      true 播放       false 暂停
        case Play
        /// 静音 -> bool
        case Mute
        /// 目录 -> string
        case Menu
        /// 歌曲 -> string    "nil"表示歌名无法解析
        case Song
        /// 歌曲列表 -> string       "nil"表示歌名无法解析
        case SongList
        /// 退出歌曲列表
        case SongListOut
    }
    
    public init() {
    }
    
    /// 返回类型，以及具体的值
    public var parserHandle: ((MusicCMDType, Any)->Void)?
    
    /// 解析cmd
    public func parserMusicCMD(cmd: String) {
        if cmd.substring(from: 4, length: 2) == "90" {
            BWSDKLog.shared.debug("该协议疑似声比可协议，放入声比可解析中")
            parseSBK(cmd: cmd)
        }
        if cmd.count < 10 {
            if cmd.isEmpty {
                BWSDKLog.shared.debug("背景音乐解析完毕")
            } else {
                BWSDKLog.shared.error("错误的背景音乐反馈指令:\(cmd)")
            }
            return
        }
        if let first = cmd.substring(from: 0, length: 2)?.lowercased() {
            switch first {
            case "b9":
                BWSDKLog.shared.debug("解析b9指令")
                B9Parser(cmd: getCurrentParserMSG(cmd: cmd))
            case "e9":
                BWSDKLog.shared.debug("解析e9指令")
                E9Parser(cmd: getCurrentParserMSG(cmd: cmd))
            case "f4":
                BWSDKLog.shared.debug("解析f4指令")
                F4Parser(cmd: getCurrentParserMSG(cmd: cmd))
            case "fb":
                BWSDKLog.shared.debug("解析fb指令")
                FBParser(cmd: getCurrentParserMSG(cmd: cmd))
            case "d6":
                BWSDKLog.shared.debug("解析d6指令")
                D6Parser(cmd: getCurrentParserMSG(cmd: cmd))
            case "fc":
                BWSDKLog.shared.debug("解析fc指令")
                FCParser(cmd: getCurrentParserMSG(cmd: cmd))
            case "f2":
                BWSDKLog.shared.debug("解析f2指令，专辑指令没用到，不用解析")
            case "f1":
                BWSDKLog.shared.debug("解析f1指令")
                F1Parser(cmd: getCurrentParserMSG(cmd: cmd))
            case "e5":
                BWSDKLog.shared.debug("退出选曲")
                parserHandle?(MusicCMDType.SongListOut, "nil")
            default:
                BWSDKLog.shared.debug("该指令不是优达协议指令，无法解析:\(getCurrentParserMSG(cmd: cmd))")
            }
            parserMusicCMD(cmd: getNextParserMSG(cmd: cmd))
        }
    }
    
    /// 解析声比可协议
    func parseSBK(cmd: String) {
        if let raw = cmd.substring(from: 6, length: 2)?.toIntValue()  {
            if raw >> 7 & 1 == 1 {
                BWSDKLog.shared.debug("声比可 -> 暂停")
                parserHandle?(MusicCMDType.Play, false)
            }
            if raw >> 6 & 1 == 1 {
                BWSDKLog.shared.debug("声比可 -> 播放")
                parserHandle?(MusicCMDType.Play, true)
            }
            if raw >> 5 & 1 == 1 {
                BWSDKLog.shared.debug("声比可 -> 静音")
                parserHandle?(MusicCMDType.Mute, true)
            } else {
                BWSDKLog.shared.debug("声比可 -> 未静音")
                parserHandle?(MusicCMDType.Mute, false)
            }
            let voice = raw & 31
            BWSDKLog.shared.debug("声比可 -> 音量\(voice)")
            parserHandle?(MusicCMDType.Volume, voice)
        }
        if let raw = cmd.substring(from: 8, length: 2)?.toIntValue() {
            if raw >> 7 & 1 == 1 {
                BWSDKLog.shared.debug("声比可 -> 开机")
                parserHandle?(MusicCMDType.ON, true)
            } else {
                BWSDKLog.shared.debug("声比可 -> 关机")
                parserHandle?(MusicCMDType.ON, false)
            }
        }
    }
    
    /// 获得当前待解析字符串
    func getCurrentParserMSG(cmd: String) -> String {
        if let first = cmd.substring(from: 0, length: 2)?.lowercased() {
            if first < "e0" {
                if let current = cmd.substring(from: 0, length: 10) {
                    BWSDKLog.shared.debug("解析当前指令:\(current)")
                    return current
                }
            } else {
                if let lenStr = cmd.substring(from: 4, length: 2) {
                    var len = lenStr.toIntValue()
                    if len < 5 {
                        len = 5
                    }
                    if let current = cmd.substring(from: 0, length: len*2) {
                        BWSDKLog.shared.debug("解析当前指令:\(current)")
                        return current
                    }
                }
            }
        }
        return ""
    }
    
    /// 获得剩余未解析字符串
    func getNextParserMSG(cmd: String) -> String {
        if let first = cmd.substring(from: 0, length: 2)?.lowercased() {
            if first < "e0" {
                if let sub = cmd.substring(from: 10, length: cmd.count-10) {
                    BWSDKLog.shared.debug("继续解析剩余指令:\(sub)")
                    return sub
                }
            } else {
                if let lenStr = cmd.substring(from: 4, length: 2) {
                    var len = lenStr.toIntValue()
                    if len < 5 {
                        len = 5
                    }
                    if let sub = cmd.substring(from: len*2, length: cmd.count-len*2) {
                        BWSDKLog.shared.debug("继续解析剩余指令:\(sub)")
                        return sub
                    }
                }
            }
        }
        return ""
    }
    
    /// 解析B9
    public func B9Parser(cmd: String) {
        if let third = cmd.substring(from: 4, length: 2) {
            switch third {
            case "03":
                BWSDKLog.shared.debug("B9解析:开")
                parserHandle?(MusicCMDType.ON, true)
            case "04":
                BWSDKLog.shared.debug("B9解析:关")
                parserHandle?(MusicCMDType.ON, false)
            case "05":
                if let typeStr = cmd.substring(from: 7, length: 1), let type = Int(typeStr) {
                    BWSDKLog.shared.debug("B9解析:音源\(type)")
                    parserHandle?(MusicCMDType.Source, type)
                }
            case "07":
                if let voiceStr = cmd.substring(from: 6, length: 2) {
                    let len = voiceStr.toIntValue()
                    let voice = len - 128
                    BWSDKLog.shared.debug("B9解析:音量\(voice)")
                    parserHandle?(MusicCMDType.Volume, voice)
                }
            default:
                BWSDKLog.shared.debug("B9无法解析:\(cmd)")
            }
        } else {
            BWSDKLog.shared.debug("B9解析长度不正确:\(cmd)")
        }
    }
    
    /// 解析E9
    public func E9Parser(cmd: String) {
        if let third = cmd.substring(from: 4, length: 2) {
            if third == "02" {
                if let typeStr = cmd.substring(from: 6, length: 2), let type = Int(typeStr) {
                    if type == 0 {
                        BWSDKLog.shared.debug("E9解析:播放")
                        parserHandle?(MusicCMDType.Play, true)
                    } else if type == 1 {
                        BWSDKLog.shared.debug("E9解析:暂停")
                        parserHandle?(MusicCMDType.Play, false)
                    }
                }
            } else if third == "04" {
                if let typeStr = cmd.substring(from: 6, length: 2), let type = Int(typeStr) {
                    if type == 0 {
                        BWSDKLog.shared.debug("E9解析:未静音")
                        parserHandle?(MusicCMDType.Mute, false)
                    } else if type == 1 {
                        BWSDKLog.shared.debug("E9解析:静音")
                        parserHandle?(MusicCMDType.Mute, true)
                    }
                }
            } else {
                BWSDKLog.shared.debug("E9无法解析:\(cmd)")
            }
        } else {
            BWSDKLog.shared.debug("E9解析长度不正确:\(cmd)")
        }
    }
    
    /// 解析F4
    public func F4Parser(cmd: String) {
        if cmd.count >= 12 {
            if let dataStr = cmd.substring(from: 10, length: cmd.count - 12) {
                let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
                if let menu = String(data: dataStr.hexStrToData(), encoding: String.Encoding(rawValue: enc)) {
                    BWSDKLog.shared.debug("F4解析:目录->\(menu)")
                    parserHandle?(MusicCMDType.Menu, menu)
                }
            }
        } else {
            BWSDKLog.shared.debug("F4解析长度不正确:\(cmd)")
        }
    }
    
    /// 解析FB
    public func FBParser(cmd: String) {
        if cmd.count >= 12 {
            if let lenStr = cmd.substring(from: 4, length: 2) {
                let len = lenStr.toIntValue()
                if let dataStr = cmd.substring(from: 10, length: len*2-12) {
                    let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
                    for index in [0, 1, 2, 3, 4] {
                        if let songStr = dataStr.substring(from: 0, length: dataStr.count - index) {
                            if let song = String(data: songStr.hexStrToData(), encoding: String.Encoding(rawValue: enc)) {
                                BWSDKLog.shared.debug("FB解析:歌名->\(song)")
                                parserHandle?(MusicCMDType.SongList, song)
                                return
                            }
                        }
                    }
                    BWSDKLog.shared.debug("FB解析歌名无法解析:\(cmd)")
                    parserHandle?(MusicCMDType.Song, "nil")
                }
            }
        } else {
            BWSDKLog.shared.debug("FB解析长度不正确:\(cmd)")
            parserHandle?(MusicCMDType.SongList, "nil")
        }
    }
    
    /// 解析D6
    public func D6Parser(cmd: String) {
        if let third = cmd.substring(from: 4, length: 2) {
            if third == "02" {
                BWSDKLog.shared.debug("D6解析:正常播放")
            } else if third == "00" {
                BWSDKLog.shared.debug("D6解析:设备拔出")
            }
        } else {
            BWSDKLog.shared.debug("D6解析长度不正确:\(cmd)")
        }
    }
    
    /// 解析FC
    public func FCParser(cmd: String) {
        if let statusStr = cmd.substring(from: 6, length: 2) {
            let status = statusStr.toIntValue()
            if (status & 0b1000000) >> 6 == 1 {
                BWSDKLog.shared.debug("FC解析:开")
                parserHandle?(MusicCMDType.ON, true)
            } else {
                BWSDKLog.shared.debug("FC解析:关")
                parserHandle?(MusicCMDType.ON, false)
            }
            if (status & 0b100000) >> 5 == 1 {
                BWSDKLog.shared.debug("FC解析:播放")
                parserHandle?(MusicCMDType.Play, true)
            } else {
                BWSDKLog.shared.debug("FC解析:暂停")
                parserHandle?(MusicCMDType.Play, false)
            }
            if (status & 0b10000) >> 4 == 1 {
                BWSDKLog.shared.debug("FC解析:静音")
                parserHandle?(MusicCMDType.Mute, true)
            } else {
                BWSDKLog.shared.debug("FC解析:非静音")
                parserHandle?(MusicCMDType.Mute, false)
            }
            if (status & 0b1000) >> 3 == 1 {
                BWSDKLog.shared.debug("FC解析:单曲循环")
            } else if (status & 0b100) >> 2 == 1 {
                BWSDKLog.shared.debug("FC解析:专辑内循环")
            } else {
                BWSDKLog.shared.debug("FC解析:全循环")
            }
            if (status & 0b10) >> 1 == 1 {
                BWSDKLog.shared.debug("FC解析:随机播放")
            } else {
                BWSDKLog.shared.debug("FC解析:顺序播放")
            }
        }
        if let voiceStr = cmd.substring(from: 8, length: 2) {
            let voice = voiceStr.toIntValue()
            BWSDKLog.shared.debug("FC解析:音量\(voice)")
            parserHandle?(MusicCMDType.Volume, voice)
        }
        if let sourceStr = cmd.substring(from: 14, length: 2), let source = Int(sourceStr) {
            BWSDKLog.shared.debug("FC解析:音源\(source)")
            parserHandle?(MusicCMDType.Source, source)
        }
    }
    
    /// 解析F1
    public func F1Parser(cmd: String) {
        if cmd.count >= 10 {
            if let third = cmd.substring(from: 4, length: 2) {
                if third == "00" {
                    BWSDKLog.shared.debug("F1解析:操作失败->\(cmd)")
                } else {
                    let len = third.toIntValue()
                    if let nameCMD = cmd.substring(from: 0, length: len * 2) {
                        parserMusicName(cmd: nameCMD)
                    }
                }
            }
        } else {
            BWSDKLog.shared.debug("F1解析长度不正确")
            parserHandle?(MusicCMDType.Song, "nil")
        }
    }
    
    /// 解析歌曲名
    func parserMusicName(cmd: String) {
        if let name = cmd.substring(from: 8, length: cmd.count - 10) {
            let enc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
            for index in [0, 1, 2, 3, 4] {
                if let songStr = name.substring(from: 0, length: name.count - index) {
                    if let song = String(data: songStr.hexStrToData(), encoding: String.Encoding(rawValue: enc)) {
                        BWSDKLog.shared.debug("F1解析:歌名->\(song)")
                        parserHandle?(MusicCMDType.Song, song)
                        return
                    }
                }
            }
            BWSDKLog.shared.debug("F1解析歌名无法解析:\(cmd)")
            parserHandle?(MusicCMDType.Song, "nil")
        }
    }
}
