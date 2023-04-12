import Foundation


struct PackageItem: Codable {
    
    var platform: String
    var env: String
    var branchId: String
    var changelog: String
    var downloadUrl: String
    var date: Int64?
    var version: String?
    var build: String?
}

// 项目对象
struct ProjectItem: Codable {
    // 项目id
    var id: String
    // 项目名称
    var name: String
}

/// 扫描当前目录的JSON文件
func scanJSONFileFromDir(_ dir: String) -> [String] {
    let fm = dir
    if let em = FileManager.default.enumerator(atPath: fm) {
        return em.compactMap({
            item -> String? in
            if let file = item as? String, file.hasSuffix(".json") {
                return file
            }
            return nil
        })
    }
    return []
}


func printHelp() {
    print("workDir -> json文件路径")
    print("project -> 项目id： project -> hkddd | fangkebao")
    print("projectName -> 项目名称：projectName -> 房客宝")
    print("platform -> 平台：platform -> ios | android")
    print("env -> app环境：env -> test | staging")
    print("branchId -> 分支id，同样的只能存在一个: branchId ->*")
    print("changelog -> 打包内容描述：changelog -> *")
    print("downloadUrl -> 下载地址： downloadUrl -> *")
    print("version -> 版本号： version -> 0.0.0")
    print("build -> 构建序号： build -> *")
}

/// 解析命令行参数
/// 返回 工作目录地址，项目对象，app包对象
func parseCommandLineArg() -> (String, ProjectItem, PackageItem)? {
    
    let argv = CommandLine.arguments

    print("输入参数列表：\(argv)\n")
    let dict = argv.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }).reduce(into: [String: String]()) { (result, arg) in
        let kv = arg.split(separator: "=")
        if kv.count > 1 {
            result[String(kv[0])] = kv[kv.index(kv.startIndex, offsetBy: 1)..<kv.endIndex].joined(separator: "=")
        }
    }


    print("\n打印dict参数：\(dict)\n")
    // 判断工作区间是否存在
    if let projectId = dict["project"], let workDir = dict["workDir"] {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            let item = try JSONDecoder().decode(PackageItem.self, from: data)
            var projectName = dict["projectName"] ?? ""
            if projectName.isEmpty {
                projectName = projectId
            }
            return (workDir, ProjectItem(id: projectId, name: projectName), item)
        } catch {
            print("error -> \(error)")
        }
    }
    return nil
}

// 更新json文件
func updateJSONFile(_ item: PackageItem, project: ProjectItem, inDir dir: String) {
    print("更新JSON文件")
    let url = URL(fileURLWithPath: dir + "/\(project.id).json")
    do {
        let data = try Data(contentsOf: url)
        var items = try JSONDecoder().decode([PackageItem].self, from: data)
        
        // 过滤30天前的数据
        items = items.filter({
            item in
            if let time = item.date {
                if time > Int64(Date().timeIntervalSince1970 - 2592000) {
                    return true
                }
            }
            return false
        })
        
        if let index = items.firstIndex(where: {
            it in
            return it.branchId == item.branchId
        }) {
            var newItem = item
            newItem.date = Int64(Date().timeIntervalSince1970)
            items[index] = newItem
        } else {
            var newItem = item
            newItem.date = Int64(Date().timeIntervalSince1970)
            items.insert(newItem, at: 0)
        }
        items.sort {
            if let time1 = $0.date, let time2 = $1.date {
                return time1 > time2
            }
            return true
        }
        print("\(items)")
        let newData = try JSONEncoder().encode(items)
        try newData.write(to: url)
    } catch {
        print("error: \(error)")
    }
}

// 创建文件
func makeProjectJSONFile(_ item: PackageItem, project: ProjectItem, inDir dir: String) {
    print("创建JSON文件")
    do {
        var newItem = item
        newItem.date = Int64(Date().timeIntervalSince1970)
        let data = try JSONEncoder().encode([newItem])
        let path = dir
        let url = URL(fileURLWithPath: path + "/" + project.id + ".json")
        print(url.absoluteString)
        try data.write(to: url)
    } catch {
        print("error: \(error)")
        exit(1)
    }
}

/// 检查projects.jsonso 索引
func checkAndAddProject(_ project: ProjectItem, inDir dir: String) {
    print("检查projects.json文件")
    let res = FileManager.default.fileExists(atPath: dir + "/projects.json")
    let url = URL(fileURLWithPath: dir + "/projects.json")
    do {
        if res {
            // 获取projects.json文件的内容
            let data = try Data(contentsOf: url)
            
            // 旧方式读取
            let oldAllProject = (try? JSONDecoder().decode([String].self, from: data)) ?? []
            var allProject: [ProjectItem] = (try? JSONDecoder().decode([ProjectItem].self, from: data)) ?? []
            // 如果是旧方式存的 需要转成新的结构
            if !oldAllProject.isEmpty {
                allProject = oldAllProject.map({
                    it in
                    return  ProjectItem(id: it, name: it)
                })
            } 
            print("读取projects.json内容：\(allProject)")
            // 判断projects.json是否包含工作区间，如果不包含，直接覆写
            if let index =  allProject.firstIndex(where: {
                return $0.id == project.id
            }) {
                if allProject[index].name != project.name {
                    allProject[index].name = project.name
                    let newData = try JSONEncoder().encode(allProject)
                    try newData.write(to: url)
                }
            } else {
                allProject.append(project)
                let newData = try JSONEncoder().encode(allProject)
                try newData.write(to: url)
            }
            if !allProject.contains(where: { $0.id == project.id }) {
                allProject.append(project)
                let newData = try JSONEncoder().encode(allProject)
                try newData.write(to: url)
            }
        }
        // projects.json文件不在存在
        else {
            if !res {
                print("projects.json文件不存在")
            }
            let newData = try JSONEncoder().encode([project])
            try newData.write(to: url)
        }
        print("projects.json文件路径是：\(url)")
    } catch {
        print("error: \(error)")
    }
}

func main() {
    /// 解析参数
    guard let (dir, project, content) = parseCommandLineArg() else {
        printHelp()
        exit(1)
    }

    /// 检查工作区间是否存在, 不存在则创建
    if !FileManager.default.fileExists(atPath: dir) {
        do {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("error: \(error)")
            exit(1)
        }
    }
    
    checkAndAddProject(project, inDir: dir)
    
    // 扫描当前文件
    let currnetFiles = scanJSONFileFromDir(dir)
    
    /// 匹配是否存在project.json
    let targetName = project.id + ".json"
    if currnetFiles.contains(where: {
        item in
        return item.replacingOccurrences(of: " ", with: "") == targetName
    }) {
        // 查是否存在同样的 branchId 如果没有加入新的，有的话需要覆盖旧的
        updateJSONFile(content, project: project, inDir: dir)
    } else {
        //如果没有需要创建，并写入到json文件中
        makeProjectJSONFile( content, project: project, inDir: dir)
    }
    print("JSON生成完成")
}

main()

