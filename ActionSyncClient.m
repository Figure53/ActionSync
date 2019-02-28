//
//  ActionSyncClient.m
//  Action Sync
//
//  Created by Sean Dougall on 9/9/15.
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to use ARC).
#endif

#import "ActionSyncClient.h"
#import "ActionSyncClientDelegate.h"
#import "ActionSyncMeasurement.h"
#import "F53OSC.h"

@interface ActionSyncClient() <F53OSCClientDelegate, F53OSCPacketDestination, NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (strong) F53OSCClient *oscClient;
@property (strong) NSNetServiceBrowser *netServiceBrowser;
@property (strong) NSMutableArray *unresolvedServices;    ///< NSNetServices
@property (strong) NSMutableSet *availableServices;       ///< Dictionaries
@property (strong) void (^searchSuccessHandler)(NSSet *); ///< See http://goshdarnblocksyntax.com/ for a reminder on block syntax.

@property (strong) NSTimer *pingTimer;
@property (assign) double lastPingMachTime;
@property (strong) NSMutableArray *offsetMeasurements;
@property (assign) double averageOffset;

@end

#pragma mark -

@implementation ActionSyncClient

- (instancetype)init
{
    self = [super init];
    if ( self )
    {
        self.delegate = nil;

        self.oscClient = nil;
        self.netServiceBrowser = nil;
        self.availableServices = [NSMutableSet set];
        self.unresolvedServices = [NSMutableArray array];

        self.pingTimer = nil;
        self.lastPingMachTime = 0;
        self.offsetMeasurements = [NSMutableArray array];
        self.averageOffset = 0;
    }
    return self;
}

- (void)searchForServers:(void (^)(NSSet *))successHandler
{
    self.searchSuccessHandler = [successHandler copy];

    self.netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    self.netServiceBrowser.delegate = self;
    [self.netServiceBrowser searchForServicesOfType:@"_actionsync._tcp" inDomain:@"local."]; // Might be more correct to use _osc._tcp
}

- (BOOL)connectToHost:(NSString *)host port:(UInt16)port
{
    self.oscClient = [F53OSCClient new];
    self.oscClient.host = host;
    self.oscClient.port = port;
    self.oscClient.useTcp = YES;
    self.oscClient.delegate = self;

    if ( [self.oscClient connect] )
    {
        F53OSCMessage *message = [F53OSCMessage new];
        message.addressPattern = @"/actionsync/subscribe";

        [self.oscClient sendPacket:message];
        return YES;
    }
    return NO;
}

- (void)disconnect
{
    F53OSCMessage *message = [F53OSCMessage new];
    message.addressPattern = @"/actionsync/unsubscribe";

    [self.oscClient sendPacket:message];
    [self.oscClient disconnect];
    self.oscClient = nil;
}

- (BOOL)connected
{
    return ( self.offsetMeasurements.count > 10 );
}

- (double)offsetFromServerClock
{
    return self.averageOffset;
}

#pragma mark - F53OSCClientDelegate

- (void)clientDidConnect:(F53OSCClient *)client
{
    [self sendPing];
}

- (void)clientDidDisconnect:(F53OSCClient *)client
{
    [self.pingTimer invalidate];
    self.pingTimer = nil;
}

#pragma mark - F53OSCPacketDestination

- (void)takeMessage:(F53OSCMessage *)message
{
    NSLog( @"take %@", message.addressPattern );

    double now = machTimeInSeconds();
    if ( [message.addressPattern isEqualToString:@"/actionsync/pong"] )
    {
        [self handlePong:message.arguments atMachTime:now];
        return;
    }
    
    if ( message.addressParts.count == 3 && [message.addressParts.firstObject isEqualToString:@"actionsync"] )
    {
        NSString *timelineID = message.addressParts[1];
        NSString *action = message.addressParts[2];
        
        if ( [action isEqualToString:@"status"] )
        {
            [self handleStatusMessage:message.arguments forTimelineID:timelineID];
        }
    }
}

#pragma mark - Messages

- (void)sendPing
{
    F53OSCMessage *message = [F53OSCMessage new];
    message.addressPattern = @"/actionsync/ping";
    self.lastPingMachTime = machTimeInSeconds();
    [self.oscClient sendPacket:message];

    // Start off by sending pings frequently, then ease up as we get more data.
    double delay = ( self.offsetMeasurements.count < 10 ? 0.1 : self.offsetMeasurements.count < 25 ? 0.3 : 1.0 );
    [self.pingTimer invalidate];
    self.pingTimer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(sendPing) userInfo:nil repeats:NO];
}

// Arguments: <server_host_time:L>
- (void)handlePong:(NSArray *)arguments atMachTime:(double)machTimeInSeconds
{
    double oneWayLatency = ( machTimeInSeconds - self.lastPingMachTime ) * 0.5;
    ActionSyncLocation serverHostLocation = ActionSyncLocationMake( [arguments[0] intValue], [arguments[1] intValue] );
    double estimatedLocalTime = self.lastPingMachTime + oneWayLatency;
    double serverHostTime = ActionSyncLocationGetSeconds( serverHostLocation );
    double secondsToAdd = estimatedLocalTime - serverHostTime;
    
    ActionSyncMeasurement *measurement = [ActionSyncMeasurement new];
    measurement.oneWayLatency = @( oneWayLatency );
    measurement.clockOffset = @( secondsToAdd );

    // Clear out old measurements and append this new one.
    while ( self.offsetMeasurements.count >= 200 )
    {
        [self.offsetMeasurements removeObjectAtIndex:0];
    }
    [self.offsetMeasurements addObject:measurement];
    
    // A naive implementation could simply calculate the average. However, after discarding some outliers, it seems that there's a linear correlation
    // between the measured latency and the error in the offset. So we'll do a linear regression, and use the intercept to determine the offset from the host.
    // TODO: Is it worth parallelizing this code?
    NSArray *sortedMeasurements = [self.offsetMeasurements sortedArrayUsingSelector:@selector(compareLatency:)];
    double xBar = 0.0, yBar = 0.0, xyBar = 0.0, xxBar = 0.0;
    for ( NSUInteger i = 0; i < sortedMeasurements.count * 2 / 3; i++ )
    {
        ActionSyncMeasurement *measurement = sortedMeasurements[i];
        double x = measurement.oneWayLatency.doubleValue, y = measurement.clockOffset.doubleValue;
        xBar += x;
        yBar += y;
        xxBar += x * x;
        xyBar += x * y;
    }
    double count = (double)( sortedMeasurements.count * 2 / 3 );
    xBar /= count;
    yBar /= count;
    xxBar /= count;
    xyBar /= count;
    double slope = ( xyBar - xBar * yBar ) / ( xxBar - xBar * xBar );
    self.averageOffset = yBar - slope * xBar;

    NSLog( @"%@, %0.06f", measurement, self.averageOffset );
}

// Arguments: <state:i> <timeline_location:L> <server_host_time:L> <nominal_rate:f>
- (void)handleStatusMessage:(NSArray *)arguments forTimelineID:(NSString *)timelineID
{

}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreComing
{
    [self.unresolvedServices addObject:netService];
    netService.delegate = self;
    [netService resolveWithTimeout:5.0];
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    [self.availableServices removeAllObjects];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
    NSLog( @"Did not search for ActionSync service. Error: %@", errorDict );
}

#pragma mark - NSNetServiceDelegate

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog( @"Did not resolve ActionSync service. Error: %@", errorDict );

    [self.unresolvedServices removeObject:sender];
    [self notifyIfAllResolved];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSDictionary *info = @{ @"host": sender.hostName, @"port": @(sender.port), @"name": sender.name };
    [self.availableServices addObject:info];
    [self.unresolvedServices removeObject:sender];
    [self notifyIfAllResolved];
}

- (void)notifyIfAllResolved
{
    if ( self.unresolvedServices.count == 0 && self.searchSuccessHandler )
    {
        self.searchSuccessHandler( [self.availableServices copy] );
    }
}

@end
