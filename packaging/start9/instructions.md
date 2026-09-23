# NWC/NCC Bridge

Control a Core Lightning node from the btc-blake2b wallet app.

## 1. Install

Install this service. If the **Core Lightning** service is already installed on
your server, the bridge connects to it automatically.

## 2. Open the bridge page

Open the **Web Interface** from the service page. The page shows the bridge
status, the node settings and the connection string.

> The page contains a device secret. The bridge generates a UI token at first
> start: you will find it in the service logs. Append it to the page URL as
> `?token=<token>` when you open it from another device.

## 3. Connect the node (only if Core Lightning is not installed here)

In the **Core Lightning node** section of the page enter:

- **REST URL** — the `clnrest` endpoint of your node, e.g.
  `http://192.168.1.50:3010` (or its Tor address);
- **Rune** — a rune created on that node for this bridge (`createrune`).

Press **Save and apply**: the change is applied immediately, no restart needed.

## 4. Connect the wallet app

Scan the QR code (or copy the string) and paste it in the app under
**Lightning → Connect**. Each device needs its own string: press
**Authorize a new device** to create one.

## Troubleshooting

- **"Nodo non configurato"** in the app → the bridge has no node configured:
  open the page and fill in the URL and rune.
- **Node network: non raggiungibile** → the URL/rune are wrong or `clnrest` is
  not reachable from this server.
- **Relay disconnected** → the bridge reconnects automatically; check that
  outbound HTTPS (443) is allowed.
