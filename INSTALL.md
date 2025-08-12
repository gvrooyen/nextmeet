# Installation Guide for NextMeet

This guide provides step-by-step instructions for installing and setting up `nextmeet`.

## System Requirements

- **Operating System**: Linux (tested on Ubuntu, Debian, Arch Linux)
- **OCaml**: 4.08 or later
- **Memory**: 50MB RAM during operation
- **Disk Space**: ~20MB for installation
- **Network**: Internet connection for Google Calendar API access

## Installation Methods

### Method 1: From Source (Recommended)

#### Step 1: Install OCaml and Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install ocaml opam m4 pkg-config libssl-dev libgmp-dev
```

**Arch Linux:**
```bash
sudo pacman -S ocaml opam base-devel openssl gmp
```

**Other distributions:**
Install equivalent packages for OCaml, opam, and development tools.

#### Step 2: Initialize opam

```bash
opam init
eval $(opam env)
```

#### Step 3: Install OCaml Dependencies

```bash
opam install lwt cohttp-lwt-unix tls-lwt yojson ptime uri base64 str dune alcotest
```

#### Step 4: Clone and Build

```bash
git clone https://github.com/your-username/nextmeet.git
cd nextmeet
dune build
```

#### Step 5: Install

```bash
# Install to opam directory
dune install

# Or install system-wide (requires sudo)
sudo cp _build/default/bin/main.exe /usr/local/bin/nextmeet
sudo chmod 755 /usr/local/bin/nextmeet
```

#### Step 6: Verify Installation

```bash
which nextmeet
nextmeet  # Should show authentication setup message
```

### Method 2: Binary Installation (Future)

*Note: Binary releases are planned for future versions.*

## Google Calendar Setup

### Step 1: Create Google Cloud Project

1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Click "New Project" or select existing project
3. Enter project name (e.g., "nextmeet-calendar")
4. Click "Create"

### Step 2: Enable Google Calendar API

1. In Google Cloud Console, go to "APIs & Services" > "Library"
2. Search for "Google Calendar API"
3. Click on it and press "Enable"
4. Wait for API to be enabled (usually instant)

### Step 3: Create OAuth2 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. If prompted, configure OAuth consent screen:
   - Choose "External" user type
   - Fill in application name: "NextMeet"
   - Add your email as developer contact
   - Add scopes: `../auth/calendar.readonly`
   - Save and continue
4. Select "Desktop application" as application type
5. Name: "nextmeet" (or any descriptive name)
6. Click "Create"
7. **Download the JSON file** - this contains your credentials

### Step 4: Configure NextMeet

1. Create config directory:
   ```bash
   mkdir -p ~/.config/nextmeet
   ```

2. Copy your downloaded credentials:
   ```bash
   cp ~/Downloads/client_secret_*.json ~/.config/nextmeet/credentials.json
   ```

3. Verify file format (should look like this):
   ```bash
   cat ~/.config/nextmeet/credentials.json
   ```
   ```json
   {
     "installed": {
       "client_id": "123456789-abcdefg.apps.googleusercontent.com",
       "client_secret": "your-secret-here",
       "redirect_uris": ["http://localhost"]
     }
   }
   ```

4. If format differs, manually create the file:
   ```bash
   cat > ~/.config/nextmeet/credentials.json << 'EOF'
   {
     "client_id": "your-client-id-here",
     "client_secret": "your-client-secret-here", 
     "redirect_uri": "http://localhost:8080"
   }
   EOF
   ```

5. Set secure permissions:
   ```bash
   chmod 600 ~/.config/nextmeet/credentials.json
   ```

## First-Time Authentication

### Step 1: Run NextMeet

```bash
nextmeet
```

### Step 2: Complete OAuth Flow

1. Your default browser should open automatically
2. If not, copy the URL from the terminal and paste into browser
3. Sign in to your Google account
4. Review permissions:
   - "See, edit, share, and permanently delete all calendars"
   - Choose "Allow" (nextmeet only reads, never modifies)
5. You'll see "Authentication successful!" message
6. Browser page will show "Authentication successful! You can close this window."

### Step 3: Verify Setup

```bash
nextmeet
echo $?  # Should print 0 or 1 depending on whether meetings exist
```

## Troubleshooting Installation

### OCaml/opam Issues

**Problem**: `opam: command not found`
```bash
# Install opam first
sudo apt install opam  # Ubuntu/Debian
sudo pacman -S opam    # Arch Linux
```

**Problem**: OCaml compilation errors
```bash
# Update opam and reinstall dependencies
opam update
opam upgrade
```

### Build Issues

**Problem**: Missing system dependencies
```bash
# Ubuntu/Debian
sudo apt install libssl-dev libgmp-dev pkg-config

# Arch Linux  
sudo pacman -S openssl gmp pkgconf
```

**Problem**: Dune build fails
```bash
# Clean and rebuild
dune clean
dune build
```

### Authentication Issues

**Problem**: Port 8080 already in use
```bash
# Find what's using the port
sudo lsof -i :8080

# Kill the process or choose different port
# (nextmeet currently only supports port 8080)
```

**Problem**: Browser doesn't open
1. Copy the URL from terminal output
2. Paste into any browser
3. Complete authentication flow
4. Return to terminal

**Problem**: "Invalid credentials" error
1. Verify `~/.config/nextmeet/credentials.json` format
2. Ensure client_id and client_secret are correct
3. Check that OAuth consent screen is configured
4. Verify Google Calendar API is enabled

### Permission Issues

**Problem**: Cannot write to config directory
```bash
# Check permissions
ls -la ~/.config/
mkdir -p ~/.config/nextmeet
chmod 700 ~/.config/nextmeet
```

**Problem**: Cannot access credentials file
```bash
# Fix permissions
chmod 600 ~/.config/nextmeet/credentials.json
chown $USER:$USER ~/.config/nextmeet/credentials.json
```

## Upgrading

### From Source

```bash
cd nextmeet
git pull
dune clean
dune build
dune install
```

### Backup Configuration

Before upgrading, backup your configuration:

```bash
cp -r ~/.config/nextmeet ~/.config/nextmeet.backup
```

## Uninstalling

### Remove Binary

```bash
# If installed via dune
dune uninstall

# If installed system-wide
sudo rm /usr/local/bin/nextmeet
```

### Remove Configuration

```bash
rm -rf ~/.config/nextmeet
```

### Remove OCaml Dependencies (Optional)

```bash
opam remove lwt cohttp-lwt-unix tls-lwt yojson ptime uri base64 str dune alcotest
```

## Security Notes

- Credentials are stored with 600 permissions (owner read/write only)
- OAuth tokens are automatically refreshed and securely stored
- No sensitive information is logged or displayed in error messages
- Local callback server (port 8080) only binds to localhost
- Consider using a dedicated Google account for calendar access

## Platform-Specific Notes

### Ubuntu/Debian
- May need `snap install google-chrome` for browser OAuth flow
- Firewall may block local server - add exception for port 8080

### Arch Linux
- Use `yay` or `paru` to install AUR packages if needed
- May need to enable `systemd-resolved` for DNS resolution

### WSL (Windows Subsystem for Linux)
- Browser OAuth flow may not work automatically
- Manually copy URL to Windows browser
- Ensure port 8080 is forwarded between WSL and Windows

## Performance Tuning

For optimal performance:

```bash
# Reduce memory usage
export OCAMLRUNPARAM=s=256k,i=32k

# Cache DNS lookups
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
```

## Support and Community

- **Documentation**: Check README.md for usage examples
- **Issues**: Report bugs on the project repository
- **Debug**: Use `dune exec bin/debug.exe` for verbose output
- **Community**: Join discussions in project forums

This completes the installation guide. NextMeet should now be ready to find your Google Meet links!
