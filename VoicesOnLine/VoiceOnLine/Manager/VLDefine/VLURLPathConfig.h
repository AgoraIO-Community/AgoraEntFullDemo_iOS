//
//  VLURLPathConfig.h
//  VoiceOnLine
//

#ifndef VLURLPathConfig_h
#define VLURLPathConfig_h

//通知的字符串
static NSString * const kExitRoomNotification = @"exitRoomNotification";
static NSString * const kDianGeSuccessNotification = @"DianGeSuccessNotification";
static NSString * const kMakeTopNotification = @"MakeTopNotification";
static NSString * const kDeleteSuccessNotification = @"DeleteSuccessNotification";

#pragma mark - API
static NSString * const kURLPathUploadImage = @"/upload"; //上传图片
static NSString * const kURLPathDestroyUser = @"/users/cancellation"; //注销用户
static NSString * const kURLPathGetUserInfo = @"/users/getUserInfo"; //获取用户信息
static NSString * const kURLPathLogin = @"/users/login"; // 登录
static NSString * const kURLPathLogout = @"/users/logout"; // 退出登录 （接口文档未完成）
static NSString * const kURLPathUploadUserInfo = @"/users/update";  //修改用户信息
static NSString * const kURLPathVerifyCode = @"/users/verificationCode"; //发送验证码
static NSString * const kURLCreateRoom = @"/roomInfo/createRoom";
static NSString * const kURLGetRoolList = @"/roomInfo/roomList";
static NSString * const kURLGetSongsList = @"/songs/getListPage"; //获取歌曲列表
static NSString * const kURLChoosedSongs = @"/roomSong/haveOrderedList"; //已点歌曲列表
static NSString * const kURLSongDetail = @"/songs/getSongOnline";  //歌曲详情
static NSString * const kURLChooseSong = @"/roomSong/chooseSong";  //点歌
static NSString * const kURLGetInRoom = @"/roomInfo/getRoomInfo";  //进入房间
static NSString * const kURLRoomOnSeat = @"/roomInfo/onSeat";      //上麦
static NSString * const kURLRoomDropSeat = @"/roomInfo/outSeat";   //下麦
static NSString * const kURLRoomClose = @"/roomInfo/closeRoom";    //关闭房间
static NSString * const kURLRoomOut = @"/roomInfo/outRoom";        //退出房间
static NSString * const kURLRoomMakeSongTop = @"/roomSong/toDevelop"; //置顶歌曲
static NSString * const kURLDeleteSong = @"/roomSong/delSong";   //删除歌曲
static NSString * const kURLBeginSinging = @"/roomSong/begin";   //开始唱歌
static NSString * const kURLIfSetMute = @"/roomUsers/ifQuiet";   //是否静音
static NSString * const kURLIfOpenVido = @"/roomUsers/openCamera"; //是否开启摄像头
static NSString * const kURLUpdataRoom = @"/roomInfo/updateRoom";   //更新房间信息
static NSString * const kURLGetRTMToken = @"/users/getToken"; //获取RTM Token

#pragma mark - H5相关
static NSString * const kURLPathH5UserAgreement = @"https://www.agora.io/cn/about-us/";
static NSString * const kURLPathH5Privacy = @"https://www.agora.io/cn/about-us/";
static NSString * const kURLPathH5AboutUS = @"https://www.agora.io/cn/about-us/";



#endif /* VLURLPathConfig_h */
