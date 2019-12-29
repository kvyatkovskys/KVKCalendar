#!/usr/bin/env bash

VALUE=${1?Error: no number given}
carthage build --no-skip-current
echo "Build for Carthage!"

git commit -m "update version to $VALUE"
git tag $VALUE
git push origin $VALUE
pod lib lint
pod trunk push
echo "Build for CocoaPods!"