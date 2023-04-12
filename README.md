项目说明

# 项目结构
- app-center-index.html app-center首页，部署地址：https://test-pm3.kfang.com
- build_archive_83.sh 10.210.12.83机器用的打包脚本（2022年不再使用, 缺点：ipa包占用硬盘内存、不具备ipa上传功能、与运维沟通成本高, 学习地址：https://docs.qq.com/doc/DSWtid3RJU09pUHJI?groupUin=Nna4umWbPJIRvUEI0cmzGA%3D%3D&tdsourcetag=s_macqq_aiomsg&jumpuin=611161512）
- build_archive.sh 现用打包脚本 （2022年不再使用，优化了上个版本的缺点：ipa包占用硬盘内存、与运维沟通成本高）
- build_with_fastlane.sh 新增基于fastlane打包脚本 （此版本优化上述版本的缺点：ipa包占用硬盘内存、不具备ipa上传功能、与运维沟通成本高; 增加上传appstore流程, 增加飞书通知，增加packjson的内容哈希值的缓存策略。）
- gen-package-json.swift app-center生成数据的代码 
- fangkebao-update-json.swift 房客宝生成升级文件的代码
- app-release-pip app store审核流程状态监视程序项目
- fastlane-template fastlane配置模版
- Makefile 一键快速安装指令集 （方便使用者一键部署打包环境）


# 注意
- 10.210.10.184 原生打包机器地址
- jenkins需要免密登录到原生打包的机器，配置jenkens的id_rsa.pub公钥复制到原生打包机器的的authorized_keys文件上(cat id_rsa.pub >> ~/.ssh/authorized_keys ), 然后jenkins的机子拿自己的私钥去ssh登录
  (~/.ssh/authorized_keys是SSH协议中用来验证用户身份的文件，存储了公钥认证用的公钥信息。当用户使用SSH登录远程服务器时，会自动生成一对公私钥并将公钥存放在本地的~/.ssh/id_rsa.pub中。为了能够无密码登录远程服务器，可以将本地的公钥内容追加到~/.ssh/authorized_keys文件中。远程服务器使用本地用户的公钥，加密一个随机数并将其发送回来。如果本地用户能够使用对应的私钥解密该随机数，则说明该用户拥有对应的私钥和公钥组合，能够被认证成功，并允许登录远程服务器。学习地址：https://www.ruanyifeng.com/blog/2011/12/ssh_remote_login.html)
- jenkins配置任务的时候，注意访问Git仓库的git账号需要切换
- jenkins配置ssh执行命令，注意切换访问登录的用户名称、执行build_with_fastlane.sh的绝对路径的用户名称
- 被远程登录的机子，需要安装fastlane的环境
- web文件目录被拷贝，需要修改nginx.config中root路径的用户名称


# 子项目说明

## app-release-pipe
固定占用端口 8080

安装docker客户端（官网也支持下载 https://docs.docker.com/desktop/install/mac-install/）
brew install --cask --appdir=Applications docker

构建docker image (需要cd到app-archive-script/app-release-pipe目录下)
`cd /Users/xxx/app-archive-script/app-release-pipe/`  
`docker build . -t app-release-pipe:lastest`

启动docker容器服务（-d防止进程意外终止、-p 8080:8080 指定机器的端口和docker的端口进行映射）
`docker run -d -p 8080:8080  app-release-pipe:lastest`

这里你会疑问app-release-pipe目录下的文件是怎么配置出来的？这里采用了Vapor框架，自动生成该目录下的文件
`brew install vapor`
`vapor new app-release-pipe`

打包机启用了域名test3.kfang.com, 端口数据转发还依赖nginx服务，需要启动nginx

## fastlane-template
见fastlane-template/README.md
