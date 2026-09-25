# Tech Interview Revision — AI Agent Skill

An AI agent skill that generates **concise, interview-focused Markdown revision notes** for any technology topic. Hand it a topic, get back a structured set of files you can revise start-to-finish before walking into an interview.

---

## What It Does

When you ask your AI agent to create revision notes for a topic (e.g. *"revise Azure for interview"*, *"prep me for Python"*), this skill instructs the agent to:

1. **Plan** the right number of files (up to 8 topic files + 1 interview questions file)
2. **Write** each file in a question-driven format — the same way an interviewer would ask
3. **Finish** with `99_interview_questions.md` — a rapid-fire revision sheet for last-minute prep

### Output Structure

```
01_<topic>_fundamentals.md
02_<core_concepts>.md
...
08_<advanced>.md
99_interview_questions.md       ← most important file
```

### What Makes the Notes Good

- **Question → Answer → Key Points → Example → Tip** format
- Priority markers: ⭐ MUST KNOW · 🟠 IMPORTANT · 🎯 SCENARIO · ⚠️ INTERVIEW TRAP
- Comparison tables, ASCII diagrams, real commands/code
- Scenario-based questions (debugging, design, production)
- Concise answers you can actually *say* in an interview

### Topics It Handles

Anything technical — programming languages, frameworks, DSA, system design, databases, cloud (AWS/Azure/GCP), DevOps, Docker, Kubernetes, Terraform, AI/ML, LLMs, security, networking, data engineering, and more.

---

## Setup by Agent

### Google Antigravity (AGY)

Place the skill file at one of these locations:

```
# Workspace-level (recommended — per project)
<your-repo>/.agents/skills/tech-interview-revision/skill.md

# Global (applies to all projects)
~/.gemini/antigravity/skills/tech-interview-revision/SKILL.md
```

AGY auto-discovers skills from `.agents/skills/` — no extra config needed.

### Claude Code (Anthropic)

Add as a slash command or project instruction:

```
# Option 1: Project instructions
<your-repo>/.claude/commands/tech-interview-revision.md
# Copy the contents of skill.md into this file

# Option 2: CLAUDE.md reference
# Add to your .claude/CLAUDE.md:
When the user asks for interview revision notes, follow the instructions in .agents/skills/tech-interview-revision/skill.md
```

### OpenAI Codex / ChatGPT

```
# Option 1: Paste skill.md content into Custom Instructions or System Prompt

# Option 2: Reference in project setup
# Add to your .codex/instructions.md or AGENTS.md:
For interview revision requests, follow the skill at .agents/skills/tech-interview-revision/skill.md
```

### Cursor / Windsurf / Other AI IDEs

```
# Cursor — add to project rules
<your-repo>/.cursor/rules/tech-interview-revision.md

# Windsurf — add to project rules  
<your-repo>/.windsurfrules

# Generic — most AI IDEs support a rules/instructions file
# Copy skill.md content into your IDE's instruction mechanism
```

### Any Agent (Generic)

If your agent supports custom instructions or system prompts, either:
- Point it to `skill.md` in your repo
- Paste the skill content directly into the system prompt

The skill is **self-contained** — it's a single Markdown file with all the instructions the agent needs.

---

## Usage

Just ask naturally. The skill activates on requests like:

```
"Create interview revision notes for Kubernetes"
"I need to revise Docker for an interview"
"Prep me for a Python backend interview"
"Quick revision notes on system design"
"Notes on Terraform for interview"
```

You can also specify:
- **Output directory** — *"save notes in ./Docker/"*
- **Role/level** — *"for a senior SRE role"*
- **Scope** — *"focus on networking only, skip storage"*

---

## Reading the Notes ⭐ 

The generated `.md` files use GitHub-flavored Markdown with tables, callouts, code blocks, and ASCII diagrams. For the best reading experience in **VS Code**:

1. Install the **Markdown Preview Enhanced** extension by **Yiyi Wang**
2. Open any `.md` file and press `Ctrl + Shift + V` to get a rendered preview

---

## File Reference

```
tech-interview-revision/
├── skill.md          ← the skill instructions (this is what the agent reads)
└── README.md         ← you are here
```

---

## License

Open for personal and team use. Modify the skill to fit your workflow.
