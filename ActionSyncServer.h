//
//  ActionSyncServer.h
//  Action Sync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#import <Foundation/Foundation.h>
#import "ActionSyncServerTimeline.h"

@interface ActionSyncServer : NSObject

@property (copy) NSString *publishedServiceName; ///< Normally this should be the application name.

- (BOOL) startListeningOnPort:(uint16_t)port;
- (BOOL) startListeningOnPort:(uint16_t)port withPublishedServiceName:(NSString *)publishedServiceName;
- (void) stopListening;

- (void) registerTimeline:(id<ActionSyncServerTimeline>)timeline; ///< See the ActionSyncServerTimeline protocol for requirements and discussion.
- (void) unregisterTimeline:(id<ActionSyncServerTimeline>)timeline;

@end
