//! Licensing: human keys, signed device tokens, offline entitlement rules and the
//! plan → feature table. Mirrors `server/src/license/*` byte-for-byte where the
//! server is the reference implementation (key format, token format).

pub mod entitlement;
pub mod key;
pub mod plans;
pub mod token;

/// One day in seconds. Licensing never phones home more often than this (spec §3.4 rule 4).
pub const DAY_SECS: i64 = 86_400;
