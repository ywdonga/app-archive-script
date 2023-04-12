
import JWT
import JWTKit
import Logging

struct ActionError: Error {
    var code = "E10000"
    var message: String
}


public struct LinksItem: Codable {
    struct Inner: Codable {
        var `self`: String
        var related: String
    }
    var links: Inner
}

//MARK: - Appl列表模型 -
public struct AppAttribute: Codable {
    var name: String
    var bundleId: String
}

public struct AppRelationShip: Codable {
    var appStoreVersions: LinksItem
    var preReleaseVersions: LinksItem
}

public struct AppListItem: Codable {
    var id: String

    var attributes: AppAttribute

    var relationships: AppRelationShip
}

//MARK: 版本相关
public struct VersionItemModel: Codable {
    var type: String
    var id: String
    struct Attribute: Codable {
        var versionString: String
        var appStoreState: String
    }

    var attributes: Attribute

}

public struct BuildInfoModel: Codable {
    public struct Attribute: Codable {
        var version: String
        var minOsVersion: String
    }
    
    var attributes: Attribute
}

struct VersionInfoModel: Codable {

    struct Attribute: Codable {
        var versionString: String
        var appStoreState: String
    }

    var attributes: Attribute
}

//MARK: - common -
struct RespData<T:Codable>: Codable {
    var data: T
}

struct Empty: Codable {}



/// AppState
enum AppState: String {

    case developerRemovedFromSale = "DEVELOPER_REMOVED_FROM_SALE"

    case developerRejected = "DEVELOPER_REJECTED"

    case inReview = "IN_REVIEW"

    case invalidBinary = "INVALID_BINARY"

    case metadataRejected = "METADATA_REJECTED"

    case pendingAppleRelease = "PENDING_APPLE_RELEASE"

    case pendingContract = "PENDING_CONTRACT"

    case pendingDeveloperRelease = "PENDING_DEVELOPER_RELEASE"

    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"

    case preorderReadyForSale = "PREORDER_READY_FOR_SALE"

    case processingForAppStore = "PROCESSING_FOR_APP_STORE"

    case readyForSale = "READY_FOR_SALE"

    case rejected = "REJECTED"

    case removedFromSale = "REMOVED_FROM_SALE"

    case waitingForExportCompliance = "WAITING_FOR_EXPORT_COMPLIANCE"

    case waitingForReview = "WAITING_FOR_REVIEW"

    case replacedWithNewVersion = "REPLACED_WITH_NEW_VERSION"

    case accepted = "ACCEPTED"

    case readyForReview = "READY_FOR_REVIEW"

}

extension AppState {
    var desc: String {
        switch self {
        case .developerRemovedFromSale:
            return "开发者下架"
        case .developerRejected:
            return "开发者撤回"
        case .inReview:
            return "正在审核"
        case .invalidBinary:
            return "无效二进制包"
        case .metadataRejected:
            return "元数据无效"
        case .pendingAppleRelease:
            return  "等待Apple发布"
        case .pendingContract:
            return "等待合约"
        case .pendingDeveloperRelease:
            return "已通过审核，等待发布"
        case .prepareForSubmission:
            return "准备提交"
        case .preorderReadyForSale:
            return "预售已就绪"
        case .processingForAppStore:
            return "App Store处理中"
        case .readyForSale:
            return "已发布至App Store"
        case .rejected:
            return "审核被拒绝"
        case .removedFromSale:
            return  "被下架"
        case .waitingForExportCompliance:
            return "等待出口许可"
        case .waitingForReview:
            return  "等待审核"
        case .replacedWithNewVersion:
            return "已替换为新版本"
        case .accepted:
            return "已被接受"
        case .readyForReview:
            return "可被审核"
        }
    }

    // 是否需要发送消息,并atAll
    var isNeedSendMessage: (Bool, Bool) {
        switch self {
        case .pendingDeveloperRelease,
             .rejected:
                return (true, true)
        case .readyForSale,
             .waitingForReview,
             .inReview:
            return (true, false)
        default:
            return (false, false)
        }
    }
}


