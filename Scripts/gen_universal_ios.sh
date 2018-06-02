#!/bin/sh

set -e

FRAMEWORK=IotaKit

BUILD=build
FRAMEWORK_PATH=$FRAMEWORK.framework
OUTPUT_PATH=${HOME}/Desktop/Frameworks
cd ..

rm -Rf $BUILD
rm -f $FRAMEWORK.framework.tar.gz

xcodebuild archive -project $FRAMEWORK.xcodeproj -scheme $FRAMEWORK-Package -sdk iphoneos SYMROOT=$BUILD
xcodebuild build -configuration Release -project $FRAMEWORK.xcodeproj -target $FRAMEWORK -sdk iphonesimulator SYMROOT=$BUILD

cp -RL $BUILD/Release-iphoneos $BUILD/Release-universal
cp -RL $BUILD/Release-iphonesimulator/$FRAMEWORK_PATH/Modules/$FRAMEWORK.swiftmodule/* $BUILD/Release-universal/$FRAMEWORK_PATH/Modules/$FRAMEWORK.swiftmodule

lipo -create $BUILD/Release-iphoneos/$FRAMEWORK_PATH/$FRAMEWORK $BUILD/Release-iphonesimulator/$FRAMEWORK_PATH/$FRAMEWORK -output $BUILD/Release-universal/$FRAMEWORK_PATH/$FRAMEWORK

tar -czv -C $BUILD/Release-universal -f $FRAMEWORK.tar.gz $FRAMEWORK_PATH $FRAMEWORK_PATH.dSYM

mkdir -p $OUTPUT_PATH
rm -rf $OUTPUT_PATH/$FRAMEWORK
cp -R $BUILD/Release-universal/ $OUTPUT_PATH/$FRAMEWORK
rm -Rf $BUILD
open $OUTPUT_PATH