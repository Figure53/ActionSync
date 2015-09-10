//
//  F53OSCSyncClientDelegate.h
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

/* Definitions
 
 A "location" is a point on a timeline, in seconds. OSC doesn't support types with more than 32 bits of resolution, so we split it into two 32-bit types, much like NTP and the OSC time tag do.
 
 */

#ifdef __OBJC__

#ifndef F53OSCSync_F53OSCSyncClientDelegate_h
#define F53OSCSync_F53OSCSyncClientDelegate_h

@import Foundation;
#include "F53OSCSyncTypes.h"

@protocol F53OSCSyncClientTimeline <NSObject>

- (NSUInteger) uniqueIDForSyncClient;

@optional

- (void) syncClientDidStartTimelineID:(UInt64)timelineID
                           atLocation:(F53OSCSyncLocation)location
                             withRate:(float)rate
                           atHostTime:(double)hostTimeInSeconds;
- (void) syncClientDidStopTimelineID:(UInt64)timelineID;
- (void) syncClientDidChangeRateForTimelineID:(UInt64)timelineID
                                   atLocation:(F53OSCSyncLocation)location
                                  withNewRate:(float)rate;
- (void) syncClientDidScrubTimelineID:(UInt64)timelineID
                           toLocation:(F53OSCSyncLocation)location;

@end

#endif
#endif