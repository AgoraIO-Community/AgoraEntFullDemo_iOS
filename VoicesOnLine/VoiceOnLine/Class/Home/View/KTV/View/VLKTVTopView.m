//
//  VLKTVTopView.m
//  VoiceOnLine
//

#import "VLKTVTopView.h"
#import "VLRoomListModel.h"

@interface VLKTVTopView ()

@property(nonatomic, weak) id <VLKTVTopViewDelegate>delegate;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) QMUIButton *networkStatusBtn;
@property (nonatomic, strong) UILabel *countLabel;

@end

@implementation VLKTVTopView

- (instancetype)initWithFrame:(CGRect)frame withDelegate:(id<VLKTVTopViewDelegate>)delegate {
    if (self = [super initWithFrame:frame]) {
        self.delegate = delegate;
        [self setupView];
    }
    return self;
}

- (void)setupView {
    UIImageView *logoImgView = [[UIImageView alloc]initWithFrame:CGRectMake(20, 10, 20, 20)];
    logoImgView.image = UIImageMake(@"ktv_logo_icon");
    [self addSubview:logoImgView];
    
    VLHotSpotBtn *closeBtn = [[VLHotSpotBtn alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-27-20, logoImgView.top, 20, 20)];
    [closeBtn setImage:UIImageMake(@"ktv_close_icon") forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnEvent) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:closeBtn];
    
    self.titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(logoImgView.right+5, logoImgView.centerY-11, 120, 22)];
    self.titleLabel.font = UIFontBoldMake(16);
    self.titleLabel.textColor = UIColorWhite;
    [self addSubview:self.titleLabel];
    
    self.networkStatusBtn = [[QMUIButton alloc] qmui_initWithImage:UIImageMake(@"ktv_network_wellIcon") title:NSLocalizedString(@"本机网络好", nil)];
    self.networkStatusBtn.frame = CGRectMake(closeBtn.left-15-75, closeBtn.top, 75, 20);
    self.networkStatusBtn.imagePosition = QMUIButtonImagePositionLeft;
    self.networkStatusBtn.spacingBetweenImageAndTitle = 4;
    self.networkStatusBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.networkStatusBtn setTitleColor:UIColorMakeWithHex(@"#979CBB") forState:UIControlStateNormal];
    self.networkStatusBtn.titleLabel.font = UIFontMake(10.0);
    [self addSubview:self.networkStatusBtn];
    
    self.countLabel = [[UILabel alloc]initWithFrame:CGRectMake(logoImgView.left, logoImgView.bottom+10, 120, 14)];
    self.countLabel.font = UIFontMake(10);
    self.countLabel.textColor = UIColorMakeWithHex(@"#979CBB");
    [self addSubview:self.countLabel];
}

#pragma mark --Event
- (void)closeBtnEvent {
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeBtnAction)]) {
        [self.delegate closeBtnAction];
    }
}

- (void)setListModel:(VLRoomListModel *)listModel {
    _listModel = listModel;
    self.titleLabel.text = listModel.name;
    if (listModel.roomPeopleNum) {
        self.countLabel.text = [NSString stringWithFormat:NSLocalizedString(@"当前在线人数：%@", nil), listModel.roomPeopleNum];
    }else{
        self.countLabel.text = NSLocalizedString(@"当前在线人数：1", nil);
    }
}

@end
