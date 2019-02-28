//
//  ActionSyncClientDelegate.h
//  Action Sync
//
//  Created by Sean Dougall on 9/9/15.
//

/* 
 
 The ActionSyncClientDelegate protocol allows a controller object to receive notifications about changes to timeline status on the server end.
 
 If you are hosting an ActionSyncClient, you should have a (most likely single) controller object that implements this protocol.
 
 */

#import <Foundation/Foundation.h>

#include "ActionSyncTypes.h"

@protocol ActionSyncClientDelegate <NSObject>

@optional

- (void)syncClientDidStartTimelineID:(NSString *)timelineID
                           atLocation:(ActionSyncLocation)location
                             withRate:(float)rate
                           atHostTime:(double)hostTimeInSeconds;
- (void)syncClientDidStopTimelineID:(NSString *)timelineID;
- (void)syncClientDidChangeRateForTimelineID:(NSString *)timelineID
                                   atLocation:(ActionSyncLocation)location
                                  withNewRate:(float)rate;
- (void)syncClientDidScrubTimelineID:(NSString *)timelineID
                           toLocation:(ActionSyncLocation)location;

@end
