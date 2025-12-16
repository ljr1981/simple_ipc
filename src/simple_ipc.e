note
	description: "[
		SCOOP-compatible inter-process communication facade.

		Platform-aware factory that creates the appropriate connection:
		- Windows: Named pipes via NAMED_PIPE_CONNECTION
		- Linux/macOS: Unix sockets via UNIX_SOCKET_CONNECTION (future)

		Maintains backward compatibility with previous SIMPLE_IPC API.
		All consumers can continue using SIMPLE_IPC without changes.

		Usage:
			create ipc.make_server ("my_service")
			create ipc.make_client ("my_service")
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_IPC

create
	make_server,
	make_client

feature {NONE} -- Initialization

	make_server (a_name: READABLE_STRING_GENERAL)
			-- Create an IPC server with `a_name'.
			-- Uses platform-appropriate transport.
		require
			name_not_empty: not a_name.is_empty
		do
			if {PLATFORM}.is_windows then
				create {NAMED_PIPE_CONNECTION} connection.make_server (a_name)
			else
				-- Unix socket (future implementation)
				create {UNIX_SOCKET_CONNECTION} connection.make_server (a_name)
			end
		ensure
			connection_created: connection /= Void
		end

	make_client (a_name: READABLE_STRING_GENERAL)
			-- Connect to an IPC server with `a_name'.
			-- Uses platform-appropriate transport.
		require
			name_not_empty: not a_name.is_empty
		do
			if {PLATFORM}.is_windows then
				create {NAMED_PIPE_CONNECTION} connection.make_client (a_name)
			else
				-- Unix socket (future implementation)
				create {UNIX_SOCKET_CONNECTION} connection.make_client (a_name)
			end
		ensure
			connection_created: connection /= Void
		end

feature -- Access

	connection: IPC_CONNECTION
			-- Underlying platform-specific connection.
			-- Allows advanced users to access platform-specific features.

feature -- Status

	is_valid: BOOLEAN
			-- Is the connection handle valid?
		do
			Result := connection.is_valid
		end

	is_connected: BOOLEAN
			-- Is the connection established?
		do
			Result := connection.is_connected
		end

	is_server: BOOLEAN
			-- Is this a server connection?
		do
			Result := connection.is_server
		end

	has_data_available: BOOLEAN
			-- Is data available to read?
		require
			valid: is_valid
		do
			Result := connection.has_data_available
		end

	last_error: detachable STRING_32
			-- Error message from last failed operation.
		do
			Result := connection.last_error
		end

feature -- Server Operations

	wait_for_connection (a_timeout_ms: INTEGER)
			-- Wait for a client to connect.
			-- If `a_timeout_ms' <= 0, wait indefinitely.
			-- Check `last_wait_succeeded' for result.
		require
			valid: is_valid
			server: is_server
		do
			connection.wait_for_connection (a_timeout_ms)
		end

	disconnect
			-- Disconnect from client and prepare for new connection.
		require
			valid: is_valid
			server: is_server
		do
			connection.disconnect
		end

feature -- Read Operations

	read_bytes (a_count: INTEGER): ARRAY [NATURAL_8]
			-- Read up to `a_count' bytes from connection.
		require
			valid: is_valid
			connected: is_connected
			positive_count: a_count > 0
		do
			Result := connection.read_bytes (a_count)
		ensure
			result_exists: Result /= Void
		end

	read_string (a_max_length: INTEGER): STRING_8
			-- Read a string from connection (up to `a_max_length' bytes).
		require
			valid: is_valid
			connected: is_connected
			positive_length: a_max_length > 0
		do
			Result := connection.read_string (a_max_length)
		ensure
			result_exists: Result /= Void
		end

	read_line: STRING_8
			-- Read a line from connection (up to newline).
		require
			valid: is_valid
			connected: is_connected
		do
			Result := connection.read_line
		ensure
			result_exists: Result /= Void
		end

feature -- Write Operations

	write_bytes (a_bytes: ARRAY [NATURAL_8])
			-- Write `a_bytes' to connection.
		require
			valid: is_valid
			connected: is_connected
			bytes_not_empty: not a_bytes.is_empty
		do
			connection.write_bytes (a_bytes)
		end

	write_string (a_string: READABLE_STRING_8)
			-- Write `a_string' to connection.
		require
			valid: is_valid
			connected: is_connected
			string_not_empty: not a_string.is_empty
		do
			connection.write_string (a_string)
		end

feature -- Operations

	close
			-- Close and release the connection.
		do
			connection.close
		ensure
			closed: not is_valid
		end

feature -- Status Report

	last_read_count: INTEGER
			-- Number of bytes read in last read operation.
		do
			Result := connection.last_read_count
		end

	last_write_count: INTEGER
			-- Number of bytes written in last write operation.
		do
			Result := connection.last_write_count
		end

	last_wait_succeeded: BOOLEAN
			-- Did the last wait_for_connection succeed?
		do
			Result := connection.last_wait_succeeded
		end

	last_disconnect_succeeded: BOOLEAN
			-- Did the last disconnect succeed?
		do
			Result := connection.last_disconnect_succeeded
		end

feature -- Platform Query

	is_using_named_pipes: BOOLEAN
			-- Is this connection using Windows named pipes?
		do
			Result := attached {NAMED_PIPE_CONNECTION} connection
		end

	is_using_unix_socket: BOOLEAN
			-- Is this connection using Unix domain sockets?
		do
			Result := attached {UNIX_SOCKET_CONNECTION} connection
		end

invariant
	connection_exists: connection /= Void

end
