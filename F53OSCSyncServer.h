//
//  F53OSCSyncServer.h
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#import <Foundation/Foundation.h>

@interface F53OSCSyncServer : NSObject

- (BOOL) startListeningOnPort:(uint16_t)port;
- (void) stopListening;

@end
