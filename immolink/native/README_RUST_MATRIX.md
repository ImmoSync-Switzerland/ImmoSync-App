Rust Matrix bridge - quick start

This folder contains a scaffold for integrating `matrix-rust-sdk` with the
Flutter app using `flutter_rust_bridge` (FRB).

Quick steps

1. Install Rust toolchain:
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

2. Install FRB codegen:
   cargo install flutter_rust_bridge_codegen

3. From `immolink/native/matrix_bridge` run codegen:
   flutter_rust_bridge_codegen --rust-input src/bridge.rs --dart-output ../../lib/bridge_generated.dart

4. Build native libs:
   - Android: use `cargo ndk` or FRB helper scripts to produce `.so` files and copy
     them into `android/src/main/jniLibs/<ABI>/`.
   - iOS: follow FRB iOS instructions to produce and embed the library.

5. Wire `lib/bridge_generated.dart` into `lib/matrix_rust_bridge.dart` and
   implement the Dart-side adapter.

When to implement real matrix code

- The current `bridge.rs` contains stubs for codegen and local testing. If
  you want, I can now implement the real `matrix-sdk` usage for `login`,
  `create_room`, `send_message` and a tokio-backed sync loop. This requires a
  working Synapse endpoint to test against.
