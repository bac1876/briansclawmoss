# BriansClaw + OpenMOSS Deployment Package

Complete automated setup for OpenClaw + OpenMOSS on DigitalOcean droplet.

**Specs:** 16GB RAM / 4 CPUs / 320GB SSD / Ubuntu 24.04 LTS  
**IP:** 143.110.233.145  
**Services:**
- OpenClaw Gateway (port 8080)
- OpenMOSS Backend (port 6565)
- Nginx reverse proxy (port 80/443)

---

## Quick Start

### Prerequisites
- Domain registered and ready (you'll point it to 143.110.233.145)
- SSH access to droplet
- Anthropic API key for Claude agents

### One-Command Deploy

SSH into your droplet and run:

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/briansclawmoss/main/deploy.sh | bash
```

Or manually:

```bash
git clone https://github.com/yourusername/briansclawmoss.git
cd briansclawmoss
bash deploy.sh
```

### Post-Deploy Setup

1. **Add your domain to DO:**
   - Log into DigitalOcean console → Networking → Domains
   - Add A record pointing to 143.110.233.145

2. **Enable SSL:**
   ```bash
   sudo ./scripts/enable-ssl.sh your-domain.com
   ```

3. **Configure OpenMOSS:**
   - Edit `/opt/openmoss/config.yaml` with:
     - Admin password
     - Agent registration token
     - Notification channels (optional)

4. **Create agents:**
   - Visit `http://your-domain.com:6565` (or `https://...` after SSL)
   - Use setup wizard to register agents
   - Deploy agent instances with role prompts from `agents/` folder

---

## Directory Structure

```
briansclawmoss/
├── deploy.sh                 # Main automated setup script
├── scripts/
│   ├── enable-ssl.sh        # Enable HTTPS with Let's Encrypt
│   ├── firewall-setup.sh    # Configure UFW rules
│   └── health-check.sh      # System health monitoring
├── config/
│   ├── openmoss.yaml        # OpenMOSS config template
│   ├── openclaw.json        # OpenClaw gateway config
│   └── nginx-template.conf  # Nginx reverse proxy template
├── services/
│   ├── openmoss.service     # systemd service for OpenMOSS
│   ├── openclaw.service     # systemd service for OpenClaw
│   └── nginx.conf           # Nginx config (systemd-managed)
├── agents/
│   ├── planner-prompt.md    # Planner agent role definition
│   ├── executor-prompt.md   # Executor agent role definition
│   ├── reviewer-prompt.md   # Reviewer agent role definition
│   └── patrol-prompt.md     # Patrol agent role definition
└── docs/
    ├── DEPLOYMENT.md        # Detailed deployment guide
    ├── AGENTS.md            # Agent setup & registration
    ├── TROUBLESHOOTING.md   # Common issues & fixes
    └── API.md               # OpenMOSS API reference
```

---

## Key Files Explained

### `deploy.sh`
Automated installation script that:
- Updates system packages
- Installs Node.js 18+ and Python 3.10+
- Clones OpenClaw and OpenMOSS repos
- Creates systemd services
- Sets up firewall rules
- Initializes databases
- Starts services

**Time to complete:** ~10-15 minutes

### `config/openmoss.yaml`
Pre-configured OpenMOSS settings:
- Admin password (change during setup wizard)
- Agent registration token (auto-generated, shown in setup)
- Workspace directory: `/opt/openmoss-workspace`
- Database: SQLite at `/opt/openmoss/data/tasks.db`
- Server port: 6565 (proxied through Nginx)

### `config/openclaw.json`
OpenClaw gateway configuration:
- Gateway bind: 0.0.0.0:8080
- Session storage: `/opt/openclaw/sessions`
- Log directory: `/var/log/openclaw`

### `agents/`
Four role prompts ready to deploy:

1. **Planner** — Breaks down goals, creates tasks, manages workflow
2. **Executor** — Claims and executes tasks, produces deliverables
3. **Reviewer** — Reviews quality, scores, approves/rejects
4. **Patrol** — Monitors for stuck tasks, auto-fixes, prevents failure

Each prompt is customized to use the OpenMOSS API endpoints.

---

## Services & Ports

| Service | Port | Type | Purpose |
|---------|------|------|---------|
| OpenClaw Gateway | 8080 | Internal | Agent session management |
| OpenMOSS Backend | 6565 | Internal | Task scheduling & API |
| Nginx | 80 | Public | HTTP → HTTPS redirect |
| Nginx | 443 | Public | HTTPS reverse proxy |

All services auto-start on reboot via systemd.

---

## Common Tasks

### Check Service Status
```bash
sudo systemctl status openmoss
sudo systemctl status openclaw
sudo systemctl status nginx
```

### View Logs
```bash
sudo journalctl -u openmoss -f      # OpenMOSS logs
sudo journalctl -u openclaw -f      # OpenClaw logs
tail -f /var/log/nginx/error.log    # Nginx errors
```

### Restart Services
```bash
sudo systemctl restart openmoss
sudo systemctl restart openclaw
sudo systemctl restart nginx
```

### Update OpenMOSS
```bash
cd /opt/openmoss
git pull
pip install -r requirements.txt
sudo systemctl restart openmoss
```

---

## Security Notes

✅ **Included:**
- UFW firewall with default-deny incoming
- Rate limiting on Nginx
- HTTPS with Let's Encrypt (after domain setup)
- API key authentication for agents
- Admin token for WebUI access

⚠️ **Before Production:**
1. Change admin password during setup wizard
2. Use strong agent registration token
3. Enable notification channels if available
4. Monitor logs for suspicious activity
5. Regular backups of `/opt/openmoss/data/`

---

## Troubleshooting

**Services won't start?**
```bash
sudo journalctl -u openmoss -n 50  # Last 50 log lines
```

**Port already in use?**
```bash
sudo lsof -i :6565    # Check what's using port 6565
sudo lsof -i :8080    # Check what's using port 8080
```

**SSL certificate issues?**
```bash
sudo certbot renew --dry-run  # Test renewal
```

See `docs/TROUBLESHOOTING.md` for more solutions.

---

## Next Steps

1. ✅ Run `deploy.sh` on droplet
2. ⏳ Get domain registered
3. 🔗 Point domain to 143.110.233.145 in DO console
4. 🔒 Run `scripts/enable-ssl.sh your-domain.com`
5. 🤖 Register agents via WebUI at `https://your-domain.com`
6. 🚀 Deploy first task and watch agents run autonomously!

---

## Support & Docs

- **Deployment Guide:** `docs/DEPLOYMENT.md`
- **Agent Setup:** `docs/AGENTS.md`
- **API Reference:** `docs/API.md`
- **Troubleshooting:** `docs/TROUBLESHOOTING.md`

---

**Built for:** Brian's autonomous AI team  
**Last updated:** 2026-03-30  
**License:** MIT
