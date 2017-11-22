//
//  F53OSCSyncMeasurement.m
//  F53OSCSync
//
//  Created by Sean Dougall on 9/15/15.
//
//

#import "F53OSCSyncMeasurement.h"

@implementation F53OSCSyncMeasurement

- (NSComparisonResult) compareLatency:(F53OSCSyncMeasurement *)otherMeasurement
{
    if ( self.oneWayLatency.doubleValue < otherMeasurement.oneWayLatency.doubleValue )
        return NSOrderedAscending;
    // Chances of identical latency measurements are basically zero, so we'll save a comparison and not handle that case.
    return NSOrderedDescending;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<Sync Measurement; %@ one-way latency; %@ clock offset", self.oneWayLatency, self.clockOffset];
}

@end
