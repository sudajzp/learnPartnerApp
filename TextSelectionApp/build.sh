#!/bin/bash

# 获取当前脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 编译脚本
echo "Building LearnPartner..."

# 确保捆绑包目录结构存在
mkdir -p "$SCRIPT_DIR/LearnPartner.app/Contents/MacOS" "$SCRIPT_DIR/LearnPartner.app/Contents/Resources" "$SCRIPT_DIR/LearnPartner.app/Contents/Library/Python"

# 收集所有Swift源文件
SWIFT_FILES=$(find "$SCRIPT_DIR/Sources" -name "*.swift" | tr '\n' ' ')

echo "Compiling Swift files from: $SCRIPT_DIR/Sources"
echo "Files: $SWIFT_FILES"

# 使用swiftc编译到捆绑包目录
swiftc -o "$SCRIPT_DIR/LearnPartner.app/Contents/MacOS/LearnPartner" $SWIFT_FILES -framework Cocoa -framework Foundation -framework WebKit -framework Security -suppress-warnings

if [ $? -eq 0 ]; then
    # 复制Info.plist到捆绑包
    cp "$SCRIPT_DIR/Info.plist" "$SCRIPT_DIR/LearnPartner.app/Contents/"
    
    # 创建PkgInfo文件
    echo 'APPL????' > "$SCRIPT_DIR/LearnPartner.app/Contents/PkgInfo"
    
    # 复制图标文件到Resources目录
    if [ -f "$SCRIPT_DIR/resource/AppIcon.icns" ]; then
        cp "$SCRIPT_DIR/resource/AppIcon.icns" "$SCRIPT_DIR/LearnPartner.app/Contents/Resources/"
        echo "Main icon copied to bundle"
    fi
    
    # 复制状态栏图标到Resources目录
    if [ -f "$SCRIPT_DIR/resource/StatusIcon.png" ]; then
        cp "$SCRIPT_DIR/resource/StatusIcon.png" "$SCRIPT_DIR/LearnPartner.app/Contents/Resources/"
        echo "Status bar icon copied to bundle"
    fi
    
    # 复制深色版状态栏图标到Resources目录
    if [ -f "$SCRIPT_DIR/resource/StatusIconDark.png" ]; then
        cp "$SCRIPT_DIR/resource/StatusIconDark.png" "$SCRIPT_DIR/LearnPartner.app/Contents/Resources/"
        echo "Dark mode status bar icon copied to bundle"
    fi
    
    # 安装Python依赖到应用包中
    echo "Installing Python dependencies..."
    pip3 install --target="$SCRIPT_DIR/LearnPartner.app/Contents/Library/Python" requests
    
    # 复制翻译脚本到Resources目录
    if [ -f "$SCRIPT_DIR/PythonScripts/translate.py" ]; then
        cp "$SCRIPT_DIR/PythonScripts/translate.py" "$SCRIPT_DIR/LearnPartner.app/Contents/Resources/"
        chmod +x "$SCRIPT_DIR/LearnPartner.app/Contents/Resources/translate.py"
        echo "Translation script copied to bundle"
    fi
    
    # 创建DMG安装包
    echo "Creating DMG package..."
    
    # 清理旧的DMG文件
    rm -f "$SCRIPT_DIR/LearnPartner.dmg"
    
    # 创建临时DMG目录
    DMG_DIR="$SCRIPT_DIR/LearnPartner_DMG"
    rm -rf "$DMG_DIR"
    mkdir -p "$DMG_DIR"
    
    # 复制应用到临时目录
    cp -r "$SCRIPT_DIR/LearnPartner.app" "$DMG_DIR/"
    
    # 创建背景图片目录（可选）
    mkdir -p "$DMG_DIR/.background"
    
    # 为DMG创建一个链接到Applications
    ln -s /Applications "$DMG_DIR/Applications"
    
    # 创建DMG文件
    hdiutil create -volname "LearnPartner" -srcfolder "$DMG_DIR" -ov -format UDZO "$SCRIPT_DIR/LearnPartner.dmg"
    
    # 清理临时目录
    rm -rf "$DMG_DIR"
    
    echo "Build successful!"
    echo "DMG package created: $SCRIPT_DIR/LearnPartner.dmg"
    echo "To install: Double-click LearnPartner.dmg and drag LearnPartner.app to Applications"
    echo "Note: You may need to grant accessibility permissions in System Preferences > Security & Privacy > Accessibility"
else
    echo "Build failed!"
    exit 1
fi
