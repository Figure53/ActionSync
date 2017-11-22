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

@interface F53OSCSyncServer () <F53OSCPacketDestination, NSNetServiceDelegate>
{
    F53OSCServer *_oscServer;
    NSNetService *_netService;
    double _lastPongExecutionTime;
    
    NSMutableSet<NSDictionary *> *_subscribers;
    NSMutableSet<id<F53OSCSyncServerTimeline>> *_timelines;
}

@end

#pragma mark -

@implementation F53OSCSyncServer

- (instancetype) init
{
    self = [super init];
    if ( self )
    {
        _subscribers = [NSMutableSet set];
    }
    return self;
}

- (BOOL) startListeningOnPort:(uint16_t)port withPublishedServiceName:(NSString *)publishedServiceName
{
    [self stopListening];
    
    if ( publishedServiceName )
        self.publishedServiceName = publishedServiceName;
    
    if ( self.publishedServiceName )
    {
        _netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_f53oscsync._tcp" name:self.publishedServiceName port:port];
        _netService.delegate = self;
        [_netService publish];
    }
    _oscServer = [F53OSCServer new];
    _oscServer.port = port;
    _oscServer.delegate = self;
    return [_oscServer startListening];
}

- (BOOL) startListeningOnPort:(uint16_t)port
{
    return [self startListeningOnPort:port withPublishedServiceName:nil];
}

- (void) stopListening
{
    _netService = nil;
    [_oscServer stopListening];
    _oscServer = nil;
}

- (void) registerTimeline:(id<F53OSCSyncServerTimeline>)timeline
{
    // TODO: add to _timelines; observe for @"F53OSCSyncTimelineStateDidChange" notifications
}

- (void) unregisterTimeline:(id<F53OSCSyncServerTimeline>)timeline
{
    // TODO: remove from _timelines; remove observation for @"F53OSCSyncTimelineStateDidChange" notifications
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
    else if ( [message.addressPattern isEqualToString:@"/timeline/subscribe"] )
    {
        NSDictionary *subscriber = @{ @"socket": message.replySocket };
        @synchronized ( self )
        {
            [_subscribers addObject:subscriber];
        }
    }
    else if ( [message.addressPattern isEqualToString:@"/timeline/catchup"] )
    {
        
    }
    else if ( [message.addressPattern isEqualToString:@"/timeline/unsubscribe"] )
    {
        NSDictionary *subscriber = @{ @"socket": message.replySocket };
        @synchronized ( self )
        {
            [_subscribers removeObject:subscriber];
        }
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

- (void) _sendStartMessageForTimelineID:(NSString *)timelineID
                      timelineLocation:(double)timelineLocationSeconds
                           nominalRate:(float)nominalRate
                        serverHostTime:(double)serverHostTimeSeconds
{
    F53OSCSyncLocation timelineLocation = F53OSCSyncLocationMakeWithSeconds( timelineLocationSeconds );
    F53OSCSyncLocation serverHostTime = F53OSCSyncLocationMakeWithSeconds( serverHostTimeSeconds );
    F53OSCMessage *msg = [F53OSCMessage new];
    msg.addressPattern = [NSString stringWithFormat:@"/timeline/%@/start", timelineID];
    msg.arguments = @[ @( timelineLocation.seconds ), @( timelineLocation.fraction ), @( nominalRate ), @( serverHostTime.seconds ), @( serverHostTime.fraction ) ];
    // TODO: finish this
}

- (void) _sendStopMessageForTimelineID:(NSString *)timelineID
                     timelineLocation:(double)timelineLocationSeconds
{
    // TODO: this
}

- (void) _sendScrubMessageForTimelineID:(NSString *)timelineID
                      timelineLocation:(double)timelineLocationSeconds
{
    // TODO: this
}

- (void) _sendRateMessageForTimelineID:(NSString *)timelineID
                     timelineLocation:(double)timelineLocationSeconds
                       newNominalRate:(float)nominalRate
{
    // TODO: this
}

- (void) _sendLoadMessageForTimelineID:(NSString *)timelineID
                     timelineLocation:(float)timelineLocationSeconds
{
    // TODO: this
}

#pragma mark - NSNetServiceDelegate

- (void) netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    NSLog( @"Did not publish: %@", errorDict );
}

- (void) netServiceDidPublish:(NSNetService *)sender
{
}

@end
