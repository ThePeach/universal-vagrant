#!/bin/bash

echo -e "\n--- Installing Yii 1.1 ---\n"
cd /
rm -rf yii*
wget -q https://github.com/yiisoft/yii/releases/download/1.1.14/yii-1.1.14.f0fee9.tar.gz
tar -xpf yii-1.1.14.f0fee9.tar.gz
rm yii-1.1.14.f0fee9.tar.gz

