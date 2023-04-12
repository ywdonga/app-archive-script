//
// Created by matt on 2022/7/11.
//

import Foundation

class AppStateCache {
    // 状态缓存
    private var dict: [String: AppState] = [:]

    // 单例
    static let `default` = AppStateCache()

    private init() {}

    // 更新缓存
    // 如果存在不一致，则返回true
    func updateIfDiff(key: String, value: AppState) -> (Bool, Bool) {
        let old = dict[key]
        if old != value {
            if value == .readyForSale {
                dict.removeValue(forKey: key)
            } else {
                dict[key] = value
            }

            if old != nil {
                return value.isNeedSendMessage
            }
        }
        return (false, false)
    }

    // 列出所有缓存
    func listAll() {
        var desc: String = ""
        for it in dict {
            desc.append("\(it.key): \(it.value.rawValue), \(it.value.desc) \n")
        }
        logger.notice("======= 当前缓存记录 \n  \(desc) \n=======")
    }
}
