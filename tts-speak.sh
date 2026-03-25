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

[ -z "$(echo "$text" | tr -d '[:space:]')" ] && exit 0

# Single Python call: strip markdown + detect language + chunk text
# Line 1 = voice name, line 2+ = chunks
prepared=$(echo "$text" | python3 "$SCRIPT_DIR/tts-prepare.py")
[ -z "$prepared" ] && exit 0

voice=$(echo "$prepared" | head -1)
echo "$prepared" | tail -n +2 > /tmp/tts-chunks.txt

(echo $BASHPID > /tmp/tts-loop.pid
rm -f /tmp/tts-stop
i=0; while IFS= read -r chunk; do
    [ -f /tmp/tts-stop ] && break
    [ -z "$chunk" ] && continue
    outfile="/tmp/tts-chunk-${i}.mp3"
    edge-tts --voice "$voice" --rate="+25%" --text "$chunk" --write-media "$outfile" 2>/dev/null
    [ -f /tmp/tts-stop ] && rm -f "$outfile" && break
    afplay "$outfile" &
    AFPLAY_PID=$!
    if [ -x "$SCRIPT_DIR/tts-mic-stop" ]; then
        "$SCRIPT_DIR/tts-mic-stop" &
    fi
    wait $AFPLAY_PID
    rm -f "$outfile"
    i=$((i + 1))
done < /tmp/tts-chunks.txt
rm -f /tmp/tts-chunks.txt /tmp/tts-loop.pid /tmp/tts-stop) &
