# share-port

> Instantly expose any local port to the internet via Cloudflare Tunnel.
> Generates a secure, temporary HTTPS public URL without router port forwarding.

- Expose local self-hosted Vaultwarden server (port 8222):
  tunnel 8222

- Expose a local web app or dev server (e.g. Next.js / Vite on port 3000):
  share 3000

- Expose Portainer container GUI (port 9000):
  share-port 9000
