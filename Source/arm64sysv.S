.text
.align 2
#ifdef __APPLE__
.globl _arm64call
.p2align 2
_arm64call:
#else
.globl arm64call
.type arm64call, %function
arm64call:
#endif
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]

    mov x24, x0
    mov x19, x1
    mov x20, x2
    mov x21, x3
    mov x22, x4
    mov x23, x5

    cbz x23, 1f
    lsl x9, x23, #3
    sub sp, sp, x9
    mov x10, sp
0:
    ldr x11, [x22], #8
    str x11, [x10], #8
    subs x23, x23, #1
    b.ne 0b
1:
    ldr w9, [x21, #120]

    tbnz w9, #0, 2f
    ldr d0, [x20]
    b 3f
2:
    ldr d16, [x20]
    fcvt s0, d16
3:
    ldr x0, [x19]
    ldr x1, [x21, #0]
    ldr x2, [x21, #8]
    ldr x3, [x21, #16]
    ldr x4, [x21, #24]
    ldr x5, [x21, #32]
    ldr x6, [x21, #40]
    ldr x7, [x21, #48]
    ldr x8, [x21, #56]

    tbnz w9, #1, 4f
    ldr d1, [x21, #64]
    b 5f
4: ldr d16, [x21, #64]
    fcvt s1, d16
5:
    tbnz w9, #2, 6f
    ldr d2, [x21, #72]
    b 7f
6: ldr d16, [x21, #72]
    fcvt s2, d16
7:
    tbnz w9, #3, 8f
    ldr d3, [x21, #80]
    b 9f
8: ldr d16, [x21, #80]
    fcvt s3, d16
9:
    tbnz w9, #4, 10f
    ldr d4, [x21, #88]
    b 11f
10: ldr d16, [x21, #88]
    fcvt s4, d16
11:
    tbnz w9, #5, 12f
    ldr d5, [x21, #96]
    b 13f
12: ldr d16, [x21, #96]
    fcvt s5, d16
13:
    tbnz w9, #6, 14f
    ldr d6, [x21, #104]
    b 15f
14: ldr d16, [x21, #104]
    fcvt s6, d16
15:
    tbnz w9, #7, 16f
    ldr d7, [x21, #112]
    b 17f
16: ldr d16, [x21, #112]
    fcvt s7, d16
17:
    blr x24

    str x0, [x19]
    tbnz w9, #8, 18f
    str d0, [x20]
    b 19f
18:
    fcvt d16, s0
    str d16, [x20]
19:
    mov sp, x29
    ldp x19, x20, [sp, #16]
    ldp x21, x22, [sp, #32]
    ldp x23, x24, [sp, #48]
    ldp x29, x30, [sp], #64
    ret
#ifndef __APPLE__
.size arm64call, .-arm64call
#endif
