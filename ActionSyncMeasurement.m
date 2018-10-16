//
//  ActionSyncMeasurement.m
//  Action Sync
//
//  Created by Sean Dougall on 9/15/15.
//
//

#import "ActionSyncMeasurement.h"

@implementation ActionSyncMeasurement

- (NSComparisonResult) compareLatency:(ActionSyncMeasurement *)otherMeasurement
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
