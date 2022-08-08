//
//  VLRoomSelSongModel.m
//  VoiceOnLine
//

#import "VLRoomSelSongModel.h"

@implementation VLRoomSelSongModel

- (bool)isOwnSong {
    if ([self.userNo isEqualToString:VLUserCenter.user.userNo]) {
        return YES;
    }
    return NO;
}

@end
