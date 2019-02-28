//
//  ActionSyncServer.m
//  Action Sync
//
//  Created by Sean Dougall on 9/9/15.
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to use ARC).
#endif

#import "ActionSyncServer.h"
#import "F53OSC.h"
#import "ActionSyncTypes.h"

@interface ActionSyncServer () <F53OSCPacketDestination, NSNetServiceDelegate>

@property (strong) F53OSCServer *oscServer;
@property (strong) NSNetService *netService;

@property (strong) NSMutableSet<id<ActionSyncServerTimeline>> *timelines;
@property (strong) NSMutableSet<NSDictionary *> *subscribers;

@end

#pragma mark -

@implementation ActionSyncServer

- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        self.subscribers = [NSMutableSet set];
    }
    return self;
}

- (BOOL)startListeningOnPort:(uint16_t)port withPublishedServiceName:(NSString *)publishedServiceName
{
    [self stopListening];

    self.oscServer = [F53OSCServer new];
    self.oscServer.port = port;
    self.oscServer.delegate = self;
    
    if ( [self.oscServer startListening] )
    {
        if ( publishedServiceName )
            self.publishedServiceName = publishedServiceName;

        if ( self.publishedServiceName )
        {
            self.netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_actionsync._tcp" name:self.publishedServiceName port:port]; // Might be more correct to use _osc._tcp
            self.netService.delegate = self;
            [self.netService publish];
        }

        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)startListeningOnPort:(uint16_t)port
{
    return [self startListeningOnPort:port withPublishedServiceName:nil];
}

- (void)stopListening
{
    [self.netService stop];
    self.netService = nil;

    [self.oscServer stopListening];
    self.oscServer = nil;
}

- (void)registerTimeline:(id<ActionSyncServerTimeline>)timeline
{
    [self.timelines addObject:timeline];
}

- (void)unregisterTimeline:(id<ActionSyncServerTimeline>)timeline
{
    [self.timelines removeObject:timeline];
}

- (void)sendStatus:(ActionSyncStatus)status forTimeline:(id<ActionSyncServerTimeline>)timeline
{
    NSString *timelineID = [timeline timelineIDForSyncServer:self];

    NSLog( @"/actionsync/%@/status %@ %@ %@ %@", timelineID, @(status.state), @(status.rate), @(ActionSyncLocationGetSeconds(status.location)), @(ActionSyncLocationGetSeconds(status.hostTime)) );

    for ( NSDictionary *subscriber in self.subscribers )
    {
        F53OSCSocket *socket = subscriber[@"socket"];
        [self sendStatus:status forTimelineID:timelineID toSocket:socket];
    }
}

#pragma mark - F53OSCPacketDestination

- (void)takeMessage:(F53OSCMessage *)message
{
    if ( message.addressParts.count < 2 || ![message.addressParts.firstObject isEqualToString:@"actionsync"] )
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
            [self.subscribers addObject:subscriber];
        }
    }
    else if ( [message.addressPattern isEqualToString:@"/actionsync/catchup"] )
    {
        for ( id<ActionSyncServerTimeline> timeline in self.timelines )
        {
            NSString *timelineID = [timeline timelineIDForSyncServer:self];
            ActionSyncStatus currentStatus = [timeline timelineStatusForSyncServer:self];
            [self sendStatus:currentStatus forTimelineID:timelineID toSocket:message.replySocket];
        }
    }
    else if ( [message.addressPattern isEqualToString:@"/actionsync/unsubscribe"] )
    {
        NSDictionary *subscriber = @{ @"socket": message.replySocket };
        @synchronized( self )
        {
            [self.subscribers removeObject:subscriber];
        }
    }
}

- (void)sendPongToSocket:(F53OSCSocket *)socket
{
    double now = machTimeInSeconds();
    ActionSyncLocation nowAsLocation = ActionSyncLocationMakeWithSeconds(now);

    F53OSCMessage *pong = [F53OSCMessage new];
    pong.addressPattern = @"/actionsync/pong";
    pong.arguments = @[ @(nowAsLocation.seconds), @(nowAsLocation.fraction) ];
    // TODO: optional string argument received from ping

    [socket sendPacket:pong];
}

- (void)sendStatus:(ActionSyncStatus)status
     forTimelineID:(NSString *)timelineID
          toSocket:(F53OSCSocket *)socket
{
    if ( timelineID == nil || socket == nil )
        return;

    F53OSCMessage *msg = [F53OSCMessage new];
    msg.addressPattern = [NSString stringWithFormat:@"/actionsync/%@/status", timelineID];
    msg.arguments = @[ @(status.state), @(status.rate), @(status.location.seconds), @(status.location.fraction), @(status.hostTime.seconds), @(status.hostTime.fraction) ];

    [socket sendPacket:msg];
}

#pragma mark - NSNetServiceDelegate

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    NSLog( @"Did not publish ActionSync service '%@': %@", sender.name, errorDict );
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
}

@end
