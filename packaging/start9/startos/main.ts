import { sdk } from './sdk'
import { clnMountpoint, clnRestHostId, dataMountpoint, uiPort } from './utils'
import { manifest as clnManifest } from 'cln-startos/startos/manifest'
import { clnrestPort } from 'cln-startos/startos/utils'

export const main = sdk.setupMain(async ({ effects }) => {
  console.info('Starting NWC/NCC bridge...')

  /**
   * ======================== Volumes ========================
   */
  let mounts = sdk.Mounts.of().mountVolume({
    volumeId: 'main',
    subpath: null,
    mountpoint: dataMountpoint,
    readonly: false,
  })

  /**
   * ====================== Dependency =======================
   *
   * // PERCHÉ: la dipendenza è opzionale. Se Core Lightning è installato ci
   * colleghiamo alla sua clnrest sulla rete interna e leggiamo la rune dal suo
   * volume; se non c'è (o l'utente vuole un nodo remoto) la pagina del bridge
   * resta l'unico punto di configurazione e nessun mount è necessario.
   */
  const clnAddr = await sdk.host
    .getBridgeAddress(effects, {
      packageId: 'c-lightning',
      hostId: clnRestHostId,
      internalPort: clnrestPort,
      ssl: false,
    })
    .const()

  if (clnAddr) {
    // // clnrest parla in chiaro sulla rete interna (StartOS termina il TLS al
    // bordo): niente certificati da montare.
    mounts = mounts.mountDependency<typeof clnManifest>({
      dependencyId: 'c-lightning',
      volumeId: 'main',
      subpath: null,
      mountpoint: clnMountpoint,
      readonly: true,
    })
  }

  const bridgeSub = sdk.SubContainer.of(
    effects,
    { imageId: 'bridge' },
    mounts,
    'bridge-sub',
  )

  const env: Record<string, string> = {
    BRIDGE_UI_PORT: String(uiPort),
    BRIDGE_ALIAS: 'btcblake2b-bridge',
  }

  if (clnAddr) {
    env.BRIDGE_CLN_URL = `http://${clnAddr}`
    // // PERCHÉ: `.commando-env` è il file con la rune della UI di CLN (formato
    // `LIGHTNING_RUNE="…"`, già accettato dal bridge). Il bridge non ha accesso
    // al nodo oltre a ciò che la rune concede.
    env.BRIDGE_RUNE_FILE = `${clnMountpoint}/.commando-env`
    console.info(`Using the local Core Lightning node at http://${clnAddr}`)
  } else {
    console.info(
      'Core Lightning is not installed: configure a node from the bridge page',
    )
  }

  return sdk.Daemons.of(effects).addDaemon('primary', {
    subcontainer: bridgeSub,
    exec: {
      command: [
        '/usr/local/bin/bridge-exe',
        '--ensure-config',
        `--config=${dataMountpoint}/config.json`,
      ],
      env,
    },
    ready: {
      display: 'Web Interface',
      fn: () =>
        sdk.healthCheck.checkPortListening(effects, uiPort, {
          successMessage: 'The bridge page is ready',
          errorMessage: 'The bridge page is not ready',
        }),
    },
    requires: [],
  })
})
