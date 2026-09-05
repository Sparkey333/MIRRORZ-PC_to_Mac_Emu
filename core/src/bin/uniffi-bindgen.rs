//! Thin wrapper around the UniFFI bindings generator so the Swift/Kotlin
//! bindings are produced by the exact `uniffi` version this crate links against.
//!
//! Build/run with: `cargo run --features cli --bin uniffi-bindgen -- generate ...`
fn main() {
    uniffi::uniffi_bindgen_main()
}
