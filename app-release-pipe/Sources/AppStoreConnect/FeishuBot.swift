//
// Created by matt on 2022/7/8.
//

import Foundation
import AsyncHTTPClient
import NIOHTTP1
import NIOCore

public class FeishuBot {
    
    /// 发送失败时重试次数
    private(set) var retryCount: UInt = 2
    
    init(retry: UInt = 2) {
        self.retryCount = retry
    }
    
    /// 发送应用状态到飞书机器人
    ///
    /// - Parameters:
    ///   - name: 应用名称
    ///   - version: 应用版本
    ///   - state: 应用状态
    public func sendAppState(name: String, version: String, state: String) async {
        let text = "iOS: \(name) \(version) \(state)"
        logger.notice("发送消息： \"iOS: \(name) \(version) \(state)\" 到 \(Config.feishuBotHook)")
        await send(text: text)
    }
    
    /// 发送文本消息到飞书机器人
    ///
    /// - Parameter text: 消息文本
    public func send(text: String) async {
        let res = await pSend(text: text)
        if !res && self.retryCount > 0 {
            self.retryCount -= 1
            await send(text: text)
        }
    }
    
    private func pSend(text: String) async -> Bool {
        let client = HTTPClient(eventLoopGroupProvider: .createNew)
        var req = HTTPClientRequest(url: Config.feishuBotHook)
        req.headers = HTTPHeaders([("Content-Type", "application/json")])
        req.method = .POST
        let dict: [String: Any] = [
            "msg_type": "text",
            "content": [
                "text": text
            ],
        ]
        
        var res = false
        
        if let data = try? JSONSerialization.data(withJSONObject: dict) {
            req.body = .bytes(ByteBuffer(data: data))
            do {
                logger.info("--- request ------")
                let resp = try await client.execute(req, timeout: .seconds(20))
                if resp.status == .ok {
                    let body = try await resp.body.collect(upTo: 1024*1024)
                    logger.info(" \(body)")
                    res = true
                } else {
                    logger.info("\(resp.status.code)")
                }
            } catch {
                logger.error("\(error)")
            }
        }
        try? await client.shutdown()
        return res
    }
}
