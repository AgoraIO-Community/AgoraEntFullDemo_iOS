//
//  VLRoomSetModel.m
//  VoiceOnLine
//

#import "VLRoomSeatModel.h"

@implementation VLRoomSeatModel

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (void)resetLeaveSeat {
    self.isMaster = false;
    self.headUrl = @"";
    self.name = @"";
    self.userNo = @"";
    self.id = @"";
    self.isSelfMuted = 1;
    self.isVideoMuted = 0;

}

@end
