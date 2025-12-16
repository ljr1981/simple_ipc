note
	description: "Test application for simple_ipc"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

create
	make

feature -- Initialization

	make
			-- Run tests.
		local
			l_tests: LIB_TESTS
			l_passed, l_failed: INTEGER
		do
			print ("Testing SIMPLE_IPC v2.0.0...%N%N")

			create l_tests

			-- Original tests
			l_passed := l_passed + run_test (l_tests, "test_server_creation", agent l_tests.test_server_creation)
			l_passed := l_passed + run_test (l_tests, "test_server_close", agent l_tests.test_server_close)
			l_passed := l_passed + run_test (l_tests, "test_client_without_server", agent l_tests.test_client_without_server)
			l_passed := l_passed + run_test (l_tests, "test_multiple_servers_same_name", agent l_tests.test_multiple_servers_same_name)
			l_passed := l_passed + run_test (l_tests, "test_server_status_queries", agent l_tests.test_server_status_queries)

			-- Facade tests
			l_passed := l_passed + run_test (l_tests, "test_facade_platform_detection", agent l_tests.test_facade_platform_detection)
			l_passed := l_passed + run_test (l_tests, "test_facade_connection_access", agent l_tests.test_facade_connection_access)

			-- Named pipe direct tests
			l_passed := l_passed + run_test (l_tests, "test_named_pipe_direct_server", agent l_tests.test_named_pipe_direct_server)
			l_passed := l_passed + run_test (l_tests, "test_named_pipe_direct_client_no_server", agent l_tests.test_named_pipe_direct_client_no_server)

			-- Unix socket stub tests
			l_passed := l_passed + run_test (l_tests, "test_unix_socket_stub_server", agent l_tests.test_unix_socket_stub_server)
			l_passed := l_passed + run_test (l_tests, "test_unix_socket_stub_client", agent l_tests.test_unix_socket_stub_client)

			-- Status tests
			l_passed := l_passed + run_test (l_tests, "test_read_count_initial", agent l_tests.test_read_count_initial)
			l_passed := l_passed + run_test (l_tests, "test_write_count_initial", agent l_tests.test_write_count_initial)
			l_passed := l_passed + run_test (l_tests, "test_wait_disconnect_initial_status", agent l_tests.test_wait_disconnect_initial_status)

			l_failed := 14 - l_passed

			print ("%N======================================%N")
			print ("Results: " + l_passed.out + " passed, " + l_failed.out + " failed%N")
		end

feature {NONE} -- Implementation

	run_test (a_tests: LIB_TESTS; a_name: STRING; a_test: PROCEDURE): INTEGER
			-- Run a single test. Return 1 if passed, 0 if failed.
		do
			print ("  " + a_name + ": ")
			a_tests.on_prepare
			a_test.call (Void)
			a_tests.on_clean
			print ("PASSED%N")
			Result := 1
		rescue
			print ("FAILED%N")
			Result := 0
			a_tests.on_clean
			retry
		end

end
