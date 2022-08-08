//
//  VLKTVViewController.m
//  VoiceOnLine
//

#import "VLKTVViewController.h"
#import "VLKTVTopView.h"
#import "VLKTVMVView.h"
#import "VLRoomPersonView.h"
#import "VLKTVBottomView.h"
#import "VLTouristOnLineView.h"
#import "VLBelcantoModel.h"
#import "VLNoBodyOnLineView.h"
#import "VLOnLineListVC.h"
//弹框视图
#import "VLPopSelBgView.h"
#import "VLPopMoreSelView.h"
#import "VLDropOnLineView.h"
#import "VLPopOnLineTypeView.h"
#import "VLChooseBelcantoView.h"
#import "VLPopChooseSongView.h"
#import "VLsoundEffectView.h"
#import "VLBadNetWorkView.h"
#import <AgoraRtcKit/AgoraRtcKit.h>

#import "VLKTVSettingView.h"
#import "YGViewDisplayer.h"
//model
#import "VLSongItmModel.h"
#import "VLRoomListModel.h"
#import "AgoraRtm.h"
#import "VLRoomSeatModel.h"
#import "VLRoomSelSongModel.h"
#import "VLKTVSelBgModel.h"
#import "RtcMusicLrcMessage.h"
#import "UIViewController+VL.h"
#import "VLPopScoreView.h"
#import "VLConfig.h"
#import "AgoraRtcKit/AgoraMusicContentCenter.h"

typedef void (^sendStreamSuccess)(BOOL ifSuccess);

typedef enum : NSUInteger {
    VLSendMessageTypeOnSeat = 0,         // 上麦
    VLSendMessageTypeDropSeat = 1,       // 下麦
    VLSendMessageTypeChooseSong = 2,     // 点歌
    VLSendMessageTypeChangeSong = 3,     // 切歌
    VLSendMessageTypeCloseRoom = 4,      // 关闭房间
    VLSendMessageTypeChangeMVBg = 5,     // 切换MV背景

    VLSendMessageTypeAudioMute= 9,      // 静音
    VLSendMessageTypeVideoIfOpen = 10,    // 摄像头
    VLSendMessageTypeTellSingerSomeBodyJoin = 11, //通知主唱有人加入合唱
    VLSendMessageTypeTellJoinUID = 12, //通知合唱者 主唱UID
    VLSendMessageTypeSoloSong = 13,  //独唱
    VLSendMessageTypeSeeScore = 14   //观众看到分数
    
} VLSendMessageType;

static NSInteger streamId = -1;

@interface VLKTVViewController ()<VLKTVTopViewDelegate,VLKTVMVViewDelegate,VLRoomPersonViewDelegate,VLKTVBottomViewDelegate,VLPopSelBgViewDelegate,VLPopMoreSelViewDelegate,VLDropOnLineViewDelegate,VLTouristOnLineViewDelegate,VLPopOnLineTypeViewDelegate,VLChooseBelcantoViewDelegate,VLPopChooseSongViewDelegate,VLsoundEffectViewDelegate,VLKTVSettingViewDelegate,VLBadNetWorkViewDelegate,AgoraRtmDelegate,AgoraRtmChannelDelegate,AgoraRtcMediaPlayerDelegate,AgoraRtcEngineDelegate, AgoraMusicContentCenterEventHandler>

@property (nonatomic, strong) VLKTVMVView *MVView;
@property (nonatomic, strong) VLKTVSelBgModel *choosedBgModel;
@property (nonatomic, strong) VLKTVBottomView *bottomView;
@property (nonatomic, strong) VLBelcantoModel *selBelcantoModel;
@property (nonatomic, strong) VLNoBodyOnLineView *noBodyOnLineView; // mv空页面
@property (nonatomic, strong) LSTPopView *popSelBgView;       //切换MV背景
@property (nonatomic, strong) VLKTVTopView *topView;
@property (nonatomic, strong) LSTPopView *popMoreView;        //更多视图
@property (nonatomic, strong) LSTPopView *dropLineView;       //下麦视图
@property (nonatomic, strong) LSTPopView *popOnLineTypeView;  //上麦类型视图
@property (nonatomic, strong) LSTPopView *belcantoView;       //美声视图
@property (nonatomic, strong) LSTPopView *popChooseSongView;  //点歌
@property (nonatomic, strong) LSTPopView *popSoundEffectView; //音效设置
@property (nonatomic, strong) LSTPopView *popBadNetWorkView;  //网络差视图
@property (nonatomic, strong) VLKTVSettingView *settingView;
@property (nonatomic, strong) VLRoomPersonView *roomPersonView; //房间麦位视图
@property (nonatomic, strong) VLTouristOnLineView *requestOnLineView;//空位上麦
@property (nonatomic, strong)  VLPopChooseSongView *chooseSongView; //点歌视图

@property (nonatomic, strong) AgoraRtmChannel *rtmChannel;
@property (nonatomic, strong) NSArray *selSongsArray;
//@property (nonatomic, weak) id<AgoraRtcMediaPlayerProtocol> rtcMediaPlayer;
@property (nonatomic, strong) id<AgoraMusicPlayerProtocol> rtcMediaPlayer;
@property (nonatomic, strong) VLSongItmModel *choosedSongModel; //点的歌曲
@property (nonatomic, assign) float currentTime;
@property (nonatomic, strong) AgoraRtcEngineKit *RTCkit;
@property (nonatomic, strong) AgoraMusicContentCenter *AgoraMcc;
@end

@implementation VLKTVViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createChannel:self.roomModel.roomNo];
    
    
    if (VLUserCenter.user.ifMaster || [self.roomModel.creator isEqualToString:VLUserCenter.user.userNo] || [self isOnSeat]) { //自己是房间的创建者
        [self joinRTCChannelIfRequestOnSeat:YES];
    }else{
        [self joinRTCChannelIfRequestOnSeat:NO];
    }
    

    //添加通知
    [self addNotification];
    //处理背景
    [self dealWithSelBg];
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
}

-(BOOL)isOnSeat{
    for (VLRoomSeatModel *seatModel in self.seatsArray) {
        if (seatModel.id != nil) {
            if ([seatModel.id isEqual:VLUserCenter.user.id]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)loadMusicWithURL:(NSString *)url lrc:(NSString *)lrc songCode:(NSString *)songCode {
    [self.MVView loadLrcURL:lrc];
//    [self.rtcMediaPlayer open:url startPos:0];
    NSInteger songCodeIntValue = [songCode integerValue];
    if([self.AgoraMcc isPreloadedWith:songCodeIntValue type:AgoraMusicContentCenterMediaTypeAudio resolution:nil] == 0) {
        [self playMusic:songCodeIntValue];
    }
    else {
        [self.AgoraMcc preloadWith:songCodeIntValue type:AgoraMusicContentCenterMediaTypeAudio resolution:nil];
    }
    VLLog(@"_rtcMediaPlayer--------是否静音:%d",[_rtcMediaPlayer getMute]);
}

- (void)playMusic:(NSInteger )songCode {
//    [self.rtcMediaPlayer open:songCode startPos:0];
    [self.rtcMediaPlayer openMediaWithSongCode:songCode  type:AgoraMusicContentCenterMediaTypeAudio resolution:nil startPos:0];
}

- (void)dealWithSelBg{
    if (self.roomModel.bgOption) {
        VLKTVSelBgModel *selBgModel = [VLKTVSelBgModel new];
        selBgModel.imageName = [NSString stringWithFormat:@"ktv_mvbg%d",(int)self.roomModel.bgOption];
        selBgModel.ifSelect = YES;
        self.choosedBgModel = selBgModel;
        [self.MVView changeBgViewByModel:self.choosedBgModel];
    }
}

#pragma mark - 评分相关
- (void)rtcEngine:(AgoraRtcEngineKit *_Nonnull)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason{
    VLLog(@"下线了：：%ld::reason:%ld",uid,reason);
}

- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed{
    VLLog(@"收到了视频信息：：%ld",(long)uid);
}
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine localAudioStats:(AgoraRtcLocalAudioStats * _Nonnull)stats{
}

- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine remoteAudioStats:(AgoraRtcRemoteAudioStats * _Nonnull)stats{

}

- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine firstLocalAudioFrame:(NSInteger)elapsed{
}


- (void)rtcEngine:(AgoraRtcEngineKit *_Nonnull)engine rtmpStreamingChangedToState:(NSString *_Nonnull)url state:(AgoraRtmpStreamingState)state errorCode:(AgoraRtmpStreamingErrorCode)errorCode{
    VLLog(@"收到了数据流状态改变：：%lu",state);

}
- (void)rtcEngine:(AgoraRtcEngineKit *)engine reportAudioVolumeIndicationOfSpeakers:(NSArray<AgoraRtcAudioVolumeInfo *> *)speakers totalVolume:(NSInteger)totalVolume {
        if (speakers.count) {
//            AgoraRtcAudioVolumeInfo *info = speakers.firstObject;
//            VLLog(@"评分回调---：%@,%ld",[info yy_modelDescription],totalVolume);
            double voicePitch = (double)totalVolume;
            [self.MVView setVoicePitch:@[@(voicePitch)]];
            NSDictionary *dict = @{
                @"messageType":@(VLSendMessageTypeSeeScore),
                @"pitch":@(totalVolume),
                @"platform":@"1",
                @"roomNo":self.roomModel.roomNo
            };
            NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
            AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
            [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
                if (errorCode == 0) {
//                    NSLog(@"发送分数消息");
                }
            }];
        }
//    }
}

#pragma mark -  播放状态

- (void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol> _Nonnull)playerKit
          didChangedToState:(AgoraMediaPlayerState)state
                      error:(AgoraMediaPlayerError)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        VLLog(@"AgoraMediaPlayerState---%ld\n",state);
        if (state == AgoraMediaPlayerStateOpenCompleted) {
//            [playerKit setPlaybackSpeed:400];
            [self playSongWithPlayer:playerKit];
        } else if (state == AgoraMediaPlayerStatePlayBackCompleted) {
            VLLog(@"Playback Completed");
        } else if (state == AgoraMediaPlayerStatePlayBackAllLoopsCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                VLLog(@"Playback all loop completed");
                [self playNextSong];
            });
        } else if (state == AgoraMediaPlayerStateStopped) {
        }
    });
}

- (void)showScoreViewWithScore:(int)score song:(VLRoomSelSongModel *)song {
    if (score <= 0 && song.isChorus) return;
    VLPopScoreView *scoreView = [[VLPopScoreView alloc] initWithFrame:self.view.bounds withDelegate:nil];
    [scoreView configScore:score];
    [self.view addSubview:scoreView];
}

#pragma mark --播放进度回调
- (void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol> _Nonnull)playerKit
       didChangedToPosition:(NSInteger)position {
    //只有主唱才能发送消息
    if (self.selSongsArray.count > 0) {
        VLRoomSelSongModel *songModel = self.selSongsArray.firstObject;
            if ([songModel.userNo isEqualToString:VLUserCenter.user.userNo]) { //主唱
//                VLLog(@"didChangedToPosition-----%@,%ld",playerKit,position);
                NSDictionary *dict = @{
                    @"cmd":@"setLrcTime",
                    @"duration":@([self ktvMVViewMusicTotalTime]),
                    @"time":@(position),
                };
                [self sendStremMessageWithDict:dict success:^(BOOL ifSuccess) {
                    if (ifSuccess) {
//                        VLLog(@"发送成功");
                    }else{
//                        VLLog(@"发送失败");
                    }
                }];
            }
    }
}

- (void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol> _Nonnull)playerKit
              didOccurEvent:(AgoraMediaPlayerEvent)eventCode
                elapsedTime:(NSInteger)elapsedTime
                    message:(NSString *_Nullable)message { //报告当前播放器发生的事件，如定位开始、定位成功或定位失败。
    if (eventCode == AgoraMediaPlayerEventSeekComplete) {
//        [_MVView start];
//        [_MVView updateMVPlayerState:VLKTVMVViewActionTypeMVPlay];
//        [self playSongWithPlayer:playerKit];
    }
}

- (void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol> _Nonnull)playerKit
             didReceiveData:(NSString *_Nullable)data
                     length:(NSInteger)length {
//    VLLog(@"didReceiveData-----%@,%ld",data,length);
}

- (void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol> _Nonnull)playerKit
       didPlayBufferUpdated:(NSInteger)playCachedBuffer {
//    VLLog(@"didPlayBufferUpdated-----%@,%ld",playerKit,playCachedBuffer);
    
}

- (void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol> _Nonnull)playerKit
            didPreloadEvent:(AgoraMediaPlayerPreloadEvent)event {
//    VLLog(@"didPreloadEvent-----%@,%ld",playerKit,event);
    if (event == 1) {
        
    }
}

- (void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol> _Nonnull)playerKit playerSrcInfoDidChange:(AgoraMediaPlayerSrcInfo *_Nonnull)to from:(AgoraMediaPlayerSrcInfo *_Nonnull)from {
//    VLLog(@"playerSrcInfoDidChange-----%@,%@,%@",playerKit,[to yy_modelDescription],[from yy_modelDescription]);
}

- (void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol> _Nonnull)playerKit infoUpdated:(AgoraMediaPlayerUpdatedInfo *_Nonnull)info
{
//    VLLog(@"AgoraRtcMediaPlayer-----%@,%@",playerKit,[info yy_modelDescription]);
}

- (void)onAgoraCDNTokenWillExpire {
//    VLLog(@"onAgoraCDNTokenWillExpire");
}

- (void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol> _Nonnull)playerKit
 volumeIndicationDidReceive:(NSInteger)volume {
//    NSLog(@"volumeIndicationDidReceive-----%@,%ld",playerKit,volume);
}

//发送流消息
- (void)sendStremMessageWithDict:(NSDictionary *)dict success:(sendStreamSuccess)success {
    NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
    if (streamId == -1) {
        AgoraDataStreamConfig *config = [AgoraDataStreamConfig new];
        config.ordered = false;
        config.syncWithAudio = false;
        [self.RTCkit createDataStream:&streamId config:config];
    }
    
    int code = [self.RTCkit sendStreamMessage:streamId data:messageData];
    if (code == 0) {
        success(YES);
    }else{
//                    VLLog(@"发送失败-streamId:%ld\n",streamId);
    };
}

#pragma mark - zzzzz

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIViewController popGestureClose:self];
    

    //请求已点歌曲
    [self userFirstGetInRoom];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIViewController popGestureOpen:self];
    [self leaveChannel];
    [self leaveRTCChannel];
    [[UIApplication sharedApplication] setIdleTimerDisabled: NO];
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dianGeSuccessEvent:) name:kDianGeSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(makeTopSuccessEvent) name:kMakeTopNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(deleteSuccessEvent) name:kDeleteSuccessNotification object:nil];

}

- (void)dealloc {
    streamId = -1;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

/// 销毁播放器
- (void)destroyMediaPlayer {
    [self.rtcMediaPlayer stop];
    [self.RTCkit destroyMediaPlayer:self.rtcMediaPlayer];
}

- (void)createChannel:(NSString *)channel {
    AgoraRtmChannel *rtmChannel = [AgoraRtm.kit createChannelWithId:channel delegate:self];
    
    if (!rtmChannel) {
        [VLToast toast:NSLocalizedString(@"加入频道失败", nil)];
    }
    
    [rtmChannel joinWithCompletion:^(AgoraRtmJoinChannelErrorCode errorCode) {
        if (errorCode != AgoraRtmJoinChannelErrorOk) {
            [VLToast toast:[NSString stringWithFormat:NSLocalizedString(@"加入频道失败:%ld", nil), errorCode]];
        }
    }];
    
    self.rtmChannel = rtmChannel;
}

- (void)joinRTCChannelIfRequestOnSeat:(BOOL)ifRequestOnSeat {
    [self.RTCkit leaveChannel:nil];
    [AgoraRtcEngineKit destroy];
    self.RTCkit = nil;
    
    self.RTCkit = [AgoraRtcEngineKit sharedEngineWithAppId:AGORA_APP_ID delegate:self];
    [self.RTCkit setChannelProfile:AgoraChannelProfileLiveBroadcasting];
    /// 开启唱歌评分功能
    int code = [self.RTCkit enableAudioVolumeIndication:3000 smooth:3 reportVad:YES];
    if (code == 0) {
        VLLog(@"评分回调开启成功\n");
    } else {
        VLLog(@"评分回调开启失败：%d\n",code);
    }
    
    [self.RTCkit enableVideo];
    [self.RTCkit enableLocalVideo:YES];

//    [self.RTCkit startPreview];
    [self.RTCkit enableAudio];
    if (ifRequestOnSeat) {
        [self.RTCkit muteLocalVideoStream:NO];
        [self.RTCkit muteLocalAudioStream:NO];
        [self.RTCkit setClientRole:AgoraClientRoleBroadcaster];
    }else{
        [self.RTCkit muteLocalVideoStream:YES];
        [self.RTCkit muteLocalAudioStream:YES];
        [self.RTCkit setClientRole:AgoraClientRoleAudience];

    }
    AgoraVideoEncoderConfiguration *encoderConfiguration = [[AgoraVideoEncoderConfiguration alloc] initWithSize:CGSizeMake(100, 100) frameRate:AgoraVideoFrameRateFps7 bitrate:20 orientationMode:AgoraVideoOutputOrientationModeFixedLandscape mirrorMode:AgoraVideoMirrorModeAuto];
    [self.RTCkit setVideoEncoderConfiguration:encoderConfiguration];
    [self.RTCkit joinChannelByToken:@"" channelId:self.roomModel.roomNo info:nil uid:[VLUserCenter.user.id integerValue] joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
        VLLog(@"加入RTC成功");
       
        [self setUpUI];
        [AgoraRtm updateDelegate:self];
    }];
    [self.RTCkit setEnableSpeakerphone:YES];
    
    NSDictionary *param = @{
        @"userId": VLUserCenter.user.id
    };
    [VLAPIRequest getRequestURL:kURLGetRTMToken parameter:param showHUD:YES success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            VLLog(@"RTM Token: %@ for user: %@", response.data[@"token"], VLUserCenter.user.id);
            
            // TODO: Nasty documented APIs, totally guessing
            AgoraMusicContentCenterConfig *contentCenterConfiguration = [[AgoraMusicContentCenterConfig alloc] init];
            contentCenterConfiguration.rtcEngine = self.RTCkit;
            contentCenterConfiguration.appId = AGORA_APP_ID;
            contentCenterConfiguration.mccUid = [VLUserCenter.user.id integerValue];
            contentCenterConfiguration.rtmToken = response.data[@"token"];
//            contentCenterConfiguration.rtmToken = @"0065b34cef94e7f48ba98f1d7799590f087IABXcj7ILEceOlae0CCeg3oI0gpHBPWgt1Atdj1vrhLlMwAAAABEU0//CgD+/KcBvkzyYgAA";
            
            self.AgoraMcc = [AgoraMusicContentCenter sharedContentCenterWithConfig:contentCenterConfiguration];
            [self.AgoraMcc registerEventHandler:self];
        }
    } failure:^(NSError * _Nullable error) {
        
    }];
    
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)leaveChannel {
    [self.rtmChannel leaveWithCompletion:^(AgoraRtmLeaveChannelErrorCode errorCode) {
        NSLog(@"leave channel error: %ld", (long)errorCode);
    }];
}

- (void)leaveRTCChannel {
    [self.RTCkit leaveChannel:^(AgoraChannelStats * _Nonnull stat) {
        
    }];
}

- (void)setUpUI {
    [self setBackgroundImage:@"ktv_temp_mainbg"];
    
    UIView *bgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    bgView.backgroundColor = UIColorMakeWithRGBA(0, 0, 0, 0.6);
    [self.view addSubview:bgView];
    //头部视图
    VLKTVTopView *topView = [[VLKTVTopView alloc]initWithFrame:CGRectMake(0, kStatusBarHeight+10, SCREEN_WIDTH, 22+20+14) withDelegate:self];
    [self.view addSubview:topView];
    self.topView = topView;
    topView.listModel = self.roomModel;
    
    //MV视图(显示歌词...)
    self.MVView = [[VLKTVMVView alloc]initWithFrame:CGRectMake(15, topView.bottom+13, SCREEN_WIDTH-30, (SCREEN_WIDTH-30)*0.67) withDelegate:self];
    [self.view addSubview:self.MVView];
    
    //房间麦位视图
    VLRoomPersonView *personView = [[VLRoomPersonView alloc]initWithFrame:CGRectMake(0, self.MVView.bottom+42, SCREEN_WIDTH, (VLREALVALUE_WIDTH(54)+20)*2+26) withDelegate:self withRTCkit:self.RTCkit];
    self.roomPersonView = personView;
    [self.roomPersonView setSeatsArray:self.seatsArray];
    [self.view addSubview:personView];
    
    //底部按钮视图
    VLKTVBottomView *bottomView = [[VLKTVBottomView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT-40-kSafeAreaBottomHeight-VLREALVALUE_WIDTH(35), SCREEN_WIDTH, 40) withDelegate:self withRoomNo:self.roomModel.roomNo withData:self.seatsArray];
    self.bottomView = bottomView;
    bottomView.backgroundColor = UIColorClear;
//    self.bottomView.hidden = YES;
    [self.view addSubview:bottomView];
    
    //空位上麦视图
    VLTouristOnLineView *requestOnLineView = [[VLTouristOnLineView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT-kSafeAreaBottomHeight-56-VLREALVALUE_WIDTH(30), SCREEN_WIDTH, 56) withDelegate:self];
    self.requestOnLineView = requestOnLineView;
    [self.view addSubview:requestOnLineView];
    
    if (VLUserCenter.user.ifMaster) {
        self.bottomView.hidden = NO;
        self.requestOnLineView.hidden = YES;
    }else{
        BOOL ifOnSeat = NO;
        for (VLRoomSeatModel *model in self.seatsArray) {
            if ([model.userNo isEqualToString:VLUserCenter.user.userNo]) {
                ifOnSeat = YES;
            }
        }
        self.bottomView.hidden = !ifOnSeat;
        self.requestOnLineView.hidden = ifOnSeat;
    }
}

#pragma mark - Public Methods
- (void)configNavigationBar:(UINavigationBar *)navigationBar {
    [super configNavigationBar:navigationBar];
}
- (BOOL)preferredNavigationBarHidden {
    return true;
}
// 是否允许手动滑回 @return true 是、 false否
- (BOOL)forceEnableInteractivePopGestureRecognizer {
    return NO;
}

#pragma mark -- delegate Event
- (void)closeBtnAction {
/// TODO:统一一个退出方法，退出时候调用 [self destroyMediaPlayer] ,否则控制器无法正常销毁
    if (VLUserCenter.user.ifMaster) { //自己是房主关闭房间
        [LEEAlert alert].config
        .LeeAddTitle(^(UILabel *label) {
            label.text = NSLocalizedString(@"退出房间", nil);
            label.textColor = UIColorMakeWithHex(@"#040925");
            label.font = UIFontBoldMake(16);
        })
        .LeeAddContent(^(UILabel *label) {
            label.text = NSLocalizedString(@"确定解散该房间吗", nil);
            label.textColor = UIColorMakeWithHex(@"#6C7192");
            label.font = UIFontMake(14);
            
        })
        .LeeAddAction(^(LEEAction *action) {
            action.type = LEEActionTypeCancel;
            action.title = NSLocalizedString(@"取消", nil);
            action.titleColor = UIColorMakeWithHex(@"#000000");
            action.backgroundColor = UIColorMakeWithHex(@"#EFF4FF");
            action.cornerRadius = 20;
            action.height = 40;
            action.font = UIFontBoldMake(16);
            action.insets = UIEdgeInsetsMake(10, 20, 20, 20);
            action.borderColor = UIColorMakeWithHex(@"#EFF4FF");
            action.clickBlock = ^{
                // 取消点击事件Block
            };
        })
        .LeeAddAction(^(LEEAction *action) {
            VL(weakSelf);
            action.type = LEEActionTypeCancel;
            action.title = NSLocalizedString(@"确定", nil);
            action.titleColor = UIColorMakeWithHex(@"#FFFFFF");
            action.backgroundColor = UIColorMakeWithHex(@"#2753FF");
            action.cornerRadius = 20;
            action.height = 40;
            action.insets = UIEdgeInsetsMake(10, 20, 20, 20);
            action.font = UIFontBoldMake(16);
            action.clickBlock = ^{
                [weakSelf destroyMediaPlayer];
                [weakSelf roomerCloseRoom];
            };
        })
        .LeeShow();
    }else{
        [self otherPersonExitRoom];
    }
}

- (void)roomerCloseRoom {
    NSDictionary *param = @{
        @"roomNo": self.roomModel.roomNo,
        @"userNo":VLUserCenter.user.userNo
    };
    [VLAPIRequest getRequestURL:kURLRoomClose parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            for (BaseViewController *vc in self.navigationController.childViewControllers) {
                //发送通知
                [[NSNotificationCenter defaultCenter]postNotificationName:kExitRoomNotification object:nil];
                //发送关闭房间的消息
                NSDictionary *dict = @{
                    @"messageType":@(VLSendMessageTypeCloseRoom),
                    @"platform":@"1",
                    @"roomNo":self.roomModel.roomNo
                };
                NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
                AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
                [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
                    if (errorCode == 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([vc isKindOfClass:[VLOnLineListVC class]]) {
                                [self.navigationController popToViewController:vc animated:YES];
                            }
                        });
                    }
                }];
            }
        }
    } failure:^(NSError * _Nullable error) {
        
    }];
}

- (void)otherPersonExitRoom {
    NSDictionary *param = @{
        @"roomNo": self.roomModel.roomNo,
        @"userNo":VLUserCenter.user.userNo
    };
    BOOL ifOnSeat = NO;
    NSInteger seatIndex = -1;
    for (VLRoomSeatModel *model in self.seatsArray) {
        if ([model.userNo isEqualToString:VLUserCenter.user.userNo]) {
            ifOnSeat = YES;
            seatIndex = model.onSeat;
        }
    }
    if (ifOnSeat) { //在麦位
        [VLAPIRequest getRequestURL:kURLRoomDropSeat parameter:param showHUD:YES success:^(VLResponseDataModel * _Nonnull response) {
            if (response.code == 0) {
                //发送下麦的推送
                NSDictionary *dict = @{
                    @"messageType":@(VLSendMessageTypeDropSeat),
                    @"headUrl":VLUserCenter.user.headUrl ? VLUserCenter.user.headUrl:@"",
                    @"onSeat":@(seatIndex),
                    @"name":VLUserCenter.user.name,
                    @"userNo":VLUserCenter.user.userNo,
                    @"id":VLUserCenter.user.id,
                    @"platform":@"1",
                    @"roomNo":self.roomModel.roomNo
                };
                NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
                AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
                [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
                    if (errorCode == 0) {
                        VLLog(@"发送下麦消息成功");
                        [VLUserCenter clearUserRoomInfo];
                        [self userOutRoom];
                    }
                }];
            }
        } failure:^(NSError * _Nullable error) {
            
        }];
    }else{
        [self userOutRoom];
    }
}

- (void)userOutRoom {
    NSDictionary *param = @{
        @"roomNo": self.roomModel.roomNo,
        @"userNo":VLUserCenter.user.userNo
    };
    [VLAPIRequest getRequestURL:kURLRoomOut parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            [[NSNotificationCenter defaultCenter]postNotificationName:kExitRoomNotification object:nil];
            [self destroyMediaPlayer];
            for (BaseViewController *vc in self.navigationController.childViewControllers) {
                if ([vc isKindOfClass:[VLOnLineListVC class]]) {
                    [self.navigationController popToViewController:vc animated:YES];
                }
            }
        }
    } failure:^(NSError * _Nullable error) {

    }];
}


- (void)moreItemBtnAction:(VLKTVMoreBtnClickType)typeValue {
    switch (typeValue) {
        case VLKTVMoreBtnClickTypeBelcanto:
            [self.popMoreView dismiss];
            [self popBelcantoView];
            break;
        case VLKTVMoreBtnClickTypeSound:
//            [self.popMoreView dismiss];

            [self.popMoreView dismiss];
            [self popSetSoundEffectView];
            break;
        case VLKTVMoreBtnClickTypeMV:
            [self.popMoreView dismiss];
            [self popSelMVBgView];
            break;
            
        default:
            break;
    }
}

#pragma mark --底部按钮的点击事件
- (void)bottomSetAudioMute:(NSInteger)ifMute{
    if (ifMute == 1) {
        [self.RTCkit muteLocalAudioStream:NO];
    }
    else{
        [self.RTCkit muteLocalAudioStream:YES];
    }
}

- (void)bottomSetVideoMute:(NSInteger)ifOpen{
    if (ifOpen == 1) {
        [self.RTCkit muteLocalVideoStream:NO];
    }
    else{
        [self.RTCkit muteLocalVideoStream:YES];
    }
}

- (void)bottomAudionBtnAction:(NSInteger)ifMute {
    NSDictionary *dict = @{
        @"messageType":@(VLSendMessageTypeAudioMute),
        @"userNo":VLUserCenter.user.userNo,
        @"id":VLUserCenter.user.id,
        @"isSelfMuted" : @(ifMute),
        @"platform":@"1",
        @"roomNo":self.roomModel.roomNo
    };
    
   // [self.RTCkit muteLocalAudioStream:ifMute];
    
    NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
    AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
    [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
        if (errorCode == 0) {
            VLRoomSeatModel *model = [VLRoomSeatModel new];
            model.userNo = VLUserCenter.user.userNo;
            model.isSelfMuted = ifMute;
            for (VLRoomSeatModel *seatModel in self.seatsArray) {
                if ([seatModel.userNo isEqualToString:model.userNo]) {
                    seatModel.isSelfMuted = model.isSelfMuted;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.roomPersonView updateSeatsByModel:seatModel];
                    });
                    break;
                }
            }
          
        }
    }];
}

// 开启视频事件回调
- (void)bottomVideoBtnAction:(NSInteger)ifOpen {
    NSDictionary *dict = @{
        @"messageType":@(VLSendMessageTypeVideoIfOpen),
        @"userNo":VLUserCenter.user.userNo,
        @"id":VLUserCenter.user.id,
        @"isVideoMuted" : @(ifOpen),
        @"platform":@"1",
        @"roomNo":self.roomModel.roomNo
    };
    
    NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
    AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
    [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
        if (errorCode == 0) {
            for (VLRoomSeatModel *seatModel in self.seatsArray) {
                if ([seatModel.userNo isEqualToString:VLUserCenter.user.userNo]) {
                    seatModel.isVideoMuted = ifOpen;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.roomPersonView updateSeatsByModel:seatModel];
                    });
                }
            }
            
        }
    }];
}

- (void)bottomBtnsClickAction:(VLKTVBottomBtnClickType)tagValue withSender:(nonnull VLHotSpotBtn *)sender{
    switch (tagValue) {
        case VLKTVBottomBtnClickTypeMore:  //更多
//            [self popSelMVBgView];
            [self popSelMoreView];
            break;
        case VLKTVBottomBtnClickTypeChorus:
            [self popUpChooseSongView:YES];
            break;
        case VLKTVBottomBtnClickTypeChoose:
            [self popUpChooseSongView:NO];
            break;
            
        default:
            break;
    }
}

#pragma mark --切换MV背景
- (void)bgItemClickAction:(VLKTVSelBgModel *)selBgModel index:(NSInteger)index {
    
    NSDictionary *param = @{
        @"roomNo": self.roomModel.roomNo,
        @"bgOption":[NSString stringWithFormat:@"%d",(int)index],
        @"userNo":VLUserCenter.user.userNo
    };
    [VLAPIRequest postRequestURL:kURLUpdataRoom parameter:param showHUD:YES success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.popSelBgView dismiss];
                self.choosedBgModel = selBgModel;
                [self.MVView changeBgViewByModel:selBgModel];
            });
            //发送切换背景的消息
            NSDictionary *dict = @{
                @"messageType":@(VLSendMessageTypeChangeMVBg),
                @"bgOption":[NSString stringWithFormat:@"%d",(int)index],
                @"platform":@"1",
                @"roomNo":self.roomModel.roomNo
            };
            NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
            AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
            [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
                if (errorCode == 0) {
                    VLLog(@"发送切换背景消息");
                }
            }];
        }else{
            [VLToast toast:response.message];
        }
    } failure:^(NSError * _Nullable error) {
        [VLToast toast:NSLocalizedString(@"修改背景失败", nil)];
    }];
}

- (void)backBtnAction {
    [self.popOnLineTypeView dismiss];
}

- (void)belcantoBackBtnAction {
    [self.belcantoView dismiss];
}

- (void)belcantoItemClickAction:(VLBelcantoModel *)model withIndx:(NSInteger)index {
    self.selBelcantoModel = model;
    [self.RTCkit setAudioProfile:AgoraAudioProfileMusicHighQuality scenario:AgoraAudioScenarioGameStreaming];
    if (index == 0) {
        [self.RTCkit setVoiceBeautifierPreset:AgoraVoiceBeautifierPresetOff];
    }else if (index == 1){
        [self.RTCkit setVoiceBeautifierPreset:AgoraVoiceBeautifierPresetChatBeautifierMagnetic];
    }else if (index == 2){
        [self.RTCkit setVoiceBeautifierPreset:AgoraVoiceBeautifierPresetChatBeautifierFresh];
    }else if (index == 3){
        [self.RTCkit setVoiceBeautifierPreset:AgoraVoiceBeautifierPresetChatBeautifierVitality];
    }else if (index == 4){
        [self.RTCkit setVoiceBeautifierPreset:AgoraVoiceBeautifierPresetChatBeautifierVitality];
    }
}



#pragma mark --某人下麦
- (void)dropOnLineAction:(VLRoomSeatModel *)seatModel {
    NSDictionary *param = @{
        @"roomNo": self.roomModel.roomNo,
        @"userNo": seatModel.userNo
    };
    [VLAPIRequest getRequestURL:kURLRoomDropSeat parameter:param showHUD:YES success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            //发送下麦的推送
            NSDictionary *dict = @{
                @"messageType":@(VLSendMessageTypeDropSeat),
                @"headUrl":seatModel.headUrl ? seatModel.headUrl:@"",
                @"onSeat":@(seatModel.onSeat),
                @"name":seatModel.name,
                @"userNo":seatModel.userNo,
                @"id":seatModel.id,
                @"platform":@"1",
                @"roomNo":self.roomModel.roomNo
            };
            NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
            AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
            [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
                if (errorCode == 0) {
                    VLLog(@"发送下麦消息成功");
                    //房主自己手动更新视图
                    if ([seatModel.userNo isEqualToString:VLUserCenter.user.userNo]) {//如果自己主动下麦
                        //当前的座位用户离开RTC通道
                        [self leaveRTCChannel];
                        [self.MVView updateUIWithUserOnSeat:NO song:self.selSongsArray.firstObject];
                        self.bottomView.hidden = YES;
                        self.requestOnLineView.hidden = NO;
                    }
                    for (VLRoomSeatModel *model in self.seatsArray) {
                        if (model.onSeat == seatModel.onSeat) {
                            [model resetLeaveSeat];
                        }
                    }
                    [self.roomPersonView setSeatsArray:self.seatsArray];
                    [self.dropLineView dismiss];
                }
            }];
        }
    } failure:^(NSError * _Nullable error) {

    }];
    
}

//美声点击事件
- (void)itemClickAction:(VLBelcantoModel *)model {
    self.selBelcantoModel = model;
}

//网络差知道了点击事件
- (void)knowBtnClickAction {
    [self.popBadNetWorkView dismiss];
}

//上麦方式
- (void)requestOnlineAction {
//    CGFloat popViewH = 104+VLREALVALUE_WIDTH(72)+kSafeAreaBottomHeight;
//    VLPopOnLineTypeView *typeView = [[VLPopOnLineTypeView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, popViewH) withDelegate:self];
//
//    self.popOnLineTypeView = [self setPopCommenSettingWithContentView:typeView ifClickBackDismiss:NO];
//    [self.popOnLineTypeView pop];
}

//更换MV背景
- (void)popSelMVBgView {
    CGFloat popViewH = (SCREEN_WIDTH-60)/3.0*0.75*3+100+kSafeAreaBottomHeight;
    VLPopSelBgView *changeBgView = [[VLPopSelBgView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, popViewH) withDelegate:self];
    changeBgView.selBgModel = self.choosedBgModel;
    
    self.popSelBgView = [self setPopCommenSettingWithContentView:changeBgView ifClickBackDismiss:YES];
    [self.popSelBgView pop];
}

//弹出更多
- (void)popSelMoreView {
    CGFloat popViewH = 190+kSafeAreaBottomHeight;
    VLPopMoreSelView *moreView = [[VLPopMoreSelView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, popViewH) withDelegate:self];
    
    self.popMoreView = [self setPopCommenSettingWithContentView:moreView ifClickBackDismiss:YES];
    [self.popMoreView pop];
}

//弹出下麦视图
- (void)popDropLineViewWithSeatModel:(VLRoomSeatModel *)seatModel {
    CGFloat popViewH = 212+kSafeAreaBottomHeight+32;
    VLDropOnLineView *dropLineView = [[VLDropOnLineView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, popViewH) withDelegate:self];
    dropLineView.seatModel = seatModel;
    
    self.dropLineView = [self setPopCommenSettingWithContentView:dropLineView ifClickBackDismiss:YES];
    [self.dropLineView pop];
}

//弹出美声视图
- (void)popBelcantoView {
    CGFloat popViewH = 175+kSafeAreaBottomHeight;
    VLChooseBelcantoView *belcantoView = [[VLChooseBelcantoView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, popViewH) withDelegate:self];
    belcantoView.selBelcantoModel = self.selBelcantoModel;
    self.belcantoView = [self setPopCommenSettingWithContentView:belcantoView ifClickBackDismiss:YES];
    [self.belcantoView pop];
}

//弹出点歌视图
- (void)popUpChooseSongView:(BOOL)ifChorus {
    CGFloat popViewH = SCREEN_HEIGHT*0.7;
    VLPopChooseSongView *chooseSongView = [[VLPopChooseSongView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, popViewH) withDelegate:self withRoomNo:self.roomModel.roomNo ifChorus:ifChorus];
    self.chooseSongView = chooseSongView;
    self.chooseSongView.selSongsArray = self.selSongsArray;
    self.popChooseSongView = [self setPopCommenSettingWithContentView:chooseSongView ifClickBackDismiss:YES];
    self.popChooseSongView.isAvoidKeyboard = NO;
    [self.popChooseSongView pop];
}

//弹出音效
- (void)popSetSoundEffectView {
    CGFloat popViewH = 88+17+270+kSafeAreaBottomHeight;
    VLsoundEffectView *soundEffectView = [[VLsoundEffectView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, popViewH) withDelegate:self];
    
    self.popSoundEffectView = [self setPopCommenSettingWithContentView:soundEffectView ifClickBackDismiss:YES];
    [self.popSoundEffectView pop];
}
//网络差视图
- (void)popBadNetWrokTipView {
    CGFloat popViewH = 276;
    VLBadNetWorkView *badNetView = [[VLBadNetWorkView alloc]initWithFrame:CGRectMake(40, 0, SCREEN_WIDTH-80, popViewH) withDelegate:self];
    
    LSTPopView *popView = [LSTPopView initWithCustomView:badNetView parentView:self.view popStyle:LSTPopStyleFade dismissStyle:LSTDismissStyleFade];
    popView.hemStyle = LSTHemStyleCenter;
    popView.popDuration = 0.5;
    popView.dismissDuration = 0.5;
    popView.cornerRadius = 20;
    self.popBadNetWorkView = popView;
    popView.isClickFeedback = NO;
    
    [self.popBadNetWorkView pop];
}

//公共弹窗视图设置
- (LSTPopView *)setPopCommenSettingWithContentView:(UIView *)contentView ifClickBackDismiss:(BOOL)dismiss{
    LSTPopView *popView = [LSTPopView initWithCustomView:contentView parentView:self.view popStyle:LSTPopStyleSmoothFromBottom dismissStyle:LSTDismissStyleSmoothToBottom];
    popView.hemStyle = LSTHemStyleBottom;
    popView.popDuration = 0.5;
    popView.dismissDuration = 0.5;
    popView.cornerRadius = 20;
    LSTPopViewWK(popView)
    if (dismiss) {
        popView.isClickFeedback = YES;
        popView.bgClickBlock = ^{
            [wk_popView dismiss];
        };
    }else{
        popView.isClickFeedback = NO;
    }
    popView.rectCorners = UIRectCornerTopLeft | UIRectCornerTopRight;
    
    return  popView;
    
}

- (void)showSettingView {
    [YGViewDisplayer popupBottom:self.settingView setupBlock:^(YGViewDisplayOptions * _Nonnull options) {
        options.screenInteraction = YGViewDisplayOptionsUserInteractionDismiss;
        options.safeArea = YGViewDisplayOptionsSafeAreaOverridden;
        options.backgroundColor = [UIColor clearColor];
        options.screenBackgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    }];
}

- (void)dismissSettingView {
    [YGViewDisplayer dismiss:self.settingView completionHandler:^{}];
}

- (void)playSongWithPlayer:(id<AgoraRtcMediaPlayerProtocol>)player {
    if (self.selSongsArray.count > 0) {
        VLRoomSelSongModel *model = self.selSongsArray.firstObject;
        if ([model.userNo isEqualToString:VLUserCenter.user.userNo]) {
            AgoraRtcChannelMediaOptions *option = [[AgoraRtcChannelMediaOptions alloc]init];
            [option setPublishAudioTrack:[AgoraRtcBoolOptional of:YES]];
            [option setPublishMediaPlayerId:[AgoraRtcIntOptional of:[self.rtcMediaPlayer getMediaPlayerId]]];
            
            [option setClientRoleType:[AgoraRtcIntOptional of:AgoraClientRoleBroadcaster]];
            option.publishCameraTrack = [AgoraRtcBoolOptional of:NO];
            option.autoSubscribeAudio = [AgoraRtcBoolOptional of:YES];
            option.enableAudioRecordingOrPlayout = [AgoraRtcBoolOptional of:YES];
            option.publishMediaPlayerAudioTrack = [AgoraRtcBoolOptional of:YES];
            [self.RTCkit updateChannelWithMediaOptions:option];
            [player play];
            
            [_MVView start];
            [_MVView updateMVPlayerState:VLKTVMVViewActionTypeMVPlay];
            
            if (self.selSongsArray.count) {
                [self tellSeverTheCurrentPlaySongWithModel:self.selSongsArray.firstObject];
            }
        }
    }
    
}

#pragma mark - MVViewDelegate

- (NSTimeInterval)ktvMVViewMusicTotalTime {
    NSTimeInterval time = [_rtcMediaPlayer getDuration];
    NSTimeInterval real = time / 1000;
//    VLLog(@"totalTime-----%f",real);
    return real;
}

- (NSTimeInterval)ktvMVViewMusicCurrentTime {
    VLRoomSelSongModel *model = self.selSongsArray.firstObject;
    if ([model.userNo isEqualToString:VLUserCenter.user.userNo]) {
        NSTimeInterval time = [_rtcMediaPlayer getPosition];
        NSTimeInterval real = time / 1000;
//        VLLog(@"time-----%f",real);
        return real;
    }else{
        return self.currentTime;
    }

}

// 打分实时回调
- (void)ktvMVViewMusicScore:(int)score {
}

- (void)ktvMVViewDidClick:(VLKTVMVViewActionType)type {
    if (type == VLKTVMVViewActionTypeSetParam) {
        [self showSettingView];
    } else if (type == VLKTVMVViewActionTypeMVPlay) { //播放
        [self.rtcMediaPlayer resume];
        [self.MVView start];
        //发送继续播放的消息
        [self sendPauseOrResumeMessage:1];
    } else if (type == VLKTVMVViewActionTypeMVPause) { //暂停
        [self.rtcMediaPlayer pause];
        [self.MVView stop];
        //发送暂停的消息
        [self sendPauseOrResumeMessage:0];
    } else if (type == VLKTVMVViewActionTypeMVNext) { //切换
        if (self.selSongsArray.count >= 1) {
            [self playNextSong];
            //发送切换歌的消息
            [self sendChangeSongMessage];
        }
    } else if (type == VLKTVMVViewActionTypeSingOrigin) { // 原唱
        [self.rtcMediaPlayer setAudioDualMonoMode:AgoraAudioDualMonoR];
    } else if (type == VLKTVMVViewActionTypeSingAcc) { // 伴奏
        [self.rtcMediaPlayer setAudioDualMonoMode:AgoraAudioDualMonoL];
    }
}

- (void)playNextSong {
    //            [self showScoreViewWithScore:[self.MVView getSongScore] song:self.selSongsArray.firstObject];
    //            [self.MVView updateMVPlayerState:VLKTVMVViewActionTypeMVPlay];
    //            [self.MVView stop];
    //            [self.MVView reset];
    //            [self.MVView cleanMusicText];
    //            [self deleteSongEvent:self.selSongsArray.firstObject];
    //
    //            if (self.selSongsArray.count > 1) {
    //                // 切换成暂停样式
    //                [self.MVView updateMVPlayerState:VLKTVMVViewActionTypeMVPause];
    //            } else {
    //            }
        
    self.currentTime = 0;
    [self.MVView stop];
    [self.MVView reset];
    [self.MVView cleanMusicText];
    [self.rtcMediaPlayer stop];
    [self deleteSongEvent:self.selSongsArray.firstObject];
}

//合唱的倒计时事件
- (void)ktvMVViewTimerCountDown:(NSInteger)countDownSecond {
    if (!(self.selSongsArray.count > 0)) {
        return;
    }
    VLRoomSelSongModel *selSongModel = self.selSongsArray.firstObject;
    if ([selSongModel.userNo isEqualToString:VLUserCenter.user.userNo]) {
        NSDictionary *dict = @{
            @"cmd":@"countdown",
            @"time":@(countDownSecond)
        };
        [self sendStremMessageWithDict:dict success:^(BOOL ifSuccess) {
            if (ifSuccess) {
                VLLog(@"倒计时发送成功");
            }
        }];
    }
}


- (void)sendPauseOrResumeMessage:(NSInteger)type {
    NSDictionary *dict;
    if (type == 0) {
        dict = @{
            @"cmd":@"musicStopped",
            @"value":@"0"
        };
    }else if (type == 1){
        dict = @{
            @"cmd":@"musicStopped",
            @"value":@"1"
        };
    }
    [self sendStremMessageWithDict:dict success:^(BOOL ifSuccess) {
        if (ifSuccess) {
            VLLog(@"发送暂停和播放成功");
        }
    }];
}

- (void)sendChangeSongMessage {
    NSDictionary *dict = @{
        @"messageType":@(VLSendMessageTypeChangeSong),
        @"platform":@"1",
        @"roomNo":self.roomModel.roomNo
    };
    NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
    AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
    [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
        if (errorCode == 0) {
            VLLog(@"发送切歌的消息");
        }
    }];
}

- (void)deleteSongEvent:(VLRoomSelSongModel *)model {
    NSDictionary *param = @{
        @"roomNo" : self.roomModel.roomNo,
        @"songNo": model.songNo,
        @"sort":model.sort
    };
    
    [VLAPIRequest getRequestURL:kURLDeleteSong parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            //发送点歌消息
            [self sendDianGeMessage];
            [self getChoosedSongsList];
        }
    } failure:^(NSError * _Nullable error) {
    }];
}

- (void)ktvMVViewDidClickSingType:(VLKTVMVViewSingActionType)singType {
    // 独唱
    if (singType == VLKTVMVViewSingActionTypeSolo) {
        [self playSongWithPlayer:self.rtcMediaPlayer];
        //发送独唱的消息
        [self sendSoloMessage];
    } else if (singType == VLKTVMVViewSingActionTypeJoinChorus) { // 加入合唱
//        [self getChoosedSongsList];
//        [self joinChorusConfig];
        [self sendJoinInSongMessage]; //发送加入合唱的消息
    }
}

//发送独唱的消息
- (void)sendSoloMessage {
    NSDictionary *dict = @{
        @"messageType":@(VLSendMessageTypeSoloSong),
        @"platform":@"1",
        @"roomNo":self.roomModel.roomNo
    };
    NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
    AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
    [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
        if (errorCode == 0) {
            VLLog(@"发送独唱消息成功");
        }
    }];
}

//发送加入合唱的消息
- (void)sendJoinInSongMessage {
    NSDictionary *dict = @{
        @"messageType":@(VLSendMessageTypeTellSingerSomeBodyJoin),
        @"uid":VLUserCenter.user.id ? VLUserCenter.user.id : @"1",
        @"platform":@"1",
        @"roomNo":self.roomModel.roomNo
    };
    NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
    AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
    [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
        if (errorCode == 0) {
            VLLog(@"发送加入合唱消息成功");
        }
    }];
}

/// 加入合唱配置
- (void)joinChorusConfig {
    for (VLRoomSelSongModel *selSongModel in self.selSongsArray) {
        if ([selSongModel.userNo isEqualToString:VLUserCenter.user.userNo]) {
            AgoraRtcChannelMediaOptions *option = [AgoraRtcChannelMediaOptions new];
            [option setAutoSubscribeAudio:[AgoraRtcBoolOptional of:YES]];
            [option setAutoSubscribeVideo:[AgoraRtcBoolOptional of:YES]];
            [option setPublishAudioTrack:[AgoraRtcBoolOptional of:YES]];
            [option setPublishMediaPlayerId:[AgoraRtcIntOptional of:[self.rtcMediaPlayer getMediaPlayerId]]];
            // 发布播放器音频流
            option.publishMediaPlayerAudioTrack = [AgoraRtcBoolOptional of:YES];
            option.enableAudioRecordingOrPlayout = [AgoraRtcBoolOptional of:NO];
            AgoraRtcConnection *connection = [AgoraRtcConnection new];
            connection.channelId = self.roomModel.roomNo;
            connection.localUid = 0;

            int ret  = [self.RTCkit joinChannelExByToken:nil connection:connection delegate:self mediaOptions:option joinSuccess:nil];
            if (ret == 0) {
                VLLog(@"成功了!!!!!!!!!!!!!!!!!!!!!!!1");
            }
        }
    }
}

#pragma mark - VLKTVSettingViewDelegate

- (void)settingViewSettingChanged:(VLKTVSettingModel *)setting valueDidChangedType:(VLKTVValueDidChangedType)type {
    VLLog(@"%@",[setting yy_modelDescription]);
    if (type == VLKTVValueDidChangedTypeEar) { // 耳返设置
        // 用户必须使用有线耳机才能听到耳返效果
        // 1、不在耳返中添加audiofilter
        // AgoraEarMonitoringFilterNone
        // 2: 在耳返中添加人声效果 audio filter。如果你实现了美声、音效等功能，用户可以在耳返中听到添加效果后的声音。
        // AgoraEarMonitoringFilterBuiltInAudioFilters
        // 4: 在耳返中添加降噪 audio filter。
        // AgoraEarMonitoringFilterNoiseSuppression
        // [self.RTCkit enableInEarMonitoring:setting.soundOn includeAudioFilters:AgoraEarMonitoringFilterBuiltInAudioFilters | AgoraEarMonitoringFilterNoiseSuppression];
        [self.RTCkit enableInEarMonitoring:setting.soundOn];
        
    } else if (type == VLKTVValueDidChangedTypeMV) { // MV
        
    } else if (type == VLKTVValueDidChangedRiseFall) { // 升降调
        // 调整当前播放的媒体资源的音调
        // 按半音音阶调整本地播放的音乐文件的音调，默认值为 0，即不调整音调。取值范围为 [-12,12]，每相邻两个值的音高距离相差半音。取值的绝对值越大，音调升高或降低得越多
        NSInteger value = setting.toneValue * 2 - 12;
        [self.rtcMediaPlayer setAudioPitch:value];
    } else if (type == VLKTVValueDidChangedTypeSound) { // 音量
        // 调节音频采集信号音量、取值范围为 [0,400]
        // 0、静音 100、默认原始音量 400、原始音量的4倍、自带溢出保护
        [self.RTCkit adjustRecordingSignalVolume:setting.soundValue * 400];
    } else if (type == VLKTVValueDidChangedTypeAcc) { // 伴奏
        int value = setting.accValue * 400;
        // 官方文档是100 ？ SDK 是 400？？？？
        // 调节本地播放音量 取值范围为 [0,100]
        // 0、无声。 100、（默认）媒体文件的原始播放音量
        [self.rtcMediaPlayer adjustPlayoutVolume:value];
        
        // 调节远端用户听到的音量 取值范围[0、400]
        // 100: （默认）媒体文件的原始音量。400: 原始音量的四倍（自带溢出保护）
        [self.rtcMediaPlayer adjustPublishSignalVolume:value];
    } else if (type == VLKTVValueDidChangedTypeListItem) {
        AgoraAudioEffectPreset preset = [self audioEffectPreset:setting.kindIndex];
        [self.RTCkit setAudioEffectPreset:preset];
    }
}
- (AgoraAudioEffectPreset)audioEffectPreset:(NSInteger)index {
    switch (index) {
        case 0:
            return AgoraAudioEffectPresetOff;
        case 1:
            return AgoraAudioEffectPresetRoomAcousticsKTV;
        case 2:
            return AgoraAudioEffectPresetRoomAcousVocalConcer;
        case 3:
            return AgoraAudioEffectPresetRoomAcousStudio;
        case 4:
            return AgoraAudioEffectPresetRoomAcousPhonograph;
        case 5:
            return AgoraAudioEffectPresetRoomAcousSpatial;
        case 6:
            return AgoraAudioEffectPresetRoomAcousEthereal;
        case 7:
            return AgoraAudioEffectPresetStyleTransformationPopular;
        case 8:
            return AgoraAudioEffectPresetStyleTransformationRnb;
        default:
            return AgoraAudioEffectPresetOff;
    }
}

//音效设置
- (void)soundEffectViewBackBtnAction {
    [self.popSoundEffectView dismiss];
}

- (void)soundEffectItemClickAction:(VLKTVSoundEffectType)effectType {
    if (effectType == VLKTVSoundEffectTypeHeFeng) {
        [self.RTCkit setAudioProfile:AgoraAudioProfileMusicHighQuality];
        [self.RTCkit setAudioEffectParameters:AgoraAudioEffectPresetPitchCorrection param1:3 param2:2];
    }else if (effectType == VLKTVSoundEffectTypeXiaoDiao){
        [self.RTCkit setAudioProfile:AgoraAudioProfileMusicHighQuality];
        [self.RTCkit setAudioEffectParameters:AgoraAudioEffectPresetPitchCorrection param1:3 param2:2];
    }else if (effectType == VLKTVSoundEffectTypeDaDiao){
        [self.RTCkit setAudioProfile:AgoraAudioProfileMusicHighQuality];
        [self.RTCkit setAudioEffectParameters:AgoraAudioEffectPresetPitchCorrection param1:3 param2:1];
    }
}

#pragma mark - AgoraRtmDelegate
- (void)rtmKit:(AgoraRtmKit *)kit connectionStateChanged:(AgoraRtmConnectionState)state reason:(AgoraRtmConnectionChangeReason)reason {
    NSString *message = [NSString stringWithFormat:@"connection state changed: %ld", state];
    VLLog(@"%@",message);
}

- (void)rtmKit:(AgoraRtmKit *)kit messageReceived:(AgoraRtmMessage *)message fromPeer:(NSString *)peerId {
    VLLog(@"messageReceived--");
}


#pragma mark - RTM 收到RTM消息
- (void)channel:(AgoraRtmChannel *)channel memberJoined:(AgoraRtmMember *)member {
    NSString *user = member.userId;
    NSString *text = [user stringByAppendingString:@" join"];
    VLLog(@"%@",text);
}

- (void)channel:(AgoraRtmChannel *)channel memberLeft:(AgoraRtmMember *)member {
    NSString *user = member.userId;
    NSString *text = [user stringByAppendingString:@" left"];
    VLLog(@"%@",text);
}

- (void)channel:(AgoraRtmChannel * _Nonnull)channel memberCount:(int)count {
    VLLog(@"memberCount::::%d",count);
    self.roomModel.roomPeopleNum = [NSString stringWithFormat:@"%d",count];
    self.topView.listModel = self.roomModel;
}

- (void)channel:(AgoraRtmChannel *)channel messageReceived:(AgoraRtmMessage *)message fromMember:(AgoraRtmMember *)member {
    AgoraRtmRawMessage *rowMessage = (AgoraRtmRawMessage *)message;
    NSDictionary *dict = [VLGlobalHelper dictionaryForJsonData:rowMessage.rawData];
    if([dict[@"messageType"] intValue] != VLSendMessageTypeSeeScore){
        VLLog(@"messageReceived::%@",dict);
    }
    if (!([dict[@"roomNo"] isEqualToString:self.roomModel.roomNo])) {
        return;
    }
    if (message.type == AgoraRtmMessageTypeRaw) {
        if ([dict[@"messageType"] intValue] == VLSendMessageTypeOnSeat) { //上麦消息
            VLRoomSeatModel *seatModel = [VLRoomSeatModel vj_modelWithDictionary:dict];
            for (VLRoomSeatModel *model in self.seatsArray) {
                if (model.onSeat == seatModel.onSeat) {
                    model.isMaster = seatModel.isMaster;
                    model.headUrl = seatModel.headUrl;
                    model.onSeat = seatModel.onSeat;
                    model.name = seatModel.name;
                    model.userNo = seatModel.userNo;
                    model.id = seatModel.id;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.roomPersonView setSeatsArray:self.seatsArray];
            });
            
        }else if([dict[@"messageType"] intValue] == VLSendMessageTypeDropSeat){  // 下麦消息
            // 下麦模型
            VLRoomSeatModel *seatModel = [VLRoomSeatModel vj_modelWithDictionary:dict];
            // 被下麦用户刷新UI
            if ([seatModel.userNo isEqualToString:VLUserCenter.user.userNo]) {
                //当前的座位用户离开RTC通道
                [self leaveRTCChannel];
                [self.MVView updateUIWithUserOnSeat:NO song:self.selSongsArray.firstObject];
                self.bottomView.hidden = YES;
                // 取出对应模型、防止数组越界
                if (self.seatsArray.count - 1 >= seatModel.onSeat) {
                    // 下麦重置占位模型
                    VLRoomSeatModel *indexSeatModel = self.seatsArray[seatModel.onSeat];
                    [indexSeatModel resetLeaveSeat];
                }
            }else{
                for (VLRoomSeatModel *model in self.seatsArray) {
                    if ([seatModel.userNo isEqualToString:model.userNo]) {
                        [model resetLeaveSeat];
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.roomPersonView setSeatsArray:self.seatsArray];
            });
            
        } else if ([dict[@"messageType"] intValue] == VLSendMessageTypeCloseRoom) {//房主关闭房间
            //发送通知
            [[NSNotificationCenter defaultCenter]postNotificationName:kExitRoomNotification object:nil];
            [self popForceLeaveRoom];
            
        }else if ([dict[@"messageType"] intValue] == VLSendMessageTypeChooseSong) {//收到点歌的消息
            //当前是否有歌曲在播放 如果没有则下载歌词准备播放,如果有则刷新列表
//            AgoraMediaPlayerState mediaState = [self.rtcMediaPlayer getPlayerState];
//            if (mediaState != AgoraMediaPlayerStatePlaying) { //当前没有在播放的歌曲
//                //获取歌曲的详情,去播放歌曲
//                [self.MVView updateMVPlayerState:VLKTVMVViewActionTypeMVPlay];
//                [self loadMusicWithURL:selSongModel.songUrl lrc:selSongModel.lyric];
//            }else{ //当前歌曲在播放
                [self getChoosedSongsList];
//            }
        }else if([dict[@"messageType"] intValue] == VLSendMessageTypeChangeSong) { //切换歌曲
            dispatch_async(dispatch_get_main_queue(), ^{
                [self playNextSong];
            });
        }else if ([dict[@"messageType"] intValue] == VLSendMessageTypeTellSingerSomeBodyJoin) {//有人加入合唱
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.MVView setJoinInViewHidden];
                [self joinChorusConfig];
                [self playSongWithPlayer:self.rtcMediaPlayer];
            });
            
        }else if([dict[@"messageType"] intValue] == VLSendMessageTypeSoloSong){ //独唱
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.MVView setJoinInViewHidden];
            });
        }else if([dict[@"messageType"] intValue] == VLSendMessageTypeChangeMVBg){ //切换背景
            VLKTVSelBgModel *selBgModel = [VLKTVSelBgModel new];
            selBgModel.imageName = [NSString stringWithFormat:@"ktv_mvbg%d",[dict[@"bgOption"] intValue]];
            selBgModel.ifSelect = YES;
            self.choosedBgModel = selBgModel;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.MVView changeBgViewByModel:selBgModel];
            });
        }else if([dict[@"messageType"] intValue] == VLSendMessageTypeAudioMute){ //是否静音
            VLRoomSeatModel *model = [VLRoomSeatModel new];
            model.userNo = dict[@"userNo"];
            model.id = dict[@"id"];
            model.isSelfMuted = [dict[@"isSelfMuted"] intValue];
            for (VLRoomSeatModel *seatModel in self.seatsArray) {
                if ([seatModel.userNo isEqualToString:model.userNo]) {
                    seatModel.isSelfMuted = model.isSelfMuted;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.roomPersonView updateSeatsByModel:seatModel];
                    });
                    break;
                }
            }
            
        }else if([dict[@"messageType"] intValue] == VLSendMessageTypeVideoIfOpen) { //是否打开视频
            VLRoomSeatModel *model = [VLRoomSeatModel new];
            model.userNo = dict[@"userNo"];
            model.id = dict[@"id"];
            model.isVideoMuted = [dict[@"isVideoMuted"] intValue];
            for (VLRoomSeatModel *seatModel in self.seatsArray) {
                if ([seatModel.userNo isEqualToString:model.userNo]) {
                    seatModel.isVideoMuted = model.isVideoMuted;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.roomPersonView updateSeatsByModel:seatModel];
                    });
                }
                
            }
            
        }else if([dict[@"messageType"] intValue] == VLSendMessageTypeSeeScore) { //观众看到打分
//            [self.MVView MVViewSetVoicePitch:[dict[@"pitch"] doubleValue]];
            double voicePitch = [dict[@"pitch"] doubleValue];
            [self.MVView setVoicePitch:@[@(voicePitch)]];
        }
    }
}
- (void)channel:(AgoraRtmChannel * _Nonnull)channel attributeUpdate:(NSArray< AgoraRtmChannelAttribute *> * _Nonnull)attributes {
    NSLog(@"%@",attributes);
}

//用户弹框离开房间
- (void)popForceLeaveRoom {
    [LEEAlert alert].config
    .LeeAddTitle(^(UILabel *label) {
        label.text = NSLocalizedString(@"房主已解散房间,请确认离开房间", nil);
        label.textColor = UIColorMakeWithHex(@"#040925");
        label.font = UIFontBoldMake(16);
    })
    .LeeAddAction(^(LEEAction *action) {
        VL(weakSelf);
        action.type = LEEActionTypeCancel;
        action.title = NSLocalizedString(@"确定", nil);
        action.titleColor = UIColorMakeWithHex(@"#FFFFFF");
        action.backgroundColor = UIColorMakeWithHex(@"#2753FF");
        action.cornerRadius = 20;
        action.height = 40;
        action.insets = UIEdgeInsetsMake(10, 20, 20, 20);
        action.font = UIFontBoldMake(16);
        action.clickBlock = ^{
            for (BaseViewController *vc in self.navigationController.childViewControllers) {
                if ([vc isKindOfClass:[VLOnLineListVC class]]) {
                    [weakSelf destroyMediaPlayer];
                    [weakSelf leaveChannel];
                    [weakSelf leaveRTCChannel];
                    [weakSelf.navigationController popToViewController:vc animated:YES];
                }
            }
        };
    })
    .LeeShow();
}

/// 当前用户是否在麦上
- (BOOL)currentUserIsOnSeat {
    if (!self.seatsArray.count) return NO;
    bool onSeat = NO;
    for (VLRoomSeatModel *seat in self.seatsArray) {
        if ([seat.userNo isEqualToString:VLUserCenter.user.userNo]) {
            return YES;
        }
    }
    return onSeat;
}

#pragma mark -- 收到RTC消息
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine
                receiveStreamMessageFromUid:(NSUInteger)uid
                streamId:(NSInteger)streamId
             data:(NSData * _Nonnull)data {    //接收到对方的RTC消息
    
    NSDictionary *dict = [VLGlobalHelper dictionaryForJsonData:data];
    VLLog(@"receiveStreamMessageFromUid::%ld---message::%@",uid, dict);

//    VLLog(@"返回数据:%@,streatID:%d,uid:%d",dict,(int)streamId,(int)uid);
    if ([dict[@"cmd"] isEqualToString:@"setLrcTime"]) {  //同步歌词
        RtcMusicLrcMessage *musicLrcMessage = [RtcMusicLrcMessage vj_modelWithDictionary:dict];
        float postion = musicLrcMessage.time / 1000.0;
        self.currentTime = postion;
        [_MVView updateMVPlayerState:VLKTVMVViewActionTypeMVPlay];
        if (!_MVView.lrcView.isStart) {
            [_MVView start];
        }
    
//        [self.rtcMediaPlayer seekToPosition:postion];
    }else if([dict[@"cmd"] isEqualToString:@"countdown"]){  //倒计时
        int leftSecond = [dict[@"time"] intValue];
        VLRoomSelSongModel *song = self.selSongsArray.count ? self.selSongsArray.firstObject : nil;
        [self.MVView receiveCountDown:leftSecond onSeat:[self currentUserIsOnSeat] currentSong:song];
        VLLog(@"收到倒计时剩余:%d秒",(int)leftSecond);
    }else if([dict[@"cmd"] isEqualToString:@"musicStopped"]){ //暂停播放
        if ([dict[@"value"] intValue] == 0) {
            if (self.rtcMediaPlayer.getPlayerState == AgoraMediaPlayerStatePlaying) {
                [self.rtcMediaPlayer pause];
            }
        }else if ([dict[@"value"] intValue] == 1){
            if (self.rtcMediaPlayer.getPlayerState == AgoraMediaPlayerStatePaused) {
                [self.rtcMediaPlayer resume];
            }
        }
    }
}

#pragma mark -- 房间麦位点击事件(上麦)
- (void)seatItemClickAction:(VLRoomSeatModel *)model withIndex:(NSInteger)seatIndex{
    [self requestOnSeatWithIndex:seatIndex];
}

- (void)requestOnSeatWithIndex:(NSInteger)index {
    NSDictionary *param = @{
        @"roomNo" : self.roomModel.roomNo,
        @"seat": @(index),
        @"userNo":VLUserCenter.user.userNo
    };
    
    @weakify(self)
    [VLAPIRequest getRequestURL:kURLRoomOnSeat parameter:param showHUD:YES success:^(VLResponseDataModel * _Nonnull response) {
        @strongify(self)
        if (response.code == 0) {
            NSDictionary *dict = @{
                @"messageType":@(VLSendMessageTypeOnSeat),
                @"headUrl":VLUserCenter.user.headUrl ? VLUserCenter.user.headUrl:@"",
                @"onSeat":@(index),
                @"name":VLUserCenter.user.name,
                @"userNo":VLUserCenter.user.userNo,
                @"id":VLUserCenter.user.id,
                @"platform":@"1",
                @"roomNo":self.roomModel.roomNo
            };
            NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
            AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
            [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
                if (errorCode == 0) {
                    VLLog(@"发送上麦消息成功");
                    dispatch_async(dispatch_get_main_queue(), ^{ //自己在该位置刷新UI
                        for (VLRoomSeatModel *model in self.seatsArray) {
                            if (model.onSeat == index) {
                                model.isMaster = false;
                                model.headUrl = VLUserCenter.user.headUrl;
                                model.onSeat = index;
                                model.name = VLUserCenter.user.name;
                                model.userNo = VLUserCenter.user.userNo;
                                model.id = VLUserCenter.user.id;
                            }
                        }
                        [self.roomPersonView setSeatsArray:self.seatsArray];
                        self.requestOnLineView.hidden = YES;
                        self.bottomView.hidden = NO;
                        [self.MVView updateUIWithUserOnSeat:YES song:self.selSongsArray.firstObject];
                        [self.RTCkit setClientRole:AgoraClientRoleBroadcaster];
                    });
                }
            }];
        }
    } failure:^(NSError * _Nullable error) {

    }];
}

//房主让某人下线
- (void)roomMasterMakePersonDropOnLineWithIndex:(NSInteger)seatIndex withDropType:(VLRoomSeatDropType)type{
    VLRoomSeatModel *seatModel = self.seatsArray[seatIndex];
    if (self.selSongsArray.count > 0) {
        VLRoomSelSongModel *selSongModel = self.selSongsArray.firstObject;
        if ([selSongModel.userNo isEqualToString:seatModel.userNo]) {   //当前点的歌
            return;
        }
    }
    [self popDropLineViewWithSeatModel:seatModel];
}

#pragma mark --

- (void)dianGeSuccessEvent:(NSNotification *)notification {
    [self sendDianGeMessage];
    [self getChoosedSongsList];
}

- (void)sendDianGeMessage {
    //发送消息
    NSDictionary *dict = @{
        @"messageType":@(VLSendMessageTypeChooseSong),
        @"platform":@"1",
        @"roomNo":self.roomModel.roomNo
    };
    NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
    AgoraRtmRawMessage *roaMessage = [[AgoraRtmRawMessage alloc]initWithRawData:messageData description:@""];
    [self.rtmChannel sendMessage:roaMessage completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
        if (errorCode == 0) {
            VLLog(@"发送点歌消息成功");
        }
    }];
}

- (void)makeTopSuccessEvent {
    [self choosedSongsListToChangeUI];
}

- (void)deleteSuccessEvent {
    [self choosedSongsListToChangeUI];
}

- (void)getChoosedSongsList {
    NSDictionary *param = @{
        @"roomNo" : self.roomModel.roomNo
    };
    [VLAPIRequest getRequestURL:kURLChoosedSongs parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            self.selSongsArray = [VLRoomSelSongModel vj_modelArrayWithJson:response.data];
            if (self.chooseSongView) {
                self.chooseSongView.selSongsArray = self.selSongsArray; //刷新已点歌曲UI
            }
            [self.MVView updateUIWithSong:self.selSongsArray.firstObject onSeat:[self currentUserIsOnSeat]];
            [self.roomPersonView updateSingBtnWithChoosedSongArray:self.selSongsArray];

            if (!(self.selSongsArray.count > 0)){
                return;
            }
            VLRoomSelSongModel *selSongModel = self.selSongsArray.firstObject;
            NSDictionary *param = @{
                @"lyricType" : @(0),
                @"songCode": selSongModel.songNo
            };
            [VLAPIRequest getRequestURL:kURLSongDetail parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
                if (response.code == 0) {     //拿到歌曲和歌词
                    selSongModel.lyric = response.data[@"data"][@"lyric"];
                    selSongModel.songUrl = response.data[@"data"][@"playUrl"];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.MVView updateMVPlayerState:VLKTVMVViewActionTypeMVPlay];
                        [self loadMusicWithURL:selSongModel.songUrl lrc:selSongModel.lyric songCode:selSongModel.songNo];
                    });
                }
            } failure:^(NSError * _Nullable error) {
                
            }];
        }
    } failure:^(NSError * _Nullable error) {
        
    }];
}

- (void)choosedSongsListToChangeUI {
    NSDictionary *param = @{
        @"roomNo" : self.roomModel.roomNo
    };
    [VLAPIRequest getRequestURL:kURLChoosedSongs parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            self.selSongsArray = [VLRoomSelSongModel vj_modelArrayWithJson:response.data];
            if (self.chooseSongView) {
                self.chooseSongView.selSongsArray = self.selSongsArray; //刷新已点歌曲UI
            }
            //刷新MV里的视图
            [self.MVView updateUIWithSong:self.selSongsArray.firstObject onSeat:[self currentUserIsOnSeat]];
        }
    } failure:^(NSError * _Nullable error) {
        
    }];
}

- (void)userFirstGetInRoom {
    NSDictionary *param = @{
        @"roomNo" : self.roomModel.roomNo
    };
    [VLAPIRequest getRequestURL:kURLChoosedSongs parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            self.selSongsArray = [VLRoomSelSongModel vj_modelArrayWithJson:response.data];
            if (self.chooseSongView) {
                self.chooseSongView.selSongsArray = self.selSongsArray; //刷新已点歌曲UI
            }
            //刷新MV里的视图
            [self.MVView updateUIWithSong:self.selSongsArray.firstObject onSeat:[self currentUserIsOnSeat]];
            if (!(self.selSongsArray.count > 0)) {
                return;
            }
            //拿到当前歌的歌词去播放和同步歌词
            VLRoomSelSongModel *selSongModel = self.selSongsArray.firstObject;
            if (selSongModel.status == 2) { //歌曲正在播放
                //请求歌词和歌曲
                NSDictionary *param = @{
                    @"lyricType" : @(0),
                    @"songCode": selSongModel.songNo
                };
                [VLAPIRequest getRequestURL:kURLSongDetail parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
                    if (response.code == 0) {     //拿到歌曲和歌词
                        selSongModel.lyric = response.data[@"data"][@"lyric"];
                        selSongModel.songUrl = response.data[@"data"][@"playUrl"];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.MVView updateMVPlayerState:VLKTVMVViewActionTypeMVPlay];
                            [self loadMusicWithURL:selSongModel.songUrl lrc:selSongModel.lyric songCode:selSongModel.songNo];
                        });
                    }
                } failure:^(NSError * _Nullable error) {
                    
                }];
            }
        }
    } failure:^(NSError * _Nullable error) {
    }];
}

//主唱告诉后台当前播放的歌曲
- (void)tellSeverTheCurrentPlaySongWithModel:(VLRoomSelSongModel *)selSongModel {
    NSDictionary *param = @{
        @"imageUrl":selSongModel.imageUrl,
        @"isChorus":@(selSongModel.isChorus),
        @"score":@"",
        @"singer":selSongModel.singer,
        @"songName":selSongModel.songName,
        @"songNo":selSongModel.songNo,
        @"songUrl":selSongModel.songUrl,
        @"userNo":selSongModel.userNo,
        @"roomNo":self.roomModel.roomNo
    };
    [VLAPIRequest getRequestURL:kURLBeginSinging parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            VLLog(@"告诉后台成功");
        }else{
        }
    } failure:^(NSError * _Nullable error) {
        
    }];
}

#pragma mark - Lazy

- (id<AgoraRtcMediaPlayerProtocol>)rtcMediaPlayer {
    if (!_rtcMediaPlayer) {
//        _rtcMediaPlayer = [self.RTCkit createMediaPlayerWithDelegate:self];
        _rtcMediaPlayer = [self.AgoraMcc createMusicPlayerWithDelegate:self];
        // 调节本地播放音量。0-100
         [_rtcMediaPlayer adjustPlayoutVolume:200];
//         调节远端用户听到的音量。0-400
         [_rtcMediaPlayer adjustPublishSignalVolume:200];
    }
    return _rtcMediaPlayer;
}

- (VLKTVSettingView *)settingView {
    if (!_settingView) {
        _settingView = [[VLKTVSettingView alloc] initWithSetting:nil];
        _settingView.backgroundColor = UIColorMakeWithHex(@"#152164");
        [_settingView vl_radius:20 corner:UIRectCornerTopLeft | UIRectCornerTopRight];
        _settingView.delegate = self;
    }
    return _settingView;
}



- (void)onLyricResult:(nonnull NSString *)requestId lyricUrl:(nonnull NSString *)lyricUrl {
    
}

- (void)onMusicChartsResult:(nonnull NSString *)requestId status:(AgoraMusicContentCenterStatusCode)status result:(nonnull NSArray<MusicChartInfo *> *)result {
    VLLog(@"Music charts - ");
}

- (void)onMusicCollectionResult:(nonnull NSString *)requestId status:(AgoraMusicContentCenterStatusCode)status result:(nonnull AgoraMusicCollection *)result {
    
}

- (void)onPreLoadEvent:(NSInteger)songCode percent:(NSInteger)percent status:(AgoraMusicContentCenterPreloadStatus)status msg:(nonnull NSString *)msg lyricUrl:(nonnull NSString *)lyricUrl {
    if (status == AgoraMusicContentCenterPreloadStatusOK) {
        [self playMusic:songCode];
    }
    else if(status == AgoraMusicContentCenterPreloadStatusPreloading) {
        // Do nothing.
    }
    else {
        dispatch_main_async_safe(^{
            [VLToast toast:NSLocalizedString(@"加载歌曲失败", nil)];
        })
    }
}

@end