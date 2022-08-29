//
//  VLLoginModel.h
//  VoiceOnLine
//

#import "VLBaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLLoginModel : VLBaseModel

@property (nonatomic, copy) NSString *openId;
@property (nonatomic, copy) NSString *userNo;
@property (nonatomic, copy) NSString *headUrl;
@property (nonatomic, copy) NSString *mobile;
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, copy) NSString *sex;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *id;

//自己是否是房主
@property (nonatomic, assign) BOOL ifMaster;
@property (nonatomic, assign) NSString *agoraRTMToken;
@property (nonatomic, assign) NSString *agoraRTCToken;

@end

NS_ASSUME_NONNULL_END
