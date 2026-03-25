#!/usr/bin/env python3
"""All-in-one TTS preparation: strip markdown, detect language, chunk text.

Reads text from stdin. Outputs to stdout:
  Line 1: voice name (e.g. zh-CN-shaanxi-XiaoniNeural)
  Line 2+: one chunk per line, ready for edge-tts

First chunk is kept small (~100 chars) for faster initial playback.
"""
import re
import sys

# ── 1. Read ──────────────────────────────────────────────────────────────
t = sys.stdin.read()
if not t.strip():
    sys.exit(0)

# ── 2. Strip markdown ────────────────────────────────────────────────────
t = re.sub(r'```[\s\S]*?```', '', t)
t = re.sub(r'`([^`]+)`', r'\1', t)
t = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', t)
t = re.sub(r'https?://\S+', '', t)
t = re.sub(r'^#{1,6}\s*', '', t, flags=re.MULTILINE)
t = re.sub(r'\*{1,3}', '', t)
t = re.sub(r'_{1,3}', ' ', t)
t = re.sub(r'^[-*_]{3,}\s*$', '', t, flags=re.MULTILINE)
t = re.sub(r'^\s*[-*+]\s+', '', t, flags=re.MULTILINE)
t = re.sub(r'^\s*\d+\.\s+', '', t, flags=re.MULTILINE)
t = re.sub(r'^>\s*', '', t, flags=re.MULTILINE)
t = re.sub(r'<[^>]+>', '', t)
t = re.sub(r'^\|.*\|\s*$', '', t, flags=re.MULTILINE)
t = re.sub(r'\S+/\S+\.\w{1,5}(:\d+)?', '', t)
t = t.replace('`', '')
t = t.replace('\u201c', '"').replace('\u201d', '"')
t = t.replace('\u2018', "'").replace('\u2019', "'")
t = t.replace('\u2014', ', ').replace('\u2013', ', ')
t = re.sub(r'\n{2,}', '. ', t)
t = re.sub(r'\s{2,}', ' ', t)
t = t.strip()[:2000]
t = re.sub(r'\n', ' ', t)

if not t.strip():
    sys.exit(0)

# ── 3. Detect language ───────────────────────────────────────────────────
cjk = sum(1 for c in t if '\u4e00' <= c <= '\u9fff' or '\u3400' <= c <= '\u4dbf')
is_zh = cjk / max(len(t), 1) > 0.15
voice = 'zh-CN-shaanxi-XiaoniNeural' if is_zh else 'en-US-AvaMultilingualNeural'

# ── 4. Chunk on sentence boundaries ──────────────────────────────────────
# First chunk is smaller (~100 chars) so playback starts faster
FIRST_CHUNK_MAX = 100
CHUNK_MAX = 200

parts = re.split(r'(?<=[.!?。！？])\s*', t)
chunks = []
buf = ''
for p in parts:
    if not p.strip():
        continue
    limit = FIRST_CHUNK_MAX if not chunks else CHUNK_MAX
    if buf and len(buf) + len(p) + 1 > limit:
        chunks.append(buf)
        buf = p
    else:
        buf = (buf + ' ' + p).strip() if buf else p
if buf:
    chunks.append(buf)

# ── 5. Output: voice on line 1, then chunks ──────────────────────────────
print(voice)
for c in chunks:
    print(c)
