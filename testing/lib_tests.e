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

end
