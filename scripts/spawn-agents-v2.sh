#!/bin/bash
# Spawn 4 autonomous agents as actual OpenClaw processes
# These agents will run on persistent cron schedules and poll OpenMOSS for work

set -e

OPENMOSS_URL="http://127.0.0.1:6565"
GATEWAY_URL="http://127.0.0.1:8080"
WORKSPACE="/opt/openmoss-workspace"

echo "════════════════════════════════════════════════════════════"
echo "  BriansClaw + OpenMOSS — Agent Spawner v2"
echo "════════════════════════════════════════════════════════════"
echo ""

# Get agent API keys from database
echo "[INFO] Retrieving agent credentials from database..."

PLANNER_KEY=$(sqlite3 /opt/openmoss/data/tasks.db "SELECT api_key FROM agent WHERE role='planner';")
EXECUTOR_KEY=$(sqlite3 /opt/openmoss/data/tasks.db "SELECT api_key FROM agent WHERE role='executor';")
REVIEWER_KEY=$(sqlite3 /opt/openmoss/data/tasks.db "SELECT api_key FROM agent WHERE role='reviewer';")
PATROL_KEY=$(sqlite3 /opt/openmoss/data/tasks.db "SELECT api_key FROM agent WHERE role='patrol';")

if [ -z "$PLANNER_KEY" ]; then
  echo "[ERROR] Could not retrieve agent keys from database"
  exit 1
fi

echo "[✓] Agent credentials loaded"
echo ""

# Create agent configuration files
mkdir -p "$WORKSPACE/agents"

echo "[INFO] Creating agent configurations..."

# Planner Agent Config
cat > "$WORKSPACE/agents/planner-config.json" << 'EOF'
{
  "role": "planner",
  "name": "Planner",
  "description": "Analyzes tasks and creates execution plans",
  "api_key": "PLANNER_KEY_PLACEHOLDER",
  "gateway_url": "GATEWAY_URL_PLACEHOLDER",
  "openmoss_url": "OPENMOSS_URL_PLACEHOLDER",
  "poll_interval_seconds": 60,
  "cron_schedule": "*/5 * * * *"
}
EOF

# Executor Agent Config
cat > "$WORKSPACE/agents/executor-config.json" << 'EOF'
{
  "role": "executor",
  "name": "Executor",
  "description": "Executes tasks and handles implementations",
  "api_key": "EXECUTOR_KEY_PLACEHOLDER",
  "gateway_url": "GATEWAY_URL_PLACEHOLDER",
  "openmoss_url": "OPENMOSS_URL_PLACEHOLDER",
  "poll_interval_seconds": 60,
  "cron_schedule": "*/5 * * * *"
}
EOF

# Reviewer Agent Config
cat > "$WORKSPACE/agents/reviewer-config.json" << 'EOF'
{
  "role": "reviewer",
  "name": "Reviewer",
  "description": "Reviews work and validates quality",
  "api_key": "REVIEWER_KEY_PLACEHOLDER",
  "gateway_url": "GATEWAY_URL_PLACEHOLDER",
  "openmoss_url": "OPENMOSS_URL_PLACEHOLDER",
  "poll_interval_seconds": 60,
  "cron_schedule": "*/5 * * * *"
}
EOF

# Patrol Agent Config
cat > "$WORKSPACE/agents/patrol-config.json" << 'EOF'
{
  "role": "patrol",
  "name": "Patrol",
  "description": "Monitors system health and reports",
  "api_key": "PATROL_KEY_PLACEHOLDER",
  "gateway_url": "GATEWAY_URL_PLACEHOLDER",
  "openmoss_url": "OPENMOSS_URL_PLACEHOLDER",
  "poll_interval_seconds": 60,
  "cron_schedule": "*/5 * * * *"
}
EOF

# Replace placeholders
sed -i "s|PLANNER_KEY_PLACEHOLDER|$PLANNER_KEY|g" "$WORKSPACE/agents/planner-config.json"
sed -i "s|EXECUTOR_KEY_PLACEHOLDER|$EXECUTOR_KEY|g" "$WORKSPACE/agents/executor-config.json"
sed -i "s|REVIEWER_KEY_PLACEHOLDER|$REVIEWER_KEY|g" "$WORKSPACE/agents/reviewer-config.json"
sed -i "s|PATROL_KEY_PLACEHOLDER|$PATROL_KEY|g" "$WORKSPACE/agents/patrol-config.json"

sed -i "s|GATEWAY_URL_PLACEHOLDER|$GATEWAY_URL|g" "$WORKSPACE/agents/"*.json
sed -i "s|OPENMOSS_URL_PLACEHOLDER|$OPENMOSS_URL|g" "$WORKSPACE/agents/"*.json

echo "[✓] Agent configurations created in $WORKSPACE/agents/"
echo ""

# Create agent startup scripts using OpenClaw CLI
echo "[INFO] Creating agent startup scripts..."

cat > "$WORKSPACE/agents/start-planner.sh" << 'EOF'
#!/bin/bash
# Planner Agent — Analyzes tasks and creates execution plans
CONFIG=$(cat /opt/openmoss-workspace/agents/planner-config.json)
ROLE=$(echo $CONFIG | jq -r .role)
NAME=$(echo $CONFIG | jq -r .name)
API_KEY=$(echo $CONFIG | jq -r .api_key)
OPENMOSS_URL=$(echo $CONFIG | jq -r .openmoss_url)

openclaw agent \
  --name "$NAME" \
  --role "$ROLE" \
  --api-key "$API_KEY" \
  --openmoss-url "$OPENMOSS_URL" \
  --task "You are the Planner agent. Your job is to: 
  1. Poll OpenMOSS for new tasks in 'planning' status
  2. Break down each task into modules and subtasks
  3. Assign subtasks to appropriate agents
  4. Track progress until all subtasks are complete
  Use the provided API to interact with OpenMOSS. Work continuously."
EOF

cat > "$WORKSPACE/agents/start-executor.sh" << 'EOF'
#!/bin/bash
# Executor Agent — Executes tasks and implementations
CONFIG=$(cat /opt/openmoss-workspace/agents/executor-config.json)
ROLE=$(echo $CONFIG | jq -r .role)
NAME=$(echo $CONFIG | jq -r .name)
API_KEY=$(echo $CONFIG | jq -r .api_key)
OPENMOSS_URL=$(echo $CONFIG | jq -r .openmoss_url)

openclaw agent \
  --name "$NAME" \
  --role "$ROLE" \
  --api-key "$API_KEY" \
  --openmoss-url "$OPENMOSS_URL" \
  --task "You are the Executor agent. Your job is to:
  1. Poll OpenMOSS for subtasks assigned to you
  2. Execute each subtask with high quality
  3. Submit completed work for review
  4. Handle feedback and rework if needed
  Use the provided API to interact with OpenMOSS. Work continuously."
EOF

cat > "$WORKSPACE/agents/start-reviewer.sh" << 'EOF'
#!/bin/bash
# Reviewer Agent — Reviews and validates work
CONFIG=$(cat /opt/openmoss-workspace/agents/reviewer-config.json)
ROLE=$(echo $CONFIG | jq -r .role)
NAME=$(echo $CONFIG | jq -r .name)
API_KEY=$(echo $CONFIG | jq -r .api_key)
OPENMOSS_URL=$(echo $CONFIG | jq -r .openmoss_url)

openclaw agent \
  --name "$NAME" \
  --role "$ROLE" \
  --api-key "$API_KEY" \
  --openmoss-url "$OPENMOSS_URL" \
  --task "You are the Reviewer agent. Your job is to:
  1. Poll OpenMOSS for subtasks in 'review' status
  2. Evaluate work quality against requirements
  3. Provide constructive feedback
  4. Approve work or request rework with specific guidance
  Use the provided API to interact with OpenMOSS. Work continuously."
EOF

cat > "$WORKSPACE/agents/start-patrol.sh" << 'EOF'
#!/bin/bash
# Patrol Agent — Monitors system health
CONFIG=$(cat /opt/openmoss-workspace/agents/patrol-config.json)
ROLE=$(echo $CONFIG | jq -r .role)
NAME=$(echo $CONFIG | jq -r .name)
API_KEY=$(echo $CONFIG | jq -r .api_key)
OPENMOSS_URL=$(echo $CONFIG | jq -r .openmoss_url)

openclaw agent \
  --name "$NAME" \
  --role "$ROLE" \
  --api-key "$API_KEY" \
  --openmoss-url "$OPENMOSS_URL" \
  --task "You are the Patrol agent. Your job is to:
  1. Periodically check system status via OpenMOSS API
  2. Identify stuck or blocked tasks
  3. Monitor agent health and performance
  4. Alert about anomalies
  5. Trigger recovery procedures when needed
  Use the provided API to interact with OpenMOSS. Work continuously."
EOF

chmod +x "$WORKSPACE/agents/start-*.sh"
echo "[✓] Agent startup scripts created"
echo ""

# Create systemd service files
echo "[INFO] Creating systemd service units..."

cat > /etc/systemd/system/openmoss-agent-planner.service << EOF
[Unit]
Description=OpenMOSS Planner Agent
After=openmoss.service openclaw.service
Wants=openmoss.service openclaw.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openmoss-workspace
ExecStart=/bin/bash $WORKSPACE/agents/start-planner.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/openmoss-agent-executor.service << EOF
[Unit]
Description=OpenMOSS Executor Agent
After=openmoss.service openclaw.service
Wants=openmoss.service openclaw.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openmoss-workspace
ExecStart=/bin/bash $WORKSPACE/agents/start-executor.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/openmoss-agent-reviewer.service << EOF
[Unit]
Description=OpenMOSS Reviewer Agent
After=openmoss.service openclaw.service
Wants=openmoss.service openclaw.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openmoss-workspace
ExecStart=/bin/bash $WORKSPACE/agents/start-reviewer.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/openmoss-agent-patrol.service << EOF
[Unit]
Description=OpenMOSS Patrol Agent
After=openmoss.service openclaw.service
Wants=openmoss.service openclaw.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/openmoss-workspace
ExecStart=/bin/bash $WORKSPACE/agents/start-patrol.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "[✓] Systemd service units created"
echo ""

# Reload systemd and start agents
echo "[INFO] Starting agent services..."

systemctl daemon-reload

systemctl enable openmoss-agent-planner.service
systemctl enable openmoss-agent-executor.service
systemctl enable openmoss-agent-reviewer.service
systemctl enable openmoss-agent-patrol.service

systemctl start openmoss-agent-planner.service
systemctl start openmoss-agent-executor.service
systemctl start openmoss-agent-reviewer.service
systemctl start openmoss-agent-patrol.service

sleep 2

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ All 4 agents are now ACTIVE!"
echo "════════════════════════════════════════════════════════════"
echo ""

# Show status
echo "[INFO] Agent Service Status:"
systemctl status openmoss-agent-planner.service --no-pager 2>/dev/null | grep "Active:"
systemctl status openmoss-agent-executor.service --no-pager 2>/dev/null | grep "Active:"
systemctl status openmoss-agent-reviewer.service --no-pager 2>/dev/null | grep "Active:"
systemctl status openmoss-agent-patrol.service --no-pager 2>/dev/null | grep "Active:"

echo ""
echo "[INFO] Agent Configuration:"
echo "  Planner:  $PLANNER_KEY"
echo "  Executor: $EXECUTOR_KEY"
echo "  Reviewer: $REVIEWER_KEY"
echo "  Patrol:   $PATROL_KEY"
echo ""
echo "[INFO] View logs:"
echo "  sudo journalctl -u openmoss-agent-planner -f"
echo "  sudo journalctl -u openmoss-agent-executor -f"
echo "  sudo journalctl -u openmoss-agent-reviewer -f"
echo "  sudo journalctl -u openmoss-agent-patrol -f"
echo ""
echo "[INFO] View all agent logs:"
echo "  sudo journalctl -u 'openmoss-agent-*' -f"
echo ""
echo "🚀 Your autonomous AI team is now RUNNING!"
echo "   Go to https://solvetheproblem.ai and watch your agents work!"
echo ""
