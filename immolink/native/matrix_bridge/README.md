Matrix Rust SDK bridge (scaffold)

What this folder contains

- `Cargo.toml` - Rust crate manifest
- `src/lib.rs` - minimal stub implementations (placeholders)

Goal

Provide a Rust library that wraps `matrix-rust-sdk` and exposes a small, safe API
to Dart using `flutter_rust_bridge` (FRB). The final integration will:

- Manage a Matrix client instance per app user
- Provide login / restore session / create/join rooms
- Run a sync loop and emit incoming events to Dart
- Send messages and attachments

Next steps (recommended)

1. Install Rust toolchain: `rustup` + `cargo`.
2. Install FRB codegen:
   - `cargo install flutter_rust_bridge_codegen` or use it as a build dependency.
3. Replace stubs in `src/lib.rs` with real `matrix-sdk` usage. Prefer creating an
   internal client manager (struct) that performs async work on a tokio runtime.
4. Create a `src/bridge.rs` and annotate the public bridge functions with the
   `#[frb]` attribute following FRB examples. Run the codegen to produce the
   Dart bindings (`bridge_generated.dart`).
   Example codegen command (run from this crate root):

   ```bash
   flutter_rust_bridge_codegen --rust-input src/bridge.rs --dart-output ../../lib/bridge_generated.dart
   ```
5. Build native libraries for Android/iOS following FRB docs. For Android you
   can use `cargo ndk` or the FRB helper scripts.

Notes

- The current files are intentionally minimal to get you started quickly.
- If you want, I can implement the first-pass real API (login, create_room,
  send_message) using `matrix-sdk` and add FRB-compatible bridge definitions.
