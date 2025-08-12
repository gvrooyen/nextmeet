# Changelog

All notable changes to NextMeet will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-08-12

### Added
- Initial release of NextMeet
- Google Calendar integration with OAuth2 authentication
- Google Meet URL extraction from multiple sources:
  - `hangoutLink` field (primary)
  - `conferenceData.entryPoints` (structured data)
  - Text-based parsing from descriptions, locations, summaries (fallback)
- Time window filtering (±10 minutes from current time)
- Silent operation mode (production)
- Debug mode for troubleshooting
- Comprehensive test suite with 19+ test cases
- Secure credential and token storage with proper file permissions
- Automatic token refresh functionality
- Cross-platform browser opening for OAuth2 flow
- Robust error handling for network and API failures

### Security
- OAuth2 credentials stored with 600 permissions (owner read/write only)
- CSRF protection in OAuth2 flow using state parameter
- Local callback server bound to localhost only
- No sensitive data exposed in logs or error messages
- Automatic token refresh before expiry

### Documentation
- Complete installation guide (INSTALL.md)
- Comprehensive usage examples (EXAMPLES.md)
- Detailed README with architecture overview
- API documentation and troubleshooting guide

### Technical Features
- Built with OCaml and modern libraries (lwt, cohttp, yojson, ptime)
- TLS/SSL support for secure HTTPS communication
- RFC3339 timestamp handling for Google Calendar API
- Modular architecture with separated concerns:
  - `auth.ml`: OAuth2 authentication
  - `calendar.ml`: Google Calendar API client
  - `config.ml`: Configuration management
  - `meet_parser.ml`: URL extraction logic
  - `time_utils.ml`: Time calculations
- Performance optimizations:
  - Limited API requests (10 events max)
  - Early termination on first URL found
  - Efficient regex patterns for URL matching
  - Minimal field selection in API requests

### Exit Codes
- 0: Google Meet URL found and printed
- 1: No meeting found in time window
- Other: Authentication or system errors

### Requirements
- Linux operating system
- OCaml 4.08 or later
- Internet connection for Google Calendar API
- Modern web browser for OAuth2 authentication

## [Unreleased]

### Planned Features
- Support for other meeting platforms (Zoom, Microsoft Teams)
- Configuration file for custom time windows
- Multiple Google account support
- Binary releases for common Linux distributions
- Systemd service integration
- GUI version for desktop environments

### Known Issues
- OAuth2 callback server only supports port 8080
- Time zone handling assumes system timezone matches calendar
- WSL browser integration may require manual URL copying
- Large calendar responses not paginated

## Development History

### Phase 1: Core Infrastructure ✅
- Project setup with dune and OCaml dependencies
- OAuth2 authentication flow implementation
- Secure configuration and token management
- Browser-based authentication testing

### Phase 2: Calendar Integration ✅  
- Google Calendar API client implementation
- Time window calculations and RFC3339 formatting
- Event filtering and data parsing
- API request optimization

### Phase 3: Meet URL Extraction ✅
- Google Meet URL regex patterns
- Multiple extraction sources (hangoutLink, conferenceData, text)
- Priority-based URL detection
- Edge case handling

### Phase 4: Integration & Polish ✅
- Production-ready main application
- Silent operation mode
- Comprehensive error handling
- Performance optimizations
- End-to-end testing

### Phase 5: Testing & Documentation ✅
- Unit test suite (19 tests covering all modules)
- Integration tests with mock API responses
- Complete documentation set
- Installation and usage guides
- Distribution packaging

---

For support and bug reports, please visit the project repository.
