//
//  ActionSyncServerTimeline.h
//  Action Sync
//
//  Created by Sean Dougall on 11/22/17.
//  Copyright © 2017 Figure 53, LLC. All rights reserved.
//

/*

 The ActionSyncServerTimeline protocol allows a sync server to query any active timelines for their status.

 If you are hosting a ActionSyncServer, the timeline objects you register with it must implement this protocol. All methods are required.

 Furthermore, timeline objects should post NSNotifications with the name @"ActionSyncTimelineStateDidChange"; the server will observe those notifications and immediately query the timeline object for its state.

 */

#import <Foundation/Foundation.h>

@class ActionSyncServer;

@protocol ActionSyncServerTimeline <NSObject>

- (NSString *) timelineIDForSyncServer:(ActionSyncServer *)sender;

// Timing methods. These are built on the assumption that a single anchor time exists, around which timing calculations can be made based on a constant nominal playback rate.
- (double) anchorHostTimeForSyncServer:(ActionSyncServer *)sender;
- (double) anchorTimelineLocationForSyncServer:(ActionSyncServer *)sender;
- (float) nominalRateForSyncServer:(ActionSyncServer *)sender;

@end

