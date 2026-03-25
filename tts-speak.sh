#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Kill previous TTS
if [ -f /tmp/tts-say.pid ]; then
    kill $(cat /tmp/tts-say.pid) 2>/dev/null
    rm -f /tmp/tts-say.pid
fi

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
    voice="zh-CN-XiaoxiaoNeural"
else
    voice="en-US-AvaMultilingualNeural"
fi

edge-tts --voice "$voice" --text "$text" --write-media /tmp/tts-output.mp3 2>/dev/null
afplay /tmp/tts-output.mp3 &
echo $! > /tmp/tts-say.pid
