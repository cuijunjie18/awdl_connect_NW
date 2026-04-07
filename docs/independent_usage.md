# 脱离 Xcode 独立编译、打包、运行方案

## 项目概述

`awdl_connect_oc` 是一个基于 OC/C 语言的 iOS 应用，使用 `NSNetService`（Bonjour）进行 AWDL 设备发现，并通过原生 BSD Socket（C 语言）进行 TCP 通信。

**项目关键信息：**

| 配置项 | 值 |
|---|---|
| Product Name | awdl_connect_oc |
| Bundle ID | wxg.junocui.awdl-connect-oc |
| Deployment Target | iOS 18.6 |
| Development Team | 6Y8DN793XB |
| 语言 | Objective-C + C |
| 依赖框架 | UIKit, Foundation, Network, os (均为系统框架) |
| 第三方依赖 | 无 |
| Storyboard | 无（纯代码 UI） |

---

## 方案一：xcodebuild 命令行编译（推荐）

这是最简单、最可靠的方案。`xcodebuild` 是 Xcode 自带的命令行工具，**不需要打开 Xcode IDE**，只需安装 Xcode Command Line Tools 即可。

### 1. 前置条件

```bash
# Ensure Xcode Command Line Tools are installed
xcode-select --install

# Verify installation
xcodebuild -version
```

### 2. 编译（Build）

```bash
cd /Users/junjiecui/workspace/Apple_Connect_tools/awdl_connect_oc

# Debug build for iOS device
xcodebuild \
  -project awdl_connect_oc.xcodeproj \
  -scheme awdl_connect_oc \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=6Y8DN793XB \
  build

# Debug build for iOS Simulator
xcodebuild \
  -project awdl_connect_oc.xcodeproj \
  -scheme awdl_connect_oc \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

### 3. 打包（Archive & Export IPA）

```bash
# Step 1: Archive
xcodebuild \
  -project awdl_connect_oc.xcodeproj \
  -scheme awdl_connect_oc \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=6Y8DN793XB \
  -archivePath ./build/awdl_connect_oc.xcarchive \
  archive

# Step 2: Create ExportOptions.plist (see below)

# Step 3: Export IPA
xcodebuild \
  -exportArchive \
  -archivePath ./build/awdl_connect_oc.xcarchive \
  -exportOptionsPlist ./build/ExportOptions.plist \
  -exportPath ./build/ipa
```

**ExportOptions.plist** 文件内容（保存到 `./build/ExportOptions.plist`）：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>6Y8DN793XB</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
```

### 4. 安装到设备并运行

```bash
# Method A: Use ios-deploy (recommended for command-line workflow)
# Install ios-deploy
brew install ios-deploy

# Install and launch app on connected device
ios-deploy --bundle ./build/ipa/awdl_connect_oc.ipa --debug

# Or install .app directly from build products
ios-deploy --bundle \
  ./build/awdl_connect_oc.xcarchive/Products/Applications/awdl_connect_oc.app

# Method B: Use Apple's devicectl (Xcode 15+)
xcrun devicectl device install app --device <DEVICE_UDID> \
  ./build/ipa/awdl_connect_oc.ipa

# Method C: Use ideviceinstaller (libimobiledevice)
brew install ideviceinstaller
ideviceinstaller -i ./build/ipa/awdl_connect_oc.ipa

# List connected devices
xcrun xctrace list devices
# Or
ios-deploy --detect
```

### 5. 在模拟器中运行

```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator
xcrun simctl boot "iPhone 16"

# Install app to simulator
xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/awdl_connect_oc-*/Build/Products/Debug-iphonesimulator/awdl_connect_oc.app

# Launch app
xcrun simctl launch booted "wxg.junocui.awdl-connect-oc"
```

---

## 方案二：一键构建脚本

将以下脚本保存为项目根目录下的 `build.sh`，实现一键编译、打包、安装：

```bash
#!/bin/bash
set -euo pipefail

# ============================================================
# awdl_connect_oc - Independent Build Script
# Usage:
#   ./build.sh build          - Build for device (Debug)
#   ./build.sh build-sim      - Build for simulator (Debug)
#   ./build.sh archive        - Archive and export IPA (Release)
#   ./build.sh install        - Install to connected device
#   ./build.sh run-sim        - Build, install and run on simulator
#   ./build.sh clean          - Clean build artifacts
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="awdl_connect_oc"
SCHEME="awdl_connect_oc"
BUNDLE_ID="wxg.junocui.awdl-connect-oc"
TEAM_ID="6Y8DN793XB"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
IPA_PATH="${BUILD_DIR}/ipa"
EXPORT_OPTIONS="${BUILD_DIR}/ExportOptions.plist"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

create_export_options() {
    mkdir -p "${BUILD_DIR}"
    cat > "${EXPORT_OPTIONS}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
    log_info "ExportOptions.plist created at ${EXPORT_OPTIONS}"
}

cmd_build() {
    log_info "Building ${PROJECT_NAME} for iOS device (Debug)..."
    xcodebuild \
        -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration Debug \
        -sdk iphoneos \
        -destination 'generic/platform=iOS' \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM="${TEAM_ID}" \
        SYMROOT="${BUILD_DIR}" \
        build
    log_info "Build succeeded! Output: ${BUILD_DIR}/Debug-iphoneos/${PROJECT_NAME}.app"
}

cmd_build_sim() {
    log_info "Building ${PROJECT_NAME} for iOS Simulator (Debug)..."
    xcodebuild \
        -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration Debug \
        -sdk iphonesimulator \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        SYMROOT="${BUILD_DIR}" \
        build
    log_info "Build succeeded! Output: ${BUILD_DIR}/Debug-iphonesimulator/${PROJECT_NAME}.app"
}

cmd_archive() {
    log_info "Archiving ${PROJECT_NAME} (Release)..."
    xcodebuild \
        -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -sdk iphoneos \
        -destination 'generic/platform=iOS' \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM="${TEAM_ID}" \
        -archivePath "${ARCHIVE_PATH}" \
        archive

    log_info "Archive succeeded! Exporting IPA..."
    create_export_options

    xcodebuild \
        -exportArchive \
        -archivePath "${ARCHIVE_PATH}" \
        -exportOptionsPlist "${EXPORT_OPTIONS}" \
        -exportPath "${IPA_PATH}"

    log_info "IPA exported to: ${IPA_PATH}/${PROJECT_NAME}.ipa"
}

cmd_install() {
    local APP_PATH="${BUILD_DIR}/Debug-iphoneos/${PROJECT_NAME}.app"
    if [ ! -d "${APP_PATH}" ]; then
        log_warn ".app not found, building first..."
        cmd_build
    fi

    if command -v ios-deploy &> /dev/null; then
        log_info "Installing via ios-deploy..."
        ios-deploy --bundle "${APP_PATH}" --justlaunch
    elif command -v xcrun &> /dev/null; then
        log_info "Installing via devicectl..."
        DEVICE_UDID=$(xcrun xctrace list devices 2>&1 | grep -v "Simulator" | grep -oE '[A-F0-9-]{25,}' | head -1)
        if [ -z "${DEVICE_UDID}" ]; then
            log_error "No connected device found"
            exit 1
        fi
        xcrun devicectl device install app --device "${DEVICE_UDID}" "${APP_PATH}"
    else
        log_error "Neither ios-deploy nor devicectl found. Install via: brew install ios-deploy"
        exit 1
    fi
}

cmd_run_sim() {
    cmd_build_sim
    local APP_PATH="${BUILD_DIR}/Debug-iphonesimulator/${PROJECT_NAME}.app"

    # Boot simulator if not running
    BOOTED=$(xcrun simctl list devices booted | grep -c "Booted" || true)
    if [ "${BOOTED}" -eq 0 ]; then
        log_info "Booting simulator..."
        xcrun simctl boot "iPhone 16" 2>/dev/null || true
        sleep 3
    fi

    log_info "Installing to simulator..."
    xcrun simctl install booted "${APP_PATH}"

    log_info "Launching app..."
    xcrun simctl launch booted "${BUNDLE_ID}"
}

cmd_clean() {
    log_info "Cleaning build artifacts..."
    rm -rf "${BUILD_DIR}"
    xcodebuild \
        -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        clean 2>/dev/null || true
    log_info "Clean completed"
}

# Main entry point
case "${1:-help}" in
    build)      cmd_build ;;
    build-sim)  cmd_build_sim ;;
    archive)    cmd_archive ;;
    install)    cmd_install ;;
    run-sim)    cmd_run_sim ;;
    clean)      cmd_clean ;;
    *)
        echo "Usage: $0 {build|build-sim|archive|install|run-sim|clean}"
        echo ""
        echo "Commands:"
        echo "  build       - Build for iOS device (Debug)"
        echo "  build-sim   - Build for iOS Simulator (Debug)"
        echo "  archive     - Archive and export IPA (Release)"
        echo "  install     - Install to connected iOS device"
        echo "  run-sim     - Build, install and run on Simulator"
        echo "  clean       - Clean all build artifacts"
        exit 1
        ;;
esac
```

---

## 方案三：Makefile 构建

如果你更习惯 `make` 工作流，可以使用以下 Makefile：

```makefile
PROJECT     = awdl_connect_oc
SCHEME      = awdl_connect_oc
BUNDLE_ID   = wxg.junocui.awdl-connect-oc
TEAM_ID     = 6Y8DN793XB
BUILD_DIR   = ./build
ARCHIVE     = $(BUILD_DIR)/$(PROJECT).xcarchive
IPA_DIR     = $(BUILD_DIR)/ipa

.PHONY: build build-sim archive install run-sim clean

build:
	xcodebuild \
		-project $(PROJECT).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Debug \
		-sdk iphoneos \
		-destination 'generic/platform=iOS' \
		CODE_SIGN_STYLE=Automatic \
		DEVELOPMENT_TEAM=$(TEAM_ID) \
		SYMROOT=$(BUILD_DIR) \
		build

build-sim:
	xcodebuild \
		-project $(PROJECT).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Debug \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=iPhone 16' \
		SYMROOT=$(BUILD_DIR) \
		build

archive:
	xcodebuild \
		-project $(PROJECT).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-sdk iphoneos \
		-destination 'generic/platform=iOS' \
		CODE_SIGN_STYLE=Automatic \
		DEVELOPMENT_TEAM=$(TEAM_ID) \
		-archivePath $(ARCHIVE) \
		archive
	xcodebuild \
		-exportArchive \
		-archivePath $(ARCHIVE) \
		-exportOptionsPlist $(BUILD_DIR)/ExportOptions.plist \
		-exportPath $(IPA_DIR)

install: build
	ios-deploy --bundle $(BUILD_DIR)/Debug-iphoneos/$(PROJECT).app --justlaunch

run-sim: build-sim
	xcrun simctl install booted $(BUILD_DIR)/Debug-iphonesimulator/$(PROJECT).app
	xcrun simctl launch booted $(BUNDLE_ID)

clean:
	rm -rf $(BUILD_DIR)
	xcodebuild -project $(PROJECT).xcodeproj -scheme $(SCHEME) clean
```

---

## 方案四：完全脱离 Xcode 工程文件（纯命令行 clang 编译）

> ⚠️ **此方案仅作参考**，适用于极端场景。由于本项目使用了 UIKit、NSNetService 等 iOS 框架，实际上仍需要 iOS SDK（随 Xcode 安装），但不需要 `.xcodeproj` 文件。

### 原理

直接使用 `clang` 编译器编译所有 `.m` 和 `.c` 文件，手动链接系统框架，生成可执行文件后打包为 `.app`。

### 源文件清单

```
awdl_connect_oc/main.m
awdl_connect_oc/AppDelegate.m
awdl_connect_oc/ViewController.m
awdl_connect_oc/models/Advertiser.m
awdl_connect_oc/models/Browser.m
awdl_connect_oc/utils/NetworkManager.m
awdl_connect_oc/services/TcpService.c
```

### 编译命令

```bash
# Set SDK path
SDK=$(xcrun --sdk iphoneos --show-sdk-path)
ARCH="arm64"
MIN_IOS="18.6"
BUILD_OUT="./build/manual"

mkdir -p "${BUILD_OUT}"

# Compile all source files and link into executable
xcrun clang \
  -arch ${ARCH} \
  -isysroot ${SDK} \
  -miphoneos-version-min=${MIN_IOS} \
  -fobjc-arc \
  -fmodules \
  -I awdl_connect_oc \
  -framework UIKit \
  -framework Foundation \
  -framework Network \
  awdl_connect_oc/main.m \
  awdl_connect_oc/AppDelegate.m \
  awdl_connect_oc/ViewController.m \
  awdl_connect_oc/models/Advertiser.m \
  awdl_connect_oc/models/Browser.m \
  awdl_connect_oc/utils/NetworkManager.m \
  awdl_connect_oc/services/TcpService.c \
  -o ${BUILD_OUT}/awdl_connect_oc

# Create .app bundle structure
APP_BUNDLE="${BUILD_OUT}/awdl_connect_oc.app"
mkdir -p "${APP_BUNDLE}"
cp "${BUILD_OUT}/awdl_connect_oc" "${APP_BUNDLE}/"
cp awdl_connect_oc/Info.plist "${APP_BUNDLE}/"

# Compile asset catalog (if needed)
xcrun actool awdl_connect_oc/Assets.xcassets \
  --compile "${APP_BUNDLE}" \
  --platform iphoneos \
  --minimum-deployment-target ${MIN_IOS} \
  --app-icon AppIcon \
  --accent-color AccentColor \
  --output-partial-info-plist "${BUILD_OUT}/assetcatalog_generated_info.plist"

# Code sign
codesign --force --sign "Apple Development: <YOUR_IDENTITY>" \
  --entitlements /dev/null \
  "${APP_BUNDLE}"
```

> 注意：此方案需要手动处理 Info.plist 合并、Asset Catalog 编译、代码签名等步骤，复杂度较高，**推荐使用方案一或方案二**。

---

## 方案对比

| 方案 | 复杂度 | 是否需要 Xcode 安装 | 是否需要打开 Xcode IDE | 适用场景 |
|---|---|---|---|---|
| **方案一：xcodebuild** | ⭐ 低 | ✅ 需要（仅 CLI Tools） | ❌ 不需要 | 日常开发、CI/CD |
| **方案二：build.sh 脚本** | ⭐ 低 | ✅ 需要（仅 CLI Tools） | ❌ 不需要 | 一键操作、团队协作 |
| **方案三：Makefile** | ⭐⭐ 中 | ✅ 需要（仅 CLI Tools） | ❌ 不需要 | 习惯 make 工作流 |
| **方案四：纯 clang** | ⭐⭐⭐ 高 | ✅ 需要（仅 SDK） | ❌ 不需要 | 极端场景、学习原理 |

---

## CI/CD 集成示例（GitHub Actions）

```yaml
name: Build iOS App

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app

      - name: Build
        run: |
          xcodebuild \
            -project awdl_connect_oc.xcodeproj \
            -scheme awdl_connect_oc \
            -configuration Release \
            -sdk iphoneos \
            -destination 'generic/platform=iOS' \
            CODE_SIGN_STYLE=Manual \
            CODE_SIGNING_ALLOWED=NO \
            build

      - name: Archive
        run: |
          xcodebuild \
            -project awdl_connect_oc.xcodeproj \
            -scheme awdl_connect_oc \
            -configuration Release \
            -sdk iphoneos \
            -destination 'generic/platform=iOS' \
            CODE_SIGN_STYLE=Manual \
            CODE_SIGNING_ALLOWED=NO \
            -archivePath ./build/awdl_connect_oc.xcarchive \
            archive
```

---

## 常用命令速查

```bash
# List connected devices
xcrun xctrace list devices

# List available simulators
xcrun simctl list devices available

# Check code signing identity
security find-identity -v -p codesigning

# View provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# Check build settings
xcodebuild -project awdl_connect_oc.xcodeproj \
  -scheme awdl_connect_oc \
  -showBuildSettings

# List available schemes
xcodebuild -project awdl_connect_oc.xcodeproj -list
```

---

## 注意事项

1. **Xcode CLI Tools 是必须的**：即使不打开 Xcode IDE，iOS 应用编译仍然依赖 Apple 提供的 SDK 和工具链（`clang`、`ld`、`codesign`、`actool` 等），这些工具随 Xcode 安装。目前没有任何第三方工具链可以完全替代。

2. **代码签名**：安装到真机需要有效的开发者证书和 Provisioning Profile。使用 `CODE_SIGN_STYLE=Automatic` 配合 `DEVELOPMENT_TEAM` 可以自动管理签名（前提是本机已登录过 Apple Developer 账号）。

3. **AWDL 限制**：AWDL（Apple Wireless Direct Link）功能仅在真机上可用，模拟器不支持 `awdl0` 接口。因此测试 Bonjour P2P 发现和 TCP 通信功能必须使用真机。

4. **本地网络权限**：`Info.plist` 中已配置 `NSLocalNetworkUsageDescription` 和 `NSBonjourServices`，首次运行时系统会弹出本地网络访问权限请求。

5. **无第三方依赖**：本项目不依赖 CocoaPods、SPM 或 Carthage，所有框架均为系统内置，简化了命令行构建流程。
