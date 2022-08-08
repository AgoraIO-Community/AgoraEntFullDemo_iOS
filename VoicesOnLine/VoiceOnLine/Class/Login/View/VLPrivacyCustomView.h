//
//  VLPrivacyCustomView.h
//  VoiceOnLine
//

#import "VLBaseView.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    VLPrivacyClickTypeAgree = 0,
    VLPrivacyClickTypeDisagree,
    VLPrivacyClickTypePrivacy,
} VLPrivacyClickType;

@protocol VLPrivacyCustomViewDelegate <NSObject>

- (void)privacyCustomViewDidClick:(VLPrivacyClickType)type;

@end

@interface VLPrivacyCustomView : VLBaseView

@property (nonatomic, weak) id <VLPrivacyCustomViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
