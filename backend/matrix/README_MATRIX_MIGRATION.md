# Matrix Migration Plan

This document outlines the phased migration of the existing custom Socket.IO chat with ad-hoc E2EE to the Matrix protocol (Synapse server + Olm/Megolm). Goal: robust, audited end-to-end encryption, multi-device capability, and less custom maintenance.

## Phases

### Phase 0 – Environment Bootstrap
- Add Synapse via Docker (single-node, SQLite or Postgres) for dev.
- Create test users mapped to existing user IDs.
- Verify basic room creation, message send, E2EE enablement.

### Phase 1 – Abstraction Layer in Flutter
- Introduce a ChatRepository interface hiding transport.
- Provide legacy (current WebSocket) implementation + new Matrix implementation side-by-side.
- Feature toggle (remote config or compile flag) to switch per build.

### Phase 2 – User Mapping & Authentication
- Map existing `users` collection `_id` => Matrix user ID: `@<mongoId>:your-domain`.
- Provision accounts automatically via Synapse Admin API (shared secret registration) when user registers or first logs in.
- Store Matrix access token per user (secure storage on device; server optional cache for push).

### Phase 3 – Conversation Mapping
- Existing one-to-one conversation => Direct Matrix room (tagged `m.direct`).
- Maintain `conversationId <-> roomId` mapping collection.
- On first migration access: if mapping missing, create/join room, persist mapping.

### Phase 4 – Message Flow Migration
- Sending:
  * Legacy path: unchanged.
  * Matrix path: use matrix-dart SDK to send `m.room.message` with encrypted payload automatically (Olm/Megolm handled by SDK after initial verification).
- Receiving: timeline sync -> transform into internal `ChatMessage` model.
- Attachments: upload to Matrix media repo (`/_matrix/media/r0/upload`) or keep existing storage and send URI in body; decide per security/performance.

### Phase 5 – E2EE Verification & Trust UX
- Display device list + verification status.
- Implement emoji/SAS verification flow (optional initial deferral if single device per user).

### Phase 6 – Backfill Historical Messages
- Option A: Leave historical messages read-only (legacy channel) & show boundary.
- Option B: Re-inject historical messages into Matrix room as pseudo events (NOT recommended for cryptographic integrity).
- Option C: Export legacy transcript downloadable per conversation.

### Phase 7 – Decommission Legacy Socket Chat
- After acceptable adoption & stability window.
- Freeze legacy writes -> full cutover.

## Data Model Additions (Backend)
Collection: `matrix_accounts`
```
{ userId: ObjectId, mxid: string, accessToken: string, createdAt, updatedAt }
```
Collection: `matrix_conversations`
```
{ conversationId: ObjectId, roomId: string, participants: [userIds], createdAt, updatedAt }
```

## Dev Synapse (docker-compose snippet placeholder)
A `docker-compose.matrix.yml` will be added to spin up Synapse + Element Web for manual inspection.

## Flutter Dependencies (planned)
- matrix: A Dart/Flutter Matrix SDK (evaluate: matrix dart community packages). If inadequate, use FFI or a thin bridge around matrix-rust-sdk.

## Incremental Rollout Strategy
1. Ship build with dual stack + toggle default OFF.
2. Internal test group ON.
3. Monitor: sync latency, room creation success, encryption errors, crash rate.
4. Gradually expand.

## Security Considerations
- Ensure domain & SSL for production homeserver.
- Enforce cross-signing / disable unverified device sending if policy requires.
- Periodic key backup (Secure Secret Storage) guidance for users.

## Open Questions
- Push notifications: use Matrix push gateway vs existing mechanism?
- Multi-device: will backend need device list for presence? Possibly derive from Matrix presence API.

## Next Steps
1. Commit docker-compose + env template.
2. Add backend provisioning script for Matrix users using admin shared secret.
3. Abstract Flutter chat layer.
4. Implement create/join room mapping logic.

---
This file will evolve as implementation proceeds.
