// std.net — Networking: sockets, TCP, UDP, DNS resolution.

extern i32    socket(i32 domain, i32 type, i32 proto);
extern i32    bind(i32 fd, void* addr, u32 addrlen);
extern i32    listen(i32 fd, i32 backlog);
extern i32    accept(i32 fd, void* addr, u32* addrlen);
extern i32    connect(i32 fd, void* addr, u32 addrlen);
extern i64    send(i32 fd, void* buf, u64 n, i32 flags);
extern i64    recv(i32 fd, void* buf, u64 n, i32 flags);
extern i64    sendto(i32 fd, void* buf, u64 n, i32 flags, void* addr, u32 addrlen);
extern i64    recvfrom(i32 fd, void* buf, u64 n, i32 flags, void* addr, u32* addrlen);
extern i32    close(i32 fd);
extern i32    setsockopt(i32 fd, i32 level, i32 opt, void* val, u32 len);
extern i32    getsockopt(i32 fd, i32 level, i32 opt, void* val, u32* len);
extern i32    getaddrinfo(i8* host, i8* service, void* hints, void** res);
extern void   freeaddrinfo(void* res);
extern i32    getnameinfo(void* sa, u32 salen, i8* host, u32 hlen, i8* serv, u32 slen, i32 flags);
extern u32    htonl(u32 h);
extern u16    htons(u16 h);
extern u32    ntohl(u32 n);
extern u16    ntohs(u16 n);
extern i32    inet_pton(i32 af, i8* src, void* dst);
extern i8*    inet_ntop(i32 af, void* src, i8* dst, u32 size);
extern i32    shutdown(i32 fd, i32 how);
extern i32    select(i32 nfds, void* rfds, void* wfds, void* efds, void* timeout);
extern i32    poll(void* fds, u32 nfds, i32 timeout);

namespace std {
namespace net {

constexpr i32 AF_INET   = 2;
constexpr i32 AF_INET6  = 10;
constexpr i32 SOCK_STREAM = 1;
constexpr i32 SOCK_DGRAM  = 2;
constexpr i32 IPPROTO_TCP = 6;
constexpr i32 IPPROTO_UDP = 17;
constexpr i32 SOL_SOCKET  = 1;
constexpr i32 SO_REUSEADDR = 2;
constexpr i32 SO_KEEPALIVE = 9;
constexpr i32 SHUT_RD  = 0;
constexpr i32 SHUT_WR  = 1;
constexpr i32 SHUT_RDWR = 2;

// IPv4 socket address (mirrors struct sockaddr_in)
struct addr_v4 {
    u16 family;
    u16 port;
    u32 ip;
    i8  pad[8];
}

// --- socket handle ---

istruc socket_t {
    i32 fd;

    void __construct__(&self) { self.fd = -1; }

    bool is_valid(&self) { return self.fd >= 0; }

    void close(&self) {
        if (self.fd >= 0) { close(self.fd); self.fd = -1; }
    }

    i64 send_bytes(&self, void* buf, u64 n) { return send(self.fd, buf, n, 0); }
    i64 recv_bytes(&self, void* buf, u64 n) { return recv(self.fd, buf, n, 0); }

    bool set_reuse_addr(&self) {
        i32 val = 1;
        return setsockopt(self.fd, SOL_SOCKET, SO_REUSEADDR, &val, (u32)sizeof(i32)) == 0;
    }

    bool set_keepalive(&self) {
        i32 val = 1;
        return setsockopt(self.fd, SOL_SOCKET, SO_KEEPALIVE, &val, (u32)sizeof(i32)) == 0;
    }
}

// --- TCP listener ---

istruc tcp_listener {
    socket_t sock;

    bool bind_and_listen(&self, u16 port, i32 backlog) {
        self.sock.fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (!self.sock.is_valid()) { return false; }
        self.sock.set_reuse_addr();
        addr_v4 addr;
        addr.family = (u16)AF_INET;
        addr.port   = htons(port);
        addr.ip     = 0;  // INADDR_ANY
        if (bind(self.sock.fd, &addr, (u32)sizeof(addr_v4)) != 0) {
            self.sock.close(); return false;
        }
        return listen(self.sock.fd, backlog) == 0;
    }

    bool accept_conn(&self, socket_t* out_sock) {
        addr_v4 addr;
        u32 len = (u32)sizeof(addr_v4);
        i32 fd  = accept(self.sock.fd, &addr, &len);
        if (fd < 0) { return false; }
        (*out_sock).fd = fd;
        return true;
    }

    void close(&self) { self.sock.close(); }
}

// --- TCP client ---

istruc tcp_client {
    socket_t sock;

    bool connect_to(&self, i8* host, u16 port) {
        void* res = (void*)0;
        i8 port_str[8];
        i32 pi = port;
        i32 pos = 0;
        if (pi == 0) { port_str[0] = '0'; port_str[1] = 0; }
        else {
            while (pi > 0) { port_str[pos] = (i8)('0' + pi % 10); pos = pos + 1; pi = pi / 10; }
            // reverse
            for (i32 i = 0; i < pos / 2; i = i + 1) {
                i8 tmp = port_str[i]; port_str[i] = port_str[pos-1-i]; port_str[pos-1-i] = tmp;
            }
            port_str[pos] = 0;
        }
        if (getaddrinfo(host, port_str, (void*)0, &res) != 0) { return false; }
        // Try each address
        void* p = res;
        bool connected = false;
        while (p != (void*)0 && !connected) {
            // addrinfo layout: ai_flags(4) ai_family(4) ai_socktype(4) ai_protocol(4) ai_addrlen(8) ai_canonname(ptr) ai_addr(ptr) ai_next(ptr)
            i32* ip = (i32*)p;
            i32 fam  = ip[1];
            i32 type = ip[2];
            i32 prot = ip[3];
            u64* up  = (u64*)(p + 16);
            u64 addrlen = up[0];
            void* sa    = (void*)up[1];
            void* next  = (void*)up[2];
            i32 fd = socket(fam, type, prot);
            if (fd >= 0) {
                if (connect(fd, sa, (u32)addrlen) == 0) {
                    self.sock.fd = fd; connected = true;
                } else { close(fd); }
            }
            p = next;
        }
        freeaddrinfo(res);
        return connected;
    }

    i64 send_bytes(&self, void* buf, u64 n) { return self.sock.send_bytes(buf, n); }
    i64 recv_bytes(&self, void* buf, u64 n) { return self.sock.recv_bytes(buf, n); }
    void close(&self) { self.sock.close(); }
}

// --- UDP socket ---

istruc udp_socket {
    socket_t sock;

    bool open(&self) {
        self.sock.fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        return self.sock.is_valid();
    }

    bool bind_port(&self, u16 port) {
        addr_v4 addr;
        addr.family = (u16)AF_INET;
        addr.port   = htons(port);
        addr.ip     = 0;
        return bind(self.sock.fd, &addr, (u32)sizeof(addr_v4)) == 0;
    }

    i64 send_to(&self, void* buf, u64 n, i8* host, u16 port) {
        addr_v4 addr;
        addr.family = (u16)AF_INET;
        addr.port   = htons(port);
        inet_pton(AF_INET, host, &addr.ip);
        return sendto(self.sock.fd, buf, n, 0, &addr, (u32)sizeof(addr_v4));
    }

    i64 recv_from(&self, void* buf, u64 n, addr_v4* from) {
        u32 len = (u32)sizeof(addr_v4);
        return recvfrom(self.sock.fd, buf, n, 0, from, &len);
    }

    void close(&self) { self.sock.close(); }
}

} // net
} // std
