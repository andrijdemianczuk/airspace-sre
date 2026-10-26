# ADR 0002: adsb.lol as the ADS-B data source

**Status:** Accepted, 2026-10-26

## Context
The service needs a free, live feed of aircraft positions around Calgary (YYC, 51.13 N, 114.01 W). No receiver hardware.

The free community aggregators are polled REST APIs, not push streams. "Streaming" in this system means a tight poll loop producing a continuous series of snapshots.

## Options
- **adsb.lol OpenAPI** (`/v2/point/{lat}/{lon}/{radius}`, radius up to 250 nm). Keyless and free today, ODbL-licensed data. The maintainer states rate limits and an API key (obtained by feeding the network) may be introduced later.
- **airplanes.live.** Same endpoint shape, documented limit of 1 request/second, but non-commercial access now requires contacting the project first.
- **OpenSky Network.** OAuth2 client credentials with a daily credit allowance. Better suited to historical research than tight polling.

## Decision
Poll adsb.lol every 5 seconds for a 250 nm radius around YYC. Keep the client provider-agnostic (adsb.lol and airplanes.live share a response schema) so a fallback is a config change.

## Consequences
- The upstream is a **dependency we don't control**, with announced future rate limits. That is a feature for this project: it forces the distinction between *our* reliability and *upstream* reliability.
  - Ingest SLIs are measured on what we control (poll success excluding upstream 5xx/429, processing latency, freshness of stored data).
  - A separate dependency SLI tracks upstream availability, so an adsb.lol outage shows up as a dependency event rather than silently burning our budget.
- The client must honour 429s with exponential backoff and jitter, and expose backoff state as a metric.
- Poll interval is a tunable, not a constant; documented as the first lever if limits arrive.
- ODbL attribution goes in the README.
