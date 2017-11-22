//
//  F53OSCSyncTypes.h
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#ifndef __F53OSCSync__F53OSCSyncTypes__
#define __F53OSCSync__F53OSCSyncTypes__

// In F53OSCSync nomenclature, a "location" is a point on a timeline, in seconds. OSC doesn't support types with more than 32 bits of resolution, so we split it into two 32-bit types, much like NTP and the OSC time tag do.

typedef struct {
    uint32_t seconds;
    uint32_t fraction;  ///< remainder * 2^32
} F53OSCSyncLocation;

F53OSCSyncLocation F53OSCSyncLocationMake(uint32_t seconds, uint32_t fraction);
F53OSCSyncLocation F53OSCSyncLocationMakeWithSeconds(double seconds);
double F53OSCSyncLocationGetSeconds(F53OSCSyncLocation location);
double machTimeInSeconds();

#endif /* defined(__F53OSCSync__F53OSCSyncTypes__) */
