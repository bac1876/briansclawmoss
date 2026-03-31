# ⚡ Critical: LLM Configuration Required

**Before deploying, you MUST configure an LLM provider.**

Agents can't work without an LLM to generate responses!

---

## Quick Setup (Choose One)

### 🥇 Recommended: Anthropic Claude

1. **Get API key:** https://console.anthropic.com/api-keys
2. **After `deploy.sh` runs:**

```bash
ssh root@143.110.233.145

# Set API key (replace with your actual key)
export ANTHROPIC_API_KEY=sk-ant-XXXXXXXXXXXX
echo 'export ANTHROPIC_API_KEY=sk-ant-XXXXXXXXXXXX' >> /etc/environment

# Update OpenClaw config
sed -i 's|ANTHROPIC_API_KEY_HERE|sk-ant-XXXXXXXXXXXX|' /opt/openclaw/config.json

# Restart OpenClaw
sudo systemctl restart openclaw
```

### Alternative: OpenAI GPT-4

```bash
export OPENAI_API_KEY=sk-XXXXXXXXXXXX
echo 'export OPENAI_API_KEY=sk-XXXXXXXXXXXX' >> /etc/environment
```

### Budget: Local Ollama (Free)

```bash
# Install & run locally
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull mistral
```

---

## Full Setup Guide

See: **`docs/LLM_SETUP.md`**

This covers:
- ✅ All LLM provider options (Anthropic, OpenAI, Azure, Ollama)
- ✅ Cost estimation
- ✅ Model selection guidance
- ✅ Configuration steps
- ✅ Troubleshooting

---

## Cost Estimate

**Claude Sonnet (recommended):**
- Small task: ~$0.01-0.05
- Medium task: ~$0.10-0.20
- Full workflow (plan→execute→review): ~$0.30-0.50

**Budget:** $50-200/month for active autonomous team

---

## Deployment Timeline

1. Choose LLM provider → 5 min
2. Get API key → 2 min
3. Run `deploy.sh` → 15 min
4. Configure LLM → 2 min
5. Register agents → 5 min
6. Create test task → 2 min

**Total: ~30 minutes**

---

**Don't skip this step!** Read `docs/LLM_SETUP.md` before deploying.
