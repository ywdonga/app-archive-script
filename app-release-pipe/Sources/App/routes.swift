import Vapor
import AppStoreConnect

func routes(_ app: Application) throws {
    
    app.get(["appstoreManager", "api", "appList"]) {
        req -> AppListForVaporResp in
        return await AppStateFetchPipe().getAppList()
    }

    app.get(["appstoreManager", "api", "appVersion"]) {
        req -> AppItemForVapor in
        // 获取请求参数中的id
        guard let id: String = req.query["id"] else {
            throw Abort.init(.badRequest)
        }
        
        // 获取指定id的app版本信息
        guard let res = await AppStateFetchPipe().getAppVersionInfo(id: id) else {
            throw Abort.init(.badRequest)
        }
        return res
    }

    app.post(["appstoreManager", "api", "release"]) {
        req -> Bool in
        // Logger(label: "000 ").notice("\(req.body.string) - \(req.peerAddress?.ipAddress)")
        
        // 检查请求体中是否存在id
        guard let id: String = req.body.string else {
            throw Abort.init(.badRequest)
        }
        // 确认发布具有给定id的应用程序
        let res = await AppStateFetchPipe().confirmReleaseApp(id: id)
        return res
    }

}