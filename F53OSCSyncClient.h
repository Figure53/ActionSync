//
//  F53OSCSyncClient.h
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#import <Foundation/Foundation.h>

@protocol F53OSCSyncClientTimeline;

@interface F53OSCSyncClient : NSObject

@property (strong) NSMutableDictionary *registeredTimelines;
@property (readonly) double offsetFromServerClock;
@property (readonly) BOOL connected;

- (void) searchForServers:(void (^)(NSSet *))success; ///< Passes a set of dictionaries, with @"name", @"host", and @"port" keys.

- (BOOL) connectToHost:(NSString *)host port:(UInt16)port;
- (void) disconnect;

- (void) registerTimeline:(id<F53OSCSyncClientTimeline>)timeline;
- (void) unregisterTimeline:(id<F53OSCSyncClientTimeline>)timeline;

@end
