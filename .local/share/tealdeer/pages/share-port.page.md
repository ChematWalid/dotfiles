# share-port

> Expose a local port publicly through a temporary Cloudflare Tunnel.
> The service is reachable from the public internet; verify it has suitable authentication.

- Expose local self-hosted Vaultwarden server (port 8222):
  `tunnel --public 8222`

- Expose a local web app or dev server (e.g. Next.js / Vite on port 3000):
  `share --public 3000`

- Expose Portainer container GUI (port 9000):
  `share-port --public 9000`
