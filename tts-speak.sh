#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Kill previous TTS immediately (both the playback loop and afplay)
if [ -f /tmp/tts-loop.pid ]; then
    kill -- -$(cat /tmp/tts-loop.pid) 2>/dev/null || kill $(cat /tmp/tts-loop.pid) 2>/dev/null
    rm -f /tmp/tts-loop.pid
fi
killall afplay 2>/dev/null

# Read text
if [ -n "$1" ]; then
    text="$*"
else
    text=$(cat)
fi

# Strip markdown
text=$(echo "$text" | python3 "$SCRIPT_DIR/tts-strip-markdown.py")
text=$(echo "$text" | tr '\n' ' ')
[ -z "$(echo "$text" | tr -d '[:space:]')" ] && exit 0

# Detect language
lang=$(python3 -c "
import sys
text = sys.argv[1]
cjk = sum(1 for c in text if '\u4e00' <= c <= '\u9fff' or '\u3400' <= c <= '\u4dbf')
print('zh' if cjk / max(len(text), 1) > 0.15 else 'en')
" "$text")

# Speak using edge-tts (Microsoft Neural voices)
if [ "$lang" = "zh" ]; then
    voice="zh-CN-shaanxi-XiaoniNeural"
else
    voice="en-US-AvaMultilingualNeural"
fi

# Split into chunks on sentence boundaries, generate and play each chunk
# First chunk starts playing while the rest are still being generated
python3 -c "
import re, sys
text = sys.argv[1]
parts = re.split(r'(?<=[.!?。！？])\s*', text)
chunks, buf = [], ''
for p in parts:
    if not p.strip():
        continue
    if buf and len(buf) + len(p) + 1 > 200:
        chunks.append(buf)
        buf = p
    else:
        buf = (buf + ' ' + p).strip() if buf else p
if buf:
    chunks.append(buf)
for c in chunks:
    print(c)
" "$text" > /tmp/tts-chunks.txt

(echo $BASHPID > /tmp/tts-loop.pid
i=0; while IFS= read -r chunk; do
    [ -z "$chunk" ] && continue
    outfile="/tmp/tts-chunk-${i}.mp3"
    edge-tts --voice "$voice" --rate="+25%" --text "$chunk" --write-media "$outfile" 2>/dev/null
    afplay "$outfile" &
    AFPLAY_PID=$!
    # Launch mic monitor for this chunk — kills afplay+loop when mic activates
    if [ -x "$SCRIPT_DIR/tts-mic-stop" ]; then
        "$SCRIPT_DIR/tts-mic-stop" &
    fi
    wait $AFPLAY_PID
    rm -f "$outfile"
    i=$((i + 1))
done < /tmp/tts-chunks.txt
rm -f /tmp/tts-chunks.txt /tmp/tts-loop.pid) &
