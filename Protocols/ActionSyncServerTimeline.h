//
//  ActionSyncServerTimeline.h
//  Action Sync
//
//  Created by Sean Dougall on 11/22/17.
//

/*

 The ActionSyncServerTimeline protocol allows a sync server to query any active timelines for their status.

 If you are hosting a ActionSyncServer, the timeline objects you register with it must implement this protocol. All methods are required.

 */

#import <Foundation/Foundation.h>
#import "ActionSyncTypes.h"

@class ActionSyncServer;

@protocol ActionSyncServerTimeline <NSObject>

- (NSString *)timelineIDForSyncServer:(ActionSyncServer *)sender;
- (ActionSyncStatus)timelineStatusForSyncServer:(ActionSyncServer *)sender;

@end

