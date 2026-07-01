---
name: runnable-python
description: Use whenever you would otherwise hand the user a multi-line `python -c "..."` snippet to copy and run in their terminal, including over SSH. Multi-line python -c is fragile under copy-paste because terminal selection and clipboard handling mangle indentation, causing IndentationError. Triggers: any time you are about to output a bash code block containing `python -c` with a body longer than one line.
---

# Runnable Python snippets

When you would write a multi-line `python -c "..."` for the user to run, do this instead:

1. Write the script to a temp file using a **single-quoted** heredoc (prevents shell expansion, preserves indentation exactly):

```bash
   cat > /tmp/snippet.py <<'PYEOF'
   import ray
   # ... full script here, normal indentation ...
   PYEOF
   python /tmp/snippet.py
```

2. Single-line `python -c '...'` is still fine. The rule only applies when the body has 2+ statements or any indented block.

3. If the target is a remote host, write locally then `scp` over, or pipe the heredoc through `ssh host 'cat > /tmp/snippet.py && python /tmp/snippet.py'`.

Never emit a `python -c` block whose body contains a function definition, a class, or a `for`/`if` with an indented body. That is the failure mode.
