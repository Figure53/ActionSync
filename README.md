# Action Sync protocol

Version 0.2 (2018-10-16)

## Introduction

Action Sync is an attempt to address some of the shortcomings of [SMPTE timecode](https://en.wikipedia.org/wiki/SMPTE_timecode), particularly as it is used in theatrical contexts. People currently use timecode for several things:

- Periodic address checks
- Starting and stopping
- Nominal rate
- Clocking / Clock drift correction

Timecode, whether [MTC](https://en.wikipedia.org/wiki/MIDI_timecode) or [LTC](https://en.wikipedia.org/wiki/Linear_timecode), attempts to address all four of those concerns by implementing only the first one. Timecode is nothing more than a stream of addresses, one per frame or fraction thereof, and it is up to the receiving end to analyze that stream and extract information about rate, drift, and starting and stopping.

One area where timecode falls short is separating nominal rate from clock drift. In a timecode universe, there is no distinction between them; both are conveyed by the rate at which messages are received, and the receiving end must decide what nominal rate it expects. As a result, only two nominal rates are typically used: 1.0 (film speed) and 0.999 (video speed).

Starting and stopping should be simple. With timecode, though, stopping is complex, because there's no explicit stop; you don't know if the sending machine actually intended to stop, or if the signal just dropped out. So there's always a period of "freewheel" built in to the receiving end, meaning that it will always take some substantial amount of time for the receiver to truly stop when the sender stops sending timecode. Additionally, this either-running-or-not binary means that scrubbing is unsupported by timecode, and so most applications turn to other standards (such as MIDI Machine Code) to support scrubbing.

One last shortcoming of timecode is that it only supports one timeline. Timecode streams cannot be combined, so either the timeline must stop, relocate, and start again, or multiple physical channels of timecode are needed (however, most platforms do not support this).


## Protocol structure

Action Sync is built upon OSC. It is a client-server model, with one server and zero or more clients. Messages are transmitted over a TCP connection initiated by the client. Multiple independent timelines are supported, and any number can run simultaneously (subject to reason and network bandwidth, of course).

For each timeline, Action Sync supports transmitting explicit information about:

- Periodic address checks
- Starting and stopping
- Nominal rate

The approach of Action Sync falls into two parts: (1) sharing the current time (i.e. the address) of the server's host clock, to establish a common frame of reference that clients can use, and (2) sending control messages to clients.

A client initiates a connection with `/actionsync/subscribe` (and keeps that connection alive), followed by a series of `/actionsync/ping` messages. The server then responds to those pings with `/actionsync/pong`, which carries the server's host time. The client measures the round-trip latency, halves it to estimate the one-way latency, and uses that to calculate its own host clock's offset from the server's.

The server then sends each subscribed client control messages in response to any playback changes on its end. Since the client has an approximate knowledge of the server's host time, it uses that knowledge to follow along at home.


## A note about clocking

In general terms, any discussion of synchronization encompasses two concepts: `clock` (which refers to the rate at which time monotonically increases at the hardware level—much like the ticking of a metronome) and `address` (which refers to an absolute location on a timeline). These two concepts are separate but complementary, and together define a complete picture of synchronization between two devices.

"Clocking" two devices together means to make one device's sense of time move forward strictly according to another device’s clock (e.g. [word clock](https://en.wikipedia.org/wiki/Word_clock)).

Timecode is a stream of addresses. It was designed to drive analog tape, and while it can be sufficient for clocking video frame updates, it does not have enough resolution to drive an audio clock reliably. (For that matter, neither does a typical network connection.) Thus, as a replacement for timecode, Action Sync does not attempt to clock two pieces of hardware together in a strict sense. If a client desires, it can smooth its offset calculations and use that to drive a varispeed plugin, but we're not currently attempting that in our implementation.

We assume that if strict clocking is required, some other high-resolution clocking mechanism will be used (e.g. AVB or word clock). For many theatrical uses, such as lighting, video, or even short audio cues, strict clocking is not necessary. In these cases, events on separate machines can be effectively synchronized within the margin of clocking error that results from periodic address checks combined with an explicit nominal rate.


## Messages sent by client

### `/actionsync/ping`

Arguments: none

Clients send this to request a `/actionsync/pong` message from the server. Use the roundtrip time for these two messages to calculate an estimated one-way latency. Since this latency calculation is critical, `/actionsync/ping` should be sent relatively frequently until a good sense of the netwok latency is achieved. After that, it can be sent less frequently.

### `/actionsync/subscribe`

Arguments: none

Clients send this mesage to the server to begin receiving `/actionsync/<id>/status` messages. By leaving the TCP connection open after sending this, the client provides the server with a reply port, with the server needing no prior knowledge of the client's configuration.

### `/actionsync/catchup`

Arguments: none

Clients may send this once enough latency calculations have been made to establish an offset from the server's host time. This invites the server to send `/actionsync/<id>/status` messages for all current timelines. If a client is not interested in playback that began before it connected up, it may opt not to send this message.

### `/actionsync/unsubscribe`

Arguments: none

Clients should send this before disconnecting, as a courtesy notice to the server that it may stop sending to a particular client.



## Messages sent by server

### `/actionsync/pong`

Arguments: `server host time` ([time](#time-def))

Sent in response to `/actionsync/ping`.


### `/actionsync/<id>/status`

Arguments: `state` (int), `timeline location` ([time](#time-def)), `server host time` ([time](#time-def)), `nominal rate` (float)

Sent when the status of a timeline changes, or in response to `/actionsync/catchup`. Only the first argument is required. Subsequent arguments are optional in an additive manner. For example: if `server host time` is provided, `timeline location` must also be provided.

Argument details:

 | argument |            | description  |
 | -------- | ---------- | ------------ |
 | `state`  | required | 0 = stopped, 1 = paused, 2 = running |
 | `timeline location` | optional | The location on the timeline where the state change did happen or will happen in the future.  All timelines start at location zero (0). If location is not provided, the state change specified by `state` should be applied immediately. |
 | `server host time` | optional | The host time, in seconds, when the state change did happen or will happen in the future. If provided, the client may use its knowledge of the offset between the server host time and the client host time to schedule the state change on the client. If not provided, the client may use its local knowledge of the current timeline location to schedule a state change on the client corresponding to the given `timeline location`. |
 | `nominal rate` | optional | The nominal playback rate of the timeline at the given timeline location. Nominal rate is only meaningful when the `state` is "running" (2). If the state is not currently running this message may be ignored. Default is 1.0. |



<a name="time-def"></a>

## Time structure

OSC's native types are limited to 32 bits, which is insufficient for high-precision timing. So for arguments listed as "time" above, we take an approach similar to NTP and OSC's time tag structure, splitting the time in seconds into two 32-bit integers. The first carries the integer portion of the value, while the second carries the remainder (multiplied by 2^32).
