# F53OSCSync protocol

Version 0.1 (2015-09-10)

## Introduction

F53OSCSync is an attempt to address some of the shortcomings of timecode, particularly as it is used in theatrical contexts. Timecode currently gets used for several things, some well and some badly:

- Nominal rate
- Clock drift correction
- Starting and stopping
- Periodic address checks

Timecode, whether MTC or LTC, attempts to address all four of those concerns by implementing only the last one. Timecode is nothing more than a stream of address checks, one per frame or fraction thereof, and it is up to the receiving end to analyze that stream and extract information about rate, drift, and starting and stopping.

One area where this becomes problematic is in trying to separate nominal rate from clock drift. In a timecode universe, there is no distinction between them; both are conveyed by the rate at which messages are received, and the receiving end must decide what nominal rate it expects. As a result, only two nominal rates are typically used: 1.0 (film speed) and 0.999 (video speed).

Starting and stopping should be simple. With timecode, though, stopping is particularly complex, because there's no explicit stop; you don't know if the sending machine actually intended to stop, or if the signal just dropped out. So there's always a "freewheel" time on the receiving end, meaning that it will always take some substantial amount of time to stop after the master stops. Additionally, this either-running-or-not binary means that scrubbing is unsupported by timecode, and so most applications turn to other standards (such as MIDI Machine Code) to support scrubbing.

One last shortcoming of timecode is that it only supports one timeline at any given time. Timecode streams cannot be combined, so either the timeline must stop, relocate, and start again, or multiple physical channels of timecode are needed (however, most platforms do not support this).


## Protocol structure

F53OSCSync is built upon OSC. It is a client-server model, with one server and zero or more clients. Messages are transmitted over a TCP connection initiated by the client. Multiple independent timelines are supported, and any number can run simultaneously (subject to reason and network bandwidth, of course).

The approach of F53OSCSync falls into two parts: (1) allow the server to share its host clock, to establish a common frame of reference that clients can use, and (2) send control messages to clients.

A client initiates a connection with `/timeline/subscribe` (and keeps that connection alive), followed by a series of `/timeline/ping` messages. The server then responds to those pings with `/timeline/pong`, which carries the server's host time. The client measures the round-trip latency, halves it to estimate the one-way latency, and uses that to calculate its own host clock's offset from the server's.

The server then sends each subscribed client control messages in response to any playback changes on its end. Since the client has an approximate knowledge of the server's host time, it uses that knowledge to follow along at home.


## A note about clocking

Timecode does not have sufficient bandwidth to drive an audio clock reliably, and neither does a typical network connection. We're not going to attempt to reclock any hardware. If a client desires, it can smooth its offset calculations and use that to drive a varispeed plugin, but we're not currently attempting that in our implementation.

In general, if we assume that there's some other clocking mechanism (e.g. AVB or word clock), then we don't need to handle clock drift correction. It can be up to the user to decide whether or not they need machines clocked together; if each cue is only a couple minutes or less, or even a bit longer if it's all video or lights, they probably don't need it. So for our purposes, we only need to worry about nominal rate.



## Messages sent by server

### `/timeline/pong`

Arguments: `server host time` (time)

Sent in response to `/timeline/ping`.


### `/timeline/<id>/start`

Arguments: `timeline location` (time), `nominal rate` (float), `server host time` (time)

Sent when any timeline starts, or in response to `/timeline/catchup` for each timeline that is currently running. When a client receives this message, it should start the corresponding timeline, using `timeline location` as an anchor point and extrapolating from its knowledge of the server's host time.

Note: Receiving this message is, aside from the ping cycle, the only time when the client cares about the server host time. 


### `/timeline/<id>/stop`

Arguments: `timeline location` (time, optional)

Stops the corresponding timeline. If `timeline location` is provided and in the past, the timeline's playhead should scrub back to that position to end at the same time as the server. If it is provided and in the future, the client should schedule a stop at the appropriate moment in the timeline. If not provided, the client should simply stop the timeline immediately.


### `/timeline/<id>/scrub`

Arguments: `timeline location` (time)

Scrubs the timeline, leaving it paused at `timeline location`.


### `/timeline/<id>/rate`

Arguments: `timeline location` (time), `new nominal rate` (float)

Denotes a change in the nominal playback rate of the timeline. Clients should use `timeline location` as a new anchor point for all timing calculations occurring after this rate change.


## Messages sent by client

### `/timeline/subscribe`

Arguments: none

Clients send this mesage to the server to begin receiving /start, /stop, /scrub, and /rate messages. By leaving the TCP connection open after sending this, the client provides the server with a reply port, with the server needing no prior knowledge of the client's configuration.


### `/timeline/ping`

Arguments: none

Clients send this to request a `/timeline/pong` message from the server. Use the roundtrip time for these two messages to calculate an estimated one-way latency. Since this latency calculation is critical, `/timeline/ping` should be sent relatively frequently until a good sense of the netwok latency is achieved. After that, it can be sent less frequently.


### `/timeline/catchup`

Arguments: none

Clients may send this once enough latency calculations have been made to establish an offset from the server's host time. This invites the server to send `/timeline/start` messages for any timelines that are currently running, or `/timeline/scrub` messages for any timelines that are currently paused. If a client is not interested in playback that began before it connected up, it may opt not to send this message.


### `/timeline/unsubscribe`

Arguments: none

Clients should send this before disconnecting, as a courtesy notice to the server that it may stop sending to a particular client.