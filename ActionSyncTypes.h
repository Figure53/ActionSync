//
//  ActionSyncTypes.h
//  Action Sync
//
//  Created by Sean Dougall on 9/9/15.
//

// In ActionSync nomenclature, a "location" is a point on a timeline, in seconds.
// OSC doesn't support types with more than 32 bits of resolution, so we split it
// into two 32-bit types, much like NTP and the OSC time tag do.

typedef struct {
    uint32_t seconds;
    uint32_t fraction;  ///< remainder * 2^32
} ActionSyncLocation;

ActionSyncLocation ActionSyncLocationMake(uint32_t seconds, uint32_t fraction);
ActionSyncLocation ActionSyncLocationMakeWithSeconds(double seconds);
double ActionSyncLocationGetSeconds(ActionSyncLocation location);
double machTimeInSeconds();
double machTimeToSeconds(uint64_t mach_time);

enum ActionSyncState { ActionSyncStateStopped = 0, ActionSyncStatePaused = 1, ActionSyncStateRunning = 2 };

typedef struct {
    int32_t state;
    float rate;
    ActionSyncLocation location;
    ActionSyncLocation hostTime;
} ActionSyncStatus;

ActionSyncStatus ActionSyncStatusMake(int32_t state, float rate, double location, double hostTime);