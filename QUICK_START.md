# Quick Start — BriansClaw + OpenMOSS

**TL;DR:** Get your autonomous AI team running in 3 steps.

---

## ⚡ The 3-Step Deploy

### Step 1: SSH into Your Droplet
```bash
ssh root@143.110.233.145
```

### Step 2: Run One Command
```bash
curl -fsSL https://raw.github.com/yourusername/briansclawmoss/deploy.sh | bash
```

⏳ Wait 10-15 minutes... ☕

### Step 3: Access & Configure
```
Visit: http://143.110.233.145:6565
Complete setup wizard
Register agents
Create your first task
```

**That's it! Your agents are now working autonomously.** 🚀

---

## 📋 What Gets Installed

| Component | Port | Status |
|-----------|------|--------|
| OpenMOSS Backend | 6565 | ✅ Running |
| OpenClaw Gateway | 8080 | ✅ Running |
| Nginx Proxy | 80/443 | ✅ Running |
| SQLite Database | — | ✅ Ready |

---

## 🔑 Credentials (Save These!)

After deploy finishes, you'll see:
```
Admin Password: [RANDOM_STRING]
Registration Token: openclaw-[HEX]
```

Also saved to: `/root/openmoss-credentials.txt`

⚠️ **Keep these safe!**

---

## 📖 After Deploy

1. **Get a domain**
   - Register at GoDaddy, Namecheap, etc.
   - Point to: 143.110.233.145

2. **Enable SSL**
   ```bash
   sudo bash scripts/enable-ssl.sh your-domain.com
   ```

3. **Create agents**
   - Visit WebUI at `https://your-domain.com`
   - Register Planner, Executor, Reviewer, Patrol agents
   - Use role prompts from `agents/` folder

4. **Create task**
   - Click "New Task" in WebUI
   - Describe what you want built
   - Watch agents execute autonomously!

---

## 🎯 Example: Build a Blog API

**Goal:** Create REST API for a blog

**Workflow:**
1. Planner breaks into modules:
   - User authentication
   - Blog post CRUD
   - Comments system
   - Testing & deployment

2. Executor agents implement each module

3. Reviewer checks quality (tests, code style, docs)

4. Patrol monitors for issues & blockers

5. All work delivered automatically ✅

---

## 🔍 Monitor Progress

**View real-time activity:**
```bash
# Option 1: WebUI Activity Feed
https://your-domain.com/feed

# Option 2: Terminal logs
sudo journalctl -u openmoss -f
```

---

## ⚙️ Common Commands

```bash
# Check service status
sudo systemctl status openmoss

# Restart services
sudo systemctl restart openmoss openclaw

# View logs
sudo journalctl -u openmoss -n 50

# SSH into droplet
ssh root@143.110.233.145
```

---

## 📞 When Something Goes Wrong

**Services not starting?**
```bash
sudo journalctl -u openmoss -n 50
# Check error message, fix, restart
```

**Agent not connecting?**
```bash
# Verify:
# 1. External URL set in OpenMOSS config
# 2. Agent has correct API key
# 3. Network connectivity (ping your-domain.com)
```

**Need to rebuild?**
```bash
sudo bash deploy.sh   # Re-runs safely, updates components
```

---

## 🎓 Learning More

- **Full deployment guide:** `docs/DEPLOYMENT.md`
- **Agent setup & prompts:** `agents/`
- **OpenMOSS docs:** https://github.com/uluckyXH/OpenMOSS
- **OpenClaw docs:** https://github.com/openclaw/openclaw

---

## 💡 Pro Tips

1. **Start small** — Create simple tasks first
2. **Monitor agents** — Watch activity feed to understand workflow
3. **Iterate on prompts** — Refine agent instructions based on results
4. **Backup regularly** — The SQLite database is your audit trail
5. **Scale up slowly** — Add more executor agents as you get comfortable

---

## 🚀 You're Ready!

Your autonomous AI team is ready to work 24/7. Give it a task and watch magic happen.

Questions? Check `docs/` folder or see OpenMOSS/OpenClaw documentation.

**Good luck!** 🎉
