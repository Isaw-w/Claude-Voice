#!/bin/bash
# Advanced TTS for AI coding assistants (Claude Code, Codex, etc.)
# Speaks text aloud using macOS system Spoken Content voice (supports Siri natural voices).
#
# Usage:
#   echo "hello" | ./tts-speak.sh          # pipe text directly
#   ./tts-speak.sh "hello world"            # pass as argument
#   jq -r '.message' | ./tts-speak.sh      # pipe from JSON extraction
#
# The voice is determined by your system settings:
#   System Settings > Accessibility > Spoken Content > System Voice
#
# Configure your preferred voices there (e.g. Siri voices for natural TTS).
# The system automatically picks the right voice based on text language.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Kill any previous speech so responses don't overlap
killall say 2>/dev/null

# Read text from argument or stdin
if [ -n "$1" ]; then
    text="$*"
else
    text=$(cat)
fi

# Strip markdown using external Python script (avoids backtick escaping issues)
text=$(echo "$text" | python3 "$SCRIPT_DIR/tts-strip-markdown.py")

# Skip if empty
[ -z "$(echo "$text" | tr -d '[:space:]')" ] && exit 0

# Escape double quotes for AppleScript
text=$(echo "$text" | sed 's/"/\\"/g')

# Speak using macOS system Spoken Content voice
# No 'using' parameter = system picks the right voice per language
osascript -e "say \"$text\"" &
