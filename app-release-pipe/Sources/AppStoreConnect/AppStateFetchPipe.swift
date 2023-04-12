//
// Created by matt on 2022/7/7.
//

import Foundation
import JWT
import JWTKit
import Logging
import AsyncHTTPClient
import NIOHTTP1

public class AppStateFetchPipe {

    let client =  HTTPClient(eventLoopGroupProvider: .createNew)

    public init() {}

    deinit  {
        try? client.syncShutdown()
    }

    func work() async {

        await fetchAppList()
    }
}

// http service api
extension AppStateFetchPipe {
    /// 获取app列表
    /// - Returns: app列表
    public func getAppList() async -> AppListForVaporResp {
        let api = AppStoreConnectApi.list
        if let model = await fetchApi(api, modelType: RespData<[AppListItem]>.self) {
            return AppListForVaporResp(apps: model.data, count: model.data.count)
        }
        return AppListForVaporResp(apps: [], count: 0)
    }

    /// 获取app版本信息
    /// - Parameter id: app id
    /// - Returns: app版本信息
    public func getAppVersionInfo(id: String) async -> AppItemForVapor? {
        
        if let version = await fetchApi(.allAppstoreVersionForApp(id: id), modelType: RespData<[VersionItemModel]>.self) {
            if let latestVersion = version.data.first {
                var res = AppItemForVapor(appId: id, name: "")
                let state = AppState(rawValue: latestVersion.attributes
                        .appStoreState)
                res.versionState = state?.desc
                res.versionStateRaw = state?.rawValue
                res.version = latestVersion.attributes.versionString

                if let build = await fetchApi(.buildForAppStoreVersion(id: latestVersion.id), modelType: RespData<BuildInfoModel>.self) {
                    logger.notice("--- \(build)")
                    res.build = build.data.attributes
                }
                return res
            }
        }
        return nil
    }

    /// 确认发布app
    /// - Parameter id: app id
    /// - Returns: 是否发布成功
    public func confirmReleaseApp(id: String) async -> Bool {
        return true
    }
}


/// 定时器获取逻辑
extension AppStateFetchPipe {
    //获取app列表数据
    fileprivate func fetchAppList() async {
        let api = AppStoreConnectApi.list

        if let model = await fetchApi(api, modelType: RespData<[AppListItem]>.self) {
            logger.info("\(model)")

            let appList = model.data.filter({
                return Config.keyAppIds.contains($0.id)
            })

            logger.notice("\(appList)")

            for it in appList {
                Task {

                    if let version = await fetchApi(.allAppstoreVersionForApp(id: it
                            .id), modelType: RespData<[VersionItemModel]>.self) {
                        if let latestVersion = version.data.first {
                            if let state = AppState(rawValue: latestVersion.attributes
                                    .appStoreState) {
                                let tup = AppStateCache.default.updateIfDiff(key: latestVersion.id,
                                        value: state)
                                if tup.0 {
                                    let feishu = FeishuBot()
                                    await feishu.sendAppState(name: it.attributes.name,
                                                              version: latestVersion.attributes.versionString,
                                                              state: state.desc)
                                }
                            }
                        }
                        AppStateCache.default.listAll()
                    }
                }
            }
        }
    }

}

extension AppStateFetchPipe {

    fileprivate func fetchItunesState(id: String) async -> String? {

        struct ItunesResp: Codable {
            struct Item: Codable {
                var version: String
                var releaseNotes: String
                var trackName: String
                var kind: String
            }

            var results: [Item]
        }

        var req =  HTTPClientRequest(url: "https://itunes.apple.com/cn/lookup?id=\(id)")
        req.headers = HTTPHeaders([("Content-Type", "application/json")])
        do {
            let resp = try await client.execute(req, timeout: .seconds(10))
            if resp.status == .ok {
                let body = try await resp.body.collect(upTo: 1024*1024)
                let model = try  JSONDecoder().decode(ItunesResp.self, from: body)
                let version = model.results.first { (v: ItunesResp.Item) in  v.kind == "software"
                        }?.version
                return version
            } else {
                logger.info("\(resp.status.code)")
            }
        } catch {
            logger.error("\(error)")
        }
        return  nil
    }

    //MARK: -- 获取接口数据
    fileprivate func fetchApi<T: Codable>(_ api: AppStoreConnectApi,
                                          modelType: T.Type,
                                          headers: [String: String] = [:],
                                          body: [String: String] = [:]) async -> T? {
        guard let token = api.token else {
            logger.error("token is nil")
            return nil
        }
        let req = RequestTarget(api: api,
                headers: [:],
                body: [:],
                method: .GET,
                token: token)
                .request

        do {
            let resp = try await client.execute(req, timeout: .seconds(10))
            if resp.status == .ok {
                let body = try await resp.body.collect(upTo: 1024*1024)
                let model = try  JSONDecoder().decode(T.self, from: body)
                return model
            } else {
                logger.info("\(resp.status.code)")
            }
        } catch {
            logger.error("\(error)")
        }

        return nil
    }
}
