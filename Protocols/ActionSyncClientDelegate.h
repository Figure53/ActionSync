//
//  ActionSyncClientDelegate.h
//  Action Sync
//
//  Created by Sean Dougall on 9/9/15.
//

/* 
 
 The ActionSyncClientDelegate protocol allows a client object to receive notifications about changes to timeline status on the server end.
 
 If you are hosting an ActionSyncClient, you should have a (most likely single) controller object that implements this protocol.
 
 */

#import <Foundation/Foundation.h>

#include "ActionSyncTypes.h"

@protocol ActionSyncClientDelegate <NSObject>

@optional

- (void)syncClientStartTimelineID:(NSString *)timelineID
                         withRate:(float)rate
                       atLocation:(double)location
                       atHostTime:(double)hostTimeInSeconds;

- (void)syncClientPauseTimelineID:(NSString *)timelineID
                       atLocation:(double)locationInSeconds
                       atHostTime:(double)hostTimeInSeconds;

- (void)syncClientStopTimelineID:(NSString *)timelineID
                      atLocation:(double)location
                      atHostTime:(double)hostTimeInSeconds;

@end
