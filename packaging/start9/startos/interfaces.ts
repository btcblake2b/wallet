import { sdk } from './sdk'
import { uiPort } from './utils'

export const setInterfaces = sdk.setupInterfaces(async ({ effects }) => {
  const uiMulti = sdk.MultiHost.of(effects, 'ui')
  const uiMultiOrigin = await uiMulti.bindPort(uiPort, { protocol: 'http' })

  const ui = sdk.createInterface(effects, {
    name: 'Web Interface',
    id: 'ui',
    description:
      'Bridge status, node settings and the NWC/NCC connection string (URI + QR)',
    type: 'ui',
    masked: false,
    schemeOverride: null,
    username: null,
    path: '',
    query: {},
  })

  return [await uiMultiOrigin.export([ui])]
})
