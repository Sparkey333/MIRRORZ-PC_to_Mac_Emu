# MIRRORZ developer entry points. See README.md for the module map.
.PHONY: setup test test-server test-core test-apple test-android lint fixtures run-server website

setup:            ## install toolchains/deps that work on any OS
	cd server && npm ci
	command -v cargo >/dev/null || echo "install Rust: https://rustup.rs"

test: test-server test-core   ## everything that runs on Linux/macOS without Xcode

test-server:
	cd server && npm run typecheck && npm test

test-core:
	cd core && cargo test

test-apple:       ## requires macOS + Xcode 16
	cd apps/shared/MirrorzKit && swift test
	cd apps/macos/Packages/MirrorzEngine && swift test
	cd apps/macos && xcodegen generate && xcodebuild -scheme MIRRORZ -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test

test-android:     ## requires JDK 21 (+ Android SDK for :app)
	cd apps/android && gradle :core:test

lint:
	cd core && cargo fmt --check && cargo clippy --all-targets --features cli -- -D warnings
	cd server && npm run typecheck

fixtures:         ## regenerate cross-language license fixtures from the server implementation
	cd server && npx tsx src/tools/fixtures.ts

run-server:
	cd server && npm run dev

website:
	node website/build.mjs
