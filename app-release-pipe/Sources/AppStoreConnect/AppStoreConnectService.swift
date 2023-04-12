//
// Created by matt on 2022/7/7.
//

import Foundation
import AsyncHTTPClient
import NIOHTTP1
import NIOCore
import JWT
import JWTKit

let rootURL = "https://api.appstoreconnect.apple.com"

/// JWT负载
struct Payload: JWTPayload {
    // App Store Connect 中 API Keys 页面的发行者
    var iss: String
    // 令牌的创建时间
    var iat: Int64
    // 令牌过期时间
    var exp: Int64
    // aud- 观众
    var aud: String = "appstoreconnect-v1"
    // scope- 令牌范围(App Store Connect 允许此令牌的操作列表)
    var scope: [String]
    
    func verify(using signer: JWTSigner) throws {
        //            try self.expiration.verifyNotExpired()
    }
}

enum AppStoreConnectApi {
    case list
    case appInfo(id: String)
    case apppsReviewSubmissions(id: String)
    case reviewSubmissions(appIds: String)
    case reviewSubmissionsById(id: String)
    case reviewSubmissionsAllItemsById(id: String)
    case allAppstoreVersionForApp(id: String)
    case appstoreVersionInfoById(id: String)
    case allPreReleaseVersionForApp(id: String)
    case preReleaseVersionById(id: String)
    case buildForAppStoreVersion(id: String)
}

extension AppStoreConnectApi {
    var path: String {
        switch self {
        case .list:
            return  "/v1/apps" // 列出所有应用
        case .appInfo(let id):
            return  "/v1/apps/\(id)/appInfos" // 获取应用信息
        case .apppsReviewSubmissions(id: let id):
            return  "/v1/apps/\(id)/reviewSubmissions" // 获取应用审核提交
        case .reviewSubmissions(appIds: let appIds):
            return "/v1/reviewSubmissions?filter[app]=[\(appIds)]" // 获取应用审核提交
        case .reviewSubmissionsById(id: let id):
            return  "/v1/reviewSubmissions/\(id)" // 获取应用审核提交
        case .reviewSubmissionsAllItemsById(let id):
            return "/v1/reviewSubmissions/\(id)/items" // 获取应用审核提交的所有信息
        case .allAppstoreVersionForApp(let id):
            return "/v1/apps/\(id)/appStoreVersions" // 获取应用所有上架版本
        case .appstoreVersionInfoById(let id):
            return  "/v1/appStoreVersions/\(id)" // 获取应用上架版本信息
        case .allPreReleaseVersionForApp(let id):
            return "/v1/apps/\(id)/relationships/preReleaseVersions" // 获取应用所有预发布版本
        case .preReleaseVersionById(let id):
            return  "/v1/preReleaseVersions/\(id)" // 获取应用预发布版本信息
        case .buildForAppStoreVersion(let id):
            return "/v1/appStoreVersions/\(id)/build" // 获取应用上架版本的构建信息
        }
    }
    
    
    var token: String? {
        guard let key = try? ECDSAKey.private(pem: Config.privatePem) else {
            logger.info("create  pem key failed")
            return nil
        }
        logger.info("\(key)")
        let signer = JWTSigner.es256(key: key)
        let now = Int64(Date().timeIntervalSince1970)
        let expire = now + 60
        let p = Payload(iss: Config.issueId,
                        iat: now,
                        exp: expire,
                        scope: [
                            "GET \(path)"
                        ])
        return try? signer.sign(p, typ: "JWT", kid: JWKIdentifier(string: Config.kid),
                                cty: nil)
    }
}

/// 请求目标
struct RequestTarget {
    /// api服务
    var api: AppStoreConnectApi
    /// 头部参数
    var headers: [String: String]
    /// 参数体
    var body: [String: String]
    var method: HTTPMethod
    var token: String
    var request: HTTPClientRequest {
        var req =  HTTPClientRequest(url: rootURL.appending(api.path))
        var headerFeild = headers.map { key, value -> (String, String) in  (key, value) }
        headerFeild.append(("Authorization", " Bearer \(token)"))
        var str = ""
        for it in body {
            str.append("\"\(it.key)\":\"\(it.value)\",")
        }
        str = str.trimmingCharacters(in: CharacterSet(charactersIn:","))
        
        req.body =  .bytes(ByteBuffer(string: str))
        req.headers = HTTPHeaders(headerFeild)
        return  req
    }
}
