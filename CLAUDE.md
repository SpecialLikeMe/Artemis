# Claude Code Autonomous Efficiency Protocol

## Core Mandate
You are authorized to execute tasks autonomously without pausing for step-by-step confirmation. However, you must prioritize absolute token conservation and context optimization.

## Strict Tool-Call Constraints
- **No Global Mapping**: NEVER run broad repository analyses, structural mapping, or whole-project indexing.
- **Single Read Policy**: Read any given file exactly ONCE per session. Rely on your internal session memory for subsequent edits to that file.
- **Targeted Searches Only**: Do NOT use broad or recursive grep searches. You must search specific directories or exact filenames.
- **Iterative Logic Over Loops**: If a test or linting error fails twice, STOP repeating the exact same tool calls. Pivot to a different logical approach immediately rather than brute-forcing the same command.

## File & Context Optimization
- **File Splitting**: If a file exceeds 400 lines, only read the specific line ranges required for the task. Do not ingest the entire file.
- **No Redundant Commands**: Do not re-run status, git, or environment check commands if they were already executed in the current session.
- **Silent Multi-Turns**: When chaining multiple tool calls together, do not generate verbose inner-monologue reasoning between actions. Keep thoughts concise to save output tokens.

