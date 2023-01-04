// Пример для обхода DEP с помощью ROP.
//
// cl dep_rop1.c /Zi /GS- /link /safeseh:no /base:0x08040000 /nodefaultlib:libcmt.lib msvcrt.lib ws2_32.lib
//
// Маткин Илья Александрович    07.10.2015

#include <string.h>
#include <fcntl.h>
//#include <winsock.h>
#include <winsock2.h>
#include <windows.h>


SOCKADDR_IN addr;
size_t size = sizeof(SOCKADDR_IN);
int port;
SOCKADDR_IN ptr;


static void* ProcessingRequest (SOCKET sock);
static SOCKET init_sock (int port);


int main (unsigned int argc, char *argv[], char *envp[]) {

char *info;
SOCKET sock;
SOCKET connectSock;
int status;
WSADATA wsaData;

    WSAStartup (MAKEWORD (2, 2), &wsaData);

    if (argc <= 1) {
        port = 6666;
        }
    else {
        port = atoi(argv[1]);
        }

    if (!port) {
        printf ("Error port %d\n", port);
        return 1;
        }

    sock = init_sock (port);
    if (sock == INVALID_SOCKET) {
        return 1;
        }

    while ((connectSock = accept (sock, (LPSOCKADDR)&ptr, &size)) != INVALID_SOCKET) {
        
        ProcessingRequest (connectSock);
        
        closesocket (connectSock);
        }

    WSACleanup();
    
    return 0;
}



SOCKET init_sock (int port) {

SOCKET sock;

    sock = WSASocket (AF_INET, SOCK_STREAM, IPPROTO_TCP, NULL, 0, 0);
    //sock = socket (AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock == INVALID_SOCKET) {
        return INVALID_SOCKET;
        }
	
    memset (&addr, 0, sizeof(addr));

	addr.sin_family = AF_INET;
    addr.sin_port = htons (port);
    addr.sin_addr.s_addr = INADDR_ANY;

	if (bind (sock, (LPSOCKADDR)&addr, sizeof (struct sockaddr_in)) == SOCKET_ERROR) {
        puts ("Error bind address");
        closesocket (sock);
        return -1;
        }

    listen (sock, 10);

    return sock;
}


SOCKET glSock;

static void * ProcessingRequest (SOCKET sock) {

char buf[1000];
char c;
size_t i = 0;
void * ret;

    glSock = sock;
    
    while (recv (glSock, &c, 1, 0) > 0) {
        if (c == '\n') {
            buf[i++] = 0;
            break;
            }
        buf[i++] = c;
        }
        
    printf ("read %d bytes:\n", i);
    printf ("%s\n", buf);
    
    ret = VirtualAlloc (NULL, i, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    RtlCopyMemory (ret, buf, i);

    return ret;
}
