#!/bin/bash
# Claude Code TTS Hook
# Reads Claude's response from the Stop hook and speaks it aloud
# using macOS system Spoken Content voice (supports Siri natural voices).
#
# The voice is determined by your system settings:
#   System Settings > Accessibility > Spoken Content > System Voice
#
# Configure your preferred voices there (e.g. Siri voices for natural TTS).
# The system automatically picks the right voice based on text language.

# Kill any previous speech so responses don't overlap
killall say 2>/dev/null

# Read text from stdin (hook pipes JSON, jq extracts the message)
text=$(cat)

# Strip markdown formatting that sounds bad when read aloud
text=$(echo "$text" \
  | sed 's/```[^`]*```//g' \
  | sed 's/`[^`]*`//g' \
  | sed 's/^#\+//g' \
  | sed 's/\*\*//g' \
  | sed 's/\[[^]]*\]([^)]*)//g')

# Truncate to avoid very long speeches
text=$(echo "$text" | cut -c1-2000)

# Skip if empty
[ -z "$(echo "$text" | tr -d '[:space:]')" ] && exit 0

# Escape double quotes for AppleScript
text=$(echo "$text" | sed 's/"/\\"/g')

# Speak using macOS system Spoken Content voice
# No 'using' parameter = system picks the right voice per language
osascript -e "say \"$text\"" &
