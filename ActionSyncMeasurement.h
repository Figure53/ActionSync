//
//  ActionSyncMeasurement.h
//  Action Sync
//
//  Created by Sean Dougall on 9/15/15.
//
//

#import <Foundation/Foundation.h>

@interface ActionSyncMeasurement : NSObject

@property (strong) NSNumber *oneWayLatency;
@property (strong) NSNumber *clockOffset;

- (NSComparisonResult) compareLatency:(ActionSyncMeasurement *)otherMeasurement;

@end
