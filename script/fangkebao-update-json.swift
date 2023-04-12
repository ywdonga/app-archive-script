
import Foundation


struct VersionModel: Codable {


    var newVersion: String
    var newVersionCode: Int

    var updateMode: String

    var noPromptDays: String?

    var minVersion: String
    var minVersionCode: Int
    
    var secondHouseContent: String?
    var newHouseContent: String?
    var anchangContent: String?


    func generateJSON() -> Result<String, String> {
        var dict: [String: Any] = [:]
        dict["newVersion"] = newVersion
        dict["newVersionCode"] = newVersionCode
        dict["updateMode"] = updateMode
        dict["noPromptDays"] = Int(noPromptDays ?? "") ?? 0
        dict["minVersion"] = minVersion
        dict["minVersionCode"] = minVersionCode

        var content: [String: Any] = [:]
        content["secondHouseContent"] = secondHouseContent
        content["newHouseContent"] = newHouseContent
        content["anchangContent"] = anchangContent
        dict["updateContent"] = content
        dict["introduction"] = secondHouseContent
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return .success(jsonString)
            }
            return .failure("json解析失败")
        } catch {
            print(error)
            return .failure("json error")
        }
    }

}

func checkVersionVaild(version: String) -> Result<String, String> {
    let regex = "^[0-9]{1,}.[0-9]{1,}.[0-9]{1,}$"
    let pre = NSPredicate(format: "SELF MATCHES %@", regex)
    if pre.evaluate(with: version) {
        return .success("ok")
    }
    return .failure("版本号不合规")
}

extension String: Error {}

let needArguments = ["newVersion", "newVersionCode", "updateMode", "minVersion", "minVersionCode", "secondHouseContent", "newHouseContent", "anchangContent"]

func checkArgumengCount(arg: [String]) -> Result<Bool, String> {
    let inputArgKeys:[String] = arg.map { $0.split(separator: "=").map({ String($0) }).first ?? "" }
    let set = Set(needArguments)
    let result = set.subtracting(inputArgKeys)
    if result.count == 0 {
        return .success(true)
    } else {
        return .failure("缺少参数: \(result.joined(separator: ", "))")
    }
}

func parseArgument(arg: [String]) -> Result<VersionModel, String> {

    var dict = arg.reduce(into: [String: Any]()) { (result, item) in
        let keyValue = item.split(separator: "=").map({ String($0) })
        if keyValue.count > 1 {
            if let key = keyValue.first {
                result[key] = keyValue[keyValue.index(keyValue.startIndex, offsetBy: 1)..<keyValue.endIndex].joined(separator: "=")
            }
        }
    }

    if let newCode = dict["newVersionCode"] as? String, let newCodeInt = Int(newCode) {
        dict["newVersionCode"] = newCodeInt
    }

    if let newCode = dict["minVersionCode"] as? String, let newCodeInt = Int(newCode) {
        dict["minVersionCode"] = newCodeInt
    }

    print("\n\n====================")
    print(dict)
    print("====================\n\n")
    do {
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        let model = try decoder.decode(VersionModel.self, from: data)

        if case let .failure(reason) = checkVersionVaild(version: model.newVersion) {
            return .failure("\("newVersion") : \(reason)")
        }


        if !["FORCE", "PROMPT", "NO_PROMPT"].contains(model.updateMode) {
            return .failure("更新模式必须是 FORCE（强制更新）、PROMPT（提示更新）、 NO_PROMPT（不提示更新） 中的一种")
        }

        return .success(model)
    } catch {
        print(error)
        return .failure("解析参数失败")
    }
}

func getOutput(arg: [String]) -> Result<String, String> {
    let dict = arg.reduce(into: [String: Any]()) { (result, item) in
        let keyValue = item.split(separator: "=").map({ String($0) })
        if keyValue.count > 1 {
            if let key = keyValue.first {
                result[key] = keyValue[keyValue.index(keyValue.startIndex, offsetBy: 1)..<keyValue.endIndex].joined(separator: "=")
            }
        }
    }
    if let output = dict["output"] as? String {
        return .success(output)
    }
    return .failure("缺少参数: output(文件输出路径)")
}

func writeFile(path: String, content: String) -> Result<(), String> {
    do {
        
        var url = URL(fileURLWithPath: path)
        url.deleteLastPathComponent()
        if !FileManager.default.fileExists(atPath: url.path) {
            print(url.path)
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        }

        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        }

        try content.write(toFile: path, atomically: true, encoding: .utf8)
        return .success(())
    } catch {
        print(error)
        return .failure("写入更新文件失败")
    }
}

func main() {

    var cmdArgs = CommandLine.arguments.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
    cmdArgs.removeFirst()

    let result = checkArgumengCount(arg: cmdArgs)
    if case .failure(let error) = result {
        print(error)
        exit(1)
    }

    let result2 = parseArgument(arg: cmdArgs)
    if case .failure(let error) = result2 {
        print(error)
        exit(1)
    }

    switch result2 {
        case .success(let model):

            let getOutputResult = getOutput(arg: cmdArgs)
            switch getOutputResult {
                case .success(let output):
                    let result = model.generateJSON()
                    switch result {
                        case .success(let json):
                            let writeResult = writeFile(path: output, content: json)
                            switch writeResult {
                                case .success:
                                    print("写入成功")
                                case .failure(let error):
                                    print(error)
                                    exit(1)
                            }
                        case .failure(let error):
                            print(error)
                            exit(1)
                    }
                case .failure(let error):
                    print(error)
                    exit(1)
            }
        case .failure(let message):
            print(message)
            exit(1)
    }
}

main()