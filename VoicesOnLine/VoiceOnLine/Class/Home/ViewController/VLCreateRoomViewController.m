//
//  VLCreateRoomViewController.m
//  VoiceOnLine
//

#import "VLCreateRoomViewController.h"
#import <AgoraRtcKit/AgoraRtcKit.h>
#import "VLCreateRoomView.h"
#import "VLKTVViewController.h"
#import "VLRoomSeatModel.h"
#import "VLRoomListModel.h"
#import "AgoraRtm.h"
#import "VLAddRoomModel.h"
#import "VLConfig.h"

@interface VLCreateRoomViewController ()<VLCreateRoomViewDelegate,AgoraRtmDelegate>
@property (nonatomic, strong) AgoraRtcEngineKit *RTCkit;

@end

@implementation VLCreateRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AgoraRtcEngineConfig *config = [[AgoraRtcEngineConfig alloc]init];
    config.appId = AGORA_APP_ID;
    config.audioScenario = AgoraAudioScenarioChorus;
    config.channelProfile = AgoraChannelProfileLiveBroadcasting;
    self.RTCkit = [AgoraRtcEngineKit sharedEngineWithConfig:config delegate:nil];
    /// 开启唱歌评分功能
    int code = [self.RTCkit enableAudioVolumeIndication:20 smooth:3 reportVad:YES];
    if (code == 0) {
        VLLog(@"评分回调开启成功\n");
    } else {
        VLLog(@"评分回调开启失败：%d\n",code);
    }
    [self commonUI];
    [self setUpUI];
    
}

- (void)commonUI {
    [self setBackgroundImage:@"online_list_BgIcon"];
    [self setNaviTitleName:NSLocalizedString(@"创建房间", nil)];
    [self setBackBtn];
}

#pragma mark - Public Methods
- (void)configNavigationBar:(UINavigationBar *)navigationBar {
    [super configNavigationBar:navigationBar];
}
- (BOOL)preferredNavigationBarHidden {
    return true;
}

- (void)createBtnAction:(VLAddRoomModel *)roomModel {  //房主创建
    NSDictionary *param = @{
        @"belCanto": @"0",
        @"icon": [NSString stringWithFormat:@"%@",roomModel.icon],
        @"isPrivate":roomModel.isPrivate ? @(1) : @(0),
        @"name": [NSString stringWithFormat:@"%@",roomModel.name],
        @"password": roomModel.password.length > 0 ? [NSString stringWithFormat:@"%@",roomModel.password] : @"",
        @"soundEffect": @"0",
        @"userNo": VLUserCenter.user.userNo
    };
    [VLAPIRequest postRequestURL:kURLCreateRoom parameter:param showHUD:YES success:^(VLResponseDataModel * _Nonnull response) {
        if (response.code == 0) {
            NSDictionary *param = @{
                @"roomNo" : response.data,
                @"userNo":VLUserCenter.user.userNo,
                @"password":roomModel.password.length > 0 ? [NSString stringWithFormat:@"%@",roomModel.password] : @""
            };
            VLRoomListModel *listModel = [[VLRoomListModel alloc]init];
            
            [VLAPIRequest getRequestURL:kURLGetInRoom parameter:param showHUD:YES success:^(VLResponseDataModel * _Nonnull response) {
                if (response.code == 0) {
                    [AgoraRtm updateDelegate:self];
                    if ([response.data[@"creatorNo"] isEqualToString:VLUserCenter.user.userNo]) { //自己是房主
                        VLUserCenter.user.ifMaster = YES;
                    }else{
                        VLUserCenter.user.ifMaster = NO;
                    }
                    
                    VLUserCenter.user.agoraRTCToken = response.data[@"agoraRTCToken"];
                    VLUserCenter.user.agoraRTMToken = response.data[@"agoraRTMToken"];
                    VLLog(@"Agora - RTCToken: %@, RTMToken: %@, UID: %@, roomNo: %@", VLUserCenter.user.agoraRTCToken, VLUserCenter.user.agoraRTMToken, VLUserCenter.user.id, param[@"roomNo"]);
                    [AgoraRtm.kit loginByToken:VLUserCenter.user.agoraRTMToken user:VLUserCenter.user.id completion:^(AgoraRtmLoginErrorCode errorCode) {
                        if (!(errorCode == AgoraRtmLoginErrorOk || errorCode == AgoraRtmLoginErrorAlreadyLogin)) {
                            VLLog(@"Agora - 加入RTM失败");
                            return;
                        }
                        [AgoraRtm setStatus:LoginStatusOnline];
                        //登录RTC
                        [self.RTCkit joinChannelByToken:VLUserCenter.user.agoraRTCToken channelId:listModel.roomNo info:nil uid:[VLUserCenter.user.id integerValue] joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
                            VLLog(@"Agora - 加入RTC成功");
                            [self.RTCkit setClientRole:AgoraClientRoleBroadcaster];
                        }];
                        //处理座位信息
                        listModel.roomNo = response.data[@"roomNo"];
                        listModel.name = response.data[@"name"];
                        listModel.bgOption = 0;
                        NSArray *seatsArray = response.data[@"roomUserInfoDTOList"];
                        VLKTVViewController *ktvVC = [[VLKTVViewController alloc]init];
                        ktvVC.roomModel = listModel;
                        ktvVC.seatsArray = [self configureSeatsWithArray:seatsArray];
                        [self.navigationController pushViewController:ktvVC animated:YES];
                    }];
                }else{
                    [VLToast toast:NSLocalizedString(@"加入房间失败", nil)];
                }
                
            } failure:^(NSError * _Nullable error) {
                [VLToast toast:NSLocalizedString(@"加入房间失败", nil)];
            }];
            
        }else{
            [VLToast toast:response.message];
        }
    } failure:^(NSError * _Nullable error) {
        [VLToast toast:NSLocalizedString(@"创建房间失败", nil)];
    }];
}

- (NSArray *)configureSeatsWithArray:(NSArray *)seatsArray {
    NSMutableArray *seatMuArray = [NSMutableArray array];
    NSArray *modelArray = [VLRoomSeatModel vj_modelArrayWithJson:seatsArray];
    for (int i=0; i<8; i++) {
        BOOL ifFind = NO;
        for (VLRoomSeatModel *model in modelArray) {
            if (model.onSeat == i) { //这个位置已经有人了
                ifFind = YES;
                [seatMuArray addObject:model];
            }
        }
        if (!ifFind) {
            VLRoomSeatModel *model = [[VLRoomSeatModel alloc]init];
            model.onSeat = i;
            [seatMuArray addObject:model];
        }
    }
    return seatMuArray.mutableCopy;
}

- (void)setUpUI {
    VLCreateRoomView *createRoomView = [[VLCreateRoomView alloc]initWithFrame:CGRectMake(0, kTopNavHeight, SCREEN_WIDTH, SCREEN_HEIGHT-kTopNavHeight) withDelegate:self];
    [self.view addSubview:createRoomView];
}



@end
