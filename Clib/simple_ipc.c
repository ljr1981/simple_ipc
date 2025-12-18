/*
 * simple_ipc.c - Inter-process communication for Eiffel (Named Pipes)
 * Copyright (c) 2025 Larry Rix - MIT License
 */

#include "simple_ipc.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#if defined(_WIN32) || defined(EIF_WINDOWS)

#define PIPE_BUFFER_SIZE 4096

static char last_error_msg[512] = {0};

static void store_last_error(void) {
    DWORD err = GetLastError();
    FormatMessageA(
        FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL, err,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        last_error_msg, sizeof(last_error_msg) - 1, NULL
    );
}

static sipc_pipe* create_pipe_struct(void) {
    sipc_pipe* p = (sipc_pipe*)malloc(sizeof(sipc_pipe));
    if (p) {
        memset(p, 0, sizeof(sipc_pipe));
        p->pipe_handle = INVALID_HANDLE_VALUE;
    }
    return p;
}

char* sipc_make_pipe_name(const char* simple_name) {
    char* full_name;
    size_t len;

    if (!simple_name) return NULL;

    len = strlen("\\\\.\\pipe\\") + strlen(simple_name) + 1;
    full_name = (char*)malloc(len);
    if (full_name) {
        sprintf(full_name, "\\\\.\\pipe\\%s", simple_name);
    }
    return full_name;
}

sipc_pipe* sipc_create_server(const char* name) {
    sipc_pipe* p;

    p = create_pipe_struct();
    if (!p) return NULL;

    p->is_server = 1;

    p->pipe_handle = CreateNamedPipeA(
        name,
        PIPE_ACCESS_DUPLEX,
        PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
        1,                  /* Max instances */
        PIPE_BUFFER_SIZE,   /* Output buffer size */
        PIPE_BUFFER_SIZE,   /* Input buffer size */
        0,                  /* Default timeout */
        NULL                /* Default security */
    );

    if (p->pipe_handle == INVALID_HANDLE_VALUE) {
        store_last_error();
        p->error_message = _strdup(last_error_msg);
    }

    return p;
}

sipc_pipe* sipc_connect_client(const char* name) {
    sipc_pipe* p;
    DWORD mode;

    p = create_pipe_struct();
    if (!p) return NULL;

    p->is_server = 0;

    /* Try to connect */
    p->pipe_handle = CreateFileA(
        name,
        GENERIC_READ | GENERIC_WRITE,
        0,
        NULL,
        OPEN_EXISTING,
        0,
        NULL
    );

    if (p->pipe_handle == INVALID_HANDLE_VALUE) {
        store_last_error();
        p->error_message = _strdup(last_error_msg);
        return p;
    }

    /* Set to message mode */
    mode = PIPE_READMODE_MESSAGE;
    if (!SetNamedPipeHandleState(p->pipe_handle, &mode, NULL, NULL)) {
        store_last_error();
        p->error_message = _strdup(last_error_msg);
        CloseHandle(p->pipe_handle);
        p->pipe_handle = INVALID_HANDLE_VALUE;
        return p;
    }

    p->is_connected = 1;
    return p;
}

int sipc_wait_for_connection(sipc_pipe* pipe, int timeout_ms) {
    BOOL connected;
    OVERLAPPED overlapped = {0};
    DWORD wait_result;

    if (!pipe || pipe->pipe_handle == INVALID_HANDLE_VALUE || !pipe->is_server) {
        return 0;
    }

    if (timeout_ms <= 0) {
        /* Blocking wait */
        connected = ConnectNamedPipe(pipe->pipe_handle, NULL);
        if (!connected) {
            DWORD err = GetLastError();
            if (err == ERROR_PIPE_CONNECTED) {
                /* Client already connected */
                pipe->is_connected = 1;
                return 1;
            }
            store_last_error();
            if (pipe->error_message) free(pipe->error_message);
            pipe->error_message = _strdup(last_error_msg);
            return 0;
        }
        pipe->is_connected = 1;
        return 1;
    }

    /* Non-blocking with timeout - use overlapped I/O */
    overlapped.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (!overlapped.hEvent) {
        store_last_error();
        if (pipe->error_message) free(pipe->error_message);
        pipe->error_message = _strdup(last_error_msg);
        return 0;
    }

    connected = ConnectNamedPipe(pipe->pipe_handle, &overlapped);
    if (!connected) {
        DWORD err = GetLastError();
        if (err == ERROR_PIPE_CONNECTED) {
            CloseHandle(overlapped.hEvent);
            pipe->is_connected = 1;
            return 1;
        }
        if (err != ERROR_IO_PENDING) {
            store_last_error();
            if (pipe->error_message) free(pipe->error_message);
            pipe->error_message = _strdup(last_error_msg);
            CloseHandle(overlapped.hEvent);
            return 0;
        }
    }

    wait_result = WaitForSingleObject(overlapped.hEvent, (DWORD)timeout_ms);
    CloseHandle(overlapped.hEvent);

    if (wait_result == WAIT_OBJECT_0) {
        pipe->is_connected = 1;
        return 1;
    }

    /* Cancel pending operation on timeout */
    CancelIo(pipe->pipe_handle);
    return 0;
}

int sipc_disconnect(sipc_pipe* pipe) {
    if (!pipe || pipe->pipe_handle == INVALID_HANDLE_VALUE || !pipe->is_server) {
        return 0;
    }

    FlushFileBuffers(pipe->pipe_handle);
    DisconnectNamedPipe(pipe->pipe_handle);
    pipe->is_connected = 0;
    return 1;
}

int sipc_read(sipc_pipe* pipe, void* buffer, int buffer_size) {
    DWORD bytes_read = 0;
    BOOL success;

    if (!pipe || pipe->pipe_handle == INVALID_HANDLE_VALUE || !buffer) {
        return -1;
    }

    success = ReadFile(pipe->pipe_handle, buffer, (DWORD)buffer_size, &bytes_read, NULL);

    if (!success && GetLastError() != ERROR_MORE_DATA) {
        store_last_error();
        if (pipe->error_message) free(pipe->error_message);
        pipe->error_message = _strdup(last_error_msg);
        return -1;
    }

    return (int)bytes_read;
}

int sipc_write(sipc_pipe* pipe, const void* data, int data_size) {
    DWORD bytes_written = 0;
    BOOL success;

    if (!pipe || pipe->pipe_handle == INVALID_HANDLE_VALUE || !data) {
        return -1;
    }

    success = WriteFile(pipe->pipe_handle, data, (DWORD)data_size, &bytes_written, NULL);

    if (!success) {
        store_last_error();
        if (pipe->error_message) free(pipe->error_message);
        pipe->error_message = _strdup(last_error_msg);
        return -1;
    }

    return (int)bytes_written;
}

int sipc_read_line(sipc_pipe* pipe, char* buffer, int buffer_size) {
    int total_read = 0;
    char ch;
    DWORD bytes_read;
    BOOL success;

    if (!pipe || pipe->pipe_handle == INVALID_HANDLE_VALUE || !buffer || buffer_size <= 0) {
        return -1;
    }

    while (total_read < buffer_size - 1) {
        success = ReadFile(pipe->pipe_handle, &ch, 1, &bytes_read, NULL);
        if (!success || bytes_read == 0) {
            break;
        }
        if (ch == '\n') {
            break;
        }
        if (ch != '\r') {
            buffer[total_read++] = ch;
        }
    }

    buffer[total_read] = '\0';
    return total_read;
}

int sipc_write_string(sipc_pipe* pipe, const char* str) {
    if (!str) return -1;
    return sipc_write(pipe, str, (int)strlen(str));
}

int sipc_data_available(sipc_pipe* pipe) {
    DWORD bytes_available = 0;
    BOOL success;

    if (!pipe || pipe->pipe_handle == INVALID_HANDLE_VALUE) {
        return -1;
    }

    success = PeekNamedPipe(pipe->pipe_handle, NULL, 0, NULL, &bytes_available, NULL);

    if (!success) {
        return -1;
    }

    return bytes_available > 0 ? 1 : 0;
}

int sipc_is_connected(sipc_pipe* pipe) {
    return pipe ? pipe->is_connected : 0;
}

int sipc_is_server(sipc_pipe* pipe) {
    return pipe ? pipe->is_server : 0;
}

const char* sipc_get_error(sipc_pipe* pipe) {
    return pipe ? pipe->error_message : NULL;
}

void sipc_close(sipc_pipe* pipe) {
    if (pipe) {
        if (pipe->pipe_handle != INVALID_HANDLE_VALUE) {
            if (pipe->is_server && pipe->is_connected) {
                FlushFileBuffers(pipe->pipe_handle);
                DisconnectNamedPipe(pipe->pipe_handle);
            }
            CloseHandle(pipe->pipe_handle);
        }
        if (pipe->error_message) {
            free(pipe->error_message);
        }
        free(pipe);
    }
}

#else
/* Linux/macOS stubs - use UNIX_SOCKET_CONNECTION instead */
static const char* stub_error = "Named pipes not supported. Use Unix sockets.";
char* sipc_make_pipe_name(const char* n) { (void)n; return NULL; }
sipc_pipe* sipc_create_server(const char* n) { (void)n; return NULL; }
sipc_pipe* sipc_connect_client(const char* n) { (void)n; return NULL; }
int sipc_wait_for_connection(sipc_pipe* p, int t) { (void)p; (void)t; return 0; }
int sipc_disconnect(sipc_pipe* p) { (void)p; return 0; }
int sipc_read(sipc_pipe* p, void* b, int s) { (void)p; (void)b; (void)s; return -1; }
int sipc_write(sipc_pipe* p, const void* d, int s) { (void)p; (void)d; (void)s; return -1; }
int sipc_read_line(sipc_pipe* p, char* b, int s) { (void)p; (void)b; (void)s; return -1; }
int sipc_write_string(sipc_pipe* p, const char* s) { (void)p; (void)s; return -1; }
int sipc_data_available(sipc_pipe* p) { (void)p; return -1; }
int sipc_is_connected(sipc_pipe* p) { (void)p; return 0; }
int sipc_is_server(sipc_pipe* p) { (void)p; return 0; }
const char* sipc_get_error(sipc_pipe* p) { (void)p; return stub_error; }
void sipc_close(sipc_pipe* p) { (void)p; }
#endif /* _WIN32 || EIF_WINDOWS */
