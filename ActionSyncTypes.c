//
//  ActionSyncTypes.c
//  Action Sync
//
//  Created by Sean Dougall on 9/9/15.
//

#include <math.h>
#include <assert.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include "ActionSyncTypes.h"


inline ActionSyncLocation ActionSyncLocationMake(uint32_t seconds, uint32_t fraction)
{
    return (ActionSyncLocation){
        .seconds = seconds,
        .fraction = fraction
    };
}

inline ActionSyncLocation ActionSyncLocationMakeWithSeconds(double seconds)
{
    double fraction = fmod( seconds, 1.0 ) * (double)UINT32_MAX;
    return (ActionSyncLocation){
        .seconds = (uint32_t)trunc( seconds ),
        .fraction = (uint32_t)fraction
    };
}

inline double ActionSyncLocationGetSeconds(ActionSyncLocation location)
{
    double fraction = (double)location.fraction / (double)UINT32_MAX;
    return (double)location.seconds + fraction;
}

// The following function is based on Apple's documentation, at https://developer.apple.com/library/mac/qa/qa1398/_index.html

double machTimeInSeconds()
{
    return machTimeToSeconds(mach_absolute_time());
}

double machTimeToSeconds(uint64_t mach_time)
{
    static mach_timebase_info_data_t sTimebaseInfo;
    if ( sTimebaseInfo.denom == 0 ) {
        (void) mach_timebase_info(&sTimebaseInfo);
    }

    // Do the maths. We hope that the multiplication doesn't
    // overflow; the price you pay for working in fixed point.
    uint64_t nanos = mach_time * sTimebaseInfo.numer / sTimebaseInfo.denom;

    return (double)nanos / 1000000000.;
}

inline ActionSyncStatus ActionSyncStatusMake(int32_t state, double location, double hostTime, float rate)
{
    return (ActionSyncStatus){
        .state = state,
        .location = ActionSyncLocationMakeWithSeconds(location),
        .hostTime = ActionSyncLocationMakeWithSeconds(hostTime),
        .rate = rate
    };
}