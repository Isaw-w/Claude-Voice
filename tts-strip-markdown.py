#!/usr/bin/env python3
"""Strip markdown formatting from text for TTS readability."""
import re
import sys

t = sys.stdin.read()

# Remove fenced code blocks (multiline) — drop entirely, code isn't speakable
t = re.sub(r'```[\s\S]*?```', '', t)

# Inline code: keep the content, strip the backticks
t = re.sub(r'`([^`]+)`', r'\1', t)

# Remove markdown links, keep link text: [text](url) -> text
t = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', t)

# Remove bare URLs
t = re.sub(r'https?://\S+', '', t)

# Remove headers (# ## ### etc)
t = re.sub(r'^#{1,6}\s*', '', t, flags=re.MULTILINE)

# Remove bold/italic markers
t = re.sub(r'\*{1,3}', '', t)
t = re.sub(r'_{1,3}', ' ', t)

# Remove horizontal rules
t = re.sub(r'^[-*_]{3,}\s*$', '', t, flags=re.MULTILINE)

# Remove bullet points and numbered lists markers
t = re.sub(r'^\s*[-*+]\s+', '', t, flags=re.MULTILINE)
t = re.sub(r'^\s*\d+\.\s+', '', t, flags=re.MULTILINE)

# Remove blockquotes
t = re.sub(r'^>\s*', '', t, flags=re.MULTILINE)

# Remove HTML tags
t = re.sub(r'<[^>]+>', '', t)

# Remove pipe table formatting
t = re.sub(r'^\|.*\|\s*$', '', t, flags=re.MULTILINE)

# Remove file paths that look like code references
t = re.sub(r'\S+/\S+\.\w{1,5}(:\d+)?', '', t)

# Replace symbols that Apple natural voice can't speak
t = t.replace('`', '')       # stray backticks
t = t.replace('"', '"').replace('"', '"')  # smart quotes to plain
t = t.replace(''', "'").replace(''', "'")
t = t.replace('—', ', ').replace('–', ', ')  # em/en dash to pause

# Collapse multiple newlines/spaces
t = re.sub(r'\n{2,}', '. ', t)
t = re.sub(r'\s{2,}', ' ', t)

print(t.strip()[:2000])
