//
//  VLKTVBottomView.m
//  VoiceOnLine
//

#import "VLKTVBottomView.h"

typedef void (^actionSuccess)(BOOL ifSuccess);

@interface VLKTVBottomView ()

@property(nonatomic, weak) id <VLKTVBottomViewDelegate>delegate;
@property (nonatomic, copy) NSString *roomNo;
@property (nonatomic, strong) NSArray <VLRoomSeatModel *> *seatsArray;
@property (nonatomic, assign) NSInteger isSelfMuted;
@property (nonatomic, assign) NSInteger isVideoMuted;
@property (nonatomic, strong)VLHotSpotBtn *audioBtn;
@property (nonatomic, strong)VLHotSpotBtn *videoBtn;
@end

@implementation VLKTVBottomView

- (instancetype)initWithFrame:(CGRect)frame withDelegate:(id<VLKTVBottomViewDelegate>)delegate withRoomNo:(NSString *)roomNo withData:(NSArray <VLRoomSeatModel *> *)seatsArray{
    if (self = [super initWithFrame:frame]) {
        self.delegate = delegate;
        self.roomNo = roomNo;
        self.seatsArray = seatsArray;
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.audioBtn = [[VLHotSpotBtn alloc]initWithFrame:CGRectMake(25, (self.height-24)*0.5, 24, 24)];
    [self.audioBtn setImage:UIImageMake(@"ktv_audio_icon") forState:UIControlStateNormal];
    [self.audioBtn setImage:UIImageMake(@"ktv_audio_icon") forState:UIControlStateSelected];
    self.audioBtn.tag = VLKTVBottomBtnClickTypeAudio;
    [self.audioBtn addTarget:self action:@selector(bottomBtnClickEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.audioBtn];
    
    self.videoBtn = [[VLHotSpotBtn alloc]initWithFrame:CGRectMake(self.audioBtn.right+15, (self.height-24)*0.5, 24, 24)];
    [self.videoBtn setImage:UIImageMake(@"ktv_video_muteIcon") forState:UIControlStateNormal];
    [self.videoBtn setImage:UIImageMake(@"ktv_video_muteIcon") forState:UIControlStateSelected];
    self.videoBtn.tag = VLKTVBottomBtnClickTypeVideo;
    [self.videoBtn addTarget:self action:@selector(bottomBtnClickEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.videoBtn];
    
    VLHotSpotBtn *moreBtn = [[VLHotSpotBtn alloc]initWithFrame:CGRectMake(self.videoBtn.right+15, (self.height-24)*0.5, 24, 24)];
    [moreBtn setImage:UIImageMake(@"ktv_moreItem_icon") forState:UIControlStateNormal];
    moreBtn.tag = VLKTVBottomBtnClickTypeMore;
    [moreBtn addTarget:self action:@selector(bottomBtnClickEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:moreBtn];
    
    VLHotSpotBtn *dianGeBtn = [[VLHotSpotBtn alloc]initWithFrame:CGRectMake(self.width-20-70, (self.height-32)*0.5, 70, 32)];
    [dianGeBtn setImage:UIImageMake(@"ktv_diange_icon") forState:UIControlStateNormal];
    [dianGeBtn addTarget:self action:@selector(bottomBtnClickEvent:) forControlEvents:UIControlEventTouchUpInside];
    dianGeBtn.tag = VLKTVBottomBtnClickTypeChoose;
    [self addSubview:dianGeBtn];
    
    VLHotSpotBtn *heChangeBtn = [[VLHotSpotBtn alloc]initWithFrame:CGRectMake(dianGeBtn.left-20-70, (self.height-32)*0.5, 70, 32)];
    heChangeBtn.tag = VLKTVBottomBtnClickTypeChorus;
    [heChangeBtn setImage:UIImageMake(@"ktv_hechang_icon") forState:UIControlStateNormal];
    [heChangeBtn addTarget:self action:@selector(bottomBtnClickEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:heChangeBtn];
    
    for (VLRoomSeatModel *info in self.seatsArray) {
        if ([info.id integerValue] == [VLUserCenter.user.id integerValue]) {
            self.isSelfMuted = info.isSelfMuted;
            self.isVideoMuted = info.isVideoMuted;

            if (info.isSelfMuted == 0) {
                [self.audioBtn setImage:UIImageMake(@"ktv_audio_icon") forState:UIControlStateNormal];
            }
            else{
                [self.audioBtn setImage:UIImageMake(@"ktv_self_muteIcon") forState:UIControlStateNormal];
            }
            if (info.isVideoMuted == 1) {
                [self.videoBtn setImage:UIImageMake(@"ktv_video_icon") forState:UIControlStateNormal];
            }
            else{
                [self.videoBtn setImage:UIImageMake(@"ktv_video_muteIcon") forState:UIControlStateNormal];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(bottomSetAudioMute:)]) {
                [self.delegate bottomSetAudioMute:info.isSelfMuted];
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(bottomSetVideoMute:)]) {
                [self.delegate bottomSetVideoMute:info.isVideoMuted];
            }
            break;
        }
    }
}

- (void)bottomBtnClickEvent:(VLHotSpotBtn *)sender {
    if (sender.tag == VLKTVBottomBtnClickTypeAudio) {
        NSDictionary *param = @{
            @"roomNo": self.roomNo,
            @"userNo": VLUserCenter.user.userNo
        };
        [VLAPIRequest getRequestURL:kURLIfSetMute parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
            if (response.code == 0) {
                if (self.isSelfMuted == 1) {
                    self.isSelfMuted = 0;
                }
                else{
                    self.isSelfMuted = 1;
                }
                if (self.delegate && [self.delegate respondsToSelector:@selector(bottomAudionBtnAction:)]) {
                    [self.delegate bottomAudionBtnAction:self.isSelfMuted];
                }
                if (self.delegate && [self.delegate respondsToSelector:@selector(bottomSetAudioMute:)]) {
                    [self.delegate bottomSetAudioMute:self.isSelfMuted];
                }
               
                if (self.isSelfMuted == 0){
                    [self.audioBtn setImage:UIImageMake(@"ktv_audio_icon") forState:UIControlStateNormal];
                }
                else{
                    [self.audioBtn setImage:UIImageMake(@"ktv_self_muteIcon") forState:UIControlStateNormal];
                }
                
               
            }
        } failure:^(NSError * _Nullable error) {
            
        }];
    
    }else if (sender.tag == VLKTVBottomBtnClickTypeVideo){
        NSDictionary *param = @{
            @"roomNo": self.roomNo,
            @"userNo": VLUserCenter.user.userNo
        };
        [VLAPIRequest getRequestURL:kURLIfOpenVido parameter:param showHUD:NO success:^(VLResponseDataModel * _Nonnull response) {
            if (response.code == 0) {
                if (self.isVideoMuted == 1) {
                    self.isVideoMuted = 0;
                }
                else{
                    self.isVideoMuted = 1;
                }
                if (self.delegate && [self.delegate respondsToSelector:@selector(bottomSetVideoMute:)]) {
                    [self.delegate bottomSetVideoMute:self.isVideoMuted];
                }
                if (self.delegate && [self.delegate respondsToSelector:@selector(bottomVideoBtnAction:)]) {
                    [self.delegate bottomVideoBtnAction:self.isVideoMuted];
                }
                if (self.isVideoMuted == 1) {
                    [self.videoBtn setImage:UIImageMake(@"ktv_video_icon") forState:UIControlStateNormal];
                }
                else{
                    [self.videoBtn setImage:UIImageMake(@"ktv_video_muteIcon") forState:UIControlStateNormal];
                }
            }
        } failure:^(NSError * _Nullable error) {
            
        }];
    }else{
        if (self.delegate && [self.delegate respondsToSelector:@selector(bottomBtnsClickAction: withSender:)]) {
            [self.delegate bottomBtnsClickAction:sender.tag withSender:sender];
        }
    }
    
}

@end
