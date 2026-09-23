import { sdk } from '../sdk'
import { restoreInit } from '../backups'
import { setDependencies } from '../dependencies'
import { setInterfaces } from '../interfaces'
import { versionGraph } from '../versions'

// // PERCHÉ: l'ordine conta — `restoreInit` (ripristino backup) prima delle
// interfacce, che devono essere esportate col volume già ripristinato.
export const init = sdk.setupInit(
  restoreInit,
  versionGraph,
  setInterfaces,
  setDependencies,
)

export const uninit = sdk.setupUninit(versionGraph)
