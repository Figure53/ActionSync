//
//  F53OSCSyncClientDelegate.h
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

/* 
 
 The F53OSCSyncClientDelegate protocol allows a controller object to receive notifications about changes to timeline status on the server end.
 
 If you are hosting an F53OSCSyncClient, you should have a (most likely single) controller object that implements this protocol.
 
 */

#ifdef __OBJC__

#ifndef F53OSCSync_F53OSCSyncClientDelegate_h
#define F53OSCSync_F53OSCSyncClientDelegate_h

@import Foundation;
#include "F53OSCSyncTypes.h"

@protocol F53OSCSyncClientDelegate <NSObject>

@optional

- (void) syncClientDidStartTimelineID:(NSString *)timelineID
                           atLocation:(F53OSCSyncLocation)location
                             withRate:(float)rate
                           atHostTime:(double)hostTimeInSeconds;
- (void) syncClientDidStopTimelineID:(NSString *)timelineID;
- (void) syncClientDidChangeRateForTimelineID:(NSString *)timelineID
                                   atLocation:(F53OSCSyncLocation)location
                                  withNewRate:(float)rate;
- (void) syncClientDidScrubTimelineID:(NSString *)timelineID
                           toLocation:(F53OSCSyncLocation)location;

@end

#endif
#endif
