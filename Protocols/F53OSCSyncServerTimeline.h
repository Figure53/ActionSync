//
//  F53OSCSyncServerTimeline.h
//  Action Sync video test macOS
//
//  Created by Sean Dougall on 11/22/17.
//  Copyright © 2017 Figure 53, LLC. All rights reserved.
//

#ifdef __OBJC__

#ifndef F53OSCSync_F53OSCSyncServerTimeline_h
#define F53OSCSync_F53OSCSyncServerTimeline_h
@import Foundation;
@class F53OSCSyncServer;

/*
 
 The F53OSCSyncServerTimeline protocol allows a sync server to query any active timelines for their status.
 
 If you are hosting a F53OSCSyncServer, the timeline objects you register with it must implement this protocol. All methods are required.
 
 Furthermore, timeline objects should post NSNotifications with the name @"F53OSCSyncTimelineStateDidChange"; the server will observe those notifications and immediately query the timeline object for its state.
 
 */

@protocol F53OSCSyncServerTimeline <NSObject>

- (NSString *) timelineIDForSyncServer:(F53OSCSyncServer *)sender;

// Timing methods. These are built on the assumption that a single anchor time exists, around which timing calculations can be made based on a constant nominal playback rate.
- (double) anchorHostTimeForSyncServer:(F53OSCSyncServer *)sender;
- (double) anchorTimelineLocationForSyncServer:(F53OSCSyncServer *)sender;
- (float) nominalRateForSyncServer:(F53OSCSyncServer *)sender;

@end

#endif
#endif
