import { VersionInfo } from '@start9labs/start-sdk'

export const current = VersionInfo.of({
  version: '0.1.0:0',
  releaseNotes: {
    en_US: `First release of the NWC/NCC bridge for StartOS.

- Exposes a Core Lightning node over Nostr Wallet Connect (NIP-47) and NCC
- Connects automatically to the Core Lightning service when it is installed
- Web page with the connection string (URI + QR) and node settings (URL + rune)
- Works with a remote node too: nothing is required except clnrest reachability`,
  },
  migrations: {},
})
