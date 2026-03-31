# LLM Setup Guide — OpenClaw + OpenMOSS

Your agents need an LLM to function. This guide covers all setup options.

---

## Overview

**How it works:**
1. Agents run on OpenClaw
2. OpenClaw calls an LLM API (Claude, GPT, etc.)
3. LLM generates task responses
4. Responses flow back through OpenMOSS

**Cost note:** Each agent interaction uses tokens. Budget accordingly!

---

## Option 1: Anthropic Claude (Recommended)

### Why Claude?
- ✅ Excellent code generation
- ✅ Large context window (200k tokens)
- ✅ Best for multi-agent coordination
- ✅ Works with OpenClaw's native integration

### Setup Steps

#### 1. Get API Key

1. Visit: https://console.anthropic.com
2. Log in or create account
3. Go to **API Keys** section
4. Click **Create Key**
5. Copy the key (starts with `sk-ant-`)

#### 2. Set Environment Variable

SSH into droplet:

```bash
ssh root@143.110.233.145

# Add to system environment
echo 'export ANTHROPIC_API_KEY=sk-ant-XXXXXXXXXXXX' >> /etc/environment

# Reload environment
source /etc/environment

# Verify it's set
echo $ANTHROPIC_API_KEY
```

#### 3. Configure OpenClaw

Edit OpenClaw config:

```bash
nano /opt/openclaw/config.json
```

Add/update:

```json
{
  "model": {
    "provider": "anthropic",
    "model": "claude-opus-4-6",
    "apiKey": "${ANTHROPIC_API_KEY}"
  }
}
```

#### 4. Test Connection

```bash
# Restart OpenClaw
sudo systemctl restart openclaw

# Check logs
sudo journalctl -u openclaw -n 20

# Should show: "Model initialized: claude-opus-4-6"
```

### Model Options

| Model | Speed | Cost | Use Case |
|-------|-------|------|----------|
| claude-haiku-4-5 | Fast | Low | Simple tasks, quick responses |
| claude-sonnet-4-6 | Balanced | Medium | General-purpose (recommended) |
| claude-opus-4-6 | Slow | High | Complex reasoning, architecture |

**Recommendation:** Start with Sonnet, use Opus for complex tasks.

#### Switching Models

```bash
# In /opt/openclaw/config.json, change:
"model": "claude-sonnet-4-6"

# Then restart
sudo systemctl restart openclaw
```

---

## Option 2: OpenAI GPT

### Setup Steps

#### 1. Get API Key

1. Visit: https://platform.openai.com/api-keys
2. Create new secret key
3. Copy key (starts with `sk-`)

#### 2. Set Environment Variable

```bash
echo 'export OPENAI_API_KEY=sk-XXXXXXXXXXXX' >> /etc/environment
source /etc/environment
```

#### 3. Configure OpenClaw

```bash
nano /opt/openclaw/config.json
```

```json
{
  "model": {
    "provider": "openai",
    "model": "gpt-4o",
    "apiKey": "${OPENAI_API_KEY}"
  }
}
```

#### 4. Restart OpenClaw

```bash
sudo systemctl restart openclaw
```

### Model Options

| Model | Notes |
|-------|-------|
| gpt-4o | Most capable, higher cost |
| gpt-4-turbo | Good balance |
| gpt-3.5-turbo | Budget option, lower quality |

---

## Option 3: Local LLM (Ollama)

### For Budget/Privacy-Conscious Setup

If you want to run LLM locally (on your droplet):

#### 1. Install Ollama

```bash
curl -fsSL https://ollama.ai/install.sh | sh

# Start service
systemctl start ollama
systemctl enable ollama
```

#### 2. Download Model

```bash
# Option A: Larger, better quality
ollama pull mistral

# Option B: Smaller, faster
ollama pull neural-chat

# Option C: Specialized coding
ollama pull codellama
```

#### 3. Configure OpenClaw

```bash
nano /opt/openclaw/config.json
```

```json
{
  "model": {
    "provider": "ollama",
    "model": "mistral",
    "baseUrl": "http://localhost:11434"
  }
}
```

#### 4. Restart OpenClaw

```bash
sudo systemctl restart openclaw
```

**Trade-offs:**
- ✅ No API costs
- ✅ Full privacy
- ✅ Instant inference
- ❌ Lower quality than Claude/GPT
- ❌ Uses significant droplet resources
- ❌ Slower inference

---

## Option 4: Azure OpenAI

### For Enterprise Deployments

#### 1. Setup Azure Account

- Create Azure subscription
- Deploy OpenAI resource
- Get endpoint URL and API key

#### 2. Configure OpenClaw

```bash
nano /opt/openclaw/config.json
```

```json
{
  "model": {
    "provider": "azure",
    "model": "gpt-4o",
    "apiKey": "${AZURE_OPENAI_API_KEY}",
    "endpoint": "https://your-resource.openai.azure.com/"
  }
}
```

#### 3. Set Environment Variables

```bash
echo 'export AZURE_OPENAI_API_KEY=xxxxx' >> /etc/environment
echo 'export AZURE_OPENAI_ENDPOINT=https://...' >> /etc/environment
source /etc/environment
```

---

## Recommendation Matrix

| Scenario | Best Choice |
|----------|-------------|
| **Production autonomous agents** | Claude Opus |
| **Cost-effective production** | Claude Sonnet |
| **High-volume simple tasks** | Claude Haiku |
| **OpenAI ecosystem** | GPT-4o |
| **Budget conscious** | Local Ollama |
| **Enterprise** | Azure OpenAI |

---

## Cost Estimation

### Anthropic Claude

| Task Type | Tokens | Cost |
|-----------|--------|------|
| Task planning | 500-2000 | $0.01-0.04 |
| Code generation | 2000-5000 | $0.04-0.10 |
| Code review | 1500-3000 | $0.03-0.06 |
| Full task (plan→exec→review) | 10000-20000 | $0.20-0.40 |

**Rough budget for autonomous team:**
- 10 tasks/day: ~$2-4/day = $60-120/month
- 100 tasks/day: ~$20-40/day = $600-1200/month

### OpenAI GPT-4o

Similar pricing (~$0.03 per 1K input tokens, $0.06 per 1K output tokens)

### Local Ollama

$0 (electricity only, ~$5-10/month depending on model)

---

## Multi-Model Setup (Advanced)

You can use **different models for different agents**:

```bash
# Create multiple OpenClaw instances
/opt/openclaw-planner/   # Uses Claude Opus (expensive, smart planning)
/opt/openclaw-executor/  # Uses Claude Sonnet (balanced)
/opt/openclaw-reviewer/  # Uses Claude Haiku (fast, simple QA)
/opt/openclaw-patrol/    # Uses Local Ollama (cheap, monitoring only)
```

This optimizes cost vs. quality for each agent role.

---

## Monitoring API Usage

### Anthropic Console

Visit: https://console.anthropic.com/usage

- Track tokens used
- Monitor costs
- Set spending limits
- View API request history

### OpenAI Console

Visit: https://platform.openai.com/usage/overview

- View usage by model
- Check costs
- Set rate limits

### Local Ollama

Check memory/CPU usage:

```bash
htop  # Look for ollama process
nvidia-smi  # If using GPU
```

---

## Troubleshooting

### "API Key Invalid"

```bash
# Check key is set
echo $ANTHROPIC_API_KEY

# Verify it's in config
grep -i apikey /opt/openclaw/config.json

# Restart service
sudo systemctl restart openclaw
```

### "Rate Limited"

Anthropic/OpenAI have rate limits:
- Wait before retrying
- Use backoff in agent prompts
- Consider higher-tier API plan

### "Model Not Available"

Ensure model name matches provider:
- Claude: `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5`
- OpenAI: `gpt-4o`, `gpt-4-turbo`, `gpt-3.5-turbo`
- Ollama: `mistral`, `neural-chat`, `codellama`, etc.

### Slow Responses

Likely causes:
- Large context window (reduce task complexity)
- Rate limiting (add delays)
- Model overloaded (switch to faster model)
- Network latency (check connection)

---

## Security Best Practices

⚠️ **API Keys are secrets!**

```bash
# ✅ Store in environment variables
export ANTHROPIC_API_KEY=sk-ant-xxxxx

# ✅ Never commit to git
echo "*.env" >> .gitignore

# ✅ Use systemd secrets for production
systemctl edit openclaw  # Secure storage

# ❌ Never hardcode in config files
# ❌ Never paste in logs
# ❌ Never commit to version control
```

---

## Next Steps After LLM Setup

1. ✅ Choose LLM provider
2. ✅ Get API key
3. ✅ Update OpenClaw config
4. ✅ Restart services
5. ✅ Test with simple agent task
6. ✅ Monitor costs
7. ✅ Adjust model selection if needed

---

## Example: Testing LLM Connection

After setup, create a simple test task:

```bash
# SSH into droplet
ssh root@143.110.233.145

# Check OpenClaw is running
sudo systemctl status openclaw

# View logs (should show model loading)
sudo journalctl -u openclaw -n 20
```

Then in OpenMOSS WebUI:
1. Create a task: "Write hello world in Python"
2. Watch it flow through agents
3. Check logs for any errors

---

**You're ready to power your autonomous team!** 🚀
