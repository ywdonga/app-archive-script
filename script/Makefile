
APP_CENTER_DIR=$(HOME)/server/app-center
CMD_DIR=$(HOME)/server/cmd
ARCHIVE_SPACE_DIR=$(HOME)/server/archive-space
WEB_DIR=$(HOME)/server/

# 测试区
# 编译
test-gen-package-json: gen-package-json.swift
	@swiftc gen-package-json.swift
	@./gen-package-json \
	workDir="./output/test-html" \
  	project=test \
  	platform=ios \
  	env=test \
  	branchId=test \
  	changelog="11231321" \
  	downloadUrl="https://test-pm3.kfang.com/package/ios/tuokeben-dev-hidden-tfb-debug-offline.plist" \
  	projectName="哈哈哈哈" \
	version=1.1.2 \
	build=12

test-fangkebao-update:
	@swiftc fangkebao-update-json.swift
	@./fangkebao-update-json \
	newVersion=1.0.0 \
	newVersionCode=12 \
	minVersion=1.0.0 \
	minVersionCode=1 \
	secondHouseContent="1111" \
	newHouseContent="2222" \
	anchangContent="3333" \
	updateMode="FORCE" \
	output=./output/update-iOS.json


test-deploy-html:
	@cp app-center-index.html ./output/test-html/index.html

test-run-html:
	@cd ./output/test-html/ && pwd
	@anywhere -d ./output/test-html/ # 需要先安装 npm install -g anywher

# 清理编译生成文件
clean:
	@rm -rf test/ test-html/ output/
	@rm gen-package-json fangkebao-update-json



# 安装指令区
# 部署html
install-html:
	$(call checkDir, ${APP_CENTER_DIR})
	@cp app-center-index.html $(APP_CENTER_DIR)/index.html
	@echo "Command executed successfully!(install-html)"; \


#	@if [ ! -d ${WORK_DIR} ]; then mkdir -p ${WORK_DIR} && echo "$(WORK_DIR) does not exist! now create dir for you!" && cp app-center-index.html $(WORK_DIR)/index.html; fi

# 安装包索引记录生成程序
install-gen-package-json:
	@swiftc gen-package-json.swift
	$(call checkDir, ${CMD_DIR})
	@cp gen-package-json $(CMD_DIR)/gen-package-json
	@rm gen-package-json
	@echo "Command executed successfully!(install-gen-package-json)"

install-fangkebao-update-json:
	@swiftc fangkebao-update-json.swift
	@cp fangkebao-update-json $(CMD_DIR)/fangkebao-update-json
	@rm fangkebao-update-json
	@echo "Command executed successfully!(install-fangkebao-update-json)"

# 安装shell脚本
install-shell:
	$(call checkDir, ${ARCHIVE_SPACE_DIR})
	@cp build_with_fastlane.sh $(ARCHIVE_SPACE_DIR)/build_with_fastlane.sh
	@cp build_archive.sh $(ARCHIVE_SPACE_DIR)/build_archive.sh
	@echo "Command executed successfully!(install-shell)"
	
# 安装web服务
install-web:
	$(call checkDir, ${WEB_DIR})
	@cp -r web $(WEB_DIR)/web
	@echo "Command executed successfully!(install-web)"

define checkDir
	@if [ ! -d $(1) ]; then \
		echo "$(1) does not exist! Creating a directory for you!"; \
		mkdir -p $(1);  \
		echo "The directory($(1)) created successfully! "; \
    else \
		echo "The directory($(1)) exists !"; \
    fi
endef
