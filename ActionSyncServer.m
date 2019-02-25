//
//  ActionSyncServer.m
//  Action Sync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to use ARC).
#endif

#import "ActionSyncServer.h"
#import "F53OSC.h"
#import "ActionSyncTypes.h"

@interface ActionSyncServer () <F53OSCPacketDestination, NSNetServiceDelegate>
{
    F53OSCServer *_oscServer;
    NSNetService *_netService;
    double _lastPongExecutionTime;
    
    NSMutableSet<NSDictionary *> *_subscribers;
    NSMutableSet<id<ActionSyncServerTimeline>> *_timelines;
}

@end

#pragma mark -

@implementation ActionSyncServer

- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        _subscribers = [NSMutableSet set];
    }
    return self;
}

- (BOOL)startListeningOnPort:(uint16_t)port withPublishedServiceName:(NSString *)publishedServiceName
{
    [self stopListening];
    
    if ( publishedServiceName )
        self.publishedServiceName = publishedServiceName;
    
    if ( self.publishedServiceName )
    {
        _netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_actionsync._tcp" name:self.publishedServiceName port:port]; // Might be more correct to use _osc._tcp
        _netService.delegate = self;
        [_netService publish];
    }
    _oscServer = [F53OSCServer new];
    _oscServer.port = port;
    _oscServer.delegate = self;
    return [_oscServer startListening];
}

- (BOOL)startListeningOnPort:(uint16_t)port
{
    return [self startListeningOnPort:port withPublishedServiceName:nil];
}

- (void)stopListening
{
    _netService = nil;
    [_oscServer stopListening];
    _oscServer = nil;
}

- (void)registerTimeline:(id<ActionSyncServerTimeline>)timeline
{
    // TODO: add to _timelines; observe for @"ActionSyncTimelineStateDidChange" notifications
}

- (void)unregisterTimeline:(id<ActionSyncServerTimeline>)timeline
{
    // TODO: remove from _timelines; remove observation for @"ActionSyncTimelineStateDidChange" notifications
}

#pragma mark - F53OSCPacketDestination

- (void)takeMessage:(F53OSCMessage *)message
{
    if ( message.addressParts.count < 2 || ![message.addressParts.firstObject isEqualToString:@"timeline"] )
    {
        return;
    }
    
    if ( [message.addressPattern isEqualToString:@"/actionsync/ping"] )
    {
        [self sendPongToSocket:message.replySocket];
    }
    else if ( [message.addressPattern isEqualToString:@"/actionsync/subscribe"] )
    {
        NSDictionary *subscriber = @{ @"socket": message.replySocket };
        @synchronized( self )
        {
            [_subscribers addObject:subscriber];
        }
    }
    else if ( [message.addressPattern isEqualToString:@"/actionsync/catchup"] )
    {
        
    }
    else if ( [message.addressPattern isEqualToString:@"/actionsync/unsubscribe"] )
    {
        NSDictionary *subscriber = @{ @"socket": message.replySocket };
        @synchronized( self )
        {
            [_subscribers removeObject:subscriber];
        }
    }
}

- (void)sendPongToSocket:(F53OSCSocket *)socket
{
    double now = machTimeInSeconds();
    ActionSyncLocation nowAsLocation = ActionSyncLocationMakeWithSeconds( now );
    F53OSCMessage *pong = [F53OSCMessage new];
    pong.addressPattern = @"/actionsync/pong";
    pong.arguments = @[ @( nowAsLocation.seconds ), @( nowAsLocation.fraction ) ];
    [socket sendPacket:pong];
}

- (void)sendStartMessageForTimelineID:(NSString *)timelineID
                     timelineLocation:(double)timelineLocationSeconds
                          nominalRate:(float)nominalRate
                       serverHostTime:(double)serverHostTimeSeconds
{
    ActionSyncLocation timelineLocation = ActionSyncLocationMakeWithSeconds( timelineLocationSeconds );
    ActionSyncLocation serverHostTime = ActionSyncLocationMakeWithSeconds( serverHostTimeSeconds );
    F53OSCMessage *msg = [F53OSCMessage new];
    msg.addressPattern = [NSString stringWithFormat:@"/actionsync/%@/start", timelineID];
    msg.arguments = @[ @( timelineLocation.seconds ), @( timelineLocation.fraction ), @( nominalRate ), @( serverHostTime.seconds ), @( serverHostTime.fraction ) ];
    // TODO: finish this
}

- (void)sendStopMessageForTimelineID:(NSString *)timelineID
                    timelineLocation:(double)timelineLocationSeconds
{
    // TODO: this
}

- (void)sendScrubMessageForTimelineID:(NSString *)timelineID
                     timelineLocation:(double)timelineLocationSeconds
{
    // TODO: this
}

- (void)sendRateMessageForTimelineID:(NSString *)timelineID
                    timelineLocation:(double)timelineLocationSeconds
                      newNominalRate:(float)nominalRate
{
    // TODO: this
}

- (void)sendLoadMessageForTimelineID:(NSString *)timelineID
                    timelineLocation:(float)timelineLocationSeconds
{
    // TODO: this
}

#pragma mark - NSNetServiceDelegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    NSLog( @"Did not publish: %@", errorDict );
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
}

@end
