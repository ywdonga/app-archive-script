#!/bin/zsh
# 脚本使用说明

# ！！！打包前置条件
# 1. 需要在 xcode 工程设置中去除 `Automatically manage signing` 否则会报错
# 2. 项目配置需要scheme和target同名
# 3. 打包基于workspace, 当前不适用于project，也就是单个项目的打包工作空间
# 4. 项目需配置Debug,Staging,Release三个配置项
# 5. 项目路径配置ExportOptions.plist文件,命名规则：ExportOptions+Configuration.plist, eg: ExportOptionsDebug.plist
# ！！！！！！！！！！！

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++
# 全局变量定义区

##############################配置基本变量来接受外界传进来的参数##############################

archive_space=$HOME/server/archive-space

#用来匹配外界即将传入的变量，打包模式、分支、版本、RN具体包、打包描述、上传方式
# git 地址
git=""
# 工作空间(取项目全拼，例如房客宝项目，工作空间：fangkebao)
workspace=""
# 目标名 (其实就是项目project的名称，例如：房客宝项目为 agent-iOS)
target=""
#打包模式 (测试:debug 预发：staging 正式:release)
mode=""
#打包分支
branch=""
#RN在线包 online  离线包 offline，默认不传)
rn=""
#应用名称
appName=""

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++

# //////////////////////////////////////////////////////
# //////////////////////////////////////////////////////
# 函数声明区

# 配置bash shell刷新
function refresh_sh_config() {
    export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/opt/homebrew/bin

    echo "== 当前PATH: $PATH"    
    # 刷新shell配置
    if [ $SHELL = '/bin/zsh' ]; then
        if [[ -d $HOME/.zshrc ]]; then
            echo "== 加载.zshrc"
            source $HOME/.zshrc
        fi
    elif [ $SHELL = '/bin/bash' ]; then
        if [[ -d $HOME/.bash_profile ]]; then
            echo "== 加载.bash_profile"
            source $HOME/.bash_profile
        fi
    fi    
}


# 解析脚本传入参数
function parse_cmd_param() { #$@是此行命令所在函数(脚本)的所有被传入参数的合集
    echo "== 解析脚本传入参数"
    local cmd_git="git="
    local cmd_workspace="workspace="
    local cmd_target="target="
    local cmd_mode="mode="
    local cmd_branch="branch="
    local cmd_rn="rn="
    local cmd_appName="appName="
    for i in $@; do
        if [[ $i == $cmd_git* ]]; then #如果存在变量git,,以“git=” 来匹配参数，并且分割，取后者赋值
            git=${i:4}
        elif [[ $i == $cmd_workspace* ]]; then #如果存在变量workspace,,以“workspace=” 来匹配参数，并且分割，取后者赋值
            workspace=${i:10}
        elif [[ $i == $cmd_target* ]]; then #如果存在变量target,,以“target=” 来匹配参数，并且分割，取后者赋值
            target=${i:7}
        elif [[ $i == $cmd_mode* ]]; then #如果存在变量model,,以“mode=” 来匹配参数，并且分割，取后者赋值
            mode=${i:5}
        elif [[ $i == $cmd_branch* ]]; then #如果存在变量branch，以“branch=” 来匹配参数，并且分割，取后者赋值
            local br="${i:7}"
            branch=${br/origin\//}
        elif [[ $i == $cmd_rn* ]]; then #如果存在变量rn，以“rn=” 来匹配参数，并且分割，取后者赋值
            rn=${i:3}
        elif [[ $i == $cmd_appName* ]]; then #如果存在变量desc，以“desc=” 来匹配参数，并且分割，取后者赋值
            appName=${i:8}
        fi
        echo $i
    done
    echo "== 解析完成"
}


#检查命令行参数值，变量的值为空,设置默认值
function check_cmd_param() {
    echo "== 开始检查命令参数"
    if [ -z "$git" ]; then
        echo "命令参数错误：未指定git地址"
        exit 1
    fi

    if [ -z "$workspace" ]; then
        echo "命令参数错误：未指定工作目录"
        exit 1
    fi

    if [ -z "$target" ]; then
        echo "命令参数错误：未指定打包目标"
        exit 1
    fi

    if [ -z "$branch" ]; then
        branch="master"
    fi

    rn="$(echo $rn | xargs echo)"

    #打印参数
    echo "执行脚本命令具体参数：git=$git workspace=$workspace target=$target mode=$mode branch=$branch rn=$rn appName:$appName"
}


# 创建文件夹，如果文件夹不存在, 存在就使用已有的
function make_dir_if_not_exist() {
    if [ ! -d "$1" ]; then
        echo "=== 创建文件夹： $1"
        mkdir -p $1
    fi
}


# 删除文件夹，如果存在的话
function remove_dir_if_exist() {
    if [[ -d $1 ]]; then
        echo "=== 移除文件夹： $1"
        rm -rf $1 -r
    fi
}


# 打印当前目录完整地址
function print_current_dir() {
    echo "== 当前目录：>>>>> $PWD"
}


# 检查硬盘空间，并提供预警
function check_disk_space() {
    disk_sp=$(df -H -T apfs / | awk 'NR==2{print $4}' | sed 's/G//g')
    echo "== 硬盘空间${disk_sp}G"

    if [[ disk_sp -le 3 ]];then
        echo "== ❌❌❌ 硬盘空间过小，请先清理"
        echo "== ❌❌❌ 硬盘空间过小，请先清理"
        echo "== ❌❌❌ 硬盘空间过小，请先清理"
        exit 1
    elif [[ disk_sp -le 10 ]];then
        echo "== ⚠️⚠️⚠️ 硬盘空间可能不足"
        echo "== ⚠️⚠️⚠️ 硬盘空间可能不足"
        echo "== ⚠️⚠️⚠️ 硬盘空间可能不足"
    fi
}


# 清理过期构建包缓存
function clean_expired_archive_cache() {
    echo "== 开始清理构建包缓存"
    # 删除rn库缓存
    echo "== 1.清理rn库缓存"
    find $archive_space/node-lib-cache-dir -mtime +1w -maxdepth 1 -exec rm -rf {} \;

    # 删除pod缓存
    echo "== 2. 清理pod缓存"
    find $archive_space/pod-cache-dir -mtime +1w -maxdepth 1 -exec rm -rf {} \;
    
    # 删除archive包缓存
    echo "== 3. 清理archive缓存"
    find $HOME/Library/Developer/Xcode/Archives -mtime +1 -exec rm -rf {} \;

    echo "==== 开始清理 app center 20天前的安装包数据 ===="
    find $HOME/server/app-center/package/ios -mtime +20 -name "*.plist" -exec rm -rf {} \;
    find $HOME/server/app-center/package/ios -mtime +20 -name "*.ipa" -exec rm -rf {} \;
    echo "=============清理结束=============="
}


# 安装js依赖
function install_node_modules() {
    
    echo "== 安装node_modules"
    echo "== 1. 检查package.json是否存在"
    if [[ ! -e package.json ]]; then
        echo "package.json 不存在，无需安装"
        return 0
    fi

    #获取当前package.json的md5
    local package_md5=$(shasum package.json | sed 's/package.json//g' $1)
    echo "== package.json md5: $package_md5"
    # 根据md5去检查是否有存在的nodel_modules下载缓存
    local cache_dir=$archive_space/node-lib-cache-dir/$package_md5

    if [ ! -d $cache_dir ]; then
        mkdir -p $cache_dir
    fi

    cp package.json $cache_dir/package.json
    
    # 记录当前工作目录
    local curr_work_dir=$PWD

    cd  $cache_dir
    print_current_dir
    echo "== 开始检查node_modules是否存在"
    local check_result=1
    if [[ -e node_modules ]]; then
        # 检查node_modules是否与package.json一致
        echo "== 开始执行yarn check"
        yarn check --offline
        check_result=$?
    fi
    
    # 如果检查指令返回码为0,说明是一致的，否则需要重新安装依赖
    if [ $check_result -ne 0 ]; then
        echo "== 正在更新node_modules..."
        yarn
        pre_exit_code=$?
        if [ $pre_exit_code -ne 0 ]; then
            exit $pre_exit_code
        fi
    fi

    cd $curr_work_dir
    echo "== 使用缓存node_modules"
    cp -r $cache_dir/node_modules .

    echo "== node_modules安装结束"
}


# 下载对应仓库地址代码，参数: $1:branch(分支) $2: url(git仓库地址)
function git_clone_code() {
    echo "~~~~~~~~~~~~~~~~~~~git clone开始 $(date "+%Y-%m-%d %H:%M:%S") ~~~~~~~~~~~~~~~~~~~"
    # http://kfang-ci:kfang-ci@
    #git clone -b $1 "http://kfang-ci:kfang-ci@$2" $3
    git clone -b $1 $2

    #判断克隆代码执行是否成功
    if test $? -eq 0; then
        echo "~~~~~~~~~~~~~~~~~~~git clone成功 $(date "+%Y-%m-%d %H:%M:%S") ~~~~~~~~~~~~~~~~~~~"
        echo ""
    else
        echo "~~~~~~~~~~~~~~~~~~~git clone失败~~~~~~~~~~~~~~~~~~~"
        exit 1
    fi
}


#获取git版本提交信息
function fetch_git_commit_info() {
    gitauthor=$(git show -s --format=%an)
    gitcommitDate=$(git show -s --format=%cd)
    gitCommitHash=$(git show -s --format=%H)
    gitCommitLog=$(git show -s --format=%s)
    gitTreeHashLite=$(git show -s --format=%t)
    gitCurrentBranch=$(git branch --show-current)

    echo "~~~~~~~~~~~~~~~~~~~获取git提交信息~~~~~~~~~~~~~~~~~~~"
    echo "提交者:$gitauthor"
    echo "提交时间:$gitcommitDate"
    echo "提交分支:$gitCurrentBranch"
    echo "CommitId:$gitCommitHash"
    echo "CommitLog:$gitCommitLog\n"
    echo "~~~~~~~~~~~~~~~~~~~~~~~end~~~~~~~~~~~~~~~~~~~~~~~~~"
}


# 检查是否应在当前分支构建
function check_build_branch() {
    if [ $mode = "Release" ]; then 
        if  [ $gitCurrentBranch = "release-abm" ] || [ $gitCurrentBranch = "master" ] ||  [ $gitCurrentBranch = "main" ]; then
            echo "========================================"
            echo "即将构建App Store包..."
            echo "========================================"
        else
            echo "========================================"
            echo "========================================"
            echo "⚠️请在release-abm或master构建App Store包⚠️"
            echo "⚠️请在release-abm或master构建App Store包⚠️"
            echo "⚠️请在release-abm或master构建App Store包⚠️"
            echo "========================================"
            echo "========================================"
            exit 1
        fi
    fi
}


function get_bundle_info() {
    print_current_dir
    #获取版本号
    bundle_version=$(sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' ${target}.xcodeproj/project.pbxproj)
    echo "== 获取版本号:"$bundle_version

    if [ -z "${bundle_version}" ]; then
        echo "[ERROR] failed to get MARKETING_VERSION"
        exit 1
    fi

    #获取BundleID
    bundle_id=$(sed -n '/PRODUCT_BUNDLE_IDENTIFIER/{s/PRODUCT_BUNDLE_IDENTIFIER = //;s/;//;s/^[[:space:]]*//;p;q;}' ./${target}.xcodeproj/project.pbxproj)

    echo "== 获取BundleID:"$bundle_id

    if [ -z "${bundle_id}" ]; then
        echo "[ERROR] failed to get PRODUCT_BUNDLE_IDENTIFIER"
        exit 1
    fi
}

function find_xcode_project_dir() {
    local dir=$(find $1 -name "Podfile")
    echo "== 定位Podfile位置: $dir"
    if [[ dir == "" ]];then
        exit 1
    fi
    project_dir=$(dirname $dir)
    echo $project_dir
}


# 运行fastlane构建
function run_fastlane_build() {
    
    # 检查Pods是否存在缓存，如果有就恢复
    if [[ ! -e Podfile ]]; then
        echo "== Podfile 不存在"
        exit 1
    fi

    # 获取podfile md5
    local podfile_md5=$(shasum Podfile | sed 's/Podfile//g' $1)
    echo "== Podfile md5: $podfile_md5"
    local cache_dir=$archive_space/pod-cache-dir/$podfile_md5

    make_dir_if_not_exist Pods

    # 如果有缓存，直接从缓存恢复
    if [ -d $cache_dir ]; then
        echo "== 使用缓存Pods"
        cp -r $cache_dir/ ./Pods
    fi
    

    echo "=== 执行fastlane"
    export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=wstw-jraa-pqlg-qhbe
    export FASTLANE_PASSWORD=kfPkz2020@@
    fastlane ios $mode
    exit_code=$?
    if test $exit_code -ne 0; then
        echo "=== === === === === === === ==="
        echo "=== === === 打包失败 === === ==="
        echo "=== === === === === === === ==="
        exit $exit_code
    fi

    
    if [ ! -d $cache_dir ]; then
        mkdir -p $cache_dir
    else
        rm -r $cache_dir/* # 如果该文件夹已经存在了，清空下面的文件和子文件夹
    fi

    cp -r Pods/ $cache_dir/ #备份最新pod install的库

    # upload_to_appstore
    if [ $mode = "Release" ]; then
        nohup fastlane ios Upload
    fi
}


function gen_app_center_record() {
    # 获取version
    local appVersion=$(xcodeproj show | grep "MARKETING_VERSION: " | grep -o '[0-9]\{1,\}.[0-9]\{1,\}.[0-9]\{1,\}' -m 1)
    # 获取build
    local appBuild=$(xcodeproj show | grep "CURRENT_PROJECT_VERSION:" | grep -o '[0-9]\{1,\}' -m 1)

    $HOME/server/cmd/gen-package-json \
        workDir=="$HOME/server/app-center" \
        project==$workspace \
        platform==ios \
        env==$mode \
        branchId==$branchId \
        changelog=="$gitCommitLog" \
        downloadUrl=="itms-services://?action=download-manifest%26url=https://test-pm3.kfang.com/package/ios/$workspace-$branchId.plist" \
        projectName=="$appName" \
        version="$appVersion" \
        build="$appBuild"
}


# 生成manifest.plist, 参数： $1: bundle_version(包版本号) $2: manifest_path(文件存放路径)
function gen_manifest() {
    #manfest.plist中的信息
    local icon57_url="https://test-pm3.kfang.com/icons/$workspace-57.png"
    local icon512_url="https://test-pm3.kfang.com/icons/$workspace-512.png"
    local ipa_url="https://test-pm3.kfang.com/package/ios/$1"

    echo "== 生成maifest.plist"
    local content=$(cat $HOME/server/template/manifest.plist | sed -e "s#{ipa_url}#${ipa_url}#g" -e "s#{icon57_url}#${icon57_url}#g" -e "s#{icon512_url}#${icon512_url}#g" -e "s/{bundle_id}/${bundle_id}/g" -e "s/{bundle_version}/${bundle_version}/g" -e "s#{workspace}#${workspace}#g")
    echo "== manifest.plist 内容："
    echo "\n$content"
    echo $content > $2

}


# //////////////////////////////////////////////////////
# //////////////////////////////////////////////////////

# ======================================================
# ======================================================
# 脚本执行区
# ======================================================
# ======================================================
# 预处理
## 解锁钥匙串
security unlock-keychain -p "kfang12345" /Users/kfang/Library/Keychains/login.keychain
## 刷新shell配置
refresh_sh_config
## 清理硬盘文件
clean_expired_archive_cache
## 重新检查硬盘剩余容量
check_disk_space


# 1. 解析脚本参数
#获取外界传入对应比变量的值
echo "①①① ①①① ①①① ①①① ①①①"
parse_cmd_param $@


# 2. 校验脚本参数
echo "②②② ②②② ②②② ②②② ②②②"
check_cmd_param


# 3. 检查项目工作空间是否存在，如果不存在就创建
echo "③③③ ③③③ ③③③ ③③③ ③③③"
cd $HOME/server/archive-space
make_dir_if_not_exist ${PWD}/${workspace}
# 进入项目工作空间
cd $workspace
print_current_dir


# 4. 检查打包工作目录
echo "④④④ ④④④ ④④④ ④④④ ④④④"
make_dir_if_not_exist $PWD/package-${mode}
# 暂存当前打包工作目录
package_root_dir=$PWD/package-${mode}
# 进入打包工作目录
cd $package_root_dir
print_current_dir


# 5. 检查git项目目录
# 检查是否存在旧项目目录
echo "⑤⑤⑤ ⑤⑤⑤ ⑤⑤⑤ ⑤⑤⑤ ⑤⑤⑤"
remove_dir_if_exist ${workspace}
remove_dir_if_exist ${target}
# 下载项目代码
git_clone_code $branch $git $target


# 6. 进入代码项目工程目录, 并获取git commit记录
# todo: 查找xcworkspace,进入对应目录
echo "⑥⑥⑥ ⑥⑥⑥ ⑥⑥⑥ ⑥⑥⑥ ⑥⑥⑥"
find_xcode_project_dir .
cd ./${project_dir}
print_current_dir
fetch_git_commit_info
# 检查当前分支
check_build_branch


# 7. 安装rn依赖
echo "⑦⑦⑦ ⑦⑦⑦ ⑦⑦⑦ ⑦⑦⑦ ⑦⑦⑦"
install_node_modules


# 8. 获取bundle信息
echo "⑧⑧⑧ ⑧⑧⑧ ⑧⑧⑧ ⑧⑧⑧ ⑧⑧⑧"
get_bundle_info


# 9. 开始构建
echo "⑨⑨⑨ ⑨⑨⑨ ⑨⑨⑨ ⑨⑨⑨ ⑨⑨⑨"
run_fastlane_build


# 10. 生成manifest
echo "⑩⑩⑩ ⑩⑩⑩ ⑩⑩⑩ ⑩⑩⑩ ⑩⑩⑩"
branchId="$branch-$mode"
gen_manifest $workspace-$branchId.ipa $workspace-$branchId.plist


# 11. 复制ipa 和plist到http服务目录下
echo "⑪⑪⑪ ⑪⑪⑪ ⑪⑪⑪ ⑪⑪⑪ ⑪⑪⑪"
make_dir_if_not_exist $HOME/server/app-center/package/ios
if [ -f "$target.ipa" ]; then
    cp $target.ipa $HOME/server/app-center/package/ios/$workspace-$branchId.ipa
elif [ -f "build/$target/$target.ipa" ]; then
    cp "build/$target/$target.ipa" $HOME/server/app-center/package/ios/$workspace-$branchId.ipa
else
    echo "ERROR: 未找到ipa包"
    exit 1
fi
cp $workspace-$branchId.plist $HOME/server/app-center/package/ios/$workspace-$branchId.plist


# 12. 增加app center下发布记录
echo "⑫⑫⑫ ⑫⑫⑫ ⑫⑫⑫ ⑫⑫⑫ ⑫⑫⑫"
gen_app_center_record


echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 构建完毕 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
# ======================================================
# ======================================================
