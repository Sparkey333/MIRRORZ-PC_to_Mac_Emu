import { exportPrivatePem, exportPublicPem, generateSigningKeys, publicKeyRawB64Url } from '../license/keys.js';

const keys = generateSigningKeys();
console.log('# Put the private key in LICENSE_SIGNING_KEY_PEM (keep secret; rotate by adding a new kid to clients first)');
console.log(exportPrivatePem(keys.privateKey));
console.log('# Public key (SPKI PEM) — embed in the macOS/iOS/Android clients');
console.log(exportPublicPem(keys.publicKey));
console.log(`# Raw public key (base64url, 32 bytes): ${publicKeyRawB64Url(keys.publicKey)}`);
console.log(`# kid: ${keys.kid}`);
