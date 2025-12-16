<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# SIMPLE_IPC

**[Documentation](https://simple-eiffel.github.io/simple_ipc/)**

### Cross-Platform IPC Library for Eiffel

[![Language](https://img.shields.io/badge/language-Eiffel-blue.svg)](https://www.eiffel.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20|%20Linux%20|%20macOS-blue.svg)]()
[![SCOOP](https://img.shields.io/badge/SCOOP-compatible-orange.svg)]()
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()
[![Tests](https://img.shields.io/badge/tests-14%20passing-brightgreen.svg)]()

---

## Overview

SIMPLE_IPC provides SCOOP-compatible inter-process communication for Eiffel applications with platform-specific transports:

- **Windows:** Named Pipes (`\\.\pipe\name`)
- **Linux/macOS:** Unix Domain Sockets (`/var/run/name.sock`) *(coming soon)*

The library uses a facade pattern with a common `IPC_CONNECTION` interface, automatically selecting the appropriate transport for the current platform.

**v2.0.0 Architecture:**
```
SIMPLE_IPC (facade)
    └── IPC_CONNECTION (deferred base)
            ├── NAMED_PIPE_CONNECTION (Windows)
            └── UNIX_SOCKET_CONNECTION (Linux/macOS)
```

**Developed using AI-assisted methodology:** Built interactively with Claude Opus 4.5 following rigorous Design by Contract principles.

---

## Features

### Transport Support

| Platform | Transport | Status |
|----------|-----------|--------|
| Windows | Named Pipes | Implemented |
| Linux | Unix Sockets | Stub (coming soon) |
| macOS | Unix Sockets | Stub (coming soon) |

### Operations

- **Server Mode** - Create IPC endpoint and wait for client connections
- **Client Mode** - Connect to existing IPC endpoint
- **Read/Write** - Send and receive string and binary data
- **Connection Management** - Disconnect and reconnect capabilities
- **Platform Query** - Check which transport is in use

---

## Quick Start

### Installation

1. Clone the repository:
```bash
git clone https://github.com/simple-eiffel/simple_ipc.git
```

2. Set the environment variable:
```bash
# Windows
set SIMPLE_IPC=D:\path\to\simple_ipc

# Linux/macOS
export SIMPLE_IPC=/path/to/simple_ipc
```

3. Add to your ECF file:
```xml
<library name="simple_ipc" location="$SIMPLE_IPC\simple_ipc.ecf"/>
```

### Basic Usage

#### Using the Facade (Recommended)

```eiffel
-- Server
create ipc.make_server ("my_service")
if ipc.is_valid then
    ipc.wait_for_connection (5000)  -- 5 second timeout
    if ipc.is_connected then
        ipc.write_string ("Hello client!")
        response := ipc.read_string (1024)
    end
    ipc.close
end

-- Client
create ipc.make_client ("my_service")
if ipc.is_connected then
    message := ipc.read_string (1024)
    ipc.write_string ("Hello server!")
    ipc.close
end
```

#### Direct Platform Access

```eiffel
-- Windows named pipe directly
create pipe.make_server ("my_pipe")
if pipe.is_valid then
    -- Use Win32 named pipe features
end

-- Check platform
if ipc.is_using_named_pipes then
    print ("Using Windows Named Pipes%N")
end
```

---

## API Reference

### SIMPLE_IPC (Facade)

```eiffel
-- Creation
make_server (a_name: READABLE_STRING_GENERAL)
make_client (a_name: READABLE_STRING_GENERAL)

-- Status
is_valid: BOOLEAN
is_connected: BOOLEAN
is_server: BOOLEAN
has_data_available: BOOLEAN
last_error: detachable STRING_32

-- Platform Query
is_using_named_pipes: BOOLEAN
is_using_unix_socket: BOOLEAN
connection: IPC_CONNECTION  -- Access underlying connection

-- Server Operations
wait_for_connection (a_timeout_ms: INTEGER)
disconnect

-- Read Operations
read_bytes (a_count: INTEGER): ARRAY [NATURAL_8]
read_string (a_max_length: INTEGER): STRING_8
read_line: STRING_8

-- Write Operations
write_bytes (a_bytes: ARRAY [NATURAL_8])
write_string (a_string: READABLE_STRING_8)

-- Operations
close
```

### IPC_CONNECTION (Deferred Base)

The abstract interface implemented by all platform-specific connections. Use this type for polymorphic handling.

### NAMED_PIPE_CONNECTION (Windows)

Direct access to Windows Named Pipes. Same API as `SIMPLE_IPC`.

### UNIX_SOCKET_CONNECTION (Linux/macOS)

Unix domain socket implementation. Currently a stub - returns "not yet implemented" errors.

---

## Building & Testing

### Compile Library

```bash
cd simple_ipc
ec -config simple_ipc.ecf -target simple_ipc -c_compile
```

### Run Tests

```bash
ec -config simple_ipc.ecf -target simple_ipc_tests -c_compile
./EIFGENs/simple_ipc_tests/W_code/simple_ipc.exe
```

**Test Results:** 14 tests passing

---

## Project Structure

```
simple_ipc/
├── Clib/                           # C wrapper library
│   ├── simple_ipc.h                # Win32 pipe header
│   ├── simple_ipc.c                # Win32 pipe implementation
│   └── compile.bat                 # Build script
├── src/                            # Eiffel source
│   ├── simple_ipc.e                # Facade (platform detection)
│   ├── ipc_connection.e            # Deferred base class
│   ├── named_pipe_connection.e     # Windows implementation
│   └── unix_socket_connection.e    # Unix stub (Phase 2)
├── testing/                        # Test suite
│   ├── lib_tests.e                 # Test cases
│   └── test_app.e                  # Test runner
├── docs/                           # Documentation
│   └── index.html                  # API docs
├── simple_ipc.ecf                  # Library configuration
├── README.md                       # This file
├── CHANGELOG.md                    # Version history
└── LICENSE                         # MIT License
```

---

## Dependencies

- **EiffelStudio 23.09+** - Development environment
- **Windows:** Visual Studio C++ Build Tools (for C wrapper)
- **Linux/macOS:** GCC (for future Unix socket support)

---

## Roadmap

- [x] Windows Named Pipes (v1.0)
- [x] Cross-platform architecture (v2.0)
- [ ] Unix Domain Sockets (Phase 2)
- [ ] Connection pooling
- [ ] Async I/O support

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

## Contact

- **Author:** Larry Rix
- **Repository:** https://github.com/simple-eiffel/simple_ipc
- **Issues:** https://github.com/simple-eiffel/simple_ipc/issues

---

## Acknowledgments

- Built with Claude Opus 4.5 (Anthropic)
- Uses Win32 Named Pipe API (Microsoft)
- Part of the simple_ library collection for Eiffel
