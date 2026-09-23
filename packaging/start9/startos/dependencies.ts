import { T } from '@start9labs/start-sdk'
import { manifest } from './manifest'
import { sdk } from './sdk'

export const setDependencies = sdk.setupDependencies(async () => {
  const deps = {} as T.CurrentDependenciesResult<typeof manifest>

  // // PERCHÉ: nel manifest la dipendenza è `optional` (il bridge funziona anche
  // con un nodo remoto configurato a mano). Se però il servizio Core Lightning è
  // installato, deve essere in esecuzione: senza `lightningd` up la clnrest non
  // risponde e il bridge non avrebbe nulla da esporre.
  deps['c-lightning'] = {
    kind: 'running',
    versionRange: '>=26.6.6:1',
    healthChecks: ['lightningd'],
  }

  return deps
})
