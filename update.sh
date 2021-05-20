#!/usr/bin/env bash

VALUE=${1?Error: no number given}
carthage build --no-skip-current --use-xcframeworks
echo "Created build for Carthage!"

git add .
git commit -m "update version to $VALUE"
git push -u origin master
git tag $VALUE
git push origin $VALUE
pod trunk push