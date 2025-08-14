#!/bin/bash

VERSION=$(cat MIDIEventViewer.xcodeproj/project.pbxproj | \
          grep -m1 'MARKETING_VERSION' | cut -d'=' -f2 | \
          tr -d ';' | tr -d ' ')
ARCHIVE_DIR=/Users/Larry/Library/Developer/Xcode/Archives/CommandLine

rm -f make.log
touch make.log
rm -rf build

echo "Building MIDIEventViewer" 2>&1 | tee -a make.log

xcodebuild -project MIDIEventViewer.xcodeproj clean 2>&1 | tee -a make.log
xcodebuild -project MIDIEventViewer.xcodeproj \
    -scheme "MIDIEventViewer Release" -archivePath MIDIEventViewer.xcarchive \
    archive 2>&1 | tee -a make.log

rm -rf ${ARCHIVE_DIR}/MIDIEventViewer-v${VERSION}.xcarchive
cp -rf MIDIEventViewer.xcarchive ${ARCHIVE_DIR}/MIDIEventViewer-v${VERSION}.xcarchive

