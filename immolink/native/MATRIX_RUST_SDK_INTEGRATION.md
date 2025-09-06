Matrix Rust SDK integration (flutter_rust_bridge)

Goal

Integrate `matrix-rust-sdk` into the Flutter app via a small Rust library exposed to Dart with `flutter_rust_bridge` (FRB). This gives you a production-ready Matrix client (Olm/Megolm E2EE, sessions, sync loop) without reimplementing crypto.

High-level approach

1. Add a Rust crate (library) that depends on `matrix-sdk` and `matrix-sdk-crypto`.
2. Expose a small, well-defined API from Rust to Dart using `flutter_rust_bridge`.
3. Generate Dart bindings with `flutter_rust_bridge_codegen`.
4. Build the Rust crate as a dynamic library included in the Flutter app for Android/iOS (FRB automates this with cargo-ndk / build scripts).
5. Implement a Dart wrapper that calls the generated bindings and adapts events into your app models.

Tradeoffs
- Pros: Full, official Matrix client with robust E2EE (Olm/Megolm), device cross-signing, and better long-term security.
- Cons: More complex CI/build (Rust toolchain, cross-compile), larger binary size, native code debugging.

Files we will add locally (this scaffold)
- `immolink/native/` - instructions and Rust stub
- `immolink/lib/matrix_rust_bridge.dart` - Dart shim calling into generated bindings (placeholder)

Step-by-step (detailed)

Prerequisites
- Install Rust toolchain + cargo (https://rustup.rs)
- Install flutter_rust_bridge tools:
  - `cargo install flutter_rust_bridge_codegen` (or use the codegen as a crate in build.rs)
  - Follow FRB docs: https://github.com/fzyzcjy/flutter_rust_bridge
- Android: install `cargo-ndk` or use `cargo ndk` for building `.so`s for Android ABIs. iOS: set up Xcode toolchain.

1) Create Rust crate
From `immolink/native`:

```bash
cargo new --lib matrix_bridge
cd matrix_bridge
```

Cargo.toml: add dependencies (example; use latest compatible versions)
```toml
[package]
name = "matrix_bridge"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
matrix-sdk = "0.7" # check latest
ruma = { version = "0.9", features = ["js-sys"] }
# crypto or olm libs as needed; matrix-sdk pulls crypto pieces
anyhow = "1.0"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
log = "0.4"
# flutter_rust_bridge support
flutter_rust_bridge = "1.85"
```

2) Write small Rust wrapper API (examples)
- Expose `init(homeserver_url, cache_dir)`
- `login(username, password) -> access_token, user_id`
- `restore_session(...)`
- `create_room(other_mxid) -> room_id`
- `send_message(room_id, body) -> event_id`
- `start_sync(callback)` and `stop_sync()` — sync loop sends events back (FRB supports callbacks)

The SDK uses async Rust; FRB supports async functions via generated code.

3) Generate Dart bindings
- Add a `bridge.h`/`bridge.rs` definition file per FRB examples and run:
  `flutter_rust_bridge_codegen --rust-input src/bridge.rs --dart-output ../lib/bridge_generated.dart`

4) Build for platforms
- Android: `cargo ndk -t armeabi-v7a -t arm64-v8a -t x86_64 -o ../android/src/main/jniLibs build --release`
- iOS: follow FRB iOS docs to produce a static library and link it

5) Dart wrapper
- In `lib/matrix_rust_bridge.dart` provide a small class that loads the generated bindings and adapts types into your app models.
- Store credentials in `flutter_secure_storage` and expose convenient methods.

6) Migration & Rollout
- Keep legacy transport available. For each conversation, if mapping contains `roomId`, use Matrix transport. Otherwise, use legacy socket and provide a migrate button that calls your backend to create the room, then call Rust API to join.
- Feature-flag the change.

Testing
- Unit tests in Rust for key serialization and login flows
- Integration: start Synapse (dev), call `login`, `create_room`, `send_message`, verify messages in Element

Security notes
- Key backup: matrix-rust-sdk supports secret storage; decide whether to require user opt-in for secure key backups.
- Ensure device verification UX in app when enabling E2EE.

Files added here are scaffolds and placeholders. Building requires setting up FRB codegen and the Rust toolchain.
