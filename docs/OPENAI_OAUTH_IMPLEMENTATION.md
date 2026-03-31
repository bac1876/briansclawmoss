# OpenAI OAuth Implementation for BriansClaw

Use OpenAI OAuth to authenticate agents instead of API keys.

---

## What is OAuth?

OAuth lets users authorize your app to use OpenAI on their behalf **without sharing API keys**.

**Instead of:**
```
Your app → API key → OpenAI
(exposes key)
```

**With OAuth:**
```
User → OpenAI login → Authorization → Token → Your app → OpenAI
(secure, user-controlled)
```

---

## Step 1: Register Your App with OpenAI

### Visit OpenAI OAuth Settings

1. Go to: https://platform.openai.com/apps
2. Click **New App**
3. Fill in:
   - **App name:** `BriansClaw` (or your preference)
   - **App URL:** `https://solvetheproblem.ai`
   - **Redirect URI:** `https://solvetheproblem.ai/auth/callback`
   - **Description:** Autonomous AI agent team

4. Click **Create App**

5. You'll receive:
   - **Client ID** (share openly)
   - **Client Secret** (KEEP SECRET!)

Save both securely!

---

## Step 2: Store Credentials on Droplet

SSH into your droplet:

```bash
ssh root@143.110.233.145

# Create secure credentials directory
mkdir -p /opt/credentials
chmod 700 /opt/credentials

# Store OAuth credentials
cat > /opt/credentials/openai-oauth.env << 'EOF'
OPENAI_CLIENT_ID=your-client-id-here
OPENAI_CLIENT_SECRET=your-client-secret-here
OPENAI_REDIRECT_URI=https://solvetheproblem.ai/auth/callback
EOF

chmod 600 /opt/credentials/openai-oauth.env

# Load into environment
source /opt/credentials/openai-oauth.env
echo "export OPENAI_CLIENT_ID=$OPENAI_CLIENT_ID" >> /etc/environment
echo "export OPENAI_CLIENT_SECRET=$OPENAI_CLIENT_SECRET" >> /etc/environment
echo "export OPENAI_REDIRECT_URI=$OPENAI_REDIRECT_URI" >> /etc/environment

source /etc/environment
```

---

## Step 3: Configure OpenClaw for OAuth

### Edit OpenClaw config:

```bash
nano /opt/openclaw/config.json
```

Replace the model section with:

```json
{
  "auth": {
    "provider": "openai-oauth",
    "clientId": "${OPENAI_CLIENT_ID}",
    "clientSecret": "${OPENAI_CLIENT_SECRET}",
    "redirectUri": "${OPENAI_REDIRECT_URI}"
  },
  "model": {
    "provider": "openai",
    "model": "gpt-4o",
    "auth": "oauth"
  }
}
```

---

## Step 4: Add OAuth Callback Handler

Create an endpoint that handles OAuth redirects:

```bash
cat > /opt/openclaw/routes/oauth-callback.js << 'EOF'
const express = require('express');
const router = express.Router();
const axios = require('axios');

// OAuth callback endpoint
router.get('/auth/callback', async (req, res) => {
  const { code, state } = req.query;
  
  if (!code) {
    return res.status(400).json({ error: 'Missing authorization code' });
  }

  try {
    // Exchange code for access token
    const tokenResponse = await axios.post('https://api.openai.com/oauth/token', {
      grant_type: 'authorization_code',
      client_id: process.env.OPENAI_CLIENT_ID,
      client_secret: process.env.OPENAI_CLIENT_SECRET,
      code: code,
      redirect_uri: process.env.OPENAI_REDIRECT_URI
    });

    const accessToken = tokenResponse.data.access_token;
    const refreshToken = tokenResponse.data.refresh_token;

    // Store tokens securely (preferably in database)
    // For now, store in session/cookie
    res.cookie('openai_access_token', accessToken, {
      secure: true,
      httpOnly: true,
      sameSite: 'Strict'
    });

    if (refreshToken) {
      res.cookie('openai_refresh_token', refreshToken, {
        secure: true,
        httpOnly: true,
        sameSite: 'Strict'
      });
    }

    // Redirect to success page
    res.redirect('/auth/success');
  } catch (error) {
    console.error('OAuth token exchange failed:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
});

// OAuth login initiation
router.get('/auth/login', (req, res) => {
  const authUrl = new URL('https://api.openai.com/oauth/authorize');
  authUrl.searchParams.append('client_id', process.env.OPENAI_CLIENT_ID);
  authUrl.searchParams.append('redirect_uri', process.env.OPENAI_REDIRECT_URI);
  authUrl.searchParams.append('response_type', 'code');
  authUrl.searchParams.append('scope', 'openai');
  
  res.redirect(authUrl.toString());
});

module.exports = router;
EOF
```

### Register the route in OpenClaw:

```bash
# In /opt/openclaw/app.js, add:
const oauthRoutes = require('./routes/oauth-callback');
app.use('/', oauthRoutes);
```

---

## Step 5: Configure OpenMOSS for OAuth

Edit OpenMOSS config:

```bash
nano /opt/openmoss/config.yaml
```

Add OAuth section:

```yaml
openai:
  auth_type: oauth
  client_id: ${OPENAI_CLIENT_ID}
  client_secret: ${OPENAI_CLIENT_SECRET}
  redirect_uri: https://solvetheproblem.ai/auth/callback
  
  # Token storage (use database in production)
  token_storage: redis  # or: database, memory
  
  # Scopes requested from OpenAI
  scopes:
    - openai  # Full access
    - openai:write  # Create/modify
    - openai:read   # Read only
```

---

## Step 6: Add OAuth Login Page (WebUI)

Create a login page for users:

```html
<!-- /opt/openmoss/webui/src/views/OAuthLogin.vue -->

<template>
  <div class="oauth-login">
    <h1>Connect OpenAI Account</h1>
    <p>Authorize BriansClaw to use your OpenAI account</p>
    
    <a href="/auth/login" class="btn btn-primary">
      Login with OpenAI
    </a>
  </div>
</template>

<script setup>
// Component to redirect to OAuth flow
</script>

<style scoped>
.oauth-login {
  text-align: center;
  padding: 40px;
}

.btn {
  padding: 12px 24px;
  font-size: 16px;
  cursor: pointer;
}

.btn-primary {
  background-color: #10a37f;
  color: white;
  border: none;
  border-radius: 6px;
}
</style>
```

---

## Step 7: Token Management

### Store Tokens Securely

**Option A: Redis (Recommended)**

```bash
# Install Redis
apt-get install -y redis-server

# Store tokens
redis-cli SET oauth:user:123 '{"access_token":"...", "refresh_token":"..."}'
```

**Option B: PostgreSQL Database**

```sql
-- Create tokens table
CREATE TABLE oauth_tokens (
  user_id UUID PRIMARY KEY,
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for quick lookup
CREATE INDEX idx_oauth_user ON oauth_tokens(user_id);
```

**Option C: Encrypted File Storage**

```bash
# Store encrypted tokens
cat > /opt/openmoss/lib/token-storage.js << 'EOF'
const crypto = require('crypto');
const fs = require('fs');

class TokenStorage {
  constructor(encryptionKey) {
    this.encryptionKey = encryptionKey;
    this.storePath = '/opt/credentials/tokens.enc';
  }

  saveToken(userId, accessToken, refreshToken) {
    const token = {
      userId,
      accessToken,
      refreshToken,
      savedAt: new Date()
    };

    // Encrypt token
    const cipher = crypto.createCipher('aes-256-cbc', this.encryptionKey);
    let encrypted = cipher.update(JSON.stringify(token), 'utf8', 'hex');
    encrypted += cipher.final('hex');

    // Store encrypted
    fs.writeFileSync(this.storePath, encrypted);
  }

  getToken(userId) {
    const encrypted = fs.readFileSync(this.storePath, 'utf8');
    
    // Decrypt token
    const decipher = crypto.createDecipher('aes-256-cbc', this.encryptionKey);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return JSON.parse(decrypted);
  }
}

module.exports = TokenStorage;
EOF
```

### Refresh Expired Tokens

```javascript
async function refreshAccessToken(refreshToken) {
  try {
    const response = await axios.post('https://api.openai.com/oauth/token', {
      grant_type: 'refresh_token',
      client_id: process.env.OPENAI_CLIENT_ID,
      client_secret: process.env.OPENAI_CLIENT_SECRET,
      refresh_token: refreshToken
    });

    return response.data.access_token;
  } catch (error) {
    console.error('Token refresh failed:', error);
    throw error;
  }
}
```

---

## Step 8: Use OAuth Token in API Calls

### When Making OpenAI Requests:

```javascript
// Instead of API key
const config = {
  headers: {
    'Authorization': `Bearer ${accessToken}`,  // OAuth token
    'Content-Type': 'application/json'
  }
};

// Make API call
const response = await axios.post(
  'https://api.openai.com/v1/chat/completions',
  {
    model: 'gpt-4o',
    messages: [{ role: 'user', content: 'Hello' }]
  },
  config
);
```

---

## Step 9: Restart Services

```bash
# Reload environment
source /etc/environment

# Restart OpenClaw
sudo systemctl restart openclaw

# Restart OpenMOSS
sudo systemctl restart openmoss

# Check logs
sudo journalctl -u openclaw -n 50
```

Should see:
```
OpenAI OAuth initialized
Redirect URI: https://solvetheproblem.ai/auth/callback
Ready for user authentication
```

---

## Step 10: Test OAuth Flow

### 1. Visit Login Page

```
https://solvetheproblem.ai/auth/login
```

### 2. Click "Login with OpenAI"

Redirects to OpenAI login screen

### 3. User Authorizes

User logs in and grants permission

### 4. Callback Received

Redirected back to: `https://solvetheproblem.ai/auth/callback`

Token stored securely

### 5. Ready to Use

Agents can now make OpenAI API calls using user's auth!

---

## User Experience Flow

```
User visits solvetheproblem.ai
        ↓
Clicks "Connect OpenAI"
        ↓
Redirected to OpenAI login
        ↓
User authorizes app
        ↓
Redirected back to solvetheproblem.ai
        ↓
Token stored securely
        ↓
Agents can use OpenAI on user's behalf
        ↓
User creates task
        ↓
Agents execute using user's OpenAI account
```

---

## Security Best Practices

⚠️ **Critical:**

```bash
# ✅ Store client secret securely
chmod 600 /opt/credentials/openai-oauth.env

# ✅ Use HTTPS only (no HTTP)
# ✅ Use secure cookies (httpOnly, sameSite)
# ✅ Validate redirect URI matches registered URI
# ✅ Store tokens encrypted at rest
# ✅ Implement PKCE for extra security (if mobile apps)

# ❌ Never log or expose tokens
# ❌ Never store in plaintext
# ❌ Never share client secret
```

### Token Rotation

Implement automatic token refresh:

```bash
# Every 24 hours, refresh tokens
0 0 * * * curl https://solvetheproblem.ai/api/oauth/refresh-tokens
```

---

## Troubleshooting

### "Invalid Redirect URI"

Error: `redirect_uri_mismatch`

Fix:
1. Visit: https://platform.openai.com/apps
2. Check registered redirect URI
3. Ensure it matches `OPENAI_REDIRECT_URI` environment variable
4. Must use HTTPS (not HTTP)

### "Client ID/Secret Invalid"

```bash
# Verify they're set
echo $OPENAI_CLIENT_ID
echo $OPENAI_CLIENT_SECRET

# Check they match registered app values
# Regenerate at: https://platform.openai.com/apps
```

### "Token Expired"

Implement auto-refresh:

```javascript
// Middleware to check & refresh token
async function ensureValidToken(req, res, next) {
  let token = req.user.accessToken;
  
  if (isTokenExpired(token)) {
    token = await refreshAccessToken(req.user.refreshToken);
    req.user.accessToken = token;  // Update
  }
  
  next();
}

app.use(ensureValidToken);
```

---

## Deployment Checklist

- [ ] Register app at https://platform.openai.com/apps
- [ ] Get Client ID & Client Secret
- [ ] Set environment variables on droplet
- [ ] Configure OpenClaw for OAuth
- [ ] Configure OpenMOSS for OAuth
- [ ] Create OAuth callback handler
- [ ] Add login page to WebUI
- [ ] Setup token storage (Redis/DB/Encrypted)
- [ ] Test OAuth flow end-to-end
- [ ] Implement token refresh
- [ ] Deploy to production

---

## Next Steps

1. Register your app: https://platform.openai.com/apps
2. Get Client ID & Secret
3. SSH into droplet & follow Steps 2-9
4. Test OAuth login flow
5. Create first task using OAuth-authenticated agent

---

**Now your agents use OAuth — secure, user-controlled authentication!** 🔐
