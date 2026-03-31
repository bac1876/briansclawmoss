# Installation Guide — BriansClaw + OpenMOSS

**Complete, production-ready setup in one deployment.**

---

## Prerequisites

✅ DigitalOcean Droplet (16GB RAM, 4 CPUs, Ubuntu 24.04 LTS)
✅ Domain pointing to droplet IP (DNS working)
✅ OpenAI API key (from https://platform.openai.com/api-keys)
✅ SSH access to droplet

---

## Step 1: Prepare Your Domain (Already Done)

Your domain `solvetheproblem.ai` is already:
- ✅ Pointing to 143.110.233.145
- ✅ Has SSL certificate installed

---

## Step 2: SSH Into Droplet

```
ssh root@143.110.233.145
```

---

## Step 3: Clone This Repository

```
cd /root
git clone https://github.com/yourusername/briansclawmoss.git deployment
cd deployment
```

---

## Step 4: Configure Before Deployment

### Set your OpenAI credentials:

```
export OPENAI_CLIENT_ID=your-client-id
export OPENAI_CLIENT_SECRET=your-client-secret
export OPENAI_REDIRECT_URI=https://solvetheproblem.ai/auth/callback
```

Save to system environment:

```
cat >> /etc/environment << 'EOF'
OPENAI_CLIENT_ID=your-client-id
OPENAI_CLIENT_SECRET=your-client-secret
OPENAI_REDIRECT_URI=https://solvetheproblem.ai/auth/callback
EOF

source /etc/environment
```

---

## Step 5: Run Full Deployment

```
sudo bash deploy.sh
```

This **one command** will:
- ✅ Install all system dependencies
- ✅ Clone OpenClaw and OpenMOSS
- ✅ Install Python packages
- ✅ Create systemd services
- ✅ Configure Nginx
- ✅ Initialize databases
- ✅ Start all services

**Time:** 15-20 minutes

---

## Step 6: Verify Installation

Check services are running:

```
sudo systemctl status openmoss
sudo systemctl status openclaw
sudo systemctl status nginx
```

All should show: `active (running)`

Check logs for errors:

```
sudo journalctl -u openmoss -n 20
sudo journalctl -u openclaw -n 20
```

---

## Step 7: Access WebUI

Open your browser:

```
https://solvetheproblem.ai
```

You should see the **OpenMOSS Setup Wizard**.

---

## Step 8: Complete Setup Wizard

1. **Admin Password** — Change to a strong password
2. **Project Name** — "BriansClaw"
3. **Workspace** — `/opt/openmoss-workspace`
4. **Registration Token** — Copy and save (agents use this)
5. **External URL** — `https://solvetheproblem.ai`
6. **Click Complete**

---

## Step 9: Register Your First Agents

In WebUI, click **Admin** → **Agents** → **Register New Agent**

For each agent, fill in:
- **Name:** Agent name
- **Role:** planner/executor/reviewer/patrol
- **Prompt:** Copy from `agents/[role]-prompt.md`

Save the API keys you receive!

---

## Step 10: Test End-to-End

1. Click **Tasks** → **New Task**
2. Enter: `"Build a hello world REST API"`
3. Click **Create**
4. Watch the **Activity Feed** — agents should start working!

---

## Troubleshooting

### Services won't start

```
sudo journalctl -u openmoss -n 50
```

Check for:
- Missing dependencies: Run `deploy.sh` again
- Port conflicts: `sudo lsof -i :6565`
- Config errors: Check `/opt/openmoss/config.yaml`

### WebUI won't load

```
curl https://solvetheproblem.ai
```

If error, check:
- Nginx logs: `sudo tail -f /var/log/nginx/error.log`
- Services running: `sudo systemctl status nginx`
- SSL cert: `sudo certbot certificates`

### Agents not working

Check:
- OpenAI API key is set: `echo $OPENAI_CLIENT_ID`
- Services are running: `sudo systemctl status`
- Logs for errors: `sudo journalctl -u openmoss -f`

---

## Post-Deployment

### Backup Your Data

```
tar -czf /backup/openmoss-$(date +%Y%m%d).tar.gz /opt/openmoss/data/
```

### Monitor Services

```
watch -n 5 'systemctl status openmoss openclaw nginx'
```

### View Real-Time Logs

```
sudo journalctl -u openmoss -f
```

### Restart Services

```
sudo systemctl restart openmoss openclaw nginx
```

### Update Services

```
cd /root/deployment
git pull
sudo bash deploy.sh  # Safe to run again, updates only what changed
```

---

## Security Checklist

- [ ] Changed admin password during setup
- [ ] Saved agent registration token securely
- [ ] OpenAI credentials stored in `/etc/environment` (not config files)
- [ ] Firewall enabled: `sudo ufw status`
- [ ] SSL certificate active: `sudo certbot certificates`
- [ ] Regular backups of `/opt/openmoss/data/`

---

## You're Done! 🎉

Your autonomous AI team is now running 24/7 at:

```
https://solvetheproblem.ai
```

**Next steps:**
1. Create your first task
2. Monitor agent activity
3. Refine agent prompts based on results
4. Scale up with more executor agents

---

For detailed guides, see:
- `QUICK_START.md` — 3-step overview
- `docs/DEPLOYMENT.md` — Comprehensive guide
- `docs/OPENAI_OAUTH_IMPLEMENTATION.md` — OAuth setup
- `docs/LLM_SETUP.md` — LLM configuration
- `agents/` — Agent role definitions

---

**Questions?** Check the logs:

```
sudo journalctl -u openmoss -n 100
```

**Issues?** Review `docs/TROUBLESHOOTING.md`
