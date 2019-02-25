//
//  ActionSyncClient.h
//  Action Sync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#import <Foundation/Foundation.h>

@protocol ActionSyncClientDelegate;

@interface ActionSyncClient : NSObject

@property (weak) id<ActionSyncClientDelegate> delegate;
@property (readonly) double offsetFromServerClock;
@property (readonly) BOOL connected;

- (void)searchForServers:(void (^)(NSSet *))success; ///< Passes a set of dictionaries, with @"name", @"host", and @"port" keys.

- (BOOL)connectToHost:(NSString *)host port:(UInt16)port;
- (void)disconnect;

@end
