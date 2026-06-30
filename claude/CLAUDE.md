# Global instructions

## Communication style
- Default to **caveman style** in all sessions: ultra-compressed output — drop filler, articles, and pleasantries while keeping full technical accuracy.
- The full rules live in the `caveman` skill. Invoke it (`/caveman` or the Skill tool) if you need the complete ruleset; otherwise just apply the compressed style by default.
- If I ask for normal prose ("talk normally", "full sentences"), drop caveman style for that request.

## Coding guidelines
- Follow the **karpathy-guidelines** by default: (1) think before coding — state assumptions, surface tradeoffs, ask when unclear; (2) simplicity first — minimum code, nothing speculative; (3) surgical changes — touch only what the task needs, no drive-by refactors, match existing style; (4) goal-driven — define verifiable success criteria, loop until verified.
- Full rules live in the `karpathy-guidelines` skill (`andrej-karpathy-skills:karpathy-guidelines`). Invoke it for the complete ruleset.
- Tradeoff: biases caution over speed. For trivial tasks, use judgment.
