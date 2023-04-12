#!/bin/bash
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
#执行时间
curl_date=$(date +%Y%m%d)
curl_time=$(date +%H%M%S)

#计时
SECONDS=0

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

#描述信息
desc=""

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
    # 刷新shell配置
    if [ $SHELL = '/bin/zsh' ]; then
        if [[ -d $HOME/.zshrc ]]; then
            source $HOME/.zshrc
        fi
    elif [ $SHELL = '/bin/bash' ]; then
        if [[ -d $HOME/.bash_profile ]]; then
            source $HOME/.bash_profile
        fi
    fi  
}

# 解析脚本传入参数
function parse_cmd_param() { #$@是此行命令所在函数(脚本)的所有被传入参数的合集
    local cmd_git="git="
    local cmd_workspace="workspace="
    local cmd_target="target="
    local cmd_mode="mode="
    local cmd_branch="branch="
    local cmd_rn="rn="
    local cmd_desc="desc="
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
        elif [[ $i == $cmd_desc* ]]; then #如果存在变量desc，以“desc=” 来匹配参数，并且分割，取后者赋值
            desc=${i:5}
        elif [[ $i == $cmd_appName* ]]; then #如果存在变量desc，以“desc=” 来匹配参数，并且分割，取后者赋值
            appName=${i:8}
        fi
        echo $i
    done
}

#检查命令行参数值，变量的值为空,设置默认值
function check_cmd_param() {

    if [ -z "$git" ]; then
        echo "未指定git地址"
        exit 1
    fi

    if [ -z "$workspace" ]; then
        echo "未指定工作目录"
        exit 1
    fi

    if [ -z "$target" ]; then
        echo "未指定打包目标"
        exit 1
    fi

    if [ $(tr 'A-Z' 'a-z' <<< $mode) = "release" ]; then
        mode="Release"
    fi

    if [ $(tr 'A-Z' 'a-z' <<< $mode) = "staging" ]; then
        mode="Staging"
    fi

    if [ $(tr 'A-Z' 'a-z' <<< $mode) = "debug" ] || [ -z "$mode" ]; then
        mode="Debug"
    fi

    if [ -z "$branch" ]; then
        branch="master"
    fi

    if [ -z "$rn" ]; then
        rn="offline"
    fi
}

# 创建文件夹，如果文件夹不存在, 存在就使用已有的
function make_dir_if_not_exist() {
    if [ ! -d "$1" ]; then
        mkdir -p $1
    fi
}
# 删除文件夹，如果存在的话
function remove_dir_if_exist() {
    if [[ -d $1 ]]; then
        rm -rf $1 -r
    fi
}

function print_current_dir() {
    echo "当前目录：>>>>> $PWD"
}

function create_Node_modules_dir() {
    
    if [ ! -d $package_root_dir/node_modules ]; then
        mkdir -p $package_root_dir/${target}/node_modules
        echo "创建解压路径：>>>>> $package_root_dir/${target}/node_modules"
    fi
}

function copy_Node_modules() {
    echo "目标路径：>>>>> $package_root_dir/${target}/node_modules"
    unzip -o -d $package_root_dir/${target} /Users/kfang/server/archive-space/fangkebao/node_modules.zip
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
    gitTreeHash=$(git show -s --format=%T)
    gitCommitLog=$(git show -s --format=%s)
    gitTreeHashLite=$(git show -s --format=%t)
    gitCurrentBranch=$(git branch --show-current)

    echo "~~~~~~~~~~~~~~~~~~~获取git提交信息~~~~~~~~~~~~~~~~~~~"
    echo "提交者:$gitauthor"
    echo "提交时间:$gitcommitDate"
    echo "提交分支:$gitCurrentBranch"
    echo "treeId:$gitTreeHash"
    echo "gitCommitLog:$gitCommitLog\n"
}

# 检查是否应在当前分支构建
function check_build_branch() {
    if [ $mode = "Release" ]; then 
        if [ $gitCurrentBranch = "release-abm" ] || [ $gitCurrentBranch = "master" ] ||  [ $gitCurrentBranch = "main" ]; then
            echo "========================================"
            echo "即将构建App Store包..."
            echo "========================================"
        else
            echo "========================================"
            echo "========================================"
            echo "⚠️请在release-abm或master构建App Store包⚠️"
            echo "========================================"
            echo "========================================"
            exit 1
        fi
    fi
}

# 设置xcodebuild所需参数
function setup_xcode_env_var() {
    #工程绝对路径  (这里注意是shell脚本所在的路径)
    project_path=${target}

    #工程名
    project_name=${target}

    #scheme名
    project_scheme=${target}

    #打包模式 Debug/Release
    development_mode=${mode}

    #xcworkspace名
    project_workspace=${project_name}.xcworkspace

    #build文件夹路径
    build_path=${project_path}/build

    # archive_path        eg:$project_path/$project_name.xcarchive
    archive_path=$project_path/build/$project_name.xcarchive

    #导出ipa文件存放路径
    export_ipa_path=${project_path}/package/app

    #plist文件所在路径 eg:$project_path/ExportOptions.plist
    export_options_plist=${PWD}/ExportOptions$mode.plist
}

function get_bundle_info() {
    #获取版本号
    bundle_version=$(sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' ${project_name}.xcodeproj/project.pbxproj)
    echo "获取版本号:"$bundle_version

    if [ -z "${bundle_version}" ]; then
        echo "[ERROR] failed to get MARKETING_VERSION"
        exit 1
    fi

    #获取BundleID
    bundle_id=$(sed -n '/PRODUCT_BUNDLE_IDENTIFIER/{s/PRODUCT_BUNDLE_IDENTIFIER = //;s/;//;s/^[[:space:]]*//;p;q;}' ./${project_name}.xcodeproj/project.pbxproj)

    echo "获取BundleID:"$bundle_id

    if [ -z "${bundle_id}" ]; then
        echo "[ERROR] failed to get PRODUCT_BUNDLE_IDENTIFIER"
        exit 1
    fi
}

# 运行xcode构建
function run_xcode_building() {
    echo '~~~~~~~~~~~~开始安装项目依赖~~~~~~~~~~~~\n'
    refresh_sh_config
    /usr/local/bin/pod install
    if test $? -eq 0; then
        echo "~~~~~~~~~~~~~~安装依赖完成~~~~~~~~~~~~~~~\n"
    else
        echo "~~~~~~~~~~~~~安装依赖失败~~~~~~~~~~~~~~~\n"
        exit 1
    fi

    echo '~~~~~~~~~~~~开始ipa打包，正在清理工程~~~~~~~~~~~~\n'

    xcodebuild clean \
        -workspace ${project_workspace} \
        -scheme ${project_scheme} \
        -configuration ${development_mode} \
        -quiet || exit

    echo '~~~~~~~~~~~~~~~~清理完成,开始编译~~~~~~~~~~~~~~~~\n'
    echo "workspace: ${project_workspace}"
    echo "archive: ${archive_path}"
    echo "scheme: ${project_scheme}"
    echo "configuration: ${development_mode}"
    xcodebuild archive \
        -workspace ${project_workspace} \
        -scheme ${project_scheme} \
        -configuration ${development_mode} \
        -archivePath ${archive_path} \
        -sdk iphoneos \
        -allowProvisioningUpdates || exit
    

    #判断编译结果
    if test $? -eq 0; then
        echo "~~~~~~~~~~~~~~生成.xcarchive包成功~~~~~~~~~~~~~~~\n"
    else
        echo "~~~~~~~~~~~~~生成.xcarchive包失败~~~~~~~~~~~~~~~\n"
        exit 1
    fi

    echo '~~~~~~~~~~~根据.archive包导出成ipa文件~~~~~~~~~~~\n'
    echo "plist: ${export_options_plist}"
    echo "archive: ${archive_path}"
    echo "ipa: ${export_ipa_path}"
    echo "configuration: ${development_mode}"

    xcodebuild -exportArchive \
        -archivePath ${archive_path} \
        -configuration ${development_mode} \
        -exportPath ${export_ipa_path} \
        -exportOptionsPlist ${export_options_plist} \
        -allowProvisioningUpdates \
        -quiet || exit

    if [ -e $export_ipa_path/${target}.ipa ]; then
        echo '\n~~~~~~~~~~~~~~~~~~ipa包已导出~~~~~~~~~~~~~~~~~~~\n'

        cd $export_ipa_path

        local ipa=$workspace-$branch-$mode-$rn.ipa
        
        ipa=$(tr 'A-Z' 'a-z' <<< $workspace-$branch-$mode-$rn.ipa)
        
        mv ${target}.ipa $ipa
        #open $export_ipa_path
        make_dir_if_not_exist $package_root_dir/package-history
        
        remove_dir_if_exist $package_root_dir/jenkins-workspace
        make_dir_if_not_exist $package_root_dir/jenkins-workspace

        cp -r $ipa $package_root_dir/package-history/$ipa
        cp -r $ipa $package_root_dir/jenkins-workspace/$ipa
    else
        echo '~~~~~~~~~~~~~~~~~ipa包导出失败~~~~~~~~~~~~~~~~~\n'
    fi

    #删除build包
    remove_dir_if_exist build
}

# 推送钉钉
function notify_dingding() {

    if [ -z "${appName}" ]; then
        echo ""
    else
        echo "通知钉钉机器人"
        curl 'https://oapi.dingtalk.com/robot/send?access_token=34c43fab3a640a4307d40739643e912293611277f9f3f843b5e9d37e29f3d16f' -H  'Content-Type: application/json' -d  "{\"msgtype\": \"text\",\"text\": {\"content\": \"iOS：😊${appName}🏠${mode}包构建成功，请同学们访问http://10.210.12.83 进行下载🌷\"}}"
    fi
}


# 生成manifest.plist, 参数： $1: bundle_version(包版本号) $2: manifest_path(文件存放路径)
function gen_manifest() {
    #manfest.plist中的信息
    local icon57_url="https://test-pm3.kfang.com/icons/$workspace-57.png"
    local icon512_url="https://test-pm3.kfang.com/icons/$workspace-512.png"
    local ipa_url="https://test-pm3.kfang.com/package/ios/$1"

    cat <<-EOF > $2
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items</key>
    <array>
        <dict>
            <key>assets</key>
            <array>
                <dict>
                    <key>kind</key>
                    <string>software-package</string>
                    <key>url</key>
                    <string>${ipa_url}</string>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>display-image</string>
                    <key>url</key>
                    <string>${icon57_url}</string>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>full-size-image</string>
                    <key>url</key>
                    <string>${icon512_url}</string>
                </dict>
            </array>
            <key>metadata</key>
            <dict>
                <key>bundle-identifier</key>
                <string>${bundle_id}</string>
                <key>bundle-version</key>
                <string>${bundle_version}</string>
                <key>kind</key>
                <string>software</string>
                <key>platform-identifier</key>
                <string>com.apple.platform.iphoneos</string>
                <key>title</key>
                <string>$workspace</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF
}

# //////////////////////////////////////////////////////
# //////////////////////////////////////////////////////

# ======================================================
# ======================================================
# 脚本执行区
security unlock-keychain -p "kfang12345" /Users/kfang/Library/Keychains/login.keychain

export PATH='$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'

# 1. 解析脚本参数
#获取外界传入对应比变量的值
parse_cmd_param $@

# 2. 校验脚本参数
check_cmd_param

# 3. 打印参数
echo "\n执行脚本命令具体参数如下："
echo "git:"$git
echo "workspace:"$workspace
echo "target:"$target
echo "mode:"$mode
echo "branch:"$branch
echo "rn:"$rn
echo "desc:"$desc
echo "appName":$appName
echo "\n"

# 4. 检查项目工作空间是否存在，如果不存在就创建
cd ~/server/archive-space
make_dir_if_not_exist ${PWD}/${workspace}
# 进入项目工作空间
cd $workspace
print_current_dir

# 5. 检查打包工作目录
make_dir_if_not_exist $PWD/package-${mode}
# 暂存当前打包工作目录
package_root_dir=$PWD/package-${mode}
# 进入打包工作目录
cd $package_root_dir
print_current_dir

# 6. 检查git项目目录
# 检查是否存在旧项目目录
remove_dir_if_exist ${workspace}
remove_dir_if_exist ${target}
# 下载项目代码
git_clone_code $branch $git $target

# 7. 进入代码项目工程目录, 并获取git commit记录
cd ./${target}
print_current_dir
fetch_git_commit_info

#7.1 
check_build_branch

copy_Node_modules

# 8. 配置xcode打包配置变量
setup_xcode_env_var

# 9. 获取bundle信息
get_bundle_info

# 10. 检查代码项目目录下是否有打包目录
make_dir_if_not_exist package/app

# 11. 开始构建
run_xcode_building
echo "\033[36;1m 打包 ipa 完成。总耗时:${SECONDS}s \033[0m"

# 创建分支唯一标识
if [ $(tr 'A-Z' 'a-z' <<< $rn) = "offline" ]; then
    branchId=$(tr 'A-Z' 'a-z' <<< "$branch-$mode-offline")
else
    branchId=$(tr 'A-Z' 'a-z' <<< "$branch-$mode-online")
fi

# 12. 生成manifest
gen_manifest $workspace-$branchId.ipa $package_root_dir/jenkins-workspace/$branchId.plist

# 13. 复制ipa 和plist到http服务目录下
make_dir_if_not_exist ~/server/app-center/package/ios
cp $workspace-$branch-$mode-$rn.ipa ~/server/app-center/package/ios/$workspace-$branchId.ipa
cp $package_root_dir/jenkins-workspace/$branchId.plist ~/server/app-center/package/ios/$workspace-$branchId.plist
#platId=4
#case $mode in
#Debug)
#    platId=4
#    ;;
#Staging)
#	platId=5
#	;;
#esac

#curl --form plat_id=$platId --form file_nick_name=$branchId --form token=a12da33672ae3b3fa8c9898a41452684204f6e08 --form features= --form file=@$workspace-$branch-$mode-$rn.ipa http://10.210.12.83:3000/api/pkgs

# 15. 增加app center下发布记录
local cur=${PWD}
~/server/cmd/gen-package-json \
    workDir=="$HOME/server/app-center" \
    project==$workspace \
    platform==ios \
    env==$mode \
    branchId==$branchId \
    changelog=="$gitCommitLog" \
    downloadUrl=="itms-services://?action=download-manifest%26url=https://test-pm3.kfang.com/package/ios/$workspace-$branchId.plist" \
    projectName=="$appName"
# 16. 找出30天前的文件并删除
# 查找30天前的文件并删除
cd ~/server/app-center/package/ios
echo "==== 开始清理30天前的数据 ===="
find . -mtime +30 -name "*.plist" -exec rm -rf {} \;
find . -mtime +30 -name "*.ipa" -exec rm -rf {} \;
echo "==========================="
cd $cur
# 16. 推送钉钉
notify_dingding

echo "已运行完毕>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
# ======================================================
# ======================================================
