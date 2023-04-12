fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Configurations

配置调整涉及Appfile, Fastfile, ExportOptionsDevelopment.plish ExportOptionsAdhoc.plist, ExportOptionsRelease.plist

- Appfile 主要需要设置app_identifier，即实际项目的bundleID
- Fastfile 


# Available Actions

## iOS

### ios Test

```sh
[bundle exec] fastlane ios Test
```

测试环境打包

### ios Staging

```sh
[bundle exec] fastlane ios Staging
```

预发环境打包

### ios ProductAdhoc

```sh
[bundle exec] fastlane ios ProductAdhoc
```

线上环境打包

### ios Release

```sh
[bundle exec] fastlane ios Release
```

appstore打包

### ios Upload

```sh
[bundle exec] fastlane ios Upload
```

appstore上传

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
