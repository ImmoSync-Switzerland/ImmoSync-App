# Nginx + Let's Encrypt setup for Matrix homeserver

Placeholders: replace `matrix.example.com` and `element.example.com` with your real domains.

1) Copy Nginx config
```bash
sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled /var/www/letsencrypt
sudo cp backend/matrix/nginx/matrix.conf /etc/nginx/sites-available/matrix
sudo ln -s /etc/nginx/sites-available/matrix /etc/nginx/sites-enabled/matrix
```

2) Test nginx config and reload
```bash
sudo nginx -t && sudo systemctl reload nginx
```

3) Obtain Let's Encrypt certificates (Certbot)
```bash
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
# Ensure DNS A records for matrix.example.com and element.example.com point to this vserver IP
sudo certbot --nginx -d matrix.example.com -d element.example.com
```

4) Open firewall ports (ufw example)
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8448/tcp   # optional for federation
sudo ufw reload
```

5) Verify
```bash
curl -fsS https://matrix.example.com/_matrix/client/versions | jq .
curl -fsS https://element.example.com/ # should return Element web UI
```

6) Notes
- If your Synapse container is not exposing port 8008 on localhost, adapt the proxy_pass to point to the internal container address or map the port when running the container.
- Federation port 8448 must be reachable for other homeservers to federate with you.
- Renewals: certbot sets up automatic renewals; test with `sudo certbot renew --dry-run`.

7) Upload size limits (413 Request Entity Too Large)
- To support larger encrypted chat attachments, increase body size in Nginx:
	- In the server block handling uploads, set `client_max_body_size 50m;`
	- Optionally, raise timeouts for slow links: `proxy_read_timeout 300s; proxy_send_timeout 300s;`
- Align backend multer limit via environment: `CHAT_MAX_ATTACHMENT_MB=50`
- Reload Nginx after changes and retry the upload.
