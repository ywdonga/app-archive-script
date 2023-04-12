import Vapor

public protocol Dao: Codable, AsyncResponseEncodable { }

extension Dao {
    public func encodeResponse(for request: Request) async throws -> Response {
    var headers = HTTPHeaders()
    headers.add(name: .contentType, value: "application/json;charset=utf-8")
    headers.add(name: "Access-Control-Allow-Origin", value: "*")
    headers.add(name: "Access-Control-Allow-method", value: "POST")
    let data = try? JSONEncoder().encode(self)
    return .init(status: .ok, headers: headers, body: .init(data: data ?? Data()))
  }
}

/// app列表响应对象
public struct  AppListForVaporResp: Dao {
    public var apps: [AppListItem]
    public var count: Int
}


public struct AppItemForVapor: Dao {
    public var appId: String
    public var name: String
    public var versionState: String?
    public var versionStateRaw: String?
    public var version: String?
    public var versionDesc: String?
    public var build: BuildInfoModel.Attribute?
}