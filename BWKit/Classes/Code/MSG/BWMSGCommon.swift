//
//  BWMSGCommon.swift
//  BWKit
//
//  Created by yuhua on 2020/3/3.
//  Copyright © 2020 bw. All rights reserved.
//

import Foundation

/// 设备类型
public enum ProductType: String {
    /// --照明
    /// 普通灯
    case OnOffLight = "On/Off Light"
    /// 可调灯
    case DimmableLight = "Dimmable Light"
    /// 终端控制器
    case CombinedInterface = "Combined Interface"
    /// 大功率模块
    case OnOffOutput = "On/Off Output"
    /// --遮阳
    /// 窗帘
    case WindowCoveringDevice = "Window Covering Device"
    /// 窗帘遥控器
    case WindowCoveringController = "Window Covering Controller"
    /// --家电
    /// 电源控制器
    case MainsPowerOutlet = "Mains Power Outlet"
    /// 空调控制器
    case AirCondition = "Air Condition"
    /// 空调网关
    case ACGateway = "AC gateway"
    /// 红外转发器
    case IR = "IR"
    /// --安防
    /// 安防传感器
    case IasZone = "IAS Zone"
    /// 报警设备
    case WarningDevice = "Warning Device"
    /// --环境
    /// 空气盒子
    case AirBox = "Air Box"
    /// 空气质量传感器
    case AirQualitySensor = "Air Quality Sensor"
    /// 甲醛探测传感器
    case HCHOSensor = "HCHO Sensor"
    /// 光照度传感器
    case LightSensor = "Light Sensor"
    /// 温度传感器
    case TemperatureSensor = "Temperature Sensor"
    /// 温湿度传感器
    case TemperatureHumiditySensor = "Temperature Humidity Sensor"
    /// --接口
    /// 协议转换器
    case DataTransport = "Data Transport"
    /// DI
    case ZigbeeIO_I = "Zigbee IO_I"
    /// DO
    case ZigbeeIO_O = "Zigbee IO_O"
    /// --集中控制
    /// 场景
    case SceneSelector = "Scene Selector"
    /// zigbee遥控器
    case RemoteController = "Remote Controller"
    /// --门锁
    /// 门锁
    case DoorLock = "Door Lock"
    /// --暖通
    /// 温控器
    case Thermostat = "Thermostat"
    /// 地暖
    case FloorHeatController = "Floor heat controller"
    /// 新风
    case NewWindController = "New wind controller"
    /// --背景音乐
    /// 背景音乐
    case BackgroundMusic = "Background Music"
    /// 向往背景音乐
    case XWBackgroundMusic = "Xiangwang Background Music"
    /// 华尔思背景音乐
    case HESBackgroundMusic = "Huaers Background Music"
    /// --风扇
    /// 风扇
    case Fan = "Fan"
    /// --门窗
    /// 门窗
    case WindowLock = "Window Lock"
    
    /// --未知分类
    case OnOffSwitch = "On/Off Switch"
    
    /// 未知类型
    case Unknown = "unknown"
    
    /// 摄像机
    case Camera = "BW Camera"
    
    /// 猫眼
    case Cateye = "BW Cateye"
}

/// 设备属性
public enum DeviceAttr: String {
    /// --照明
    /// 普通灯
    case OnOffLight = "Light"
    /// 可调灯
    case DimmableLight = "DimmableL"
    /// 灯光遥控器
    case OnOffSwitch = "OnOffSwitch"
    
    /// --遮阳
    /// 升降窗帘
    case LiftCurtain = "LiftC"
    /// 开合窗帘
    case SwitchCurtain = "SwitchC"
    /// 窗帘遥控器
    case WindowCoverController = "WindowCoverController"
    
    /// 摄像机
    case Camera = "BW Camera"
    
    /// 猫眼
    case Cateye = "BW Cateye"
    
    /// --家电
    /// 电源
    case PowerSupply = "Power"
    /// dvd
    case DVD = "DVD"
    /// 机顶盒
    case Tvbox = "TVBox"
    /// 电视
    case Television = "Television"
    /// 投影仪
    case Projector = "pj"
    /// 中央空调
    case CentralAirCondition = "CentralAC"
    /// 单体空调
    case UnitAirCondition = "UnitAC"
    /// 温控器
    case Thermostat = "Thermostat"
    /// 背景音乐
    case BackgroundMusic = "BMusic"
    /// 地暖
    case FloorHeating = "FloorHeating"
    /// 新风
    case NewWindController = "NewWindController"
    /// 空调控制器
    case AirCondition = "AirContidion"
    /// 向往背景音乐
    case XiangwangBackgroundMusic = "XwBMusic"
    /// 华尔思背景音乐
    case HuaErSiBMusic = "HuaErSiBMusic"
    /// 空调网关
    case ACGatewayFather = "AC gateway"
    case ACGatewaySub = "ACGateway"
    
    /// --安防
    /// 幕帘探测器
    case MotionSensor = "CurtainS"
    /// 可燃气体探测器
    case GasSensor = "GasS"
    /// 烟雾探测器
    case FireSensor = "SmokeS"
    /// 浸水探测器
    case WaterSensor = "ImmersionS"
    /// 门窗磁探测器
    case ContactSensor = "ContactS"
    /// 室外周界探测器
    case BoundarySensor = "BoundaryS"
    /// 紧急按钮
    case DangerButton = "DangerBtn"
    /// 声报警器
    case SoundAlarm = "SoundA"
    /// 光报警器
    case LightAlarm = "LightA"
    /// 声光报警器
    case SoundAndLightAlarm = "SoundLightA"
    
    /// --环境监测
    /// 空气质量传感器
    case Pm25Sensor = "PM25S"
    /// 温湿度传感器
    case HumitureSensor = "HumitureS"
    /// 风雨传感器
    case WindRainSensor = "WindRainS"
    /// 光照度传感器
    case IlluminanceSensor = "IlluminanceS"
    /// 空气盒子
    case AirBox = "AirBox"
    
    /// 场景控制器
    case SceneController = "Scene"
    /// 智能门锁
    case DoorLock = "DoorLock"
    /// 红外
    case IR = "IR"
    /// 数据透传
    case DataTransport = "Data Transport"
    /// 自定义设备
    case CustomDevice = "CustomDev"
    /// 门
    case Door = "Door"
    /// 窗
    case Window = "Window"
    
    /// DI
    case ZigbeeIO_I = "Zigbee IO_I"
    /// DO
    case ZigbeeIO_O = "Zigbee IO_O"
    
    /// --视频对讲
    /// 视频对讲
    case VideoIntercom = "Video Intercom"
}

struct MSGString {
    
    //server
    static let AppCommon = "app_common"
    static let AppHeartbeat = "app_heartbeat"
    
    static let AppAuth = "app_auth"
    static let UserReg = "user_reg"
    static let UserRegWithCode = "user_reg_with_code"
    static let UserLogin = "user_login"//both
    static let SMSLogin = "sms_login"
    static let TokenLogin = "token_login"
    static let UserChangePWD = "user_change_pwd"
    static let UserRegcheck = "user_regcheck"
    static let SMSCode = "smscode"
    static let SendSMSCode = "send_sms_code"
    static let ResetPWD = "reset_pwd"
    static let JPushRegidUpload = "jpush_regid_upload"
    static let BJLogin = "sz_tiannengxiang_login"
    
    static let ThirdAuth = "third_auth"
    static let ThirdAuthLogin = "third_auth_login"
    static let ThirdAuthBind = "third_auth_bind"
    
    static let GWAppMgmt = "gwapp_mgmt"
    static let GWAppQueryToken = "gwapp_query_token"
    static let GWAppBind = "gwapp_bind"
    static let GWAppEdit = "gwapp_edit"
    static let GWAppUnbind = "gwapp_unbind"
    
    static let GWUserMgmt = "gwuser_mgmt"
    static let GWUserList = "gw_userlist"
    static let GWUserAdd = "gw_user_add"
    static let GWDeviceUserAdd = "gw_device_user_add"
    static let GWUserDel = "gw_user_del"
    static let GWUserEdit = "gw_user_edit"
    static let GWSetAdmin = "gw_set2admin"
    static let GWUserQuit = "gw_user_quit"
    static let GWApplyJoin = "gw_apply_join"
    static let GWAdminApply = "gw_admin_apply"
    
    static let CAMMgmt = "camera_mgmt"
    static let CAMAdd = "camera_add"
    static let CAMQuery = "camera_list"
    static let CAMEdit = "camera_edit"
    static let CAMDel = "camera_del"
    
    static let QuickMgmt = "appshortcut_mgmt"
    static let SetQuick = "appshortcut_set"
    static let QueryQuick = "appshortcut_query"
    
    //gateway
    static let UserMgmt = "user_mgmt"
    static let TimeSync = "time_sync"
    static let UserPermissionGet = "user_permission_get"
    static let UserPermissionSet = "user_permission_set"
    static let UserWifiPermissionSet = "user_wifi_permission_set"
    static let UserWifiPermissionGet = "user_wifi_permission_get"
    static let UserQuery = "user_query"
    static let ForceLogout = "force_logout"//both
    
    static let VersionMgmt = "version_mgmt"
    static let CFGVerQuery = "cfg_ver_query"
    static let HardVerQuery = "hard_ver_query"
    static let RequestGWUpdate = "request_gw_update"
    static let RequestHubUpdate = "request_hub_update"
    static let RequestDeviceUpdate = "request_device_update"
    static let QueryDeviceUpdateState = "query_device_update_state"
    static let CancelDeviceUpdate = "cancel_device_update"
    
    static let DeviceMgmt = "device_mgmt"
    static let DeviceQuery = "device_query"
    static let DeviceAdd = "device_add"
    static let DeviceDel = "device_del"
    static let DeviceEdit = "device_edit"
    static let DeviceCMDQuery = "device_cmd_query"
    static let DeviceReport = "device_report"
    static let BaudQuery = "baud_query"
    static let BaudSet = "baud_set"
    static let DevInfoReport = "dev_info_report"
    static let WorkModeConfig = "workmode_config"
    static let WorkModeGet = "workmode_get"
    static let DLIdAdd = "DL_id_add"
    static let DLIdQuery = "DL_id_query"
    static let DLIdEdit = "DL_id_edit"
    static let DLIdDel = "DL_id_del"
    static let UndefDLId = "undef_DL_id"
    static let DLIdSync = "DL_id_sync"
    static let DiscoveryTCPDevice = "Discovery_tcp_device"
    static let ConnectTCPDevice = "connect_tcp_device"
    static let BindTCPDevice = "bind_tcp_device"
    static let DeviceBind = "device_bind"
    static let DeviceBindQuery = "device_bind_query"
    static let DeviceRSSIReport = "device_rssi_report"
    static let DeviceRSSIQuery = "device_rssi_query"
    
    static let SceneMgmt = "scene_mgmt"
    static let SceneQuery = "scene_query"
    static let SceneAdd = "scene_add"
    static let SceneDel = "scene_del"
    static let SceneEdit = "scene_edit"
    static let SceneExe = "scene_exe"
    static let SceneDevAddReport = "scene_dev_add_report"
    
    static let TimerMgmt = "timer_mgmt"
    static let TimerQuery = "timer_query"
    static let TimerAdd = "timer_add"
    static let TimerDel = "timer_del"
    static let TimerEdit = "timer_edit"
    
    static let LinkageMgmt = "linkage_mgmt"
    static let LinkageQuery = "linkage_query"
    static let LinkageAdd = "linkage_add"
    static let LinkageDel = "linkage_del"
    static let LinkageEdit = "linkage_edit"
    
    static let RoomMgmt = "room_mgmt"
    static let RoomQuery = "room_query"
    static let RoomAdd = "room_add"
    static let RoomDel = "room_del"
    static let RoomEdit = "room_edit"
    
    static let ZoneMgmt = "zone_mgmt"
    static let ZoneQuery = "zone_query"
    static let ZoneAdd = "zone_add"
    static let ZoneDel = "zone_del"
    static let ZoneEdit = "zone_edit"
    static let ZoneSwitch = "zone_switch"
    
    static let ControlMgmt = "control_mgmt"
    static let DeviceStateGet = "device_state_get"
    static let DeviceControl = "device_control"
    static let IRLearn = "ir_learn"
    static let IRLearnReport = "ir_learn_report"
    static let DeviceStateReport = "device_state_report"
    static let Identify = "identify"
    static let VoiceControl = "voice_control"
    static let DoorlockRequestOpen = "doorlock_request_open"
    
    static let GatewayMgmt = "gateway_mgmt"
    static let GatewayDiscover = "gateway_discovery"
    static let ZBNetOpen = "zb_net_open"
    static let GWAliasSet = "gw_alias_set"
    static let SetLanguage = "set_language"
    static let BuildNetwork = "build_zigbee_network"
    static let NetworkGet = "network_get"
    static let NetworkSet = "network_set"
    
    static let MsgMgmt = "msg_mgmt"
    static let MsgReport = "msg_report"
    static let MsgQuery = "msg_query"
    static let ReadMsgidSet = "read_msgid_set"
    static let UnreadNumGet = "unread_num_get"
    static let EquesMsgPush = "eques_msg_push"
    static let MSGPushGetConfig = "msgpush_getconfig"//server
    static let MSGPushSetConfig = "msgpush_setconfig"//server
    static let MSGPushGetSMSBalance = "msgpush_getsmsbalance"//server
    static let GetEmail = "get_email"//server
    static let SetEmail = "set_mail"//server
    
    static let PowerMgmt = "power_mgmt"
    static let PowerRecordQuery = "power_record_query"
    
    static let GWCommon = "gw_common"
    static let GWHeartbeat = "gw_heartbeat"
}
