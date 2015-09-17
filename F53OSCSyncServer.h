//
//  F53OSCSyncServer.h
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#import <Foundation/Foundation.h>

@interface F53OSCSyncServer : NSObject

@property (copy) NSString *publishedServiceName; ///< Normally this should be the application name.

- (BOOL) startListeningOnPort:(uint16_t)port;
- (BOOL) startListeningOnPort:(uint16_t)port withPublishedServiceName:(NSString *)publishedServiceName;
- (void) stopListening;

@end
