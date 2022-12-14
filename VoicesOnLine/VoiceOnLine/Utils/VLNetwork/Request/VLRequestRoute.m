//
//  VLRequestRoute.m
//  VoiceOnLine
//

#import "VLRequestRoute.h"
#import "VLNetworkConfig.h"
#import "VLConfig.h"

@implementation VLRequestRoute

+ (NSString *)doRoute:(NSString *)route andMethod:(NSString *)method{
    NSString *url = @"";
    if(route && route.length > 0){
        if (method && method.length > 0) {
            url = [NSString stringWithFormat:@"%@?act=%@&op=%@",[self getHostUrl],route,method];
        }else{
           url =  [NSString stringWithFormat:@"%@?act=%@",[self getHostUrl],route];
        }
    }else{
        return [self getRequestUrl:method];
    }
    return url;
}
+ (NSString*)getHostUrl {
    return [NSString stringWithFormat:@"%@",HOST];
}
+ (NSString*)getRequestUrl:(NSString *)url {
    return [NSString stringWithFormat:@"%@%@",HOST,url];
}

+ (NSString *)getToken {
    if ([VLUserCenter center].isLogin){
        return VLUserCenter.user.token;
    }else{
        return @"";
    }
    return @"";
}

@end
