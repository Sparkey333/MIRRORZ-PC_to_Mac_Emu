//! Human-typed license keys.
//!
//! Format: `MZ-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX`
//!
//! * Alphabet: Crockford base32 (`0123456789ABCDEFGHJKMNPQRSTVWXYZ`, no I/L/O/U), so a
//!   key is unambiguous when read aloud or typed.
//! * 24 random symbols (120 bits of entropy) + 1 check symbol (Luhn mod N, N = 32).
//! * The server only ever stores `sha256(normalized key)`.
//!
//! This module is a byte-for-byte port of `server/src/license/keyformat.ts`. Clients
//! MUST normalize before sending a key to the API (spec §3.3) and SHOULD validate the
//! check symbol locally for instant feedback in the "Enter license key" screen.

/// Crockford base32 alphabet used by license keys.
pub const KEY_ALPHABET: &str = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
/// Every key starts with this prefix (stripped during normalization).
pub const KEY_PREFIX: &str = "MZ";
/// Number of random symbols in a key body.
pub const BODY_LEN: usize = 24;
/// Canonical key length: body + one check symbol.
pub const KEY_LEN: usize = BODY_LEN + 1;

const N: u32 = 32;
const GROUP_LEN: usize = 5;

fn symbol_index(c: char) -> Option<u32> {
    KEY_ALPHABET
        .bytes()
        .position(|b| b as char == c)
        .map(|i| i as u32)
}

fn symbol_at(index: u32) -> char {
    KEY_ALPHABET.as_bytes()[index as usize] as char
}

/// One Luhn mod N step: `factor * code`, then sum of the base-N digits (the value is < N², so
/// this is exactly `floor(a / N) + (a mod N)`, as in the reference implementation).
fn luhn_addend(factor: u32, code: u32) -> u32 {
    let a = factor * code;
    a / N + a % N
}

/// Computes the check symbol for a body of key symbols. Returns `None` if the body contains a
/// character outside the alphabet. Not exported over FFI (clients never mint keys).
pub fn luhn_check_symbol(body: &str) -> Option<char> {
    let mut factor = 2;
    let mut sum = 0;
    for c in body.chars().rev() {
        let code = symbol_index(c)?;
        sum += luhn_addend(factor, code);
        factor = if factor == 2 { 1 } else { 2 };
    }
    let remainder = sum % N;
    Some(symbol_at((N - remainder) % N))
}

/// Validates body + check symbol together.
fn luhn_valid(full: &str) -> bool {
    let mut factor = 1;
    let mut sum = 0;
    for c in full.chars().rev() {
        let Some(code) = symbol_index(c) else {
            return false;
        };
        sum += luhn_addend(factor, code);
        factor = if factor == 2 { 1 } else { 2 };
    }
    sum % N == 0
}

/// The exact character class JavaScript's `\s` matches (the reference implementation strips
/// separators with `/[\s\-_.]/g`). Deliberately *not* `char::is_whitespace`: Rust's set includes
/// U+0085 and excludes U+FEFF, which would make the two implementations disagree.
fn is_js_whitespace(c: char) -> bool {
    matches!(
        c,
        '\t' | '\n' | '\u{000B}' | '\u{000C}' | '\r' | ' ' | '\u{00A0}' | '\u{1680}' | '\u{2000}'
            ..='\u{200A}'
                | '\u{2028}'
                | '\u{2029}'
                | '\u{202F}'
                | '\u{205F}'
                | '\u{3000}'
                | '\u{FEFF}'
    )
}

/// Normalizes user input into the canonical 25-symbol key, or `None` if the input is not a
/// well-formed key with a valid check symbol.
///
/// Steps (same order and semantics as `normalizeLicenseKey` in `keyformat.ts`):
/// 1. uppercase;
/// 2. drop whitespace, `-`, `_` and `.`;
/// 3. map look-alikes `O→0`, `I→1`, `L→1`;
/// 4. strip a leading `MZ`;
/// 5. require exactly 25 alphabet symbols and a valid Luhn mod 32 check.
///
/// The returned string is what the API expects in `POST /v1/licenses/activate { key }`.
#[uniffi::export]
pub fn normalize_license_key(input: String) -> Option<String> {
    let mut s = String::with_capacity(KEY_LEN + KEY_PREFIX.len());
    for c in input.to_uppercase().chars() {
        if is_js_whitespace(c) || matches!(c, '-' | '_' | '.') {
            continue;
        }
        s.push(match c {
            'O' => '0',
            'I' | 'L' => '1',
            other => other,
        });
    }
    let body = s.strip_prefix(KEY_PREFIX).unwrap_or(&s);
    if body.chars().count() != KEY_LEN {
        return None;
    }
    if !body.chars().all(|c| symbol_index(c).is_some()) {
        return None;
    }
    if !luhn_valid(body) {
        return None;
    }
    Some(body.to_string())
}

/// `true` if [`normalize_license_key`] accepts the input.
#[uniffi::export]
pub fn is_valid_license_key(input: String) -> bool {
    normalize_license_key(input).is_some()
}

/// Formats canonical key symbols for display: `MZ-` + groups of five joined by `-`.
/// Mirrors `formatKey` in `keyformat.ts`; the input is expected to be the 25-symbol canonical
/// form (see [`display_license_key`] for a normalize-then-format convenience).
#[uniffi::export]
pub fn format_license_key(symbols: String) -> String {
    let chars: Vec<char> = symbols.chars().collect();
    let groups: Vec<String> = chars
        .chunks(GROUP_LEN)
        .map(|g| g.iter().collect())
        .collect();
    format!("{KEY_PREFIX}-{}", groups.join("-"))
}

/// Normalizes sloppy input and, if it is a valid key, returns the pretty `MZ-XXXXX-…` form.
/// Handy for the "Enter license key" field: echo this back as the user types.
#[uniffi::export]
pub fn display_license_key(input: String) -> Option<String> {
    normalize_license_key(input).map(format_license_key)
}

/// Appends the check symbol to a 24-symbol body and returns the canonical 25-symbol key.
/// Rust-only helper (tests, tooling); the server is the only party that mints real keys.
pub fn complete_license_key(body: &str) -> Option<String> {
    if body.chars().count() != BODY_LEN {
        return None;
    }
    let check = luhn_check_symbol(body)?;
    let mut full = body.to_string();
    full.push(check);
    Some(full)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Deterministic pseudo-random key bodies so tests need no RNG dependency.
    fn synthetic_key(seed: u64) -> String {
        let mut state = seed
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        let mut body = String::with_capacity(BODY_LEN);
        for _ in 0..BODY_LEN {
            state = state
                .wrapping_mul(6364136223846793005)
                .wrapping_add(1442695040888963407);
            body.push(symbol_at(((state >> 33) % N as u64) as u32));
        }
        complete_license_key(&body).unwrap()
    }

    #[test]
    fn alphabet_is_crockford_without_ilou() {
        assert_eq!(KEY_ALPHABET.len(), 32);
        for banned in ['I', 'L', 'O', 'U'] {
            assert!(!KEY_ALPHABET.contains(banned));
        }
    }

    #[test]
    fn synthetic_keys_are_well_formed_and_validate() {
        for seed in 0..200u64 {
            let canonical = synthetic_key(seed);
            let pretty = format_license_key(canonical.clone());
            assert_eq!(pretty.len(), 2 + 5 * 6, "{pretty}");
            assert!(pretty.starts_with("MZ-"));
            assert!(is_valid_license_key(pretty.clone()), "{pretty}");
            assert_eq!(normalize_license_key(pretty), Some(canonical));
        }
    }

    #[test]
    fn normalization_tolerates_case_separators_and_look_alikes() {
        let canonical = synthetic_key(7);
        let pretty = format_license_key(canonical.clone());
        let sloppy = pretty
            .to_lowercase()
            .replace('-', " ")
            .replace('0', "o")
            .replace('1', "l");
        assert_eq!(normalize_license_key(sloppy), Some(canonical.clone()));
        let underscored = format!("  {} ", pretty.replace('-', "_"));
        assert_eq!(normalize_license_key(underscored), Some(canonical.clone()));
        let dotted = pretty.replace('-', ".");
        assert_eq!(normalize_license_key(dotted), Some(canonical.clone()));
        let with_i = canonical.replace('1', "I");
        assert_eq!(normalize_license_key(with_i), Some(canonical.clone()));
        // Unicode whitespace that JavaScript's \s strips must be stripped here too.
        let nbsp = pretty.replace('-', "\u{00A0}");
        assert_eq!(normalize_license_key(nbsp), Some(canonical));
    }

    #[test]
    fn a_single_wrong_symbol_is_rejected_by_the_check_symbol() {
        let canonical = synthetic_key(42);
        let mut rejected = 0;
        for pos in 0..canonical.len() {
            let orig = canonical.as_bytes()[pos] as char;
            let alt = symbol_at((symbol_index(orig).unwrap() + 1) % N);
            let mut mutated = canonical.clone();
            mutated.replace_range(pos..pos + 1, &alt.to_string());
            if !is_valid_license_key(format_license_key(mutated)) {
                rejected += 1;
            }
        }
        assert_eq!(rejected, canonical.len());
    }

    #[test]
    fn garbage_is_rejected() {
        assert_eq!(normalize_license_key(String::new()), None);
        assert_eq!(normalize_license_key("MZ-AAAAA".into()), None);
        assert_eq!(
            normalize_license_key("MZ-UUUUU-UUUUU-UUUUU-UUUUU-UUUUU".into()),
            None
        );
        assert_eq!(normalize_license_key("not a key".into()), None);
        // Right length, wrong alphabet (U is banned).
        let mut bad = synthetic_key(3);
        bad.replace_range(0..1, "U");
        assert_eq!(normalize_license_key(bad), None);
        // Non-ASCII noise never validates.
        assert_eq!(
            normalize_license_key("MZ-ÄÄÄÄÄ-ÄÄÄÄÄ-ÄÄÄÄÄ-ÄÄÄÄÄ-ÄÄÄÄÄ".into()),
            None
        );
    }

    #[test]
    fn prefix_is_only_stripped_once() {
        let canonical = synthetic_key(11);
        // "MZMZ…" leaves a stray "MZ" in the body -> wrong length -> rejected.
        assert_eq!(normalize_license_key(format!("MZMZ{canonical}")), None);
        assert_eq!(
            normalize_license_key(format!("mz{canonical}")),
            Some(canonical.clone())
        );
        assert_eq!(normalize_license_key(canonical.clone()), Some(canonical));
    }

    #[test]
    fn format_groups_by_five() {
        assert_eq!(format_license_key(String::new()), "MZ-");
        assert_eq!(format_license_key("ABCDEFG".into()), "MZ-ABCDE-FG");
        let canonical = synthetic_key(1);
        let pretty = format_license_key(canonical.clone());
        assert_eq!(pretty.matches('-').count(), 5);
        assert_eq!(display_license_key(pretty.to_lowercase()), Some(pretty));
        assert_eq!(display_license_key("nope".into()), None);
    }

    #[test]
    fn check_symbol_matches_reference_worked_example() {
        // Hand-computed with the reference algorithm: body of 24 zeros has sum 0 -> check '0'.
        let zeros = "0".repeat(BODY_LEN);
        assert_eq!(luhn_check_symbol(&zeros), Some('0'));
        assert!(luhn_valid(&format!("{zeros}0")));
        // Body "1" x24: alternating factors 2,1 -> addends 2,1 -> sum 36 -> remainder 4 -> check 28 = 'W'.
        let ones = "1".repeat(BODY_LEN);
        assert_eq!(luhn_check_symbol(&ones), Some('W'));
        assert!(luhn_valid(&format!("{ones}W")));
        assert!(!luhn_valid(&format!("{ones}X")));
        assert_eq!(luhn_check_symbol("U"), None);
        assert_eq!(complete_license_key("SHORT"), None);
    }
}
