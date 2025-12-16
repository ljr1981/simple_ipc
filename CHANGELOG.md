# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2025-12-15

### Added
- Cross-platform architecture with platform-specific transports
- `IPC_CONNECTION` deferred base class defining common API
- `NAMED_PIPE_CONNECTION` class for Windows named pipes
- `UNIX_SOCKET_CONNECTION` stub for future Unix socket support
- Platform detection in `SIMPLE_IPC` facade
- `is_using_named_pipes` and `is_using_unix_socket` query features
- `connection` attribute for direct access to underlying transport
- 9 new tests (14 total)

### Changed
- `SIMPLE_IPC` refactored from implementation to facade pattern
- ECF description updated for cross-platform support
- README updated with new architecture documentation

### Backward Compatibility
- All existing `SIMPLE_IPC` API preserved
- Existing code compiles without modification
- Behavior unchanged on Windows

## [1.0.0] - 2025-12-08

### Added
- Initial release
- Windows Named Pipe IPC implementation
- Server and client modes
- String and binary read/write operations
- Connection management (wait, disconnect, close)
- SCOOP compatibility
- Test suite with 5 tests
- Documentation and examples

[Unreleased]: https://github.com/simple-eiffel/simple_ipc/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/simple-eiffel/simple_ipc/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/simple-eiffel/simple_ipc/releases/tag/v1.0.0
