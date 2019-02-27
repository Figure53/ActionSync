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
@property (readonly) BOOL connected;
@property (readonly) double offsetFromServerClock;

- (void)searchForServers:(void (^)(NSSet *))successHandler; ///< successHandler will be called with a set of dictionaries containing @"name", @"host", and @"port" keys.

- (BOOL)connectToHost:(NSString *)host port:(UInt16)port;
- (void)disconnect;

@end
