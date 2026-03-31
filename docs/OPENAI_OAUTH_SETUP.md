# OpenAI OAuth Setup for SolveTheProblem.ai

Configure BriansClaw agents to use your OpenAI OAuth account.

---

## Architecture

```
Agents (OpenClaw) 
    ↓
OpenAI API (using your OAuth credentials)
    ↓
GPT-4o (primary model for agents)
    ↓
Task completions via solvetheproblem.ai
```

---

## Step 1: Get Your OpenAI API Key

### Option A: Personal API Key (Simplest)

1. Visit: https://platform.openai.com/api-keys
2. Click **Create new secret key**
3. Copy the key (starts with `sk-`)
4. Save it securely (you can't view it again)

### Option B: Organization API Key (Recommended for Business)

1. Visit: https://platform.openai.com/organization/settings/general
2. Get your **Organization ID**
3. Create API key under organization settings
4. This separates billing per organization

---

## Step 2: Set Up on Droplet

### SSH into your droplet:

```bash
ssh root@143.110.233.145
```

### Create a secure credentials file:

```bash
# Create credentials directory
mkdir -p /opt/credentials
chmod 700 /opt/credentials

# Create credentials file
cat > /opt/credentials/openai.env << 'EOF'
# OpenAI API Configuration
OPENAI_API_KEY=sk-proj-XXXXXXXXXXXXXXXXXXXX
OPENAI_ORG_ID=org-XXXXXXXXXXXXXXXXXXXX  # Optional, only if using org API key
OPENAI_MODEL=gpt-4o
EOF

# Secure it
chmod 600 /opt/credentials/openai.env
```

Replace:
- `sk-proj-XXXXXXXXXXXXXXXXXXXX` with your actual API key
- `org-XXXXXXXXXXXXXXXXXXXX` with your org ID (if applicable)

### Load credentials into system:

```bash
# Add to /etc/environment for system-wide access
cat >> /etc/environment << 'EOF'
OPENAI_API_KEY=sk-proj-XXXXXXXXXXXXXXXXXXXX
OPENAI_ORG_ID=org-XXXXXXXXXXXXXXXXXXXX
OPENAI_MODEL=gpt-4o
EOF

# Reload environment
source /etc/environment

# Verify
echo $OPENAI_API_KEY
```

---

## Step 3: Configure OpenClaw for OpenAI

### Edit OpenClaw config:

```bash
nano /opt/openclaw/config.json
```

Update the model section:

```json
{
  "model": {
    "provider": "openai",
    "model": "gpt-4o",
    "apiKey": "${OPENAI_API_KEY}",
    "organizationId": "${OPENAI_ORG_ID}"
  },
  "modelFallback": {
    "enabled": true,
    "fallbackModel": "gpt-4-turbo",
    "fallbackConditions": ["rate_limit", "model_unavailable"]
  }
}
```

### Configure OpenMOSS for OpenAI (optional):

```bash
nano /opt/openmoss/config.yaml
```

Add:

```yaml
models:
  default: gpt-4o
  fallback: gpt-4-turbo
  organization_id: org-XXXXXXXXXXXXXXXXXXXX
  
# Cost tracking
cost_tracking:
  enabled: true
  alert_threshold: 50  # Alert if daily spend > $50
```

---

## Step 4: Model Selection

### Recommended Configuration:

| Agent | Model | Reason |
|-------|-------|--------|
| **Planner** | gpt-4o | Complex reasoning, task decomposition |
| **Executor** | gpt-4o | Code quality & accuracy |
| **Reviewer** | gpt-4-turbo | Fast QA, cost optimization |
| **Patrol** | gpt-3.5-turbo | Simple monitoring, cheap |

### Advanced: Multi-Model Setup

Create separate OpenClaw instances per agent role:

```bash
# Create config for planner (expensive, smart)
cat > /opt/openclaw-planner.json << 'EOF'
{
  "model": {
    "provider": "openai",
    "model": "gpt-4o"
  }
}
EOF

# Create config for executor (balanced)
cat > /opt/openclaw-executor.json << 'EOF'
{
  "model": {
    "provider": "openai",
    "model": "gpt-4-turbo"
  }
}
EOF

# Create config for reviewer (cheap, fast)
cat > /opt/openclaw-reviewer.json << 'EOF'
{
  "model": {
    "provider": "openai",
    "model": "gpt-3.5-turbo"
  }
}
EOF
```

This optimizes cost while maintaining quality.

---

## Step 5: Restart Services

```bash
# Reload environment
source /etc/environment

# Restart OpenClaw
sudo systemctl restart openclaw

# Restart OpenMOSS
sudo systemctl restart openmoss

# Verify they're running
sudo systemctl status openclaw
sudo systemctl status openmoss
```

### Check logs for successful connection:

```bash
sudo journalctl -u openclaw -n 50

# Should show:
# "OpenAI API initialized"
# "Model: gpt-4o"
# "Organization: org-XXXXX (if configured)"
```

---

## Step 6: Cost Management

### Monitor Usage:

```bash
# OpenAI dashboard
https://platform.openai.com/usage/overview

# Check by model:
https://platform.openai.com/billing/limits
```

### Set Spending Limits (Recommended):

1. Visit: https://platform.openai.com/account/billing/limits
2. Set **Hard Limit** (stops API calls when exceeded)
3. Set **Soft Limit** (alerts you when spending reaches threshold)

**Recommendations:**
- Hard limit: $100/month (or your budget)
- Soft limit: $80/month (get alerted before hitting hard limit)

### Track Costs:

OpenAI charges per 1,000 tokens:

| Model | Input | Output | Notes |
|-------|-------|--------|-------|
| gpt-4o | $0.005 | $0.015 | Best quality, most expensive |
| gpt-4-turbo | $0.01 | $0.03 | Good balance |
| gpt-3.5-turbo | $0.0005 | $0.0015 | Budget option |

**Rough task costs:**
- Simple task: $0.02-0.05
- Medium task: $0.05-0.15
- Complex task: $0.15-0.50
- Full workflow: $0.30-1.00

---

## Step 7: Test Connection

### Create a test task:

1. SSH into droplet
2. Start a simple test:

```bash
curl -X POST http://localhost:6565/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Write hello world in Python",
    "modules": [
      {
        "name": "Simple Task",
        "description": "Just test if OpenAI is connected"
      }
    ]
  }'
```

### Monitor task execution:

```bash
# Watch OpenClaw logs
sudo journalctl -u openclaw -f

# Should show:
# "Calling OpenAI API..."
# "Model: gpt-4o"
# "Tokens used: XXX"
```

### Check OpenMOSS WebUI:

Visit: `https://your-domain.com` (after SSL setup)

1. Go to **Tasks**
2. Create new task: "Build a REST API"
3. Watch agents execute using GPT-4o
4. Check activity feed to see API calls

---

## Advanced: OAuth Token Refresh (If Needed)

If using OAuth tokens instead of API keys:

```bash
# OAuth setup (less common for API automation)
cat > /opt/credentials/openai-oauth.env << 'EOF'
OPENAI_CLIENT_ID=xxx
OPENAI_CLIENT_SECRET=yyy
OPENAI_REFRESH_TOKEN=zzz
EOF

chmod 600 /opt/credentials/openai-oauth.env
```

Then configure OpenClaw to use OAuth:

```json
{
  "model": {
    "provider": "openai",
    "auth": "oauth",
    "clientId": "${OPENAI_CLIENT_ID}",
    "clientSecret": "${OPENAI_CLIENT_SECRET}"
  }
}
```

---

## Domain Integration: solvetheproblem.ai

Once agents are working, you can surface results via your domain:

### Option 1: Proxy Through Nginx

```nginx
# In /etc/nginx/sites-available/solvetheproblem.ai

location /agents/ {
    proxy_pass http://127.0.0.1:6565/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

This exposes agent results at: `https://solvetheproblem.ai/agents/`

### Option 2: Webhook Notifications

Configure agents to POST results to your domain:

```yaml
# In OpenMOSS config
webhooks:
  task_completed: https://solvetheproblem.ai/api/task-complete
  review_approved: https://solvetheproblem.ai/api/review-approved
```

Agents will POST task results to your API endpoints.

### Option 3: Custom Integration

Build a custom API endpoint that:
1. Accepts task requests via solvetheproblem.ai
2. Creates OpenMOSS task
3. Waits for completion
4. Returns results to user

---

## Troubleshooting

### "Invalid API Key"

```bash
# Verify key is set
echo $OPENAI_API_KEY

# Verify it's valid (starts with sk-)
echo $OPENAI_API_KEY | grep -E '^sk-'

# Test with curl
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### "Rate Limited"

OpenAI rate limits depend on your account:
- Free tier: 3 requests/minute
- Paid tier: Much higher (check your account)

**Fix:**
1. Upgrade to paid OpenAI account
2. Wait between requests
3. Use fallback models (gpt-3.5-turbo is cheaper)

### "Model Not Available"

Ensure model names are correct:
- `gpt-4o` ✅
- `gpt-4-turbo` ✅
- `gpt-3.5-turbo` ✅
- `gpt-4` ✅
- `gpt-3.5` ❌ (missing -turbo)

### "Organization ID Invalid"

Optional — only include if using org API key:

```bash
# Verify org ID
curl https://api.openai.com/v1/organization \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "OpenAI-Organization: $OPENAI_ORG_ID"
```

---

## Security Best Practices

⚠️ **Your API key is a secret!**

```bash
# ✅ Store in environment variables
export OPENAI_API_KEY=sk-proj-xxxxx

# ✅ Restrict file permissions
chmod 600 /opt/credentials/openai.env

# ✅ Never commit to git
echo ".env" >> .gitignore
echo "/opt/credentials/" >> .gitignore

# ❌ Never hardcode in configs
# ❌ Never paste in logs
# ❌ Never share in Discord/email

# Rotate regularly
# If leaked, regenerate immediately at:
# https://platform.openai.com/api-keys
```

### Audit Trail:

```bash
# Monitor API usage
https://platform.openai.com/account/usage

# Check for suspicious activity
# Look for unexpected model calls or high usage
```

---

## Deployment Summary

1. ✅ Get OpenAI API key from https://platform.openai.com/api-keys
2. ✅ SSH into droplet: `ssh root@143.110.233.145`
3. ✅ Set `OPENAI_API_KEY` environment variable
4. ✅ Update OpenClaw config.json with OpenAI provider
5. ✅ Restart services: `sudo systemctl restart openclaw openmoss`
6. ✅ Test with simple task via WebUI
7. ✅ Monitor costs at https://platform.openai.com/usage/overview
8. ✅ (Optional) Set spending limits to prevent surprises

---

## Next Steps

- [x] Setup OpenAI API key
- [ ] Run `deploy.sh` on droplet
- [ ] Get domain (solvetheproblem.ai is already yours!)
- [ ] Point domain to 143.110.233.145
- [ ] Enable SSL: `sudo bash scripts/enable-ssl.sh solvetheproblem.ai`
- [ ] Register agents in OpenMOSS
- [ ] Create first task and watch GPT-4o work

---

**Ready to launch your autonomous AI team on solvetheproblem.ai!** 🚀
