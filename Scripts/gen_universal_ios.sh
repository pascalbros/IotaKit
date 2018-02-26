#!/bin/sh

# Instructions:
# 1. Select "IotaKit-Package" scheme
# 2. Select "Simulator" and build
# 3. Select "Generic iOS Device" and build
# 4. Select Universal scheme (Generic iOS Device) and build
# 5. The lib will be copied to ~/Desktop/Frameworks/
set -e

FRAMEWORK=IotaKit

BUILD=~/.xcodebuild/$FRAMEWORK/build
FRAMEWORK_PATH=$FRAMEWORK.framework

rm -Rf $BUILD

if [[ "$SDK_NAME" =~ ([A-Za-z]+) ]]; then
RW_SDK_PLATFORM=${BASH_REMATCH[1]}
else
echo "Could not find platform name from SDK_NAME: $SDK_NAME"
exit 1
fi

# 3 - Determine the other platform
if [ "$RW_SDK_PLATFORM" == "iphoneos" ]; then
RW_OTHER_PLATFORM=iphonesimulator
else
RW_OTHER_PLATFORM=iphoneos
fi

# 4 - Find the build directory
if [[ "$BUILT_PRODUCTS_DIR" =~ (.*)$RW_SDK_PLATFORM$ ]]; then
RW_OTHER_BUILT_PRODUCTS_DIR="${BASH_REMATCH[1]}${RW_OTHER_PLATFORM}"
else
echo "Could not find other platform build directory."
exit 1
fi

mkdir -p "$BUILD/Release-universal/"
cp -RL "$BUILT_PRODUCTS_DIR/" "$BUILD/Release-universal"
cp -R "$RW_OTHER_BUILT_PRODUCTS_DIR/$FRAMEWORK_PATH/Modules/$FRAMEWORK.swiftmodule/" "$BUILD/Release-universal/$FRAMEWORK_PATH/Modules/$FRAMEWORK.swiftmodule"
lipo -create "$BUILT_PRODUCTS_DIR/$FRAMEWORK_PATH/$FRAMEWORK" "$RW_OTHER_BUILT_PRODUCTS_DIR/$FRAMEWORK_PATH/$FRAMEWORK" -output "$BUILD/Release-universal/$FRAMEWORK_PATH/$FRAMEWORK"

mkdir -p "${HOME}/Desktop/Frameworks/"
rm -rf "${HOME}/Desktop/Frameworks/$FRAMEWORK.framework"
cp -R "$BUILD/Release-universal/$FRAMEWORK_PATH" "${HOME}/Desktop/Frameworks/$FRAMEWORK.framework"
open "${HOME}/Desktop/Frameworks/"
