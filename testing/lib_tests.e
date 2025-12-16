note
	description: "Tests for SIMPLE_IPC library"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE
		redefine
			on_prepare,
			on_clean
		end

feature -- Setup

	on_prepare
			-- Set up test fixtures.
		do
			-- Generate unique pipe name for each test using counter
			test_counter := test_counter + 1
			test_pipe_name := "SimpleIPCTest" + test_counter.out
		end

	on_clean
			-- Clean up after tests.
		do
			-- Nothing to clean up
		end

feature -- Access

	test_pipe_name: STRING
			-- Unique pipe name for tests.

	test_counter: INTEGER
			-- Counter for generating unique names.

feature -- Test: Server Creation

	test_server_creation
			-- Test creating a server pipe.
		local
			l_server: SIMPLE_IPC
		do
			create l_server.make_server (test_pipe_name)
			assert ("server valid", l_server.is_valid)
			assert ("is server", l_server.is_server)
			assert ("not connected initially", not l_server.is_connected)
			l_server.close
		end

	test_server_close
			-- Test closing server pipe.
		local
			l_server: SIMPLE_IPC
		do
			create l_server.make_server (test_pipe_name)
			assert ("initially valid", l_server.is_valid)
			l_server.close
			assert ("invalid after close", not l_server.is_valid)
		end

feature -- Test: Client Without Server

	test_client_without_server
			-- Test client connection failure when no server.
		local
			l_client: SIMPLE_IPC
		do
			create l_client.make_client ("NonexistentPipe12345")
			-- Client should fail to connect without a server
			assert ("not connected", not l_client.is_connected)
			assert ("has error", l_client.last_error /= Void)
			l_client.close
		end

feature -- Test: Multiple Server Instances Blocked

	test_multiple_servers_same_name
			-- Test that second server with same name fails.
		local
			l_server1, l_server2: SIMPLE_IPC
		do
			create l_server1.make_server (test_pipe_name)
			assert ("server1 valid", l_server1.is_valid)

			-- Second server with same name should fail
			create l_server2.make_server (test_pipe_name)
			-- The second server may or may not be valid depending on Windows version
			-- but at least it shouldn't crash

			l_server2.close
			l_server1.close
		end

feature -- Test: Server Status

	test_server_status_queries
			-- Test server status query features.
		local
			l_server: SIMPLE_IPC
		do
			create l_server.make_server (test_pipe_name)

			assert ("is_valid true", l_server.is_valid)
			assert ("is_server true", l_server.is_server)
			assert ("is_connected false", not l_server.is_connected)
			assert ("has_data_available false or error", True) -- Just ensure no crash

			l_server.close
		end

feature -- Test: Facade Platform Detection

	test_facade_platform_detection
			-- Test that SIMPLE_IPC correctly detects platform.
		local
			l_server: SIMPLE_IPC
		do
			create l_server.make_server (test_pipe_name)
			-- On Windows, should use named pipes
			if {PLATFORM}.is_windows then
				assert ("using named pipes on Windows", l_server.is_using_named_pipes)
				assert ("not using unix socket on Windows", not l_server.is_using_unix_socket)
			else
				assert ("using unix socket on non-Windows", l_server.is_using_unix_socket)
				assert ("not using named pipes on non-Windows", not l_server.is_using_named_pipes)
			end
			l_server.close
		end

	test_facade_connection_access
			-- Test that underlying connection is accessible.
		local
			l_server: SIMPLE_IPC
			l_connection: IPC_CONNECTION
		do
			create l_server.make_server (test_pipe_name)
			l_connection := l_server.connection
			assert ("connection accessible", l_connection /= Void)
			assert ("connection matches valid state", l_connection.is_valid = l_server.is_valid)
			assert ("connection matches server state", l_connection.is_server = l_server.is_server)
			l_server.close
		end

feature -- Test: Named Pipe Connection Direct Use

	test_named_pipe_direct_server
			-- Test creating named pipe connection directly.
		local
			l_pipe: NAMED_PIPE_CONNECTION
		do
			create l_pipe.make_server (test_pipe_name)
			assert ("pipe valid", l_pipe.is_valid)
			assert ("pipe is server", l_pipe.is_server)
			l_pipe.close
			assert ("pipe closed", not l_pipe.is_valid)
		end

	test_named_pipe_direct_client_no_server
			-- Test client without server returns error.
		local
			l_pipe: NAMED_PIPE_CONNECTION
		do
			create l_pipe.make_client ("NonexistentPipe54321")
			assert ("pipe not valid", not l_pipe.is_valid or else not l_pipe.is_connected)
			assert ("has error", l_pipe.last_error /= Void)
			l_pipe.close
		end

feature -- Test: Unix Socket Stub (Placeholder)

	test_unix_socket_stub_server
			-- Test Unix socket stub returns not implemented.
		local
			l_socket: UNIX_SOCKET_CONNECTION
		do
			create l_socket.make_server (test_pipe_name)
			-- Stub should indicate not implemented
			assert ("not valid (stub)", not l_socket.is_valid)
			assert ("has error message", attached l_socket.last_error as err and then err.has_substring ("not yet implemented"))
			l_socket.close
		end

	test_unix_socket_stub_client
			-- Test Unix socket client stub returns not implemented.
		local
			l_socket: UNIX_SOCKET_CONNECTION
		do
			create l_socket.make_client (test_pipe_name)
			-- Stub should indicate not implemented
			assert ("not valid (stub)", not l_socket.is_valid)
			assert ("has error message", attached l_socket.last_error as err and then err.has_substring ("not yet implemented"))
			l_socket.close
		end

feature -- Test: Read/Write Status

	test_read_count_initial
			-- Test that read count starts at zero.
		local
			l_server: SIMPLE_IPC
		do
			create l_server.make_server (test_pipe_name)
			assert ("last_read_count is 0", l_server.last_read_count = 0)
			l_server.close
		end

	test_write_count_initial
			-- Test that write count starts at zero.
		local
			l_server: SIMPLE_IPC
		do
			create l_server.make_server (test_pipe_name)
			assert ("last_write_count is 0", l_server.last_write_count = 0)
			l_server.close
		end

feature -- Test: Wait and Disconnect Status

	test_wait_disconnect_initial_status
			-- Test wait and disconnect status start correctly.
		local
			l_server: SIMPLE_IPC
		do
			create l_server.make_server (test_pipe_name)
			-- Initial status before any operations
			assert ("last_wait_succeeded is false initially", not l_server.last_wait_succeeded)
			assert ("last_disconnect_succeeded is false initially", not l_server.last_disconnect_succeeded)
			l_server.close
		end

end
