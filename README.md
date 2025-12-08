<p align="center">
  <img src="https://raw.githubusercontent.com/ljr1981/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# SIMPLE_IPC

**[Documentation](https://simple-eiffel.github.io/simple_ipc/)**

### Named Pipe IPC Library for Eiffel

[![Language](https://img.shields.io/badge/language-Eiffel-blue.svg)](https://www.eiffel.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)]()
[![SCOOP](https://img.shields.io/badge/SCOOP-compatible-orange.svg)]()
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()
[![Tests](https://img.shields.io/badge/tests-5%20passing-brightgreen.svg)]()

---

## Overview

SIMPLE_IPC provides SCOOP-compatible inter-process communication via Windows Named Pipes for Eiffel applications. It wraps the Win32 Named Pipe API (CreateNamedPipe, ConnectNamedPipe, CreateFile, etc.) through a clean C interface, enabling IPC without threading complications.

The library supports both server and client pipe operations, with read/write capabilities for text and binary data, making it ideal for local service communication and process coordination.

**Developed using AI-assisted methodology:** Built interactively with Claude Opus 4.5 following rigorous Design by Contract principles.

---

## Features

### Pipe Operations

- **Server Mode** - Create named pipes and wait for client connections
- **Client Mode** - Connect to existing named pipes
- **Read/Write** - Send and receive string and binary data
- **Connection Management** - Disconnect and reconnect capabilities

### Pipe Modes

| Mode | Description |
|------|-------------|
| Server | Creates pipe and waits for connections |
| Client | Connects to existing pipe |

### Data Operations

| Operation | Description |
|-----------|-------------|
| `read` | Read string data from pipe |
| `write` | Write string data to pipe |
| `read_bytes` | Read binary data |
| `write_bytes` | Write binary data |

---

## Quick Start

### Installation

1. Clone the repository:
```bash
git clone https://github.com/simple-eiffel/simple_ipc.git
```

2. Compile the C library:
```bash
cd simple_ipc/Clib
compile.bat
```

3. Set the environment variable:
```bash
set SIMPLE_IPC=D:\path\to\simple_ipc
```

4. Add to your ECF file:
```xml
<library name="simple_ipc" location="$SIMPLE_IPC\simple_ipc.ecf"/>
```

### Basic Usage

#### Server Side

```eiffel
class
    MY_SERVER

feature

    start_server
        local
            pipe: SIMPLE_IPC
        do
            -- Create named pipe server
            create pipe.make_server ("MyPipe")

            if pipe.is_valid then
                print ("Waiting for client...%N")
                pipe.wait_for_connection

                if pipe.is_connected then
                    -- Read from client
                    if attached pipe.read as msg then
                        print ("Received: " + msg + "%N")
                    end

                    -- Send response
                    pipe.write ("Hello from server!")
                end

                pipe.close
            end
        end

end
```

#### Client Side

```eiffel
class
    MY_CLIENT

feature

    connect_to_server
        local
            pipe: SIMPLE_IPC
        do
            -- Connect to named pipe
            create pipe.make_client ("MyPipe")

            if pipe.is_valid then
                -- Send message
                pipe.write ("Hello from client!")

                -- Read response
                if attached pipe.read as response then
                    print ("Server says: " + response + "%N")
                end

                pipe.close
            end
        end

end
```

---

## API Reference

### SIMPLE_IPC Class

#### Creation

```eiffel
make_server (a_name: STRING_8)
    -- Create named pipe server with given name.
    -- Pipe name will be: \\.\pipe\<a_name>

make_client (a_name: STRING_8)
    -- Connect to existing named pipe.
```

#### Connection Management

```eiffel
wait_for_connection
    -- Wait for client to connect (server mode).

disconnect
    -- Disconnect current client, allow new connection.

close
    -- Close pipe and release resources.
```

#### Reading Data

```eiffel
read: detachable STRING_8
    -- Read string from pipe.
    -- Returns Void if no data or error.

read_bytes (a_count: INTEGER): detachable ARRAY [NATURAL_8]
    -- Read up to a_count bytes from pipe.
```

#### Writing Data

```eiffel
write (a_data: STRING_8): BOOLEAN
    -- Write string to pipe.
    -- Returns True if successful.

write_bytes (a_data: ARRAY [NATURAL_8]): BOOLEAN
    -- Write bytes to pipe.
```

#### Status Queries

```eiffel
is_valid: BOOLEAN
    -- Is the pipe valid?

is_connected: BOOLEAN
    -- Is a client connected? (server mode)

is_server: BOOLEAN
    -- Is this a server pipe?

pipe_name: STRING_8
    -- Full pipe name (\\.\pipe\...)
```

---

## Building & Testing

### Build Library

```bash
cd simple_ipc
ec -config simple_ipc.ecf -target simple_ipc -c_compile
```

### Run Tests

```bash
ec -config simple_ipc.ecf -target simple_ipc_tests -c_compile
./EIFGENs/simple_ipc_tests/W_code/simple_ipc.exe
```

**Test Results:** 5 tests passing

---

## Project Structure

```
simple_ipc/
├── Clib/                       # C wrapper library
│   ├── simple_ipc.h            # C header file
│   ├── simple_ipc.c            # C implementation
│   └── compile.bat             # Build script
├── src/                        # Eiffel source
│   └── simple_ipc.e            # Main wrapper class
├── testing/                    # Test suite
│   ├── application.e           # Test runner
│   └── test_simple_ipc.e       # Test cases
├── simple_ipc.ecf              # Library configuration
├── README.md                   # This file
└── LICENSE                     # MIT License
```

---

## Dependencies

- **Windows OS** - Named Pipes are Windows-specific
- **EiffelStudio 23.09+** - Development environment
- **Visual Studio C++ Build Tools** - For compiling C wrapper

---

## SCOOP Compatibility

SIMPLE_IPC is fully SCOOP-compatible. The C wrapper handles all Win32 API calls synchronously without threading dependencies, making it safe for use in concurrent Eiffel applications.

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
