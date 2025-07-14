//
// ViewerEvent.h
//
// Copyright (c) 2020-2025 Larry M. Taylor
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software. Permission is granted to anyone to
// use this software for any purpose, including commercial applications, and to
// to alter it and redistribute it freely, subject to 
// the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source
//    distribution.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>

#import "LTLog.h"
#import "LTMidi.h"

#define MAX_STR_LEN  50

@interface LTViewerEvent : NSObject
{
    NSNumber *mDrumChannel;
}

@property NSString *track;
@property NSString *time;
@property NSInteger totalTime;
@property NSString *deltaTime;
@property NSString *channel;
@property NSString *status;
@property NSString *data1;
@property NSString *data2;
@property NSString *length;
@property NSString *hex;

- (id)initWithEvent:(struct LTSMFEvent)event
    withDrumChannel:(NSNumber *)channel;

@end
