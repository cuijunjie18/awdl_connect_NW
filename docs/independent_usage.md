# 脱离 Xcode 独立编译、打包与运行 awdl_NW

## 项目概况

| 项目属性 | 值 |
|---|---|
| 产品类型 | iOS App (.app) |
| 语言 | Swift 5.0 + C (Bridging Header) |
| UI 框架 | SwiftUI |
| 最低部署版本 | iOS 18.6 |
| Bundle ID | `wxg.junocui.awdl-NW` |
| 开发团队 | `6Y8DN793XB` |

## 前提条件

无论使用哪种方案，都需要满足以下条件：

1. **macOS 系统** — Apple 工具链仅在 macOS 上可用
2. **Xcode Command Line Tools** — 即使不打开 Xcode GUI，也需要安装命令行工具（包含 `xcodebuild`、`swift`、`clang` 等）
3. **有效的 Apple 开发者证书** — 真机运行需要代码签名
4. **已安装对应的 iOS SDK** — 通常随 Xcode 一起安装

```bash
# Install Command Line Tools (if not already installed)
xcode-select --install

# Verify installation
xcodebuild -version
swift --version
```

> **重要说明**：由于本项目是 iOS 应用（非 macOS），无法完全脱离 Apple 工具链。以下方案的核心目标是 **脱离 Xcode GUI**，通过命令行完成全部流程。

---

## 方案一：xcodebuild 命令行编译（推荐）

这是最简单、最可靠的方案。直接复用现有的 `.xcodeproj` 工程文件，通过命令行调用 `xcodebuild` 完成编译、打包和安装。

### 1.1 编译（Build）

```bash
# Debug build for simulator
xcodebuild build \
  -project awdl_NW.xcodeproj \
  -scheme awdl_NW \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath ./build

# Debug build for real device
xcodebuild build \
  -project awdl_NW.xcodeproj \
  -scheme awdl_NW \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath ./build

# Release build for real device
xcodebuild build \
  -project awdl_NW.xcodeproj \
  -scheme awdl_NW \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath ./build
```

编译产物位于：`./build/Build/Products/Debug-iphoneos/awdl_NW.app`（或对应的配置目录）

### 1.2 打包为 IPA

```bash
# Step 1: Archive
xcodebuild archive \
  -project awdl_NW.xcodeproj \
  -scheme awdl_NW \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath ./build/awdl_NW.xcarchive

# Step 2: Create ExportOptions.plist (for development distribution)
cat > ./build/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
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
EOF

# Step 3: Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/awdl_NW.xcarchive \
  -exportPath ./build/ipa \
  -exportOptionsPlist ./build/ExportOptions.plist
```

最终 IPA 文件位于：`./build/ipa/awdl_NW.ipa`

### 1.3 安装到真机

```bash
# Method 1: Using ios-deploy (recommended)
# Install ios-deploy
brew install ios-deploy

# Install app to connected device
ios-deploy --bundle ./build/Build/Products/Debug-iphoneos/awdl_NW.app

# Install and launch with debug output
ios-deploy --bundle ./build/Build/Products/Debug-iphoneos/awdl_NW.app --debug

# Method 2: Using Apple's devicectl (Xcode 15+)
xcrun devicectl device install app --device <DEVICE_UDID> ./build/Build/Products/Debug-iphoneos/awdl_NW.app

# Method 3: Install IPA using ideviceinstaller
brew install ideviceinstaller
ideviceinstaller -i ./build/ipa/awdl_NW.ipa
```

### 1.4 在模拟器中运行

```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator
xcrun simctl boot "iPhone 16"

# Install app to simulator
xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/awdl_NW.app

# Launch app
xcrun simctl launch booted wxg.junocui.awdl-NW

# View logs
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.awdl.nw"'
```

### 1.5 一键脚本

在项目根目录创建 `build.sh`：

```bash
#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
SCHEME="awdl_NW"
PROJECT="${PROJECT_DIR}/awdl_NW.xcodeproj"

usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  build-sim        Build for iOS Simulator"
    echo "  build-device     Build for real device"
    echo "  archive          Archive and export IPA"
    echo "  run-sim          Build and run on Simulator"
    echo "  install-device   Build and install on connected device"
    echo "  clean            Clean build artifacts"
    echo ""
    echo "Options:"
    echo "  --release        Use Release configuration (default: Debug)"
    echo "  --simulator NAME Specify simulator name (default: iPhone 16)"
}

CONFIG="Debug"
SIM_NAME="iPhone 16"

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        build-sim|build-device|archive|run-sim|install-device|clean)
            COMMAND=$1; shift ;;
        --release)
            CONFIG="Release"; shift ;;
        --simulator)
            SIM_NAME="$2"; shift 2 ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

case "$COMMAND" in
    build-sim)
        echo "🔨 Building for Simulator ($CONFIG)..."
        xcodebuild build \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration "$CONFIG" \
            -destination "platform=iOS Simulator,name=${SIM_NAME}" \
            -derivedDataPath "$BUILD_DIR" \
            | tail -20
        echo "✅ Build succeeded: ${BUILD_DIR}/Build/Products/${CONFIG}-iphonesimulator/awdl_NW.app"
        ;;
    build-device)
        echo "🔨 Building for Device ($CONFIG)..."
        xcodebuild build \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration "$CONFIG" \
            -destination 'generic/platform=iOS' \
            -derivedDataPath "$BUILD_DIR" \
            | tail -20
        echo "✅ Build succeeded: ${BUILD_DIR}/Build/Products/${CONFIG}-iphoneos/awdl_NW.app"
        ;;
    archive)
        echo "📦 Archiving ($CONFIG)..."
        xcodebuild archive \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration Release \
            -destination 'generic/platform=iOS' \
            -archivePath "${BUILD_DIR}/awdl_NW.xcarchive"

        cat > "${BUILD_DIR}/ExportOptions.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>6Y8DN793XB</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST

        xcodebuild -exportArchive \
            -archivePath "${BUILD_DIR}/awdl_NW.xcarchive" \
            -exportPath "${BUILD_DIR}/ipa" \
            -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist"
        echo "✅ IPA exported: ${BUILD_DIR}/ipa/awdl_NW.ipa"
        ;;
    run-sim)
        echo "🚀 Building and running on Simulator..."
        xcodebuild build \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration "$CONFIG" \
            -destination "platform=iOS Simulator,name=${SIM_NAME}" \
            -derivedDataPath "$BUILD_DIR" \
            | tail -5
        xcrun simctl boot "${SIM_NAME}" 2>/dev/null || true
        xcrun simctl install booted "${BUILD_DIR}/Build/Products/${CONFIG}-iphonesimulator/awdl_NW.app"
        xcrun simctl launch booted wxg.junocui.awdl-NW
        echo "✅ App launched on ${SIM_NAME}"
        ;;
    install-device)
        echo "📱 Building and installing on device..."
        xcodebuild build \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -configuration "$CONFIG" \
            -destination 'generic/platform=iOS' \
            -derivedDataPath "$BUILD_DIR" \
            | tail -5
        ios-deploy --bundle "${BUILD_DIR}/Build/Products/${CONFIG}-iphoneos/awdl_NW.app"
        echo "✅ App installed on device"
        ;;
    clean)
        echo "🧹 Cleaning..."
        rm -rf "$BUILD_DIR"
        xcodebuild clean -project "$PROJECT" -scheme "$SCHEME" 2>/dev/null || true
        echo "✅ Clean completed"
        ;;
    *)
        usage; exit 1 ;;
esac
```

使用方式：

```bash
chmod +x build.sh

./build.sh build-sim                    # Build for simulator
./build.sh build-device --release       # Release build for device
./build.sh run-sim --simulator "iPhone 16"  # Build & run on simulator
./build.sh archive                      # Archive and export IPA
./build.sh install-device               # Build & install on device
./build.sh clean                        # Clean build artifacts
```

---

## 方案二：Makefile 封装

对于习惯使用 `make` 的开发者，可以用 Makefile 封装 xcodebuild 命令：

```makefile
# Makefile for awdl_NW
PROJECT    := awdl_NW.xcodeproj
SCHEME     := awdl_NW
BUILD_DIR  := ./build
CONFIG     ?= Debug
SIM_NAME   ?= iPhone 16
TEAM_ID    := 6Y8DN793XB
BUNDLE_ID  := wxg.junocui.awdl-NW

.PHONY: build-sim build-device archive run-sim install clean

build-sim:
	xcodebuild build \
		-project $(PROJECT) -scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-destination 'platform=iOS Simulator,name=$(SIM_NAME)' \
		-derivedDataPath $(BUILD_DIR)

build-device:
	xcodebuild build \
		-project $(PROJECT) -scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-destination 'generic/platform=iOS' \
		-derivedDataPath $(BUILD_DIR)

archive:
	xcodebuild archive \
		-project $(PROJECT) -scheme $(SCHEME) \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-archivePath $(BUILD_DIR)/awdl_NW.xcarchive
	@echo '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0">\n<dict>\n<key>method</key>\n<string>development</string>\n<key>teamID</key>\n<string>$(TEAM_ID)</string>\n<key>signingStyle</key>\n<string>automatic</string>\n</dict>\n</plist>' > $(BUILD_DIR)/ExportOptions.plist
	xcodebuild -exportArchive \
		-archivePath $(BUILD_DIR)/awdl_NW.xcarchive \
		-exportPath $(BUILD_DIR)/ipa \
		-exportOptionsPlist $(BUILD_DIR)/ExportOptions.plist

run-sim: build-sim
	xcrun simctl boot "$(SIM_NAME)" 2>/dev/null || true
	xcrun simctl install booted $(BUILD_DIR)/Build/Products/$(CONFIG)-iphonesimulator/awdl_NW.app
	xcrun simctl launch booted $(BUNDLE_ID)

install: build-device
	ios-deploy --bundle $(BUILD_DIR)/Build/Products/$(CONFIG)-iphoneos/awdl_NW.app

clean:
	rm -rf $(BUILD_DIR)
	xcodebuild clean -project $(PROJECT) -scheme $(SCHEME) 2>/dev/null || true
```

使用方式：

```bash
make build-sim                          # Build for simulator
make build-device CONFIG=Release        # Release build for device
make run-sim SIM_NAME="iPhone 16 Pro"   # Build & run on simulator
make archive                            # Archive and export IPA
make install                            # Build & install on device
make clean                              # Clean
```

---

## 方案三：Fastlane 自动化（适合 CI/CD）

[Fastlane](https://fastlane.tools/) 是 iOS/Android 自动化构建的行业标准工具，适合持续集成场景。

### 3.1 安装 Fastlane

```bash
# Via Homebrew
brew install fastlane

# Or via RubyGems
gem install fastlane
```

### 3.2 初始化

```bash
cd /Users/junjiecui/workspace/Apple_Connect_tools/awdl_NW
fastlane init
```

### 3.3 配置 Fastfile

在项目根目录创建 `fastlane/Fastfile`：

```ruby
default_platform(:ios)

platform :ios do
  desc "Build for simulator"
  lane :build_sim do
    build_app(
      project: "awdl_NW.xcodeproj",
      scheme: "awdl_NW",
      configuration: "Debug",
      destination: "platform=iOS Simulator,name=iPhone 16",
      derived_data_path: "./build",
      skip_archive: true,
      skip_codesigning: true
    )
  end

  desc "Build and archive for device"
  lane :build_device do
    build_app(
      project: "awdl_NW.xcodeproj",
      scheme: "awdl_NW",
      configuration: "Release",
      export_method: "development",
      output_directory: "./build/ipa",
      output_name: "awdl_NW.ipa"
    )
  end

  desc "Install on connected device"
  lane :install do
    build_device
    install_on_device(
      ipa: "./build/ipa/awdl_NW.ipa"
    )
  end
end
```

使用方式：

```bash
fastlane build_sim
fastlane build_device
fastlane install
```

---

## 方案对比

| 特性 | 方案一: xcodebuild | 方案二: Makefile | 方案三: Fastlane |
|---|---|---|---|
| 安装复杂度 | ⭐ 零额外安装 | ⭐ 零额外安装 | ⭐⭐⭐ 需安装 Ruby/Fastlane |
| 学习成本 | ⭐⭐ 需了解 xcodebuild 参数 | ⭐ 封装后简单 | ⭐⭐ 需学习 Fastlane DSL |
| 灵活性 | ⭐⭐⭐ 完全控制 | ⭐⭐ 通过变量控制 | ⭐⭐⭐ 插件生态丰富 |
| CI/CD 适配 | ⭐⭐ 需自行编写脚本 | ⭐⭐ 需自行编写脚本 | ⭐⭐⭐ 原生支持 |
| 推荐场景 | 个人开发、快速调试 | 团队开发、习惯 make | CI/CD 流水线 |

---

## 特殊说明：Swift-C 混编的注意事项

本项目使用了 **Bridging Header** (`awdl_NW/C_services/awdl_NW-Bridging-Header.h`) 来桥接 C 代码到 Swift。在命令行编译时需要注意：

1. **xcodebuild 方案**：Bridging Header 路径已在 `project.pbxproj` 中通过 `SWIFT_OBJC_BRIDGING_HEADER` 配置，无需额外处理
2. 如果遇到 Bridging Header 找不到的问题，确认路径设置：
   ```
   SWIFT_OBJC_BRIDGING_HEADER = awdl_NW/C_services/awdl_NW-Bridging-Header.h
   ```

---

## 特殊说明：AWDL 功能的限制

由于本项目依赖 **AWDL（Apple Wireless Direct Link）** 协议：

- ❌ **模拟器不支持 AWDL** — Advertiser/Browser 的核心功能只能在真机上测试
- ✅ 模拟器可以验证 UI 和基本逻辑
- ✅ 真机测试需要两台 iOS 设备

---

## 常用调试命令

```bash
# List connected devices
xcrun xctrace list devices

# View real-time device logs (filtered by app)
xcrun devicectl device process logstream --device <UDID> --predicate 'subsystem == "com.awdl.nw"'

# View simulator logs
xcrun simctl spawn booted log stream --level debug --predicate 'subsystem == "com.awdl.nw"'

# List available schemes
xcodebuild -project awdl_NW.xcodeproj -list

# Show build settings
xcodebuild -project awdl_NW.xcodeproj -scheme awdl_NW -showBuildSettings
```

---

## 总结

**推荐方案**：对于本项目，使用 **方案一（xcodebuild 命令行）+ build.sh 脚本** 是最佳选择。原因：

1. 项目结构简单，无需复杂的构建系统
2. 零额外依赖，只需 Xcode Command Line Tools
3. 完整复用现有的 `.xcodeproj` 配置（包括 Bridging Header、签名设置等）
4. 通过 `build.sh` 脚本封装后，日常使用非常便捷

> ⚠️ **注意**：虽然可以脱离 Xcode GUI，但无法完全脱离 Apple 工具链（xcodebuild、xcrun 等）。iOS 应用的编译、签名、打包都依赖 Apple 提供的工具，这是 Apple 生态的固有限制。
