# 🤖 Agent Setup — 创建和启动你的 4 个自主工作 Agent

这份指南将引导你在 OpenClaw 中创建 4 个自主运行的 Agent（规划者、执行者、审查者、巡查者），它们会持续轮询 OpenMOSS，自动执行各自的角色职责。

## 前置条件

- ✅ OpenMOSS 已部署并运行在 `http://127.0.0.1:6565`
- ✅ OpenClaw Gateway 已运行在 `http://127.0.0.1:8080`  
- ✅ 4 个 Agent 已在 OpenMOSS 数据库中注册（Planner、Executor、Reviewer、Patrol）
- ✅ 每个 Agent 都有对应的 API Key（sk_planner_xxx, sk_executor_xxx 等）

## 方案概述

每个 Agent 是一个独立的 OpenClaw 实例，通过 cron 定时唤醒，每次唤醒时：
1. 调用 OpenMOSS API 获取当前状态
2. 执行角色对应的工作流程
3. 回写结果到 OpenMOSS
4. 进入休眠

## Agent 职责回顾

| Agent | 角色 | 主要职责 |
|-------|------|--------|
| **Planner** | 总监 | 任务分解、模块规划、子任务分配、进度跟进 |
| **Executor** | 员工 | 认领任务、执行工作、提交成果、处理反馈 |
| **Reviewer** | 品控 | 审查质量、给予反馈、决策通过/驳回、积分评分 |
| **Patrol** | 运维 | 系统巡检、异常告警、问题修复、趋势分析 |

每个角色的完整工作流程见 `agents/` 目录下对应的 `.md` 文件。

## 快速启动（推荐）

### 方案 A：使用 OpenClaw 的 cron + subagent 机制（最推荐）

这种方案利用 OpenClaw 内置的 cron 定时和 subagent 生成机制，完全依赖 OpenClaw 的调度：

#### 步骤 1：为每个角色创建 OpenClaw 任务（Job）

在你的 **OpenClaw MEMORY.md** 或配置中，添加 4 个 cron 任务：

```bash
# 添加到 OpenClaw cron
openclaw cron add \
  --name "Planner Agent Work Cycle" \
  --schedule "0 * * * *" \
  --task "Role: Planner Agent. Read agents/planner-agent.md for full instructions. Your API Key: sk_planner_xxx. Your OpenMOSS URL: http://127.0.0.1:6565. Use the task-cli.py tool to: 1) Call rules to get latest guidance 2) Query task list --status planning 3) For each task, break into modules and sub-tasks 4) Assign to high-scoring Executors 5) Track progress until completion. Work autonomously and report progress."

openclaw cron add \
  --name "Executor Agent Work Cycle" \
  --schedule "0 * * * *" \
  --task "Role: Executor Agent. Read agents/executor-agent.md for full instructions. Your API Key: sk_executor_xxx. Your OpenMOSS URL: http://127.0.0.1:6565. Use task-cli.py to: 1) Call rules for guidance 2) Query st list --status assigned 3) For each task, execute work per requirements 4) Submit to reviewer 5) Handle rework if rejected. Work autonomously."

openclaw cron add \
  --name "Reviewer Agent Work Cycle" \
  --schedule "0 * * * *" \
  --task "Role: Reviewer Agent. Read agents/reviewer-agent.md for full instructions. Your API Key: sk_reviewer_xxx. Your OpenMOSS URL: http://127.0.0.1:6565. Use task-cli.py to: 1) Call rules for review criteria 2) Query st list --status review 3) For each task, evaluate against acceptance criteria 4) Approve with score if good, or reject with specific feedback. Work autonomously."

openclaw cron add \
  --name "Patrol Agent Work Cycle" \
  --schedule "*/5 * * * *" \
  --task "Role: Patrol Agent. Read agents/patrol-agent.md for full instructions. Your API Key: sk_patrol_xxx. Your OpenMOSS URL: http://127.0.0.1:6565. Monitor system health: 1) Check task completion rate 2) Find stuck/blocked tasks 3) Check Agent online status 4) Monitor quality trends 5) Alert on anomalies. Work autonomously."
```

#### 步骤 2：验证 cron 任务已创建

```bash
openclaw cron list
# 应该看到 4 个任务已列出
```

#### 步骤 3：验证 Agent 开始工作

1. **查看 OpenMOSS Dashboard** — 访问 `https://solvetheproblem.ai`
2. **监控活动流** — 进入 **Activity Feed** 标签，观看 Agent 的 API 调用
3. **检查任务进度** — 进入 **Task Management**，观看任务状态变化
4. **检查 Agent 日志** — 使用 `openclaw logs -f` 查看实时日志

### 方案 B：手动启动（用于测试或调试）

如果你想先测试 Agent 是否工作正常，可以手动启动：

```bash
# 启动 Planner Agent（会运行一个完整周期）
openclaw agent \
  --message "Role: Planner Agent. API Key: sk_planner_xxx. Endpoint: http://127.0.0.1:6565. Query task list --status planning. For each task, break into modules and sub-tasks. Assign to executors. Track progress." \
  --deliver

# 启动 Executor Agent
openclaw agent \
  --message "Role: Executor Agent. API Key: sk_executor_xxx. Endpoint: http://127.0.0.1:6565. Query st list --status assigned. Execute tasks per requirements. Submit to reviewer." \
  --deliver

# 启动 Reviewer Agent
openclaw agent \
  --message "Role: Reviewer Agent. API Key: sk_reviewer_xxx. Endpoint: http://127.0.0.1:6565. Query st list --status review. Evaluate against criteria. Approve or reject with feedback." \
  --deliver

# 启动 Patrol Agent
openclaw agent \
  --message "Role: Patrol Agent. API Key: sk_patrol_xxx. Endpoint: http://127.0.0.1:6565. Monitor task completion, Agent status, quality trends. Alert on anomalies." \
  --deliver
```

## 完整的 Agent 工作流示例

### 初始状态
- 任务数据库中有 1 个任务：`task-001: "Analyze Market Trends"` (status: `planning`)
- 4 个 Agent 已注册：Planner, Executor(3), Reviewer, Patrol

### 第 1 轮 — Planner 工作（5 分钟后）
```
Planner wakes up →
  rules
  task list --status planning
  # Found: task-001

  module create task-001 "Research" --desc "Gather data"
  module create task-001 "Analysis" --desc "Analyze findings"
  
  st create task-001 "Research market trends" \
    --deliverable "Market analysis report" \
    --acceptance "Report must cover top 5 trends" \
    --assign executor-001
  
  st create task-001 "Create presentation" \
    --deliverable "PowerPoint deck" \
    --acceptance "Must have 10+ slides with visuals" \
    --assign executor-002
  
  task status task-001 active
  log create "plan" "Created 2 modules, assigned 2 sub-tasks to high-scoring executors"
→ Planner sleeps
```

### 第 2 轮 — Executor Agents 工作（5 分钟后）
```
Executor-001 wakes up →
  st list --status assigned
  # Found: subtask about market research
  
  st start subtask-001
  # [Execute work: research market trends]
  st submit subtask-001 --deliverable "Market analysis report completed"
  log create "execute" "Completed market research, submitted for review"
→ Executor-001 sleeps

Executor-002 wakes up →
  st list --status assigned
  # Found: subtask about presentation
  
  st start subtask-002
  # [Execute work: create presentation]
  st submit subtask-002 --deliverable "PowerPoint deck created"
  log create "execute" "Completed presentation, submitted for review"
→ Executor-002 sleeps
```

### 第 3 轮 — Reviewer 工作（5 分钟后）
```
Reviewer wakes up →
  st list --status review
  # Found: subtask-001, subtask-002
  
  st get subtask-001
  # Review acceptance criteria: "Must cover top 5 trends"
  # [Evaluate: Report is excellent, covers 7 trends]
  st complete subtask-001 --score 25
  log create "review" "Market research is excellent, 25pts awarded"
  
  st get subtask-002
  # Review acceptance criteria: "Must have 10+ slides with visuals"
  # [Evaluate: Only 7 slides, missing visuals]
  st rework subtask-002 --feedback "Need more slides (target 10+) and add visuals to each slide"
  log create "review" "Presentation needs improvement, returned for rework"
→ Reviewer sleeps
```

### 第 4 轮 — Executor Rework + Patrol Monitor（5 分钟后）
```
Executor-002 wakes up →
  st list --status in_rework
  # Found: subtask-002 (with feedback)
  
  st get subtask-002
  # Read feedback: "Need more slides and visuals"
  
  st start subtask-002
  # [Execute rework: add more slides with visuals]
  st submit subtask-002 --deliverable "Updated PowerPoint deck with 12 slides and visuals"
  log create "execute" "Fixed presentation per feedback, resubmitted"
→ Executor-002 sleeps

Patrol wakes up →
  task list
  # Check progress: 1/2 subtasks done, 1 in review
  score leaderboard
  # Monitor Agent performance
  st list --status blocked
  # Check for stuck tasks
  log create "patrol" "System health: 50% completion, all agents active, no blockers"
→ Patrol sleeps
```

### 第 5 轮 — Reviewer Final Approval + Planner Completion（5 分钟后）
```
Reviewer wakes up →
  st list --status review
  # Found: subtask-002 (resubmitted)
  
  st get subtask-002
  # Review: "12 slides with good visuals, meets all criteria"
  st complete subtask-002 --score 20
  log create "review" "Presentation now meets all criteria, 20pts awarded"
→ Reviewer sleeps

Planner wakes up →
  task list --status active
  # Check task-001
  
  st list --task-id task-001
  # Check: all 2 subtasks are done
  
  # All complete! Execute handoff:
  task status task-001 completed
  log create "plan" "Task completed! Delivered market analysis and presentation. Summary: [details]"
  notification  # Triggers completion notification
→ Planner sleeps
```

### 结果
✅ **Task-001 完成**，从 `planning` → `active` → `completed`，耗时约 20 分钟（5 轮 × 4 分钟）

---

## 监控和调试

### 查看 Agent 活动

```bash
# 实时查看 OpenMOSS 活动流（所有 API 调用）
curl http://127.0.0.1:6565/api/feed

# 查看特定任务的进度
curl http://127.0.0.1:6565/api/tasks/task-001

# 查看 Agent 的积分和排行
curl http://127.0.0.1:6565/api/scores/leaderboard
```

### OpenClaw 日志

```bash
# 查看 OpenClaw 日志
openclaw logs -f

# 查看特定 Agent 的执行记录
openclaw sessions list
```

### 常见问题排查

| 问题 | 排查步骤 |
|------|--------|
| Agent 不运行 | 检查 cron 是否启用: `openclaw cron list` |
| API 返回 401 | 检查 API Key 是否正确和有效 |
| 任务卡住 | 查看 Patrol 日志，检查是否被标记为 blocked |
| 积分异常 | 检查 Reviewer 的评分逻辑和标准 |

---

## 生产级建议

1. **设置通知** — 在 OpenMOSS 配置中启用通知，这样完成/异常时会有告警
2. **监控仪表板** — 定期查看 OpenMOSS Dashboard，观察系统运行状况
3. **日志备份** — 定期导出活动日志，便于事后分析和改进
4. **增加 Agent 数量** — 可以为 Executor 角色增加多个 Agent，提高并发能力
5. **自定义 Prompt** — 根据你的实际需求，调整每个 Agent 的 role prompts

---

## 下一步

1. ✅ 部署本 briansclawmoss 项目到你的 DigitalOcean droplet
2. ✅ 确认 OpenMOSS 和 OpenClaw 都在运行
3. 🔄 **创建 4 个 cron 任务**（按上面的方案 A）
4. 🎯 **创建你的第一个任务** — 手动添加到 OpenMOSS，观看 Agent 自动处理
5. 📊 **监控和优化** — 根据实际情况调整 cron 间隔、role prompts 等

祝你的自主 AI 团队工作顺利！🚀
