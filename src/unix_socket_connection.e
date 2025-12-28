note
	description: "[
		Unix domain socket implementation of IPC_CONNECTION.
		Uses inline C for cross-platform socket operations.

		Platform: Linux, macOS (Unix-like systems)
		Transport: Unix domain sockets (/var/run/name.sock)

		Primarily used for:
		- Docker daemon communication (/var/run/docker.sock)
		- Inter-process communication on Unix systems
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	UNIX_SOCKET_CONNECTION

inherit
	IPC_CONNECTION

create
	make_server,
	make_client

feature {NONE} -- Initialization

	make_server (a_name: READABLE_STRING_GENERAL)
			-- Create a Unix socket server with `a_name'.
			-- Note: Server functionality not yet implemented.
		require
			name_not_empty: not a_name.is_empty
		do
			socket_path := a_name.to_string_8
			is_server_internal := True
			error_message := "Unix socket server not yet implemented"
		end

	make_client (a_name: READABLE_STRING_GENERAL)
			-- Connect to a Unix socket at `a_name'.
			-- `a_name' should be full path like "/var/run/docker.sock"
		require
			name_not_empty: not a_name.is_empty
		local
			l_path: STRING_8
			l_fd: INTEGER
		do
			l_path := a_name.to_string_8
			socket_path := l_path
			is_server_internal := False
			error_message := Void

			-- Create socket (returns -1 on Windows - not supported)
			l_fd := c_socket_create
			if l_fd < 0 then
				error_message := "Unix socket client not yet implemented"
			else
				socket_fd := l_fd
				-- Connect to server
				if c_socket_connect (socket_fd, l_path.area.base_address) /= 0 then
					error_message := "Failed to connect to Unix socket: " + l_path
					c_socket_close (socket_fd)
					socket_fd := 0
				else
					is_connected_internal := True
				end
			end
		ensure
			path_set: socket_path /= Void
		end

feature -- Status

	is_valid: BOOLEAN
			-- Is the socket handle valid?
		do
			Result := socket_fd > 0
		end

	is_connected: BOOLEAN
			-- Is the socket connected?
		do
			Result := is_valid and is_connected_internal
		end

	is_server: BOOLEAN
			-- Is this a server socket?
		do
			Result := is_server_internal
		end

	has_data_available: BOOLEAN
			-- Is data available to read?
		do
			if is_connected then
				Result := c_socket_has_data (socket_fd) > 0
			end
		end

	last_error: detachable STRING_32
			-- Error message from last failed operation.
		do
			if attached error_message as msg then
				Result := msg.to_string_32
			end
		end

feature -- Server Operations

	wait_for_connection (a_timeout_ms: INTEGER)
			-- Wait for a client to connect.
			-- Note: Server functionality not yet implemented.
		do
			last_wait_succeeded_internal := False
			error_message := "Unix socket server not yet implemented"
		end

	disconnect
			-- Disconnect from client and prepare for new connection.
			-- Note: Server functionality not yet implemented.
		do
			last_disconnect_succeeded_internal := False
			error_message := "Unix socket server not yet implemented"
		end

feature -- Read Operations

	read_bytes (a_count: INTEGER): ARRAY [NATURAL_8]
			-- Read up to `a_count' bytes from socket.
		local
			l_buffer: MANAGED_POINTER
			l_read: INTEGER
			i: INTEGER
		do
			create Result.make_empty
			last_read_count_internal := 0
			error_message := Void

			if is_connected and a_count > 0 then
				create l_buffer.make (a_count)
				l_read := c_socket_read (socket_fd, l_buffer.item, a_count)
				if l_read > 0 then
					last_read_count_internal := l_read
					create Result.make_filled (0, 1, l_read)
					from i := 0 until i >= l_read loop
						Result.put (l_buffer.read_natural_8 (i), i + 1)
						i := i + 1
					end
				elseif l_read < 0 then
					error_message := "Read error on Unix socket"
					is_connected_internal := False
				end
			end
		end

	read_string (a_max_length: INTEGER): STRING_8
			-- Read a string from socket (up to `a_max_length' bytes).
		local
			l_buffer: MANAGED_POINTER
			l_read: INTEGER
		do
			create Result.make_empty
			last_read_count_internal := 0
			error_message := Void

			if is_connected and a_max_length > 0 then
				create l_buffer.make (a_max_length)
				l_read := c_socket_read (socket_fd, l_buffer.item, a_max_length)
				if l_read > 0 then
					last_read_count_internal := l_read
					create Result.make (l_read)
					Result.from_c_substring (l_buffer.item, 1, l_read)
				elseif l_read < 0 then
					error_message := "Read error on Unix socket"
					is_connected_internal := False
				end
			end
		end

	read_line: STRING_8
			-- Read a line (until newline) from socket.
		local
			l_char_buffer: MANAGED_POINTER
			l_read: INTEGER
			l_char: CHARACTER
		do
			create Result.make (256)
			last_read_count_internal := 0
			error_message := Void

			if is_connected then
				create l_char_buffer.make (1)
				from
				until
					not is_connected or l_char = '%N'
				loop
					l_read := c_socket_read (socket_fd, l_char_buffer.item, 1)
					if l_read = 1 then
						l_char := l_char_buffer.read_character (0)
						if l_char /= '%N' then
							Result.append_character (l_char)
						end
						last_read_count_internal := last_read_count_internal + 1
					elseif l_read <= 0 then
						is_connected_internal := False
					end
				end
			end
		end

feature -- Write Operations

	write_bytes (a_bytes: ARRAY [NATURAL_8])
			-- Write `a_bytes' to socket.
		local
			l_buffer: MANAGED_POINTER
			l_written: INTEGER
			i: INTEGER
		do
			last_write_count_internal := 0
			error_message := Void

			if is_connected and a_bytes.count > 0 then
				create l_buffer.make (a_bytes.count)
				from i := a_bytes.lower until i > a_bytes.upper loop
					l_buffer.put_natural_8 (a_bytes [i], i - a_bytes.lower)
					i := i + 1
				end
				l_written := c_socket_write (socket_fd, l_buffer.item, a_bytes.count)
				if l_written > 0 then
					last_write_count_internal := l_written
				elseif l_written < 0 then
					error_message := "Write error on Unix socket"
					is_connected_internal := False
				end
			end
		end

	write_string (a_string: READABLE_STRING_8)
			-- Write `a_string' to socket.
		local
			l_written: INTEGER
			l_c_string: C_STRING
		do
			last_write_count_internal := 0
			error_message := Void

			if is_connected and a_string.count > 0 then
				create l_c_string.make (a_string)
				l_written := c_socket_write (socket_fd, l_c_string.item, a_string.count)
				if l_written > 0 then
					last_write_count_internal := l_written
				elseif l_written < 0 then
					error_message := "Write error on Unix socket"
					is_connected_internal := False
				end
			end
		end

feature -- Operations

	close
			-- Close and release the socket.
		do
			if socket_fd > 0 then
				c_socket_close (socket_fd)
				socket_fd := 0
			end
			is_connected_internal := False
			error_message := Void
		end

feature -- Status Report

	last_read_count: INTEGER
			-- Number of bytes read in last read operation.
		do
			Result := last_read_count_internal
		end

	last_write_count: INTEGER
			-- Number of bytes written in last write operation.
		do
			Result := last_write_count_internal
		end

	last_wait_succeeded: BOOLEAN
			-- Did the last wait_for_connection succeed?
		do
			Result := last_wait_succeeded_internal
		end

	last_disconnect_succeeded: BOOLEAN
			-- Did the last disconnect succeed?
		do
			Result := last_disconnect_succeeded_internal
		end

feature {NONE} -- Implementation

	socket_fd: INTEGER
			-- Unix socket file descriptor (0 = invalid/closed).

	socket_path: detachable STRING_8
			-- Path to the Unix socket.

	is_server_internal: BOOLEAN
			-- Is this a server socket?

	is_connected_internal: BOOLEAN
			-- Is the socket connected?

	error_message: detachable STRING_8
			-- Last error message.

	last_read_count_internal: INTEGER
			-- Internal storage for last read count.

	last_write_count_internal: INTEGER
			-- Internal storage for last write count.

	last_wait_succeeded_internal: BOOLEAN
			-- Internal storage for wait result.

	last_disconnect_succeeded_internal: BOOLEAN
			-- Internal storage for disconnect result.

feature {NONE} -- C Externals

	c_socket_create: INTEGER
			-- Create a Unix domain socket. Returns file descriptor or -1 on error.
			-- Returns -1 on Windows (not supported).
		external
			"C inline use %"unix_socket.h%""
		alias
			"[
				#if defined(EIF_WINDOWS) || defined(_WIN32)
					return -1;
				#else
					return socket(AF_UNIX, SOCK_STREAM, 0);
				#endif
			]"
		end

	c_socket_connect (a_fd: INTEGER; a_path: POINTER): INTEGER
			-- Connect socket to path. Returns 0 on success, -1 on error.
			-- Returns -1 on Windows (not supported).
		external
			"C inline use %"unix_socket.h%""
		alias
			"[
				#if defined(EIF_WINDOWS) || defined(_WIN32)
					return -1;
				#else
					{
					struct sockaddr_un addr;
					memset(&addr, 0, sizeof(addr));
					addr.sun_family = AF_UNIX;
					strncpy(addr.sun_path, (const char*)$a_path, sizeof(addr.sun_path) - 1);
					return connect($a_fd, (struct sockaddr*)&addr, sizeof(addr));
					}
				#endif
			]"
		end

	c_socket_read (a_fd: INTEGER; a_buffer: POINTER; a_size: INTEGER): INTEGER
			-- Read from socket. Returns bytes read, 0 for EOF, -1 on error.
			-- Returns -1 on Windows (not supported).
		external
			"C inline use %"unix_socket.h%""
		alias
			"[
				#if defined(EIF_WINDOWS) || defined(_WIN32)
					return -1;
				#else
					return read($a_fd, $a_buffer, $a_size);
				#endif
			]"
		end

	c_socket_write (a_fd: INTEGER; a_data: POINTER; a_size: INTEGER): INTEGER
			-- Write to socket. Returns bytes written, -1 on error.
			-- Returns -1 on Windows (not supported).
		external
			"C inline use %"unix_socket.h%""
		alias
			"[
				#if defined(EIF_WINDOWS) || defined(_WIN32)
					return -1;
				#else
					return write($a_fd, $a_data, $a_size);
				#endif
			]"
		end

	c_socket_close (a_fd: INTEGER)
			-- Close socket. No-op on Windows.
		external
			"C inline use %"unix_socket.h%""
		alias
			"[
				#if !defined(EIF_WINDOWS) && !defined(_WIN32)
					close($a_fd);
				#endif
			]"
		end

	c_socket_has_data (a_fd: INTEGER): INTEGER
			-- Check if data is available on socket. Returns 1 if data available, 0 if not, -1 on error.
			-- Returns -1 on Windows (not supported).
		external
			"C inline use %"unix_socket.h%""
		alias
			"[
				#if defined(EIF_WINDOWS) || defined(_WIN32)
					return -1;
				#else
					{
					fd_set fds;
					struct timeval tv;
					FD_ZERO(&fds);
					FD_SET($a_fd, &fds);
					tv.tv_sec = 0;
					tv.tv_usec = 0;
					return select($a_fd + 1, &fds, NULL, NULL, &tv);
					}
				#endif
			]"
		end

end
