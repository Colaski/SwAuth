#!/bin/bash
xcodebuild docbuild -scheme SwAuth-Package -derivedDataPath ./BuildFiles
cp -R ./BuildFiles/Build/Products/Debug/SwAuth.doccarchive ./docs
rm -rf ./BuildFiles/Build

echo "Updated docs"