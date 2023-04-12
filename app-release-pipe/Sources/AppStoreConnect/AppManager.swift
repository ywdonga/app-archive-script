//
// Created by matt on 2022/7/7.
//

import Dispatch
import Logging
import AsyncHTTPClient


let logger = Logger(label: "000 ")

// 应用管理器
public final class AppManager {

    public static let shared = AppManager()

    private(set) var timer: DispatchSourceTimer?

    private(set) var isTest: Bool = false

    // 是否正在运行
    public var isRuning: Bool {
        timer != nil
    }

    // 运行应用
    public func run(isTest: Bool) {
        logger.notice("===== 是否是生产环境 \(!isTest) =======")
        self.isTest = isTest
        if isRuning {
            logger.notice("正在运行")
            return
        }

        logger.notice("开始计时器")
        timer = DispatchSource.makeTimerSource()
        timer?.schedule(deadline: .now() + .seconds(1), repeating: .seconds(Config.requestInterval))
        timer?.setEventHandler {
            Task {
                let pipe = AppStateFetchPipe()
                await pipe.work()
            }
        }
        timer?.activate()
    }
}