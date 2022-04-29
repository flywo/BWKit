//
//  ViewController.swift
//  BWKit
//
//  Created by YuHua on 04/29/2022.
//  Copyright (c) 2022 YuHua. All rights reserved.
//

import UIKit
import BWKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        BWAppManager.shared.connectServer(success: {
            BWSDKLog.shared.info("连接服务器成功")
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

