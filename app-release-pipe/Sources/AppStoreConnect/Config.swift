struct Config {
    // 私钥
    static let privatePem = """
               -----BEGIN PRIVATE KEY-----
               MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQggFwPhKuRLSE9WNNv
               RudwYPaS4Q1dgeBagsXYdwrJD2CgCgYIKoZIzj0DAQehRANCAAStOtjwz61chobh
               80qlamOldyGG9Nd7QEncosWVnfYSpYszM44AnSEr9jKLBXWwRd4cKk1ckbgrCowc
               dlTOf4SF
               -----END PRIVATE KEY-----
               """
    // 问题ID
    static let issueId = "cba93062-9e08-4fec-b666-05799cfc9175"
    // 密钥ID
    static let kid = "9C9X282KD6"
    // 钉钉机器人
    static var dingdingHook: String  {
        if AppManager.shared.isTest {
            return  "https://oapi.dingtalk.com/robot/send?access_token=b4caa6fe07cf4d54dca665816043432dacf84abc4f6324fda0e3629528be0b67" // 测试环境
        }
        return "https://oapi.dingtalk.com/robot/send?access_token=1e8e647d0fc54cce75f3a994cd0eb49ab7b6aba6f1e07a7acdb5e20c44694b3b" // 生产环境
    }
    // 飞书机器人
    static var feishuBotHook: String {
        if AppManager.shared.isTest {
            return  "https://open.feishu.cn/open-apis/bot/v2/hook/490aa57e-81db-437d-9964-86f8c580d7c1" // 测试环境
        }
        return "https://open.feishu.cn/open-apis/bot/v2/hook/cf11ee8b1-8f8e-4c28-8160-832272229827" // 生产环境
    }
    // 请求间隔，单位秒
    static var requestInterval: Int {
        if AppManager.shared.isTest {
            return 200 // 测试环境
        }
        return  10 * 60 // 生产环境
    }
    // 需要重点关注的 App ID
    static let keyAppIds = [
        "1572973905", // 房客宝
        "1602634011" // 拓客本
    ]
}
