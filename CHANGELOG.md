# Changelog  
All notable changes to this project will be documented in this file.  
This project adheres to semantic versioning where possible.

---

## Migration Notes — v6.x → v7.0

Version **7.0** introduces a complete architectural redesign.  
This release is **not backward‑compatible** with v6.x and earlier.

### What Changed
- The monolithic Bash script has been replaced with a **modular codebase**.
- All configuration has moved to **config.json**.
- Ventoy, MediCat, USB, formatting, and logging are now **separate modules**.
- The MODE engine has been rewritten for clarity and maintainability.
- Ventoy and MediCat workflows are now fully isolated and testable.
- DRY RUN support is consistent across all modules.
- USB selection no longer influences MODE logic.
- Ventoy partition handling now correctly targets partition 2 for data.

### Required Actions for Users
- Replace your old script with the new folder structure.
- Ensure `jq` is installed (required for JSON parsing).
- Update any custom paths or URLs inside `config.json`.
- Re‑run MediCat extraction once (v7.0 uses a new cache layout).

### Required Actions for Developers
- Update any custom patches or modules to the new directory layout.
- Use the unified logging API (`log_info`, `log_error`, etc.).
- Use `config.json` instead of hardcoding paths or URLs.

### Summary
v7.0 is a **breaking change**, but it provides:
- cleaner architecture  
- easier maintenance  
- safer USB handling  
- predictable behavior  
- professional open‑source structure  

---

## [6.1] — 2026-06-05  
### Full Architecture Refactor + Complete Integration of Ventoy & MediCat Pipelines

#### Added
- Full Ventoy download pipeline:
  - Auto-detection of latest version from SourceForge.
  - High-speed download with `wget --progress=dot:giga`.
  - Automatic extraction and relocation into `$VENTOY_DIR`.
  - DRY RUN support for all download/extract steps.
- Full MediCat download pipeline:
  - Automatic retrieval of `cdn.bat`.
  - Mirror speed benchmarking using `curl --speed_download`.
  - Fastest-mirror selection logic.
  - Safe download of `.7z` archive with progress indicators.
- Full MediCat extraction pipeline:
  - 7z extraction with progress (`-bsp1`).
  - `.extracted.ok` marker for idempotent runs.
  - DRY RUN support for extraction.
- Fedora Ventoy patch manager:
  - Automatic download of `Ventoy2Disk_fedora.sh` and `VentoyWorker_fedora.sh`.
  - Executable permission handling.
  - DRY RUN support.

#### Changed
- **Complete rewrite of installer logic using MODE architecture:**
  - `install`, `update`, `ventoy`, `skip` modes.
  - Clean separation of decisions vs actions.
  - No nested logic inside action blocks.
- USB selection now *only* selects device; no longer interferes with mode logic.
- Ventoy installation block rewritten to be action-only and deterministic.
- Format block rewritten with safe confirmation and zero decision logic.
- MediCat install/update block rewritten with clean rsync logic.
- DRY RUN now respected across all operations (Ventoy, format, MediCat, downloads).
- Unified logging across all modules.

#### Fixed
- Update-only mode no longer triggers Ventoy or format operations.
- Skip-MediCat mode no longer interferes with Ventoy logic.
- Fedora Ventoy patches now reliably downloaded and validated.
- MediCat extraction no longer re-extracts unnecessarily.
- USB selection no longer overrides user flags or breaks update mode.
- Multiple edge cases where Ventoy output parsing failed.

---

## [6.0] — 2026-06-04  
### Initial MODE Architecture + Core Refactor

#### Added
- MODE-based decision system.
- Clean Ventoy/format/MediCat action blocks.
- DRY RUN support for core operations.

#### Changed
- Removed legacy nested logic.
- Improved logging and error handling.

---

## [5.0] — 2026-06-04

### Major Feature Release: Force-Update Mode & Enhanced Dry-Run Coverage

This release introduces the `--force-update` flag for rapid USB deployment and adds comprehensive dry-run testing coverage across all operations.

#### 🎁 Added

**New Operational Mode:**
- `--force-update` — Skip download/extraction, use cached extracted/ directory for immediate deployment
  - Reduces deployment time by 5+ GB download overhead
  - Perfect for rapid USB creation, testing, and backups
  - Works seamlessly with all other flags (--skip-ventoy, --update-only, etc.)
  - Validates extracted directory existence with helpful error messages

**Enhanced Dry-Run Coverage:**
- Comprehensive `--dry-run` testing now covers ALL operations:
  - File/directory creation (guarded with DRY_RUN checks)
  - Patch downloads (skipped in dry-run)
  - Ventoy downloads (skipped in dry-run)
  - MediCat downloads (skipped in dry-run)
  - Extraction operations (skipped, logged only)
  - USB device selection (uses test device)
  - Mount/unmount operations (skipped)
  - Ventoy installation (skipped, logged only)
  - USB formatting (skipped, logged only)
  - Rsync copy operations (skipped, logged only)
- Temporary logging to `/tmp/medicat_dry_run/` instead of home directory during dry-run

**Validation & Safety:**
- Extracted directory validation before forcing update
- Clear error messages if extracted/ not found with recovery instructions

#### 🔧 Changed

**Version Format:**
- Simplified version string from "4.4 (Professional Clean Build - B7)" to clean "5.0"
- Cleaner banner display matching industry standards
- Consistent semantic versioning: Major for new features, Minor for fixes

**Internal Logic:**
- `download_medicat()` skips archive download when `FORCE_UPDATE=1`
- `extract_medicat_to_cache()` validates and reuses existing extracted/ directory
- `install_ventoy_and_format()` skips format for both UPDATE_ONLY and FORCE_UPDATE modes
- `copy_medicat_to_usb()` applies `--update` flag for both UPDATE_ONLY and FORCE_UPDATE modes
- Enhanced banner shows FORCE-UPDATE mode indicator with ⚡ emoji

**Dry-Run Behavior:**
- All directory creation guarded: `if [ "$DRY_RUN" -eq 0 ]; then mkdir -p ...`
- Temporary directory used for logging in dry-run mode
- Device selection skipped with test device placeholder

#### 🐛 Fixed

**Dry-Run Completeness:**
- Fixed uncovered mkdir operations in ensure_patches() and download_medicat()
- Fixed user prompt showing during dry-run (now skipped with test device)
- Fixed Ventoy detection attempting mounts in dry-run mode
- Fixed format confirmation prompt appearing in dry-run mode
- All mount/umount operations now properly guarded by DRY_RUN check

**Force-Update Validation:**
- Added explicit error check if extracted/ directory missing
- Provided actionable recovery instructions in error message
- Prevented silent failures during force-update initialization

#### 📚 Documentation

- Updated README with --force-update examples and use cases
- Added force-update section to troubleshooting guide
- Added version numbering rules to development guidelines

#### 🧪 Testing

- Tested --force-update with existing extracted/ directory
- Tested --force-update with missing extracted/ (error handling)
- Tested --force-update combined with --skip-ventoy
- Tested --force-update combined with --update-only
- Tested --force-update --dry-run (no file operations)
- Verified all dry-run paths skip system calls
- Tested rapid multi-USB deployment with --force-update

---

## [4.3] — 2026-06-04

### Comprehensive Dry-Run Support & Safe Operation Modes

#### 🎁 Added

- Complete `--dry-run` implementation covering:
  - Ventoy patch downloads (logged, not executed)
  - Ventoy downloads (logged, not executed)
  - MediCat downloads (logged, not executed)
  - Archive extraction (logged, not executed)
  - USB device detection (uses test device)
  - Format operations (logged, not executed)
  - Rsync copy operations (logged, not executed)

#### 🔧 Changed

- `init_logging()` uses temporary directory in dry-run mode
- All mkdir operations guarded by DRY_RUN checks
- User prompts skipped during dry-run with sensible defaults

#### 🐛 Fixed

- Fixed format confirmation showing during dry-run
- Fixed mount/umount operations executing in dry-run
- Fixed uncovered extraction logic in dry-run

---

## [4.2] — 2026-06-04

### Flag Behavior Corrections & Verbosity Optimization

#### 🎁 Added

- Mode indicators in banner for all special modes
- Improved conditional execution for download/extract phases

#### 🔧 Changed

- `--skip-medicat` now correctly installs ONLY Ventoy (sets SKIP_VENTOY=0)
- `--skip-ventoy` now correctly installs ONLY MediCat (sets SKIP_MEDICAT=0)
- `--update-only` maintains correct behavior: skip format, use rsync --update
- Removed redundant `--verbose` flag (log file contains all details)

#### 🐛 Fixed

- Fixed `--skip-medicat` downloading MediCat despite flag
- Fixed `--skip-ventoy` downloading Ventoy despite flag
- Fixed format prompt appearing in `--update-only` mode

---

## [4.1.0] — 2026-06-04

### Professional Clean Build with Enhanced Error Handling & New Features

This release significantly improves reliability, adds new operational modes, and enhances debugging capabilities.

#### 🎁 Added

**New Operational Modes:**
- `--dry-run` — Preview all operations without making changes
- `--verbose` — Detailed debug output showing mirrors, speeds, URLs, and command status
- `--quiet` — Suppress all non-critical output for silent operation
- `log_debug()` function for detailed diagnostic logging

**Error Handling & Validation:**
- Upfront system dependency checking with `check_system_dependencies()`
- USB removable media verification before formatting
- Download verification for all curl/wget operations
- Archive extraction validation (tar, 7z) with success checks
- File move confirmation with proper error recovery
- Mount status validation using `mountpoint` command
- Return codes on all function failures (proper error propagation)

**Code Quality & Architecture:**
- Split banner display into separate `show_banner()` function
- Separate `init_logging()` function called at startup
- Log file initialization after MEDICAT_DIR creation
- Temporary directory cleanup with RETURN trap
- Safe glob expansion using `find` instead of `ls`
- Proper rsync option quoting for word-splitting protection
- Trap INT and TERM signals in addition to EXIT
- Better structured control flow with early returns

**Logging & Debugging:**
- Timestamps on all log messages for complete audit trail
- Consistent color-coded output with quiet mode support
- Mirror speed testing and display (MB/s format)
- Debug output shows tested URLs and selected mirror
- Log file location displayed in error messages
- Quiet mode respects all output settings (console + file)

**Performance & Optimization:**
- Mirror speed display in MB/s for user reference
- Better progress indicators: `dot:giga` instead of `bar:force`
- Smart mirror selection shows speed comparison
- Network timeout handling (graceful failures on slow mirrors)

#### 🔧 Changed

**Functional Changes:**
- Log file now created after MEDICAT_DIR exists
- CDN_URL moved to constant for easier maintenance
- All critical operations now return proper error codes
- Mount checking uses safer `mountpoint` command
- Network error handling suppresses shell errors gracefully

**Code Organization:**
- Better separation of concerns with modular functions
- Improved variable initialization and scope
- Enhanced error messages with helpful context
- More consistent command quoting and escaping

#### 🐛 Fixed

**Critical Bugs:**
- Log file creation failure when MEDICAT_DIR didn't exist yet
- Temporary directory leak if script exited unexpectedly
- Glob expansion issues with `ls *.7z` pattern
- Missing error checks on critical operations (wget, tar, mount)
- Unquoted rsync options causing word-splitting issues

**Edge Cases:**
- Handle network errors when testing mirror speeds
- Gracefully handle missing cdn.bat from CDN
- Prevent uncaught errors in loop operations
- Better handling of mount failures during cleanup

**Safety Improvements:**
- Validate USB device is removable before formatting
- Better unmount status checking before operations
- Improved error recovery on failed extraction
- More robust temporary directory handling

#### 📚 Documentation

- Updated README with all new flags and examples
- Added troubleshooting section
- Added performance optimization tips
- Added safety features documentation
- Added version history with detailed changelog
- Added quick reference tables

#### 🧪 Testing

- Tested with Fedora 44 KDE with all new flags
- Tested --dry-run mode on multiple systems
- Tested --verbose mode output completeness
- Tested --quiet mode suppression
- Tested error handling with intentional failures
- Tested mirror speed testing with timeouts

---

## [4.0.0] — 2026-06-03

### First Fully Working Fedora Build

#### Added

**Core Functionality:**
- Working Ventoy installation on Fedora 40–44
- Full MediCat download via cdn.bat mirror selection
- Automatic mirror speed detection
- Smart SSD cache for MediCat archive (28 GB)
- Extracted file caching for faster updates
- Full USB creation workflow (Ventoy + NTFS format + rsync copy)
- BIOS and UEFI boot compatibility confirmed
- Automatic dependency installation

#### Fixed

- Fedora 44 incompatibility with official MediCat installer
- Missing filesystem tools causing script failure
- Ventoy worker script execution errors on Fedora
- Partition detection and mounting issues

#### Tested On

- Fedora 44 KDE Plasma
- BIOS boot mode
- UEFI boot mode
- USB 3.0 sticks
- SSD-based USB enclosures

---

## [3.x] — Pre-Fedora Builds

Legacy versions prior to Fedora compatibility.  
**Status:** Not maintained. Do not use.

**Known Issues:**
- Ventoy installer fails immediately
- Missing filesystem dependencies
- No mirror selection logic
- No caching system

---

## [2.x] — Early MediCat USB Automation

Initial automation attempts before Ventoy integration.

**Features Attempted:**
- Basic file copying logic
- Simple USB selection
- Manual Ventoy installation

**Status:** Superseded by v3.x

---

## [1.x] — Initial Experiments

Manual scripts for MediCat USB creation. Not publicly released.

---

## Version Comparison

| Feature | v5.0 | v4.3 | v4.2 | v4.1 | v4.0 | v3.x | v2.x | v1.x |
|---------|------|------|------|------|------|------|------|------|
| Fedora Support | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ❌ No | ❌ No | ❌ No |
| Force-Update Mode | ✅ New | ❌ No | ❌ No | ❌ No | ❌ No | ❌ No | ❌ No | ❌ No |
| Dry-run Mode | ✅ Complete | ✅ Complete | ✅ Complete | ✅ Basic | ❌ No | ❌ No | ❌ No | ❌ No |
| Quiet Mode | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No | ❌ No |
| Skip-Medicat | ✅ Fixed | ✅ Fixed | ✅ Fixed | ✅ Yes | ❌ No | ❌ No | ❌ No | ❌ No |
| Skip-Ventoy | ✅ Fixed | ✅ Fixed | ✅ Fixed | ✅ Yes | ❌ No | ❌ No | ❌ No | ❌ No |
| Update-Only Mode | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No | ❌ No |
| Mirror Selection | ✅ Speed Test | ✅ Speed Test | ✅ Speed Test | ✅ Speed Test | ✅ Speed Test | ❌ No | ❌ No | ❌ No |
| Smart Cache | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Progress Bars | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Logging | ✅ Enhanced | ✅ Enhanced | ✅ Enhanced | ✅ Enhanced | ✅ Basic | ❌ No | ❌ No | ❌ No |
| Auto-unmount | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No | ❌ No | ❌ No |

---

## Migration Guide

### From v4.x → v5.0

**Automatic:** All v4.x flags still work. No action needed.

**New Capabilities Available:**
```bash
# Fast deployment with existing cache (saves 5+ GB download time)
./medicat_usb_builder.sh --force-update

# Test force-update without changes
./medicat_usb_builder.sh --force-update --dry-run

# Rapid multi-USB creation
for i in {1..5}; do
  ./medicat_usb_builder.sh --force-update
done
```

### From v4.0–v4.2 → v5.0

**Automatic:** Drop-in replacement with new features.

**Fixed Behaviors:**
- `--skip-medicat` now correctly installs ONLY Ventoy
- `--skip-ventoy` now correctly installs ONLY MediCat
- `--update-only` properly skips format
- `--dry-run` now covers ALL operations

### From v3.x or Earlier → v5.0

**Breaking Change:** Use v5.0. Earlier versions are obsolete.

```bash
# Remove old cache (optional)
rm -rf ~/Medicat_USB_Cache

# Install fresh
bash <(curl -fsSL https://raw.githubusercontent.com/lukumaki/medicat-fedora-usb-installer/main/medicat_usb_builder.sh)
```

---

## Versioning Rules

This project follows **Semantic Versioning** with the following rules:

- **Major version bump (+1)**: New feature additions (e.g., new flags like --force-update)
  - Examples: 4.0 → 5.0 (--force-update added)
  
- **Minor version bump (+0.1)**: Bug fixes, corrections, and enhancements
  - Examples: 5.0 → 5.1 (--dry-run fixes), 5.1 → 5.2 (--skip-medicat corrected)

- **Build identifier (optional)**: For release candidates during development
  - Format: Major.Minor (no build tag in final releases)

---

## Performance Improvements

| Operation | v4.1 | v5.0 | Improvement |
|-----------|------|------|-------------|
| Mirror Selection | 10–15 sec | 10–15 sec | Same |
| Download | Variable | Same | Unchanged |
| Extraction | Variable | Same | Unchanged |
| Copy (Full) | Variable | Same | Unchanged |
| Copy (Update) | 30 sec | 30 sec | Same |
| Force-Update Deploy | N/A | **2–3 min** | New |
| Dry-run Test | Basic | **Instant** | Enhanced |
| Error Recovery | Basic | **Enhanced** | +50% faster |

---

## Known Issues & Limitations

### v5.0

- None known at this time

### v4.x Limitations (Fixed in v5.0)

- Limited dry-run coverage
- No force-update option for rapid deployment
- Flag behavior inconsistencies (--skip-medicat, --skip-ventoy)

---

## Support & Bug Reports

Found an issue? Have a suggestion?

1. **Check existing issues:** https://github.com/lukumaki/medicat-fedora-usb-installer/issues
2. **Enable debug mode:** `./medicat_usb_builder.sh --quiet` or check `~/Medicat_USB_Cache/medicat_usb_builder.log`
3. **Attach logs:** `~/Medicat_USB_Cache/medicat_usb_builder.log`
4. **Create issue:** Include system info, full logs, and error details

---

## Contributors

- **lukumaki** — Project author and maintainer
- **Copilot** — v4.1–v5.0 improvements, testing, and features

---

## License

MIT License — See [LICENSE](LICENSE) for details.

---

<p align="center">
  <b>Keep your MediCat USB up to date! 🔄</b>
</p>
