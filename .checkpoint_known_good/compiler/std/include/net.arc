// std.net — Networking: sockets, TCP, UDP, DNS resolution.

@unsafe extern fn socket(domain: i32, type: i32, proto: i32) i32;
@unsafe extern fn bind(fd: i32, addr: *void, addrlen: u32) i32;
@unsafe extern fn listen(fd: i32, backlog: i32) i32;
@unsafe extern fn accept(fd: i32, addr: *void, addrlen: *u32) i32;
@unsafe extern fn connect(fd: i32, addr: *void, addrlen: u32) i32;
@unsafe extern fn send(fd: i32, buf: *void, n: u64, flags: i32) i64;
@unsafe extern fn recv(fd: i32, buf: *void, n: u64, flags: i32) i64;
@unsafe extern fn sendto(fd: i32, buf: *void, n: u64, flags: i32, addr: *void, addrlen: u32) i64;
@unsafe extern fn recvfrom(fd: i32, buf: *void, n: u64, flags: i32, addr: *void, addrlen: *u32) i64;
@unsafe extern fn close(fd: i32) i32;
@unsafe extern fn setsockopt(fd: i32, level: i32, opt: i32, val: *void, len: u32) i32;
@unsafe extern fn getsockopt(fd: i32, level: i32, opt: i32, val: *void, len: *u32) i32;
@unsafe extern fn getaddrinfo(host: *i8, service: *i8, hints: *void, res: **void) i32;
@unsafe extern fn freeaddrinfo(res: *void) void;
@unsafe extern fn getnameinfo(sa: *void, salen: u32, host: *i8, hlen: u32, serv: *i8, slen: u32, flags: i32) i32;
@unsafe extern fn htonl(h: u32) u32;
@unsafe extern fn htons(h: u16) u16;
@unsafe extern fn ntohl(n: u32) u32;
@unsafe extern fn ntohs(n: u16) u16;
@unsafe extern fn inet_pton(af: i32, src: *i8, dst: *void) i32;
@unsafe extern fn inet_ntop(af: i32, src: *void, dst: *i8, size: u32) *i8;
@unsafe extern fn shutdown(fd: i32, how: i32) i32;
@unsafe extern fn select(nfds: i32, rfds: *void, wfds: *void, efds: *void, timeout: *void) i32;
@unsafe extern fn poll(fds: *void, nfds: u32, timeout: i32) i32;

namespace std {
namespace net {

comptime i32 AF_INET   = 2;
comptime i32 AF_INET6  = 10;
comptime i32 SOCK_STREAM = 1;
comptime i32 SOCK_DGRAM  = 2;
comptime i32 IPPROTO_TCP = 6;
comptime i32 IPPROTO_UDP = 17;
comptime i32 SOL_SOCKET  = 1;
comptime i32 SO_REUSEADDR = 2;
comptime i32 SO_KEEPALIVE = 9;
comptime i32 SHUT_RD  = 0;
comptime i32 SHUT_WR  = 1;
comptime i32 SHUT_RDWR = 2;

// IPv4 socket address (mirrors struct sockaddr_in)
struct addr_v4 {
    let family: u16;
    let port: u16;
    let ip: u32;
    let pad: [8]i8;
}

// --- socket handle ---

istruc socket_t {
    let mut fd: i32;

    fn __construct__(self: *socket_t) void { self.fd = -1; }

    fn is_valid(self: *socket_t) bool { return self.fd >= 0; }

    fn close(self: *socket_t) void {
        if (self.fd >= 0) { close(self.fd); self.fd = -1; }
    }

    fn send_bytes(self: *socket_t, buf: *void, n: u64) i64 { return send(self.fd, buf, n, 0); }
    fn recv_bytes(self: *socket_t, buf: *void, n: u64) i64 { return recv(self.fd, buf, n, 0); }

    fn set_reuse_addr(self: *socket_t) bool {
        let mut val: i32= 1;
        return setsockopt(self.fd, SOL_SOCKET, SO_REUSEADDR, &val, (u32)sizeof(i32)) == 0;
    }

    fn set_keepalive(self: *socket_t) bool {
        let mut val: i32= 1;
        return setsockopt(self.fd, SOL_SOCKET, SO_KEEPALIVE, &val, (u32)sizeof(i32)) == 0;
    }
}

// --- TCP listener ---

istruc tcp_listener {
    let mut sock: socket_t;

    fn bind_and_listen(self: *tcp_listener, port: u16, backlog: i32) bool {
        self.sock.fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (!self.sock.is_valid()) { return false; }
        self.sock.set_reuse_addr();
        let mut addr: addr_v4;
        addr.family = (u16)AF_INET;
        addr.port   = htons(port);
        addr.ip     = 0;  // INADDR_ANY
        if (bind(self.sock.fd, &addr, (u32)sizeof(addr_v4)) != 0) {
            self.sock.close(); return false;
        }
        return listen(self.sock.fd, backlog) == 0;
    }

    fn accept_conn(self: *tcp_listener, out_sock: *socket_t) bool {
        let mut addr: addr_v4;
        let mut len: u32= (u32)sizeof(addr_v4);
        let mut fd: i32= accept(self.sock.fd, &addr, &len);
        if (fd < 0) { return false; }
        (*out_sock).fd = fd;
        return true;
    }

    fn close(self: *tcp_listener) void { self.sock.close(); }
}

// --- TCP client ---

istruc tcp_client {
    let mut sock: socket_t;

    fn connect_to(self: *tcp_client, host: *i8, port: u16) bool {
        let mut res: *void= (void*)0;
        let mut port_str: [8]i8;
        let mut pi: i32= port;
        let mut pos: i32= 0;
        if (pi == 0) { port_str[0] = '0'; port_str[1] = 0; }
        else {
            while (pi > 0) { port_str[pos] = (i8)('0' + pi % 10); pos = pos + 1; pi = pi / 10; }
            // reverse
            for (let mut i: i32 = 0; i < pos / 2; i = i + 1) {
                let mut tmp: i8= port_str[i]; port_str[i] = port_str[pos-1-i]; port_str[pos-1-i] = tmp;
            }
            port_str[pos] = 0;
        }
        if (getaddrinfo(host, port_str, (void*)0, &res) != 0) { return false; }
        // Try each address
        let mut p: *void= res;
        let mut connected: bool= false;
        while (p != (void*)0 && !connected) {
            // addrinfo layout on Linux x86-64:
            //   offset  0: ai_flags    i32 (4)
            //   offset  4: ai_family   i32 (4)
            //   offset  8: ai_socktype i32 (4)
            //   offset 12: ai_protocol i32 (4)
            //   offset 16: ai_addrlen  u32 (4)
            //   offset 20: padding     (4)
            //   offset 24: ai_canonname *i8  (8)
            //   offset 32: ai_addr     *void (8)
            //   offset 40: ai_next     *void (8)
            let mut ip: *i32= (i32*)p;
            let mut fam: i32= ip[1];
            let mut type: i32= ip[2];
            let mut prot: i32= ip[3];
            let mut addrlen_p: *u32= (u32*)((u8*)p + 16);
            let mut addrlen: u32= *addrlen_p;
            let mut ptrs: *u64= (u64*)((u8*)p + 24);
            // ptrs[0] = ai_canonname (skip), ptrs[1] = ai_addr, ptrs[2] = ai_next
            let mut sa: *void= (void*)ptrs[1];
            let mut next: *void= (void*)ptrs[2];
            let mut fd: i32= socket(fam, type, prot);
            if (fd >= 0) {
                if (connect(fd, sa, addrlen) == 0) {
                    self.sock.fd = fd; connected = true;
                } else { close(fd); }
            }
            p = next;
        }
        freeaddrinfo(res);
        return connected;
    }

    fn send_bytes(self: *tcp_client, buf: *void, n: u64) i64 { return self.sock.send_bytes(buf, n); }
    fn recv_bytes(self: *tcp_client, buf: *void, n: u64) i64 { return self.sock.recv_bytes(buf, n); }
    fn close(self: *tcp_client) void { self.sock.close(); }
}

// --- UDP socket ---

istruc udp_socket {
    let mut sock: socket_t;

    fn open(self: *udp_socket) bool {
        self.sock.fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        return self.sock.is_valid();
    }

    fn bind_port(self: *udp_socket, port: u16) bool {
        let mut addr: addr_v4;
        addr.family = (u16)AF_INET;
        addr.port   = htons(port);
        addr.ip     = 0;
        return bind(self.sock.fd, &addr, (u32)sizeof(addr_v4)) == 0;
    }

    fn send_to(self: *udp_socket, buf: *void, n: u64, host: *i8, port: u16) i64 {
        let mut addr: addr_v4;
        addr.family = (u16)AF_INET;
        addr.port   = htons(port);
        inet_pton(AF_INET, host, &addr.ip);
        return sendto(self.sock.fd, buf, n, 0, &addr, (u32)sizeof(addr_v4));
    }

    fn recv_from(self: *udp_socket, buf: *void, n: u64, from: *addr_v4) i64 {
        let mut len: u32= (u32)sizeof(addr_v4);
        return recvfrom(self.sock.fd, buf, n, 0, from, &len);
    }

    fn close(self: *udp_socket) void { self.sock.close(); }
}

} // net
} // std
