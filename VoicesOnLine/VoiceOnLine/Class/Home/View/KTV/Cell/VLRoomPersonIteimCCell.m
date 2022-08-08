//
//  VLRoomPersonIteimCCell.m
//  VoiceOnLine
//

#import "VLRoomPersonIteimCCell.h"
#import "VLRoomSeatModel.h"


@interface VLRoomPersonIteimCCell()

//@property (nonatomic, strong) AgoraRtcChannelMediaOptions *mediaOption;

@end

@implementation VLRoomPersonIteimCCell

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        [self setupView];
    }
    return self;
}
#pragma mark - Intial Methods
- (void)setupView {
    
    self.avatarImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, VLREALVALUE_WIDTH(54),  VLREALVALUE_WIDTH(54))];
    self.avatarImgView.layer.cornerRadius = VLREALVALUE_WIDTH(54)*0.5;
    self.avatarImgView.layer.masksToBounds = YES;
    self.avatarImgView.userInteractionEnabled = YES;
    [self.contentView addSubview:self.avatarImgView];
    
    self.videoView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, VLREALVALUE_WIDTH(54), VLREALVALUE_WIDTH(54))];
    self.videoView.layer.cornerRadius = VLREALVALUE_WIDTH(54)*0.5;
    self.videoView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.videoView];
    
    self.avatarCoverBgView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, VLREALVALUE_WIDTH(54), VLREALVALUE_WIDTH(54))];
    self.avatarCoverBgView.userInteractionEnabled = YES;
    self.avatarCoverBgView.backgroundColor = UIColorMakeWithRGBA(0, 0, 0, 0.6);
    self.avatarCoverBgView.layer.cornerRadius = VLREALVALUE_WIDTH(54)*0.5;
    self.avatarCoverBgView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.avatarCoverBgView];
    

    
    self.roomerImgView = [[UIImageView alloc]initWithFrame:CGRectMake((VLREALVALUE_WIDTH(54)-34)*0.5, VLREALVALUE_WIDTH(54)-12, 34, 12)];
    self.roomerImgView.image = UIImageMake(@"ktv_roomOwner_icon");
    [self.contentView addSubview:self.roomerImgView];
    
    self.roomerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 34, 11)];
    self.roomerLabel.font = UIFontMake(8);
    self.roomerLabel.textColor = UIColorMakeWithHex(@"#DBDAE9");
    self.roomerLabel.textAlignment = NSTextAlignmentCenter;
    [self.roomerImgView addSubview:self.roomerLabel];
    
    self.nickNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(2, self.avatarImgView.bottom+2, VLREALVALUE_WIDTH(54)-4, 17)];
    self.nickNameLabel.font = UIFontMake(12);
    self.nickNameLabel.textColor = UIColorMakeWithHex(@"#DBDAE9");
    self.nickNameLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.nickNameLabel];
    
    self.muteImgView = [[UIImageView alloc]initWithFrame:CGRectMake(VLREALVALUE_WIDTH(54)/2-12, VLREALVALUE_WIDTH(54)/2-12, 24, 24)];
    self.muteImgView.image = [UIImage imageNamed:@"ktv_self_seatMute"];
    self.muteImgView.userInteractionEnabled = YES;
    [self.contentView addSubview:self.muteImgView];
    
    self.singingBtn = [[QMUIButton alloc] qmui_initWithImage:UIImageMake(@"ktv_seatsinging_icon") title:NSLocalizedString(@"主唱", nil)];
    self.singingBtn.frame = CGRectMake((self.width-36)*0.5, self.nickNameLabel.bottom+2, 36, 12);
    self.singingBtn.layer.cornerRadius = 6;
    self.singingBtn.layer.masksToBounds = YES;
    self.singingBtn.imagePosition = QMUIButtonImagePositionLeft;
    self.singingBtn.spacingBetweenImageAndTitle = 2;
    self.singingBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.singingBtn setTitleColor:UIColorMakeWithHex(@"#FFFFFF") forState:UIControlStateNormal];
    self.singingBtn.titleLabel.font = UIFontMake(8);
    self.singingBtn.userInteractionEnabled = NO;
    self.singingBtn.backgroundColor = UIColorMakeWithRGBA(0, 0, 0, 0.5);
    self.singingBtn.alpha = 0.6;
    [self.contentView addSubview:self.singingBtn];
}

@end
