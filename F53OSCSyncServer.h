//
//  F53OSCSyncServer.h
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#import <Foundation/Foundation.h>
#import "F53OSCSyncServerTimeline.h"

@interface F53OSCSyncServer : NSObject

@property (copy) NSString *publishedServiceName; ///< Normally this should be the application name.

- (BOOL) startListeningOnPort:(uint16_t)port;
- (BOOL) startListeningOnPort:(uint16_t)port withPublishedServiceName:(NSString *)publishedServiceName;
- (void) stopListening;

- (void) registerTimeline:(id<F53OSCSyncServerTimeline>)timeline; ///< See the F53OSCSyncServerTimeline protocol for requirements and discussion.
- (void) unregisterTimeline:(id<F53OSCSyncServerTimeline>)timeline;

@end
