# Agora泛娱乐FullDemo

## 说明

本项目目标为声网泛娱乐场景进行全方位demo，当前已支持在线K歌房Demo，未来将支持元语聊、元直播、互动游戏的场景

## 配置与编译

### 配置项目

* 打开`VLConfig.h`
* 修改`HOST`为服务器后台地址
* 修改`AGORA_APP_ID`为声网APP ID
* 修改`AGORA_APP_CERTIFICATE`为声网证书token

### 编译项目

* 使用XCode(12.0以上版本)，打开`VoicesOnline/VoicesOnline.xcworkspace`，点击编译，即可开始编译

本项目因涉及到较多的音视频处理操作，因此最好在真机调试运行，否则某些场景可能无法运行。