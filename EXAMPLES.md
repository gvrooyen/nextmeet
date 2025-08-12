# NextMeet Usage Examples

This document provides practical examples of how to use `nextmeet` in various scenarios.

## Basic Usage

### Check for Upcoming Meetings

```bash
# Simple check
nextmeet

# With exit code handling
nextmeet && echo "Meeting found!" || echo "No meetings"
```

### Store Meeting URL

```bash
# Capture URL in variable
MEET_URL=$(nextmeet)
if [ $? -eq 0 ]; then
    echo "Next meeting: $MEET_URL"
fi
```

## Shell Scripting Examples

### Auto-Open Meeting Browser

```bash
#!/bin/bash
# auto-join.sh - Automatically open upcoming meetings

MEET_URL=$(nextmeet)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "Opening meeting: $MEET_URL"
    
    # Linux
    xdg-open "$MEET_URL"
    
    # macOS
    # open "$MEET_URL"
    
    # Windows (WSL)
    # cmd.exe /c start "$MEET_URL"
else
    echo "No upcoming meetings with Google Meet links"
fi
```

### Meeting Notification Script

```bash
#!/bin/bash
# notify-meeting.sh - Show desktop notification for upcoming meetings

MEET_URL=$(nextmeet)

if [ $? -eq 0 ]; then
    # Extract meeting ID from URL for display
    MEETING_ID=$(echo "$MEET_URL" | sed 's|.*meet.google.com/||')
    
    # Show notification (Linux)
    notify-send "📹 Meeting Ready" "Join: $MEETING_ID\n$MEET_URL" -t 30000
    
    # macOS alternative:
    # osascript -e "display notification \"$MEET_URL\" with title \"Meeting Ready\""
    
    echo "Notification sent for meeting: $MEETING_ID"
else
    echo "No meetings to notify about"
fi
```

### Cron Job Examples

```bash
# Check every 5 minutes and open meeting automatically
*/5 * * * * /usr/local/bin/nextmeet >/dev/null 2>&1 && xdg-open $(nextmeet) 2>/dev/null

# Log meeting notifications
*/5 * * * * /usr/local/bin/nextmeet && echo "$(date): Meeting available" >> ~/meeting-log.txt

# Run custom notification script
*/10 * * * * /home/user/scripts/notify-meeting.sh
```

## Desktop Integration

### i3 Window Manager Status Bar

```bash
# Add to i3status config (~/.config/i3status/config)
order += "tztime meeting"

tztime meeting {
    format = "%time"
    format_time = "%H:%M"
    on_click 1 = "exec nextmeet && xdg-open $(nextmeet)"
    on_click 3 = "exec notify-send 'Meeting Status' \"$(nextmeet >/dev/null 2>&1 && echo 'Meeting ready' || echo 'No meetings')\""
}
```

### Polybar Module

```ini
; Add to polybar config
[module/nextmeet]
type = custom/script
exec = nextmeet >/dev/null 2>&1 && echo "🎥" || echo "📅"
interval = 300
click-left = nextmeet && xdg-open $(nextmeet)
click-right = notify-send "Meeting Status" "$(nextmeet >/dev/null 2>&1 && echo 'Meeting ready' || echo 'No meetings')"
```

### GNOME Shell Extension (Concept)

```javascript
// Simple GNOME Shell extension concept
const { St, Clutter } = imports.gi;
const Main = imports.ui.main;
const Util = imports.misc.util;

let button;

function checkMeeting() {
    Util.spawn(['nextmeet'], (stdout) => {
        if (stdout.trim()) {
            button.set_label('🎥');
            button.connect('button-press-event', () => {
                Util.spawn(['xdg-open', stdout.trim()]);
            });
        } else {
            button.set_label('📅');
        }
    });
}

function init() {
    button = new St.Button({
        label: '📅',
        style_class: 'panel-button'
    });
}

function enable() {
    Main.panel._rightBox.insert_child_at_index(button, 0);
    checkMeeting();
    // Check every 5 minutes
    GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 300, checkMeeting);
}
```

## Advanced Scripting

### Multi-Account Support

```bash
#!/bin/bash
# multi-account.sh - Check multiple Google accounts

accounts=("work" "personal")

for account in "${accounts[@]}"; do
    export NEXTMEET_CONFIG_DIR="$HOME/.config/nextmeet-$account"
    
    echo "Checking $account account..."
    MEET_URL=$(nextmeet)
    
    if [ $? -eq 0 ]; then
        echo "[$account] Meeting found: $MEET_URL"
        xdg-open "$MEET_URL"
        break
    else
        echo "[$account] No meetings"
    fi
done
```

### Meeting Logger

```bash
#!/bin/bash
# meeting-logger.sh - Log all meeting activities

LOG_FILE="$HOME/meeting-history.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

MEET_URL=$(nextmeet)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "[$TIMESTAMP] MEETING_FOUND: $MEET_URL" >> "$LOG_FILE"
    
    # Optional: Record meeting duration
    echo "[$TIMESTAMP] JOINING_MEETING: $MEET_URL" >> "$LOG_FILE"
    
    # Open meeting
    xdg-open "$MEET_URL"
    
    # Wait for user to indicate meeting ended
    read -p "Press Enter when meeting ends..."
    echo "[$TIMESTAMP] MEETING_ENDED: $MEET_URL" >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] NO_MEETING_FOUND" >> "$LOG_FILE"
fi
```

### Integration with Calendar Tools

```bash
#!/bin/bash
# calendar-integration.sh - Combine with other calendar tools

# Check nextmeet first
MEET_URL=$(nextmeet)

if [ $? -eq 0 ]; then
    echo "Google Meet link found: $MEET_URL"
    xdg-open "$MEET_URL"
else
    # Fallback to other calendar tools
    echo "No Google Meet found, checking other calendars..."
    
    # Example: Check Outlook/Exchange calendar
    # evolution --component=calendar
    
    # Example: Check CalDAV calendar  
    # calcurse -a
    
    echo "No immediate meetings found"
fi
```

## Error Handling Examples

### Robust Meeting Checker

```bash
#!/bin/bash
# robust-checker.sh - Handle all possible scenarios

check_meeting() {
    local output
    local exit_code
    
    # Capture both output and exit code
    output=$(nextmeet 2>&1)
    exit_code=$?
    
    case $exit_code in
        0)
            echo "SUCCESS: Meeting found - $output"
            echo "$output" | xargs xdg-open
            return 0
            ;;
        1)
            echo "INFO: No meetings in the next 10 minutes"
            return 1
            ;;
        *)
            echo "ERROR: Failed to check calendar (exit code: $exit_code)"
            echo "Output: $output"
            
            # Log error for debugging
            echo "$(date): nextmeet failed with code $exit_code: $output" >> ~/.nextmeet-errors.log
            
            # Try to fix common issues
            if echo "$output" | grep -q "No credentials"; then
                echo "HINT: Run setup: mkdir -p ~/.config/nextmeet && cp credentials.json ~/.config/nextmeet/"
            elif echo "$output" | grep -q "Network"; then
                echo "HINT: Check internet connection"
            fi
            
            return $exit_code
            ;;
    esac
}

# Main execution
if ! check_meeting; then
    echo "Meeting check completed with issues"
fi
```

### Network Retry Logic

```bash
#!/bin/bash
# retry-meeting.sh - Retry on network failures

MAX_RETRIES=3
RETRY_DELAY=5

for attempt in $(seq 1 $MAX_RETRIES); do
    echo "Attempt $attempt/$MAX_RETRIES..."
    
    MEET_URL=$(nextmeet 2>&1)
    EXIT_CODE=$?
    
    case $EXIT_CODE in
        0)
            echo "Meeting found: $MEET_URL"
            xdg-open "$MEET_URL"
            exit 0
            ;;
        1)
            echo "No meetings found"
            exit 1
            ;;
        *)
            if [ $attempt -eq $MAX_RETRIES ]; then
                echo "Failed after $MAX_RETRIES attempts: $MEET_URL"
                exit $EXIT_CODE
            else
                echo "Attempt $attempt failed, retrying in ${RETRY_DELAY}s..."
                sleep $RETRY_DELAY
            fi
            ;;
    esac
done
```

## System Integration

### Systemd Timer (Alternative to Cron)

```ini
# ~/.config/systemd/user/nextmeet-check.service
[Unit]
Description=Check for upcoming Google Meet meetings
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nextmeet
ExecStartPost=/bin/sh -c 'if [ $? -eq 0 ]; then xdg-open $(nextmeet); fi'
```

```ini
# ~/.config/systemd/user/nextmeet-check.timer
[Unit]
Description=Check meetings every 5 minutes
Requires=nextmeet-check.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
```

Enable with:
```bash
systemctl --user daemon-reload
systemctl --user enable nextmeet-check.timer
systemctl --user start nextmeet-check.timer
```

### Alfred Workflow (macOS)

```bash
# Alfred script filter for macOS
query="$1"

MEET_URL=$(nextmeet)
if [ $? -eq 0 ]; then
    cat << EOF
{
  "items": [
    {
      "uid": "nextmeet",
      "title": "Join Meeting",
      "subtitle": "$MEET_URL",
      "arg": "$MEET_URL",
      "icon": {
        "path": "meeting.png"
      }
    }
  ]
}
EOF
else
    cat << EOF
{
  "items": [
    {
      "uid": "nextmeet",
      "title": "No Meetings",
      "subtitle": "No Google Meet links found in the next 10 minutes",
      "valid": false,
      "icon": {
        "path": "calendar.png"
      }
    }
  ]
}
EOF
fi
```

## Testing and Development

### Test with Mock Data

```bash
#!/bin/bash
# test-nextmeet.sh - Test nextmeet behavior

echo "Testing nextmeet functionality..."

# Test 1: Check if binary exists
if ! command -v nextmeet &> /dev/null; then
    echo "❌ nextmeet not found in PATH"
    exit 1
fi

# Test 2: Check configuration
if [ ! -f ~/.config/nextmeet/credentials.json ]; then
    echo "⚠️  No credentials found"
else
    echo "✅ Credentials file exists"
fi

# Test 3: Run nextmeet and check exit codes
echo "Running nextmeet..."
OUTPUT=$(nextmeet 2>&1)
EXIT_CODE=$?

case $EXIT_CODE in
    0)
        echo "✅ Meeting found: $OUTPUT"
        if [[ $OUTPUT =~ https://meet\.google\.com/ ]]; then
            echo "✅ Valid Google Meet URL format"
        else
            echo "❌ Invalid URL format: $OUTPUT"
        fi
        ;;
    1)
        echo "✅ No meetings found (expected behavior)"
        if [ -n "$OUTPUT" ]; then
            echo "❌ Unexpected output when no meetings: $OUTPUT"
        else
            echo "✅ Silent operation confirmed"
        fi
        ;;
    *)
        echo "❌ Unexpected exit code: $EXIT_CODE"
        echo "Output: $OUTPUT"
        ;;
esac

echo "Test completed"
```

### Debug Mode Usage

```bash
#!/bin/bash
# debug-meeting.sh - Use debug mode for troubleshooting

echo "=== NextMeet Debug Information ==="

# Run debug version if available
if [ -f "_build/default/bin/debug.exe" ]; then
    echo "Running debug version..."
    dune exec bin/debug.exe
else
    echo "Debug version not available, running with verbose output..."
    nextmeet
fi

echo "=== System Information ==="
echo "Date: $(date)"
echo "Timezone: $(timedatectl show --property=Timezone --value)"
echo "Network: $(ping -c 1 google.com >/dev/null 2>&1 && echo "OK" || echo "Failed")"
echo "Config dir: $(ls -la ~/.config/nextmeet/ 2>/dev/null || echo "Not found")"
```

These examples demonstrate the flexibility and power of `nextmeet` for automating meeting management workflows. Choose the examples that best fit your environment and customize them as needed!
