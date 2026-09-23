export const uiPort = 3000
export const dataMountpoint = '/data'

/** Mountpoint of the Core Lightning volume (its datadir: rune, config, data). */
export const clnMountpoint = '/mnt/cln'

/**
 * clnrest host id, referenced by literal: cln-startos exports only its
 * peer/watchtower host ids (see cln-startos/startos/interfaces.ts), so this one
 * is inlined — same approach as ride-the-lightning-startos.
 */
export const clnRestHostId = 'clnrest'
