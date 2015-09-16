//
//  F53OSCSyncMeasurement.h
//  F53OSCSync
//
//  Created by Sean Dougall on 9/15/15.
//
//

#import <Foundation/Foundation.h>

@interface F53OSCSyncMeasurement : NSObject

@property (strong) NSNumber *oneWayLatency;
@property (strong) NSNumber *clockOffset;

- (NSComparisonResult) compareLatency:(F53OSCSyncMeasurement *)otherMeasurement;

@end
