# Claude Code TTS Hook

Make Claude Code speak its responses aloud using macOS natural Siri voices.

https://github.com/user-attachments/assets/demo.mp4

## How it works

This is a [Claude Code hook](https://docs.anthropic.com/en/docs/claude-code/hooks) that triggers every time Claude finishes a response. It extracts the response text, strips markdown formatting, and speaks it using macOS system TTS via AppleScript `say`.

The key insight: AppleScript `say` (without a `using` parameter) uses your **system Spoken Content voice**, which includes Apple's natural Siri voices — much more natural than the `say` CLI command or `AVSpeechSynthesizer`.

## Features

- Natural-sounding speech using Siri voices
- Automatic language detection (voice matches text language)
- Strips markdown (code blocks, bold, headers, links) before speaking
- Kills previous speech when new response arrives (no overlap)
- Runs async — doesn't block Claude Code
- Truncates long responses (2000 char limit)

## Requirements

- macOS (uses `osascript` and `say`)
- Claude Code
- Siri voices downloaded (optional but recommended for natural TTS)

## Setup

### 1. Download Siri voices (recommended)

Go to **System Settings → Accessibility → Spoken Content → System Voice → Manage Voices** and download Siri voices for your languages. For example:

- English: Siri Voice 1 (Aaron) or Siri Voice 2
- Mandarin: Siri Voice 1 or Siri Voice 2 (Linfei)

Set your preferred voice as the system voice for each language.

### 2. Install the script

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/claude-code-tts.git

# Copy script to Claude config directory
cp claude-code-tts/tts-speak.sh ~/.claude/tts-speak.sh
chmod +x ~/.claude/tts-speak.sh
```

### 3. Add the hook to Claude Code settings

Edit `~/.claude/settings.json` and add the `Stop` hook:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.last_assistant_message // empty' | ~/.claude/tts-speak.sh &",
            "async": true
          }
        ]
      }
    ]
  }
}
```

If you already have other hooks, merge the `Stop` entry into your existing `hooks` object.

### 4. Stop speech anytime

```bash
killall say
```

## How voice selection works

macOS Spoken Content lets you configure a preferred voice per language. When AppleScript `say` runs without a `using` parameter, it uses the system voice matching the detected text language.

For example, if you set:
- System voice for English → Siri Aaron
- System voice for Mandarin → Siri Linfei

Then Claude's English responses will use Aaron, and Chinese responses will use Linfei, automatically.

## Customization

### Change the character limit

Edit `tts-speak.sh` and change the `2000` in:
```bash
text=$(echo "$text" | cut -c1-2000)
```

### Use a specific voice

Add `using "VoiceName"` to the osascript command:
```bash
osascript -e "say \"$text\" using \"Samantha\"" &
```

### Adjust speech rate

Add `speaking rate N` (words per minute, default ~175):
```bash
osascript -e "say \"$text\" speaking rate 200" &
```

## License

MIT
