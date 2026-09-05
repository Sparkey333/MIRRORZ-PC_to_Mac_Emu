# Contributing

1. Read `docs/spec/platform-contracts.md` first; every client is built against it and the server is the reference implementation.
2. `make test` must pass. Apple and Android targets are verified in CI on macOS/Android runners.
3. Keep the product promises: no ads, no nag screens, telemetry off by default, perpetual licenses never expire.
4. Prices live only in `pricing/pricing.json`; product ids only in `server/src/billing/products.ts`.
5. Regenerate fixtures (`make fixtures`) whenever license key/token formats change, and update the Rust/Swift/Kotlin ports in the same PR.
