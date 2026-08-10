import re

with open('REPO_CONTEXT.md', 'r') as f:
    content = f.read()

# Fix duplicates in REPO_CONTEXT.md that were accidentally created via diff overlap/poor replacement
import sys
# It's safer to just rewrite the file fully from git HEAD and apply the exact replacements again cleanly.
