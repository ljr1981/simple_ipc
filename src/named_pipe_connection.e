note
	description: "[
		Windows named pipe implementation of IPC_CONNECTION.
		Uses direct Win32 API calls via C wrapper.

		Platform: Windows only
		Transport: Named pipes (\\.\pipe\name)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	NAMED_PIPE_CONNECTION

inherit
	IPC_CONNECTION

create
	make_server,
	make_client

feature {NONE} -- Initialization

	make_server (a_name: READABLE_STRING_GENERAL)
			-- Create a named pipe server with `a_name'.
			-- The name will be converted to "\\.\pipe\a_name".
		require
			name_not_empty: not a_name.is_empty
		local
			l_full_name: POINTER
			l_name: C_STRING
		do
			create l_name.make (a_name.to_string_8)
			l_full_name := c_sipc_make_pipe_name (l_name.item)
			if l_full_name /= default_pointer then
				handle := c_sipc_create_server (l_full_name)
				c_free (l_full_name)
			end
		end

	make_client (a_name: READABLE_STRING_GENERAL)
			-- Connect to a named pipe server with `a_name'.
			-- The name will be converted to "\\.\pipe\a_name".
		require
			name_not_empty: not a_name.is_empty
		local
			l_full_name: POINTER
			l_name: C_STRING
		do
			create l_name.make (a_name.to_string_8)
			l_full_name := c_sipc_make_pipe_name (l_name.item)
			if l_full_name /= default_pointer then
				handle := c_sipc_connect_client (l_full_name)
				c_free (l_full_name)
			end
		end

feature -- Status

	is_valid: BOOLEAN
			-- Is the pipe handle valid?
		do
			Result := handle /= default_pointer
		end

	is_connected: BOOLEAN
			-- Is the pipe connected?
		do
			Result := handle /= default_pointer and then c_sipc_is_connected (handle) /= 0
		end

	is_server: BOOLEAN
			-- Is this a server pipe?
		do
			Result := handle /= default_pointer and then c_sipc_is_server (handle) /= 0
		end

	has_data_available: BOOLEAN
			-- Is data available to read?
		do
			Result := c_sipc_data_available (handle) = 1
		end

	last_error: detachable STRING_32
			-- Error message from last failed operation.
		local
			l_ptr: POINTER
			l_c_string: C_STRING
		do
			if handle /= default_pointer then
				l_ptr := c_sipc_get_error (handle)
				if l_ptr /= default_pointer then
					create l_c_string.make_by_pointer (l_ptr)
					Result := l_c_string.string.to_string_32
				end
			end
		end

feature -- Server Operations

	wait_for_connection (a_timeout_ms: INTEGER)
			-- Wait for a client to connect.
			-- If `a_timeout_ms' <= 0, wait indefinitely.
			-- Check `last_wait_succeeded' for result.
		do
			last_wait_succeeded_internal := c_sipc_wait_for_connection (handle, a_timeout_ms) /= 0
		end

	disconnect
			-- Disconnect from client and prepare for new connection.
		do
			last_disconnect_succeeded_internal := c_sipc_disconnect (handle) /= 0
		end

feature -- Read Operations

	read_bytes (a_count: INTEGER): ARRAY [NATURAL_8]
			-- Read up to `a_count' bytes from pipe.
		local
			l_managed: MANAGED_POINTER
			l_read, i: INTEGER
		do
			create l_managed.make (a_count)
			l_read := c_sipc_read (handle, l_managed.item, a_count)
			if l_read > 0 then
				create Result.make_filled (0, 1, l_read)
				from i := 0 until i >= l_read loop
					Result.put (l_managed.read_natural_8 (i), i + 1)
					i := i + 1
				end
			else
				create Result.make_empty
			end
			last_read_count_internal := l_read.max (0)
		end

	read_string (a_max_length: INTEGER): STRING_8
			-- Read a string from pipe (up to `a_max_length' bytes).
		local
			l_bytes: ARRAY [NATURAL_8]
			i: INTEGER
		do
			l_bytes := read_bytes (a_max_length)
			create Result.make (l_bytes.count)
			from i := 1 until i > l_bytes.count loop
				Result.append_character (l_bytes.item (i).to_character_8)
				i := i + 1
			end
		end

	read_line: STRING_8
			-- Read a line from pipe (up to newline).
		local
			l_managed: MANAGED_POINTER
			l_read: INTEGER
		do
			create l_managed.make (4096)
			l_read := c_sipc_read_line (handle, l_managed.item, 4096)
			if l_read > 0 then
				create Result.make (l_read)
				Result.from_c_substring (l_managed.item, 1, l_read)
			else
				create Result.make_empty
			end
			last_read_count_internal := l_read.max (0)
		end

feature -- Write Operations

	write_bytes (a_bytes: ARRAY [NATURAL_8])
			-- Write `a_bytes' to pipe.
		local
			l_managed: MANAGED_POINTER
			i: INTEGER
		do
			create l_managed.make (a_bytes.count)
			from i := a_bytes.lower until i > a_bytes.upper loop
				l_managed.put_natural_8 (a_bytes.item (i), i - a_bytes.lower)
				i := i + 1
			end
			last_write_count_internal := c_sipc_write (handle, l_managed.item, a_bytes.count)
		end

	write_string (a_string: READABLE_STRING_8)
			-- Write `a_string' to pipe.
		local
			l_c_string: C_STRING
		do
			create l_c_string.make (a_string)
			last_write_count_internal := c_sipc_write_string (handle, l_c_string.item)
		end

feature -- Operations

	close
			-- Close and release the pipe.
		do
			if handle /= default_pointer then
				c_sipc_close (handle)
				handle := default_pointer
			end
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

	handle: POINTER
			-- C handle to the pipe.

	last_read_count_internal: INTEGER
			-- Internal storage for last read count.

	last_write_count_internal: INTEGER
			-- Internal storage for last write count.

	last_wait_succeeded_internal: BOOLEAN
			-- Internal storage for wait result.

	last_disconnect_succeeded_internal: BOOLEAN
			-- Internal storage for disconnect result.

feature {NONE} -- C Externals

	c_sipc_make_pipe_name (a_name: POINTER): POINTER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_make_pipe_name((const char*)$a_name);"
		end

	c_sipc_create_server (a_name: POINTER): POINTER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_create_server((const char*)$a_name);"
		end

	c_sipc_connect_client (a_name: POINTER): POINTER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_connect_client((const char*)$a_name);"
		end

	c_sipc_wait_for_connection (a_handle: POINTER; a_timeout: INTEGER): INTEGER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_wait_for_connection((sipc_pipe*)$a_handle, $a_timeout);"
		end

	c_sipc_disconnect (a_handle: POINTER): INTEGER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_disconnect((sipc_pipe*)$a_handle);"
		end

	c_sipc_read (a_handle: POINTER; a_buffer: POINTER; a_size: INTEGER): INTEGER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_read((sipc_pipe*)$a_handle, $a_buffer, $a_size);"
		end

	c_sipc_write (a_handle: POINTER; a_data: POINTER; a_size: INTEGER): INTEGER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_write((sipc_pipe*)$a_handle, $a_data, $a_size);"
		end

	c_sipc_read_line (a_handle: POINTER; a_buffer: POINTER; a_size: INTEGER): INTEGER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_read_line((sipc_pipe*)$a_handle, $a_buffer, $a_size);"
		end

	c_sipc_write_string (a_handle: POINTER; a_str: POINTER): INTEGER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_write_string((sipc_pipe*)$a_handle, (const char*)$a_str);"
		end

	c_sipc_data_available (a_handle: POINTER): INTEGER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_data_available((sipc_pipe*)$a_handle);"
		end

	c_sipc_is_connected (a_handle: POINTER): INTEGER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_is_connected((sipc_pipe*)$a_handle);"
		end

	c_sipc_is_server (a_handle: POINTER): INTEGER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return sipc_is_server((sipc_pipe*)$a_handle);"
		end

	c_sipc_get_error (a_handle: POINTER): POINTER
		external
			"C inline use %"simple_ipc.h%""
		alias
			"return (char*)sipc_get_error((sipc_pipe*)$a_handle);"
		end

	c_sipc_close (a_handle: POINTER)
		external
			"C inline use %"simple_ipc.h%""
		alias
			"sipc_close((sipc_pipe*)$a_handle);"
		end

	c_free (a_ptr: POINTER)
		external
			"C inline use <stdlib.h>"
		alias
			"free($a_ptr);"
		end

invariant
	handle_default_implies_not_connected: handle = default_pointer implies not is_connected

end
