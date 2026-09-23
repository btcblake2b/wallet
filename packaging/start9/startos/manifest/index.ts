import { setupManifest } from '@start9labs/start-sdk'

export const manifest = setupManifest({
  id: 'nwc-cln-bridge',
  title: 'NWC/NCC Bridge',
  license: 'mit',
  packageRepo: 'https://github.com/btcblake2b/nwc-cln-bridge-startos',
  upstreamRepo: 'https://github.com/btcblake2b/control-plane',
  marketingUrl: 'https://btcblake2b.org/',
  donationUrl: null,
  description: {
    short: 'Control a Core Lightning node from the btc-blake2b wallet app',
    long: `Exposes a Core Lightning node over Nostr Wallet Connect (NIP-47) and NCC, so the btc-blake2b wallet app can send and receive on Lightning and manage channels without touching the node's console.

If the Core Lightning service is installed on this server, the bridge connects to it automatically (clnrest URL + rune read from its volume). Otherwise a node — local or remote — is configured from the bridge page: the clnrest REST URL and a rune created for this bridge.

The bridge page also shows the NWC/NCC connection string (with a QR code) to paste in the wallet app, one string per device.`,
  },
  volumes: ['main'],
  images: {
    bridge: {
      source: {
        // // Image built from packaging/docker/Dockerfile.bridge in the main
        // repository (multi-arch: linux/amd64 + linux/arm64).
        dockerTag: 'ghcr.io/btcblake2b/nwc-cln-bridge:0.1.0',
      },
      arch: ['x86_64', 'aarch64'],
      emulateMissingAs: 'aarch64',
    },
  },
  dependencies: {
    'c-lightning': {
      description:
        'Optional: Core Lightning on this server is exposed automatically (clnrest URL + rune). Leave it uninstalled and configure a node from the bridge page.',
      optional: true,
      metadata: {
        title: 'Core Lightning',
        icon: 'https://raw.githubusercontent.com/Start9Labs/cln-startos/master/icon.svg',
      },
    },
  },
})
