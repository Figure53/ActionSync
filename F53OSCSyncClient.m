//
//  F53OSCSyncClient.m
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#import "F53OSCSyncClient.h"
#import "F53OSCSyncClientTimelineProtocol.h"
#import "F53OSC.h"

@interface F53OSCSyncClient() <F53OSCClientDelegate, F53OSCPacketDestination>
{
    F53OSCClient *_oscClient;
    double _lastPingMachTime;
    NSMutableArray *_offsetMeasurements; ///< seconds to add to server's host clock, assuming latency is corrected for
    double _averageOffset;
    NSTimer *_pingTimer;
}

@end

#pragma mark -

@implementation F53OSCSyncClient

- (instancetype) init
{
    self = [super init];
    if ( self )
    {
        _offsetMeasurements = [NSMutableArray array];
        self.registeredTimelines = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL) connectToHost:(NSString *)host port:(UInt16)port
{
    _oscClient = [F53OSCClient new];
    _oscClient.host = host;
    _oscClient.port = port;
    _oscClient.useTcp = YES;
    _oscClient.delegate = self;
    if ( [_oscClient connect] )
    {
        F53OSCMessage *message = [F53OSCMessage new];
        message.addressPattern = @"/timeline/subscribe";
        [_oscClient sendPacket:message];
        return YES;
    }
    return NO;
}

- (void) disconnect
{
    F53OSCMessage *message = [F53OSCMessage new];
    message.addressPattern = @"/timeline/unsubscribe";
    [_oscClient sendPacket:message];
    [_oscClient disconnect];
    _oscClient = nil;
}

- (void) registerTimeline:(id<F53OSCSyncClientTimeline>)timeline
{
    dispatch_async( dispatch_get_main_queue(), ^{
        NSNumber *uniqueID = @( [timeline uniqueIDForSyncClient] );
        self.registeredTimelines[uniqueID] = timeline;
    });
}

- (void) unregisterTimeline:(id<F53OSCSyncClientTimeline>)timeline
{
    dispatch_async( dispatch_get_main_queue(), ^{
        NSNumber *uniqueID = @( [timeline uniqueIDForSyncClient] );
        [self.registeredTimelines removeObjectForKey:uniqueID];
    });
}

- (double) offsetFromServerClock
{
    return _averageOffset;
}

#pragma mark - F53OSCClientDelegate

- (void) clientDidConnect:(F53OSCClient *)client
{
    [self _sendPing];
}

- (void) clientDidDisconnect:(F53OSCClient *)client
{
    [_pingTimer invalidate];
    _pingTimer = nil;
}

#pragma mark - F53OSCPacketDestination

- (void) takeMessage:(F53OSCMessage *)message
{
    double now = machTimeInSeconds();
    if ( [message.addressPattern isEqualToString:@"/timeline/pong"] )
    {
        [self _handlePong:message.arguments atMachTime:now];
        return;
    }
    
    if ( message.addressParts.count == 3 && [message.addressParts.firstObject isEqualToString:@"timeline"] )
    {
        NSString *timelineID = message.addressParts[1];
        NSString *action = message.addressParts[2];
        
        if ( [action isEqualToString:@"start"] )
        {
            [self _handleStartMessage:message.arguments forTimelineID:timelineID];
        }
        else if ( [action isEqualToString:@"stop"] )
        {
            [self _handleStopMessage:message.arguments forTimelineID:timelineID];
        }
        else if ( [action isEqualToString:@"scrub"] )
        {
            [self _handleScrubMessage:message.arguments forTimelineID:timelineID];
        }
        else if ( [action isEqualToString:@"rate"] )
        {
            [self _handleRateChangeMessage:message.arguments forTimelineID:timelineID];
        }
    }
}

#pragma mark - Message handling

// Arguments: <server_host_time:L>
- (void) _handlePong:(NSArray *)arguments atMachTime:(double)machTimeInSeconds
{
    double oneWayLatency = ( machTimeInSeconds - _lastPingMachTime ) * 0.5;
    F53OSCSyncLocation serverHostLocation = F53OSCSyncLocationMake( [arguments[0] intValue], [arguments[1] intValue] );
    double serverHostTime = F53OSCSyncLocationGetSeconds( serverHostLocation );
    double secondsToAdd = machTimeInSeconds - serverHostTime - oneWayLatency;

    // Clear out old measurements and append this new one.
    while ( _offsetMeasurements.count >= 40 )
    {
        [_offsetMeasurements removeObjectAtIndex:0];
    }
    [_offsetMeasurements addObject:@( secondsToAdd )];
    
    // Calculate and cache the average, which we'll use for timing calculations.
    double avg = 0.0;
    for ( NSNumber *offset in _offsetMeasurements )
    {
        avg += [offset doubleValue];
    }
    avg /= (double)_offsetMeasurements.count;
    _averageOffset = avg;
    NSLog( @"avg %0.03f", 1000.0 * _averageOffset );
}

// Arguments: <timeline_location:L> <nominal_rate:f> <server_host_time:L>
- (void) _handleStartMessage:(NSArray *)arguments forTimelineID:(NSString *)timelineID
{
    
}

// Arguments: none
- (void) _handleStopMessage:(NSArray *)arguments forTimelineID:(NSString *)timelineID
{
    
}

// Arguments: <timeline_location:L>
- (void) _handleScrubMessage:(NSArray *)arguments forTimelineID:(NSString *)timelineID
{
    
}

// Arguments: <timeline_location:L> <new_rate:f>
- (void) _handleRateChangeMessage:(NSArray *)arguments forTimelineID:(NSString *)timelineID
{
    
}

- (void) _sendPing
{
    F53OSCMessage *message = [F53OSCMessage new];
    message.addressPattern = @"/timeline/ping";
    _lastPingMachTime = machTimeInSeconds();
    [_oscClient sendPacket:message];
    
    // Start off by sending pings frequently, then ease up as we get more data.
    double delay = ( _offsetMeasurements.count < 10 ? 0.1 : _offsetMeasurements.count < 25 ? 0.3 : 1.0 );
    [_pingTimer invalidate];
    _pingTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector( _sendPing ) userInfo:nil repeats:NO];
}

@end
