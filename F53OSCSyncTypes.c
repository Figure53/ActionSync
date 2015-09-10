//
//  F53OSCSyncTypes.c
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#include <math.h>
#include <assert.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include "F53OSCSyncTypes.h"

inline F53OSCSyncLocation F53OSCSyncLocationMake(uint32_t seconds, uint32_t fraction)
{
    return (F53OSCSyncLocation){
        .seconds = seconds,
        .fraction = fraction
    };
}

inline F53OSCSyncLocation F53OSCSyncLocationMakeWithSeconds(double seconds)
{
    double fraction = fmod( seconds, 1.0 ) * (double)UINT32_MAX;
    return (F53OSCSyncLocation){
        .seconds = (uint32_t)trunc( seconds ),
        .fraction = (uint32_t)fraction
    };
}

inline double F53OSCSyncLocationGetSeconds(F53OSCSyncLocation location)
{
    double fraction = (double)location.fraction / (double)UINT32_MAX;
    return (double)location.seconds + fraction;
}

// The following function is based on Apple's documentation, at https://developer.apple.com/library/mac/qa/qa1398/_index.html

double machTimeInSeconds()
{
    uint64_t mach_time;
    static mach_timebase_info_data_t sTimebaseInfo;
    
    mach_time = mach_absolute_time();
    
    if ( sTimebaseInfo.denom == 0 ) {
        (void) mach_timebase_info(&sTimebaseInfo);
    }
    
    // Do the maths. We hope that the multiplication doesn't
    // overflow; the price you pay for working in fixed point.
    
    uint64_t nanos = mach_time * sTimebaseInfo.numer / sTimebaseInfo.denom;
    
    return (double)nanos / 1000000000.;
}