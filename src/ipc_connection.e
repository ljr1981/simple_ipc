note
	description: "[
		Deferred base class for IPC connections.

		Defines the common API for inter-process communication,
		implemented by platform-specific descendants:
		- NAMED_PIPE_CONNECTION (Windows)
		- UNIX_SOCKET_CONNECTION (Linux/macOS)

		Design Pattern: Template Method
		The base class defines the interface; descendants implement
		platform-specific communication mechanisms.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	IPC_CONNECTION

feature -- Status

	is_valid: BOOLEAN
			-- Is the connection handle valid?
		deferred
		end

	is_connected: BOOLEAN
			-- Is the connection established?
		deferred
		end

	is_server: BOOLEAN
			-- Is this a server connection?
		deferred
		end

	has_data_available: BOOLEAN
			-- Is data available to read?
		require
			valid: is_valid
		deferred
		end

	last_error: detachable STRING_32
			-- Error message from last failed operation.
		deferred
		end

feature -- Server Operations

	wait_for_connection (a_timeout_ms: INTEGER)
			-- Wait for a client to connect.
			-- If `a_timeout_ms' <= 0, wait indefinitely.
			-- Check `last_wait_succeeded' for result.
		require
			valid: is_valid
			server: is_server
		deferred
		ensure
			result_set: True -- last_wait_succeeded is set
		end

	disconnect
			-- Disconnect from client and prepare for new connection.
		require
			valid: is_valid
			server: is_server
		deferred
		ensure
			result_set: True -- last_disconnect_succeeded is set
		end

feature -- Read Operations

	read_bytes (a_count: INTEGER): ARRAY [NATURAL_8]
			-- Read up to `a_count' bytes from connection.
		require
			valid: is_valid
			connected: is_connected
			positive_count: a_count > 0
		deferred
		ensure
			result_exists: Result /= Void
			count_set: last_read_count >= 0
		end

	read_string (a_max_length: INTEGER): STRING_8
			-- Read a string from connection (up to `a_max_length' bytes).
		require
			valid: is_valid
			connected: is_connected
			positive_length: a_max_length > 0
		deferred
		ensure
			result_exists: Result /= Void
		end

	read_line: STRING_8
			-- Read a line from connection (up to newline).
		require
			valid: is_valid
			connected: is_connected
		deferred
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
		deferred
		ensure
			count_set: last_write_count >= 0
		end

	write_string (a_string: READABLE_STRING_8)
			-- Write `a_string' to connection.
		require
			valid: is_valid
			connected: is_connected
			string_not_empty: not a_string.is_empty
		deferred
		ensure
			count_set: last_write_count >= 0
		end

feature -- Operations

	close
			-- Close and release the connection.
		deferred
		ensure
			closed: not is_valid
		end

feature -- Status Report

	last_read_count: INTEGER
			-- Number of bytes read in last read operation.
		deferred
		end

	last_write_count: INTEGER
			-- Number of bytes written in last write operation.
		deferred
		end

	last_wait_succeeded: BOOLEAN
			-- Did the last wait_for_connection succeed?
		deferred
		end

	last_disconnect_succeeded: BOOLEAN
			-- Did the last disconnect succeed?
		deferred
		end

end
