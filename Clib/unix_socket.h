/*
 * unix_socket.h - Platform-aware Unix socket headers
 *
 * On Windows: provides stub types so code compiles (but returns -1)
 * On Unix: includes actual socket headers
 */

#ifndef UNIX_SOCKET_H
#define UNIX_SOCKET_H

#if defined(EIF_WINDOWS) || defined(_WIN32)
    /* Windows stubs - Unix sockets not supported */
    #define AF_UNIX 1
    struct sockaddr_un { int sun_family; char sun_path[108]; };
    struct sockaddr { int dummy; };
#else
    /* Unix - include actual headers */
    #include <sys/socket.h>
    #include <sys/un.h>
    #include <sys/select.h>
    #include <sys/time.h>
    #include <unistd.h>
#endif

#include <string.h>

#endif /* UNIX_SOCKET_H */
