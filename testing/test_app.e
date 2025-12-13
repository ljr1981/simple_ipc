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
			print ("Testing SIMPLE_IPC...%N%N")

			create l_tests

			-- Test: Server creation
			print ("  test_server_creation: ")
			l_tests.on_prepare
			l_tests.test_server_creation
			l_tests.on_clean
			print ("PASSED%N")
			l_passed := l_passed + 1

			-- Test: Server close
			print ("  test_server_close: ")
			l_tests.on_prepare
			l_tests.test_server_close
			l_tests.on_clean
			print ("PASSED%N")
			l_passed := l_passed + 1

			-- Test: Client without server
			print ("  test_client_without_server: ")
			l_tests.on_prepare
			l_tests.test_client_without_server
			l_tests.on_clean
			print ("PASSED%N")
			l_passed := l_passed + 1

			-- Test: Multiple servers same name
			print ("  test_multiple_servers_same_name: ")
			l_tests.on_prepare
			l_tests.test_multiple_servers_same_name
			l_tests.on_clean
			print ("PASSED%N")
			l_passed := l_passed + 1

			-- Test: Server status queries
			print ("  test_server_status_queries: ")
			l_tests.on_prepare
			l_tests.test_server_status_queries
			l_tests.on_clean
			print ("PASSED%N")
			l_passed := l_passed + 1

			print ("%N======================================%N")
			print ("Results: " + l_passed.out + " passed, " + l_failed.out + " failed%N")
		rescue
			print ("FAILED%N")
			l_failed := l_failed + 1
			retry
		end

end
