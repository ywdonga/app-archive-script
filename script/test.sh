
# ipa_url="http://ssx.baidu.com"
# icon57_url="ht"
# icon512_url="aaaasx"
# bundle_id="123213123"
# bundle_version="1222ddd"
# workspace="sdfsfdsf"

# function gen_manifest() {
#     #manfest.plist中的信息
#     local icon57_url="https://test-pm3.kfang.com/icons/$workspace-57.png"
#     local icon512_url="https://test-pm3.kfang.com/icons/$workspace-512.png"
#     local ipa_url="https://test-pm3.kfang.com/package/ios/$1"

#     echo "== 生成maifest.plist"
#     local content=$(cat manifest.plist | sed -e "s#{ipa_url}#${ipa_url}#g" -e "s#{icon57_url}#${icon57_url}#g" -e "s#{icon512_url}#${icon512_url}#g" -e "s/{bundle_id}/${bundle_id}/g" -e "s/{bundle_version}/${bundle_version}/g" -e "s#{workspace}#${workspace}#g")
#     echo "== manifest.plist 内容："
#     echo "\n$content"
#     echo $content > $2

# }

curl -X POST -H 'Content-Type: application/json' -d '{"msg_type":"text","content":{"text":"房客宝test"}}' 'https://open.feishu.cn/open-apis/bot/v2/hook/490aa57e-81db-437d-9964-86f8c580d7c1'

# curl -X POST -H 'Content-Type: application/json' -d "{\"msg_type\":\"post\",\"content\":{\"post\":{\"zh_cn\":{\"title\":\"房客宝1.1.1\",\"content\":[[{\"tag\":\"a\",\"text\":\"前往下载\",\"href\":\"https://test-pm3.kfang.com\"}]]}}}}" https://open.feishu.cn/open-apis/bot/v2/hook/cf11e8b1-8f8e-4c28-8160-832272229827

# 测试 https://open.feishu.cn/open-apis/bot/v2/hook/490aa57e-81db-437d-9964-86f8c580d7c1