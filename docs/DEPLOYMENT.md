# Complete Deployment Guide — BriansClaw + OpenMOSS

Step-by-step instructions to deploy on your DigitalOcean droplet.

---

## Prerequisites

✅ **DigitalOcean Droplet Setup:**
- IP: 143.110.233.145
- OS: Ubuntu 24.04 LTS
- Specs: 16GB RAM / 4 CPUs / 320GB SSD
- SSH access working

✅ **Local Requirements:**
- SSH client (terminal on Mac/Linux, PuTTY/WSL on Windows)
- Domain name (can register during deployment)
- Anthropic API key (for Claude agents)

---

## Step 1: SSH into Your Droplet

```bash
ssh root@143.110.233.145
```

If prompted for a key, use the SSH key you configured in DigitalOcean.

Expected output:
```
Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.8.0-generic x86_64)
root@brianslaw:~#
```

---

## Step 2: Prepare for Deployment

Create a working directory:

```bash
mkdir -p /root/deployment
cd /root/deployment
```

Clone or download the deployment package:

**Option A: Clone from GitHub** (if uploaded)
```bash
git clone https://github.com/yourusername/briansclawmoss.git
cd briansclawmoss
```

**Option B: Manual setup** (if files are in workspace)
```bash
# Copy deployment files from your workspace
# Then continue...
```

**Option C: Download directly** (one-liner)
```bash
curl -fsSL https://raw.github.com/yourrepo/deploy.sh | bash
```

---

## Step 3: Make Deploy Script Executable

```bash
chmod +x deploy.sh
chmod +x scripts/*.sh
```

---

## Step 4: Run Automated Deployment

⚠️ **Note:** This takes 10-15 minutes depending on droplet speed.

```bash
sudo bash deploy.sh
```

What this does:
- ✅ Updates system packages
- ✅ Installs Node.js, Python, dependencies
- ✅ Clones OpenClaw and OpenMOSS
- ✅ Creates systemd services
- ✅ Configures firewall
- ✅ Starts all services
- ✅ Generates admin credentials (saved to `/root/openmoss-credentials.txt`)

**Expected output at end:**
```
==========================================
✓ Deployment Complete!
==========================================

Your BriansClaw + OpenMOSS system is ready!

Admin Password: [RANDOM STRING]
Registration Token: openclaw-[RANDOM HEX]

OpenMOSS Workspace: /opt/openmoss-workspace
OpenMOSS Database: /opt/openmoss/data/tasks.db

Credentials saved to: /root/openmoss-credentials.txt
```

Save these credentials somewhere safe! ⚠️

---

## Step 5: Verify Services Are Running

```bash
sudo systemctl status openmoss
sudo systemctl status openclaw
sudo systemctl status nginx
```

Expected output (all should show `active (running)`):
```
● openmoss.service - OpenMOSS Backend
   Loaded: loaded (/etc/systemd/system/openmoss.service)
   Active: active (running) since Mon 2026-03-30 19:59:00 UTC
```

Check logs for any errors:
```bash
sudo journalctl -u openmoss -n 20  # Last 20 lines of OpenMOSS log
sudo journalctl -u openclaw -n 20  # Last 20 lines of OpenClaw log
```

---

## Step 6: Access OpenMOSS WebUI (Before Domain)

While waiting for your domain, access via IP:

```
http://143.110.233.145:6565
```

⚠️ **Note:** Port 6565 is directly exposed for now. After adding domain + SSL, this will be proxied through Nginx.

Expected: OpenMOSS setup wizard should appear.

---

## Step 7: Register Your Domain

Once you have a domain, configure it in DigitalOcean:

1. Log into **DigitalOcean Console** → **Networking** → **Domains**
2. Click **Add Domain**
3. Enter your domain name
4. Select your droplet from the dropdown
5. DigitalOcean automatically creates nameserver records

Wait for DNS propagation (can take 5-30 minutes):

```bash
# Test DNS resolution
dig your-domain.com  # Should resolve to 143.110.233.145
```

---

## Step 8: Enable HTTPS/SSL

Once domain is resolving:

```bash
sudo bash scripts/enable-ssl.sh your-domain.com
```

This:
- ✅ Installs Let's Encrypt certificate
- ✅ Configures Nginx with SSL
- ✅ Sets up auto-renewal
- ✅ Redirects HTTP → HTTPS

**Expected output:**
```
========================================
✓ SSL Setup Complete!
========================================

Access your services at:
  https://your-domain.com          (OpenMOSS WebUI)
  https://your-domain.com/openclaw/ (OpenClaw)
```

---

## Step 9: Complete OpenMOSS Setup Wizard

Visit your domain:

```
https://your-domain.com
```

Complete the setup wizard:

1. **Set Admin Password**
   - Change from auto-generated value
   - Use a strong password (20+ characters)
   - Save securely in password manager

2. **Configure Project**
   - Name: "BriansClaw" (or your preference)
   - Workspace: `/opt/openmoss-workspace` (already set)

3. **Agent Registration Token**
   - Note the token shown (or generate new one)
   - This is what agents will use to register

4. **Notifications** (Optional)
   - Configure Slack, email, or webhooks
   - Can skip for now, add later

5. **External URL**
   - Set to: `https://your-domain.com`
   - Critical for agent callbacks!

Click **Complete Setup** when done.

---

## Step 10: Set Environment Variables (For Agents)

Agents need to know how to reach OpenMOSS. Create a config file:

```bash
cat > /etc/environment << 'EOF'
OPENMOSS_API_URL=https://your-domain.com
OPENMOSS_REGISTRATION_TOKEN=openclaw-xxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxx
EOF
```

Replace:
- `your-domain.com` with your actual domain
- `openclaw-xxxxxxxxxxxx` with your registration token
- `sk-ant-xxxxxxxxxx` with your Anthropic API key

Load the variables:

```bash
source /etc/environment
```

---

## Step 11: Create Your First Agents

In OpenMOSS WebUI, click **Admin** → **Agents** → **New Agent**

### Agent 1: Planner

```
Name: Planner Agent
Role: Planner
Prompt: [Copy from agents/planner-prompt.md]
```

Click **Register Agent** — you'll get an API key. Save it!

Repeat for:
- **Executor Agent** (using agents/executor-prompt.md)
- **Reviewer Agent** (using agents/reviewer-prompt.md)
- **Patrol Agent** (using agents/patrol-prompt.md)

---

## Step 12: Deploy Agent Instances

Each agent needs to run as an OpenClaw instance. For each agent:

```bash
# SSH into your droplet
ssh root@143.110.233.145

# Create agent config
cat > /opt/openmoss/agents/planner.json << 'EOF'
{
  "name": "Planner Agent",
  "role": "planner",
  "api_key": "YOUR_AGENT_API_KEY_FROM_STEP_11",
  "openmoss_api_url": "https://your-domain.com",
  "model": "claude-opus-4-6",
  "cron_schedule": "*/5 * * * *"
}
EOF
```

Repeat for executor, reviewer, patrol agents.

---

## Step 13: Test End-to-End

In OpenMOSS WebUI:

1. Click **Tasks** → **New Task**
2. Enter a simple goal: "Create a hello world REST API"
3. Click **Create**
4. Watch the task flow through the system!

Expected workflow:
- ✅ Planner breaks it into modules
- ✅ Planner creates sub-tasks
- ✅ Executor claims task and starts work
- ✅ Executor submits for review
- ✅ Reviewer approves or requests changes
- ✅ Patrol monitors for any issues
- ✅ Task marked complete

Check activity feed to see agents working in real-time!

---

## Step 14: Monitoring & Maintenance

### View Logs

```bash
# OpenMOSS logs
sudo journalctl -u openmoss -f

# OpenClaw logs
sudo journalctl -u openclaw -f

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### Restart Services

```bash
sudo systemctl restart openmoss
sudo systemctl restart openclaw
sudo systemctl restart nginx
```

### Check Disk Usage

```bash
df -h                    # Overall disk space
du -sh /opt/openmoss/*   # OpenMOSS disk usage
du -sh /opt/openclaw/*   # OpenClaw disk usage
```

### Backup Data

```bash
# Backup OpenMOSS database
cp /opt/openmoss/data/tasks.db /opt/openmoss/data/tasks.db.backup.$(date +%Y%m%d)

# Backup workspace
tar -czf /root/workspace-backup-$(date +%Y%m%d).tar.gz /opt/openmoss-workspace/
```

---

## Troubleshooting

### Service Won't Start

```bash
sudo journalctl -u openmoss -n 50  # See error messages
```

Common fixes:
- Port already in use: `sudo lsof -i :6565`
- Python dependency missing: `pip install -r requirements.txt`
- Config file corrupted: `cp config.example.yaml config.yaml`

### Domain Not Resolving

```bash
# Test DNS
dig your-domain.com
nslookup your-domain.com

# Verify DigitalOcean has correct IP
# (can take 5-30 minutes to propagate)
```

### SSL Certificate Issues

```bash
sudo certbot renew --dry-run  # Test renewal
sudo certbot certificates     # View all certs
```

### Agent Not Connecting

Check agent has correct:
- `OPENMOSS_API_URL` (https, with your domain)
- `OPENMOSS_REGISTRATION_TOKEN` (from setup wizard)
- `ANTHROPIC_API_KEY` (valid and not expired)

---

## Security Hardening (Production)

After initial setup, consider:

1. **Firewall Rules**
   ```bash
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 80/tcp    # HTTP
   sudo ufw allow 443/tcp   # HTTPS
   sudo ufw deny 6565/tcp   # Block direct OpenMOSS access
   sudo ufw deny 8080/tcp   # Block direct OpenClaw access
   ```

2. **Change Passwords Regularly**
   ```bash
   # In OpenMOSS admin panel, change admin password
   ```

3. **Regular Backups**
   ```bash
   # Automated backup script
   0 2 * * * tar -czf /backup/openmoss-$(date +\%Y\%m\%d).tar.gz /opt/openmoss/data/
   ```

4. **Enable Rate Limiting** (Nginx)
   - Already configured in enable-ssl.sh

5. **Monitor Logs**
   ```bash
   # Watch for suspicious activity
   grep "Failed\|Error\|Unauthorized" /var/log/nginx/error.log
   ```

---

## Next Steps

🎉 **Congratulations! Your BriansClaw + OpenMOSS is live!**

1. ✅ Create more complex tasks
2. ✅ Fine-tune agent prompts
3. ✅ Add more executor agents for parallel work
4. ✅ Set up notifications
5. ✅ Monitor and optimize

---

## Support Resources

- **OpenClaw Docs:** https://github.com/openclaw/openclaw
- **OpenMOSS Docs:** https://github.com/uluckyXH/OpenMOSS
- **DigitalOcean Support:** https://www.digitalocean.com/support/
- **Let's Encrypt Docs:** https://letsencrypt.org/getting-started/

---

**Last Updated:** 2026-03-30  
**Status:** Production Ready
