//! CatmhyOS: Bare-Metal x86_64 Hello CatmhyOS Stub
//! Copyright (c) 2026 bsd.how. All rights reserved.

const builtin = @import("builtin");
const COM1_PORT: u16 = 0x3F8;

/// x86_64 bare-metal inline assembly: write 1 byte to the specified hardware I/O port (Ring 0)
inline fn outb(port: u16, data: u8) void {
    asm volatile ("outb %[data], %[port]"
        :
        : [data] "{al}" (data),
          [port] "{dx}" (port),
    );
}

/// Zero-dependency output: direct 0x3F8 hardware UART write in bare-metal mode, or raw kernel syscall in host mode
fn printSerial(msg: []const u8) void {
    if (builtin.os.tag == .freestanding) {
        for (msg) |c| outb(COM1_PORT, c);
    } else {
        // Emit directly to stdout (FD 1) via raw inline assembly syscall in host userland (Ring 3)
        _ = asm volatile ("syscall"
            : [ret] "={rax}" (-> usize),
            : [nr] "{rax}" (@as(usize, if (builtin.os.tag == .freebsd) 4 else 1)),
              [fd] "{rdi}" (@as(usize, 1)),
              [buf] "{rsi}" (@intFromPtr(msg.ptr)),
              [len] "{rdx}" (msg.len),
            : .{ .rcx = true, .r11 = true, .memory = true }
        );
    }
}

pub fn main() void {
    // First sovereign invocation from the bare-metal genesis vector
    printSerial("Hello CatmhyOS\r\n");

    if (builtin.os.tag == .freestanding) {
        while (true) asm volatile ("hlt");
    }
}
