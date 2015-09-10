//
//  F53OSCSyncTypes.h
//  F53OSCSync
//
//  Created by Sean Dougall on 9/9/15.
//
//

#ifndef __F53OSCSync__F53OSCSyncTypes__
#define __F53OSCSync__F53OSCSyncTypes__

typedef struct {
    uint32_t seconds;
    uint32_t fraction;  ///< remainder * 2^32
} F53OSCSyncLocation;

F53OSCSyncLocation F53OSCSyncLocationMakeWithSeconds(double seconds);
double F53OSCSyncLocationGetSeconds(F53OSCSyncLocation location);
double machTimeInSeconds();

#endif /* defined(__F53OSCSync__F53OSCSyncTypes__) */
