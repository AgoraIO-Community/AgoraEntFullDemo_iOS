//
//  VLPrivacyCustomView.m
//  VoiceOnLine
//

#import "VLPrivacyCustomView.h"

@interface VLPrivacyCustomView()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) YYLabel *label;
@property (nonatomic, strong) UIButton *disButton;
@property (nonatomic, strong) UIButton *agreeButton;

@end

@implementation VLPrivacyCustomView

- (instancetype)init {
    if (self = [super init]) {
        [self initSubViews];
        [self addSubViewConstraints];
    }
    return self;
}

- (void)initSubViews {
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.label];
    
    [self addSubview:self.disButton];
    [self addSubview:self.agreeButton];
}

- (void)addSubViewConstraints {
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(self);
        make.height.mas_greaterThanOrEqualTo(200);
    }];
    
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.scrollView);
    }];
    
    [self.disButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.scrollView.mas_bottom).offset(20);
        make.left.mas_equalTo(0);
        make.width.mas_equalTo(115);
        make.height.mas_equalTo(40);
    }];
    
    [self.agreeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(115);
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(self.scrollView.mas_bottom).offset(20);
        make.right.mas_equalTo(0);
    }];
}

- (void)buttonClick:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(privacyCustomViewDidClick:)]) {
        VLPrivacyClickType type;
        if (sender == self.agreeButton) {
            type = VLPrivacyClickTypeAgree;
        } else {
            type = VLPrivacyClickTypeDisagree;
        }
        [self.delegate privacyCustomViewDidClick:type];
    }
}

#pragma mark - Lazy

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
    }
    return _scrollView;
}

- (YYLabel *)label {
    if (!_label) {
        _label = [[YYLabel alloc] init];
        _label.numberOfLines = 0;
        _label.textColor = UIColorMakeWithHex(@"#6C7192");
        _label.font = VLUIFontMake(12);
        _label.preferredMaxLayoutWidth = 250;
        
        NSString *_str4Total = NSLocalizedString(@"我已阅读并同意 用户协议 及 隐私政策 我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意我已阅读并同意\n我已阅读并同意我已阅读并同意我已阅读并同意\n我已阅读并同意我已阅读并同意我已阅读并同意", nil);
        NSString *_str4Highlight1 = NSLocalizedString(@"用户协议", nil);
        NSString *_str4Highlight2 = NSLocalizedString(@"隐私政策", nil);
        NSMutableAttributedString *_mattrStr = [NSMutableAttributedString new];
        
        [_mattrStr appendAttributedString:[[NSAttributedString alloc] initWithString:_str4Total attributes:@{NSFontAttributeName : VLUIFontMake(12), NSForegroundColorAttributeName : UIColorMakeWithHex(@"#6C7192")}]];
        _mattrStr.yy_lineSpacing = 6;
        NSRange range1 = [_str4Total rangeOfString:_str4Highlight1];
        NSRange range2 = [_str4Total rangeOfString:_str4Highlight2];
        [_mattrStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:range1];
        [_mattrStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:range2];
        if(range1.location != NSNotFound){
            kWeakSelf(self)
            [_mattrStr yy_setTextHighlightRange:range1 color:UIColorMakeWithHex(@"#009FFF") backgroundColor:[UIColor clearColor] tapAction:^(UIView * _Nonnull containerView, NSAttributedString * _Nonnull text, NSRange range, CGRect rect) {
                if ([weakself.delegate respondsToSelector:@selector(privacyCustomViewDidClick:)]) {
                    [weakself.delegate privacyCustomViewDidClick:VLPrivacyClickTypePrivacy];
                }
            }];
        }
        if(range2.location != NSNotFound){
            kWeakSelf(self)
            [_mattrStr yy_setTextHighlightRange:range2 color:UIColorMakeWithHex(@"#009FFF") backgroundColor:[UIColor clearColor] tapAction:^(UIView * _Nonnull containerView, NSAttributedString * _Nonnull text, NSRange range, CGRect rect) {
                if ([weakself.delegate respondsToSelector:@selector(privacyCustomViewDidClick:)]) {
                    [weakself.delegate privacyCustomViewDidClick:VLPrivacyClickTypePrivacy];
                }
            }];
        }
        _label.lineBreakMode = NSLineBreakByWordWrapping;
        _label.attributedText = _mattrStr;
    }
    return _label;
}

- (UIButton *)disButton {
    if (!_disButton) {
        _disButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_disButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [_disButton setTitle:NSLocalizedString(@"不同意", nil) forState:UIControlStateNormal];
        [_disButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _disButton.titleLabel.font = VLUIFontMake(16);
        [_disButton setBackgroundColor:UIColorMakeWithHex(@"#EFF4FF")];
        _disButton.layer.backgroundColor = [UIColor colorWithRed:239/255.0 green:244/255.0 blue:255/255.0 alpha:1.0].CGColor;
        _disButton.layer.cornerRadius = 20;
        _disButton.layer.shadowColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.23].CGColor;
        _disButton.layer.shadowOffset = CGSizeMake(0,5);
        _disButton.layer.shadowOpacity = 1;
        _disButton.layer.shadowRadius = 20;
    }
    return _disButton;
}

- (UIButton *)agreeButton {
    if (!_agreeButton) {
        _agreeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_agreeButton addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [_agreeButton setTitle:NSLocalizedString(@"同意", nil) forState:UIControlStateNormal];
        [_agreeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _agreeButton.titleLabel.font = VLUIFontMake(16);
        [_agreeButton setBackgroundColor:UIColorMakeWithHex(@"#2753FF")];
        // gradient
        CAGradientLayer *gl = [CAGradientLayer layer];
        gl.frame = CGRectMake(197.5,498.5,115,40);
        gl.startPoint = CGPointMake(0.43, 0);
        gl.endPoint = CGPointMake(0.43, 1);
        gl.colors = @[(__bridge id)[UIColor colorWithRed:11/255.0 green:138/255.0 blue:242/255.0 alpha:1].CGColor, (__bridge id)[UIColor colorWithRed:39/255.0 green:83/255.0 blue:255/255.0 alpha:1].CGColor];
        gl.locations = @[@(0), @(1.0f)];
        _agreeButton.layer.cornerRadius = 20;
        _agreeButton.layer.shadowColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.1000].CGColor;
        _agreeButton.layer.shadowOffset = CGSizeMake(0,5);
        _agreeButton.layer.shadowOpacity = 1;
        _agreeButton.layer.shadowRadius = 20;
    }
    return _agreeButton;
}

@end
