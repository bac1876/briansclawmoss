#!/bin/bash
# Spawn 4 autonomous agents (Planner, Executor, Reviewer, Patrol)
# These agents will auto-register with OpenMOSS via OpenClaw

set -e

OPENMOSS_URL="http://127.0.0.1:6565"
REGISTRATION_TOKEN="openclaw-e231471b2f8ff88bdd4957c53431d38c"
GATEWAY_URL="http://127.0.0.1:8080"

echo "[INFO] Spawning autonomous agents..."

# Agent definitions
declare -a AGENTS=(
  "planner|Planner|Analyzes tasks and creates execution plans"
  "executor|Executor|Executes tasks and handles implementations"
  "reviewer|Reviewer|Reviews work and validates quality"
  "patrol|Patrol|Monitors system health and reports"
)

for agent_def in "${AGENTS[@]}"; do
  IFS='|' read -r role name description <<< "$agent_def"
  
  echo "[INFO] Spawning $name agent (role: $role)..."
  
  # Register agent via API
  curl -s -X POST "$OPENMOSS_URL/api/agents/register" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $REGISTRATION_TOKEN" \
    -d "{
      \"name\": \"$name\",
      \"role\": \"$role\",
      \"description\": \"$description\",
      \"gateway_url\": \"$GATEWAY_URL\"
    }" > /dev/null 2>&1
  
  echo "[✓] $name registered"
done

echo "[✓] All agents spawned and registered!"
echo ""
echo "Agent Registration Token: $REGISTRATION_TOKEN"
echo "OpenMOSS URL: $OPENMOSS_URL"
echo "Gateway URL: $GATEWAY_URL"
echo ""
echo "Next: Create a task in OpenMOSS dashboard to test agent execution!"
