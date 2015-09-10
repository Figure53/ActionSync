//
//  F53OSCSyncServer.m
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#import "F53OSCSyncServer.h"
#import "F53OSC.h"
#import "F53OSCSyncTypes.h"

@interface F53OSCSyncServer () <F53OSCPacketDestination>
{
    F53OSCServer *_oscServer;
    double _lastPongExecutionTime;
}

@end

#pragma mark -

@implementation F53OSCSyncServer

- (instancetype) init
{
    self = [super init];
    if ( self )
    {
    }
    return self;
}

- (BOOL) startListeningOnPort:(uint16_t)port
{
    [self stopListening];
    _oscServer = [F53OSCServer new];
    _oscServer.port = port;
    _oscServer.delegate = self;
    return [_oscServer startListening];
}

- (void) stopListening
{
    [_oscServer stopListening];
    _oscServer = nil;
}

#pragma mark - F53OSCPacketDestination

- (void) takeMessage:(F53OSCMessage *)message
{
    if ( message.addressParts.count < 2 || ![message.addressParts.firstObject isEqualToString:@"timeline"] )
    {
        return;
    }
    
    if ( [message.addressPattern isEqualToString:@"/timeline/ping"] )
    {
        [self _sendPongToSocket:message.replySocket];
    }
}

- (void) _sendPongToSocket:(F53OSCSocket *)socket
{
    double now = machTimeInSeconds();
    F53OSCSyncLocation nowAsLocation = F53OSCSyncLocationMakeWithSeconds( now );
    F53OSCMessage *pong = [F53OSCMessage new];
    pong.addressPattern = @"/timeline/pong";
    pong.arguments = @[ @( nowAsLocation.seconds ), @( nowAsLocation.fraction ) ];
    [socket sendPacket:pong];
}

@end
