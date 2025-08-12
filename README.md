# NextMeet

A simple Linux command-line utility in OCaml that finds upcoming Google Meet links from your Google Calendar.

## Overview

`nextmeet` connects to your Google Calendar and looks for meetings that start within the next 10 minutes or started up to 10 minutes ago (a 20-minute window). If it finds a meeting with a Google Meet link, it prints only the URL to stdout and exits with code 0. If no meeting is found, it produces no output and exits with code 1.

## Installation

### Prerequisites

- OCaml 4.08 or later
- opam (OCaml package manager)
- dune (build system)

### Install Dependencies

```bash
opam install lwt cohttp-lwt-unix tls-lwt yojson ptime uri base64 str
```

### Build

```bash
dune build
```

### Install

```bash
dune install
```

## Setup

### 1. Create Google Cloud Project

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Calendar API:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Calendar API"
   - Click "Enable"

### 2. Create OAuth2 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Desktop application"
4. Name it "nextmeet" (or any name you prefer)
5. Download the JSON file

### 3. Configure nextmeet

Save your credentials to `~/.config/nextmeet/credentials.json`:

```json
{
  "client_id": "your-google-client-id-here",
  "client_secret": "your-google-client-secret-here", 
  "redirect_uri": "http://localhost:8080"
}
```

**Security Note**: This file contains sensitive information. The application automatically sets file permissions to 600 (owner read/write only).

## Usage

### Basic Usage

```bash
nextmeet
```

**Successful execution (meeting found):**
```bash
$ nextmeet
https://meet.google.com/abc-defg-hij
$ echo $?
0
```

**No meeting found:**
```bash
$ nextmeet
$ echo $?
1
```

### First-Time Authentication

When you run `nextmeet` for the first time (or when tokens expire), it will:

1. Open your default browser
2. Redirect to Google's OAuth2 consent screen
3. Ask you to grant calendar access permissions
4. Start a local server on port 8080 to receive the authorization code
5. Exchange the code for access and refresh tokens
6. Store tokens securely in `~/.config/nextmeet/tokens.json`

### Integration Examples

**Shell scripting:**
```bash
#!/bin/bash
MEET_URL=$(nextmeet)
if [ $? -eq 0 ]; then
    echo "Opening meeting: $MEET_URL"
    xdg-open "$MEET_URL"
else
    echo "No upcoming meetings with Google Meet links"
fi
```

**Cron job (check every 5 minutes):**
```bash
*/5 * * * * /usr/local/bin/nextmeet && xdg-open $(nextmeet) 2>/dev/null
```

**i3 status bar:**
```bash
# Add to your i3status config
bar {
    status_command while nextmeet >/dev/null 2>&1 && echo "🎥 Meeting Ready" || echo "📅 No Meeting"; do sleep 60; done
}
```

**Hyprland key binding:**
```hyprlang
# When opening a new browser window, automatically connect to the current meeting, if any
bind = $mainMod, B, exec, ~/bin/nextmeet | xargs $browser --new-window
```

## Architecture

The application consists of several modular components:

### Authentication Flow

```
1. Check existing tokens
2. If invalid/missing:
   a. Generate OAuth2 authorization URL
   b. Open browser for user consent
   c. Start local callback server (port 8080)
   d. Exchange authorization code for tokens
   e. Store tokens securely
3. Use tokens for API requests
4. Auto-refresh when needed
```

### Time Window Logic

```
Current Time: 14:30:00
Window Start: 14:20:00 (current - 10 minutes)
Window End:   14:40:00 (current + 10 minutes)

Events starting between 14:20:00 and 14:40:00 are included
```

## Configuration Files

All configuration is stored in `~/.config/nextmeet/`:

- **`credentials.json`**: OAuth2 client credentials (user-provided)
- **`tokens.json`**: Access and refresh tokens (auto-generated)

Both files have 600 permissions (owner read/write only) for security.

## API Details

### Google Calendar API

- **Endpoint**: `https://www.googleapis.com/calendar/v3/calendars/primary/events`
- **Scopes**: `https://www.googleapis.com/auth/calendar.readonly`
- **Fields Requested**: `id,summary,description,location,start,end,hangoutLink,conferenceData`

### Rate Limiting

The application respects Google's API rate limits:
- Maximum 10 events per request
- Built-in error handling for 429 (Too Many Requests)
- Automatic retry logic for transient failures

## Troubleshooting

### Common Issues

**No credentials configured:**
```
Authentication failed: No credentials configured
Please ensure your Google OAuth2 credentials are set up correctly.
Save credentials to: /home/user/.config/nextmeet/credentials.json
```
*Solution*: Follow the setup instructions to create and save OAuth2 credentials.

**Port 8080 in use:**
```
Authentication failed: Network connection refused
```
*Solution*: Ensure port 8080 is available during authentication, or kill processes using it.

**Network connectivity:**
```
Authentication failed: Network timeout
```
*Solution*: Check internet connection and firewall settings.

### Debug Mode

Use the debug version to see detailed operation:

```bash
dune exec bin/debug.exe
```

This shows:
- Current time window
- All fetched events
- Meet URL extraction process
- Detailed error messages

### Re-authentication

If authentication fails repeatedly, clear stored tokens:

```bash
rm ~/.config/nextmeet/tokens.json
```

The next run will trigger a fresh authentication flow.

## Testing

Run the test suite:

```bash
dune test
```

This includes:
- Unit tests for all modules
- Time calculation validation
- Meet URL parsing tests
- Configuration management tests
- Mock API response parsing

## Development

### Project Structure

```
nextmeet/
├── bin/
│   ├── main.ml          # Production entry point
│   └── debug.ml         # Debug version
├── lib/
│   ├── auth.ml          # OAuth2 authentication
│   ├── calendar.ml      # Google Calendar API
│   ├── config.ml        # Configuration management
│   ├── meet_parser.ml   # Meet URL extraction
│   └── time_utils.ml    # Time calculations
├── test/
│   └── test_*.ml        # Test suites
├── dune-project         # Project configuration
└── README.md
```

### Building

```bash
# Development build
dune build

# Run tests
dune test

# Install locally
dune install
```

## License

This project is released under the [MIT License](LICENSE).

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass with `dune test`
5. Run `dune fmt` to lint the source
6. Submit a pull request

## Support

For issues and questions:
- Check the troubleshooting section above
- Use debug mode for detailed diagnostics
- Review the Google Calendar API documentation
- File an issue on the project repository
