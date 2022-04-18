
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c7c78793          	addi	a5,a5,-900 # 80005ce0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3ea080e7          	jalr	1002(ra) # 80002516 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f2c080e7          	jalr	-212(ra) # 80002100 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	2b0080e7          	jalr	688(ra) # 800024c0 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	27a080e7          	jalr	634(ra) # 8000256c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e46080e7          	jalr	-442(ra) # 8000228c <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	0a078793          	addi	a5,a5,160 # 80021518 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	9ec080e7          	jalr	-1556(ra) # 8000228c <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	7d4080e7          	jalr	2004(ra) # 80002100 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	88a080e7          	jalr	-1910(ra) # 8000275e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	e44080e7          	jalr	-444(ra) # 80005d20 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	022080e7          	jalr	34(ra) # 80001f06 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	7ea080e7          	jalr	2026(ra) # 80002736 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	80a080e7          	jalr	-2038(ra) # 8000275e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	dae080e7          	jalr	-594(ra) # 80005d0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	dbc080e7          	jalr	-580(ra) # 80005d20 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	f9a080e7          	jalr	-102(ra) # 80002f06 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	62a080e7          	jalr	1578(ra) # 8000359e <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	5d4080e7          	jalr	1492(ra) # 80004550 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	ebe080e7          	jalr	-322(ra) # 80005e42 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	cfc080e7          	jalr	-772(ra) # 80001c88 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	a62a0a13          	addi	s4,s4,-1438 # 800172d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	17048493          	addi	s1,s1,368
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	99698993          	addi	s3,s3,-1642 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	8791                	srai	a5,a5,0x4
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	17048493          	addi	s1,s1,368
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e707a783          	lw	a5,-400(a5) # 80008870 <first.1681>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	d84080e7          	jalr	-636(ra) # 8000278e <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e407ab23          	sw	zero,-426(a5) # 80008870 <first.1681>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	afa080e7          	jalr	-1286(ra) # 8000351e <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	e2878793          	addi	a5,a5,-472 # 80008874 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	06093683          	ld	a3,96(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	7128                	ld	a0,96(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001b7e:	6ca8                	ld	a0,88(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	68ac                	ld	a1,80(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001b90:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001b9c:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00015917          	auipc	s2,0x15
    80001bd2:	70290913          	addi	s2,s2,1794 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	17048493          	addi	s1,s1,368
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a889                	j	80001c4a <allocproc+0x90>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	eec080e7          	jalr	-276(ra) # 80000af4 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	f0a8                	sd	a0,96(s1)
    80001c14:	c131                	beqz	a0,80001c58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001c24:	c531                	beqz	a0,80001c70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	06848513          	addi	a0,s1,104
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0b0080e7          	jalr	176(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	db078793          	addi	a5,a5,-592 # 800019e8 <forkret>
    80001c40:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	64bc                	ld	a5,72(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	f8bc                	sd	a5,112(s1)
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f08080e7          	jalr	-248(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	bff1                	j	80001c4a <allocproc+0x90>
    freeproc(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	ef0080e7          	jalr	-272(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	01c080e7          	jalr	28(ra) # 80000c98 <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7d1                	j	80001c4a <allocproc+0x90>

0000000080001c88 <userinit>:
{
    80001c88:	7179                	addi	sp,sp,-48
    80001c8a:	f406                	sd	ra,40(sp)
    80001c8c:	f022                	sd	s0,32(sp)
    80001c8e:	ec26                	sd	s1,24(sp)
    80001c90:	e84a                	sd	s2,16(sp)
    80001c92:	e44e                	sd	s3,8(sp)
    80001c94:	1800                	addi	s0,sp,48
  p = allocproc();
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	f24080e7          	jalr	-220(ra) # 80001bba <allocproc>
    80001c9e:	84aa                	mv	s1,a0
  initproc = p;
    80001ca0:	00007997          	auipc	s3,0x7
    80001ca4:	39098993          	addi	s3,s3,912 # 80009030 <initproc>
    80001ca8:	00a9b023          	sd	a0,0(s3)
  printf("Process name is: %s\n", initproc->name);
    80001cac:	16050913          	addi	s2,a0,352
    80001cb0:	85ca                	mv	a1,s2
    80001cb2:	00006517          	auipc	a0,0x6
    80001cb6:	54e50513          	addi	a0,a0,1358 # 80008200 <digits+0x1c0>
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	8ce080e7          	jalr	-1842(ra) # 80000588 <printf>
  printf("Process ID is: %d\n", initproc->pid);
    80001cc2:	0009b783          	ld	a5,0(s3)
    80001cc6:	5b8c                	lw	a1,48(a5)
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	55050513          	addi	a0,a0,1360 # 80008218 <digits+0x1d8>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	8b8080e7          	jalr	-1864(ra) # 80000588 <printf>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd8:	03400613          	li	a2,52
    80001cdc:	00007597          	auipc	a1,0x7
    80001ce0:	ba458593          	addi	a1,a1,-1116 # 80008880 <initcode>
    80001ce4:	6ca8                	ld	a0,88(s1)
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	682080e7          	jalr	1666(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cee:	6785                	lui	a5,0x1
    80001cf0:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cf2:	70b8                	ld	a4,96(s1)
    80001cf4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf8:	70b8                	ld	a4,96(s1)
    80001cfa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfc:	4641                	li	a2,16
    80001cfe:	00006597          	auipc	a1,0x6
    80001d02:	53258593          	addi	a1,a1,1330 # 80008230 <digits+0x1f0>
    80001d06:	854a                	mv	a0,s2
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	12a080e7          	jalr	298(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d10:	00006517          	auipc	a0,0x6
    80001d14:	53050513          	addi	a0,a0,1328 # 80008240 <digits+0x200>
    80001d18:	00002097          	auipc	ra,0x2
    80001d1c:	234080e7          	jalr	564(ra) # 80003f4c <namei>
    80001d20:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001d24:	478d                	li	a5,3
    80001d26:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80001d28:	00007797          	auipc	a5,0x7
    80001d2c:	3107a783          	lw	a5,784(a5) # 80009038 <ticks>
    80001d30:	dcdc                	sw	a5,60(s1)
  release(&p->lock);
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	f64080e7          	jalr	-156(ra) # 80000c98 <release>
}
    80001d3c:	70a2                	ld	ra,40(sp)
    80001d3e:	7402                	ld	s0,32(sp)
    80001d40:	64e2                	ld	s1,24(sp)
    80001d42:	6942                	ld	s2,16(sp)
    80001d44:	69a2                	ld	s3,8(sp)
    80001d46:	6145                	addi	sp,sp,48
    80001d48:	8082                	ret

0000000080001d4a <growproc>:
{
    80001d4a:	1101                	addi	sp,sp,-32
    80001d4c:	ec06                	sd	ra,24(sp)
    80001d4e:	e822                	sd	s0,16(sp)
    80001d50:	e426                	sd	s1,8(sp)
    80001d52:	e04a                	sd	s2,0(sp)
    80001d54:	1000                	addi	s0,sp,32
    80001d56:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d58:	00000097          	auipc	ra,0x0
    80001d5c:	c58080e7          	jalr	-936(ra) # 800019b0 <myproc>
    80001d60:	892a                	mv	s2,a0
  sz = p->sz;
    80001d62:	692c                	ld	a1,80(a0)
    80001d64:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d68:	00904f63          	bgtz	s1,80001d86 <growproc+0x3c>
  } else if(n < 0){
    80001d6c:	0204cc63          	bltz	s1,80001da4 <growproc+0x5a>
  p->sz = sz;
    80001d70:	1602                	slli	a2,a2,0x20
    80001d72:	9201                	srli	a2,a2,0x20
    80001d74:	04c93823          	sd	a2,80(s2)
  return 0;
    80001d78:	4501                	li	a0,0
}
    80001d7a:	60e2                	ld	ra,24(sp)
    80001d7c:	6442                	ld	s0,16(sp)
    80001d7e:	64a2                	ld	s1,8(sp)
    80001d80:	6902                	ld	s2,0(sp)
    80001d82:	6105                	addi	sp,sp,32
    80001d84:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d86:	9e25                	addw	a2,a2,s1
    80001d88:	1602                	slli	a2,a2,0x20
    80001d8a:	9201                	srli	a2,a2,0x20
    80001d8c:	1582                	slli	a1,a1,0x20
    80001d8e:	9181                	srli	a1,a1,0x20
    80001d90:	6d28                	ld	a0,88(a0)
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	690080e7          	jalr	1680(ra) # 80001422 <uvmalloc>
    80001d9a:	0005061b          	sext.w	a2,a0
    80001d9e:	fa69                	bnez	a2,80001d70 <growproc+0x26>
      return -1;
    80001da0:	557d                	li	a0,-1
    80001da2:	bfe1                	j	80001d7a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da4:	9e25                	addw	a2,a2,s1
    80001da6:	1602                	slli	a2,a2,0x20
    80001da8:	9201                	srli	a2,a2,0x20
    80001daa:	1582                	slli	a1,a1,0x20
    80001dac:	9181                	srli	a1,a1,0x20
    80001dae:	6d28                	ld	a0,88(a0)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	62a080e7          	jalr	1578(ra) # 800013da <uvmdealloc>
    80001db8:	0005061b          	sext.w	a2,a0
    80001dbc:	bf55                	j	80001d70 <growproc+0x26>

0000000080001dbe <fork>:
{
    80001dbe:	7179                	addi	sp,sp,-48
    80001dc0:	f406                	sd	ra,40(sp)
    80001dc2:	f022                	sd	s0,32(sp)
    80001dc4:	ec26                	sd	s1,24(sp)
    80001dc6:	e84a                	sd	s2,16(sp)
    80001dc8:	e44e                	sd	s3,8(sp)
    80001dca:	e052                	sd	s4,0(sp)
    80001dcc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	be2080e7          	jalr	-1054(ra) # 800019b0 <myproc>
    80001dd6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	de2080e7          	jalr	-542(ra) # 80001bba <allocproc>
    80001de0:	12050163          	beqz	a0,80001f02 <fork+0x144>
    80001de4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001de6:	05093603          	ld	a2,80(s2)
    80001dea:	6d2c                	ld	a1,88(a0)
    80001dec:	05893503          	ld	a0,88(s2)
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	77e080e7          	jalr	1918(ra) # 8000156e <uvmcopy>
    80001df8:	04054663          	bltz	a0,80001e44 <fork+0x86>
  np->sz = p->sz;
    80001dfc:	05093783          	ld	a5,80(s2)
    80001e00:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e04:	06093683          	ld	a3,96(s2)
    80001e08:	87b6                	mv	a5,a3
    80001e0a:	0609b703          	ld	a4,96(s3)
    80001e0e:	12068693          	addi	a3,a3,288
    80001e12:	0007b803          	ld	a6,0(a5)
    80001e16:	6788                	ld	a0,8(a5)
    80001e18:	6b8c                	ld	a1,16(a5)
    80001e1a:	6f90                	ld	a2,24(a5)
    80001e1c:	01073023          	sd	a6,0(a4)
    80001e20:	e708                	sd	a0,8(a4)
    80001e22:	eb0c                	sd	a1,16(a4)
    80001e24:	ef10                	sd	a2,24(a4)
    80001e26:	02078793          	addi	a5,a5,32
    80001e2a:	02070713          	addi	a4,a4,32
    80001e2e:	fed792e3          	bne	a5,a3,80001e12 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e32:	0609b783          	ld	a5,96(s3)
    80001e36:	0607b823          	sd	zero,112(a5)
    80001e3a:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    80001e3e:	15800a13          	li	s4,344
    80001e42:	a03d                	j	80001e70 <fork+0xb2>
    freeproc(np);
    80001e44:	854e                	mv	a0,s3
    80001e46:	00000097          	auipc	ra,0x0
    80001e4a:	d1c080e7          	jalr	-740(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e4e:	854e                	mv	a0,s3
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	e48080e7          	jalr	-440(ra) # 80000c98 <release>
    return -1;
    80001e58:	5a7d                	li	s4,-1
    80001e5a:	a859                	j	80001ef0 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5c:	00002097          	auipc	ra,0x2
    80001e60:	786080e7          	jalr	1926(ra) # 800045e2 <filedup>
    80001e64:	009987b3          	add	a5,s3,s1
    80001e68:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e6a:	04a1                	addi	s1,s1,8
    80001e6c:	01448763          	beq	s1,s4,80001e7a <fork+0xbc>
    if(p->ofile[i])
    80001e70:	009907b3          	add	a5,s2,s1
    80001e74:	6388                	ld	a0,0(a5)
    80001e76:	f17d                	bnez	a0,80001e5c <fork+0x9e>
    80001e78:	bfcd                	j	80001e6a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e7a:	15893503          	ld	a0,344(s2)
    80001e7e:	00002097          	auipc	ra,0x2
    80001e82:	8da080e7          	jalr	-1830(ra) # 80003758 <idup>
    80001e86:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e8a:	4641                	li	a2,16
    80001e8c:	16090593          	addi	a1,s2,352
    80001e90:	16098513          	addi	a0,s3,352
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	f9e080e7          	jalr	-98(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e9c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ea0:	854e                	mv	a0,s3
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	df6080e7          	jalr	-522(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001eaa:	0000f497          	auipc	s1,0xf
    80001eae:	40e48493          	addi	s1,s1,1038 # 800112b8 <wait_lock>
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	d30080e7          	jalr	-720(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ebc:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	dd6080e7          	jalr	-554(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001eca:	854e                	mv	a0,s3
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	d18080e7          	jalr	-744(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ed4:	478d                	li	a5,3
    80001ed6:	00f9ac23          	sw	a5,24(s3)
  np->last_runnable_time = ticks;
    80001eda:	00007797          	auipc	a5,0x7
    80001ede:	15e7a783          	lw	a5,350(a5) # 80009038 <ticks>
    80001ee2:	02f9ae23          	sw	a5,60(s3)
  release(&np->lock);
    80001ee6:	854e                	mv	a0,s3
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	db0080e7          	jalr	-592(ra) # 80000c98 <release>
}
    80001ef0:	8552                	mv	a0,s4
    80001ef2:	70a2                	ld	ra,40(sp)
    80001ef4:	7402                	ld	s0,32(sp)
    80001ef6:	64e2                	ld	s1,24(sp)
    80001ef8:	6942                	ld	s2,16(sp)
    80001efa:	69a2                	ld	s3,8(sp)
    80001efc:	6a02                	ld	s4,0(sp)
    80001efe:	6145                	addi	sp,sp,48
    80001f00:	8082                	ret
    return -1;
    80001f02:	5a7d                	li	s4,-1
    80001f04:	b7f5                	j	80001ef0 <fork+0x132>

0000000080001f06 <scheduler>:
{
    80001f06:	711d                	addi	sp,sp,-96
    80001f08:	ec86                	sd	ra,88(sp)
    80001f0a:	e8a2                	sd	s0,80(sp)
    80001f0c:	e4a6                	sd	s1,72(sp)
    80001f0e:	e0ca                	sd	s2,64(sp)
    80001f10:	fc4e                	sd	s3,56(sp)
    80001f12:	f852                	sd	s4,48(sp)
    80001f14:	f456                	sd	s5,40(sp)
    80001f16:	f05a                	sd	s6,32(sp)
    80001f18:	ec5e                	sd	s7,24(sp)
    80001f1a:	e862                	sd	s8,16(sp)
    80001f1c:	e466                	sd	s9,8(sp)
    80001f1e:	1080                	addi	s0,sp,96
  printf("DAFULT MATAFAKA\n");
    80001f20:	00006517          	auipc	a0,0x6
    80001f24:	32850513          	addi	a0,a0,808 # 80008248 <digits+0x208>
    80001f28:	ffffe097          	auipc	ra,0xffffe
    80001f2c:	660080e7          	jalr	1632(ra) # 80000588 <printf>
    80001f30:	8792                	mv	a5,tp
  int id = r_tp();
    80001f32:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f34:	00779c93          	slli	s9,a5,0x7
    80001f38:	0000f717          	auipc	a4,0xf
    80001f3c:	36870713          	addi	a4,a4,872 # 800112a0 <pid_lock>
    80001f40:	9766                	add	a4,a4,s9
    80001f42:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f46:	0000f717          	auipc	a4,0xf
    80001f4a:	39270713          	addi	a4,a4,914 # 800112d8 <cpus+0x8>
    80001f4e:	9cba                	add	s9,s9,a4
      if(pause_ticks <= ticks ||  p->pid < 3) {
    80001f50:	00007a97          	auipc	s5,0x7
    80001f54:	0d8a8a93          	addi	s5,s5,216 # 80009028 <pause_ticks>
    80001f58:	00007a17          	auipc	s4,0x7
    80001f5c:	0e0a0a13          	addi	s4,s4,224 # 80009038 <ticks>
        if(p->state == RUNNABLE )
    80001f60:	4b0d                	li	s6,3
          c->proc = p;
    80001f62:	079e                	slli	a5,a5,0x7
    80001f64:	0000fb97          	auipc	s7,0xf
    80001f68:	33cb8b93          	addi	s7,s7,828 # 800112a0 <pid_lock>
    80001f6c:	9bbe                	add	s7,s7,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f6e:	00015997          	auipc	s3,0x15
    80001f72:	36298993          	addi	s3,s3,866 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f7e:	10079073          	csrw	sstatus,a5
    80001f82:	0000f497          	auipc	s1,0xf
    80001f86:	74e48493          	addi	s1,s1,1870 # 800116d0 <proc>
          p->state = RUNNING;
    80001f8a:	4c11                	li	s8,4
    80001f8c:	a829                	j	80001fa6 <scheduler+0xa0>
        if(p->state == RUNNABLE )
    80001f8e:	4c9c                	lw	a5,24(s1)
    80001f90:	03678c63          	beq	a5,s6,80001fc8 <scheduler+0xc2>
      release(&p->lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	d02080e7          	jalr	-766(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f9e:	17048493          	addi	s1,s1,368
    80001fa2:	fd348ae3          	beq	s1,s3,80001f76 <scheduler+0x70>
      acquire(&p->lock);
    80001fa6:	8926                	mv	s2,s1
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	c3a080e7          	jalr	-966(ra) # 80000be4 <acquire>
      if(pause_ticks <= ticks ||  p->pid < 3) {
    80001fb2:	000aa703          	lw	a4,0(s5)
    80001fb6:	000a2783          	lw	a5,0(s4)
    80001fba:	fce7fae3          	bgeu	a5,a4,80001f8e <scheduler+0x88>
    80001fbe:	5898                	lw	a4,48(s1)
    80001fc0:	4789                	li	a5,2
    80001fc2:	fce7c9e3          	blt	a5,a4,80001f94 <scheduler+0x8e>
    80001fc6:	b7e1                	j	80001f8e <scheduler+0x88>
          p->state = RUNNING;
    80001fc8:	0184ac23          	sw	s8,24(s1)
          c->proc = p;
    80001fcc:	029bb823          	sd	s1,48(s7)
          swtch(&c->context, &p->context);
    80001fd0:	06890593          	addi	a1,s2,104
    80001fd4:	8566                	mv	a0,s9
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	6f6080e7          	jalr	1782(ra) # 800026cc <swtch>
          c->proc = 0;
    80001fde:	020bb823          	sd	zero,48(s7)
    80001fe2:	bf4d                	j	80001f94 <scheduler+0x8e>

0000000080001fe4 <sched>:
{
    80001fe4:	7179                	addi	sp,sp,-48
    80001fe6:	f406                	sd	ra,40(sp)
    80001fe8:	f022                	sd	s0,32(sp)
    80001fea:	ec26                	sd	s1,24(sp)
    80001fec:	e84a                	sd	s2,16(sp)
    80001fee:	e44e                	sd	s3,8(sp)
    80001ff0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff2:	00000097          	auipc	ra,0x0
    80001ff6:	9be080e7          	jalr	-1602(ra) # 800019b0 <myproc>
    80001ffa:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ffc:	fffff097          	auipc	ra,0xfffff
    80002000:	b6e080e7          	jalr	-1170(ra) # 80000b6a <holding>
    80002004:	c93d                	beqz	a0,8000207a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002006:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002008:	2781                	sext.w	a5,a5
    8000200a:	079e                	slli	a5,a5,0x7
    8000200c:	0000f717          	auipc	a4,0xf
    80002010:	29470713          	addi	a4,a4,660 # 800112a0 <pid_lock>
    80002014:	97ba                	add	a5,a5,a4
    80002016:	0a87a703          	lw	a4,168(a5)
    8000201a:	4785                	li	a5,1
    8000201c:	06f71763          	bne	a4,a5,8000208a <sched+0xa6>
  if(p->state == RUNNING)
    80002020:	4c98                	lw	a4,24(s1)
    80002022:	4791                	li	a5,4
    80002024:	06f70b63          	beq	a4,a5,8000209a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002028:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000202c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000202e:	efb5                	bnez	a5,800020aa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002030:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002032:	0000f917          	auipc	s2,0xf
    80002036:	26e90913          	addi	s2,s2,622 # 800112a0 <pid_lock>
    8000203a:	2781                	sext.w	a5,a5
    8000203c:	079e                	slli	a5,a5,0x7
    8000203e:	97ca                	add	a5,a5,s2
    80002040:	0ac7a983          	lw	s3,172(a5)
    80002044:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002046:	2781                	sext.w	a5,a5
    80002048:	079e                	slli	a5,a5,0x7
    8000204a:	0000f597          	auipc	a1,0xf
    8000204e:	28e58593          	addi	a1,a1,654 # 800112d8 <cpus+0x8>
    80002052:	95be                	add	a1,a1,a5
    80002054:	06848513          	addi	a0,s1,104
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	674080e7          	jalr	1652(ra) # 800026cc <swtch>
    80002060:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002062:	2781                	sext.w	a5,a5
    80002064:	079e                	slli	a5,a5,0x7
    80002066:	97ca                	add	a5,a5,s2
    80002068:	0b37a623          	sw	s3,172(a5)
}
    8000206c:	70a2                	ld	ra,40(sp)
    8000206e:	7402                	ld	s0,32(sp)
    80002070:	64e2                	ld	s1,24(sp)
    80002072:	6942                	ld	s2,16(sp)
    80002074:	69a2                	ld	s3,8(sp)
    80002076:	6145                	addi	sp,sp,48
    80002078:	8082                	ret
    panic("sched p->lock");
    8000207a:	00006517          	auipc	a0,0x6
    8000207e:	1e650513          	addi	a0,a0,486 # 80008260 <digits+0x220>
    80002082:	ffffe097          	auipc	ra,0xffffe
    80002086:	4bc080e7          	jalr	1212(ra) # 8000053e <panic>
    panic("sched locks");
    8000208a:	00006517          	auipc	a0,0x6
    8000208e:	1e650513          	addi	a0,a0,486 # 80008270 <digits+0x230>
    80002092:	ffffe097          	auipc	ra,0xffffe
    80002096:	4ac080e7          	jalr	1196(ra) # 8000053e <panic>
    panic("sched running");
    8000209a:	00006517          	auipc	a0,0x6
    8000209e:	1e650513          	addi	a0,a0,486 # 80008280 <digits+0x240>
    800020a2:	ffffe097          	auipc	ra,0xffffe
    800020a6:	49c080e7          	jalr	1180(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020aa:	00006517          	auipc	a0,0x6
    800020ae:	1e650513          	addi	a0,a0,486 # 80008290 <digits+0x250>
    800020b2:	ffffe097          	auipc	ra,0xffffe
    800020b6:	48c080e7          	jalr	1164(ra) # 8000053e <panic>

00000000800020ba <yield>:
{
    800020ba:	1101                	addi	sp,sp,-32
    800020bc:	ec06                	sd	ra,24(sp)
    800020be:	e822                	sd	s0,16(sp)
    800020c0:	e426                	sd	s1,8(sp)
    800020c2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	8ec080e7          	jalr	-1812(ra) # 800019b0 <myproc>
    800020cc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	b16080e7          	jalr	-1258(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020d6:	478d                	li	a5,3
    800020d8:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    800020da:	00007797          	auipc	a5,0x7
    800020de:	f5e7a783          	lw	a5,-162(a5) # 80009038 <ticks>
    800020e2:	dcdc                	sw	a5,60(s1)
  sched();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	f00080e7          	jalr	-256(ra) # 80001fe4 <sched>
  release(&p->lock);
    800020ec:	8526                	mv	a0,s1
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	baa080e7          	jalr	-1110(ra) # 80000c98 <release>
}
    800020f6:	60e2                	ld	ra,24(sp)
    800020f8:	6442                	ld	s0,16(sp)
    800020fa:	64a2                	ld	s1,8(sp)
    800020fc:	6105                	addi	sp,sp,32
    800020fe:	8082                	ret

0000000080002100 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002100:	7179                	addi	sp,sp,-48
    80002102:	f406                	sd	ra,40(sp)
    80002104:	f022                	sd	s0,32(sp)
    80002106:	ec26                	sd	s1,24(sp)
    80002108:	e84a                	sd	s2,16(sp)
    8000210a:	e44e                	sd	s3,8(sp)
    8000210c:	1800                	addi	s0,sp,48
    8000210e:	89aa                	mv	s3,a0
    80002110:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002112:	00000097          	auipc	ra,0x0
    80002116:	89e080e7          	jalr	-1890(ra) # 800019b0 <myproc>
    8000211a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	ac8080e7          	jalr	-1336(ra) # 80000be4 <acquire>
  release(lk);
    80002124:	854a                	mv	a0,s2
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	b72080e7          	jalr	-1166(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000212e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002132:	4789                	li	a5,2
    80002134:	cc9c                	sw	a5,24(s1)

  sched();
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	eae080e7          	jalr	-338(ra) # 80001fe4 <sched>

  // Tidy up.
  p->chan = 0;
    8000213e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002142:	8526                	mv	a0,s1
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	b54080e7          	jalr	-1196(ra) # 80000c98 <release>
  acquire(lk);
    8000214c:	854a                	mv	a0,s2
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	a96080e7          	jalr	-1386(ra) # 80000be4 <acquire>
}
    80002156:	70a2                	ld	ra,40(sp)
    80002158:	7402                	ld	s0,32(sp)
    8000215a:	64e2                	ld	s1,24(sp)
    8000215c:	6942                	ld	s2,16(sp)
    8000215e:	69a2                	ld	s3,8(sp)
    80002160:	6145                	addi	sp,sp,48
    80002162:	8082                	ret

0000000080002164 <wait>:
{
    80002164:	715d                	addi	sp,sp,-80
    80002166:	e486                	sd	ra,72(sp)
    80002168:	e0a2                	sd	s0,64(sp)
    8000216a:	fc26                	sd	s1,56(sp)
    8000216c:	f84a                	sd	s2,48(sp)
    8000216e:	f44e                	sd	s3,40(sp)
    80002170:	f052                	sd	s4,32(sp)
    80002172:	ec56                	sd	s5,24(sp)
    80002174:	e85a                	sd	s6,16(sp)
    80002176:	e45e                	sd	s7,8(sp)
    80002178:	e062                	sd	s8,0(sp)
    8000217a:	0880                	addi	s0,sp,80
    8000217c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	832080e7          	jalr	-1998(ra) # 800019b0 <myproc>
    80002186:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002188:	0000f517          	auipc	a0,0xf
    8000218c:	13050513          	addi	a0,a0,304 # 800112b8 <wait_lock>
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	a54080e7          	jalr	-1452(ra) # 80000be4 <acquire>
    havekids = 0;
    80002198:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000219a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000219c:	00015997          	auipc	s3,0x15
    800021a0:	13498993          	addi	s3,s3,308 # 800172d0 <tickslock>
        havekids = 1;
    800021a4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021a6:	0000fc17          	auipc	s8,0xf
    800021aa:	112c0c13          	addi	s8,s8,274 # 800112b8 <wait_lock>
    havekids = 0;
    800021ae:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800021b0:	0000f497          	auipc	s1,0xf
    800021b4:	52048493          	addi	s1,s1,1312 # 800116d0 <proc>
    800021b8:	a0bd                	j	80002226 <wait+0xc2>
          pid = np->pid;
    800021ba:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021be:	000b0e63          	beqz	s6,800021da <wait+0x76>
    800021c2:	4691                	li	a3,4
    800021c4:	02c48613          	addi	a2,s1,44
    800021c8:	85da                	mv	a1,s6
    800021ca:	05893503          	ld	a0,88(s2)
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	4a4080e7          	jalr	1188(ra) # 80001672 <copyout>
    800021d6:	02054563          	bltz	a0,80002200 <wait+0x9c>
          freeproc(np);
    800021da:	8526                	mv	a0,s1
    800021dc:	00000097          	auipc	ra,0x0
    800021e0:	986080e7          	jalr	-1658(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	ab2080e7          	jalr	-1358(ra) # 80000c98 <release>
          release(&wait_lock);
    800021ee:	0000f517          	auipc	a0,0xf
    800021f2:	0ca50513          	addi	a0,a0,202 # 800112b8 <wait_lock>
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	aa2080e7          	jalr	-1374(ra) # 80000c98 <release>
          return pid;
    800021fe:	a09d                	j	80002264 <wait+0x100>
            release(&np->lock);
    80002200:	8526                	mv	a0,s1
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	a96080e7          	jalr	-1386(ra) # 80000c98 <release>
            release(&wait_lock);
    8000220a:	0000f517          	auipc	a0,0xf
    8000220e:	0ae50513          	addi	a0,a0,174 # 800112b8 <wait_lock>
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a86080e7          	jalr	-1402(ra) # 80000c98 <release>
            return -1;
    8000221a:	59fd                	li	s3,-1
    8000221c:	a0a1                	j	80002264 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000221e:	17048493          	addi	s1,s1,368
    80002222:	03348463          	beq	s1,s3,8000224a <wait+0xe6>
      if(np->parent == p){
    80002226:	60bc                	ld	a5,64(s1)
    80002228:	ff279be3          	bne	a5,s2,8000221e <wait+0xba>
        acquire(&np->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	9b6080e7          	jalr	-1610(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002236:	4c9c                	lw	a5,24(s1)
    80002238:	f94781e3          	beq	a5,s4,800021ba <wait+0x56>
        release(&np->lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a5a080e7          	jalr	-1446(ra) # 80000c98 <release>
        havekids = 1;
    80002246:	8756                	mv	a4,s5
    80002248:	bfd9                	j	8000221e <wait+0xba>
    if(!havekids || p->killed){
    8000224a:	c701                	beqz	a4,80002252 <wait+0xee>
    8000224c:	02892783          	lw	a5,40(s2)
    80002250:	c79d                	beqz	a5,8000227e <wait+0x11a>
      release(&wait_lock);
    80002252:	0000f517          	auipc	a0,0xf
    80002256:	06650513          	addi	a0,a0,102 # 800112b8 <wait_lock>
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	a3e080e7          	jalr	-1474(ra) # 80000c98 <release>
      return -1;
    80002262:	59fd                	li	s3,-1
}
    80002264:	854e                	mv	a0,s3
    80002266:	60a6                	ld	ra,72(sp)
    80002268:	6406                	ld	s0,64(sp)
    8000226a:	74e2                	ld	s1,56(sp)
    8000226c:	7942                	ld	s2,48(sp)
    8000226e:	79a2                	ld	s3,40(sp)
    80002270:	7a02                	ld	s4,32(sp)
    80002272:	6ae2                	ld	s5,24(sp)
    80002274:	6b42                	ld	s6,16(sp)
    80002276:	6ba2                	ld	s7,8(sp)
    80002278:	6c02                	ld	s8,0(sp)
    8000227a:	6161                	addi	sp,sp,80
    8000227c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000227e:	85e2                	mv	a1,s8
    80002280:	854a                	mv	a0,s2
    80002282:	00000097          	auipc	ra,0x0
    80002286:	e7e080e7          	jalr	-386(ra) # 80002100 <sleep>
    havekids = 0;
    8000228a:	b715                	j	800021ae <wait+0x4a>

000000008000228c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000228c:	7139                	addi	sp,sp,-64
    8000228e:	fc06                	sd	ra,56(sp)
    80002290:	f822                	sd	s0,48(sp)
    80002292:	f426                	sd	s1,40(sp)
    80002294:	f04a                	sd	s2,32(sp)
    80002296:	ec4e                	sd	s3,24(sp)
    80002298:	e852                	sd	s4,16(sp)
    8000229a:	e456                	sd	s5,8(sp)
    8000229c:	e05a                	sd	s6,0(sp)
    8000229e:	0080                	addi	s0,sp,64
    800022a0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022a2:	0000f497          	auipc	s1,0xf
    800022a6:	42e48493          	addi	s1,s1,1070 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022aa:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022ac:	4b0d                	li	s6,3
        p->last_runnable_time = ticks;
    800022ae:	00007a97          	auipc	s5,0x7
    800022b2:	d8aa8a93          	addi	s5,s5,-630 # 80009038 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022b6:	00015917          	auipc	s2,0x15
    800022ba:	01a90913          	addi	s2,s2,26 # 800172d0 <tickslock>
    800022be:	a839                	j	800022dc <wakeup+0x50>
        p->state = RUNNABLE;
    800022c0:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    800022c4:	000aa783          	lw	a5,0(s5)
    800022c8:	dcdc                	sw	a5,60(s1)
      }
      release(&p->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	9cc080e7          	jalr	-1588(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022d4:	17048493          	addi	s1,s1,368
    800022d8:	03248463          	beq	s1,s2,80002300 <wakeup+0x74>
    if(p != myproc()){
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	6d4080e7          	jalr	1748(ra) # 800019b0 <myproc>
    800022e4:	fea488e3          	beq	s1,a0,800022d4 <wakeup+0x48>
      acquire(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	8fa080e7          	jalr	-1798(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022f2:	4c9c                	lw	a5,24(s1)
    800022f4:	fd379be3          	bne	a5,s3,800022ca <wakeup+0x3e>
    800022f8:	709c                	ld	a5,32(s1)
    800022fa:	fd4798e3          	bne	a5,s4,800022ca <wakeup+0x3e>
    800022fe:	b7c9                	j	800022c0 <wakeup+0x34>
    }
  }
}
    80002300:	70e2                	ld	ra,56(sp)
    80002302:	7442                	ld	s0,48(sp)
    80002304:	74a2                	ld	s1,40(sp)
    80002306:	7902                	ld	s2,32(sp)
    80002308:	69e2                	ld	s3,24(sp)
    8000230a:	6a42                	ld	s4,16(sp)
    8000230c:	6aa2                	ld	s5,8(sp)
    8000230e:	6b02                	ld	s6,0(sp)
    80002310:	6121                	addi	sp,sp,64
    80002312:	8082                	ret

0000000080002314 <reparent>:
{
    80002314:	7179                	addi	sp,sp,-48
    80002316:	f406                	sd	ra,40(sp)
    80002318:	f022                	sd	s0,32(sp)
    8000231a:	ec26                	sd	s1,24(sp)
    8000231c:	e84a                	sd	s2,16(sp)
    8000231e:	e44e                	sd	s3,8(sp)
    80002320:	e052                	sd	s4,0(sp)
    80002322:	1800                	addi	s0,sp,48
    80002324:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002326:	0000f497          	auipc	s1,0xf
    8000232a:	3aa48493          	addi	s1,s1,938 # 800116d0 <proc>
      pp->parent = initproc;
    8000232e:	00007a17          	auipc	s4,0x7
    80002332:	d02a0a13          	addi	s4,s4,-766 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002336:	00015997          	auipc	s3,0x15
    8000233a:	f9a98993          	addi	s3,s3,-102 # 800172d0 <tickslock>
    8000233e:	a029                	j	80002348 <reparent+0x34>
    80002340:	17048493          	addi	s1,s1,368
    80002344:	01348d63          	beq	s1,s3,8000235e <reparent+0x4a>
    if(pp->parent == p){
    80002348:	60bc                	ld	a5,64(s1)
    8000234a:	ff279be3          	bne	a5,s2,80002340 <reparent+0x2c>
      pp->parent = initproc;
    8000234e:	000a3503          	ld	a0,0(s4)
    80002352:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    80002354:	00000097          	auipc	ra,0x0
    80002358:	f38080e7          	jalr	-200(ra) # 8000228c <wakeup>
    8000235c:	b7d5                	j	80002340 <reparent+0x2c>
}
    8000235e:	70a2                	ld	ra,40(sp)
    80002360:	7402                	ld	s0,32(sp)
    80002362:	64e2                	ld	s1,24(sp)
    80002364:	6942                	ld	s2,16(sp)
    80002366:	69a2                	ld	s3,8(sp)
    80002368:	6a02                	ld	s4,0(sp)
    8000236a:	6145                	addi	sp,sp,48
    8000236c:	8082                	ret

000000008000236e <exit>:
{
    8000236e:	7179                	addi	sp,sp,-48
    80002370:	f406                	sd	ra,40(sp)
    80002372:	f022                	sd	s0,32(sp)
    80002374:	ec26                	sd	s1,24(sp)
    80002376:	e84a                	sd	s2,16(sp)
    80002378:	e44e                	sd	s3,8(sp)
    8000237a:	e052                	sd	s4,0(sp)
    8000237c:	1800                	addi	s0,sp,48
    8000237e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	630080e7          	jalr	1584(ra) # 800019b0 <myproc>
    80002388:	89aa                	mv	s3,a0
  if(p == initproc)
    8000238a:	00007797          	auipc	a5,0x7
    8000238e:	ca67b783          	ld	a5,-858(a5) # 80009030 <initproc>
    80002392:	0d850493          	addi	s1,a0,216
    80002396:	15850913          	addi	s2,a0,344
    8000239a:	02a79363          	bne	a5,a0,800023c0 <exit+0x52>
    panic("init exiting");
    8000239e:	00006517          	auipc	a0,0x6
    800023a2:	f0a50513          	addi	a0,a0,-246 # 800082a8 <digits+0x268>
    800023a6:	ffffe097          	auipc	ra,0xffffe
    800023aa:	198080e7          	jalr	408(ra) # 8000053e <panic>
      fileclose(f);
    800023ae:	00002097          	auipc	ra,0x2
    800023b2:	286080e7          	jalr	646(ra) # 80004634 <fileclose>
      p->ofile[fd] = 0;
    800023b6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023ba:	04a1                	addi	s1,s1,8
    800023bc:	01248563          	beq	s1,s2,800023c6 <exit+0x58>
    if(p->ofile[fd]){
    800023c0:	6088                	ld	a0,0(s1)
    800023c2:	f575                	bnez	a0,800023ae <exit+0x40>
    800023c4:	bfdd                	j	800023ba <exit+0x4c>
  begin_op();
    800023c6:	00002097          	auipc	ra,0x2
    800023ca:	da2080e7          	jalr	-606(ra) # 80004168 <begin_op>
  iput(p->cwd);
    800023ce:	1589b503          	ld	a0,344(s3)
    800023d2:	00001097          	auipc	ra,0x1
    800023d6:	57e080e7          	jalr	1406(ra) # 80003950 <iput>
  end_op();
    800023da:	00002097          	auipc	ra,0x2
    800023de:	e0e080e7          	jalr	-498(ra) # 800041e8 <end_op>
  p->cwd = 0;
    800023e2:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    800023e6:	0000f497          	auipc	s1,0xf
    800023ea:	ed248493          	addi	s1,s1,-302 # 800112b8 <wait_lock>
    800023ee:	8526                	mv	a0,s1
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	7f4080e7          	jalr	2036(ra) # 80000be4 <acquire>
  reparent(p);
    800023f8:	854e                	mv	a0,s3
    800023fa:	00000097          	auipc	ra,0x0
    800023fe:	f1a080e7          	jalr	-230(ra) # 80002314 <reparent>
  wakeup(p->parent);
    80002402:	0409b503          	ld	a0,64(s3)
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	e86080e7          	jalr	-378(ra) # 8000228c <wakeup>
  acquire(&p->lock);
    8000240e:	854e                	mv	a0,s3
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	7d4080e7          	jalr	2004(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002418:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000241c:	4795                	li	a5,5
    8000241e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	874080e7          	jalr	-1932(ra) # 80000c98 <release>
  sched();
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	bb8080e7          	jalr	-1096(ra) # 80001fe4 <sched>
  panic("zombie exit");
    80002434:	00006517          	auipc	a0,0x6
    80002438:	e8450513          	addi	a0,a0,-380 # 800082b8 <digits+0x278>
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	102080e7          	jalr	258(ra) # 8000053e <panic>

0000000080002444 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002444:	7179                	addi	sp,sp,-48
    80002446:	f406                	sd	ra,40(sp)
    80002448:	f022                	sd	s0,32(sp)
    8000244a:	ec26                	sd	s1,24(sp)
    8000244c:	e84a                	sd	s2,16(sp)
    8000244e:	e44e                	sd	s3,8(sp)
    80002450:	1800                	addi	s0,sp,48
    80002452:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002454:	0000f497          	auipc	s1,0xf
    80002458:	27c48493          	addi	s1,s1,636 # 800116d0 <proc>
    8000245c:	00015997          	auipc	s3,0x15
    80002460:	e7498993          	addi	s3,s3,-396 # 800172d0 <tickslock>
    acquire(&p->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	ffffe097          	auipc	ra,0xffffe
    8000246a:	77e080e7          	jalr	1918(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000246e:	589c                	lw	a5,48(s1)
    80002470:	01278d63          	beq	a5,s2,8000248a <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	822080e7          	jalr	-2014(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000247e:	17048493          	addi	s1,s1,368
    80002482:	ff3491e3          	bne	s1,s3,80002464 <kill+0x20>
  }
  return -1;
    80002486:	557d                	li	a0,-1
    80002488:	a829                	j	800024a2 <kill+0x5e>
      p->killed = 1;
    8000248a:	4785                	li	a5,1
    8000248c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000248e:	4c98                	lw	a4,24(s1)
    80002490:	4789                	li	a5,2
    80002492:	00f70f63          	beq	a4,a5,800024b0 <kill+0x6c>
      release(&p->lock);
    80002496:	8526                	mv	a0,s1
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	800080e7          	jalr	-2048(ra) # 80000c98 <release>
      return 0;
    800024a0:	4501                	li	a0,0
}
    800024a2:	70a2                	ld	ra,40(sp)
    800024a4:	7402                	ld	s0,32(sp)
    800024a6:	64e2                	ld	s1,24(sp)
    800024a8:	6942                	ld	s2,16(sp)
    800024aa:	69a2                	ld	s3,8(sp)
    800024ac:	6145                	addi	sp,sp,48
    800024ae:	8082                	ret
        p->state = RUNNABLE;
    800024b0:	478d                	li	a5,3
    800024b2:	cc9c                	sw	a5,24(s1)
        p->last_runnable_time = ticks;
    800024b4:	00007797          	auipc	a5,0x7
    800024b8:	b847a783          	lw	a5,-1148(a5) # 80009038 <ticks>
    800024bc:	dcdc                	sw	a5,60(s1)
    800024be:	bfe1                	j	80002496 <kill+0x52>

00000000800024c0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024c0:	7179                	addi	sp,sp,-48
    800024c2:	f406                	sd	ra,40(sp)
    800024c4:	f022                	sd	s0,32(sp)
    800024c6:	ec26                	sd	s1,24(sp)
    800024c8:	e84a                	sd	s2,16(sp)
    800024ca:	e44e                	sd	s3,8(sp)
    800024cc:	e052                	sd	s4,0(sp)
    800024ce:	1800                	addi	s0,sp,48
    800024d0:	84aa                	mv	s1,a0
    800024d2:	892e                	mv	s2,a1
    800024d4:	89b2                	mv	s3,a2
    800024d6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	4d8080e7          	jalr	1240(ra) # 800019b0 <myproc>
  if(user_dst){
    800024e0:	c08d                	beqz	s1,80002502 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024e2:	86d2                	mv	a3,s4
    800024e4:	864e                	mv	a2,s3
    800024e6:	85ca                	mv	a1,s2
    800024e8:	6d28                	ld	a0,88(a0)
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	188080e7          	jalr	392(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024f2:	70a2                	ld	ra,40(sp)
    800024f4:	7402                	ld	s0,32(sp)
    800024f6:	64e2                	ld	s1,24(sp)
    800024f8:	6942                	ld	s2,16(sp)
    800024fa:	69a2                	ld	s3,8(sp)
    800024fc:	6a02                	ld	s4,0(sp)
    800024fe:	6145                	addi	sp,sp,48
    80002500:	8082                	ret
    memmove((char *)dst, src, len);
    80002502:	000a061b          	sext.w	a2,s4
    80002506:	85ce                	mv	a1,s3
    80002508:	854a                	mv	a0,s2
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	836080e7          	jalr	-1994(ra) # 80000d40 <memmove>
    return 0;
    80002512:	8526                	mv	a0,s1
    80002514:	bff9                	j	800024f2 <either_copyout+0x32>

0000000080002516 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002516:	7179                	addi	sp,sp,-48
    80002518:	f406                	sd	ra,40(sp)
    8000251a:	f022                	sd	s0,32(sp)
    8000251c:	ec26                	sd	s1,24(sp)
    8000251e:	e84a                	sd	s2,16(sp)
    80002520:	e44e                	sd	s3,8(sp)
    80002522:	e052                	sd	s4,0(sp)
    80002524:	1800                	addi	s0,sp,48
    80002526:	892a                	mv	s2,a0
    80002528:	84ae                	mv	s1,a1
    8000252a:	89b2                	mv	s3,a2
    8000252c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	482080e7          	jalr	1154(ra) # 800019b0 <myproc>
  if(user_src){
    80002536:	c08d                	beqz	s1,80002558 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002538:	86d2                	mv	a3,s4
    8000253a:	864e                	mv	a2,s3
    8000253c:	85ca                	mv	a1,s2
    8000253e:	6d28                	ld	a0,88(a0)
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	1be080e7          	jalr	446(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002548:	70a2                	ld	ra,40(sp)
    8000254a:	7402                	ld	s0,32(sp)
    8000254c:	64e2                	ld	s1,24(sp)
    8000254e:	6942                	ld	s2,16(sp)
    80002550:	69a2                	ld	s3,8(sp)
    80002552:	6a02                	ld	s4,0(sp)
    80002554:	6145                	addi	sp,sp,48
    80002556:	8082                	ret
    memmove(dst, (char*)src, len);
    80002558:	000a061b          	sext.w	a2,s4
    8000255c:	85ce                	mv	a1,s3
    8000255e:	854a                	mv	a0,s2
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	7e0080e7          	jalr	2016(ra) # 80000d40 <memmove>
    return 0;
    80002568:	8526                	mv	a0,s1
    8000256a:	bff9                	j	80002548 <either_copyin+0x32>

000000008000256c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000256c:	715d                	addi	sp,sp,-80
    8000256e:	e486                	sd	ra,72(sp)
    80002570:	e0a2                	sd	s0,64(sp)
    80002572:	fc26                	sd	s1,56(sp)
    80002574:	f84a                	sd	s2,48(sp)
    80002576:	f44e                	sd	s3,40(sp)
    80002578:	f052                	sd	s4,32(sp)
    8000257a:	ec56                	sd	s5,24(sp)
    8000257c:	e85a                	sd	s6,16(sp)
    8000257e:	e45e                	sd	s7,8(sp)
    80002580:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002582:	00006517          	auipc	a0,0x6
    80002586:	b4650513          	addi	a0,a0,-1210 # 800080c8 <digits+0x88>
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	ffe080e7          	jalr	-2(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002592:	0000f497          	auipc	s1,0xf
    80002596:	29e48493          	addi	s1,s1,670 # 80011830 <proc+0x160>
    8000259a:	00015917          	auipc	s2,0x15
    8000259e:	e9690913          	addi	s2,s2,-362 # 80017430 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025a4:	00006997          	auipc	s3,0x6
    800025a8:	d2498993          	addi	s3,s3,-732 # 800082c8 <digits+0x288>
    printf("%d %s %s", p->pid, state, p->name);
    800025ac:	00006a97          	auipc	s5,0x6
    800025b0:	d24a8a93          	addi	s5,s5,-732 # 800082d0 <digits+0x290>
    printf("\n");
    800025b4:	00006a17          	auipc	s4,0x6
    800025b8:	b14a0a13          	addi	s4,s4,-1260 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025bc:	00006b97          	auipc	s7,0x6
    800025c0:	d4cb8b93          	addi	s7,s7,-692 # 80008308 <states.1718>
    800025c4:	a00d                	j	800025e6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025c6:	ed06a583          	lw	a1,-304(a3)
    800025ca:	8556                	mv	a0,s5
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbc080e7          	jalr	-68(ra) # 80000588 <printf>
    printf("\n");
    800025d4:	8552                	mv	a0,s4
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	fb2080e7          	jalr	-78(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025de:	17048493          	addi	s1,s1,368
    800025e2:	03248163          	beq	s1,s2,80002604 <procdump+0x98>
    if(p->state == UNUSED)
    800025e6:	86a6                	mv	a3,s1
    800025e8:	eb84a783          	lw	a5,-328(s1)
    800025ec:	dbed                	beqz	a5,800025de <procdump+0x72>
      state = "???";
    800025ee:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f0:	fcfb6be3          	bltu	s6,a5,800025c6 <procdump+0x5a>
    800025f4:	1782                	slli	a5,a5,0x20
    800025f6:	9381                	srli	a5,a5,0x20
    800025f8:	078e                	slli	a5,a5,0x3
    800025fa:	97de                	add	a5,a5,s7
    800025fc:	6390                	ld	a2,0(a5)
    800025fe:	f661                	bnez	a2,800025c6 <procdump+0x5a>
      state = "???";
    80002600:	864e                	mv	a2,s3
    80002602:	b7d1                	j	800025c6 <procdump+0x5a>
  }
}
    80002604:	60a6                	ld	ra,72(sp)
    80002606:	6406                	ld	s0,64(sp)
    80002608:	74e2                	ld	s1,56(sp)
    8000260a:	7942                	ld	s2,48(sp)
    8000260c:	79a2                	ld	s3,40(sp)
    8000260e:	7a02                	ld	s4,32(sp)
    80002610:	6ae2                	ld	s5,24(sp)
    80002612:	6b42                	ld	s6,16(sp)
    80002614:	6ba2                	ld	s7,8(sp)
    80002616:	6161                	addi	sp,sp,80
    80002618:	8082                	ret

000000008000261a <kill_system>:

/*-----------------------------------*********************-----------------------------------*********************-----------------------------------*/

int kill_system(void)
{
    8000261a:	7179                	addi	sp,sp,-48
    8000261c:	f406                	sd	ra,40(sp)
    8000261e:	f022                	sd	s0,32(sp)
    80002620:	ec26                	sd	s1,24(sp)
    80002622:	e84a                	sd	s2,16(sp)
    80002624:	e44e                	sd	s3,8(sp)
    80002626:	e052                	sd	s4,0(sp)
    80002628:	1800                	addi	s0,sp,48
  int syscall_status = 0;
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
    8000262a:	0000f497          	auipc	s1,0xf
    8000262e:	0a648493          	addi	s1,s1,166 # 800116d0 <proc>
  int syscall_status = 0;
    80002632:	4901                	li	s2,0
  {
    acquire(&p->lock);
    if (p->pid > 2)
    80002634:	4a09                	li	s4,2
  for(p = proc; p < &proc[NPROC]; p++)
    80002636:	00015997          	auipc	s3,0x15
    8000263a:	c9a98993          	addi	s3,s3,-870 # 800172d0 <tickslock>
    8000263e:	a811                	j	80002652 <kill_system+0x38>
      release(&p->lock);
      syscall_status = kill(p->pid) || syscall_status;
    }
    else
    {
    release(&p->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	656080e7          	jalr	1622(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++)
    8000264a:	17048493          	addi	s1,s1,368
    8000264e:	03348a63          	beq	s1,s3,80002682 <kill_system+0x68>
    acquire(&p->lock);
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	590080e7          	jalr	1424(ra) # 80000be4 <acquire>
    if (p->pid > 2)
    8000265c:	589c                	lw	a5,48(s1)
    8000265e:	fefa51e3          	bge	s4,a5,80002640 <kill_system+0x26>
      release(&p->lock);
    80002662:	8526                	mv	a0,s1
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	634080e7          	jalr	1588(ra) # 80000c98 <release>
      syscall_status = kill(p->pid) || syscall_status;
    8000266c:	5888                	lw	a0,48(s1)
    8000266e:	00000097          	auipc	ra,0x0
    80002672:	dd6080e7          	jalr	-554(ra) # 80002444 <kill>
    80002676:	01256533          	or	a0,a0,s2
    8000267a:	2501                	sext.w	a0,a0
    8000267c:	00a03933          	snez	s2,a0
    80002680:	b7e9                	j	8000264a <kill_system+0x30>
    }
  }
  return !syscall_status ? 0 : -1;
}
    80002682:	41200533          	neg	a0,s2
    80002686:	70a2                	ld	ra,40(sp)
    80002688:	7402                	ld	s0,32(sp)
    8000268a:	64e2                	ld	s1,24(sp)
    8000268c:	6942                	ld	s2,16(sp)
    8000268e:	69a2                	ld	s3,8(sp)
    80002690:	6a02                	ld	s4,0(sp)
    80002692:	6145                	addi	sp,sp,48
    80002694:	8082                	ret

0000000080002696 <pause_system>:

int pause_system(int seconds)
{
    80002696:	1141                	addi	sp,sp,-16
    80002698:	e406                	sd	ra,8(sp)
    8000269a:	e022                	sd	s0,0(sp)
    8000269c:	0800                	addi	s0,sp,16
  pause_ticks = (seconds * 10) + ticks;
    8000269e:	0025179b          	slliw	a5,a0,0x2
    800026a2:	9fa9                	addw	a5,a5,a0
    800026a4:	0017979b          	slliw	a5,a5,0x1
    800026a8:	00007517          	auipc	a0,0x7
    800026ac:	99052503          	lw	a0,-1648(a0) # 80009038 <ticks>
    800026b0:	9fa9                	addw	a5,a5,a0
    800026b2:	00007717          	auipc	a4,0x7
    800026b6:	96f72b23          	sw	a5,-1674(a4) # 80009028 <pause_ticks>
  yield();
    800026ba:	00000097          	auipc	ra,0x0
    800026be:	a00080e7          	jalr	-1536(ra) # 800020ba <yield>
  return 0;
    800026c2:	4501                	li	a0,0
    800026c4:	60a2                	ld	ra,8(sp)
    800026c6:	6402                	ld	s0,0(sp)
    800026c8:	0141                	addi	sp,sp,16
    800026ca:	8082                	ret

00000000800026cc <swtch>:
    800026cc:	00153023          	sd	ra,0(a0)
    800026d0:	00253423          	sd	sp,8(a0)
    800026d4:	e900                	sd	s0,16(a0)
    800026d6:	ed04                	sd	s1,24(a0)
    800026d8:	03253023          	sd	s2,32(a0)
    800026dc:	03353423          	sd	s3,40(a0)
    800026e0:	03453823          	sd	s4,48(a0)
    800026e4:	03553c23          	sd	s5,56(a0)
    800026e8:	05653023          	sd	s6,64(a0)
    800026ec:	05753423          	sd	s7,72(a0)
    800026f0:	05853823          	sd	s8,80(a0)
    800026f4:	05953c23          	sd	s9,88(a0)
    800026f8:	07a53023          	sd	s10,96(a0)
    800026fc:	07b53423          	sd	s11,104(a0)
    80002700:	0005b083          	ld	ra,0(a1)
    80002704:	0085b103          	ld	sp,8(a1)
    80002708:	6980                	ld	s0,16(a1)
    8000270a:	6d84                	ld	s1,24(a1)
    8000270c:	0205b903          	ld	s2,32(a1)
    80002710:	0285b983          	ld	s3,40(a1)
    80002714:	0305ba03          	ld	s4,48(a1)
    80002718:	0385ba83          	ld	s5,56(a1)
    8000271c:	0405bb03          	ld	s6,64(a1)
    80002720:	0485bb83          	ld	s7,72(a1)
    80002724:	0505bc03          	ld	s8,80(a1)
    80002728:	0585bc83          	ld	s9,88(a1)
    8000272c:	0605bd03          	ld	s10,96(a1)
    80002730:	0685bd83          	ld	s11,104(a1)
    80002734:	8082                	ret

0000000080002736 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002736:	1141                	addi	sp,sp,-16
    80002738:	e406                	sd	ra,8(sp)
    8000273a:	e022                	sd	s0,0(sp)
    8000273c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000273e:	00006597          	auipc	a1,0x6
    80002742:	bfa58593          	addi	a1,a1,-1030 # 80008338 <states.1718+0x30>
    80002746:	00015517          	auipc	a0,0x15
    8000274a:	b8a50513          	addi	a0,a0,-1142 # 800172d0 <tickslock>
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	406080e7          	jalr	1030(ra) # 80000b54 <initlock>
}
    80002756:	60a2                	ld	ra,8(sp)
    80002758:	6402                	ld	s0,0(sp)
    8000275a:	0141                	addi	sp,sp,16
    8000275c:	8082                	ret

000000008000275e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000275e:	1141                	addi	sp,sp,-16
    80002760:	e422                	sd	s0,8(sp)
    80002762:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002764:	00003797          	auipc	a5,0x3
    80002768:	4ec78793          	addi	a5,a5,1260 # 80005c50 <kernelvec>
    8000276c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002770:	6422                	ld	s0,8(sp)
    80002772:	0141                	addi	sp,sp,16
    80002774:	8082                	ret

0000000080002776 <yield_wrap>:

#ifdef DEFAULT
void
yield_wrap(){
    80002776:	1141                	addi	sp,sp,-16
    80002778:	e406                	sd	ra,8(sp)
    8000277a:	e022                	sd	s0,0(sp)
    8000277c:	0800                	addi	s0,sp,16
  yield();
    8000277e:	00000097          	auipc	ra,0x0
    80002782:	93c080e7          	jalr	-1732(ra) # 800020ba <yield>
}
    80002786:	60a2                	ld	ra,8(sp)
    80002788:	6402                	ld	s0,0(sp)
    8000278a:	0141                	addi	sp,sp,16
    8000278c:	8082                	ret

000000008000278e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000278e:	1141                	addi	sp,sp,-16
    80002790:	e406                	sd	ra,8(sp)
    80002792:	e022                	sd	s0,0(sp)
    80002794:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002796:	fffff097          	auipc	ra,0xfffff
    8000279a:	21a080e7          	jalr	538(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000279e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027a2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027a4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027a8:	00005617          	auipc	a2,0x5
    800027ac:	85860613          	addi	a2,a2,-1960 # 80007000 <_trampoline>
    800027b0:	00005697          	auipc	a3,0x5
    800027b4:	85068693          	addi	a3,a3,-1968 # 80007000 <_trampoline>
    800027b8:	8e91                	sub	a3,a3,a2
    800027ba:	040007b7          	lui	a5,0x4000
    800027be:	17fd                	addi	a5,a5,-1
    800027c0:	07b2                	slli	a5,a5,0xc
    800027c2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027c4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027c8:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027ca:	180026f3          	csrr	a3,satp
    800027ce:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027d0:	7138                	ld	a4,96(a0)
    800027d2:	6534                	ld	a3,72(a0)
    800027d4:	6585                	lui	a1,0x1
    800027d6:	96ae                	add	a3,a3,a1
    800027d8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027da:	7138                	ld	a4,96(a0)
    800027dc:	00000697          	auipc	a3,0x0
    800027e0:	13868693          	addi	a3,a3,312 # 80002914 <usertrap>
    800027e4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027e6:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027e8:	8692                	mv	a3,tp
    800027ea:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ec:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027f0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027f4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027f8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027fc:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027fe:	6f18                	ld	a4,24(a4)
    80002800:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002804:	6d2c                	ld	a1,88(a0)
    80002806:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002808:	00005717          	auipc	a4,0x5
    8000280c:	88870713          	addi	a4,a4,-1912 # 80007090 <userret>
    80002810:	8f11                	sub	a4,a4,a2
    80002812:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002814:	577d                	li	a4,-1
    80002816:	177e                	slli	a4,a4,0x3f
    80002818:	8dd9                	or	a1,a1,a4
    8000281a:	02000537          	lui	a0,0x2000
    8000281e:	157d                	addi	a0,a0,-1
    80002820:	0536                	slli	a0,a0,0xd
    80002822:	9782                	jalr	a5
}
    80002824:	60a2                	ld	ra,8(sp)
    80002826:	6402                	ld	s0,0(sp)
    80002828:	0141                	addi	sp,sp,16
    8000282a:	8082                	ret

000000008000282c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000282c:	1101                	addi	sp,sp,-32
    8000282e:	ec06                	sd	ra,24(sp)
    80002830:	e822                	sd	s0,16(sp)
    80002832:	e426                	sd	s1,8(sp)
    80002834:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002836:	00015497          	auipc	s1,0x15
    8000283a:	a9a48493          	addi	s1,s1,-1382 # 800172d0 <tickslock>
    8000283e:	8526                	mv	a0,s1
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	3a4080e7          	jalr	932(ra) # 80000be4 <acquire>
  ticks++;
    80002848:	00006517          	auipc	a0,0x6
    8000284c:	7f050513          	addi	a0,a0,2032 # 80009038 <ticks>
    80002850:	411c                	lw	a5,0(a0)
    80002852:	2785                	addiw	a5,a5,1
    80002854:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002856:	00000097          	auipc	ra,0x0
    8000285a:	a36080e7          	jalr	-1482(ra) # 8000228c <wakeup>
  release(&tickslock);
    8000285e:	8526                	mv	a0,s1
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	438080e7          	jalr	1080(ra) # 80000c98 <release>
}
    80002868:	60e2                	ld	ra,24(sp)
    8000286a:	6442                	ld	s0,16(sp)
    8000286c:	64a2                	ld	s1,8(sp)
    8000286e:	6105                	addi	sp,sp,32
    80002870:	8082                	ret

0000000080002872 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002872:	1101                	addi	sp,sp,-32
    80002874:	ec06                	sd	ra,24(sp)
    80002876:	e822                	sd	s0,16(sp)
    80002878:	e426                	sd	s1,8(sp)
    8000287a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000287c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002880:	00074d63          	bltz	a4,8000289a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002884:	57fd                	li	a5,-1
    80002886:	17fe                	slli	a5,a5,0x3f
    80002888:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000288a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000288c:	06f70363          	beq	a4,a5,800028f2 <devintr+0x80>
  }
}
    80002890:	60e2                	ld	ra,24(sp)
    80002892:	6442                	ld	s0,16(sp)
    80002894:	64a2                	ld	s1,8(sp)
    80002896:	6105                	addi	sp,sp,32
    80002898:	8082                	ret
     (scause & 0xff) == 9){
    8000289a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000289e:	46a5                	li	a3,9
    800028a0:	fed792e3          	bne	a5,a3,80002884 <devintr+0x12>
    int irq = plic_claim();
    800028a4:	00003097          	auipc	ra,0x3
    800028a8:	4b4080e7          	jalr	1204(ra) # 80005d58 <plic_claim>
    800028ac:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028ae:	47a9                	li	a5,10
    800028b0:	02f50763          	beq	a0,a5,800028de <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028b4:	4785                	li	a5,1
    800028b6:	02f50963          	beq	a0,a5,800028e8 <devintr+0x76>
    return 1;
    800028ba:	4505                	li	a0,1
    } else if(irq){
    800028bc:	d8f1                	beqz	s1,80002890 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028be:	85a6                	mv	a1,s1
    800028c0:	00006517          	auipc	a0,0x6
    800028c4:	a8050513          	addi	a0,a0,-1408 # 80008340 <states.1718+0x38>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	cc0080e7          	jalr	-832(ra) # 80000588 <printf>
      plic_complete(irq);
    800028d0:	8526                	mv	a0,s1
    800028d2:	00003097          	auipc	ra,0x3
    800028d6:	4aa080e7          	jalr	1194(ra) # 80005d7c <plic_complete>
    return 1;
    800028da:	4505                	li	a0,1
    800028dc:	bf55                	j	80002890 <devintr+0x1e>
      uartintr();
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	0ca080e7          	jalr	202(ra) # 800009a8 <uartintr>
    800028e6:	b7ed                	j	800028d0 <devintr+0x5e>
      virtio_disk_intr();
    800028e8:	00004097          	auipc	ra,0x4
    800028ec:	974080e7          	jalr	-1676(ra) # 8000625c <virtio_disk_intr>
    800028f0:	b7c5                	j	800028d0 <devintr+0x5e>
    if(cpuid() == 0){
    800028f2:	fffff097          	auipc	ra,0xfffff
    800028f6:	092080e7          	jalr	146(ra) # 80001984 <cpuid>
    800028fa:	c901                	beqz	a0,8000290a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028fc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002900:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002902:	14479073          	csrw	sip,a5
    return 2;
    80002906:	4509                	li	a0,2
    80002908:	b761                	j	80002890 <devintr+0x1e>
      clockintr();
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	f22080e7          	jalr	-222(ra) # 8000282c <clockintr>
    80002912:	b7ed                	j	800028fc <devintr+0x8a>

0000000080002914 <usertrap>:
{
    80002914:	1101                	addi	sp,sp,-32
    80002916:	ec06                	sd	ra,24(sp)
    80002918:	e822                	sd	s0,16(sp)
    8000291a:	e426                	sd	s1,8(sp)
    8000291c:	e04a                	sd	s2,0(sp)
    8000291e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002920:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002924:	1007f793          	andi	a5,a5,256
    80002928:	e3ad                	bnez	a5,8000298a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000292a:	00003797          	auipc	a5,0x3
    8000292e:	32678793          	addi	a5,a5,806 # 80005c50 <kernelvec>
    80002932:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002936:	fffff097          	auipc	ra,0xfffff
    8000293a:	07a080e7          	jalr	122(ra) # 800019b0 <myproc>
    8000293e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002940:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002942:	14102773          	csrr	a4,sepc
    80002946:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002948:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000294c:	47a1                	li	a5,8
    8000294e:	04f71c63          	bne	a4,a5,800029a6 <usertrap+0x92>
    if(p->killed)
    80002952:	551c                	lw	a5,40(a0)
    80002954:	e3b9                	bnez	a5,8000299a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002956:	70b8                	ld	a4,96(s1)
    80002958:	6f1c                	ld	a5,24(a4)
    8000295a:	0791                	addi	a5,a5,4
    8000295c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002962:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002966:	10079073          	csrw	sstatus,a5
    syscall();
    8000296a:	00000097          	auipc	ra,0x0
    8000296e:	2e0080e7          	jalr	736(ra) # 80002c4a <syscall>
  if(p->killed)
    80002972:	549c                	lw	a5,40(s1)
    80002974:	ebc1                	bnez	a5,80002a04 <usertrap+0xf0>
  usertrapret();
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	e18080e7          	jalr	-488(ra) # 8000278e <usertrapret>
}
    8000297e:	60e2                	ld	ra,24(sp)
    80002980:	6442                	ld	s0,16(sp)
    80002982:	64a2                	ld	s1,8(sp)
    80002984:	6902                	ld	s2,0(sp)
    80002986:	6105                	addi	sp,sp,32
    80002988:	8082                	ret
    panic("usertrap: not from user mode");
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	9d650513          	addi	a0,a0,-1578 # 80008360 <states.1718+0x58>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bac080e7          	jalr	-1108(ra) # 8000053e <panic>
      exit(-1);
    8000299a:	557d                	li	a0,-1
    8000299c:	00000097          	auipc	ra,0x0
    800029a0:	9d2080e7          	jalr	-1582(ra) # 8000236e <exit>
    800029a4:	bf4d                	j	80002956 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029a6:	00000097          	auipc	ra,0x0
    800029aa:	ecc080e7          	jalr	-308(ra) # 80002872 <devintr>
    800029ae:	892a                	mv	s2,a0
    800029b0:	c501                	beqz	a0,800029b8 <usertrap+0xa4>
  if(p->killed)
    800029b2:	549c                	lw	a5,40(s1)
    800029b4:	c3a1                	beqz	a5,800029f4 <usertrap+0xe0>
    800029b6:	a815                	j	800029ea <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029bc:	5890                	lw	a2,48(s1)
    800029be:	00006517          	auipc	a0,0x6
    800029c2:	9c250513          	addi	a0,a0,-1598 # 80008380 <states.1718+0x78>
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	bc2080e7          	jalr	-1086(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029d2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029d6:	00006517          	auipc	a0,0x6
    800029da:	9da50513          	addi	a0,a0,-1574 # 800083b0 <states.1718+0xa8>
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	baa080e7          	jalr	-1110(ra) # 80000588 <printf>
    p->killed = 1;
    800029e6:	4785                	li	a5,1
    800029e8:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029ea:	557d                	li	a0,-1
    800029ec:	00000097          	auipc	ra,0x0
    800029f0:	982080e7          	jalr	-1662(ra) # 8000236e <exit>
  if(which_dev == 2){
    800029f4:	4789                	li	a5,2
    800029f6:	f8f910e3          	bne	s2,a5,80002976 <usertrap+0x62>
  yield();
    800029fa:	fffff097          	auipc	ra,0xfffff
    800029fe:	6c0080e7          	jalr	1728(ra) # 800020ba <yield>
}
    80002a02:	bf95                	j	80002976 <usertrap+0x62>
  int which_dev = 0;
    80002a04:	4901                	li	s2,0
    80002a06:	b7d5                	j	800029ea <usertrap+0xd6>

0000000080002a08 <kerneltrap>:
{
    80002a08:	7179                	addi	sp,sp,-48
    80002a0a:	f406                	sd	ra,40(sp)
    80002a0c:	f022                	sd	s0,32(sp)
    80002a0e:	ec26                	sd	s1,24(sp)
    80002a10:	e84a                	sd	s2,16(sp)
    80002a12:	e44e                	sd	s3,8(sp)
    80002a14:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a16:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a22:	1004f793          	andi	a5,s1,256
    80002a26:	cb85                	beqz	a5,80002a56 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a28:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a2c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a2e:	ef85                	bnez	a5,80002a66 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a30:	00000097          	auipc	ra,0x0
    80002a34:	e42080e7          	jalr	-446(ra) # 80002872 <devintr>
    80002a38:	cd1d                	beqz	a0,80002a76 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a3a:	4789                	li	a5,2
    80002a3c:	06f50a63          	beq	a0,a5,80002ab0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a40:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a44:	10049073          	csrw	sstatus,s1
}
    80002a48:	70a2                	ld	ra,40(sp)
    80002a4a:	7402                	ld	s0,32(sp)
    80002a4c:	64e2                	ld	s1,24(sp)
    80002a4e:	6942                	ld	s2,16(sp)
    80002a50:	69a2                	ld	s3,8(sp)
    80002a52:	6145                	addi	sp,sp,48
    80002a54:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a56:	00006517          	auipc	a0,0x6
    80002a5a:	97a50513          	addi	a0,a0,-1670 # 800083d0 <states.1718+0xc8>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	ae0080e7          	jalr	-1312(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	99250513          	addi	a0,a0,-1646 # 800083f8 <states.1718+0xf0>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a76:	85ce                	mv	a1,s3
    80002a78:	00006517          	auipc	a0,0x6
    80002a7c:	9a050513          	addi	a0,a0,-1632 # 80008418 <states.1718+0x110>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	b08080e7          	jalr	-1272(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a88:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a8c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	99850513          	addi	a0,a0,-1640 # 80008428 <states.1718+0x120>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	af0080e7          	jalr	-1296(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	9a050513          	addi	a0,a0,-1632 # 80008440 <states.1718+0x138>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	a96080e7          	jalr	-1386(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	f00080e7          	jalr	-256(ra) # 800019b0 <myproc>
    80002ab8:	d541                	beqz	a0,80002a40 <kerneltrap+0x38>
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	ef6080e7          	jalr	-266(ra) # 800019b0 <myproc>
    80002ac2:	4d18                	lw	a4,24(a0)
    80002ac4:	4791                	li	a5,4
    80002ac6:	f6f71de3          	bne	a4,a5,80002a40 <kerneltrap+0x38>
  yield();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	5f0080e7          	jalr	1520(ra) # 800020ba <yield>
}
    80002ad2:	b7bd                	j	80002a40 <kerneltrap+0x38>

0000000080002ad4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ad4:	1101                	addi	sp,sp,-32
    80002ad6:	ec06                	sd	ra,24(sp)
    80002ad8:	e822                	sd	s0,16(sp)
    80002ada:	e426                	sd	s1,8(sp)
    80002adc:	1000                	addi	s0,sp,32
    80002ade:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ae0:	fffff097          	auipc	ra,0xfffff
    80002ae4:	ed0080e7          	jalr	-304(ra) # 800019b0 <myproc>
  switch (n) {
    80002ae8:	4795                	li	a5,5
    80002aea:	0497e163          	bltu	a5,s1,80002b2c <argraw+0x58>
    80002aee:	048a                	slli	s1,s1,0x2
    80002af0:	00006717          	auipc	a4,0x6
    80002af4:	98870713          	addi	a4,a4,-1656 # 80008478 <states.1718+0x170>
    80002af8:	94ba                	add	s1,s1,a4
    80002afa:	409c                	lw	a5,0(s1)
    80002afc:	97ba                	add	a5,a5,a4
    80002afe:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b00:	713c                	ld	a5,96(a0)
    80002b02:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b04:	60e2                	ld	ra,24(sp)
    80002b06:	6442                	ld	s0,16(sp)
    80002b08:	64a2                	ld	s1,8(sp)
    80002b0a:	6105                	addi	sp,sp,32
    80002b0c:	8082                	ret
    return p->trapframe->a1;
    80002b0e:	713c                	ld	a5,96(a0)
    80002b10:	7fa8                	ld	a0,120(a5)
    80002b12:	bfcd                	j	80002b04 <argraw+0x30>
    return p->trapframe->a2;
    80002b14:	713c                	ld	a5,96(a0)
    80002b16:	63c8                	ld	a0,128(a5)
    80002b18:	b7f5                	j	80002b04 <argraw+0x30>
    return p->trapframe->a3;
    80002b1a:	713c                	ld	a5,96(a0)
    80002b1c:	67c8                	ld	a0,136(a5)
    80002b1e:	b7dd                	j	80002b04 <argraw+0x30>
    return p->trapframe->a4;
    80002b20:	713c                	ld	a5,96(a0)
    80002b22:	6bc8                	ld	a0,144(a5)
    80002b24:	b7c5                	j	80002b04 <argraw+0x30>
    return p->trapframe->a5;
    80002b26:	713c                	ld	a5,96(a0)
    80002b28:	6fc8                	ld	a0,152(a5)
    80002b2a:	bfe9                	j	80002b04 <argraw+0x30>
  panic("argraw");
    80002b2c:	00006517          	auipc	a0,0x6
    80002b30:	92450513          	addi	a0,a0,-1756 # 80008450 <states.1718+0x148>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	a0a080e7          	jalr	-1526(ra) # 8000053e <panic>

0000000080002b3c <fetchaddr>:
{
    80002b3c:	1101                	addi	sp,sp,-32
    80002b3e:	ec06                	sd	ra,24(sp)
    80002b40:	e822                	sd	s0,16(sp)
    80002b42:	e426                	sd	s1,8(sp)
    80002b44:	e04a                	sd	s2,0(sp)
    80002b46:	1000                	addi	s0,sp,32
    80002b48:	84aa                	mv	s1,a0
    80002b4a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	e64080e7          	jalr	-412(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b54:	693c                	ld	a5,80(a0)
    80002b56:	02f4f863          	bgeu	s1,a5,80002b86 <fetchaddr+0x4a>
    80002b5a:	00848713          	addi	a4,s1,8
    80002b5e:	02e7e663          	bltu	a5,a4,80002b8a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b62:	46a1                	li	a3,8
    80002b64:	8626                	mv	a2,s1
    80002b66:	85ca                	mv	a1,s2
    80002b68:	6d28                	ld	a0,88(a0)
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	b94080e7          	jalr	-1132(ra) # 800016fe <copyin>
    80002b72:	00a03533          	snez	a0,a0
    80002b76:	40a00533          	neg	a0,a0
}
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6902                	ld	s2,0(sp)
    80002b82:	6105                	addi	sp,sp,32
    80002b84:	8082                	ret
    return -1;
    80002b86:	557d                	li	a0,-1
    80002b88:	bfcd                	j	80002b7a <fetchaddr+0x3e>
    80002b8a:	557d                	li	a0,-1
    80002b8c:	b7fd                	j	80002b7a <fetchaddr+0x3e>

0000000080002b8e <fetchstr>:
{
    80002b8e:	7179                	addi	sp,sp,-48
    80002b90:	f406                	sd	ra,40(sp)
    80002b92:	f022                	sd	s0,32(sp)
    80002b94:	ec26                	sd	s1,24(sp)
    80002b96:	e84a                	sd	s2,16(sp)
    80002b98:	e44e                	sd	s3,8(sp)
    80002b9a:	1800                	addi	s0,sp,48
    80002b9c:	892a                	mv	s2,a0
    80002b9e:	84ae                	mv	s1,a1
    80002ba0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	e0e080e7          	jalr	-498(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002baa:	86ce                	mv	a3,s3
    80002bac:	864a                	mv	a2,s2
    80002bae:	85a6                	mv	a1,s1
    80002bb0:	6d28                	ld	a0,88(a0)
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	bd8080e7          	jalr	-1064(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002bba:	00054763          	bltz	a0,80002bc8 <fetchstr+0x3a>
  return strlen(buf);
    80002bbe:	8526                	mv	a0,s1
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	2a4080e7          	jalr	676(ra) # 80000e64 <strlen>
}
    80002bc8:	70a2                	ld	ra,40(sp)
    80002bca:	7402                	ld	s0,32(sp)
    80002bcc:	64e2                	ld	s1,24(sp)
    80002bce:	6942                	ld	s2,16(sp)
    80002bd0:	69a2                	ld	s3,8(sp)
    80002bd2:	6145                	addi	sp,sp,48
    80002bd4:	8082                	ret

0000000080002bd6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bd6:	1101                	addi	sp,sp,-32
    80002bd8:	ec06                	sd	ra,24(sp)
    80002bda:	e822                	sd	s0,16(sp)
    80002bdc:	e426                	sd	s1,8(sp)
    80002bde:	1000                	addi	s0,sp,32
    80002be0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	ef2080e7          	jalr	-270(ra) # 80002ad4 <argraw>
    80002bea:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bec:	4501                	li	a0,0
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6105                	addi	sp,sp,32
    80002bf6:	8082                	ret

0000000080002bf8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bf8:	1101                	addi	sp,sp,-32
    80002bfa:	ec06                	sd	ra,24(sp)
    80002bfc:	e822                	sd	s0,16(sp)
    80002bfe:	e426                	sd	s1,8(sp)
    80002c00:	1000                	addi	s0,sp,32
    80002c02:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	ed0080e7          	jalr	-304(ra) # 80002ad4 <argraw>
    80002c0c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c0e:	4501                	li	a0,0
    80002c10:	60e2                	ld	ra,24(sp)
    80002c12:	6442                	ld	s0,16(sp)
    80002c14:	64a2                	ld	s1,8(sp)
    80002c16:	6105                	addi	sp,sp,32
    80002c18:	8082                	ret

0000000080002c1a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c1a:	1101                	addi	sp,sp,-32
    80002c1c:	ec06                	sd	ra,24(sp)
    80002c1e:	e822                	sd	s0,16(sp)
    80002c20:	e426                	sd	s1,8(sp)
    80002c22:	e04a                	sd	s2,0(sp)
    80002c24:	1000                	addi	s0,sp,32
    80002c26:	84ae                	mv	s1,a1
    80002c28:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	eaa080e7          	jalr	-342(ra) # 80002ad4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c32:	864a                	mv	a2,s2
    80002c34:	85a6                	mv	a1,s1
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	f58080e7          	jalr	-168(ra) # 80002b8e <fetchstr>
}
    80002c3e:	60e2                	ld	ra,24(sp)
    80002c40:	6442                	ld	s0,16(sp)
    80002c42:	64a2                	ld	s1,8(sp)
    80002c44:	6902                	ld	s2,0(sp)
    80002c46:	6105                	addi	sp,sp,32
    80002c48:	8082                	ret

0000000080002c4a <syscall>:
[SYS_killsystem] sys_killsystem,
};

void
syscall(void)
{
    80002c4a:	1101                	addi	sp,sp,-32
    80002c4c:	ec06                	sd	ra,24(sp)
    80002c4e:	e822                	sd	s0,16(sp)
    80002c50:	e426                	sd	s1,8(sp)
    80002c52:	e04a                	sd	s2,0(sp)
    80002c54:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	d5a080e7          	jalr	-678(ra) # 800019b0 <myproc>
    80002c5e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c60:	06053903          	ld	s2,96(a0)
    80002c64:	0a893783          	ld	a5,168(s2)
    80002c68:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c6c:	37fd                	addiw	a5,a5,-1
    80002c6e:	4759                	li	a4,22
    80002c70:	00f76f63          	bltu	a4,a5,80002c8e <syscall+0x44>
    80002c74:	00369713          	slli	a4,a3,0x3
    80002c78:	00006797          	auipc	a5,0x6
    80002c7c:	81878793          	addi	a5,a5,-2024 # 80008490 <syscalls>
    80002c80:	97ba                	add	a5,a5,a4
    80002c82:	639c                	ld	a5,0(a5)
    80002c84:	c789                	beqz	a5,80002c8e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c86:	9782                	jalr	a5
    80002c88:	06a93823          	sd	a0,112(s2)
    80002c8c:	a839                	j	80002caa <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c8e:	16048613          	addi	a2,s1,352
    80002c92:	588c                	lw	a1,48(s1)
    80002c94:	00005517          	auipc	a0,0x5
    80002c98:	7c450513          	addi	a0,a0,1988 # 80008458 <states.1718+0x150>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	8ec080e7          	jalr	-1812(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ca4:	70bc                	ld	a5,96(s1)
    80002ca6:	577d                	li	a4,-1
    80002ca8:	fbb8                	sd	a4,112(a5)
  }
}
    80002caa:	60e2                	ld	ra,24(sp)
    80002cac:	6442                	ld	s0,16(sp)
    80002cae:	64a2                	ld	s1,8(sp)
    80002cb0:	6902                	ld	s2,0(sp)
    80002cb2:	6105                	addi	sp,sp,32
    80002cb4:	8082                	ret

0000000080002cb6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cb6:	1101                	addi	sp,sp,-32
    80002cb8:	ec06                	sd	ra,24(sp)
    80002cba:	e822                	sd	s0,16(sp)
    80002cbc:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cbe:	fec40593          	addi	a1,s0,-20
    80002cc2:	4501                	li	a0,0
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	f12080e7          	jalr	-238(ra) # 80002bd6 <argint>
    return -1;
    80002ccc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cce:	00054963          	bltz	a0,80002ce0 <sys_exit+0x2a>
  exit(n);
    80002cd2:	fec42503          	lw	a0,-20(s0)
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	698080e7          	jalr	1688(ra) # 8000236e <exit>
  return 0;  // not reached
    80002cde:	4781                	li	a5,0
}
    80002ce0:	853e                	mv	a0,a5
    80002ce2:	60e2                	ld	ra,24(sp)
    80002ce4:	6442                	ld	s0,16(sp)
    80002ce6:	6105                	addi	sp,sp,32
    80002ce8:	8082                	ret

0000000080002cea <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cea:	1141                	addi	sp,sp,-16
    80002cec:	e406                	sd	ra,8(sp)
    80002cee:	e022                	sd	s0,0(sp)
    80002cf0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	cbe080e7          	jalr	-834(ra) # 800019b0 <myproc>
}
    80002cfa:	5908                	lw	a0,48(a0)
    80002cfc:	60a2                	ld	ra,8(sp)
    80002cfe:	6402                	ld	s0,0(sp)
    80002d00:	0141                	addi	sp,sp,16
    80002d02:	8082                	ret

0000000080002d04 <sys_fork>:

uint64
sys_fork(void)
{
    80002d04:	1141                	addi	sp,sp,-16
    80002d06:	e406                	sd	ra,8(sp)
    80002d08:	e022                	sd	s0,0(sp)
    80002d0a:	0800                	addi	s0,sp,16
  return fork();
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	0b2080e7          	jalr	178(ra) # 80001dbe <fork>
}
    80002d14:	60a2                	ld	ra,8(sp)
    80002d16:	6402                	ld	s0,0(sp)
    80002d18:	0141                	addi	sp,sp,16
    80002d1a:	8082                	ret

0000000080002d1c <sys_wait>:

uint64
sys_wait(void)
{
    80002d1c:	1101                	addi	sp,sp,-32
    80002d1e:	ec06                	sd	ra,24(sp)
    80002d20:	e822                	sd	s0,16(sp)
    80002d22:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d24:	fe840593          	addi	a1,s0,-24
    80002d28:	4501                	li	a0,0
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	ece080e7          	jalr	-306(ra) # 80002bf8 <argaddr>
    80002d32:	87aa                	mv	a5,a0
    return -1;
    80002d34:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d36:	0007c863          	bltz	a5,80002d46 <sys_wait+0x2a>
  return wait(p);
    80002d3a:	fe843503          	ld	a0,-24(s0)
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	426080e7          	jalr	1062(ra) # 80002164 <wait>
}
    80002d46:	60e2                	ld	ra,24(sp)
    80002d48:	6442                	ld	s0,16(sp)
    80002d4a:	6105                	addi	sp,sp,32
    80002d4c:	8082                	ret

0000000080002d4e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d4e:	7179                	addi	sp,sp,-48
    80002d50:	f406                	sd	ra,40(sp)
    80002d52:	f022                	sd	s0,32(sp)
    80002d54:	ec26                	sd	s1,24(sp)
    80002d56:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d58:	fdc40593          	addi	a1,s0,-36
    80002d5c:	4501                	li	a0,0
    80002d5e:	00000097          	auipc	ra,0x0
    80002d62:	e78080e7          	jalr	-392(ra) # 80002bd6 <argint>
    80002d66:	87aa                	mv	a5,a0
    return -1;
    80002d68:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d6a:	0207c063          	bltz	a5,80002d8a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	c42080e7          	jalr	-958(ra) # 800019b0 <myproc>
    80002d76:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002d78:	fdc42503          	lw	a0,-36(s0)
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	fce080e7          	jalr	-50(ra) # 80001d4a <growproc>
    80002d84:	00054863          	bltz	a0,80002d94 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d88:	8526                	mv	a0,s1
}
    80002d8a:	70a2                	ld	ra,40(sp)
    80002d8c:	7402                	ld	s0,32(sp)
    80002d8e:	64e2                	ld	s1,24(sp)
    80002d90:	6145                	addi	sp,sp,48
    80002d92:	8082                	ret
    return -1;
    80002d94:	557d                	li	a0,-1
    80002d96:	bfd5                	j	80002d8a <sys_sbrk+0x3c>

0000000080002d98 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d98:	7139                	addi	sp,sp,-64
    80002d9a:	fc06                	sd	ra,56(sp)
    80002d9c:	f822                	sd	s0,48(sp)
    80002d9e:	f426                	sd	s1,40(sp)
    80002da0:	f04a                	sd	s2,32(sp)
    80002da2:	ec4e                	sd	s3,24(sp)
    80002da4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002da6:	fcc40593          	addi	a1,s0,-52
    80002daa:	4501                	li	a0,0
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	e2a080e7          	jalr	-470(ra) # 80002bd6 <argint>
    return -1;
    80002db4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002db6:	06054563          	bltz	a0,80002e20 <sys_sleep+0x88>
  acquire(&tickslock);
    80002dba:	00014517          	auipc	a0,0x14
    80002dbe:	51650513          	addi	a0,a0,1302 # 800172d0 <tickslock>
    80002dc2:	ffffe097          	auipc	ra,0xffffe
    80002dc6:	e22080e7          	jalr	-478(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002dca:	00006917          	auipc	s2,0x6
    80002dce:	26e92903          	lw	s2,622(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002dd2:	fcc42783          	lw	a5,-52(s0)
    80002dd6:	cf85                	beqz	a5,80002e0e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dd8:	00014997          	auipc	s3,0x14
    80002ddc:	4f898993          	addi	s3,s3,1272 # 800172d0 <tickslock>
    80002de0:	00006497          	auipc	s1,0x6
    80002de4:	25848493          	addi	s1,s1,600 # 80009038 <ticks>
    if(myproc()->killed){
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	bc8080e7          	jalr	-1080(ra) # 800019b0 <myproc>
    80002df0:	551c                	lw	a5,40(a0)
    80002df2:	ef9d                	bnez	a5,80002e30 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002df4:	85ce                	mv	a1,s3
    80002df6:	8526                	mv	a0,s1
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	308080e7          	jalr	776(ra) # 80002100 <sleep>
  while(ticks - ticks0 < n){
    80002e00:	409c                	lw	a5,0(s1)
    80002e02:	412787bb          	subw	a5,a5,s2
    80002e06:	fcc42703          	lw	a4,-52(s0)
    80002e0a:	fce7efe3          	bltu	a5,a4,80002de8 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e0e:	00014517          	auipc	a0,0x14
    80002e12:	4c250513          	addi	a0,a0,1218 # 800172d0 <tickslock>
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	e82080e7          	jalr	-382(ra) # 80000c98 <release>
  return 0;
    80002e1e:	4781                	li	a5,0
}
    80002e20:	853e                	mv	a0,a5
    80002e22:	70e2                	ld	ra,56(sp)
    80002e24:	7442                	ld	s0,48(sp)
    80002e26:	74a2                	ld	s1,40(sp)
    80002e28:	7902                	ld	s2,32(sp)
    80002e2a:	69e2                	ld	s3,24(sp)
    80002e2c:	6121                	addi	sp,sp,64
    80002e2e:	8082                	ret
      release(&tickslock);
    80002e30:	00014517          	auipc	a0,0x14
    80002e34:	4a050513          	addi	a0,a0,1184 # 800172d0 <tickslock>
    80002e38:	ffffe097          	auipc	ra,0xffffe
    80002e3c:	e60080e7          	jalr	-416(ra) # 80000c98 <release>
      return -1;
    80002e40:	57fd                	li	a5,-1
    80002e42:	bff9                	j	80002e20 <sys_sleep+0x88>

0000000080002e44 <sys_kill>:

uint64
sys_kill(void)
{
    80002e44:	1101                	addi	sp,sp,-32
    80002e46:	ec06                	sd	ra,24(sp)
    80002e48:	e822                	sd	s0,16(sp)
    80002e4a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e4c:	fec40593          	addi	a1,s0,-20
    80002e50:	4501                	li	a0,0
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	d84080e7          	jalr	-636(ra) # 80002bd6 <argint>
    80002e5a:	87aa                	mv	a5,a0
    return -1;
    80002e5c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e5e:	0007c863          	bltz	a5,80002e6e <sys_kill+0x2a>
  return kill(pid);
    80002e62:	fec42503          	lw	a0,-20(s0)
    80002e66:	fffff097          	auipc	ra,0xfffff
    80002e6a:	5de080e7          	jalr	1502(ra) # 80002444 <kill>
}
    80002e6e:	60e2                	ld	ra,24(sp)
    80002e70:	6442                	ld	s0,16(sp)
    80002e72:	6105                	addi	sp,sp,32
    80002e74:	8082                	ret

0000000080002e76 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e76:	1101                	addi	sp,sp,-32
    80002e78:	ec06                	sd	ra,24(sp)
    80002e7a:	e822                	sd	s0,16(sp)
    80002e7c:	e426                	sd	s1,8(sp)
    80002e7e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e80:	00014517          	auipc	a0,0x14
    80002e84:	45050513          	addi	a0,a0,1104 # 800172d0 <tickslock>
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	d5c080e7          	jalr	-676(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e90:	00006497          	auipc	s1,0x6
    80002e94:	1a84a483          	lw	s1,424(s1) # 80009038 <ticks>
  release(&tickslock);
    80002e98:	00014517          	auipc	a0,0x14
    80002e9c:	43850513          	addi	a0,a0,1080 # 800172d0 <tickslock>
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	df8080e7          	jalr	-520(ra) # 80000c98 <release>
  return xticks;
}
    80002ea8:	02049513          	slli	a0,s1,0x20
    80002eac:	9101                	srli	a0,a0,0x20
    80002eae:	60e2                	ld	ra,24(sp)
    80002eb0:	6442                	ld	s0,16(sp)
    80002eb2:	64a2                	ld	s1,8(sp)
    80002eb4:	6105                	addi	sp,sp,32
    80002eb6:	8082                	ret

0000000080002eb8 <sys_killsystem>:
/*-----------------------------------*********************-----------------------------------*********************-----------------------------------*/

//kills all processes in the system except for sh and init
uint64
sys_killsystem(void)
{
    80002eb8:	1141                	addi	sp,sp,-16
    80002eba:	e406                	sd	ra,8(sp)
    80002ebc:	e022                	sd	s0,0(sp)
    80002ebe:	0800                	addi	s0,sp,16
 kill_system();
    80002ec0:	fffff097          	auipc	ra,0xfffff
    80002ec4:	75a080e7          	jalr	1882(ra) # 8000261a <kill_system>
 return 0;
}
    80002ec8:	4501                	li	a0,0
    80002eca:	60a2                	ld	ra,8(sp)
    80002ecc:	6402                	ld	s0,0(sp)
    80002ece:	0141                	addi	sp,sp,16
    80002ed0:	8082                	ret

0000000080002ed2 <sys_pausesystem>:

uint64
sys_pausesystem(void)
{
    80002ed2:	1101                	addi	sp,sp,-32
    80002ed4:	ec06                	sd	ra,24(sp)
    80002ed6:	e822                	sd	s0,16(sp)
    80002ed8:	1000                	addi	s0,sp,32
  int seconds;
  if(argint(0, &seconds) < 0)
    80002eda:	fec40593          	addi	a1,s0,-20
    80002ede:	4501                	li	a0,0
    80002ee0:	00000097          	auipc	ra,0x0
    80002ee4:	cf6080e7          	jalr	-778(ra) # 80002bd6 <argint>
    return -1;
    80002ee8:	57fd                	li	a5,-1
  if(argint(0, &seconds) < 0)
    80002eea:	00054963          	bltz	a0,80002efc <sys_pausesystem+0x2a>
  pause_system(seconds);
    80002eee:	fec42503          	lw	a0,-20(s0)
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	7a4080e7          	jalr	1956(ra) # 80002696 <pause_system>
  return 0;
    80002efa:	4781                	li	a5,0
    80002efc:	853e                	mv	a0,a5
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	6105                	addi	sp,sp,32
    80002f04:	8082                	ret

0000000080002f06 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f06:	7179                	addi	sp,sp,-48
    80002f08:	f406                	sd	ra,40(sp)
    80002f0a:	f022                	sd	s0,32(sp)
    80002f0c:	ec26                	sd	s1,24(sp)
    80002f0e:	e84a                	sd	s2,16(sp)
    80002f10:	e44e                	sd	s3,8(sp)
    80002f12:	e052                	sd	s4,0(sp)
    80002f14:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f16:	00005597          	auipc	a1,0x5
    80002f1a:	63a58593          	addi	a1,a1,1594 # 80008550 <syscalls+0xc0>
    80002f1e:	00014517          	auipc	a0,0x14
    80002f22:	3ca50513          	addi	a0,a0,970 # 800172e8 <bcache>
    80002f26:	ffffe097          	auipc	ra,0xffffe
    80002f2a:	c2e080e7          	jalr	-978(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f2e:	0001c797          	auipc	a5,0x1c
    80002f32:	3ba78793          	addi	a5,a5,954 # 8001f2e8 <bcache+0x8000>
    80002f36:	0001c717          	auipc	a4,0x1c
    80002f3a:	61a70713          	addi	a4,a4,1562 # 8001f550 <bcache+0x8268>
    80002f3e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f42:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f46:	00014497          	auipc	s1,0x14
    80002f4a:	3ba48493          	addi	s1,s1,954 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002f4e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f50:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f52:	00005a17          	auipc	s4,0x5
    80002f56:	606a0a13          	addi	s4,s4,1542 # 80008558 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f5a:	2b893783          	ld	a5,696(s2)
    80002f5e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f60:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f64:	85d2                	mv	a1,s4
    80002f66:	01048513          	addi	a0,s1,16
    80002f6a:	00001097          	auipc	ra,0x1
    80002f6e:	4bc080e7          	jalr	1212(ra) # 80004426 <initsleeplock>
    bcache.head.next->prev = b;
    80002f72:	2b893783          	ld	a5,696(s2)
    80002f76:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f78:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7c:	45848493          	addi	s1,s1,1112
    80002f80:	fd349de3          	bne	s1,s3,80002f5a <binit+0x54>
  }
}
    80002f84:	70a2                	ld	ra,40(sp)
    80002f86:	7402                	ld	s0,32(sp)
    80002f88:	64e2                	ld	s1,24(sp)
    80002f8a:	6942                	ld	s2,16(sp)
    80002f8c:	69a2                	ld	s3,8(sp)
    80002f8e:	6a02                	ld	s4,0(sp)
    80002f90:	6145                	addi	sp,sp,48
    80002f92:	8082                	ret

0000000080002f94 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f94:	7179                	addi	sp,sp,-48
    80002f96:	f406                	sd	ra,40(sp)
    80002f98:	f022                	sd	s0,32(sp)
    80002f9a:	ec26                	sd	s1,24(sp)
    80002f9c:	e84a                	sd	s2,16(sp)
    80002f9e:	e44e                	sd	s3,8(sp)
    80002fa0:	1800                	addi	s0,sp,48
    80002fa2:	89aa                	mv	s3,a0
    80002fa4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fa6:	00014517          	auipc	a0,0x14
    80002faa:	34250513          	addi	a0,a0,834 # 800172e8 <bcache>
    80002fae:	ffffe097          	auipc	ra,0xffffe
    80002fb2:	c36080e7          	jalr	-970(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fb6:	0001c497          	auipc	s1,0x1c
    80002fba:	5ea4b483          	ld	s1,1514(s1) # 8001f5a0 <bcache+0x82b8>
    80002fbe:	0001c797          	auipc	a5,0x1c
    80002fc2:	59278793          	addi	a5,a5,1426 # 8001f550 <bcache+0x8268>
    80002fc6:	02f48f63          	beq	s1,a5,80003004 <bread+0x70>
    80002fca:	873e                	mv	a4,a5
    80002fcc:	a021                	j	80002fd4 <bread+0x40>
    80002fce:	68a4                	ld	s1,80(s1)
    80002fd0:	02e48a63          	beq	s1,a4,80003004 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fd4:	449c                	lw	a5,8(s1)
    80002fd6:	ff379ce3          	bne	a5,s3,80002fce <bread+0x3a>
    80002fda:	44dc                	lw	a5,12(s1)
    80002fdc:	ff2799e3          	bne	a5,s2,80002fce <bread+0x3a>
      b->refcnt++;
    80002fe0:	40bc                	lw	a5,64(s1)
    80002fe2:	2785                	addiw	a5,a5,1
    80002fe4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe6:	00014517          	auipc	a0,0x14
    80002fea:	30250513          	addi	a0,a0,770 # 800172e8 <bcache>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	caa080e7          	jalr	-854(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002ff6:	01048513          	addi	a0,s1,16
    80002ffa:	00001097          	auipc	ra,0x1
    80002ffe:	466080e7          	jalr	1126(ra) # 80004460 <acquiresleep>
      return b;
    80003002:	a8b9                	j	80003060 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003004:	0001c497          	auipc	s1,0x1c
    80003008:	5944b483          	ld	s1,1428(s1) # 8001f598 <bcache+0x82b0>
    8000300c:	0001c797          	auipc	a5,0x1c
    80003010:	54478793          	addi	a5,a5,1348 # 8001f550 <bcache+0x8268>
    80003014:	00f48863          	beq	s1,a5,80003024 <bread+0x90>
    80003018:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000301a:	40bc                	lw	a5,64(s1)
    8000301c:	cf81                	beqz	a5,80003034 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000301e:	64a4                	ld	s1,72(s1)
    80003020:	fee49de3          	bne	s1,a4,8000301a <bread+0x86>
  panic("bget: no buffers");
    80003024:	00005517          	auipc	a0,0x5
    80003028:	53c50513          	addi	a0,a0,1340 # 80008560 <syscalls+0xd0>
    8000302c:	ffffd097          	auipc	ra,0xffffd
    80003030:	512080e7          	jalr	1298(ra) # 8000053e <panic>
      b->dev = dev;
    80003034:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003038:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000303c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003040:	4785                	li	a5,1
    80003042:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003044:	00014517          	auipc	a0,0x14
    80003048:	2a450513          	addi	a0,a0,676 # 800172e8 <bcache>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	c4c080e7          	jalr	-948(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003054:	01048513          	addi	a0,s1,16
    80003058:	00001097          	auipc	ra,0x1
    8000305c:	408080e7          	jalr	1032(ra) # 80004460 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003060:	409c                	lw	a5,0(s1)
    80003062:	cb89                	beqz	a5,80003074 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003064:	8526                	mv	a0,s1
    80003066:	70a2                	ld	ra,40(sp)
    80003068:	7402                	ld	s0,32(sp)
    8000306a:	64e2                	ld	s1,24(sp)
    8000306c:	6942                	ld	s2,16(sp)
    8000306e:	69a2                	ld	s3,8(sp)
    80003070:	6145                	addi	sp,sp,48
    80003072:	8082                	ret
    virtio_disk_rw(b, 0);
    80003074:	4581                	li	a1,0
    80003076:	8526                	mv	a0,s1
    80003078:	00003097          	auipc	ra,0x3
    8000307c:	f0e080e7          	jalr	-242(ra) # 80005f86 <virtio_disk_rw>
    b->valid = 1;
    80003080:	4785                	li	a5,1
    80003082:	c09c                	sw	a5,0(s1)
  return b;
    80003084:	b7c5                	j	80003064 <bread+0xd0>

0000000080003086 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003086:	1101                	addi	sp,sp,-32
    80003088:	ec06                	sd	ra,24(sp)
    8000308a:	e822                	sd	s0,16(sp)
    8000308c:	e426                	sd	s1,8(sp)
    8000308e:	1000                	addi	s0,sp,32
    80003090:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003092:	0541                	addi	a0,a0,16
    80003094:	00001097          	auipc	ra,0x1
    80003098:	466080e7          	jalr	1126(ra) # 800044fa <holdingsleep>
    8000309c:	cd01                	beqz	a0,800030b4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000309e:	4585                	li	a1,1
    800030a0:	8526                	mv	a0,s1
    800030a2:	00003097          	auipc	ra,0x3
    800030a6:	ee4080e7          	jalr	-284(ra) # 80005f86 <virtio_disk_rw>
}
    800030aa:	60e2                	ld	ra,24(sp)
    800030ac:	6442                	ld	s0,16(sp)
    800030ae:	64a2                	ld	s1,8(sp)
    800030b0:	6105                	addi	sp,sp,32
    800030b2:	8082                	ret
    panic("bwrite");
    800030b4:	00005517          	auipc	a0,0x5
    800030b8:	4c450513          	addi	a0,a0,1220 # 80008578 <syscalls+0xe8>
    800030bc:	ffffd097          	auipc	ra,0xffffd
    800030c0:	482080e7          	jalr	1154(ra) # 8000053e <panic>

00000000800030c4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030c4:	1101                	addi	sp,sp,-32
    800030c6:	ec06                	sd	ra,24(sp)
    800030c8:	e822                	sd	s0,16(sp)
    800030ca:	e426                	sd	s1,8(sp)
    800030cc:	e04a                	sd	s2,0(sp)
    800030ce:	1000                	addi	s0,sp,32
    800030d0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030d2:	01050913          	addi	s2,a0,16
    800030d6:	854a                	mv	a0,s2
    800030d8:	00001097          	auipc	ra,0x1
    800030dc:	422080e7          	jalr	1058(ra) # 800044fa <holdingsleep>
    800030e0:	c92d                	beqz	a0,80003152 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030e2:	854a                	mv	a0,s2
    800030e4:	00001097          	auipc	ra,0x1
    800030e8:	3d2080e7          	jalr	978(ra) # 800044b6 <releasesleep>

  acquire(&bcache.lock);
    800030ec:	00014517          	auipc	a0,0x14
    800030f0:	1fc50513          	addi	a0,a0,508 # 800172e8 <bcache>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	af0080e7          	jalr	-1296(ra) # 80000be4 <acquire>
  b->refcnt--;
    800030fc:	40bc                	lw	a5,64(s1)
    800030fe:	37fd                	addiw	a5,a5,-1
    80003100:	0007871b          	sext.w	a4,a5
    80003104:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003106:	eb05                	bnez	a4,80003136 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003108:	68bc                	ld	a5,80(s1)
    8000310a:	64b8                	ld	a4,72(s1)
    8000310c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000310e:	64bc                	ld	a5,72(s1)
    80003110:	68b8                	ld	a4,80(s1)
    80003112:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003114:	0001c797          	auipc	a5,0x1c
    80003118:	1d478793          	addi	a5,a5,468 # 8001f2e8 <bcache+0x8000>
    8000311c:	2b87b703          	ld	a4,696(a5)
    80003120:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003122:	0001c717          	auipc	a4,0x1c
    80003126:	42e70713          	addi	a4,a4,1070 # 8001f550 <bcache+0x8268>
    8000312a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000312c:	2b87b703          	ld	a4,696(a5)
    80003130:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003132:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	1b250513          	addi	a0,a0,434 # 800172e8 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	b5a080e7          	jalr	-1190(ra) # 80000c98 <release>
}
    80003146:	60e2                	ld	ra,24(sp)
    80003148:	6442                	ld	s0,16(sp)
    8000314a:	64a2                	ld	s1,8(sp)
    8000314c:	6902                	ld	s2,0(sp)
    8000314e:	6105                	addi	sp,sp,32
    80003150:	8082                	ret
    panic("brelse");
    80003152:	00005517          	auipc	a0,0x5
    80003156:	42e50513          	addi	a0,a0,1070 # 80008580 <syscalls+0xf0>
    8000315a:	ffffd097          	auipc	ra,0xffffd
    8000315e:	3e4080e7          	jalr	996(ra) # 8000053e <panic>

0000000080003162 <bpin>:

void
bpin(struct buf *b) {
    80003162:	1101                	addi	sp,sp,-32
    80003164:	ec06                	sd	ra,24(sp)
    80003166:	e822                	sd	s0,16(sp)
    80003168:	e426                	sd	s1,8(sp)
    8000316a:	1000                	addi	s0,sp,32
    8000316c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000316e:	00014517          	auipc	a0,0x14
    80003172:	17a50513          	addi	a0,a0,378 # 800172e8 <bcache>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	a6e080e7          	jalr	-1426(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000317e:	40bc                	lw	a5,64(s1)
    80003180:	2785                	addiw	a5,a5,1
    80003182:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003184:	00014517          	auipc	a0,0x14
    80003188:	16450513          	addi	a0,a0,356 # 800172e8 <bcache>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	b0c080e7          	jalr	-1268(ra) # 80000c98 <release>
}
    80003194:	60e2                	ld	ra,24(sp)
    80003196:	6442                	ld	s0,16(sp)
    80003198:	64a2                	ld	s1,8(sp)
    8000319a:	6105                	addi	sp,sp,32
    8000319c:	8082                	ret

000000008000319e <bunpin>:

void
bunpin(struct buf *b) {
    8000319e:	1101                	addi	sp,sp,-32
    800031a0:	ec06                	sd	ra,24(sp)
    800031a2:	e822                	sd	s0,16(sp)
    800031a4:	e426                	sd	s1,8(sp)
    800031a6:	1000                	addi	s0,sp,32
    800031a8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031aa:	00014517          	auipc	a0,0x14
    800031ae:	13e50513          	addi	a0,a0,318 # 800172e8 <bcache>
    800031b2:	ffffe097          	auipc	ra,0xffffe
    800031b6:	a32080e7          	jalr	-1486(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031ba:	40bc                	lw	a5,64(s1)
    800031bc:	37fd                	addiw	a5,a5,-1
    800031be:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031c0:	00014517          	auipc	a0,0x14
    800031c4:	12850513          	addi	a0,a0,296 # 800172e8 <bcache>
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	ad0080e7          	jalr	-1328(ra) # 80000c98 <release>
}
    800031d0:	60e2                	ld	ra,24(sp)
    800031d2:	6442                	ld	s0,16(sp)
    800031d4:	64a2                	ld	s1,8(sp)
    800031d6:	6105                	addi	sp,sp,32
    800031d8:	8082                	ret

00000000800031da <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031da:	1101                	addi	sp,sp,-32
    800031dc:	ec06                	sd	ra,24(sp)
    800031de:	e822                	sd	s0,16(sp)
    800031e0:	e426                	sd	s1,8(sp)
    800031e2:	e04a                	sd	s2,0(sp)
    800031e4:	1000                	addi	s0,sp,32
    800031e6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031e8:	00d5d59b          	srliw	a1,a1,0xd
    800031ec:	0001c797          	auipc	a5,0x1c
    800031f0:	7d87a783          	lw	a5,2008(a5) # 8001f9c4 <sb+0x1c>
    800031f4:	9dbd                	addw	a1,a1,a5
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	d9e080e7          	jalr	-610(ra) # 80002f94 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031fe:	0074f713          	andi	a4,s1,7
    80003202:	4785                	li	a5,1
    80003204:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003208:	14ce                	slli	s1,s1,0x33
    8000320a:	90d9                	srli	s1,s1,0x36
    8000320c:	00950733          	add	a4,a0,s1
    80003210:	05874703          	lbu	a4,88(a4)
    80003214:	00e7f6b3          	and	a3,a5,a4
    80003218:	c69d                	beqz	a3,80003246 <bfree+0x6c>
    8000321a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000321c:	94aa                	add	s1,s1,a0
    8000321e:	fff7c793          	not	a5,a5
    80003222:	8ff9                	and	a5,a5,a4
    80003224:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003228:	00001097          	auipc	ra,0x1
    8000322c:	118080e7          	jalr	280(ra) # 80004340 <log_write>
  brelse(bp);
    80003230:	854a                	mv	a0,s2
    80003232:	00000097          	auipc	ra,0x0
    80003236:	e92080e7          	jalr	-366(ra) # 800030c4 <brelse>
}
    8000323a:	60e2                	ld	ra,24(sp)
    8000323c:	6442                	ld	s0,16(sp)
    8000323e:	64a2                	ld	s1,8(sp)
    80003240:	6902                	ld	s2,0(sp)
    80003242:	6105                	addi	sp,sp,32
    80003244:	8082                	ret
    panic("freeing free block");
    80003246:	00005517          	auipc	a0,0x5
    8000324a:	34250513          	addi	a0,a0,834 # 80008588 <syscalls+0xf8>
    8000324e:	ffffd097          	auipc	ra,0xffffd
    80003252:	2f0080e7          	jalr	752(ra) # 8000053e <panic>

0000000080003256 <balloc>:
{
    80003256:	711d                	addi	sp,sp,-96
    80003258:	ec86                	sd	ra,88(sp)
    8000325a:	e8a2                	sd	s0,80(sp)
    8000325c:	e4a6                	sd	s1,72(sp)
    8000325e:	e0ca                	sd	s2,64(sp)
    80003260:	fc4e                	sd	s3,56(sp)
    80003262:	f852                	sd	s4,48(sp)
    80003264:	f456                	sd	s5,40(sp)
    80003266:	f05a                	sd	s6,32(sp)
    80003268:	ec5e                	sd	s7,24(sp)
    8000326a:	e862                	sd	s8,16(sp)
    8000326c:	e466                	sd	s9,8(sp)
    8000326e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003270:	0001c797          	auipc	a5,0x1c
    80003274:	73c7a783          	lw	a5,1852(a5) # 8001f9ac <sb+0x4>
    80003278:	cbd1                	beqz	a5,8000330c <balloc+0xb6>
    8000327a:	8baa                	mv	s7,a0
    8000327c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000327e:	0001cb17          	auipc	s6,0x1c
    80003282:	72ab0b13          	addi	s6,s6,1834 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003286:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003288:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000328a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000328c:	6c89                	lui	s9,0x2
    8000328e:	a831                	j	800032aa <balloc+0x54>
    brelse(bp);
    80003290:	854a                	mv	a0,s2
    80003292:	00000097          	auipc	ra,0x0
    80003296:	e32080e7          	jalr	-462(ra) # 800030c4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000329a:	015c87bb          	addw	a5,s9,s5
    8000329e:	00078a9b          	sext.w	s5,a5
    800032a2:	004b2703          	lw	a4,4(s6)
    800032a6:	06eaf363          	bgeu	s5,a4,8000330c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032aa:	41fad79b          	sraiw	a5,s5,0x1f
    800032ae:	0137d79b          	srliw	a5,a5,0x13
    800032b2:	015787bb          	addw	a5,a5,s5
    800032b6:	40d7d79b          	sraiw	a5,a5,0xd
    800032ba:	01cb2583          	lw	a1,28(s6)
    800032be:	9dbd                	addw	a1,a1,a5
    800032c0:	855e                	mv	a0,s7
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	cd2080e7          	jalr	-814(ra) # 80002f94 <bread>
    800032ca:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032cc:	004b2503          	lw	a0,4(s6)
    800032d0:	000a849b          	sext.w	s1,s5
    800032d4:	8662                	mv	a2,s8
    800032d6:	faa4fde3          	bgeu	s1,a0,80003290 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032da:	41f6579b          	sraiw	a5,a2,0x1f
    800032de:	01d7d69b          	srliw	a3,a5,0x1d
    800032e2:	00c6873b          	addw	a4,a3,a2
    800032e6:	00777793          	andi	a5,a4,7
    800032ea:	9f95                	subw	a5,a5,a3
    800032ec:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032f0:	4037571b          	sraiw	a4,a4,0x3
    800032f4:	00e906b3          	add	a3,s2,a4
    800032f8:	0586c683          	lbu	a3,88(a3)
    800032fc:	00d7f5b3          	and	a1,a5,a3
    80003300:	cd91                	beqz	a1,8000331c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003302:	2605                	addiw	a2,a2,1
    80003304:	2485                	addiw	s1,s1,1
    80003306:	fd4618e3          	bne	a2,s4,800032d6 <balloc+0x80>
    8000330a:	b759                	j	80003290 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000330c:	00005517          	auipc	a0,0x5
    80003310:	29450513          	addi	a0,a0,660 # 800085a0 <syscalls+0x110>
    80003314:	ffffd097          	auipc	ra,0xffffd
    80003318:	22a080e7          	jalr	554(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000331c:	974a                	add	a4,a4,s2
    8000331e:	8fd5                	or	a5,a5,a3
    80003320:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003324:	854a                	mv	a0,s2
    80003326:	00001097          	auipc	ra,0x1
    8000332a:	01a080e7          	jalr	26(ra) # 80004340 <log_write>
        brelse(bp);
    8000332e:	854a                	mv	a0,s2
    80003330:	00000097          	auipc	ra,0x0
    80003334:	d94080e7          	jalr	-620(ra) # 800030c4 <brelse>
  bp = bread(dev, bno);
    80003338:	85a6                	mv	a1,s1
    8000333a:	855e                	mv	a0,s7
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	c58080e7          	jalr	-936(ra) # 80002f94 <bread>
    80003344:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003346:	40000613          	li	a2,1024
    8000334a:	4581                	li	a1,0
    8000334c:	05850513          	addi	a0,a0,88
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	990080e7          	jalr	-1648(ra) # 80000ce0 <memset>
  log_write(bp);
    80003358:	854a                	mv	a0,s2
    8000335a:	00001097          	auipc	ra,0x1
    8000335e:	fe6080e7          	jalr	-26(ra) # 80004340 <log_write>
  brelse(bp);
    80003362:	854a                	mv	a0,s2
    80003364:	00000097          	auipc	ra,0x0
    80003368:	d60080e7          	jalr	-672(ra) # 800030c4 <brelse>
}
    8000336c:	8526                	mv	a0,s1
    8000336e:	60e6                	ld	ra,88(sp)
    80003370:	6446                	ld	s0,80(sp)
    80003372:	64a6                	ld	s1,72(sp)
    80003374:	6906                	ld	s2,64(sp)
    80003376:	79e2                	ld	s3,56(sp)
    80003378:	7a42                	ld	s4,48(sp)
    8000337a:	7aa2                	ld	s5,40(sp)
    8000337c:	7b02                	ld	s6,32(sp)
    8000337e:	6be2                	ld	s7,24(sp)
    80003380:	6c42                	ld	s8,16(sp)
    80003382:	6ca2                	ld	s9,8(sp)
    80003384:	6125                	addi	sp,sp,96
    80003386:	8082                	ret

0000000080003388 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003388:	7179                	addi	sp,sp,-48
    8000338a:	f406                	sd	ra,40(sp)
    8000338c:	f022                	sd	s0,32(sp)
    8000338e:	ec26                	sd	s1,24(sp)
    80003390:	e84a                	sd	s2,16(sp)
    80003392:	e44e                	sd	s3,8(sp)
    80003394:	e052                	sd	s4,0(sp)
    80003396:	1800                	addi	s0,sp,48
    80003398:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000339a:	47ad                	li	a5,11
    8000339c:	04b7fe63          	bgeu	a5,a1,800033f8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033a0:	ff45849b          	addiw	s1,a1,-12
    800033a4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033a8:	0ff00793          	li	a5,255
    800033ac:	0ae7e363          	bltu	a5,a4,80003452 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033b0:	08052583          	lw	a1,128(a0)
    800033b4:	c5ad                	beqz	a1,8000341e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033b6:	00092503          	lw	a0,0(s2)
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	bda080e7          	jalr	-1062(ra) # 80002f94 <bread>
    800033c2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033c4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033c8:	02049593          	slli	a1,s1,0x20
    800033cc:	9181                	srli	a1,a1,0x20
    800033ce:	058a                	slli	a1,a1,0x2
    800033d0:	00b784b3          	add	s1,a5,a1
    800033d4:	0004a983          	lw	s3,0(s1)
    800033d8:	04098d63          	beqz	s3,80003432 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033dc:	8552                	mv	a0,s4
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	ce6080e7          	jalr	-794(ra) # 800030c4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033e6:	854e                	mv	a0,s3
    800033e8:	70a2                	ld	ra,40(sp)
    800033ea:	7402                	ld	s0,32(sp)
    800033ec:	64e2                	ld	s1,24(sp)
    800033ee:	6942                	ld	s2,16(sp)
    800033f0:	69a2                	ld	s3,8(sp)
    800033f2:	6a02                	ld	s4,0(sp)
    800033f4:	6145                	addi	sp,sp,48
    800033f6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033f8:	02059493          	slli	s1,a1,0x20
    800033fc:	9081                	srli	s1,s1,0x20
    800033fe:	048a                	slli	s1,s1,0x2
    80003400:	94aa                	add	s1,s1,a0
    80003402:	0504a983          	lw	s3,80(s1)
    80003406:	fe0990e3          	bnez	s3,800033e6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000340a:	4108                	lw	a0,0(a0)
    8000340c:	00000097          	auipc	ra,0x0
    80003410:	e4a080e7          	jalr	-438(ra) # 80003256 <balloc>
    80003414:	0005099b          	sext.w	s3,a0
    80003418:	0534a823          	sw	s3,80(s1)
    8000341c:	b7e9                	j	800033e6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000341e:	4108                	lw	a0,0(a0)
    80003420:	00000097          	auipc	ra,0x0
    80003424:	e36080e7          	jalr	-458(ra) # 80003256 <balloc>
    80003428:	0005059b          	sext.w	a1,a0
    8000342c:	08b92023          	sw	a1,128(s2)
    80003430:	b759                	j	800033b6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003432:	00092503          	lw	a0,0(s2)
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	e20080e7          	jalr	-480(ra) # 80003256 <balloc>
    8000343e:	0005099b          	sext.w	s3,a0
    80003442:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003446:	8552                	mv	a0,s4
    80003448:	00001097          	auipc	ra,0x1
    8000344c:	ef8080e7          	jalr	-264(ra) # 80004340 <log_write>
    80003450:	b771                	j	800033dc <bmap+0x54>
  panic("bmap: out of range");
    80003452:	00005517          	auipc	a0,0x5
    80003456:	16650513          	addi	a0,a0,358 # 800085b8 <syscalls+0x128>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	0e4080e7          	jalr	228(ra) # 8000053e <panic>

0000000080003462 <iget>:
{
    80003462:	7179                	addi	sp,sp,-48
    80003464:	f406                	sd	ra,40(sp)
    80003466:	f022                	sd	s0,32(sp)
    80003468:	ec26                	sd	s1,24(sp)
    8000346a:	e84a                	sd	s2,16(sp)
    8000346c:	e44e                	sd	s3,8(sp)
    8000346e:	e052                	sd	s4,0(sp)
    80003470:	1800                	addi	s0,sp,48
    80003472:	89aa                	mv	s3,a0
    80003474:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003476:	0001c517          	auipc	a0,0x1c
    8000347a:	55250513          	addi	a0,a0,1362 # 8001f9c8 <itable>
    8000347e:	ffffd097          	auipc	ra,0xffffd
    80003482:	766080e7          	jalr	1894(ra) # 80000be4 <acquire>
  empty = 0;
    80003486:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003488:	0001c497          	auipc	s1,0x1c
    8000348c:	55848493          	addi	s1,s1,1368 # 8001f9e0 <itable+0x18>
    80003490:	0001e697          	auipc	a3,0x1e
    80003494:	fe068693          	addi	a3,a3,-32 # 80021470 <log>
    80003498:	a039                	j	800034a6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000349a:	02090b63          	beqz	s2,800034d0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000349e:	08848493          	addi	s1,s1,136
    800034a2:	02d48a63          	beq	s1,a3,800034d6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034a6:	449c                	lw	a5,8(s1)
    800034a8:	fef059e3          	blez	a5,8000349a <iget+0x38>
    800034ac:	4098                	lw	a4,0(s1)
    800034ae:	ff3716e3          	bne	a4,s3,8000349a <iget+0x38>
    800034b2:	40d8                	lw	a4,4(s1)
    800034b4:	ff4713e3          	bne	a4,s4,8000349a <iget+0x38>
      ip->ref++;
    800034b8:	2785                	addiw	a5,a5,1
    800034ba:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034bc:	0001c517          	auipc	a0,0x1c
    800034c0:	50c50513          	addi	a0,a0,1292 # 8001f9c8 <itable>
    800034c4:	ffffd097          	auipc	ra,0xffffd
    800034c8:	7d4080e7          	jalr	2004(ra) # 80000c98 <release>
      return ip;
    800034cc:	8926                	mv	s2,s1
    800034ce:	a03d                	j	800034fc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034d0:	f7f9                	bnez	a5,8000349e <iget+0x3c>
    800034d2:	8926                	mv	s2,s1
    800034d4:	b7e9                	j	8000349e <iget+0x3c>
  if(empty == 0)
    800034d6:	02090c63          	beqz	s2,8000350e <iget+0xac>
  ip->dev = dev;
    800034da:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034de:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034e2:	4785                	li	a5,1
    800034e4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034e8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034ec:	0001c517          	auipc	a0,0x1c
    800034f0:	4dc50513          	addi	a0,a0,1244 # 8001f9c8 <itable>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	7a4080e7          	jalr	1956(ra) # 80000c98 <release>
}
    800034fc:	854a                	mv	a0,s2
    800034fe:	70a2                	ld	ra,40(sp)
    80003500:	7402                	ld	s0,32(sp)
    80003502:	64e2                	ld	s1,24(sp)
    80003504:	6942                	ld	s2,16(sp)
    80003506:	69a2                	ld	s3,8(sp)
    80003508:	6a02                	ld	s4,0(sp)
    8000350a:	6145                	addi	sp,sp,48
    8000350c:	8082                	ret
    panic("iget: no inodes");
    8000350e:	00005517          	auipc	a0,0x5
    80003512:	0c250513          	addi	a0,a0,194 # 800085d0 <syscalls+0x140>
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	028080e7          	jalr	40(ra) # 8000053e <panic>

000000008000351e <fsinit>:
fsinit(int dev) {
    8000351e:	7179                	addi	sp,sp,-48
    80003520:	f406                	sd	ra,40(sp)
    80003522:	f022                	sd	s0,32(sp)
    80003524:	ec26                	sd	s1,24(sp)
    80003526:	e84a                	sd	s2,16(sp)
    80003528:	e44e                	sd	s3,8(sp)
    8000352a:	1800                	addi	s0,sp,48
    8000352c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000352e:	4585                	li	a1,1
    80003530:	00000097          	auipc	ra,0x0
    80003534:	a64080e7          	jalr	-1436(ra) # 80002f94 <bread>
    80003538:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000353a:	0001c997          	auipc	s3,0x1c
    8000353e:	46e98993          	addi	s3,s3,1134 # 8001f9a8 <sb>
    80003542:	02000613          	li	a2,32
    80003546:	05850593          	addi	a1,a0,88
    8000354a:	854e                	mv	a0,s3
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	7f4080e7          	jalr	2036(ra) # 80000d40 <memmove>
  brelse(bp);
    80003554:	8526                	mv	a0,s1
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	b6e080e7          	jalr	-1170(ra) # 800030c4 <brelse>
  if(sb.magic != FSMAGIC)
    8000355e:	0009a703          	lw	a4,0(s3)
    80003562:	102037b7          	lui	a5,0x10203
    80003566:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000356a:	02f71263          	bne	a4,a5,8000358e <fsinit+0x70>
  initlog(dev, &sb);
    8000356e:	0001c597          	auipc	a1,0x1c
    80003572:	43a58593          	addi	a1,a1,1082 # 8001f9a8 <sb>
    80003576:	854a                	mv	a0,s2
    80003578:	00001097          	auipc	ra,0x1
    8000357c:	b4c080e7          	jalr	-1204(ra) # 800040c4 <initlog>
}
    80003580:	70a2                	ld	ra,40(sp)
    80003582:	7402                	ld	s0,32(sp)
    80003584:	64e2                	ld	s1,24(sp)
    80003586:	6942                	ld	s2,16(sp)
    80003588:	69a2                	ld	s3,8(sp)
    8000358a:	6145                	addi	sp,sp,48
    8000358c:	8082                	ret
    panic("invalid file system");
    8000358e:	00005517          	auipc	a0,0x5
    80003592:	05250513          	addi	a0,a0,82 # 800085e0 <syscalls+0x150>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	fa8080e7          	jalr	-88(ra) # 8000053e <panic>

000000008000359e <iinit>:
{
    8000359e:	7179                	addi	sp,sp,-48
    800035a0:	f406                	sd	ra,40(sp)
    800035a2:	f022                	sd	s0,32(sp)
    800035a4:	ec26                	sd	s1,24(sp)
    800035a6:	e84a                	sd	s2,16(sp)
    800035a8:	e44e                	sd	s3,8(sp)
    800035aa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035ac:	00005597          	auipc	a1,0x5
    800035b0:	04c58593          	addi	a1,a1,76 # 800085f8 <syscalls+0x168>
    800035b4:	0001c517          	auipc	a0,0x1c
    800035b8:	41450513          	addi	a0,a0,1044 # 8001f9c8 <itable>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	598080e7          	jalr	1432(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035c4:	0001c497          	auipc	s1,0x1c
    800035c8:	42c48493          	addi	s1,s1,1068 # 8001f9f0 <itable+0x28>
    800035cc:	0001e997          	auipc	s3,0x1e
    800035d0:	eb498993          	addi	s3,s3,-332 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035d4:	00005917          	auipc	s2,0x5
    800035d8:	02c90913          	addi	s2,s2,44 # 80008600 <syscalls+0x170>
    800035dc:	85ca                	mv	a1,s2
    800035de:	8526                	mv	a0,s1
    800035e0:	00001097          	auipc	ra,0x1
    800035e4:	e46080e7          	jalr	-442(ra) # 80004426 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035e8:	08848493          	addi	s1,s1,136
    800035ec:	ff3498e3          	bne	s1,s3,800035dc <iinit+0x3e>
}
    800035f0:	70a2                	ld	ra,40(sp)
    800035f2:	7402                	ld	s0,32(sp)
    800035f4:	64e2                	ld	s1,24(sp)
    800035f6:	6942                	ld	s2,16(sp)
    800035f8:	69a2                	ld	s3,8(sp)
    800035fa:	6145                	addi	sp,sp,48
    800035fc:	8082                	ret

00000000800035fe <ialloc>:
{
    800035fe:	715d                	addi	sp,sp,-80
    80003600:	e486                	sd	ra,72(sp)
    80003602:	e0a2                	sd	s0,64(sp)
    80003604:	fc26                	sd	s1,56(sp)
    80003606:	f84a                	sd	s2,48(sp)
    80003608:	f44e                	sd	s3,40(sp)
    8000360a:	f052                	sd	s4,32(sp)
    8000360c:	ec56                	sd	s5,24(sp)
    8000360e:	e85a                	sd	s6,16(sp)
    80003610:	e45e                	sd	s7,8(sp)
    80003612:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003614:	0001c717          	auipc	a4,0x1c
    80003618:	3a072703          	lw	a4,928(a4) # 8001f9b4 <sb+0xc>
    8000361c:	4785                	li	a5,1
    8000361e:	04e7fa63          	bgeu	a5,a4,80003672 <ialloc+0x74>
    80003622:	8aaa                	mv	s5,a0
    80003624:	8bae                	mv	s7,a1
    80003626:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003628:	0001ca17          	auipc	s4,0x1c
    8000362c:	380a0a13          	addi	s4,s4,896 # 8001f9a8 <sb>
    80003630:	00048b1b          	sext.w	s6,s1
    80003634:	0044d593          	srli	a1,s1,0x4
    80003638:	018a2783          	lw	a5,24(s4)
    8000363c:	9dbd                	addw	a1,a1,a5
    8000363e:	8556                	mv	a0,s5
    80003640:	00000097          	auipc	ra,0x0
    80003644:	954080e7          	jalr	-1708(ra) # 80002f94 <bread>
    80003648:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000364a:	05850993          	addi	s3,a0,88
    8000364e:	00f4f793          	andi	a5,s1,15
    80003652:	079a                	slli	a5,a5,0x6
    80003654:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003656:	00099783          	lh	a5,0(s3)
    8000365a:	c785                	beqz	a5,80003682 <ialloc+0x84>
    brelse(bp);
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	a68080e7          	jalr	-1432(ra) # 800030c4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003664:	0485                	addi	s1,s1,1
    80003666:	00ca2703          	lw	a4,12(s4)
    8000366a:	0004879b          	sext.w	a5,s1
    8000366e:	fce7e1e3          	bltu	a5,a4,80003630 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003672:	00005517          	auipc	a0,0x5
    80003676:	f9650513          	addi	a0,a0,-106 # 80008608 <syscalls+0x178>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	ec4080e7          	jalr	-316(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003682:	04000613          	li	a2,64
    80003686:	4581                	li	a1,0
    80003688:	854e                	mv	a0,s3
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	656080e7          	jalr	1622(ra) # 80000ce0 <memset>
      dip->type = type;
    80003692:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003696:	854a                	mv	a0,s2
    80003698:	00001097          	auipc	ra,0x1
    8000369c:	ca8080e7          	jalr	-856(ra) # 80004340 <log_write>
      brelse(bp);
    800036a0:	854a                	mv	a0,s2
    800036a2:	00000097          	auipc	ra,0x0
    800036a6:	a22080e7          	jalr	-1502(ra) # 800030c4 <brelse>
      return iget(dev, inum);
    800036aa:	85da                	mv	a1,s6
    800036ac:	8556                	mv	a0,s5
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	db4080e7          	jalr	-588(ra) # 80003462 <iget>
}
    800036b6:	60a6                	ld	ra,72(sp)
    800036b8:	6406                	ld	s0,64(sp)
    800036ba:	74e2                	ld	s1,56(sp)
    800036bc:	7942                	ld	s2,48(sp)
    800036be:	79a2                	ld	s3,40(sp)
    800036c0:	7a02                	ld	s4,32(sp)
    800036c2:	6ae2                	ld	s5,24(sp)
    800036c4:	6b42                	ld	s6,16(sp)
    800036c6:	6ba2                	ld	s7,8(sp)
    800036c8:	6161                	addi	sp,sp,80
    800036ca:	8082                	ret

00000000800036cc <iupdate>:
{
    800036cc:	1101                	addi	sp,sp,-32
    800036ce:	ec06                	sd	ra,24(sp)
    800036d0:	e822                	sd	s0,16(sp)
    800036d2:	e426                	sd	s1,8(sp)
    800036d4:	e04a                	sd	s2,0(sp)
    800036d6:	1000                	addi	s0,sp,32
    800036d8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036da:	415c                	lw	a5,4(a0)
    800036dc:	0047d79b          	srliw	a5,a5,0x4
    800036e0:	0001c597          	auipc	a1,0x1c
    800036e4:	2e05a583          	lw	a1,736(a1) # 8001f9c0 <sb+0x18>
    800036e8:	9dbd                	addw	a1,a1,a5
    800036ea:	4108                	lw	a0,0(a0)
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	8a8080e7          	jalr	-1880(ra) # 80002f94 <bread>
    800036f4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036f6:	05850793          	addi	a5,a0,88
    800036fa:	40c8                	lw	a0,4(s1)
    800036fc:	893d                	andi	a0,a0,15
    800036fe:	051a                	slli	a0,a0,0x6
    80003700:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003702:	04449703          	lh	a4,68(s1)
    80003706:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000370a:	04649703          	lh	a4,70(s1)
    8000370e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003712:	04849703          	lh	a4,72(s1)
    80003716:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000371a:	04a49703          	lh	a4,74(s1)
    8000371e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003722:	44f8                	lw	a4,76(s1)
    80003724:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003726:	03400613          	li	a2,52
    8000372a:	05048593          	addi	a1,s1,80
    8000372e:	0531                	addi	a0,a0,12
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	610080e7          	jalr	1552(ra) # 80000d40 <memmove>
  log_write(bp);
    80003738:	854a                	mv	a0,s2
    8000373a:	00001097          	auipc	ra,0x1
    8000373e:	c06080e7          	jalr	-1018(ra) # 80004340 <log_write>
  brelse(bp);
    80003742:	854a                	mv	a0,s2
    80003744:	00000097          	auipc	ra,0x0
    80003748:	980080e7          	jalr	-1664(ra) # 800030c4 <brelse>
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6902                	ld	s2,0(sp)
    80003754:	6105                	addi	sp,sp,32
    80003756:	8082                	ret

0000000080003758 <idup>:
{
    80003758:	1101                	addi	sp,sp,-32
    8000375a:	ec06                	sd	ra,24(sp)
    8000375c:	e822                	sd	s0,16(sp)
    8000375e:	e426                	sd	s1,8(sp)
    80003760:	1000                	addi	s0,sp,32
    80003762:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003764:	0001c517          	auipc	a0,0x1c
    80003768:	26450513          	addi	a0,a0,612 # 8001f9c8 <itable>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	478080e7          	jalr	1144(ra) # 80000be4 <acquire>
  ip->ref++;
    80003774:	449c                	lw	a5,8(s1)
    80003776:	2785                	addiw	a5,a5,1
    80003778:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000377a:	0001c517          	auipc	a0,0x1c
    8000377e:	24e50513          	addi	a0,a0,590 # 8001f9c8 <itable>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	516080e7          	jalr	1302(ra) # 80000c98 <release>
}
    8000378a:	8526                	mv	a0,s1
    8000378c:	60e2                	ld	ra,24(sp)
    8000378e:	6442                	ld	s0,16(sp)
    80003790:	64a2                	ld	s1,8(sp)
    80003792:	6105                	addi	sp,sp,32
    80003794:	8082                	ret

0000000080003796 <ilock>:
{
    80003796:	1101                	addi	sp,sp,-32
    80003798:	ec06                	sd	ra,24(sp)
    8000379a:	e822                	sd	s0,16(sp)
    8000379c:	e426                	sd	s1,8(sp)
    8000379e:	e04a                	sd	s2,0(sp)
    800037a0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037a2:	c115                	beqz	a0,800037c6 <ilock+0x30>
    800037a4:	84aa                	mv	s1,a0
    800037a6:	451c                	lw	a5,8(a0)
    800037a8:	00f05f63          	blez	a5,800037c6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037ac:	0541                	addi	a0,a0,16
    800037ae:	00001097          	auipc	ra,0x1
    800037b2:	cb2080e7          	jalr	-846(ra) # 80004460 <acquiresleep>
  if(ip->valid == 0){
    800037b6:	40bc                	lw	a5,64(s1)
    800037b8:	cf99                	beqz	a5,800037d6 <ilock+0x40>
}
    800037ba:	60e2                	ld	ra,24(sp)
    800037bc:	6442                	ld	s0,16(sp)
    800037be:	64a2                	ld	s1,8(sp)
    800037c0:	6902                	ld	s2,0(sp)
    800037c2:	6105                	addi	sp,sp,32
    800037c4:	8082                	ret
    panic("ilock");
    800037c6:	00005517          	auipc	a0,0x5
    800037ca:	e5a50513          	addi	a0,a0,-422 # 80008620 <syscalls+0x190>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	d70080e7          	jalr	-656(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037d6:	40dc                	lw	a5,4(s1)
    800037d8:	0047d79b          	srliw	a5,a5,0x4
    800037dc:	0001c597          	auipc	a1,0x1c
    800037e0:	1e45a583          	lw	a1,484(a1) # 8001f9c0 <sb+0x18>
    800037e4:	9dbd                	addw	a1,a1,a5
    800037e6:	4088                	lw	a0,0(s1)
    800037e8:	fffff097          	auipc	ra,0xfffff
    800037ec:	7ac080e7          	jalr	1964(ra) # 80002f94 <bread>
    800037f0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037f2:	05850593          	addi	a1,a0,88
    800037f6:	40dc                	lw	a5,4(s1)
    800037f8:	8bbd                	andi	a5,a5,15
    800037fa:	079a                	slli	a5,a5,0x6
    800037fc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037fe:	00059783          	lh	a5,0(a1)
    80003802:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003806:	00259783          	lh	a5,2(a1)
    8000380a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000380e:	00459783          	lh	a5,4(a1)
    80003812:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003816:	00659783          	lh	a5,6(a1)
    8000381a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000381e:	459c                	lw	a5,8(a1)
    80003820:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003822:	03400613          	li	a2,52
    80003826:	05b1                	addi	a1,a1,12
    80003828:	05048513          	addi	a0,s1,80
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	514080e7          	jalr	1300(ra) # 80000d40 <memmove>
    brelse(bp);
    80003834:	854a                	mv	a0,s2
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	88e080e7          	jalr	-1906(ra) # 800030c4 <brelse>
    ip->valid = 1;
    8000383e:	4785                	li	a5,1
    80003840:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003842:	04449783          	lh	a5,68(s1)
    80003846:	fbb5                	bnez	a5,800037ba <ilock+0x24>
      panic("ilock: no type");
    80003848:	00005517          	auipc	a0,0x5
    8000384c:	de050513          	addi	a0,a0,-544 # 80008628 <syscalls+0x198>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	cee080e7          	jalr	-786(ra) # 8000053e <panic>

0000000080003858 <iunlock>:
{
    80003858:	1101                	addi	sp,sp,-32
    8000385a:	ec06                	sd	ra,24(sp)
    8000385c:	e822                	sd	s0,16(sp)
    8000385e:	e426                	sd	s1,8(sp)
    80003860:	e04a                	sd	s2,0(sp)
    80003862:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003864:	c905                	beqz	a0,80003894 <iunlock+0x3c>
    80003866:	84aa                	mv	s1,a0
    80003868:	01050913          	addi	s2,a0,16
    8000386c:	854a                	mv	a0,s2
    8000386e:	00001097          	auipc	ra,0x1
    80003872:	c8c080e7          	jalr	-884(ra) # 800044fa <holdingsleep>
    80003876:	cd19                	beqz	a0,80003894 <iunlock+0x3c>
    80003878:	449c                	lw	a5,8(s1)
    8000387a:	00f05d63          	blez	a5,80003894 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000387e:	854a                	mv	a0,s2
    80003880:	00001097          	auipc	ra,0x1
    80003884:	c36080e7          	jalr	-970(ra) # 800044b6 <releasesleep>
}
    80003888:	60e2                	ld	ra,24(sp)
    8000388a:	6442                	ld	s0,16(sp)
    8000388c:	64a2                	ld	s1,8(sp)
    8000388e:	6902                	ld	s2,0(sp)
    80003890:	6105                	addi	sp,sp,32
    80003892:	8082                	ret
    panic("iunlock");
    80003894:	00005517          	auipc	a0,0x5
    80003898:	da450513          	addi	a0,a0,-604 # 80008638 <syscalls+0x1a8>
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	ca2080e7          	jalr	-862(ra) # 8000053e <panic>

00000000800038a4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038a4:	7179                	addi	sp,sp,-48
    800038a6:	f406                	sd	ra,40(sp)
    800038a8:	f022                	sd	s0,32(sp)
    800038aa:	ec26                	sd	s1,24(sp)
    800038ac:	e84a                	sd	s2,16(sp)
    800038ae:	e44e                	sd	s3,8(sp)
    800038b0:	e052                	sd	s4,0(sp)
    800038b2:	1800                	addi	s0,sp,48
    800038b4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038b6:	05050493          	addi	s1,a0,80
    800038ba:	08050913          	addi	s2,a0,128
    800038be:	a021                	j	800038c6 <itrunc+0x22>
    800038c0:	0491                	addi	s1,s1,4
    800038c2:	01248d63          	beq	s1,s2,800038dc <itrunc+0x38>
    if(ip->addrs[i]){
    800038c6:	408c                	lw	a1,0(s1)
    800038c8:	dde5                	beqz	a1,800038c0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ca:	0009a503          	lw	a0,0(s3)
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	90c080e7          	jalr	-1780(ra) # 800031da <bfree>
      ip->addrs[i] = 0;
    800038d6:	0004a023          	sw	zero,0(s1)
    800038da:	b7dd                	j	800038c0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038dc:	0809a583          	lw	a1,128(s3)
    800038e0:	e185                	bnez	a1,80003900 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038e2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038e6:	854e                	mv	a0,s3
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	de4080e7          	jalr	-540(ra) # 800036cc <iupdate>
}
    800038f0:	70a2                	ld	ra,40(sp)
    800038f2:	7402                	ld	s0,32(sp)
    800038f4:	64e2                	ld	s1,24(sp)
    800038f6:	6942                	ld	s2,16(sp)
    800038f8:	69a2                	ld	s3,8(sp)
    800038fa:	6a02                	ld	s4,0(sp)
    800038fc:	6145                	addi	sp,sp,48
    800038fe:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003900:	0009a503          	lw	a0,0(s3)
    80003904:	fffff097          	auipc	ra,0xfffff
    80003908:	690080e7          	jalr	1680(ra) # 80002f94 <bread>
    8000390c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000390e:	05850493          	addi	s1,a0,88
    80003912:	45850913          	addi	s2,a0,1112
    80003916:	a811                	j	8000392a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003918:	0009a503          	lw	a0,0(s3)
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	8be080e7          	jalr	-1858(ra) # 800031da <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003924:	0491                	addi	s1,s1,4
    80003926:	01248563          	beq	s1,s2,80003930 <itrunc+0x8c>
      if(a[j])
    8000392a:	408c                	lw	a1,0(s1)
    8000392c:	dde5                	beqz	a1,80003924 <itrunc+0x80>
    8000392e:	b7ed                	j	80003918 <itrunc+0x74>
    brelse(bp);
    80003930:	8552                	mv	a0,s4
    80003932:	fffff097          	auipc	ra,0xfffff
    80003936:	792080e7          	jalr	1938(ra) # 800030c4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000393a:	0809a583          	lw	a1,128(s3)
    8000393e:	0009a503          	lw	a0,0(s3)
    80003942:	00000097          	auipc	ra,0x0
    80003946:	898080e7          	jalr	-1896(ra) # 800031da <bfree>
    ip->addrs[NDIRECT] = 0;
    8000394a:	0809a023          	sw	zero,128(s3)
    8000394e:	bf51                	j	800038e2 <itrunc+0x3e>

0000000080003950 <iput>:
{
    80003950:	1101                	addi	sp,sp,-32
    80003952:	ec06                	sd	ra,24(sp)
    80003954:	e822                	sd	s0,16(sp)
    80003956:	e426                	sd	s1,8(sp)
    80003958:	e04a                	sd	s2,0(sp)
    8000395a:	1000                	addi	s0,sp,32
    8000395c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000395e:	0001c517          	auipc	a0,0x1c
    80003962:	06a50513          	addi	a0,a0,106 # 8001f9c8 <itable>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	27e080e7          	jalr	638(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000396e:	4498                	lw	a4,8(s1)
    80003970:	4785                	li	a5,1
    80003972:	02f70363          	beq	a4,a5,80003998 <iput+0x48>
  ip->ref--;
    80003976:	449c                	lw	a5,8(s1)
    80003978:	37fd                	addiw	a5,a5,-1
    8000397a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000397c:	0001c517          	auipc	a0,0x1c
    80003980:	04c50513          	addi	a0,a0,76 # 8001f9c8 <itable>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	314080e7          	jalr	788(ra) # 80000c98 <release>
}
    8000398c:	60e2                	ld	ra,24(sp)
    8000398e:	6442                	ld	s0,16(sp)
    80003990:	64a2                	ld	s1,8(sp)
    80003992:	6902                	ld	s2,0(sp)
    80003994:	6105                	addi	sp,sp,32
    80003996:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003998:	40bc                	lw	a5,64(s1)
    8000399a:	dff1                	beqz	a5,80003976 <iput+0x26>
    8000399c:	04a49783          	lh	a5,74(s1)
    800039a0:	fbf9                	bnez	a5,80003976 <iput+0x26>
    acquiresleep(&ip->lock);
    800039a2:	01048913          	addi	s2,s1,16
    800039a6:	854a                	mv	a0,s2
    800039a8:	00001097          	auipc	ra,0x1
    800039ac:	ab8080e7          	jalr	-1352(ra) # 80004460 <acquiresleep>
    release(&itable.lock);
    800039b0:	0001c517          	auipc	a0,0x1c
    800039b4:	01850513          	addi	a0,a0,24 # 8001f9c8 <itable>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	2e0080e7          	jalr	736(ra) # 80000c98 <release>
    itrunc(ip);
    800039c0:	8526                	mv	a0,s1
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	ee2080e7          	jalr	-286(ra) # 800038a4 <itrunc>
    ip->type = 0;
    800039ca:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039ce:	8526                	mv	a0,s1
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	cfc080e7          	jalr	-772(ra) # 800036cc <iupdate>
    ip->valid = 0;
    800039d8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039dc:	854a                	mv	a0,s2
    800039de:	00001097          	auipc	ra,0x1
    800039e2:	ad8080e7          	jalr	-1320(ra) # 800044b6 <releasesleep>
    acquire(&itable.lock);
    800039e6:	0001c517          	auipc	a0,0x1c
    800039ea:	fe250513          	addi	a0,a0,-30 # 8001f9c8 <itable>
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	1f6080e7          	jalr	502(ra) # 80000be4 <acquire>
    800039f6:	b741                	j	80003976 <iput+0x26>

00000000800039f8 <iunlockput>:
{
    800039f8:	1101                	addi	sp,sp,-32
    800039fa:	ec06                	sd	ra,24(sp)
    800039fc:	e822                	sd	s0,16(sp)
    800039fe:	e426                	sd	s1,8(sp)
    80003a00:	1000                	addi	s0,sp,32
    80003a02:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	e54080e7          	jalr	-428(ra) # 80003858 <iunlock>
  iput(ip);
    80003a0c:	8526                	mv	a0,s1
    80003a0e:	00000097          	auipc	ra,0x0
    80003a12:	f42080e7          	jalr	-190(ra) # 80003950 <iput>
}
    80003a16:	60e2                	ld	ra,24(sp)
    80003a18:	6442                	ld	s0,16(sp)
    80003a1a:	64a2                	ld	s1,8(sp)
    80003a1c:	6105                	addi	sp,sp,32
    80003a1e:	8082                	ret

0000000080003a20 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a20:	1141                	addi	sp,sp,-16
    80003a22:	e422                	sd	s0,8(sp)
    80003a24:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a26:	411c                	lw	a5,0(a0)
    80003a28:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a2a:	415c                	lw	a5,4(a0)
    80003a2c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a2e:	04451783          	lh	a5,68(a0)
    80003a32:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a36:	04a51783          	lh	a5,74(a0)
    80003a3a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a3e:	04c56783          	lwu	a5,76(a0)
    80003a42:	e99c                	sd	a5,16(a1)
}
    80003a44:	6422                	ld	s0,8(sp)
    80003a46:	0141                	addi	sp,sp,16
    80003a48:	8082                	ret

0000000080003a4a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a4a:	457c                	lw	a5,76(a0)
    80003a4c:	0ed7e963          	bltu	a5,a3,80003b3e <readi+0xf4>
{
    80003a50:	7159                	addi	sp,sp,-112
    80003a52:	f486                	sd	ra,104(sp)
    80003a54:	f0a2                	sd	s0,96(sp)
    80003a56:	eca6                	sd	s1,88(sp)
    80003a58:	e8ca                	sd	s2,80(sp)
    80003a5a:	e4ce                	sd	s3,72(sp)
    80003a5c:	e0d2                	sd	s4,64(sp)
    80003a5e:	fc56                	sd	s5,56(sp)
    80003a60:	f85a                	sd	s6,48(sp)
    80003a62:	f45e                	sd	s7,40(sp)
    80003a64:	f062                	sd	s8,32(sp)
    80003a66:	ec66                	sd	s9,24(sp)
    80003a68:	e86a                	sd	s10,16(sp)
    80003a6a:	e46e                	sd	s11,8(sp)
    80003a6c:	1880                	addi	s0,sp,112
    80003a6e:	8baa                	mv	s7,a0
    80003a70:	8c2e                	mv	s8,a1
    80003a72:	8ab2                	mv	s5,a2
    80003a74:	84b6                	mv	s1,a3
    80003a76:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a78:	9f35                	addw	a4,a4,a3
    return 0;
    80003a7a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a7c:	0ad76063          	bltu	a4,a3,80003b1c <readi+0xd2>
  if(off + n > ip->size)
    80003a80:	00e7f463          	bgeu	a5,a4,80003a88 <readi+0x3e>
    n = ip->size - off;
    80003a84:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a88:	0a0b0963          	beqz	s6,80003b3a <readi+0xf0>
    80003a8c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a8e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a92:	5cfd                	li	s9,-1
    80003a94:	a82d                	j	80003ace <readi+0x84>
    80003a96:	020a1d93          	slli	s11,s4,0x20
    80003a9a:	020ddd93          	srli	s11,s11,0x20
    80003a9e:	05890613          	addi	a2,s2,88
    80003aa2:	86ee                	mv	a3,s11
    80003aa4:	963a                	add	a2,a2,a4
    80003aa6:	85d6                	mv	a1,s5
    80003aa8:	8562                	mv	a0,s8
    80003aaa:	fffff097          	auipc	ra,0xfffff
    80003aae:	a16080e7          	jalr	-1514(ra) # 800024c0 <either_copyout>
    80003ab2:	05950d63          	beq	a0,s9,80003b0c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ab6:	854a                	mv	a0,s2
    80003ab8:	fffff097          	auipc	ra,0xfffff
    80003abc:	60c080e7          	jalr	1548(ra) # 800030c4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac0:	013a09bb          	addw	s3,s4,s3
    80003ac4:	009a04bb          	addw	s1,s4,s1
    80003ac8:	9aee                	add	s5,s5,s11
    80003aca:	0569f763          	bgeu	s3,s6,80003b18 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ace:	000ba903          	lw	s2,0(s7)
    80003ad2:	00a4d59b          	srliw	a1,s1,0xa
    80003ad6:	855e                	mv	a0,s7
    80003ad8:	00000097          	auipc	ra,0x0
    80003adc:	8b0080e7          	jalr	-1872(ra) # 80003388 <bmap>
    80003ae0:	0005059b          	sext.w	a1,a0
    80003ae4:	854a                	mv	a0,s2
    80003ae6:	fffff097          	auipc	ra,0xfffff
    80003aea:	4ae080e7          	jalr	1198(ra) # 80002f94 <bread>
    80003aee:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af0:	3ff4f713          	andi	a4,s1,1023
    80003af4:	40ed07bb          	subw	a5,s10,a4
    80003af8:	413b06bb          	subw	a3,s6,s3
    80003afc:	8a3e                	mv	s4,a5
    80003afe:	2781                	sext.w	a5,a5
    80003b00:	0006861b          	sext.w	a2,a3
    80003b04:	f8f679e3          	bgeu	a2,a5,80003a96 <readi+0x4c>
    80003b08:	8a36                	mv	s4,a3
    80003b0a:	b771                	j	80003a96 <readi+0x4c>
      brelse(bp);
    80003b0c:	854a                	mv	a0,s2
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	5b6080e7          	jalr	1462(ra) # 800030c4 <brelse>
      tot = -1;
    80003b16:	59fd                	li	s3,-1
  }
  return tot;
    80003b18:	0009851b          	sext.w	a0,s3
}
    80003b1c:	70a6                	ld	ra,104(sp)
    80003b1e:	7406                	ld	s0,96(sp)
    80003b20:	64e6                	ld	s1,88(sp)
    80003b22:	6946                	ld	s2,80(sp)
    80003b24:	69a6                	ld	s3,72(sp)
    80003b26:	6a06                	ld	s4,64(sp)
    80003b28:	7ae2                	ld	s5,56(sp)
    80003b2a:	7b42                	ld	s6,48(sp)
    80003b2c:	7ba2                	ld	s7,40(sp)
    80003b2e:	7c02                	ld	s8,32(sp)
    80003b30:	6ce2                	ld	s9,24(sp)
    80003b32:	6d42                	ld	s10,16(sp)
    80003b34:	6da2                	ld	s11,8(sp)
    80003b36:	6165                	addi	sp,sp,112
    80003b38:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b3a:	89da                	mv	s3,s6
    80003b3c:	bff1                	j	80003b18 <readi+0xce>
    return 0;
    80003b3e:	4501                	li	a0,0
}
    80003b40:	8082                	ret

0000000080003b42 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b42:	457c                	lw	a5,76(a0)
    80003b44:	10d7e863          	bltu	a5,a3,80003c54 <writei+0x112>
{
    80003b48:	7159                	addi	sp,sp,-112
    80003b4a:	f486                	sd	ra,104(sp)
    80003b4c:	f0a2                	sd	s0,96(sp)
    80003b4e:	eca6                	sd	s1,88(sp)
    80003b50:	e8ca                	sd	s2,80(sp)
    80003b52:	e4ce                	sd	s3,72(sp)
    80003b54:	e0d2                	sd	s4,64(sp)
    80003b56:	fc56                	sd	s5,56(sp)
    80003b58:	f85a                	sd	s6,48(sp)
    80003b5a:	f45e                	sd	s7,40(sp)
    80003b5c:	f062                	sd	s8,32(sp)
    80003b5e:	ec66                	sd	s9,24(sp)
    80003b60:	e86a                	sd	s10,16(sp)
    80003b62:	e46e                	sd	s11,8(sp)
    80003b64:	1880                	addi	s0,sp,112
    80003b66:	8b2a                	mv	s6,a0
    80003b68:	8c2e                	mv	s8,a1
    80003b6a:	8ab2                	mv	s5,a2
    80003b6c:	8936                	mv	s2,a3
    80003b6e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b70:	00e687bb          	addw	a5,a3,a4
    80003b74:	0ed7e263          	bltu	a5,a3,80003c58 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b78:	00043737          	lui	a4,0x43
    80003b7c:	0ef76063          	bltu	a4,a5,80003c5c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b80:	0c0b8863          	beqz	s7,80003c50 <writei+0x10e>
    80003b84:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b86:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b8a:	5cfd                	li	s9,-1
    80003b8c:	a091                	j	80003bd0 <writei+0x8e>
    80003b8e:	02099d93          	slli	s11,s3,0x20
    80003b92:	020ddd93          	srli	s11,s11,0x20
    80003b96:	05848513          	addi	a0,s1,88
    80003b9a:	86ee                	mv	a3,s11
    80003b9c:	8656                	mv	a2,s5
    80003b9e:	85e2                	mv	a1,s8
    80003ba0:	953a                	add	a0,a0,a4
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	974080e7          	jalr	-1676(ra) # 80002516 <either_copyin>
    80003baa:	07950263          	beq	a0,s9,80003c0e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bae:	8526                	mv	a0,s1
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	790080e7          	jalr	1936(ra) # 80004340 <log_write>
    brelse(bp);
    80003bb8:	8526                	mv	a0,s1
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	50a080e7          	jalr	1290(ra) # 800030c4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc2:	01498a3b          	addw	s4,s3,s4
    80003bc6:	0129893b          	addw	s2,s3,s2
    80003bca:	9aee                	add	s5,s5,s11
    80003bcc:	057a7663          	bgeu	s4,s7,80003c18 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bd0:	000b2483          	lw	s1,0(s6)
    80003bd4:	00a9559b          	srliw	a1,s2,0xa
    80003bd8:	855a                	mv	a0,s6
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	7ae080e7          	jalr	1966(ra) # 80003388 <bmap>
    80003be2:	0005059b          	sext.w	a1,a0
    80003be6:	8526                	mv	a0,s1
    80003be8:	fffff097          	auipc	ra,0xfffff
    80003bec:	3ac080e7          	jalr	940(ra) # 80002f94 <bread>
    80003bf0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf2:	3ff97713          	andi	a4,s2,1023
    80003bf6:	40ed07bb          	subw	a5,s10,a4
    80003bfa:	414b86bb          	subw	a3,s7,s4
    80003bfe:	89be                	mv	s3,a5
    80003c00:	2781                	sext.w	a5,a5
    80003c02:	0006861b          	sext.w	a2,a3
    80003c06:	f8f674e3          	bgeu	a2,a5,80003b8e <writei+0x4c>
    80003c0a:	89b6                	mv	s3,a3
    80003c0c:	b749                	j	80003b8e <writei+0x4c>
      brelse(bp);
    80003c0e:	8526                	mv	a0,s1
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	4b4080e7          	jalr	1204(ra) # 800030c4 <brelse>
  }

  if(off > ip->size)
    80003c18:	04cb2783          	lw	a5,76(s6)
    80003c1c:	0127f463          	bgeu	a5,s2,80003c24 <writei+0xe2>
    ip->size = off;
    80003c20:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c24:	855a                	mv	a0,s6
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	aa6080e7          	jalr	-1370(ra) # 800036cc <iupdate>

  return tot;
    80003c2e:	000a051b          	sext.w	a0,s4
}
    80003c32:	70a6                	ld	ra,104(sp)
    80003c34:	7406                	ld	s0,96(sp)
    80003c36:	64e6                	ld	s1,88(sp)
    80003c38:	6946                	ld	s2,80(sp)
    80003c3a:	69a6                	ld	s3,72(sp)
    80003c3c:	6a06                	ld	s4,64(sp)
    80003c3e:	7ae2                	ld	s5,56(sp)
    80003c40:	7b42                	ld	s6,48(sp)
    80003c42:	7ba2                	ld	s7,40(sp)
    80003c44:	7c02                	ld	s8,32(sp)
    80003c46:	6ce2                	ld	s9,24(sp)
    80003c48:	6d42                	ld	s10,16(sp)
    80003c4a:	6da2                	ld	s11,8(sp)
    80003c4c:	6165                	addi	sp,sp,112
    80003c4e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c50:	8a5e                	mv	s4,s7
    80003c52:	bfc9                	j	80003c24 <writei+0xe2>
    return -1;
    80003c54:	557d                	li	a0,-1
}
    80003c56:	8082                	ret
    return -1;
    80003c58:	557d                	li	a0,-1
    80003c5a:	bfe1                	j	80003c32 <writei+0xf0>
    return -1;
    80003c5c:	557d                	li	a0,-1
    80003c5e:	bfd1                	j	80003c32 <writei+0xf0>

0000000080003c60 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c60:	1141                	addi	sp,sp,-16
    80003c62:	e406                	sd	ra,8(sp)
    80003c64:	e022                	sd	s0,0(sp)
    80003c66:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c68:	4639                	li	a2,14
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	14e080e7          	jalr	334(ra) # 80000db8 <strncmp>
}
    80003c72:	60a2                	ld	ra,8(sp)
    80003c74:	6402                	ld	s0,0(sp)
    80003c76:	0141                	addi	sp,sp,16
    80003c78:	8082                	ret

0000000080003c7a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c7a:	7139                	addi	sp,sp,-64
    80003c7c:	fc06                	sd	ra,56(sp)
    80003c7e:	f822                	sd	s0,48(sp)
    80003c80:	f426                	sd	s1,40(sp)
    80003c82:	f04a                	sd	s2,32(sp)
    80003c84:	ec4e                	sd	s3,24(sp)
    80003c86:	e852                	sd	s4,16(sp)
    80003c88:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c8a:	04451703          	lh	a4,68(a0)
    80003c8e:	4785                	li	a5,1
    80003c90:	00f71a63          	bne	a4,a5,80003ca4 <dirlookup+0x2a>
    80003c94:	892a                	mv	s2,a0
    80003c96:	89ae                	mv	s3,a1
    80003c98:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9a:	457c                	lw	a5,76(a0)
    80003c9c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c9e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca0:	e79d                	bnez	a5,80003cce <dirlookup+0x54>
    80003ca2:	a8a5                	j	80003d1a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ca4:	00005517          	auipc	a0,0x5
    80003ca8:	99c50513          	addi	a0,a0,-1636 # 80008640 <syscalls+0x1b0>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	892080e7          	jalr	-1902(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cb4:	00005517          	auipc	a0,0x5
    80003cb8:	9a450513          	addi	a0,a0,-1628 # 80008658 <syscalls+0x1c8>
    80003cbc:	ffffd097          	auipc	ra,0xffffd
    80003cc0:	882080e7          	jalr	-1918(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc4:	24c1                	addiw	s1,s1,16
    80003cc6:	04c92783          	lw	a5,76(s2)
    80003cca:	04f4f763          	bgeu	s1,a5,80003d18 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cce:	4741                	li	a4,16
    80003cd0:	86a6                	mv	a3,s1
    80003cd2:	fc040613          	addi	a2,s0,-64
    80003cd6:	4581                	li	a1,0
    80003cd8:	854a                	mv	a0,s2
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	d70080e7          	jalr	-656(ra) # 80003a4a <readi>
    80003ce2:	47c1                	li	a5,16
    80003ce4:	fcf518e3          	bne	a0,a5,80003cb4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ce8:	fc045783          	lhu	a5,-64(s0)
    80003cec:	dfe1                	beqz	a5,80003cc4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cee:	fc240593          	addi	a1,s0,-62
    80003cf2:	854e                	mv	a0,s3
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	f6c080e7          	jalr	-148(ra) # 80003c60 <namecmp>
    80003cfc:	f561                	bnez	a0,80003cc4 <dirlookup+0x4a>
      if(poff)
    80003cfe:	000a0463          	beqz	s4,80003d06 <dirlookup+0x8c>
        *poff = off;
    80003d02:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d06:	fc045583          	lhu	a1,-64(s0)
    80003d0a:	00092503          	lw	a0,0(s2)
    80003d0e:	fffff097          	auipc	ra,0xfffff
    80003d12:	754080e7          	jalr	1876(ra) # 80003462 <iget>
    80003d16:	a011                	j	80003d1a <dirlookup+0xa0>
  return 0;
    80003d18:	4501                	li	a0,0
}
    80003d1a:	70e2                	ld	ra,56(sp)
    80003d1c:	7442                	ld	s0,48(sp)
    80003d1e:	74a2                	ld	s1,40(sp)
    80003d20:	7902                	ld	s2,32(sp)
    80003d22:	69e2                	ld	s3,24(sp)
    80003d24:	6a42                	ld	s4,16(sp)
    80003d26:	6121                	addi	sp,sp,64
    80003d28:	8082                	ret

0000000080003d2a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d2a:	711d                	addi	sp,sp,-96
    80003d2c:	ec86                	sd	ra,88(sp)
    80003d2e:	e8a2                	sd	s0,80(sp)
    80003d30:	e4a6                	sd	s1,72(sp)
    80003d32:	e0ca                	sd	s2,64(sp)
    80003d34:	fc4e                	sd	s3,56(sp)
    80003d36:	f852                	sd	s4,48(sp)
    80003d38:	f456                	sd	s5,40(sp)
    80003d3a:	f05a                	sd	s6,32(sp)
    80003d3c:	ec5e                	sd	s7,24(sp)
    80003d3e:	e862                	sd	s8,16(sp)
    80003d40:	e466                	sd	s9,8(sp)
    80003d42:	1080                	addi	s0,sp,96
    80003d44:	84aa                	mv	s1,a0
    80003d46:	8b2e                	mv	s6,a1
    80003d48:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d4a:	00054703          	lbu	a4,0(a0)
    80003d4e:	02f00793          	li	a5,47
    80003d52:	02f70363          	beq	a4,a5,80003d78 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d56:	ffffe097          	auipc	ra,0xffffe
    80003d5a:	c5a080e7          	jalr	-934(ra) # 800019b0 <myproc>
    80003d5e:	15853503          	ld	a0,344(a0)
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	9f6080e7          	jalr	-1546(ra) # 80003758 <idup>
    80003d6a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d6c:	02f00913          	li	s2,47
  len = path - s;
    80003d70:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d72:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d74:	4c05                	li	s8,1
    80003d76:	a865                	j	80003e2e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d78:	4585                	li	a1,1
    80003d7a:	4505                	li	a0,1
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	6e6080e7          	jalr	1766(ra) # 80003462 <iget>
    80003d84:	89aa                	mv	s3,a0
    80003d86:	b7dd                	j	80003d6c <namex+0x42>
      iunlockput(ip);
    80003d88:	854e                	mv	a0,s3
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	c6e080e7          	jalr	-914(ra) # 800039f8 <iunlockput>
      return 0;
    80003d92:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d94:	854e                	mv	a0,s3
    80003d96:	60e6                	ld	ra,88(sp)
    80003d98:	6446                	ld	s0,80(sp)
    80003d9a:	64a6                	ld	s1,72(sp)
    80003d9c:	6906                	ld	s2,64(sp)
    80003d9e:	79e2                	ld	s3,56(sp)
    80003da0:	7a42                	ld	s4,48(sp)
    80003da2:	7aa2                	ld	s5,40(sp)
    80003da4:	7b02                	ld	s6,32(sp)
    80003da6:	6be2                	ld	s7,24(sp)
    80003da8:	6c42                	ld	s8,16(sp)
    80003daa:	6ca2                	ld	s9,8(sp)
    80003dac:	6125                	addi	sp,sp,96
    80003dae:	8082                	ret
      iunlock(ip);
    80003db0:	854e                	mv	a0,s3
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	aa6080e7          	jalr	-1370(ra) # 80003858 <iunlock>
      return ip;
    80003dba:	bfe9                	j	80003d94 <namex+0x6a>
      iunlockput(ip);
    80003dbc:	854e                	mv	a0,s3
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	c3a080e7          	jalr	-966(ra) # 800039f8 <iunlockput>
      return 0;
    80003dc6:	89d2                	mv	s3,s4
    80003dc8:	b7f1                	j	80003d94 <namex+0x6a>
  len = path - s;
    80003dca:	40b48633          	sub	a2,s1,a1
    80003dce:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dd2:	094cd463          	bge	s9,s4,80003e5a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dd6:	4639                	li	a2,14
    80003dd8:	8556                	mv	a0,s5
    80003dda:	ffffd097          	auipc	ra,0xffffd
    80003dde:	f66080e7          	jalr	-154(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003de2:	0004c783          	lbu	a5,0(s1)
    80003de6:	01279763          	bne	a5,s2,80003df4 <namex+0xca>
    path++;
    80003dea:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dec:	0004c783          	lbu	a5,0(s1)
    80003df0:	ff278de3          	beq	a5,s2,80003dea <namex+0xc0>
    ilock(ip);
    80003df4:	854e                	mv	a0,s3
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	9a0080e7          	jalr	-1632(ra) # 80003796 <ilock>
    if(ip->type != T_DIR){
    80003dfe:	04499783          	lh	a5,68(s3)
    80003e02:	f98793e3          	bne	a5,s8,80003d88 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e06:	000b0563          	beqz	s6,80003e10 <namex+0xe6>
    80003e0a:	0004c783          	lbu	a5,0(s1)
    80003e0e:	d3cd                	beqz	a5,80003db0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e10:	865e                	mv	a2,s7
    80003e12:	85d6                	mv	a1,s5
    80003e14:	854e                	mv	a0,s3
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	e64080e7          	jalr	-412(ra) # 80003c7a <dirlookup>
    80003e1e:	8a2a                	mv	s4,a0
    80003e20:	dd51                	beqz	a0,80003dbc <namex+0x92>
    iunlockput(ip);
    80003e22:	854e                	mv	a0,s3
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	bd4080e7          	jalr	-1068(ra) # 800039f8 <iunlockput>
    ip = next;
    80003e2c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e2e:	0004c783          	lbu	a5,0(s1)
    80003e32:	05279763          	bne	a5,s2,80003e80 <namex+0x156>
    path++;
    80003e36:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e38:	0004c783          	lbu	a5,0(s1)
    80003e3c:	ff278de3          	beq	a5,s2,80003e36 <namex+0x10c>
  if(*path == 0)
    80003e40:	c79d                	beqz	a5,80003e6e <namex+0x144>
    path++;
    80003e42:	85a6                	mv	a1,s1
  len = path - s;
    80003e44:	8a5e                	mv	s4,s7
    80003e46:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e48:	01278963          	beq	a5,s2,80003e5a <namex+0x130>
    80003e4c:	dfbd                	beqz	a5,80003dca <namex+0xa0>
    path++;
    80003e4e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e50:	0004c783          	lbu	a5,0(s1)
    80003e54:	ff279ce3          	bne	a5,s2,80003e4c <namex+0x122>
    80003e58:	bf8d                	j	80003dca <namex+0xa0>
    memmove(name, s, len);
    80003e5a:	2601                	sext.w	a2,a2
    80003e5c:	8556                	mv	a0,s5
    80003e5e:	ffffd097          	auipc	ra,0xffffd
    80003e62:	ee2080e7          	jalr	-286(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e66:	9a56                	add	s4,s4,s5
    80003e68:	000a0023          	sb	zero,0(s4)
    80003e6c:	bf9d                	j	80003de2 <namex+0xb8>
  if(nameiparent){
    80003e6e:	f20b03e3          	beqz	s6,80003d94 <namex+0x6a>
    iput(ip);
    80003e72:	854e                	mv	a0,s3
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	adc080e7          	jalr	-1316(ra) # 80003950 <iput>
    return 0;
    80003e7c:	4981                	li	s3,0
    80003e7e:	bf19                	j	80003d94 <namex+0x6a>
  if(*path == 0)
    80003e80:	d7fd                	beqz	a5,80003e6e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e82:	0004c783          	lbu	a5,0(s1)
    80003e86:	85a6                	mv	a1,s1
    80003e88:	b7d1                	j	80003e4c <namex+0x122>

0000000080003e8a <dirlink>:
{
    80003e8a:	7139                	addi	sp,sp,-64
    80003e8c:	fc06                	sd	ra,56(sp)
    80003e8e:	f822                	sd	s0,48(sp)
    80003e90:	f426                	sd	s1,40(sp)
    80003e92:	f04a                	sd	s2,32(sp)
    80003e94:	ec4e                	sd	s3,24(sp)
    80003e96:	e852                	sd	s4,16(sp)
    80003e98:	0080                	addi	s0,sp,64
    80003e9a:	892a                	mv	s2,a0
    80003e9c:	8a2e                	mv	s4,a1
    80003e9e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ea0:	4601                	li	a2,0
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	dd8080e7          	jalr	-552(ra) # 80003c7a <dirlookup>
    80003eaa:	e93d                	bnez	a0,80003f20 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eac:	04c92483          	lw	s1,76(s2)
    80003eb0:	c49d                	beqz	s1,80003ede <dirlink+0x54>
    80003eb2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb4:	4741                	li	a4,16
    80003eb6:	86a6                	mv	a3,s1
    80003eb8:	fc040613          	addi	a2,s0,-64
    80003ebc:	4581                	li	a1,0
    80003ebe:	854a                	mv	a0,s2
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	b8a080e7          	jalr	-1142(ra) # 80003a4a <readi>
    80003ec8:	47c1                	li	a5,16
    80003eca:	06f51163          	bne	a0,a5,80003f2c <dirlink+0xa2>
    if(de.inum == 0)
    80003ece:	fc045783          	lhu	a5,-64(s0)
    80003ed2:	c791                	beqz	a5,80003ede <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed4:	24c1                	addiw	s1,s1,16
    80003ed6:	04c92783          	lw	a5,76(s2)
    80003eda:	fcf4ede3          	bltu	s1,a5,80003eb4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ede:	4639                	li	a2,14
    80003ee0:	85d2                	mv	a1,s4
    80003ee2:	fc240513          	addi	a0,s0,-62
    80003ee6:	ffffd097          	auipc	ra,0xffffd
    80003eea:	f0e080e7          	jalr	-242(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003eee:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef2:	4741                	li	a4,16
    80003ef4:	86a6                	mv	a3,s1
    80003ef6:	fc040613          	addi	a2,s0,-64
    80003efa:	4581                	li	a1,0
    80003efc:	854a                	mv	a0,s2
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	c44080e7          	jalr	-956(ra) # 80003b42 <writei>
    80003f06:	872a                	mv	a4,a0
    80003f08:	47c1                	li	a5,16
  return 0;
    80003f0a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f0c:	02f71863          	bne	a4,a5,80003f3c <dirlink+0xb2>
}
    80003f10:	70e2                	ld	ra,56(sp)
    80003f12:	7442                	ld	s0,48(sp)
    80003f14:	74a2                	ld	s1,40(sp)
    80003f16:	7902                	ld	s2,32(sp)
    80003f18:	69e2                	ld	s3,24(sp)
    80003f1a:	6a42                	ld	s4,16(sp)
    80003f1c:	6121                	addi	sp,sp,64
    80003f1e:	8082                	ret
    iput(ip);
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	a30080e7          	jalr	-1488(ra) # 80003950 <iput>
    return -1;
    80003f28:	557d                	li	a0,-1
    80003f2a:	b7dd                	j	80003f10 <dirlink+0x86>
      panic("dirlink read");
    80003f2c:	00004517          	auipc	a0,0x4
    80003f30:	73c50513          	addi	a0,a0,1852 # 80008668 <syscalls+0x1d8>
    80003f34:	ffffc097          	auipc	ra,0xffffc
    80003f38:	60a080e7          	jalr	1546(ra) # 8000053e <panic>
    panic("dirlink");
    80003f3c:	00005517          	auipc	a0,0x5
    80003f40:	83c50513          	addi	a0,a0,-1988 # 80008778 <syscalls+0x2e8>
    80003f44:	ffffc097          	auipc	ra,0xffffc
    80003f48:	5fa080e7          	jalr	1530(ra) # 8000053e <panic>

0000000080003f4c <namei>:

struct inode*
namei(char *path)
{
    80003f4c:	1101                	addi	sp,sp,-32
    80003f4e:	ec06                	sd	ra,24(sp)
    80003f50:	e822                	sd	s0,16(sp)
    80003f52:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f54:	fe040613          	addi	a2,s0,-32
    80003f58:	4581                	li	a1,0
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	dd0080e7          	jalr	-560(ra) # 80003d2a <namex>
}
    80003f62:	60e2                	ld	ra,24(sp)
    80003f64:	6442                	ld	s0,16(sp)
    80003f66:	6105                	addi	sp,sp,32
    80003f68:	8082                	ret

0000000080003f6a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f6a:	1141                	addi	sp,sp,-16
    80003f6c:	e406                	sd	ra,8(sp)
    80003f6e:	e022                	sd	s0,0(sp)
    80003f70:	0800                	addi	s0,sp,16
    80003f72:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f74:	4585                	li	a1,1
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	db4080e7          	jalr	-588(ra) # 80003d2a <namex>
}
    80003f7e:	60a2                	ld	ra,8(sp)
    80003f80:	6402                	ld	s0,0(sp)
    80003f82:	0141                	addi	sp,sp,16
    80003f84:	8082                	ret

0000000080003f86 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f86:	1101                	addi	sp,sp,-32
    80003f88:	ec06                	sd	ra,24(sp)
    80003f8a:	e822                	sd	s0,16(sp)
    80003f8c:	e426                	sd	s1,8(sp)
    80003f8e:	e04a                	sd	s2,0(sp)
    80003f90:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f92:	0001d917          	auipc	s2,0x1d
    80003f96:	4de90913          	addi	s2,s2,1246 # 80021470 <log>
    80003f9a:	01892583          	lw	a1,24(s2)
    80003f9e:	02892503          	lw	a0,40(s2)
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	ff2080e7          	jalr	-14(ra) # 80002f94 <bread>
    80003faa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fac:	02c92683          	lw	a3,44(s2)
    80003fb0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fb2:	02d05763          	blez	a3,80003fe0 <write_head+0x5a>
    80003fb6:	0001d797          	auipc	a5,0x1d
    80003fba:	4ea78793          	addi	a5,a5,1258 # 800214a0 <log+0x30>
    80003fbe:	05c50713          	addi	a4,a0,92
    80003fc2:	36fd                	addiw	a3,a3,-1
    80003fc4:	1682                	slli	a3,a3,0x20
    80003fc6:	9281                	srli	a3,a3,0x20
    80003fc8:	068a                	slli	a3,a3,0x2
    80003fca:	0001d617          	auipc	a2,0x1d
    80003fce:	4da60613          	addi	a2,a2,1242 # 800214a4 <log+0x34>
    80003fd2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fd4:	4390                	lw	a2,0(a5)
    80003fd6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fd8:	0791                	addi	a5,a5,4
    80003fda:	0711                	addi	a4,a4,4
    80003fdc:	fed79ce3          	bne	a5,a3,80003fd4 <write_head+0x4e>
  }
  bwrite(buf);
    80003fe0:	8526                	mv	a0,s1
    80003fe2:	fffff097          	auipc	ra,0xfffff
    80003fe6:	0a4080e7          	jalr	164(ra) # 80003086 <bwrite>
  brelse(buf);
    80003fea:	8526                	mv	a0,s1
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	0d8080e7          	jalr	216(ra) # 800030c4 <brelse>
}
    80003ff4:	60e2                	ld	ra,24(sp)
    80003ff6:	6442                	ld	s0,16(sp)
    80003ff8:	64a2                	ld	s1,8(sp)
    80003ffa:	6902                	ld	s2,0(sp)
    80003ffc:	6105                	addi	sp,sp,32
    80003ffe:	8082                	ret

0000000080004000 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004000:	0001d797          	auipc	a5,0x1d
    80004004:	49c7a783          	lw	a5,1180(a5) # 8002149c <log+0x2c>
    80004008:	0af05d63          	blez	a5,800040c2 <install_trans+0xc2>
{
    8000400c:	7139                	addi	sp,sp,-64
    8000400e:	fc06                	sd	ra,56(sp)
    80004010:	f822                	sd	s0,48(sp)
    80004012:	f426                	sd	s1,40(sp)
    80004014:	f04a                	sd	s2,32(sp)
    80004016:	ec4e                	sd	s3,24(sp)
    80004018:	e852                	sd	s4,16(sp)
    8000401a:	e456                	sd	s5,8(sp)
    8000401c:	e05a                	sd	s6,0(sp)
    8000401e:	0080                	addi	s0,sp,64
    80004020:	8b2a                	mv	s6,a0
    80004022:	0001da97          	auipc	s5,0x1d
    80004026:	47ea8a93          	addi	s5,s5,1150 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000402a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000402c:	0001d997          	auipc	s3,0x1d
    80004030:	44498993          	addi	s3,s3,1092 # 80021470 <log>
    80004034:	a035                	j	80004060 <install_trans+0x60>
      bunpin(dbuf);
    80004036:	8526                	mv	a0,s1
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	166080e7          	jalr	358(ra) # 8000319e <bunpin>
    brelse(lbuf);
    80004040:	854a                	mv	a0,s2
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	082080e7          	jalr	130(ra) # 800030c4 <brelse>
    brelse(dbuf);
    8000404a:	8526                	mv	a0,s1
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	078080e7          	jalr	120(ra) # 800030c4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004054:	2a05                	addiw	s4,s4,1
    80004056:	0a91                	addi	s5,s5,4
    80004058:	02c9a783          	lw	a5,44(s3)
    8000405c:	04fa5963          	bge	s4,a5,800040ae <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004060:	0189a583          	lw	a1,24(s3)
    80004064:	014585bb          	addw	a1,a1,s4
    80004068:	2585                	addiw	a1,a1,1
    8000406a:	0289a503          	lw	a0,40(s3)
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	f26080e7          	jalr	-218(ra) # 80002f94 <bread>
    80004076:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004078:	000aa583          	lw	a1,0(s5)
    8000407c:	0289a503          	lw	a0,40(s3)
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	f14080e7          	jalr	-236(ra) # 80002f94 <bread>
    80004088:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000408a:	40000613          	li	a2,1024
    8000408e:	05890593          	addi	a1,s2,88
    80004092:	05850513          	addi	a0,a0,88
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	caa080e7          	jalr	-854(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000409e:	8526                	mv	a0,s1
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	fe6080e7          	jalr	-26(ra) # 80003086 <bwrite>
    if(recovering == 0)
    800040a8:	f80b1ce3          	bnez	s6,80004040 <install_trans+0x40>
    800040ac:	b769                	j	80004036 <install_trans+0x36>
}
    800040ae:	70e2                	ld	ra,56(sp)
    800040b0:	7442                	ld	s0,48(sp)
    800040b2:	74a2                	ld	s1,40(sp)
    800040b4:	7902                	ld	s2,32(sp)
    800040b6:	69e2                	ld	s3,24(sp)
    800040b8:	6a42                	ld	s4,16(sp)
    800040ba:	6aa2                	ld	s5,8(sp)
    800040bc:	6b02                	ld	s6,0(sp)
    800040be:	6121                	addi	sp,sp,64
    800040c0:	8082                	ret
    800040c2:	8082                	ret

00000000800040c4 <initlog>:
{
    800040c4:	7179                	addi	sp,sp,-48
    800040c6:	f406                	sd	ra,40(sp)
    800040c8:	f022                	sd	s0,32(sp)
    800040ca:	ec26                	sd	s1,24(sp)
    800040cc:	e84a                	sd	s2,16(sp)
    800040ce:	e44e                	sd	s3,8(sp)
    800040d0:	1800                	addi	s0,sp,48
    800040d2:	892a                	mv	s2,a0
    800040d4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040d6:	0001d497          	auipc	s1,0x1d
    800040da:	39a48493          	addi	s1,s1,922 # 80021470 <log>
    800040de:	00004597          	auipc	a1,0x4
    800040e2:	59a58593          	addi	a1,a1,1434 # 80008678 <syscalls+0x1e8>
    800040e6:	8526                	mv	a0,s1
    800040e8:	ffffd097          	auipc	ra,0xffffd
    800040ec:	a6c080e7          	jalr	-1428(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800040f0:	0149a583          	lw	a1,20(s3)
    800040f4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040f6:	0109a783          	lw	a5,16(s3)
    800040fa:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040fc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004100:	854a                	mv	a0,s2
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	e92080e7          	jalr	-366(ra) # 80002f94 <bread>
  log.lh.n = lh->n;
    8000410a:	4d3c                	lw	a5,88(a0)
    8000410c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000410e:	02f05563          	blez	a5,80004138 <initlog+0x74>
    80004112:	05c50713          	addi	a4,a0,92
    80004116:	0001d697          	auipc	a3,0x1d
    8000411a:	38a68693          	addi	a3,a3,906 # 800214a0 <log+0x30>
    8000411e:	37fd                	addiw	a5,a5,-1
    80004120:	1782                	slli	a5,a5,0x20
    80004122:	9381                	srli	a5,a5,0x20
    80004124:	078a                	slli	a5,a5,0x2
    80004126:	06050613          	addi	a2,a0,96
    8000412a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000412c:	4310                	lw	a2,0(a4)
    8000412e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004130:	0711                	addi	a4,a4,4
    80004132:	0691                	addi	a3,a3,4
    80004134:	fef71ce3          	bne	a4,a5,8000412c <initlog+0x68>
  brelse(buf);
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	f8c080e7          	jalr	-116(ra) # 800030c4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004140:	4505                	li	a0,1
    80004142:	00000097          	auipc	ra,0x0
    80004146:	ebe080e7          	jalr	-322(ra) # 80004000 <install_trans>
  log.lh.n = 0;
    8000414a:	0001d797          	auipc	a5,0x1d
    8000414e:	3407a923          	sw	zero,850(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    80004152:	00000097          	auipc	ra,0x0
    80004156:	e34080e7          	jalr	-460(ra) # 80003f86 <write_head>
}
    8000415a:	70a2                	ld	ra,40(sp)
    8000415c:	7402                	ld	s0,32(sp)
    8000415e:	64e2                	ld	s1,24(sp)
    80004160:	6942                	ld	s2,16(sp)
    80004162:	69a2                	ld	s3,8(sp)
    80004164:	6145                	addi	sp,sp,48
    80004166:	8082                	ret

0000000080004168 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004168:	1101                	addi	sp,sp,-32
    8000416a:	ec06                	sd	ra,24(sp)
    8000416c:	e822                	sd	s0,16(sp)
    8000416e:	e426                	sd	s1,8(sp)
    80004170:	e04a                	sd	s2,0(sp)
    80004172:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004174:	0001d517          	auipc	a0,0x1d
    80004178:	2fc50513          	addi	a0,a0,764 # 80021470 <log>
    8000417c:	ffffd097          	auipc	ra,0xffffd
    80004180:	a68080e7          	jalr	-1432(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004184:	0001d497          	auipc	s1,0x1d
    80004188:	2ec48493          	addi	s1,s1,748 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000418c:	4979                	li	s2,30
    8000418e:	a039                	j	8000419c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004190:	85a6                	mv	a1,s1
    80004192:	8526                	mv	a0,s1
    80004194:	ffffe097          	auipc	ra,0xffffe
    80004198:	f6c080e7          	jalr	-148(ra) # 80002100 <sleep>
    if(log.committing){
    8000419c:	50dc                	lw	a5,36(s1)
    8000419e:	fbed                	bnez	a5,80004190 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041a0:	509c                	lw	a5,32(s1)
    800041a2:	0017871b          	addiw	a4,a5,1
    800041a6:	0007069b          	sext.w	a3,a4
    800041aa:	0027179b          	slliw	a5,a4,0x2
    800041ae:	9fb9                	addw	a5,a5,a4
    800041b0:	0017979b          	slliw	a5,a5,0x1
    800041b4:	54d8                	lw	a4,44(s1)
    800041b6:	9fb9                	addw	a5,a5,a4
    800041b8:	00f95963          	bge	s2,a5,800041ca <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041bc:	85a6                	mv	a1,s1
    800041be:	8526                	mv	a0,s1
    800041c0:	ffffe097          	auipc	ra,0xffffe
    800041c4:	f40080e7          	jalr	-192(ra) # 80002100 <sleep>
    800041c8:	bfd1                	j	8000419c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041ca:	0001d517          	auipc	a0,0x1d
    800041ce:	2a650513          	addi	a0,a0,678 # 80021470 <log>
    800041d2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	ac4080e7          	jalr	-1340(ra) # 80000c98 <release>
      break;
    }
  }
}
    800041dc:	60e2                	ld	ra,24(sp)
    800041de:	6442                	ld	s0,16(sp)
    800041e0:	64a2                	ld	s1,8(sp)
    800041e2:	6902                	ld	s2,0(sp)
    800041e4:	6105                	addi	sp,sp,32
    800041e6:	8082                	ret

00000000800041e8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041e8:	7139                	addi	sp,sp,-64
    800041ea:	fc06                	sd	ra,56(sp)
    800041ec:	f822                	sd	s0,48(sp)
    800041ee:	f426                	sd	s1,40(sp)
    800041f0:	f04a                	sd	s2,32(sp)
    800041f2:	ec4e                	sd	s3,24(sp)
    800041f4:	e852                	sd	s4,16(sp)
    800041f6:	e456                	sd	s5,8(sp)
    800041f8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041fa:	0001d497          	auipc	s1,0x1d
    800041fe:	27648493          	addi	s1,s1,630 # 80021470 <log>
    80004202:	8526                	mv	a0,s1
    80004204:	ffffd097          	auipc	ra,0xffffd
    80004208:	9e0080e7          	jalr	-1568(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000420c:	509c                	lw	a5,32(s1)
    8000420e:	37fd                	addiw	a5,a5,-1
    80004210:	0007891b          	sext.w	s2,a5
    80004214:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004216:	50dc                	lw	a5,36(s1)
    80004218:	efb9                	bnez	a5,80004276 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000421a:	06091663          	bnez	s2,80004286 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000421e:	0001d497          	auipc	s1,0x1d
    80004222:	25248493          	addi	s1,s1,594 # 80021470 <log>
    80004226:	4785                	li	a5,1
    80004228:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004234:	54dc                	lw	a5,44(s1)
    80004236:	06f04763          	bgtz	a5,800042a4 <end_op+0xbc>
    acquire(&log.lock);
    8000423a:	0001d497          	auipc	s1,0x1d
    8000423e:	23648493          	addi	s1,s1,566 # 80021470 <log>
    80004242:	8526                	mv	a0,s1
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	9a0080e7          	jalr	-1632(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000424c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004250:	8526                	mv	a0,s1
    80004252:	ffffe097          	auipc	ra,0xffffe
    80004256:	03a080e7          	jalr	58(ra) # 8000228c <wakeup>
    release(&log.lock);
    8000425a:	8526                	mv	a0,s1
    8000425c:	ffffd097          	auipc	ra,0xffffd
    80004260:	a3c080e7          	jalr	-1476(ra) # 80000c98 <release>
}
    80004264:	70e2                	ld	ra,56(sp)
    80004266:	7442                	ld	s0,48(sp)
    80004268:	74a2                	ld	s1,40(sp)
    8000426a:	7902                	ld	s2,32(sp)
    8000426c:	69e2                	ld	s3,24(sp)
    8000426e:	6a42                	ld	s4,16(sp)
    80004270:	6aa2                	ld	s5,8(sp)
    80004272:	6121                	addi	sp,sp,64
    80004274:	8082                	ret
    panic("log.committing");
    80004276:	00004517          	auipc	a0,0x4
    8000427a:	40a50513          	addi	a0,a0,1034 # 80008680 <syscalls+0x1f0>
    8000427e:	ffffc097          	auipc	ra,0xffffc
    80004282:	2c0080e7          	jalr	704(ra) # 8000053e <panic>
    wakeup(&log);
    80004286:	0001d497          	auipc	s1,0x1d
    8000428a:	1ea48493          	addi	s1,s1,490 # 80021470 <log>
    8000428e:	8526                	mv	a0,s1
    80004290:	ffffe097          	auipc	ra,0xffffe
    80004294:	ffc080e7          	jalr	-4(ra) # 8000228c <wakeup>
  release(&log.lock);
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	9fe080e7          	jalr	-1538(ra) # 80000c98 <release>
  if(do_commit){
    800042a2:	b7c9                	j	80004264 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042a4:	0001da97          	auipc	s5,0x1d
    800042a8:	1fca8a93          	addi	s5,s5,508 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042ac:	0001da17          	auipc	s4,0x1d
    800042b0:	1c4a0a13          	addi	s4,s4,452 # 80021470 <log>
    800042b4:	018a2583          	lw	a1,24(s4)
    800042b8:	012585bb          	addw	a1,a1,s2
    800042bc:	2585                	addiw	a1,a1,1
    800042be:	028a2503          	lw	a0,40(s4)
    800042c2:	fffff097          	auipc	ra,0xfffff
    800042c6:	cd2080e7          	jalr	-814(ra) # 80002f94 <bread>
    800042ca:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042cc:	000aa583          	lw	a1,0(s5)
    800042d0:	028a2503          	lw	a0,40(s4)
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	cc0080e7          	jalr	-832(ra) # 80002f94 <bread>
    800042dc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042de:	40000613          	li	a2,1024
    800042e2:	05850593          	addi	a1,a0,88
    800042e6:	05848513          	addi	a0,s1,88
    800042ea:	ffffd097          	auipc	ra,0xffffd
    800042ee:	a56080e7          	jalr	-1450(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800042f2:	8526                	mv	a0,s1
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	d92080e7          	jalr	-622(ra) # 80003086 <bwrite>
    brelse(from);
    800042fc:	854e                	mv	a0,s3
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	dc6080e7          	jalr	-570(ra) # 800030c4 <brelse>
    brelse(to);
    80004306:	8526                	mv	a0,s1
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	dbc080e7          	jalr	-580(ra) # 800030c4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004310:	2905                	addiw	s2,s2,1
    80004312:	0a91                	addi	s5,s5,4
    80004314:	02ca2783          	lw	a5,44(s4)
    80004318:	f8f94ee3          	blt	s2,a5,800042b4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	c6a080e7          	jalr	-918(ra) # 80003f86 <write_head>
    install_trans(0); // Now install writes to home locations
    80004324:	4501                	li	a0,0
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	cda080e7          	jalr	-806(ra) # 80004000 <install_trans>
    log.lh.n = 0;
    8000432e:	0001d797          	auipc	a5,0x1d
    80004332:	1607a723          	sw	zero,366(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	c50080e7          	jalr	-944(ra) # 80003f86 <write_head>
    8000433e:	bdf5                	j	8000423a <end_op+0x52>

0000000080004340 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004340:	1101                	addi	sp,sp,-32
    80004342:	ec06                	sd	ra,24(sp)
    80004344:	e822                	sd	s0,16(sp)
    80004346:	e426                	sd	s1,8(sp)
    80004348:	e04a                	sd	s2,0(sp)
    8000434a:	1000                	addi	s0,sp,32
    8000434c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000434e:	0001d917          	auipc	s2,0x1d
    80004352:	12290913          	addi	s2,s2,290 # 80021470 <log>
    80004356:	854a                	mv	a0,s2
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	88c080e7          	jalr	-1908(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004360:	02c92603          	lw	a2,44(s2)
    80004364:	47f5                	li	a5,29
    80004366:	06c7c563          	blt	a5,a2,800043d0 <log_write+0x90>
    8000436a:	0001d797          	auipc	a5,0x1d
    8000436e:	1227a783          	lw	a5,290(a5) # 8002148c <log+0x1c>
    80004372:	37fd                	addiw	a5,a5,-1
    80004374:	04f65e63          	bge	a2,a5,800043d0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004378:	0001d797          	auipc	a5,0x1d
    8000437c:	1187a783          	lw	a5,280(a5) # 80021490 <log+0x20>
    80004380:	06f05063          	blez	a5,800043e0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004384:	4781                	li	a5,0
    80004386:	06c05563          	blez	a2,800043f0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000438a:	44cc                	lw	a1,12(s1)
    8000438c:	0001d717          	auipc	a4,0x1d
    80004390:	11470713          	addi	a4,a4,276 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004394:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004396:	4314                	lw	a3,0(a4)
    80004398:	04b68c63          	beq	a3,a1,800043f0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000439c:	2785                	addiw	a5,a5,1
    8000439e:	0711                	addi	a4,a4,4
    800043a0:	fef61be3          	bne	a2,a5,80004396 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043a4:	0621                	addi	a2,a2,8
    800043a6:	060a                	slli	a2,a2,0x2
    800043a8:	0001d797          	auipc	a5,0x1d
    800043ac:	0c878793          	addi	a5,a5,200 # 80021470 <log>
    800043b0:	963e                	add	a2,a2,a5
    800043b2:	44dc                	lw	a5,12(s1)
    800043b4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043b6:	8526                	mv	a0,s1
    800043b8:	fffff097          	auipc	ra,0xfffff
    800043bc:	daa080e7          	jalr	-598(ra) # 80003162 <bpin>
    log.lh.n++;
    800043c0:	0001d717          	auipc	a4,0x1d
    800043c4:	0b070713          	addi	a4,a4,176 # 80021470 <log>
    800043c8:	575c                	lw	a5,44(a4)
    800043ca:	2785                	addiw	a5,a5,1
    800043cc:	d75c                	sw	a5,44(a4)
    800043ce:	a835                	j	8000440a <log_write+0xca>
    panic("too big a transaction");
    800043d0:	00004517          	auipc	a0,0x4
    800043d4:	2c050513          	addi	a0,a0,704 # 80008690 <syscalls+0x200>
    800043d8:	ffffc097          	auipc	ra,0xffffc
    800043dc:	166080e7          	jalr	358(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043e0:	00004517          	auipc	a0,0x4
    800043e4:	2c850513          	addi	a0,a0,712 # 800086a8 <syscalls+0x218>
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	156080e7          	jalr	342(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800043f0:	00878713          	addi	a4,a5,8
    800043f4:	00271693          	slli	a3,a4,0x2
    800043f8:	0001d717          	auipc	a4,0x1d
    800043fc:	07870713          	addi	a4,a4,120 # 80021470 <log>
    80004400:	9736                	add	a4,a4,a3
    80004402:	44d4                	lw	a3,12(s1)
    80004404:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004406:	faf608e3          	beq	a2,a5,800043b6 <log_write+0x76>
  }
  release(&log.lock);
    8000440a:	0001d517          	auipc	a0,0x1d
    8000440e:	06650513          	addi	a0,a0,102 # 80021470 <log>
    80004412:	ffffd097          	auipc	ra,0xffffd
    80004416:	886080e7          	jalr	-1914(ra) # 80000c98 <release>
}
    8000441a:	60e2                	ld	ra,24(sp)
    8000441c:	6442                	ld	s0,16(sp)
    8000441e:	64a2                	ld	s1,8(sp)
    80004420:	6902                	ld	s2,0(sp)
    80004422:	6105                	addi	sp,sp,32
    80004424:	8082                	ret

0000000080004426 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004426:	1101                	addi	sp,sp,-32
    80004428:	ec06                	sd	ra,24(sp)
    8000442a:	e822                	sd	s0,16(sp)
    8000442c:	e426                	sd	s1,8(sp)
    8000442e:	e04a                	sd	s2,0(sp)
    80004430:	1000                	addi	s0,sp,32
    80004432:	84aa                	mv	s1,a0
    80004434:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004436:	00004597          	auipc	a1,0x4
    8000443a:	29258593          	addi	a1,a1,658 # 800086c8 <syscalls+0x238>
    8000443e:	0521                	addi	a0,a0,8
    80004440:	ffffc097          	auipc	ra,0xffffc
    80004444:	714080e7          	jalr	1812(ra) # 80000b54 <initlock>
  lk->name = name;
    80004448:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000444c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004450:	0204a423          	sw	zero,40(s1)
}
    80004454:	60e2                	ld	ra,24(sp)
    80004456:	6442                	ld	s0,16(sp)
    80004458:	64a2                	ld	s1,8(sp)
    8000445a:	6902                	ld	s2,0(sp)
    8000445c:	6105                	addi	sp,sp,32
    8000445e:	8082                	ret

0000000080004460 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004460:	1101                	addi	sp,sp,-32
    80004462:	ec06                	sd	ra,24(sp)
    80004464:	e822                	sd	s0,16(sp)
    80004466:	e426                	sd	s1,8(sp)
    80004468:	e04a                	sd	s2,0(sp)
    8000446a:	1000                	addi	s0,sp,32
    8000446c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000446e:	00850913          	addi	s2,a0,8
    80004472:	854a                	mv	a0,s2
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	770080e7          	jalr	1904(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000447c:	409c                	lw	a5,0(s1)
    8000447e:	cb89                	beqz	a5,80004490 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004480:	85ca                	mv	a1,s2
    80004482:	8526                	mv	a0,s1
    80004484:	ffffe097          	auipc	ra,0xffffe
    80004488:	c7c080e7          	jalr	-900(ra) # 80002100 <sleep>
  while (lk->locked) {
    8000448c:	409c                	lw	a5,0(s1)
    8000448e:	fbed                	bnez	a5,80004480 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004490:	4785                	li	a5,1
    80004492:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004494:	ffffd097          	auipc	ra,0xffffd
    80004498:	51c080e7          	jalr	1308(ra) # 800019b0 <myproc>
    8000449c:	591c                	lw	a5,48(a0)
    8000449e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044a0:	854a                	mv	a0,s2
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	7f6080e7          	jalr	2038(ra) # 80000c98 <release>
}
    800044aa:	60e2                	ld	ra,24(sp)
    800044ac:	6442                	ld	s0,16(sp)
    800044ae:	64a2                	ld	s1,8(sp)
    800044b0:	6902                	ld	s2,0(sp)
    800044b2:	6105                	addi	sp,sp,32
    800044b4:	8082                	ret

00000000800044b6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044b6:	1101                	addi	sp,sp,-32
    800044b8:	ec06                	sd	ra,24(sp)
    800044ba:	e822                	sd	s0,16(sp)
    800044bc:	e426                	sd	s1,8(sp)
    800044be:	e04a                	sd	s2,0(sp)
    800044c0:	1000                	addi	s0,sp,32
    800044c2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044c4:	00850913          	addi	s2,a0,8
    800044c8:	854a                	mv	a0,s2
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	71a080e7          	jalr	1818(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800044d2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044d6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044da:	8526                	mv	a0,s1
    800044dc:	ffffe097          	auipc	ra,0xffffe
    800044e0:	db0080e7          	jalr	-592(ra) # 8000228c <wakeup>
  release(&lk->lk);
    800044e4:	854a                	mv	a0,s2
    800044e6:	ffffc097          	auipc	ra,0xffffc
    800044ea:	7b2080e7          	jalr	1970(ra) # 80000c98 <release>
}
    800044ee:	60e2                	ld	ra,24(sp)
    800044f0:	6442                	ld	s0,16(sp)
    800044f2:	64a2                	ld	s1,8(sp)
    800044f4:	6902                	ld	s2,0(sp)
    800044f6:	6105                	addi	sp,sp,32
    800044f8:	8082                	ret

00000000800044fa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044fa:	7179                	addi	sp,sp,-48
    800044fc:	f406                	sd	ra,40(sp)
    800044fe:	f022                	sd	s0,32(sp)
    80004500:	ec26                	sd	s1,24(sp)
    80004502:	e84a                	sd	s2,16(sp)
    80004504:	e44e                	sd	s3,8(sp)
    80004506:	1800                	addi	s0,sp,48
    80004508:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000450a:	00850913          	addi	s2,a0,8
    8000450e:	854a                	mv	a0,s2
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	6d4080e7          	jalr	1748(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004518:	409c                	lw	a5,0(s1)
    8000451a:	ef99                	bnez	a5,80004538 <holdingsleep+0x3e>
    8000451c:	4481                	li	s1,0
  release(&lk->lk);
    8000451e:	854a                	mv	a0,s2
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	778080e7          	jalr	1912(ra) # 80000c98 <release>
  return r;
}
    80004528:	8526                	mv	a0,s1
    8000452a:	70a2                	ld	ra,40(sp)
    8000452c:	7402                	ld	s0,32(sp)
    8000452e:	64e2                	ld	s1,24(sp)
    80004530:	6942                	ld	s2,16(sp)
    80004532:	69a2                	ld	s3,8(sp)
    80004534:	6145                	addi	sp,sp,48
    80004536:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004538:	0284a983          	lw	s3,40(s1)
    8000453c:	ffffd097          	auipc	ra,0xffffd
    80004540:	474080e7          	jalr	1140(ra) # 800019b0 <myproc>
    80004544:	5904                	lw	s1,48(a0)
    80004546:	413484b3          	sub	s1,s1,s3
    8000454a:	0014b493          	seqz	s1,s1
    8000454e:	bfc1                	j	8000451e <holdingsleep+0x24>

0000000080004550 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004550:	1141                	addi	sp,sp,-16
    80004552:	e406                	sd	ra,8(sp)
    80004554:	e022                	sd	s0,0(sp)
    80004556:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004558:	00004597          	auipc	a1,0x4
    8000455c:	18058593          	addi	a1,a1,384 # 800086d8 <syscalls+0x248>
    80004560:	0001d517          	auipc	a0,0x1d
    80004564:	05850513          	addi	a0,a0,88 # 800215b8 <ftable>
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	5ec080e7          	jalr	1516(ra) # 80000b54 <initlock>
}
    80004570:	60a2                	ld	ra,8(sp)
    80004572:	6402                	ld	s0,0(sp)
    80004574:	0141                	addi	sp,sp,16
    80004576:	8082                	ret

0000000080004578 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004578:	1101                	addi	sp,sp,-32
    8000457a:	ec06                	sd	ra,24(sp)
    8000457c:	e822                	sd	s0,16(sp)
    8000457e:	e426                	sd	s1,8(sp)
    80004580:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004582:	0001d517          	auipc	a0,0x1d
    80004586:	03650513          	addi	a0,a0,54 # 800215b8 <ftable>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	65a080e7          	jalr	1626(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004592:	0001d497          	auipc	s1,0x1d
    80004596:	03e48493          	addi	s1,s1,62 # 800215d0 <ftable+0x18>
    8000459a:	0001e717          	auipc	a4,0x1e
    8000459e:	fd670713          	addi	a4,a4,-42 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    800045a2:	40dc                	lw	a5,4(s1)
    800045a4:	cf99                	beqz	a5,800045c2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a6:	02848493          	addi	s1,s1,40
    800045aa:	fee49ce3          	bne	s1,a4,800045a2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045ae:	0001d517          	auipc	a0,0x1d
    800045b2:	00a50513          	addi	a0,a0,10 # 800215b8 <ftable>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	6e2080e7          	jalr	1762(ra) # 80000c98 <release>
  return 0;
    800045be:	4481                	li	s1,0
    800045c0:	a819                	j	800045d6 <filealloc+0x5e>
      f->ref = 1;
    800045c2:	4785                	li	a5,1
    800045c4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045c6:	0001d517          	auipc	a0,0x1d
    800045ca:	ff250513          	addi	a0,a0,-14 # 800215b8 <ftable>
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	6ca080e7          	jalr	1738(ra) # 80000c98 <release>
}
    800045d6:	8526                	mv	a0,s1
    800045d8:	60e2                	ld	ra,24(sp)
    800045da:	6442                	ld	s0,16(sp)
    800045dc:	64a2                	ld	s1,8(sp)
    800045de:	6105                	addi	sp,sp,32
    800045e0:	8082                	ret

00000000800045e2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045e2:	1101                	addi	sp,sp,-32
    800045e4:	ec06                	sd	ra,24(sp)
    800045e6:	e822                	sd	s0,16(sp)
    800045e8:	e426                	sd	s1,8(sp)
    800045ea:	1000                	addi	s0,sp,32
    800045ec:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045ee:	0001d517          	auipc	a0,0x1d
    800045f2:	fca50513          	addi	a0,a0,-54 # 800215b8 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	5ee080e7          	jalr	1518(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045fe:	40dc                	lw	a5,4(s1)
    80004600:	02f05263          	blez	a5,80004624 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004604:	2785                	addiw	a5,a5,1
    80004606:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004608:	0001d517          	auipc	a0,0x1d
    8000460c:	fb050513          	addi	a0,a0,-80 # 800215b8 <ftable>
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	688080e7          	jalr	1672(ra) # 80000c98 <release>
  return f;
}
    80004618:	8526                	mv	a0,s1
    8000461a:	60e2                	ld	ra,24(sp)
    8000461c:	6442                	ld	s0,16(sp)
    8000461e:	64a2                	ld	s1,8(sp)
    80004620:	6105                	addi	sp,sp,32
    80004622:	8082                	ret
    panic("filedup");
    80004624:	00004517          	auipc	a0,0x4
    80004628:	0bc50513          	addi	a0,a0,188 # 800086e0 <syscalls+0x250>
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	f12080e7          	jalr	-238(ra) # 8000053e <panic>

0000000080004634 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004634:	7139                	addi	sp,sp,-64
    80004636:	fc06                	sd	ra,56(sp)
    80004638:	f822                	sd	s0,48(sp)
    8000463a:	f426                	sd	s1,40(sp)
    8000463c:	f04a                	sd	s2,32(sp)
    8000463e:	ec4e                	sd	s3,24(sp)
    80004640:	e852                	sd	s4,16(sp)
    80004642:	e456                	sd	s5,8(sp)
    80004644:	0080                	addi	s0,sp,64
    80004646:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004648:	0001d517          	auipc	a0,0x1d
    8000464c:	f7050513          	addi	a0,a0,-144 # 800215b8 <ftable>
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	594080e7          	jalr	1428(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004658:	40dc                	lw	a5,4(s1)
    8000465a:	06f05163          	blez	a5,800046bc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000465e:	37fd                	addiw	a5,a5,-1
    80004660:	0007871b          	sext.w	a4,a5
    80004664:	c0dc                	sw	a5,4(s1)
    80004666:	06e04363          	bgtz	a4,800046cc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000466a:	0004a903          	lw	s2,0(s1)
    8000466e:	0094ca83          	lbu	s5,9(s1)
    80004672:	0104ba03          	ld	s4,16(s1)
    80004676:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000467a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000467e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004682:	0001d517          	auipc	a0,0x1d
    80004686:	f3650513          	addi	a0,a0,-202 # 800215b8 <ftable>
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	60e080e7          	jalr	1550(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004692:	4785                	li	a5,1
    80004694:	04f90d63          	beq	s2,a5,800046ee <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004698:	3979                	addiw	s2,s2,-2
    8000469a:	4785                	li	a5,1
    8000469c:	0527e063          	bltu	a5,s2,800046dc <fileclose+0xa8>
    begin_op();
    800046a0:	00000097          	auipc	ra,0x0
    800046a4:	ac8080e7          	jalr	-1336(ra) # 80004168 <begin_op>
    iput(ff.ip);
    800046a8:	854e                	mv	a0,s3
    800046aa:	fffff097          	auipc	ra,0xfffff
    800046ae:	2a6080e7          	jalr	678(ra) # 80003950 <iput>
    end_op();
    800046b2:	00000097          	auipc	ra,0x0
    800046b6:	b36080e7          	jalr	-1226(ra) # 800041e8 <end_op>
    800046ba:	a00d                	j	800046dc <fileclose+0xa8>
    panic("fileclose");
    800046bc:	00004517          	auipc	a0,0x4
    800046c0:	02c50513          	addi	a0,a0,44 # 800086e8 <syscalls+0x258>
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	e7a080e7          	jalr	-390(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046cc:	0001d517          	auipc	a0,0x1d
    800046d0:	eec50513          	addi	a0,a0,-276 # 800215b8 <ftable>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	5c4080e7          	jalr	1476(ra) # 80000c98 <release>
  }
}
    800046dc:	70e2                	ld	ra,56(sp)
    800046de:	7442                	ld	s0,48(sp)
    800046e0:	74a2                	ld	s1,40(sp)
    800046e2:	7902                	ld	s2,32(sp)
    800046e4:	69e2                	ld	s3,24(sp)
    800046e6:	6a42                	ld	s4,16(sp)
    800046e8:	6aa2                	ld	s5,8(sp)
    800046ea:	6121                	addi	sp,sp,64
    800046ec:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046ee:	85d6                	mv	a1,s5
    800046f0:	8552                	mv	a0,s4
    800046f2:	00000097          	auipc	ra,0x0
    800046f6:	34c080e7          	jalr	844(ra) # 80004a3e <pipeclose>
    800046fa:	b7cd                	j	800046dc <fileclose+0xa8>

00000000800046fc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046fc:	715d                	addi	sp,sp,-80
    800046fe:	e486                	sd	ra,72(sp)
    80004700:	e0a2                	sd	s0,64(sp)
    80004702:	fc26                	sd	s1,56(sp)
    80004704:	f84a                	sd	s2,48(sp)
    80004706:	f44e                	sd	s3,40(sp)
    80004708:	0880                	addi	s0,sp,80
    8000470a:	84aa                	mv	s1,a0
    8000470c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000470e:	ffffd097          	auipc	ra,0xffffd
    80004712:	2a2080e7          	jalr	674(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004716:	409c                	lw	a5,0(s1)
    80004718:	37f9                	addiw	a5,a5,-2
    8000471a:	4705                	li	a4,1
    8000471c:	04f76763          	bltu	a4,a5,8000476a <filestat+0x6e>
    80004720:	892a                	mv	s2,a0
    ilock(f->ip);
    80004722:	6c88                	ld	a0,24(s1)
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	072080e7          	jalr	114(ra) # 80003796 <ilock>
    stati(f->ip, &st);
    8000472c:	fb840593          	addi	a1,s0,-72
    80004730:	6c88                	ld	a0,24(s1)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	2ee080e7          	jalr	750(ra) # 80003a20 <stati>
    iunlock(f->ip);
    8000473a:	6c88                	ld	a0,24(s1)
    8000473c:	fffff097          	auipc	ra,0xfffff
    80004740:	11c080e7          	jalr	284(ra) # 80003858 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004744:	46e1                	li	a3,24
    80004746:	fb840613          	addi	a2,s0,-72
    8000474a:	85ce                	mv	a1,s3
    8000474c:	05893503          	ld	a0,88(s2)
    80004750:	ffffd097          	auipc	ra,0xffffd
    80004754:	f22080e7          	jalr	-222(ra) # 80001672 <copyout>
    80004758:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000475c:	60a6                	ld	ra,72(sp)
    8000475e:	6406                	ld	s0,64(sp)
    80004760:	74e2                	ld	s1,56(sp)
    80004762:	7942                	ld	s2,48(sp)
    80004764:	79a2                	ld	s3,40(sp)
    80004766:	6161                	addi	sp,sp,80
    80004768:	8082                	ret
  return -1;
    8000476a:	557d                	li	a0,-1
    8000476c:	bfc5                	j	8000475c <filestat+0x60>

000000008000476e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000476e:	7179                	addi	sp,sp,-48
    80004770:	f406                	sd	ra,40(sp)
    80004772:	f022                	sd	s0,32(sp)
    80004774:	ec26                	sd	s1,24(sp)
    80004776:	e84a                	sd	s2,16(sp)
    80004778:	e44e                	sd	s3,8(sp)
    8000477a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000477c:	00854783          	lbu	a5,8(a0)
    80004780:	c3d5                	beqz	a5,80004824 <fileread+0xb6>
    80004782:	84aa                	mv	s1,a0
    80004784:	89ae                	mv	s3,a1
    80004786:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004788:	411c                	lw	a5,0(a0)
    8000478a:	4705                	li	a4,1
    8000478c:	04e78963          	beq	a5,a4,800047de <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004790:	470d                	li	a4,3
    80004792:	04e78d63          	beq	a5,a4,800047ec <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004796:	4709                	li	a4,2
    80004798:	06e79e63          	bne	a5,a4,80004814 <fileread+0xa6>
    ilock(f->ip);
    8000479c:	6d08                	ld	a0,24(a0)
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	ff8080e7          	jalr	-8(ra) # 80003796 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047a6:	874a                	mv	a4,s2
    800047a8:	5094                	lw	a3,32(s1)
    800047aa:	864e                	mv	a2,s3
    800047ac:	4585                	li	a1,1
    800047ae:	6c88                	ld	a0,24(s1)
    800047b0:	fffff097          	auipc	ra,0xfffff
    800047b4:	29a080e7          	jalr	666(ra) # 80003a4a <readi>
    800047b8:	892a                	mv	s2,a0
    800047ba:	00a05563          	blez	a0,800047c4 <fileread+0x56>
      f->off += r;
    800047be:	509c                	lw	a5,32(s1)
    800047c0:	9fa9                	addw	a5,a5,a0
    800047c2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047c4:	6c88                	ld	a0,24(s1)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	092080e7          	jalr	146(ra) # 80003858 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047ce:	854a                	mv	a0,s2
    800047d0:	70a2                	ld	ra,40(sp)
    800047d2:	7402                	ld	s0,32(sp)
    800047d4:	64e2                	ld	s1,24(sp)
    800047d6:	6942                	ld	s2,16(sp)
    800047d8:	69a2                	ld	s3,8(sp)
    800047da:	6145                	addi	sp,sp,48
    800047dc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047de:	6908                	ld	a0,16(a0)
    800047e0:	00000097          	auipc	ra,0x0
    800047e4:	3c8080e7          	jalr	968(ra) # 80004ba8 <piperead>
    800047e8:	892a                	mv	s2,a0
    800047ea:	b7d5                	j	800047ce <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047ec:	02451783          	lh	a5,36(a0)
    800047f0:	03079693          	slli	a3,a5,0x30
    800047f4:	92c1                	srli	a3,a3,0x30
    800047f6:	4725                	li	a4,9
    800047f8:	02d76863          	bltu	a4,a3,80004828 <fileread+0xba>
    800047fc:	0792                	slli	a5,a5,0x4
    800047fe:	0001d717          	auipc	a4,0x1d
    80004802:	d1a70713          	addi	a4,a4,-742 # 80021518 <devsw>
    80004806:	97ba                	add	a5,a5,a4
    80004808:	639c                	ld	a5,0(a5)
    8000480a:	c38d                	beqz	a5,8000482c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000480c:	4505                	li	a0,1
    8000480e:	9782                	jalr	a5
    80004810:	892a                	mv	s2,a0
    80004812:	bf75                	j	800047ce <fileread+0x60>
    panic("fileread");
    80004814:	00004517          	auipc	a0,0x4
    80004818:	ee450513          	addi	a0,a0,-284 # 800086f8 <syscalls+0x268>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	d22080e7          	jalr	-734(ra) # 8000053e <panic>
    return -1;
    80004824:	597d                	li	s2,-1
    80004826:	b765                	j	800047ce <fileread+0x60>
      return -1;
    80004828:	597d                	li	s2,-1
    8000482a:	b755                	j	800047ce <fileread+0x60>
    8000482c:	597d                	li	s2,-1
    8000482e:	b745                	j	800047ce <fileread+0x60>

0000000080004830 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004830:	715d                	addi	sp,sp,-80
    80004832:	e486                	sd	ra,72(sp)
    80004834:	e0a2                	sd	s0,64(sp)
    80004836:	fc26                	sd	s1,56(sp)
    80004838:	f84a                	sd	s2,48(sp)
    8000483a:	f44e                	sd	s3,40(sp)
    8000483c:	f052                	sd	s4,32(sp)
    8000483e:	ec56                	sd	s5,24(sp)
    80004840:	e85a                	sd	s6,16(sp)
    80004842:	e45e                	sd	s7,8(sp)
    80004844:	e062                	sd	s8,0(sp)
    80004846:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004848:	00954783          	lbu	a5,9(a0)
    8000484c:	10078663          	beqz	a5,80004958 <filewrite+0x128>
    80004850:	892a                	mv	s2,a0
    80004852:	8aae                	mv	s5,a1
    80004854:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004856:	411c                	lw	a5,0(a0)
    80004858:	4705                	li	a4,1
    8000485a:	02e78263          	beq	a5,a4,8000487e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000485e:	470d                	li	a4,3
    80004860:	02e78663          	beq	a5,a4,8000488c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004864:	4709                	li	a4,2
    80004866:	0ee79163          	bne	a5,a4,80004948 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000486a:	0ac05d63          	blez	a2,80004924 <filewrite+0xf4>
    int i = 0;
    8000486e:	4981                	li	s3,0
    80004870:	6b05                	lui	s6,0x1
    80004872:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004876:	6b85                	lui	s7,0x1
    80004878:	c00b8b9b          	addiw	s7,s7,-1024
    8000487c:	a861                	j	80004914 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000487e:	6908                	ld	a0,16(a0)
    80004880:	00000097          	auipc	ra,0x0
    80004884:	22e080e7          	jalr	558(ra) # 80004aae <pipewrite>
    80004888:	8a2a                	mv	s4,a0
    8000488a:	a045                	j	8000492a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000488c:	02451783          	lh	a5,36(a0)
    80004890:	03079693          	slli	a3,a5,0x30
    80004894:	92c1                	srli	a3,a3,0x30
    80004896:	4725                	li	a4,9
    80004898:	0cd76263          	bltu	a4,a3,8000495c <filewrite+0x12c>
    8000489c:	0792                	slli	a5,a5,0x4
    8000489e:	0001d717          	auipc	a4,0x1d
    800048a2:	c7a70713          	addi	a4,a4,-902 # 80021518 <devsw>
    800048a6:	97ba                	add	a5,a5,a4
    800048a8:	679c                	ld	a5,8(a5)
    800048aa:	cbdd                	beqz	a5,80004960 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048ac:	4505                	li	a0,1
    800048ae:	9782                	jalr	a5
    800048b0:	8a2a                	mv	s4,a0
    800048b2:	a8a5                	j	8000492a <filewrite+0xfa>
    800048b4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048b8:	00000097          	auipc	ra,0x0
    800048bc:	8b0080e7          	jalr	-1872(ra) # 80004168 <begin_op>
      ilock(f->ip);
    800048c0:	01893503          	ld	a0,24(s2)
    800048c4:	fffff097          	auipc	ra,0xfffff
    800048c8:	ed2080e7          	jalr	-302(ra) # 80003796 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048cc:	8762                	mv	a4,s8
    800048ce:	02092683          	lw	a3,32(s2)
    800048d2:	01598633          	add	a2,s3,s5
    800048d6:	4585                	li	a1,1
    800048d8:	01893503          	ld	a0,24(s2)
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	266080e7          	jalr	614(ra) # 80003b42 <writei>
    800048e4:	84aa                	mv	s1,a0
    800048e6:	00a05763          	blez	a0,800048f4 <filewrite+0xc4>
        f->off += r;
    800048ea:	02092783          	lw	a5,32(s2)
    800048ee:	9fa9                	addw	a5,a5,a0
    800048f0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048f4:	01893503          	ld	a0,24(s2)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	f60080e7          	jalr	-160(ra) # 80003858 <iunlock>
      end_op();
    80004900:	00000097          	auipc	ra,0x0
    80004904:	8e8080e7          	jalr	-1816(ra) # 800041e8 <end_op>

      if(r != n1){
    80004908:	009c1f63          	bne	s8,s1,80004926 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000490c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004910:	0149db63          	bge	s3,s4,80004926 <filewrite+0xf6>
      int n1 = n - i;
    80004914:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004918:	84be                	mv	s1,a5
    8000491a:	2781                	sext.w	a5,a5
    8000491c:	f8fb5ce3          	bge	s6,a5,800048b4 <filewrite+0x84>
    80004920:	84de                	mv	s1,s7
    80004922:	bf49                	j	800048b4 <filewrite+0x84>
    int i = 0;
    80004924:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004926:	013a1f63          	bne	s4,s3,80004944 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000492a:	8552                	mv	a0,s4
    8000492c:	60a6                	ld	ra,72(sp)
    8000492e:	6406                	ld	s0,64(sp)
    80004930:	74e2                	ld	s1,56(sp)
    80004932:	7942                	ld	s2,48(sp)
    80004934:	79a2                	ld	s3,40(sp)
    80004936:	7a02                	ld	s4,32(sp)
    80004938:	6ae2                	ld	s5,24(sp)
    8000493a:	6b42                	ld	s6,16(sp)
    8000493c:	6ba2                	ld	s7,8(sp)
    8000493e:	6c02                	ld	s8,0(sp)
    80004940:	6161                	addi	sp,sp,80
    80004942:	8082                	ret
    ret = (i == n ? n : -1);
    80004944:	5a7d                	li	s4,-1
    80004946:	b7d5                	j	8000492a <filewrite+0xfa>
    panic("filewrite");
    80004948:	00004517          	auipc	a0,0x4
    8000494c:	dc050513          	addi	a0,a0,-576 # 80008708 <syscalls+0x278>
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	bee080e7          	jalr	-1042(ra) # 8000053e <panic>
    return -1;
    80004958:	5a7d                	li	s4,-1
    8000495a:	bfc1                	j	8000492a <filewrite+0xfa>
      return -1;
    8000495c:	5a7d                	li	s4,-1
    8000495e:	b7f1                	j	8000492a <filewrite+0xfa>
    80004960:	5a7d                	li	s4,-1
    80004962:	b7e1                	j	8000492a <filewrite+0xfa>

0000000080004964 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004964:	7179                	addi	sp,sp,-48
    80004966:	f406                	sd	ra,40(sp)
    80004968:	f022                	sd	s0,32(sp)
    8000496a:	ec26                	sd	s1,24(sp)
    8000496c:	e84a                	sd	s2,16(sp)
    8000496e:	e44e                	sd	s3,8(sp)
    80004970:	e052                	sd	s4,0(sp)
    80004972:	1800                	addi	s0,sp,48
    80004974:	84aa                	mv	s1,a0
    80004976:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004978:	0005b023          	sd	zero,0(a1)
    8000497c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004980:	00000097          	auipc	ra,0x0
    80004984:	bf8080e7          	jalr	-1032(ra) # 80004578 <filealloc>
    80004988:	e088                	sd	a0,0(s1)
    8000498a:	c551                	beqz	a0,80004a16 <pipealloc+0xb2>
    8000498c:	00000097          	auipc	ra,0x0
    80004990:	bec080e7          	jalr	-1044(ra) # 80004578 <filealloc>
    80004994:	00aa3023          	sd	a0,0(s4)
    80004998:	c92d                	beqz	a0,80004a0a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	15a080e7          	jalr	346(ra) # 80000af4 <kalloc>
    800049a2:	892a                	mv	s2,a0
    800049a4:	c125                	beqz	a0,80004a04 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049a6:	4985                	li	s3,1
    800049a8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049ac:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049b0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049b4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049b8:	00004597          	auipc	a1,0x4
    800049bc:	d6058593          	addi	a1,a1,-672 # 80008718 <syscalls+0x288>
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	194080e7          	jalr	404(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800049c8:	609c                	ld	a5,0(s1)
    800049ca:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049ce:	609c                	ld	a5,0(s1)
    800049d0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049d4:	609c                	ld	a5,0(s1)
    800049d6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049da:	609c                	ld	a5,0(s1)
    800049dc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049e0:	000a3783          	ld	a5,0(s4)
    800049e4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049e8:	000a3783          	ld	a5,0(s4)
    800049ec:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049f0:	000a3783          	ld	a5,0(s4)
    800049f4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049f8:	000a3783          	ld	a5,0(s4)
    800049fc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a00:	4501                	li	a0,0
    80004a02:	a025                	j	80004a2a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a04:	6088                	ld	a0,0(s1)
    80004a06:	e501                	bnez	a0,80004a0e <pipealloc+0xaa>
    80004a08:	a039                	j	80004a16 <pipealloc+0xb2>
    80004a0a:	6088                	ld	a0,0(s1)
    80004a0c:	c51d                	beqz	a0,80004a3a <pipealloc+0xd6>
    fileclose(*f0);
    80004a0e:	00000097          	auipc	ra,0x0
    80004a12:	c26080e7          	jalr	-986(ra) # 80004634 <fileclose>
  if(*f1)
    80004a16:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a1a:	557d                	li	a0,-1
  if(*f1)
    80004a1c:	c799                	beqz	a5,80004a2a <pipealloc+0xc6>
    fileclose(*f1);
    80004a1e:	853e                	mv	a0,a5
    80004a20:	00000097          	auipc	ra,0x0
    80004a24:	c14080e7          	jalr	-1004(ra) # 80004634 <fileclose>
  return -1;
    80004a28:	557d                	li	a0,-1
}
    80004a2a:	70a2                	ld	ra,40(sp)
    80004a2c:	7402                	ld	s0,32(sp)
    80004a2e:	64e2                	ld	s1,24(sp)
    80004a30:	6942                	ld	s2,16(sp)
    80004a32:	69a2                	ld	s3,8(sp)
    80004a34:	6a02                	ld	s4,0(sp)
    80004a36:	6145                	addi	sp,sp,48
    80004a38:	8082                	ret
  return -1;
    80004a3a:	557d                	li	a0,-1
    80004a3c:	b7fd                	j	80004a2a <pipealloc+0xc6>

0000000080004a3e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a3e:	1101                	addi	sp,sp,-32
    80004a40:	ec06                	sd	ra,24(sp)
    80004a42:	e822                	sd	s0,16(sp)
    80004a44:	e426                	sd	s1,8(sp)
    80004a46:	e04a                	sd	s2,0(sp)
    80004a48:	1000                	addi	s0,sp,32
    80004a4a:	84aa                	mv	s1,a0
    80004a4c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	196080e7          	jalr	406(ra) # 80000be4 <acquire>
  if(writable){
    80004a56:	02090d63          	beqz	s2,80004a90 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a5a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a5e:	21848513          	addi	a0,s1,536
    80004a62:	ffffe097          	auipc	ra,0xffffe
    80004a66:	82a080e7          	jalr	-2006(ra) # 8000228c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a6a:	2204b783          	ld	a5,544(s1)
    80004a6e:	eb95                	bnez	a5,80004aa2 <pipeclose+0x64>
    release(&pi->lock);
    80004a70:	8526                	mv	a0,s1
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	226080e7          	jalr	550(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004a7a:	8526                	mv	a0,s1
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	f7c080e7          	jalr	-132(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004a84:	60e2                	ld	ra,24(sp)
    80004a86:	6442                	ld	s0,16(sp)
    80004a88:	64a2                	ld	s1,8(sp)
    80004a8a:	6902                	ld	s2,0(sp)
    80004a8c:	6105                	addi	sp,sp,32
    80004a8e:	8082                	ret
    pi->readopen = 0;
    80004a90:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a94:	21c48513          	addi	a0,s1,540
    80004a98:	ffffd097          	auipc	ra,0xffffd
    80004a9c:	7f4080e7          	jalr	2036(ra) # 8000228c <wakeup>
    80004aa0:	b7e9                	j	80004a6a <pipeclose+0x2c>
    release(&pi->lock);
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	1f4080e7          	jalr	500(ra) # 80000c98 <release>
}
    80004aac:	bfe1                	j	80004a84 <pipeclose+0x46>

0000000080004aae <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aae:	7159                	addi	sp,sp,-112
    80004ab0:	f486                	sd	ra,104(sp)
    80004ab2:	f0a2                	sd	s0,96(sp)
    80004ab4:	eca6                	sd	s1,88(sp)
    80004ab6:	e8ca                	sd	s2,80(sp)
    80004ab8:	e4ce                	sd	s3,72(sp)
    80004aba:	e0d2                	sd	s4,64(sp)
    80004abc:	fc56                	sd	s5,56(sp)
    80004abe:	f85a                	sd	s6,48(sp)
    80004ac0:	f45e                	sd	s7,40(sp)
    80004ac2:	f062                	sd	s8,32(sp)
    80004ac4:	ec66                	sd	s9,24(sp)
    80004ac6:	1880                	addi	s0,sp,112
    80004ac8:	84aa                	mv	s1,a0
    80004aca:	8aae                	mv	s5,a1
    80004acc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ace:	ffffd097          	auipc	ra,0xffffd
    80004ad2:	ee2080e7          	jalr	-286(ra) # 800019b0 <myproc>
    80004ad6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	10a080e7          	jalr	266(ra) # 80000be4 <acquire>
  while(i < n){
    80004ae2:	0d405163          	blez	s4,80004ba4 <pipewrite+0xf6>
    80004ae6:	8ba6                	mv	s7,s1
  int i = 0;
    80004ae8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aea:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004aec:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004af0:	21c48c13          	addi	s8,s1,540
    80004af4:	a08d                	j	80004b56 <pipewrite+0xa8>
      release(&pi->lock);
    80004af6:	8526                	mv	a0,s1
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	1a0080e7          	jalr	416(ra) # 80000c98 <release>
      return -1;
    80004b00:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b02:	854a                	mv	a0,s2
    80004b04:	70a6                	ld	ra,104(sp)
    80004b06:	7406                	ld	s0,96(sp)
    80004b08:	64e6                	ld	s1,88(sp)
    80004b0a:	6946                	ld	s2,80(sp)
    80004b0c:	69a6                	ld	s3,72(sp)
    80004b0e:	6a06                	ld	s4,64(sp)
    80004b10:	7ae2                	ld	s5,56(sp)
    80004b12:	7b42                	ld	s6,48(sp)
    80004b14:	7ba2                	ld	s7,40(sp)
    80004b16:	7c02                	ld	s8,32(sp)
    80004b18:	6ce2                	ld	s9,24(sp)
    80004b1a:	6165                	addi	sp,sp,112
    80004b1c:	8082                	ret
      wakeup(&pi->nread);
    80004b1e:	8566                	mv	a0,s9
    80004b20:	ffffd097          	auipc	ra,0xffffd
    80004b24:	76c080e7          	jalr	1900(ra) # 8000228c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b28:	85de                	mv	a1,s7
    80004b2a:	8562                	mv	a0,s8
    80004b2c:	ffffd097          	auipc	ra,0xffffd
    80004b30:	5d4080e7          	jalr	1492(ra) # 80002100 <sleep>
    80004b34:	a839                	j	80004b52 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b36:	21c4a783          	lw	a5,540(s1)
    80004b3a:	0017871b          	addiw	a4,a5,1
    80004b3e:	20e4ae23          	sw	a4,540(s1)
    80004b42:	1ff7f793          	andi	a5,a5,511
    80004b46:	97a6                	add	a5,a5,s1
    80004b48:	f9f44703          	lbu	a4,-97(s0)
    80004b4c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b50:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b52:	03495d63          	bge	s2,s4,80004b8c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b56:	2204a783          	lw	a5,544(s1)
    80004b5a:	dfd1                	beqz	a5,80004af6 <pipewrite+0x48>
    80004b5c:	0289a783          	lw	a5,40(s3)
    80004b60:	fbd9                	bnez	a5,80004af6 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b62:	2184a783          	lw	a5,536(s1)
    80004b66:	21c4a703          	lw	a4,540(s1)
    80004b6a:	2007879b          	addiw	a5,a5,512
    80004b6e:	faf708e3          	beq	a4,a5,80004b1e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b72:	4685                	li	a3,1
    80004b74:	01590633          	add	a2,s2,s5
    80004b78:	f9f40593          	addi	a1,s0,-97
    80004b7c:	0589b503          	ld	a0,88(s3)
    80004b80:	ffffd097          	auipc	ra,0xffffd
    80004b84:	b7e080e7          	jalr	-1154(ra) # 800016fe <copyin>
    80004b88:	fb6517e3          	bne	a0,s6,80004b36 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b8c:	21848513          	addi	a0,s1,536
    80004b90:	ffffd097          	auipc	ra,0xffffd
    80004b94:	6fc080e7          	jalr	1788(ra) # 8000228c <wakeup>
  release(&pi->lock);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	0fe080e7          	jalr	254(ra) # 80000c98 <release>
  return i;
    80004ba2:	b785                	j	80004b02 <pipewrite+0x54>
  int i = 0;
    80004ba4:	4901                	li	s2,0
    80004ba6:	b7dd                	j	80004b8c <pipewrite+0xde>

0000000080004ba8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ba8:	715d                	addi	sp,sp,-80
    80004baa:	e486                	sd	ra,72(sp)
    80004bac:	e0a2                	sd	s0,64(sp)
    80004bae:	fc26                	sd	s1,56(sp)
    80004bb0:	f84a                	sd	s2,48(sp)
    80004bb2:	f44e                	sd	s3,40(sp)
    80004bb4:	f052                	sd	s4,32(sp)
    80004bb6:	ec56                	sd	s5,24(sp)
    80004bb8:	e85a                	sd	s6,16(sp)
    80004bba:	0880                	addi	s0,sp,80
    80004bbc:	84aa                	mv	s1,a0
    80004bbe:	892e                	mv	s2,a1
    80004bc0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bc2:	ffffd097          	auipc	ra,0xffffd
    80004bc6:	dee080e7          	jalr	-530(ra) # 800019b0 <myproc>
    80004bca:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bcc:	8b26                	mv	s6,s1
    80004bce:	8526                	mv	a0,s1
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	014080e7          	jalr	20(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd8:	2184a703          	lw	a4,536(s1)
    80004bdc:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004be0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be4:	02f71463          	bne	a4,a5,80004c0c <piperead+0x64>
    80004be8:	2244a783          	lw	a5,548(s1)
    80004bec:	c385                	beqz	a5,80004c0c <piperead+0x64>
    if(pr->killed){
    80004bee:	028a2783          	lw	a5,40(s4)
    80004bf2:	ebc1                	bnez	a5,80004c82 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf4:	85da                	mv	a1,s6
    80004bf6:	854e                	mv	a0,s3
    80004bf8:	ffffd097          	auipc	ra,0xffffd
    80004bfc:	508080e7          	jalr	1288(ra) # 80002100 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c00:	2184a703          	lw	a4,536(s1)
    80004c04:	21c4a783          	lw	a5,540(s1)
    80004c08:	fef700e3          	beq	a4,a5,80004be8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c0c:	09505263          	blez	s5,80004c90 <piperead+0xe8>
    80004c10:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c12:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c14:	2184a783          	lw	a5,536(s1)
    80004c18:	21c4a703          	lw	a4,540(s1)
    80004c1c:	02f70d63          	beq	a4,a5,80004c56 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c20:	0017871b          	addiw	a4,a5,1
    80004c24:	20e4ac23          	sw	a4,536(s1)
    80004c28:	1ff7f793          	andi	a5,a5,511
    80004c2c:	97a6                	add	a5,a5,s1
    80004c2e:	0187c783          	lbu	a5,24(a5)
    80004c32:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c36:	4685                	li	a3,1
    80004c38:	fbf40613          	addi	a2,s0,-65
    80004c3c:	85ca                	mv	a1,s2
    80004c3e:	058a3503          	ld	a0,88(s4)
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	a30080e7          	jalr	-1488(ra) # 80001672 <copyout>
    80004c4a:	01650663          	beq	a0,s6,80004c56 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c4e:	2985                	addiw	s3,s3,1
    80004c50:	0905                	addi	s2,s2,1
    80004c52:	fd3a91e3          	bne	s5,s3,80004c14 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c56:	21c48513          	addi	a0,s1,540
    80004c5a:	ffffd097          	auipc	ra,0xffffd
    80004c5e:	632080e7          	jalr	1586(ra) # 8000228c <wakeup>
  release(&pi->lock);
    80004c62:	8526                	mv	a0,s1
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
  return i;
}
    80004c6c:	854e                	mv	a0,s3
    80004c6e:	60a6                	ld	ra,72(sp)
    80004c70:	6406                	ld	s0,64(sp)
    80004c72:	74e2                	ld	s1,56(sp)
    80004c74:	7942                	ld	s2,48(sp)
    80004c76:	79a2                	ld	s3,40(sp)
    80004c78:	7a02                	ld	s4,32(sp)
    80004c7a:	6ae2                	ld	s5,24(sp)
    80004c7c:	6b42                	ld	s6,16(sp)
    80004c7e:	6161                	addi	sp,sp,80
    80004c80:	8082                	ret
      release(&pi->lock);
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	014080e7          	jalr	20(ra) # 80000c98 <release>
      return -1;
    80004c8c:	59fd                	li	s3,-1
    80004c8e:	bff9                	j	80004c6c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c90:	4981                	li	s3,0
    80004c92:	b7d1                	j	80004c56 <piperead+0xae>

0000000080004c94 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c94:	df010113          	addi	sp,sp,-528
    80004c98:	20113423          	sd	ra,520(sp)
    80004c9c:	20813023          	sd	s0,512(sp)
    80004ca0:	ffa6                	sd	s1,504(sp)
    80004ca2:	fbca                	sd	s2,496(sp)
    80004ca4:	f7ce                	sd	s3,488(sp)
    80004ca6:	f3d2                	sd	s4,480(sp)
    80004ca8:	efd6                	sd	s5,472(sp)
    80004caa:	ebda                	sd	s6,464(sp)
    80004cac:	e7de                	sd	s7,456(sp)
    80004cae:	e3e2                	sd	s8,448(sp)
    80004cb0:	ff66                	sd	s9,440(sp)
    80004cb2:	fb6a                	sd	s10,432(sp)
    80004cb4:	f76e                	sd	s11,424(sp)
    80004cb6:	0c00                	addi	s0,sp,528
    80004cb8:	84aa                	mv	s1,a0
    80004cba:	dea43c23          	sd	a0,-520(s0)
    80004cbe:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	cee080e7          	jalr	-786(ra) # 800019b0 <myproc>
    80004cca:	892a                	mv	s2,a0

  begin_op();
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	49c080e7          	jalr	1180(ra) # 80004168 <begin_op>

  if((ip = namei(path)) == 0){
    80004cd4:	8526                	mv	a0,s1
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	276080e7          	jalr	630(ra) # 80003f4c <namei>
    80004cde:	c92d                	beqz	a0,80004d50 <exec+0xbc>
    80004ce0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	ab4080e7          	jalr	-1356(ra) # 80003796 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cea:	04000713          	li	a4,64
    80004cee:	4681                	li	a3,0
    80004cf0:	e5040613          	addi	a2,s0,-432
    80004cf4:	4581                	li	a1,0
    80004cf6:	8526                	mv	a0,s1
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	d52080e7          	jalr	-686(ra) # 80003a4a <readi>
    80004d00:	04000793          	li	a5,64
    80004d04:	00f51a63          	bne	a0,a5,80004d18 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d08:	e5042703          	lw	a4,-432(s0)
    80004d0c:	464c47b7          	lui	a5,0x464c4
    80004d10:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d14:	04f70463          	beq	a4,a5,80004d5c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d18:	8526                	mv	a0,s1
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	cde080e7          	jalr	-802(ra) # 800039f8 <iunlockput>
    end_op();
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	4c6080e7          	jalr	1222(ra) # 800041e8 <end_op>
  }
  return -1;
    80004d2a:	557d                	li	a0,-1
}
    80004d2c:	20813083          	ld	ra,520(sp)
    80004d30:	20013403          	ld	s0,512(sp)
    80004d34:	74fe                	ld	s1,504(sp)
    80004d36:	795e                	ld	s2,496(sp)
    80004d38:	79be                	ld	s3,488(sp)
    80004d3a:	7a1e                	ld	s4,480(sp)
    80004d3c:	6afe                	ld	s5,472(sp)
    80004d3e:	6b5e                	ld	s6,464(sp)
    80004d40:	6bbe                	ld	s7,456(sp)
    80004d42:	6c1e                	ld	s8,448(sp)
    80004d44:	7cfa                	ld	s9,440(sp)
    80004d46:	7d5a                	ld	s10,432(sp)
    80004d48:	7dba                	ld	s11,424(sp)
    80004d4a:	21010113          	addi	sp,sp,528
    80004d4e:	8082                	ret
    end_op();
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	498080e7          	jalr	1176(ra) # 800041e8 <end_op>
    return -1;
    80004d58:	557d                	li	a0,-1
    80004d5a:	bfc9                	j	80004d2c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d5c:	854a                	mv	a0,s2
    80004d5e:	ffffd097          	auipc	ra,0xffffd
    80004d62:	d16080e7          	jalr	-746(ra) # 80001a74 <proc_pagetable>
    80004d66:	8baa                	mv	s7,a0
    80004d68:	d945                	beqz	a0,80004d18 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d6a:	e7042983          	lw	s3,-400(s0)
    80004d6e:	e8845783          	lhu	a5,-376(s0)
    80004d72:	c7ad                	beqz	a5,80004ddc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d74:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d76:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d78:	6c85                	lui	s9,0x1
    80004d7a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d7e:	def43823          	sd	a5,-528(s0)
    80004d82:	a42d                	j	80004fac <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d84:	00004517          	auipc	a0,0x4
    80004d88:	99c50513          	addi	a0,a0,-1636 # 80008720 <syscalls+0x290>
    80004d8c:	ffffb097          	auipc	ra,0xffffb
    80004d90:	7b2080e7          	jalr	1970(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d94:	8756                	mv	a4,s5
    80004d96:	012d86bb          	addw	a3,s11,s2
    80004d9a:	4581                	li	a1,0
    80004d9c:	8526                	mv	a0,s1
    80004d9e:	fffff097          	auipc	ra,0xfffff
    80004da2:	cac080e7          	jalr	-852(ra) # 80003a4a <readi>
    80004da6:	2501                	sext.w	a0,a0
    80004da8:	1aaa9963          	bne	s5,a0,80004f5a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dac:	6785                	lui	a5,0x1
    80004dae:	0127893b          	addw	s2,a5,s2
    80004db2:	77fd                	lui	a5,0xfffff
    80004db4:	01478a3b          	addw	s4,a5,s4
    80004db8:	1f897163          	bgeu	s2,s8,80004f9a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004dbc:	02091593          	slli	a1,s2,0x20
    80004dc0:	9181                	srli	a1,a1,0x20
    80004dc2:	95ea                	add	a1,a1,s10
    80004dc4:	855e                	mv	a0,s7
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	2a8080e7          	jalr	680(ra) # 8000106e <walkaddr>
    80004dce:	862a                	mv	a2,a0
    if(pa == 0)
    80004dd0:	d955                	beqz	a0,80004d84 <exec+0xf0>
      n = PGSIZE;
    80004dd2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dd4:	fd9a70e3          	bgeu	s4,s9,80004d94 <exec+0x100>
      n = sz - i;
    80004dd8:	8ad2                	mv	s5,s4
    80004dda:	bf6d                	j	80004d94 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ddc:	4901                	li	s2,0
  iunlockput(ip);
    80004dde:	8526                	mv	a0,s1
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	c18080e7          	jalr	-1000(ra) # 800039f8 <iunlockput>
  end_op();
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	400080e7          	jalr	1024(ra) # 800041e8 <end_op>
  p = myproc();
    80004df0:	ffffd097          	auipc	ra,0xffffd
    80004df4:	bc0080e7          	jalr	-1088(ra) # 800019b0 <myproc>
    80004df8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004dfa:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004dfe:	6785                	lui	a5,0x1
    80004e00:	17fd                	addi	a5,a5,-1
    80004e02:	993e                	add	s2,s2,a5
    80004e04:	757d                	lui	a0,0xfffff
    80004e06:	00a977b3          	and	a5,s2,a0
    80004e0a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e0e:	6609                	lui	a2,0x2
    80004e10:	963e                	add	a2,a2,a5
    80004e12:	85be                	mv	a1,a5
    80004e14:	855e                	mv	a0,s7
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	60c080e7          	jalr	1548(ra) # 80001422 <uvmalloc>
    80004e1e:	8b2a                	mv	s6,a0
  ip = 0;
    80004e20:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e22:	12050c63          	beqz	a0,80004f5a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e26:	75f9                	lui	a1,0xffffe
    80004e28:	95aa                	add	a1,a1,a0
    80004e2a:	855e                	mv	a0,s7
    80004e2c:	ffffd097          	auipc	ra,0xffffd
    80004e30:	814080e7          	jalr	-2028(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e34:	7c7d                	lui	s8,0xfffff
    80004e36:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e38:	e0043783          	ld	a5,-512(s0)
    80004e3c:	6388                	ld	a0,0(a5)
    80004e3e:	c535                	beqz	a0,80004eaa <exec+0x216>
    80004e40:	e9040993          	addi	s3,s0,-368
    80004e44:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e48:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	01a080e7          	jalr	26(ra) # 80000e64 <strlen>
    80004e52:	2505                	addiw	a0,a0,1
    80004e54:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e58:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e5c:	13896363          	bltu	s2,s8,80004f82 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e60:	e0043d83          	ld	s11,-512(s0)
    80004e64:	000dba03          	ld	s4,0(s11)
    80004e68:	8552                	mv	a0,s4
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	ffa080e7          	jalr	-6(ra) # 80000e64 <strlen>
    80004e72:	0015069b          	addiw	a3,a0,1
    80004e76:	8652                	mv	a2,s4
    80004e78:	85ca                	mv	a1,s2
    80004e7a:	855e                	mv	a0,s7
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	7f6080e7          	jalr	2038(ra) # 80001672 <copyout>
    80004e84:	10054363          	bltz	a0,80004f8a <exec+0x2f6>
    ustack[argc] = sp;
    80004e88:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e8c:	0485                	addi	s1,s1,1
    80004e8e:	008d8793          	addi	a5,s11,8
    80004e92:	e0f43023          	sd	a5,-512(s0)
    80004e96:	008db503          	ld	a0,8(s11)
    80004e9a:	c911                	beqz	a0,80004eae <exec+0x21a>
    if(argc >= MAXARG)
    80004e9c:	09a1                	addi	s3,s3,8
    80004e9e:	fb3c96e3          	bne	s9,s3,80004e4a <exec+0x1b6>
  sz = sz1;
    80004ea2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea6:	4481                	li	s1,0
    80004ea8:	a84d                	j	80004f5a <exec+0x2c6>
  sp = sz;
    80004eaa:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eac:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eae:	00349793          	slli	a5,s1,0x3
    80004eb2:	f9040713          	addi	a4,s0,-112
    80004eb6:	97ba                	add	a5,a5,a4
    80004eb8:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ebc:	00148693          	addi	a3,s1,1
    80004ec0:	068e                	slli	a3,a3,0x3
    80004ec2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ec6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004eca:	01897663          	bgeu	s2,s8,80004ed6 <exec+0x242>
  sz = sz1;
    80004ece:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ed2:	4481                	li	s1,0
    80004ed4:	a059                	j	80004f5a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ed6:	e9040613          	addi	a2,s0,-368
    80004eda:	85ca                	mv	a1,s2
    80004edc:	855e                	mv	a0,s7
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	794080e7          	jalr	1940(ra) # 80001672 <copyout>
    80004ee6:	0a054663          	bltz	a0,80004f92 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004eea:	060ab783          	ld	a5,96(s5)
    80004eee:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ef2:	df843783          	ld	a5,-520(s0)
    80004ef6:	0007c703          	lbu	a4,0(a5)
    80004efa:	cf11                	beqz	a4,80004f16 <exec+0x282>
    80004efc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004efe:	02f00693          	li	a3,47
    80004f02:	a039                	j	80004f10 <exec+0x27c>
      last = s+1;
    80004f04:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f08:	0785                	addi	a5,a5,1
    80004f0a:	fff7c703          	lbu	a4,-1(a5)
    80004f0e:	c701                	beqz	a4,80004f16 <exec+0x282>
    if(*s == '/')
    80004f10:	fed71ce3          	bne	a4,a3,80004f08 <exec+0x274>
    80004f14:	bfc5                	j	80004f04 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f16:	4641                	li	a2,16
    80004f18:	df843583          	ld	a1,-520(s0)
    80004f1c:	160a8513          	addi	a0,s5,352
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	f12080e7          	jalr	-238(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f28:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80004f2c:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80004f30:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f34:	060ab783          	ld	a5,96(s5)
    80004f38:	e6843703          	ld	a4,-408(s0)
    80004f3c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f3e:	060ab783          	ld	a5,96(s5)
    80004f42:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f46:	85ea                	mv	a1,s10
    80004f48:	ffffd097          	auipc	ra,0xffffd
    80004f4c:	bc8080e7          	jalr	-1080(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f50:	0004851b          	sext.w	a0,s1
    80004f54:	bbe1                	j	80004d2c <exec+0x98>
    80004f56:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f5a:	e0843583          	ld	a1,-504(s0)
    80004f5e:	855e                	mv	a0,s7
    80004f60:	ffffd097          	auipc	ra,0xffffd
    80004f64:	bb0080e7          	jalr	-1104(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004f68:	da0498e3          	bnez	s1,80004d18 <exec+0x84>
  return -1;
    80004f6c:	557d                	li	a0,-1
    80004f6e:	bb7d                	j	80004d2c <exec+0x98>
    80004f70:	e1243423          	sd	s2,-504(s0)
    80004f74:	b7dd                	j	80004f5a <exec+0x2c6>
    80004f76:	e1243423          	sd	s2,-504(s0)
    80004f7a:	b7c5                	j	80004f5a <exec+0x2c6>
    80004f7c:	e1243423          	sd	s2,-504(s0)
    80004f80:	bfe9                	j	80004f5a <exec+0x2c6>
  sz = sz1;
    80004f82:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f86:	4481                	li	s1,0
    80004f88:	bfc9                	j	80004f5a <exec+0x2c6>
  sz = sz1;
    80004f8a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f8e:	4481                	li	s1,0
    80004f90:	b7e9                	j	80004f5a <exec+0x2c6>
  sz = sz1;
    80004f92:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f96:	4481                	li	s1,0
    80004f98:	b7c9                	j	80004f5a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f9a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f9e:	2b05                	addiw	s6,s6,1
    80004fa0:	0389899b          	addiw	s3,s3,56
    80004fa4:	e8845783          	lhu	a5,-376(s0)
    80004fa8:	e2fb5be3          	bge	s6,a5,80004dde <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fac:	2981                	sext.w	s3,s3
    80004fae:	03800713          	li	a4,56
    80004fb2:	86ce                	mv	a3,s3
    80004fb4:	e1840613          	addi	a2,s0,-488
    80004fb8:	4581                	li	a1,0
    80004fba:	8526                	mv	a0,s1
    80004fbc:	fffff097          	auipc	ra,0xfffff
    80004fc0:	a8e080e7          	jalr	-1394(ra) # 80003a4a <readi>
    80004fc4:	03800793          	li	a5,56
    80004fc8:	f8f517e3          	bne	a0,a5,80004f56 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fcc:	e1842783          	lw	a5,-488(s0)
    80004fd0:	4705                	li	a4,1
    80004fd2:	fce796e3          	bne	a5,a4,80004f9e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fd6:	e4043603          	ld	a2,-448(s0)
    80004fda:	e3843783          	ld	a5,-456(s0)
    80004fde:	f8f669e3          	bltu	a2,a5,80004f70 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fe2:	e2843783          	ld	a5,-472(s0)
    80004fe6:	963e                	add	a2,a2,a5
    80004fe8:	f8f667e3          	bltu	a2,a5,80004f76 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fec:	85ca                	mv	a1,s2
    80004fee:	855e                	mv	a0,s7
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	432080e7          	jalr	1074(ra) # 80001422 <uvmalloc>
    80004ff8:	e0a43423          	sd	a0,-504(s0)
    80004ffc:	d141                	beqz	a0,80004f7c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004ffe:	e2843d03          	ld	s10,-472(s0)
    80005002:	df043783          	ld	a5,-528(s0)
    80005006:	00fd77b3          	and	a5,s10,a5
    8000500a:	fba1                	bnez	a5,80004f5a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000500c:	e2042d83          	lw	s11,-480(s0)
    80005010:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005014:	f80c03e3          	beqz	s8,80004f9a <exec+0x306>
    80005018:	8a62                	mv	s4,s8
    8000501a:	4901                	li	s2,0
    8000501c:	b345                	j	80004dbc <exec+0x128>

000000008000501e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000501e:	7179                	addi	sp,sp,-48
    80005020:	f406                	sd	ra,40(sp)
    80005022:	f022                	sd	s0,32(sp)
    80005024:	ec26                	sd	s1,24(sp)
    80005026:	e84a                	sd	s2,16(sp)
    80005028:	1800                	addi	s0,sp,48
    8000502a:	892e                	mv	s2,a1
    8000502c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000502e:	fdc40593          	addi	a1,s0,-36
    80005032:	ffffe097          	auipc	ra,0xffffe
    80005036:	ba4080e7          	jalr	-1116(ra) # 80002bd6 <argint>
    8000503a:	04054063          	bltz	a0,8000507a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000503e:	fdc42703          	lw	a4,-36(s0)
    80005042:	47bd                	li	a5,15
    80005044:	02e7ed63          	bltu	a5,a4,8000507e <argfd+0x60>
    80005048:	ffffd097          	auipc	ra,0xffffd
    8000504c:	968080e7          	jalr	-1688(ra) # 800019b0 <myproc>
    80005050:	fdc42703          	lw	a4,-36(s0)
    80005054:	01a70793          	addi	a5,a4,26
    80005058:	078e                	slli	a5,a5,0x3
    8000505a:	953e                	add	a0,a0,a5
    8000505c:	651c                	ld	a5,8(a0)
    8000505e:	c395                	beqz	a5,80005082 <argfd+0x64>
    return -1;
  if(pfd)
    80005060:	00090463          	beqz	s2,80005068 <argfd+0x4a>
    *pfd = fd;
    80005064:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005068:	4501                	li	a0,0
  if(pf)
    8000506a:	c091                	beqz	s1,8000506e <argfd+0x50>
    *pf = f;
    8000506c:	e09c                	sd	a5,0(s1)
}
    8000506e:	70a2                	ld	ra,40(sp)
    80005070:	7402                	ld	s0,32(sp)
    80005072:	64e2                	ld	s1,24(sp)
    80005074:	6942                	ld	s2,16(sp)
    80005076:	6145                	addi	sp,sp,48
    80005078:	8082                	ret
    return -1;
    8000507a:	557d                	li	a0,-1
    8000507c:	bfcd                	j	8000506e <argfd+0x50>
    return -1;
    8000507e:	557d                	li	a0,-1
    80005080:	b7fd                	j	8000506e <argfd+0x50>
    80005082:	557d                	li	a0,-1
    80005084:	b7ed                	j	8000506e <argfd+0x50>

0000000080005086 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005086:	1101                	addi	sp,sp,-32
    80005088:	ec06                	sd	ra,24(sp)
    8000508a:	e822                	sd	s0,16(sp)
    8000508c:	e426                	sd	s1,8(sp)
    8000508e:	1000                	addi	s0,sp,32
    80005090:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005092:	ffffd097          	auipc	ra,0xffffd
    80005096:	91e080e7          	jalr	-1762(ra) # 800019b0 <myproc>
    8000509a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000509c:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd90d8>
    800050a0:	4501                	li	a0,0
    800050a2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050a4:	6398                	ld	a4,0(a5)
    800050a6:	cb19                	beqz	a4,800050bc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050a8:	2505                	addiw	a0,a0,1
    800050aa:	07a1                	addi	a5,a5,8
    800050ac:	fed51ce3          	bne	a0,a3,800050a4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050b0:	557d                	li	a0,-1
}
    800050b2:	60e2                	ld	ra,24(sp)
    800050b4:	6442                	ld	s0,16(sp)
    800050b6:	64a2                	ld	s1,8(sp)
    800050b8:	6105                	addi	sp,sp,32
    800050ba:	8082                	ret
      p->ofile[fd] = f;
    800050bc:	01a50793          	addi	a5,a0,26
    800050c0:	078e                	slli	a5,a5,0x3
    800050c2:	963e                	add	a2,a2,a5
    800050c4:	e604                	sd	s1,8(a2)
      return fd;
    800050c6:	b7f5                	j	800050b2 <fdalloc+0x2c>

00000000800050c8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050c8:	715d                	addi	sp,sp,-80
    800050ca:	e486                	sd	ra,72(sp)
    800050cc:	e0a2                	sd	s0,64(sp)
    800050ce:	fc26                	sd	s1,56(sp)
    800050d0:	f84a                	sd	s2,48(sp)
    800050d2:	f44e                	sd	s3,40(sp)
    800050d4:	f052                	sd	s4,32(sp)
    800050d6:	ec56                	sd	s5,24(sp)
    800050d8:	0880                	addi	s0,sp,80
    800050da:	89ae                	mv	s3,a1
    800050dc:	8ab2                	mv	s5,a2
    800050de:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050e0:	fb040593          	addi	a1,s0,-80
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	e86080e7          	jalr	-378(ra) # 80003f6a <nameiparent>
    800050ec:	892a                	mv	s2,a0
    800050ee:	12050f63          	beqz	a0,8000522c <create+0x164>
    return 0;

  ilock(dp);
    800050f2:	ffffe097          	auipc	ra,0xffffe
    800050f6:	6a4080e7          	jalr	1700(ra) # 80003796 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050fa:	4601                	li	a2,0
    800050fc:	fb040593          	addi	a1,s0,-80
    80005100:	854a                	mv	a0,s2
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	b78080e7          	jalr	-1160(ra) # 80003c7a <dirlookup>
    8000510a:	84aa                	mv	s1,a0
    8000510c:	c921                	beqz	a0,8000515c <create+0x94>
    iunlockput(dp);
    8000510e:	854a                	mv	a0,s2
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	8e8080e7          	jalr	-1816(ra) # 800039f8 <iunlockput>
    ilock(ip);
    80005118:	8526                	mv	a0,s1
    8000511a:	ffffe097          	auipc	ra,0xffffe
    8000511e:	67c080e7          	jalr	1660(ra) # 80003796 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005122:	2981                	sext.w	s3,s3
    80005124:	4789                	li	a5,2
    80005126:	02f99463          	bne	s3,a5,8000514e <create+0x86>
    8000512a:	0444d783          	lhu	a5,68(s1)
    8000512e:	37f9                	addiw	a5,a5,-2
    80005130:	17c2                	slli	a5,a5,0x30
    80005132:	93c1                	srli	a5,a5,0x30
    80005134:	4705                	li	a4,1
    80005136:	00f76c63          	bltu	a4,a5,8000514e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000513a:	8526                	mv	a0,s1
    8000513c:	60a6                	ld	ra,72(sp)
    8000513e:	6406                	ld	s0,64(sp)
    80005140:	74e2                	ld	s1,56(sp)
    80005142:	7942                	ld	s2,48(sp)
    80005144:	79a2                	ld	s3,40(sp)
    80005146:	7a02                	ld	s4,32(sp)
    80005148:	6ae2                	ld	s5,24(sp)
    8000514a:	6161                	addi	sp,sp,80
    8000514c:	8082                	ret
    iunlockput(ip);
    8000514e:	8526                	mv	a0,s1
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	8a8080e7          	jalr	-1880(ra) # 800039f8 <iunlockput>
    return 0;
    80005158:	4481                	li	s1,0
    8000515a:	b7c5                	j	8000513a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000515c:	85ce                	mv	a1,s3
    8000515e:	00092503          	lw	a0,0(s2)
    80005162:	ffffe097          	auipc	ra,0xffffe
    80005166:	49c080e7          	jalr	1180(ra) # 800035fe <ialloc>
    8000516a:	84aa                	mv	s1,a0
    8000516c:	c529                	beqz	a0,800051b6 <create+0xee>
  ilock(ip);
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	628080e7          	jalr	1576(ra) # 80003796 <ilock>
  ip->major = major;
    80005176:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000517a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000517e:	4785                	li	a5,1
    80005180:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005184:	8526                	mv	a0,s1
    80005186:	ffffe097          	auipc	ra,0xffffe
    8000518a:	546080e7          	jalr	1350(ra) # 800036cc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000518e:	2981                	sext.w	s3,s3
    80005190:	4785                	li	a5,1
    80005192:	02f98a63          	beq	s3,a5,800051c6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005196:	40d0                	lw	a2,4(s1)
    80005198:	fb040593          	addi	a1,s0,-80
    8000519c:	854a                	mv	a0,s2
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	cec080e7          	jalr	-788(ra) # 80003e8a <dirlink>
    800051a6:	06054b63          	bltz	a0,8000521c <create+0x154>
  iunlockput(dp);
    800051aa:	854a                	mv	a0,s2
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	84c080e7          	jalr	-1972(ra) # 800039f8 <iunlockput>
  return ip;
    800051b4:	b759                	j	8000513a <create+0x72>
    panic("create: ialloc");
    800051b6:	00003517          	auipc	a0,0x3
    800051ba:	58a50513          	addi	a0,a0,1418 # 80008740 <syscalls+0x2b0>
    800051be:	ffffb097          	auipc	ra,0xffffb
    800051c2:	380080e7          	jalr	896(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800051c6:	04a95783          	lhu	a5,74(s2)
    800051ca:	2785                	addiw	a5,a5,1
    800051cc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051d0:	854a                	mv	a0,s2
    800051d2:	ffffe097          	auipc	ra,0xffffe
    800051d6:	4fa080e7          	jalr	1274(ra) # 800036cc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051da:	40d0                	lw	a2,4(s1)
    800051dc:	00003597          	auipc	a1,0x3
    800051e0:	57458593          	addi	a1,a1,1396 # 80008750 <syscalls+0x2c0>
    800051e4:	8526                	mv	a0,s1
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	ca4080e7          	jalr	-860(ra) # 80003e8a <dirlink>
    800051ee:	00054f63          	bltz	a0,8000520c <create+0x144>
    800051f2:	00492603          	lw	a2,4(s2)
    800051f6:	00003597          	auipc	a1,0x3
    800051fa:	56258593          	addi	a1,a1,1378 # 80008758 <syscalls+0x2c8>
    800051fe:	8526                	mv	a0,s1
    80005200:	fffff097          	auipc	ra,0xfffff
    80005204:	c8a080e7          	jalr	-886(ra) # 80003e8a <dirlink>
    80005208:	f80557e3          	bgez	a0,80005196 <create+0xce>
      panic("create dots");
    8000520c:	00003517          	auipc	a0,0x3
    80005210:	55450513          	addi	a0,a0,1364 # 80008760 <syscalls+0x2d0>
    80005214:	ffffb097          	auipc	ra,0xffffb
    80005218:	32a080e7          	jalr	810(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000521c:	00003517          	auipc	a0,0x3
    80005220:	55450513          	addi	a0,a0,1364 # 80008770 <syscalls+0x2e0>
    80005224:	ffffb097          	auipc	ra,0xffffb
    80005228:	31a080e7          	jalr	794(ra) # 8000053e <panic>
    return 0;
    8000522c:	84aa                	mv	s1,a0
    8000522e:	b731                	j	8000513a <create+0x72>

0000000080005230 <sys_dup>:
{
    80005230:	7179                	addi	sp,sp,-48
    80005232:	f406                	sd	ra,40(sp)
    80005234:	f022                	sd	s0,32(sp)
    80005236:	ec26                	sd	s1,24(sp)
    80005238:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000523a:	fd840613          	addi	a2,s0,-40
    8000523e:	4581                	li	a1,0
    80005240:	4501                	li	a0,0
    80005242:	00000097          	auipc	ra,0x0
    80005246:	ddc080e7          	jalr	-548(ra) # 8000501e <argfd>
    return -1;
    8000524a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000524c:	02054363          	bltz	a0,80005272 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005250:	fd843503          	ld	a0,-40(s0)
    80005254:	00000097          	auipc	ra,0x0
    80005258:	e32080e7          	jalr	-462(ra) # 80005086 <fdalloc>
    8000525c:	84aa                	mv	s1,a0
    return -1;
    8000525e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005260:	00054963          	bltz	a0,80005272 <sys_dup+0x42>
  filedup(f);
    80005264:	fd843503          	ld	a0,-40(s0)
    80005268:	fffff097          	auipc	ra,0xfffff
    8000526c:	37a080e7          	jalr	890(ra) # 800045e2 <filedup>
  return fd;
    80005270:	87a6                	mv	a5,s1
}
    80005272:	853e                	mv	a0,a5
    80005274:	70a2                	ld	ra,40(sp)
    80005276:	7402                	ld	s0,32(sp)
    80005278:	64e2                	ld	s1,24(sp)
    8000527a:	6145                	addi	sp,sp,48
    8000527c:	8082                	ret

000000008000527e <sys_read>:
{
    8000527e:	7179                	addi	sp,sp,-48
    80005280:	f406                	sd	ra,40(sp)
    80005282:	f022                	sd	s0,32(sp)
    80005284:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005286:	fe840613          	addi	a2,s0,-24
    8000528a:	4581                	li	a1,0
    8000528c:	4501                	li	a0,0
    8000528e:	00000097          	auipc	ra,0x0
    80005292:	d90080e7          	jalr	-624(ra) # 8000501e <argfd>
    return -1;
    80005296:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005298:	04054163          	bltz	a0,800052da <sys_read+0x5c>
    8000529c:	fe440593          	addi	a1,s0,-28
    800052a0:	4509                	li	a0,2
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	934080e7          	jalr	-1740(ra) # 80002bd6 <argint>
    return -1;
    800052aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ac:	02054763          	bltz	a0,800052da <sys_read+0x5c>
    800052b0:	fd840593          	addi	a1,s0,-40
    800052b4:	4505                	li	a0,1
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	942080e7          	jalr	-1726(ra) # 80002bf8 <argaddr>
    return -1;
    800052be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c0:	00054d63          	bltz	a0,800052da <sys_read+0x5c>
  return fileread(f, p, n);
    800052c4:	fe442603          	lw	a2,-28(s0)
    800052c8:	fd843583          	ld	a1,-40(s0)
    800052cc:	fe843503          	ld	a0,-24(s0)
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	49e080e7          	jalr	1182(ra) # 8000476e <fileread>
    800052d8:	87aa                	mv	a5,a0
}
    800052da:	853e                	mv	a0,a5
    800052dc:	70a2                	ld	ra,40(sp)
    800052de:	7402                	ld	s0,32(sp)
    800052e0:	6145                	addi	sp,sp,48
    800052e2:	8082                	ret

00000000800052e4 <sys_write>:
{
    800052e4:	7179                	addi	sp,sp,-48
    800052e6:	f406                	sd	ra,40(sp)
    800052e8:	f022                	sd	s0,32(sp)
    800052ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ec:	fe840613          	addi	a2,s0,-24
    800052f0:	4581                	li	a1,0
    800052f2:	4501                	li	a0,0
    800052f4:	00000097          	auipc	ra,0x0
    800052f8:	d2a080e7          	jalr	-726(ra) # 8000501e <argfd>
    return -1;
    800052fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fe:	04054163          	bltz	a0,80005340 <sys_write+0x5c>
    80005302:	fe440593          	addi	a1,s0,-28
    80005306:	4509                	li	a0,2
    80005308:	ffffe097          	auipc	ra,0xffffe
    8000530c:	8ce080e7          	jalr	-1842(ra) # 80002bd6 <argint>
    return -1;
    80005310:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005312:	02054763          	bltz	a0,80005340 <sys_write+0x5c>
    80005316:	fd840593          	addi	a1,s0,-40
    8000531a:	4505                	li	a0,1
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	8dc080e7          	jalr	-1828(ra) # 80002bf8 <argaddr>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005326:	00054d63          	bltz	a0,80005340 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000532a:	fe442603          	lw	a2,-28(s0)
    8000532e:	fd843583          	ld	a1,-40(s0)
    80005332:	fe843503          	ld	a0,-24(s0)
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	4fa080e7          	jalr	1274(ra) # 80004830 <filewrite>
    8000533e:	87aa                	mv	a5,a0
}
    80005340:	853e                	mv	a0,a5
    80005342:	70a2                	ld	ra,40(sp)
    80005344:	7402                	ld	s0,32(sp)
    80005346:	6145                	addi	sp,sp,48
    80005348:	8082                	ret

000000008000534a <sys_close>:
{
    8000534a:	1101                	addi	sp,sp,-32
    8000534c:	ec06                	sd	ra,24(sp)
    8000534e:	e822                	sd	s0,16(sp)
    80005350:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005352:	fe040613          	addi	a2,s0,-32
    80005356:	fec40593          	addi	a1,s0,-20
    8000535a:	4501                	li	a0,0
    8000535c:	00000097          	auipc	ra,0x0
    80005360:	cc2080e7          	jalr	-830(ra) # 8000501e <argfd>
    return -1;
    80005364:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005366:	02054463          	bltz	a0,8000538e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000536a:	ffffc097          	auipc	ra,0xffffc
    8000536e:	646080e7          	jalr	1606(ra) # 800019b0 <myproc>
    80005372:	fec42783          	lw	a5,-20(s0)
    80005376:	07e9                	addi	a5,a5,26
    80005378:	078e                	slli	a5,a5,0x3
    8000537a:	97aa                	add	a5,a5,a0
    8000537c:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005380:	fe043503          	ld	a0,-32(s0)
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	2b0080e7          	jalr	688(ra) # 80004634 <fileclose>
  return 0;
    8000538c:	4781                	li	a5,0
}
    8000538e:	853e                	mv	a0,a5
    80005390:	60e2                	ld	ra,24(sp)
    80005392:	6442                	ld	s0,16(sp)
    80005394:	6105                	addi	sp,sp,32
    80005396:	8082                	ret

0000000080005398 <sys_fstat>:
{
    80005398:	1101                	addi	sp,sp,-32
    8000539a:	ec06                	sd	ra,24(sp)
    8000539c:	e822                	sd	s0,16(sp)
    8000539e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053a0:	fe840613          	addi	a2,s0,-24
    800053a4:	4581                	li	a1,0
    800053a6:	4501                	li	a0,0
    800053a8:	00000097          	auipc	ra,0x0
    800053ac:	c76080e7          	jalr	-906(ra) # 8000501e <argfd>
    return -1;
    800053b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053b2:	02054563          	bltz	a0,800053dc <sys_fstat+0x44>
    800053b6:	fe040593          	addi	a1,s0,-32
    800053ba:	4505                	li	a0,1
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	83c080e7          	jalr	-1988(ra) # 80002bf8 <argaddr>
    return -1;
    800053c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c6:	00054b63          	bltz	a0,800053dc <sys_fstat+0x44>
  return filestat(f, st);
    800053ca:	fe043583          	ld	a1,-32(s0)
    800053ce:	fe843503          	ld	a0,-24(s0)
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	32a080e7          	jalr	810(ra) # 800046fc <filestat>
    800053da:	87aa                	mv	a5,a0
}
    800053dc:	853e                	mv	a0,a5
    800053de:	60e2                	ld	ra,24(sp)
    800053e0:	6442                	ld	s0,16(sp)
    800053e2:	6105                	addi	sp,sp,32
    800053e4:	8082                	ret

00000000800053e6 <sys_link>:
{
    800053e6:	7169                	addi	sp,sp,-304
    800053e8:	f606                	sd	ra,296(sp)
    800053ea:	f222                	sd	s0,288(sp)
    800053ec:	ee26                	sd	s1,280(sp)
    800053ee:	ea4a                	sd	s2,272(sp)
    800053f0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f2:	08000613          	li	a2,128
    800053f6:	ed040593          	addi	a1,s0,-304
    800053fa:	4501                	li	a0,0
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	81e080e7          	jalr	-2018(ra) # 80002c1a <argstr>
    return -1;
    80005404:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005406:	10054e63          	bltz	a0,80005522 <sys_link+0x13c>
    8000540a:	08000613          	li	a2,128
    8000540e:	f5040593          	addi	a1,s0,-176
    80005412:	4505                	li	a0,1
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	806080e7          	jalr	-2042(ra) # 80002c1a <argstr>
    return -1;
    8000541c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541e:	10054263          	bltz	a0,80005522 <sys_link+0x13c>
  begin_op();
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	d46080e7          	jalr	-698(ra) # 80004168 <begin_op>
  if((ip = namei(old)) == 0){
    8000542a:	ed040513          	addi	a0,s0,-304
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	b1e080e7          	jalr	-1250(ra) # 80003f4c <namei>
    80005436:	84aa                	mv	s1,a0
    80005438:	c551                	beqz	a0,800054c4 <sys_link+0xde>
  ilock(ip);
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	35c080e7          	jalr	860(ra) # 80003796 <ilock>
  if(ip->type == T_DIR){
    80005442:	04449703          	lh	a4,68(s1)
    80005446:	4785                	li	a5,1
    80005448:	08f70463          	beq	a4,a5,800054d0 <sys_link+0xea>
  ip->nlink++;
    8000544c:	04a4d783          	lhu	a5,74(s1)
    80005450:	2785                	addiw	a5,a5,1
    80005452:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005456:	8526                	mv	a0,s1
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	274080e7          	jalr	628(ra) # 800036cc <iupdate>
  iunlock(ip);
    80005460:	8526                	mv	a0,s1
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	3f6080e7          	jalr	1014(ra) # 80003858 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000546a:	fd040593          	addi	a1,s0,-48
    8000546e:	f5040513          	addi	a0,s0,-176
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	af8080e7          	jalr	-1288(ra) # 80003f6a <nameiparent>
    8000547a:	892a                	mv	s2,a0
    8000547c:	c935                	beqz	a0,800054f0 <sys_link+0x10a>
  ilock(dp);
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	318080e7          	jalr	792(ra) # 80003796 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005486:	00092703          	lw	a4,0(s2)
    8000548a:	409c                	lw	a5,0(s1)
    8000548c:	04f71d63          	bne	a4,a5,800054e6 <sys_link+0x100>
    80005490:	40d0                	lw	a2,4(s1)
    80005492:	fd040593          	addi	a1,s0,-48
    80005496:	854a                	mv	a0,s2
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	9f2080e7          	jalr	-1550(ra) # 80003e8a <dirlink>
    800054a0:	04054363          	bltz	a0,800054e6 <sys_link+0x100>
  iunlockput(dp);
    800054a4:	854a                	mv	a0,s2
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	552080e7          	jalr	1362(ra) # 800039f8 <iunlockput>
  iput(ip);
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	4a0080e7          	jalr	1184(ra) # 80003950 <iput>
  end_op();
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	d30080e7          	jalr	-720(ra) # 800041e8 <end_op>
  return 0;
    800054c0:	4781                	li	a5,0
    800054c2:	a085                	j	80005522 <sys_link+0x13c>
    end_op();
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	d24080e7          	jalr	-732(ra) # 800041e8 <end_op>
    return -1;
    800054cc:	57fd                	li	a5,-1
    800054ce:	a891                	j	80005522 <sys_link+0x13c>
    iunlockput(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	526080e7          	jalr	1318(ra) # 800039f8 <iunlockput>
    end_op();
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	d0e080e7          	jalr	-754(ra) # 800041e8 <end_op>
    return -1;
    800054e2:	57fd                	li	a5,-1
    800054e4:	a83d                	j	80005522 <sys_link+0x13c>
    iunlockput(dp);
    800054e6:	854a                	mv	a0,s2
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	510080e7          	jalr	1296(ra) # 800039f8 <iunlockput>
  ilock(ip);
    800054f0:	8526                	mv	a0,s1
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	2a4080e7          	jalr	676(ra) # 80003796 <ilock>
  ip->nlink--;
    800054fa:	04a4d783          	lhu	a5,74(s1)
    800054fe:	37fd                	addiw	a5,a5,-1
    80005500:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005504:	8526                	mv	a0,s1
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	1c6080e7          	jalr	454(ra) # 800036cc <iupdate>
  iunlockput(ip);
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	4e8080e7          	jalr	1256(ra) # 800039f8 <iunlockput>
  end_op();
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	cd0080e7          	jalr	-816(ra) # 800041e8 <end_op>
  return -1;
    80005520:	57fd                	li	a5,-1
}
    80005522:	853e                	mv	a0,a5
    80005524:	70b2                	ld	ra,296(sp)
    80005526:	7412                	ld	s0,288(sp)
    80005528:	64f2                	ld	s1,280(sp)
    8000552a:	6952                	ld	s2,272(sp)
    8000552c:	6155                	addi	sp,sp,304
    8000552e:	8082                	ret

0000000080005530 <sys_unlink>:
{
    80005530:	7151                	addi	sp,sp,-240
    80005532:	f586                	sd	ra,232(sp)
    80005534:	f1a2                	sd	s0,224(sp)
    80005536:	eda6                	sd	s1,216(sp)
    80005538:	e9ca                	sd	s2,208(sp)
    8000553a:	e5ce                	sd	s3,200(sp)
    8000553c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000553e:	08000613          	li	a2,128
    80005542:	f3040593          	addi	a1,s0,-208
    80005546:	4501                	li	a0,0
    80005548:	ffffd097          	auipc	ra,0xffffd
    8000554c:	6d2080e7          	jalr	1746(ra) # 80002c1a <argstr>
    80005550:	18054163          	bltz	a0,800056d2 <sys_unlink+0x1a2>
  begin_op();
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	c14080e7          	jalr	-1004(ra) # 80004168 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000555c:	fb040593          	addi	a1,s0,-80
    80005560:	f3040513          	addi	a0,s0,-208
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	a06080e7          	jalr	-1530(ra) # 80003f6a <nameiparent>
    8000556c:	84aa                	mv	s1,a0
    8000556e:	c979                	beqz	a0,80005644 <sys_unlink+0x114>
  ilock(dp);
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	226080e7          	jalr	550(ra) # 80003796 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005578:	00003597          	auipc	a1,0x3
    8000557c:	1d858593          	addi	a1,a1,472 # 80008750 <syscalls+0x2c0>
    80005580:	fb040513          	addi	a0,s0,-80
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	6dc080e7          	jalr	1756(ra) # 80003c60 <namecmp>
    8000558c:	14050a63          	beqz	a0,800056e0 <sys_unlink+0x1b0>
    80005590:	00003597          	auipc	a1,0x3
    80005594:	1c858593          	addi	a1,a1,456 # 80008758 <syscalls+0x2c8>
    80005598:	fb040513          	addi	a0,s0,-80
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	6c4080e7          	jalr	1732(ra) # 80003c60 <namecmp>
    800055a4:	12050e63          	beqz	a0,800056e0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055a8:	f2c40613          	addi	a2,s0,-212
    800055ac:	fb040593          	addi	a1,s0,-80
    800055b0:	8526                	mv	a0,s1
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	6c8080e7          	jalr	1736(ra) # 80003c7a <dirlookup>
    800055ba:	892a                	mv	s2,a0
    800055bc:	12050263          	beqz	a0,800056e0 <sys_unlink+0x1b0>
  ilock(ip);
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	1d6080e7          	jalr	470(ra) # 80003796 <ilock>
  if(ip->nlink < 1)
    800055c8:	04a91783          	lh	a5,74(s2)
    800055cc:	08f05263          	blez	a5,80005650 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055d0:	04491703          	lh	a4,68(s2)
    800055d4:	4785                	li	a5,1
    800055d6:	08f70563          	beq	a4,a5,80005660 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055da:	4641                	li	a2,16
    800055dc:	4581                	li	a1,0
    800055de:	fc040513          	addi	a0,s0,-64
    800055e2:	ffffb097          	auipc	ra,0xffffb
    800055e6:	6fe080e7          	jalr	1790(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ea:	4741                	li	a4,16
    800055ec:	f2c42683          	lw	a3,-212(s0)
    800055f0:	fc040613          	addi	a2,s0,-64
    800055f4:	4581                	li	a1,0
    800055f6:	8526                	mv	a0,s1
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	54a080e7          	jalr	1354(ra) # 80003b42 <writei>
    80005600:	47c1                	li	a5,16
    80005602:	0af51563          	bne	a0,a5,800056ac <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005606:	04491703          	lh	a4,68(s2)
    8000560a:	4785                	li	a5,1
    8000560c:	0af70863          	beq	a4,a5,800056bc <sys_unlink+0x18c>
  iunlockput(dp);
    80005610:	8526                	mv	a0,s1
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	3e6080e7          	jalr	998(ra) # 800039f8 <iunlockput>
  ip->nlink--;
    8000561a:	04a95783          	lhu	a5,74(s2)
    8000561e:	37fd                	addiw	a5,a5,-1
    80005620:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005624:	854a                	mv	a0,s2
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	0a6080e7          	jalr	166(ra) # 800036cc <iupdate>
  iunlockput(ip);
    8000562e:	854a                	mv	a0,s2
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	3c8080e7          	jalr	968(ra) # 800039f8 <iunlockput>
  end_op();
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	bb0080e7          	jalr	-1104(ra) # 800041e8 <end_op>
  return 0;
    80005640:	4501                	li	a0,0
    80005642:	a84d                	j	800056f4 <sys_unlink+0x1c4>
    end_op();
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	ba4080e7          	jalr	-1116(ra) # 800041e8 <end_op>
    return -1;
    8000564c:	557d                	li	a0,-1
    8000564e:	a05d                	j	800056f4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005650:	00003517          	auipc	a0,0x3
    80005654:	13050513          	addi	a0,a0,304 # 80008780 <syscalls+0x2f0>
    80005658:	ffffb097          	auipc	ra,0xffffb
    8000565c:	ee6080e7          	jalr	-282(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005660:	04c92703          	lw	a4,76(s2)
    80005664:	02000793          	li	a5,32
    80005668:	f6e7f9e3          	bgeu	a5,a4,800055da <sys_unlink+0xaa>
    8000566c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005670:	4741                	li	a4,16
    80005672:	86ce                	mv	a3,s3
    80005674:	f1840613          	addi	a2,s0,-232
    80005678:	4581                	li	a1,0
    8000567a:	854a                	mv	a0,s2
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	3ce080e7          	jalr	974(ra) # 80003a4a <readi>
    80005684:	47c1                	li	a5,16
    80005686:	00f51b63          	bne	a0,a5,8000569c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000568a:	f1845783          	lhu	a5,-232(s0)
    8000568e:	e7a1                	bnez	a5,800056d6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005690:	29c1                	addiw	s3,s3,16
    80005692:	04c92783          	lw	a5,76(s2)
    80005696:	fcf9ede3          	bltu	s3,a5,80005670 <sys_unlink+0x140>
    8000569a:	b781                	j	800055da <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000569c:	00003517          	auipc	a0,0x3
    800056a0:	0fc50513          	addi	a0,a0,252 # 80008798 <syscalls+0x308>
    800056a4:	ffffb097          	auipc	ra,0xffffb
    800056a8:	e9a080e7          	jalr	-358(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056ac:	00003517          	auipc	a0,0x3
    800056b0:	10450513          	addi	a0,a0,260 # 800087b0 <syscalls+0x320>
    800056b4:	ffffb097          	auipc	ra,0xffffb
    800056b8:	e8a080e7          	jalr	-374(ra) # 8000053e <panic>
    dp->nlink--;
    800056bc:	04a4d783          	lhu	a5,74(s1)
    800056c0:	37fd                	addiw	a5,a5,-1
    800056c2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	004080e7          	jalr	4(ra) # 800036cc <iupdate>
    800056d0:	b781                	j	80005610 <sys_unlink+0xe0>
    return -1;
    800056d2:	557d                	li	a0,-1
    800056d4:	a005                	j	800056f4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056d6:	854a                	mv	a0,s2
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	320080e7          	jalr	800(ra) # 800039f8 <iunlockput>
  iunlockput(dp);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	316080e7          	jalr	790(ra) # 800039f8 <iunlockput>
  end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	afe080e7          	jalr	-1282(ra) # 800041e8 <end_op>
  return -1;
    800056f2:	557d                	li	a0,-1
}
    800056f4:	70ae                	ld	ra,232(sp)
    800056f6:	740e                	ld	s0,224(sp)
    800056f8:	64ee                	ld	s1,216(sp)
    800056fa:	694e                	ld	s2,208(sp)
    800056fc:	69ae                	ld	s3,200(sp)
    800056fe:	616d                	addi	sp,sp,240
    80005700:	8082                	ret

0000000080005702 <sys_open>:

uint64
sys_open(void)
{
    80005702:	7131                	addi	sp,sp,-192
    80005704:	fd06                	sd	ra,184(sp)
    80005706:	f922                	sd	s0,176(sp)
    80005708:	f526                	sd	s1,168(sp)
    8000570a:	f14a                	sd	s2,160(sp)
    8000570c:	ed4e                	sd	s3,152(sp)
    8000570e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005710:	08000613          	li	a2,128
    80005714:	f5040593          	addi	a1,s0,-176
    80005718:	4501                	li	a0,0
    8000571a:	ffffd097          	auipc	ra,0xffffd
    8000571e:	500080e7          	jalr	1280(ra) # 80002c1a <argstr>
    return -1;
    80005722:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005724:	0c054163          	bltz	a0,800057e6 <sys_open+0xe4>
    80005728:	f4c40593          	addi	a1,s0,-180
    8000572c:	4505                	li	a0,1
    8000572e:	ffffd097          	auipc	ra,0xffffd
    80005732:	4a8080e7          	jalr	1192(ra) # 80002bd6 <argint>
    80005736:	0a054863          	bltz	a0,800057e6 <sys_open+0xe4>

  begin_op();
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	a2e080e7          	jalr	-1490(ra) # 80004168 <begin_op>

  if(omode & O_CREATE){
    80005742:	f4c42783          	lw	a5,-180(s0)
    80005746:	2007f793          	andi	a5,a5,512
    8000574a:	cbdd                	beqz	a5,80005800 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000574c:	4681                	li	a3,0
    8000574e:	4601                	li	a2,0
    80005750:	4589                	li	a1,2
    80005752:	f5040513          	addi	a0,s0,-176
    80005756:	00000097          	auipc	ra,0x0
    8000575a:	972080e7          	jalr	-1678(ra) # 800050c8 <create>
    8000575e:	892a                	mv	s2,a0
    if(ip == 0){
    80005760:	c959                	beqz	a0,800057f6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005762:	04491703          	lh	a4,68(s2)
    80005766:	478d                	li	a5,3
    80005768:	00f71763          	bne	a4,a5,80005776 <sys_open+0x74>
    8000576c:	04695703          	lhu	a4,70(s2)
    80005770:	47a5                	li	a5,9
    80005772:	0ce7ec63          	bltu	a5,a4,8000584a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	e02080e7          	jalr	-510(ra) # 80004578 <filealloc>
    8000577e:	89aa                	mv	s3,a0
    80005780:	10050263          	beqz	a0,80005884 <sys_open+0x182>
    80005784:	00000097          	auipc	ra,0x0
    80005788:	902080e7          	jalr	-1790(ra) # 80005086 <fdalloc>
    8000578c:	84aa                	mv	s1,a0
    8000578e:	0e054663          	bltz	a0,8000587a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005792:	04491703          	lh	a4,68(s2)
    80005796:	478d                	li	a5,3
    80005798:	0cf70463          	beq	a4,a5,80005860 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000579c:	4789                	li	a5,2
    8000579e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057a2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057a6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057aa:	f4c42783          	lw	a5,-180(s0)
    800057ae:	0017c713          	xori	a4,a5,1
    800057b2:	8b05                	andi	a4,a4,1
    800057b4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057b8:	0037f713          	andi	a4,a5,3
    800057bc:	00e03733          	snez	a4,a4
    800057c0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057c4:	4007f793          	andi	a5,a5,1024
    800057c8:	c791                	beqz	a5,800057d4 <sys_open+0xd2>
    800057ca:	04491703          	lh	a4,68(s2)
    800057ce:	4789                	li	a5,2
    800057d0:	08f70f63          	beq	a4,a5,8000586e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057d4:	854a                	mv	a0,s2
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	082080e7          	jalr	130(ra) # 80003858 <iunlock>
  end_op();
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	a0a080e7          	jalr	-1526(ra) # 800041e8 <end_op>

  return fd;
}
    800057e6:	8526                	mv	a0,s1
    800057e8:	70ea                	ld	ra,184(sp)
    800057ea:	744a                	ld	s0,176(sp)
    800057ec:	74aa                	ld	s1,168(sp)
    800057ee:	790a                	ld	s2,160(sp)
    800057f0:	69ea                	ld	s3,152(sp)
    800057f2:	6129                	addi	sp,sp,192
    800057f4:	8082                	ret
      end_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	9f2080e7          	jalr	-1550(ra) # 800041e8 <end_op>
      return -1;
    800057fe:	b7e5                	j	800057e6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005800:	f5040513          	addi	a0,s0,-176
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	748080e7          	jalr	1864(ra) # 80003f4c <namei>
    8000580c:	892a                	mv	s2,a0
    8000580e:	c905                	beqz	a0,8000583e <sys_open+0x13c>
    ilock(ip);
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	f86080e7          	jalr	-122(ra) # 80003796 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005818:	04491703          	lh	a4,68(s2)
    8000581c:	4785                	li	a5,1
    8000581e:	f4f712e3          	bne	a4,a5,80005762 <sys_open+0x60>
    80005822:	f4c42783          	lw	a5,-180(s0)
    80005826:	dba1                	beqz	a5,80005776 <sys_open+0x74>
      iunlockput(ip);
    80005828:	854a                	mv	a0,s2
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	1ce080e7          	jalr	462(ra) # 800039f8 <iunlockput>
      end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	9b6080e7          	jalr	-1610(ra) # 800041e8 <end_op>
      return -1;
    8000583a:	54fd                	li	s1,-1
    8000583c:	b76d                	j	800057e6 <sys_open+0xe4>
      end_op();
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	9aa080e7          	jalr	-1622(ra) # 800041e8 <end_op>
      return -1;
    80005846:	54fd                	li	s1,-1
    80005848:	bf79                	j	800057e6 <sys_open+0xe4>
    iunlockput(ip);
    8000584a:	854a                	mv	a0,s2
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	1ac080e7          	jalr	428(ra) # 800039f8 <iunlockput>
    end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	994080e7          	jalr	-1644(ra) # 800041e8 <end_op>
    return -1;
    8000585c:	54fd                	li	s1,-1
    8000585e:	b761                	j	800057e6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005860:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005864:	04691783          	lh	a5,70(s2)
    80005868:	02f99223          	sh	a5,36(s3)
    8000586c:	bf2d                	j	800057a6 <sys_open+0xa4>
    itrunc(ip);
    8000586e:	854a                	mv	a0,s2
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	034080e7          	jalr	52(ra) # 800038a4 <itrunc>
    80005878:	bfb1                	j	800057d4 <sys_open+0xd2>
      fileclose(f);
    8000587a:	854e                	mv	a0,s3
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	db8080e7          	jalr	-584(ra) # 80004634 <fileclose>
    iunlockput(ip);
    80005884:	854a                	mv	a0,s2
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	172080e7          	jalr	370(ra) # 800039f8 <iunlockput>
    end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	95a080e7          	jalr	-1702(ra) # 800041e8 <end_op>
    return -1;
    80005896:	54fd                	li	s1,-1
    80005898:	b7b9                	j	800057e6 <sys_open+0xe4>

000000008000589a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000589a:	7175                	addi	sp,sp,-144
    8000589c:	e506                	sd	ra,136(sp)
    8000589e:	e122                	sd	s0,128(sp)
    800058a0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	8c6080e7          	jalr	-1850(ra) # 80004168 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058aa:	08000613          	li	a2,128
    800058ae:	f7040593          	addi	a1,s0,-144
    800058b2:	4501                	li	a0,0
    800058b4:	ffffd097          	auipc	ra,0xffffd
    800058b8:	366080e7          	jalr	870(ra) # 80002c1a <argstr>
    800058bc:	02054963          	bltz	a0,800058ee <sys_mkdir+0x54>
    800058c0:	4681                	li	a3,0
    800058c2:	4601                	li	a2,0
    800058c4:	4585                	li	a1,1
    800058c6:	f7040513          	addi	a0,s0,-144
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	7fe080e7          	jalr	2046(ra) # 800050c8 <create>
    800058d2:	cd11                	beqz	a0,800058ee <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	124080e7          	jalr	292(ra) # 800039f8 <iunlockput>
  end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	90c080e7          	jalr	-1780(ra) # 800041e8 <end_op>
  return 0;
    800058e4:	4501                	li	a0,0
}
    800058e6:	60aa                	ld	ra,136(sp)
    800058e8:	640a                	ld	s0,128(sp)
    800058ea:	6149                	addi	sp,sp,144
    800058ec:	8082                	ret
    end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	8fa080e7          	jalr	-1798(ra) # 800041e8 <end_op>
    return -1;
    800058f6:	557d                	li	a0,-1
    800058f8:	b7fd                	j	800058e6 <sys_mkdir+0x4c>

00000000800058fa <sys_mknod>:

uint64
sys_mknod(void)
{
    800058fa:	7135                	addi	sp,sp,-160
    800058fc:	ed06                	sd	ra,152(sp)
    800058fe:	e922                	sd	s0,144(sp)
    80005900:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	866080e7          	jalr	-1946(ra) # 80004168 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000590a:	08000613          	li	a2,128
    8000590e:	f7040593          	addi	a1,s0,-144
    80005912:	4501                	li	a0,0
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	306080e7          	jalr	774(ra) # 80002c1a <argstr>
    8000591c:	04054a63          	bltz	a0,80005970 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005920:	f6c40593          	addi	a1,s0,-148
    80005924:	4505                	li	a0,1
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	2b0080e7          	jalr	688(ra) # 80002bd6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000592e:	04054163          	bltz	a0,80005970 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005932:	f6840593          	addi	a1,s0,-152
    80005936:	4509                	li	a0,2
    80005938:	ffffd097          	auipc	ra,0xffffd
    8000593c:	29e080e7          	jalr	670(ra) # 80002bd6 <argint>
     argint(1, &major) < 0 ||
    80005940:	02054863          	bltz	a0,80005970 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005944:	f6841683          	lh	a3,-152(s0)
    80005948:	f6c41603          	lh	a2,-148(s0)
    8000594c:	458d                	li	a1,3
    8000594e:	f7040513          	addi	a0,s0,-144
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	776080e7          	jalr	1910(ra) # 800050c8 <create>
     argint(2, &minor) < 0 ||
    8000595a:	c919                	beqz	a0,80005970 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	09c080e7          	jalr	156(ra) # 800039f8 <iunlockput>
  end_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	884080e7          	jalr	-1916(ra) # 800041e8 <end_op>
  return 0;
    8000596c:	4501                	li	a0,0
    8000596e:	a031                	j	8000597a <sys_mknod+0x80>
    end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	878080e7          	jalr	-1928(ra) # 800041e8 <end_op>
    return -1;
    80005978:	557d                	li	a0,-1
}
    8000597a:	60ea                	ld	ra,152(sp)
    8000597c:	644a                	ld	s0,144(sp)
    8000597e:	610d                	addi	sp,sp,160
    80005980:	8082                	ret

0000000080005982 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005982:	7135                	addi	sp,sp,-160
    80005984:	ed06                	sd	ra,152(sp)
    80005986:	e922                	sd	s0,144(sp)
    80005988:	e526                	sd	s1,136(sp)
    8000598a:	e14a                	sd	s2,128(sp)
    8000598c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000598e:	ffffc097          	auipc	ra,0xffffc
    80005992:	022080e7          	jalr	34(ra) # 800019b0 <myproc>
    80005996:	892a                	mv	s2,a0
  
  begin_op();
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	7d0080e7          	jalr	2000(ra) # 80004168 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059a0:	08000613          	li	a2,128
    800059a4:	f6040593          	addi	a1,s0,-160
    800059a8:	4501                	li	a0,0
    800059aa:	ffffd097          	auipc	ra,0xffffd
    800059ae:	270080e7          	jalr	624(ra) # 80002c1a <argstr>
    800059b2:	04054b63          	bltz	a0,80005a08 <sys_chdir+0x86>
    800059b6:	f6040513          	addi	a0,s0,-160
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	592080e7          	jalr	1426(ra) # 80003f4c <namei>
    800059c2:	84aa                	mv	s1,a0
    800059c4:	c131                	beqz	a0,80005a08 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	dd0080e7          	jalr	-560(ra) # 80003796 <ilock>
  if(ip->type != T_DIR){
    800059ce:	04449703          	lh	a4,68(s1)
    800059d2:	4785                	li	a5,1
    800059d4:	04f71063          	bne	a4,a5,80005a14 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059d8:	8526                	mv	a0,s1
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	e7e080e7          	jalr	-386(ra) # 80003858 <iunlock>
  iput(p->cwd);
    800059e2:	15893503          	ld	a0,344(s2)
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	f6a080e7          	jalr	-150(ra) # 80003950 <iput>
  end_op();
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	7fa080e7          	jalr	2042(ra) # 800041e8 <end_op>
  p->cwd = ip;
    800059f6:	14993c23          	sd	s1,344(s2)
  return 0;
    800059fa:	4501                	li	a0,0
}
    800059fc:	60ea                	ld	ra,152(sp)
    800059fe:	644a                	ld	s0,144(sp)
    80005a00:	64aa                	ld	s1,136(sp)
    80005a02:	690a                	ld	s2,128(sp)
    80005a04:	610d                	addi	sp,sp,160
    80005a06:	8082                	ret
    end_op();
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	7e0080e7          	jalr	2016(ra) # 800041e8 <end_op>
    return -1;
    80005a10:	557d                	li	a0,-1
    80005a12:	b7ed                	j	800059fc <sys_chdir+0x7a>
    iunlockput(ip);
    80005a14:	8526                	mv	a0,s1
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	fe2080e7          	jalr	-30(ra) # 800039f8 <iunlockput>
    end_op();
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	7ca080e7          	jalr	1994(ra) # 800041e8 <end_op>
    return -1;
    80005a26:	557d                	li	a0,-1
    80005a28:	bfd1                	j	800059fc <sys_chdir+0x7a>

0000000080005a2a <sys_exec>:

uint64
sys_exec(void)
{
    80005a2a:	7145                	addi	sp,sp,-464
    80005a2c:	e786                	sd	ra,456(sp)
    80005a2e:	e3a2                	sd	s0,448(sp)
    80005a30:	ff26                	sd	s1,440(sp)
    80005a32:	fb4a                	sd	s2,432(sp)
    80005a34:	f74e                	sd	s3,424(sp)
    80005a36:	f352                	sd	s4,416(sp)
    80005a38:	ef56                	sd	s5,408(sp)
    80005a3a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a3c:	08000613          	li	a2,128
    80005a40:	f4040593          	addi	a1,s0,-192
    80005a44:	4501                	li	a0,0
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	1d4080e7          	jalr	468(ra) # 80002c1a <argstr>
    return -1;
    80005a4e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a50:	0c054a63          	bltz	a0,80005b24 <sys_exec+0xfa>
    80005a54:	e3840593          	addi	a1,s0,-456
    80005a58:	4505                	li	a0,1
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	19e080e7          	jalr	414(ra) # 80002bf8 <argaddr>
    80005a62:	0c054163          	bltz	a0,80005b24 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a66:	10000613          	li	a2,256
    80005a6a:	4581                	li	a1,0
    80005a6c:	e4040513          	addi	a0,s0,-448
    80005a70:	ffffb097          	auipc	ra,0xffffb
    80005a74:	270080e7          	jalr	624(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a78:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a7c:	89a6                	mv	s3,s1
    80005a7e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a80:	02000a13          	li	s4,32
    80005a84:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a88:	00391513          	slli	a0,s2,0x3
    80005a8c:	e3040593          	addi	a1,s0,-464
    80005a90:	e3843783          	ld	a5,-456(s0)
    80005a94:	953e                	add	a0,a0,a5
    80005a96:	ffffd097          	auipc	ra,0xffffd
    80005a9a:	0a6080e7          	jalr	166(ra) # 80002b3c <fetchaddr>
    80005a9e:	02054a63          	bltz	a0,80005ad2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005aa2:	e3043783          	ld	a5,-464(s0)
    80005aa6:	c3b9                	beqz	a5,80005aec <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aa8:	ffffb097          	auipc	ra,0xffffb
    80005aac:	04c080e7          	jalr	76(ra) # 80000af4 <kalloc>
    80005ab0:	85aa                	mv	a1,a0
    80005ab2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ab6:	cd11                	beqz	a0,80005ad2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ab8:	6605                	lui	a2,0x1
    80005aba:	e3043503          	ld	a0,-464(s0)
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	0d0080e7          	jalr	208(ra) # 80002b8e <fetchstr>
    80005ac6:	00054663          	bltz	a0,80005ad2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005aca:	0905                	addi	s2,s2,1
    80005acc:	09a1                	addi	s3,s3,8
    80005ace:	fb491be3          	bne	s2,s4,80005a84 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ad2:	10048913          	addi	s2,s1,256
    80005ad6:	6088                	ld	a0,0(s1)
    80005ad8:	c529                	beqz	a0,80005b22 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ada:	ffffb097          	auipc	ra,0xffffb
    80005ade:	f1e080e7          	jalr	-226(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae2:	04a1                	addi	s1,s1,8
    80005ae4:	ff2499e3          	bne	s1,s2,80005ad6 <sys_exec+0xac>
  return -1;
    80005ae8:	597d                	li	s2,-1
    80005aea:	a82d                	j	80005b24 <sys_exec+0xfa>
      argv[i] = 0;
    80005aec:	0a8e                	slli	s5,s5,0x3
    80005aee:	fc040793          	addi	a5,s0,-64
    80005af2:	9abe                	add	s5,s5,a5
    80005af4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005af8:	e4040593          	addi	a1,s0,-448
    80005afc:	f4040513          	addi	a0,s0,-192
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	194080e7          	jalr	404(ra) # 80004c94 <exec>
    80005b08:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b0a:	10048993          	addi	s3,s1,256
    80005b0e:	6088                	ld	a0,0(s1)
    80005b10:	c911                	beqz	a0,80005b24 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b12:	ffffb097          	auipc	ra,0xffffb
    80005b16:	ee6080e7          	jalr	-282(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1a:	04a1                	addi	s1,s1,8
    80005b1c:	ff3499e3          	bne	s1,s3,80005b0e <sys_exec+0xe4>
    80005b20:	a011                	j	80005b24 <sys_exec+0xfa>
  return -1;
    80005b22:	597d                	li	s2,-1
}
    80005b24:	854a                	mv	a0,s2
    80005b26:	60be                	ld	ra,456(sp)
    80005b28:	641e                	ld	s0,448(sp)
    80005b2a:	74fa                	ld	s1,440(sp)
    80005b2c:	795a                	ld	s2,432(sp)
    80005b2e:	79ba                	ld	s3,424(sp)
    80005b30:	7a1a                	ld	s4,416(sp)
    80005b32:	6afa                	ld	s5,408(sp)
    80005b34:	6179                	addi	sp,sp,464
    80005b36:	8082                	ret

0000000080005b38 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b38:	7139                	addi	sp,sp,-64
    80005b3a:	fc06                	sd	ra,56(sp)
    80005b3c:	f822                	sd	s0,48(sp)
    80005b3e:	f426                	sd	s1,40(sp)
    80005b40:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b42:	ffffc097          	auipc	ra,0xffffc
    80005b46:	e6e080e7          	jalr	-402(ra) # 800019b0 <myproc>
    80005b4a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b4c:	fd840593          	addi	a1,s0,-40
    80005b50:	4501                	li	a0,0
    80005b52:	ffffd097          	auipc	ra,0xffffd
    80005b56:	0a6080e7          	jalr	166(ra) # 80002bf8 <argaddr>
    return -1;
    80005b5a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b5c:	0e054063          	bltz	a0,80005c3c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b60:	fc840593          	addi	a1,s0,-56
    80005b64:	fd040513          	addi	a0,s0,-48
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	dfc080e7          	jalr	-516(ra) # 80004964 <pipealloc>
    return -1;
    80005b70:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b72:	0c054563          	bltz	a0,80005c3c <sys_pipe+0x104>
  fd0 = -1;
    80005b76:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b7a:	fd043503          	ld	a0,-48(s0)
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	508080e7          	jalr	1288(ra) # 80005086 <fdalloc>
    80005b86:	fca42223          	sw	a0,-60(s0)
    80005b8a:	08054c63          	bltz	a0,80005c22 <sys_pipe+0xea>
    80005b8e:	fc843503          	ld	a0,-56(s0)
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	4f4080e7          	jalr	1268(ra) # 80005086 <fdalloc>
    80005b9a:	fca42023          	sw	a0,-64(s0)
    80005b9e:	06054863          	bltz	a0,80005c0e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ba2:	4691                	li	a3,4
    80005ba4:	fc440613          	addi	a2,s0,-60
    80005ba8:	fd843583          	ld	a1,-40(s0)
    80005bac:	6ca8                	ld	a0,88(s1)
    80005bae:	ffffc097          	auipc	ra,0xffffc
    80005bb2:	ac4080e7          	jalr	-1340(ra) # 80001672 <copyout>
    80005bb6:	02054063          	bltz	a0,80005bd6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bba:	4691                	li	a3,4
    80005bbc:	fc040613          	addi	a2,s0,-64
    80005bc0:	fd843583          	ld	a1,-40(s0)
    80005bc4:	0591                	addi	a1,a1,4
    80005bc6:	6ca8                	ld	a0,88(s1)
    80005bc8:	ffffc097          	auipc	ra,0xffffc
    80005bcc:	aaa080e7          	jalr	-1366(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bd0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bd2:	06055563          	bgez	a0,80005c3c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bd6:	fc442783          	lw	a5,-60(s0)
    80005bda:	07e9                	addi	a5,a5,26
    80005bdc:	078e                	slli	a5,a5,0x3
    80005bde:	97a6                	add	a5,a5,s1
    80005be0:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005be4:	fc042503          	lw	a0,-64(s0)
    80005be8:	0569                	addi	a0,a0,26
    80005bea:	050e                	slli	a0,a0,0x3
    80005bec:	9526                	add	a0,a0,s1
    80005bee:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005bf2:	fd043503          	ld	a0,-48(s0)
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	a3e080e7          	jalr	-1474(ra) # 80004634 <fileclose>
    fileclose(wf);
    80005bfe:	fc843503          	ld	a0,-56(s0)
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	a32080e7          	jalr	-1486(ra) # 80004634 <fileclose>
    return -1;
    80005c0a:	57fd                	li	a5,-1
    80005c0c:	a805                	j	80005c3c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c0e:	fc442783          	lw	a5,-60(s0)
    80005c12:	0007c863          	bltz	a5,80005c22 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c16:	01a78513          	addi	a0,a5,26
    80005c1a:	050e                	slli	a0,a0,0x3
    80005c1c:	9526                	add	a0,a0,s1
    80005c1e:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005c22:	fd043503          	ld	a0,-48(s0)
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	a0e080e7          	jalr	-1522(ra) # 80004634 <fileclose>
    fileclose(wf);
    80005c2e:	fc843503          	ld	a0,-56(s0)
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	a02080e7          	jalr	-1534(ra) # 80004634 <fileclose>
    return -1;
    80005c3a:	57fd                	li	a5,-1
}
    80005c3c:	853e                	mv	a0,a5
    80005c3e:	70e2                	ld	ra,56(sp)
    80005c40:	7442                	ld	s0,48(sp)
    80005c42:	74a2                	ld	s1,40(sp)
    80005c44:	6121                	addi	sp,sp,64
    80005c46:	8082                	ret
	...

0000000080005c50 <kernelvec>:
    80005c50:	7111                	addi	sp,sp,-256
    80005c52:	e006                	sd	ra,0(sp)
    80005c54:	e40a                	sd	sp,8(sp)
    80005c56:	e80e                	sd	gp,16(sp)
    80005c58:	ec12                	sd	tp,24(sp)
    80005c5a:	f016                	sd	t0,32(sp)
    80005c5c:	f41a                	sd	t1,40(sp)
    80005c5e:	f81e                	sd	t2,48(sp)
    80005c60:	fc22                	sd	s0,56(sp)
    80005c62:	e0a6                	sd	s1,64(sp)
    80005c64:	e4aa                	sd	a0,72(sp)
    80005c66:	e8ae                	sd	a1,80(sp)
    80005c68:	ecb2                	sd	a2,88(sp)
    80005c6a:	f0b6                	sd	a3,96(sp)
    80005c6c:	f4ba                	sd	a4,104(sp)
    80005c6e:	f8be                	sd	a5,112(sp)
    80005c70:	fcc2                	sd	a6,120(sp)
    80005c72:	e146                	sd	a7,128(sp)
    80005c74:	e54a                	sd	s2,136(sp)
    80005c76:	e94e                	sd	s3,144(sp)
    80005c78:	ed52                	sd	s4,152(sp)
    80005c7a:	f156                	sd	s5,160(sp)
    80005c7c:	f55a                	sd	s6,168(sp)
    80005c7e:	f95e                	sd	s7,176(sp)
    80005c80:	fd62                	sd	s8,184(sp)
    80005c82:	e1e6                	sd	s9,192(sp)
    80005c84:	e5ea                	sd	s10,200(sp)
    80005c86:	e9ee                	sd	s11,208(sp)
    80005c88:	edf2                	sd	t3,216(sp)
    80005c8a:	f1f6                	sd	t4,224(sp)
    80005c8c:	f5fa                	sd	t5,232(sp)
    80005c8e:	f9fe                	sd	t6,240(sp)
    80005c90:	d79fc0ef          	jal	ra,80002a08 <kerneltrap>
    80005c94:	6082                	ld	ra,0(sp)
    80005c96:	6122                	ld	sp,8(sp)
    80005c98:	61c2                	ld	gp,16(sp)
    80005c9a:	7282                	ld	t0,32(sp)
    80005c9c:	7322                	ld	t1,40(sp)
    80005c9e:	73c2                	ld	t2,48(sp)
    80005ca0:	7462                	ld	s0,56(sp)
    80005ca2:	6486                	ld	s1,64(sp)
    80005ca4:	6526                	ld	a0,72(sp)
    80005ca6:	65c6                	ld	a1,80(sp)
    80005ca8:	6666                	ld	a2,88(sp)
    80005caa:	7686                	ld	a3,96(sp)
    80005cac:	7726                	ld	a4,104(sp)
    80005cae:	77c6                	ld	a5,112(sp)
    80005cb0:	7866                	ld	a6,120(sp)
    80005cb2:	688a                	ld	a7,128(sp)
    80005cb4:	692a                	ld	s2,136(sp)
    80005cb6:	69ca                	ld	s3,144(sp)
    80005cb8:	6a6a                	ld	s4,152(sp)
    80005cba:	7a8a                	ld	s5,160(sp)
    80005cbc:	7b2a                	ld	s6,168(sp)
    80005cbe:	7bca                	ld	s7,176(sp)
    80005cc0:	7c6a                	ld	s8,184(sp)
    80005cc2:	6c8e                	ld	s9,192(sp)
    80005cc4:	6d2e                	ld	s10,200(sp)
    80005cc6:	6dce                	ld	s11,208(sp)
    80005cc8:	6e6e                	ld	t3,216(sp)
    80005cca:	7e8e                	ld	t4,224(sp)
    80005ccc:	7f2e                	ld	t5,232(sp)
    80005cce:	7fce                	ld	t6,240(sp)
    80005cd0:	6111                	addi	sp,sp,256
    80005cd2:	10200073          	sret
    80005cd6:	00000013          	nop
    80005cda:	00000013          	nop
    80005cde:	0001                	nop

0000000080005ce0 <timervec>:
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	e10c                	sd	a1,0(a0)
    80005ce6:	e510                	sd	a2,8(a0)
    80005ce8:	e914                	sd	a3,16(a0)
    80005cea:	6d0c                	ld	a1,24(a0)
    80005cec:	7110                	ld	a2,32(a0)
    80005cee:	6194                	ld	a3,0(a1)
    80005cf0:	96b2                	add	a3,a3,a2
    80005cf2:	e194                	sd	a3,0(a1)
    80005cf4:	4589                	li	a1,2
    80005cf6:	14459073          	csrw	sip,a1
    80005cfa:	6914                	ld	a3,16(a0)
    80005cfc:	6510                	ld	a2,8(a0)
    80005cfe:	610c                	ld	a1,0(a0)
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	30200073          	mret
	...

0000000080005d0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d0a:	1141                	addi	sp,sp,-16
    80005d0c:	e422                	sd	s0,8(sp)
    80005d0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d10:	0c0007b7          	lui	a5,0xc000
    80005d14:	4705                	li	a4,1
    80005d16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d18:	c3d8                	sw	a4,4(a5)
}
    80005d1a:	6422                	ld	s0,8(sp)
    80005d1c:	0141                	addi	sp,sp,16
    80005d1e:	8082                	ret

0000000080005d20 <plicinithart>:

void
plicinithart(void)
{
    80005d20:	1141                	addi	sp,sp,-16
    80005d22:	e406                	sd	ra,8(sp)
    80005d24:	e022                	sd	s0,0(sp)
    80005d26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	c5c080e7          	jalr	-932(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d30:	0085171b          	slliw	a4,a0,0x8
    80005d34:	0c0027b7          	lui	a5,0xc002
    80005d38:	97ba                	add	a5,a5,a4
    80005d3a:	40200713          	li	a4,1026
    80005d3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d42:	00d5151b          	slliw	a0,a0,0xd
    80005d46:	0c2017b7          	lui	a5,0xc201
    80005d4a:	953e                	add	a0,a0,a5
    80005d4c:	00052023          	sw	zero,0(a0)
}
    80005d50:	60a2                	ld	ra,8(sp)
    80005d52:	6402                	ld	s0,0(sp)
    80005d54:	0141                	addi	sp,sp,16
    80005d56:	8082                	ret

0000000080005d58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d58:	1141                	addi	sp,sp,-16
    80005d5a:	e406                	sd	ra,8(sp)
    80005d5c:	e022                	sd	s0,0(sp)
    80005d5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d60:	ffffc097          	auipc	ra,0xffffc
    80005d64:	c24080e7          	jalr	-988(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d68:	00d5179b          	slliw	a5,a0,0xd
    80005d6c:	0c201537          	lui	a0,0xc201
    80005d70:	953e                	add	a0,a0,a5
  return irq;
}
    80005d72:	4148                	lw	a0,4(a0)
    80005d74:	60a2                	ld	ra,8(sp)
    80005d76:	6402                	ld	s0,0(sp)
    80005d78:	0141                	addi	sp,sp,16
    80005d7a:	8082                	ret

0000000080005d7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d7c:	1101                	addi	sp,sp,-32
    80005d7e:	ec06                	sd	ra,24(sp)
    80005d80:	e822                	sd	s0,16(sp)
    80005d82:	e426                	sd	s1,8(sp)
    80005d84:	1000                	addi	s0,sp,32
    80005d86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	bfc080e7          	jalr	-1028(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d90:	00d5151b          	slliw	a0,a0,0xd
    80005d94:	0c2017b7          	lui	a5,0xc201
    80005d98:	97aa                	add	a5,a5,a0
    80005d9a:	c3c4                	sw	s1,4(a5)
}
    80005d9c:	60e2                	ld	ra,24(sp)
    80005d9e:	6442                	ld	s0,16(sp)
    80005da0:	64a2                	ld	s1,8(sp)
    80005da2:	6105                	addi	sp,sp,32
    80005da4:	8082                	ret

0000000080005da6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005da6:	1141                	addi	sp,sp,-16
    80005da8:	e406                	sd	ra,8(sp)
    80005daa:	e022                	sd	s0,0(sp)
    80005dac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dae:	479d                	li	a5,7
    80005db0:	06a7c963          	blt	a5,a0,80005e22 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005db4:	0001d797          	auipc	a5,0x1d
    80005db8:	24c78793          	addi	a5,a5,588 # 80023000 <disk>
    80005dbc:	00a78733          	add	a4,a5,a0
    80005dc0:	6789                	lui	a5,0x2
    80005dc2:	97ba                	add	a5,a5,a4
    80005dc4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dc8:	e7ad                	bnez	a5,80005e32 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dca:	00451793          	slli	a5,a0,0x4
    80005dce:	0001f717          	auipc	a4,0x1f
    80005dd2:	23270713          	addi	a4,a4,562 # 80025000 <disk+0x2000>
    80005dd6:	6314                	ld	a3,0(a4)
    80005dd8:	96be                	add	a3,a3,a5
    80005dda:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dde:	6314                	ld	a3,0(a4)
    80005de0:	96be                	add	a3,a3,a5
    80005de2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005de6:	6314                	ld	a3,0(a4)
    80005de8:	96be                	add	a3,a3,a5
    80005dea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005dee:	6318                	ld	a4,0(a4)
    80005df0:	97ba                	add	a5,a5,a4
    80005df2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005df6:	0001d797          	auipc	a5,0x1d
    80005dfa:	20a78793          	addi	a5,a5,522 # 80023000 <disk>
    80005dfe:	97aa                	add	a5,a5,a0
    80005e00:	6509                	lui	a0,0x2
    80005e02:	953e                	add	a0,a0,a5
    80005e04:	4785                	li	a5,1
    80005e06:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e0a:	0001f517          	auipc	a0,0x1f
    80005e0e:	20e50513          	addi	a0,a0,526 # 80025018 <disk+0x2018>
    80005e12:	ffffc097          	auipc	ra,0xffffc
    80005e16:	47a080e7          	jalr	1146(ra) # 8000228c <wakeup>
}
    80005e1a:	60a2                	ld	ra,8(sp)
    80005e1c:	6402                	ld	s0,0(sp)
    80005e1e:	0141                	addi	sp,sp,16
    80005e20:	8082                	ret
    panic("free_desc 1");
    80005e22:	00003517          	auipc	a0,0x3
    80005e26:	99e50513          	addi	a0,a0,-1634 # 800087c0 <syscalls+0x330>
    80005e2a:	ffffa097          	auipc	ra,0xffffa
    80005e2e:	714080e7          	jalr	1812(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e32:	00003517          	auipc	a0,0x3
    80005e36:	99e50513          	addi	a0,a0,-1634 # 800087d0 <syscalls+0x340>
    80005e3a:	ffffa097          	auipc	ra,0xffffa
    80005e3e:	704080e7          	jalr	1796(ra) # 8000053e <panic>

0000000080005e42 <virtio_disk_init>:
{
    80005e42:	1101                	addi	sp,sp,-32
    80005e44:	ec06                	sd	ra,24(sp)
    80005e46:	e822                	sd	s0,16(sp)
    80005e48:	e426                	sd	s1,8(sp)
    80005e4a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e4c:	00003597          	auipc	a1,0x3
    80005e50:	99458593          	addi	a1,a1,-1644 # 800087e0 <syscalls+0x350>
    80005e54:	0001f517          	auipc	a0,0x1f
    80005e58:	2d450513          	addi	a0,a0,724 # 80025128 <disk+0x2128>
    80005e5c:	ffffb097          	auipc	ra,0xffffb
    80005e60:	cf8080e7          	jalr	-776(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e64:	100017b7          	lui	a5,0x10001
    80005e68:	4398                	lw	a4,0(a5)
    80005e6a:	2701                	sext.w	a4,a4
    80005e6c:	747277b7          	lui	a5,0x74727
    80005e70:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e74:	0ef71163          	bne	a4,a5,80005f56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e78:	100017b7          	lui	a5,0x10001
    80005e7c:	43dc                	lw	a5,4(a5)
    80005e7e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e80:	4705                	li	a4,1
    80005e82:	0ce79a63          	bne	a5,a4,80005f56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e86:	100017b7          	lui	a5,0x10001
    80005e8a:	479c                	lw	a5,8(a5)
    80005e8c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e8e:	4709                	li	a4,2
    80005e90:	0ce79363          	bne	a5,a4,80005f56 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e94:	100017b7          	lui	a5,0x10001
    80005e98:	47d8                	lw	a4,12(a5)
    80005e9a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e9c:	554d47b7          	lui	a5,0x554d4
    80005ea0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ea4:	0af71963          	bne	a4,a5,80005f56 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea8:	100017b7          	lui	a5,0x10001
    80005eac:	4705                	li	a4,1
    80005eae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb0:	470d                	li	a4,3
    80005eb2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eb4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005eb6:	c7ffe737          	lui	a4,0xc7ffe
    80005eba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ebe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ec0:	2701                	sext.w	a4,a4
    80005ec2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec4:	472d                	li	a4,11
    80005ec6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec8:	473d                	li	a4,15
    80005eca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ecc:	6705                	lui	a4,0x1
    80005ece:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ed0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ed4:	5bdc                	lw	a5,52(a5)
    80005ed6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ed8:	c7d9                	beqz	a5,80005f66 <virtio_disk_init+0x124>
  if(max < NUM)
    80005eda:	471d                	li	a4,7
    80005edc:	08f77d63          	bgeu	a4,a5,80005f76 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ee0:	100014b7          	lui	s1,0x10001
    80005ee4:	47a1                	li	a5,8
    80005ee6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ee8:	6609                	lui	a2,0x2
    80005eea:	4581                	li	a1,0
    80005eec:	0001d517          	auipc	a0,0x1d
    80005ef0:	11450513          	addi	a0,a0,276 # 80023000 <disk>
    80005ef4:	ffffb097          	auipc	ra,0xffffb
    80005ef8:	dec080e7          	jalr	-532(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005efc:	0001d717          	auipc	a4,0x1d
    80005f00:	10470713          	addi	a4,a4,260 # 80023000 <disk>
    80005f04:	00c75793          	srli	a5,a4,0xc
    80005f08:	2781                	sext.w	a5,a5
    80005f0a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f0c:	0001f797          	auipc	a5,0x1f
    80005f10:	0f478793          	addi	a5,a5,244 # 80025000 <disk+0x2000>
    80005f14:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f16:	0001d717          	auipc	a4,0x1d
    80005f1a:	16a70713          	addi	a4,a4,362 # 80023080 <disk+0x80>
    80005f1e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f20:	0001e717          	auipc	a4,0x1e
    80005f24:	0e070713          	addi	a4,a4,224 # 80024000 <disk+0x1000>
    80005f28:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f2a:	4705                	li	a4,1
    80005f2c:	00e78c23          	sb	a4,24(a5)
    80005f30:	00e78ca3          	sb	a4,25(a5)
    80005f34:	00e78d23          	sb	a4,26(a5)
    80005f38:	00e78da3          	sb	a4,27(a5)
    80005f3c:	00e78e23          	sb	a4,28(a5)
    80005f40:	00e78ea3          	sb	a4,29(a5)
    80005f44:	00e78f23          	sb	a4,30(a5)
    80005f48:	00e78fa3          	sb	a4,31(a5)
}
    80005f4c:	60e2                	ld	ra,24(sp)
    80005f4e:	6442                	ld	s0,16(sp)
    80005f50:	64a2                	ld	s1,8(sp)
    80005f52:	6105                	addi	sp,sp,32
    80005f54:	8082                	ret
    panic("could not find virtio disk");
    80005f56:	00003517          	auipc	a0,0x3
    80005f5a:	89a50513          	addi	a0,a0,-1894 # 800087f0 <syscalls+0x360>
    80005f5e:	ffffa097          	auipc	ra,0xffffa
    80005f62:	5e0080e7          	jalr	1504(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f66:	00003517          	auipc	a0,0x3
    80005f6a:	8aa50513          	addi	a0,a0,-1878 # 80008810 <syscalls+0x380>
    80005f6e:	ffffa097          	auipc	ra,0xffffa
    80005f72:	5d0080e7          	jalr	1488(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f76:	00003517          	auipc	a0,0x3
    80005f7a:	8ba50513          	addi	a0,a0,-1862 # 80008830 <syscalls+0x3a0>
    80005f7e:	ffffa097          	auipc	ra,0xffffa
    80005f82:	5c0080e7          	jalr	1472(ra) # 8000053e <panic>

0000000080005f86 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f86:	7159                	addi	sp,sp,-112
    80005f88:	f486                	sd	ra,104(sp)
    80005f8a:	f0a2                	sd	s0,96(sp)
    80005f8c:	eca6                	sd	s1,88(sp)
    80005f8e:	e8ca                	sd	s2,80(sp)
    80005f90:	e4ce                	sd	s3,72(sp)
    80005f92:	e0d2                	sd	s4,64(sp)
    80005f94:	fc56                	sd	s5,56(sp)
    80005f96:	f85a                	sd	s6,48(sp)
    80005f98:	f45e                	sd	s7,40(sp)
    80005f9a:	f062                	sd	s8,32(sp)
    80005f9c:	ec66                	sd	s9,24(sp)
    80005f9e:	e86a                	sd	s10,16(sp)
    80005fa0:	1880                	addi	s0,sp,112
    80005fa2:	892a                	mv	s2,a0
    80005fa4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fa6:	00c52c83          	lw	s9,12(a0)
    80005faa:	001c9c9b          	slliw	s9,s9,0x1
    80005fae:	1c82                	slli	s9,s9,0x20
    80005fb0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fb4:	0001f517          	auipc	a0,0x1f
    80005fb8:	17450513          	addi	a0,a0,372 # 80025128 <disk+0x2128>
    80005fbc:	ffffb097          	auipc	ra,0xffffb
    80005fc0:	c28080e7          	jalr	-984(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005fc4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fc6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fc8:	0001db97          	auipc	s7,0x1d
    80005fcc:	038b8b93          	addi	s7,s7,56 # 80023000 <disk>
    80005fd0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fd2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fd4:	8a4e                	mv	s4,s3
    80005fd6:	a051                	j	8000605a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fd8:	00fb86b3          	add	a3,s7,a5
    80005fdc:	96da                	add	a3,a3,s6
    80005fde:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fe2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fe4:	0207c563          	bltz	a5,8000600e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fe8:	2485                	addiw	s1,s1,1
    80005fea:	0711                	addi	a4,a4,4
    80005fec:	25548063          	beq	s1,s5,8000622c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005ff0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ff2:	0001f697          	auipc	a3,0x1f
    80005ff6:	02668693          	addi	a3,a3,38 # 80025018 <disk+0x2018>
    80005ffa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005ffc:	0006c583          	lbu	a1,0(a3)
    80006000:	fde1                	bnez	a1,80005fd8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006002:	2785                	addiw	a5,a5,1
    80006004:	0685                	addi	a3,a3,1
    80006006:	ff879be3          	bne	a5,s8,80005ffc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000600a:	57fd                	li	a5,-1
    8000600c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000600e:	02905a63          	blez	s1,80006042 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006012:	f9042503          	lw	a0,-112(s0)
    80006016:	00000097          	auipc	ra,0x0
    8000601a:	d90080e7          	jalr	-624(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    8000601e:	4785                	li	a5,1
    80006020:	0297d163          	bge	a5,s1,80006042 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006024:	f9442503          	lw	a0,-108(s0)
    80006028:	00000097          	auipc	ra,0x0
    8000602c:	d7e080e7          	jalr	-642(ra) # 80005da6 <free_desc>
      for(int j = 0; j < i; j++)
    80006030:	4789                	li	a5,2
    80006032:	0097d863          	bge	a5,s1,80006042 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006036:	f9842503          	lw	a0,-104(s0)
    8000603a:	00000097          	auipc	ra,0x0
    8000603e:	d6c080e7          	jalr	-660(ra) # 80005da6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006042:	0001f597          	auipc	a1,0x1f
    80006046:	0e658593          	addi	a1,a1,230 # 80025128 <disk+0x2128>
    8000604a:	0001f517          	auipc	a0,0x1f
    8000604e:	fce50513          	addi	a0,a0,-50 # 80025018 <disk+0x2018>
    80006052:	ffffc097          	auipc	ra,0xffffc
    80006056:	0ae080e7          	jalr	174(ra) # 80002100 <sleep>
  for(int i = 0; i < 3; i++){
    8000605a:	f9040713          	addi	a4,s0,-112
    8000605e:	84ce                	mv	s1,s3
    80006060:	bf41                	j	80005ff0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006062:	20058713          	addi	a4,a1,512
    80006066:	00471693          	slli	a3,a4,0x4
    8000606a:	0001d717          	auipc	a4,0x1d
    8000606e:	f9670713          	addi	a4,a4,-106 # 80023000 <disk>
    80006072:	9736                	add	a4,a4,a3
    80006074:	4685                	li	a3,1
    80006076:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000607a:	20058713          	addi	a4,a1,512
    8000607e:	00471693          	slli	a3,a4,0x4
    80006082:	0001d717          	auipc	a4,0x1d
    80006086:	f7e70713          	addi	a4,a4,-130 # 80023000 <disk>
    8000608a:	9736                	add	a4,a4,a3
    8000608c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006090:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006094:	7679                	lui	a2,0xffffe
    80006096:	963e                	add	a2,a2,a5
    80006098:	0001f697          	auipc	a3,0x1f
    8000609c:	f6868693          	addi	a3,a3,-152 # 80025000 <disk+0x2000>
    800060a0:	6298                	ld	a4,0(a3)
    800060a2:	9732                	add	a4,a4,a2
    800060a4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060a6:	6298                	ld	a4,0(a3)
    800060a8:	9732                	add	a4,a4,a2
    800060aa:	4541                	li	a0,16
    800060ac:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060ae:	6298                	ld	a4,0(a3)
    800060b0:	9732                	add	a4,a4,a2
    800060b2:	4505                	li	a0,1
    800060b4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060b8:	f9442703          	lw	a4,-108(s0)
    800060bc:	6288                	ld	a0,0(a3)
    800060be:	962a                	add	a2,a2,a0
    800060c0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060c4:	0712                	slli	a4,a4,0x4
    800060c6:	6290                	ld	a2,0(a3)
    800060c8:	963a                	add	a2,a2,a4
    800060ca:	05890513          	addi	a0,s2,88
    800060ce:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800060d0:	6294                	ld	a3,0(a3)
    800060d2:	96ba                	add	a3,a3,a4
    800060d4:	40000613          	li	a2,1024
    800060d8:	c690                	sw	a2,8(a3)
  if(write)
    800060da:	140d0063          	beqz	s10,8000621a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060de:	0001f697          	auipc	a3,0x1f
    800060e2:	f226b683          	ld	a3,-222(a3) # 80025000 <disk+0x2000>
    800060e6:	96ba                	add	a3,a3,a4
    800060e8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060ec:	0001d817          	auipc	a6,0x1d
    800060f0:	f1480813          	addi	a6,a6,-236 # 80023000 <disk>
    800060f4:	0001f517          	auipc	a0,0x1f
    800060f8:	f0c50513          	addi	a0,a0,-244 # 80025000 <disk+0x2000>
    800060fc:	6114                	ld	a3,0(a0)
    800060fe:	96ba                	add	a3,a3,a4
    80006100:	00c6d603          	lhu	a2,12(a3)
    80006104:	00166613          	ori	a2,a2,1
    80006108:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000610c:	f9842683          	lw	a3,-104(s0)
    80006110:	6110                	ld	a2,0(a0)
    80006112:	9732                	add	a4,a4,a2
    80006114:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006118:	20058613          	addi	a2,a1,512
    8000611c:	0612                	slli	a2,a2,0x4
    8000611e:	9642                	add	a2,a2,a6
    80006120:	577d                	li	a4,-1
    80006122:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006126:	00469713          	slli	a4,a3,0x4
    8000612a:	6114                	ld	a3,0(a0)
    8000612c:	96ba                	add	a3,a3,a4
    8000612e:	03078793          	addi	a5,a5,48
    80006132:	97c2                	add	a5,a5,a6
    80006134:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006136:	611c                	ld	a5,0(a0)
    80006138:	97ba                	add	a5,a5,a4
    8000613a:	4685                	li	a3,1
    8000613c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000613e:	611c                	ld	a5,0(a0)
    80006140:	97ba                	add	a5,a5,a4
    80006142:	4809                	li	a6,2
    80006144:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006148:	611c                	ld	a5,0(a0)
    8000614a:	973e                	add	a4,a4,a5
    8000614c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006150:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006154:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006158:	6518                	ld	a4,8(a0)
    8000615a:	00275783          	lhu	a5,2(a4)
    8000615e:	8b9d                	andi	a5,a5,7
    80006160:	0786                	slli	a5,a5,0x1
    80006162:	97ba                	add	a5,a5,a4
    80006164:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006168:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000616c:	6518                	ld	a4,8(a0)
    8000616e:	00275783          	lhu	a5,2(a4)
    80006172:	2785                	addiw	a5,a5,1
    80006174:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006178:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000617c:	100017b7          	lui	a5,0x10001
    80006180:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006184:	00492703          	lw	a4,4(s2)
    80006188:	4785                	li	a5,1
    8000618a:	02f71163          	bne	a4,a5,800061ac <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000618e:	0001f997          	auipc	s3,0x1f
    80006192:	f9a98993          	addi	s3,s3,-102 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006196:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006198:	85ce                	mv	a1,s3
    8000619a:	854a                	mv	a0,s2
    8000619c:	ffffc097          	auipc	ra,0xffffc
    800061a0:	f64080e7          	jalr	-156(ra) # 80002100 <sleep>
  while(b->disk == 1) {
    800061a4:	00492783          	lw	a5,4(s2)
    800061a8:	fe9788e3          	beq	a5,s1,80006198 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800061ac:	f9042903          	lw	s2,-112(s0)
    800061b0:	20090793          	addi	a5,s2,512
    800061b4:	00479713          	slli	a4,a5,0x4
    800061b8:	0001d797          	auipc	a5,0x1d
    800061bc:	e4878793          	addi	a5,a5,-440 # 80023000 <disk>
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061c6:	0001f997          	auipc	s3,0x1f
    800061ca:	e3a98993          	addi	s3,s3,-454 # 80025000 <disk+0x2000>
    800061ce:	00491713          	slli	a4,s2,0x4
    800061d2:	0009b783          	ld	a5,0(s3)
    800061d6:	97ba                	add	a5,a5,a4
    800061d8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061dc:	854a                	mv	a0,s2
    800061de:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061e2:	00000097          	auipc	ra,0x0
    800061e6:	bc4080e7          	jalr	-1084(ra) # 80005da6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061ea:	8885                	andi	s1,s1,1
    800061ec:	f0ed                	bnez	s1,800061ce <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061ee:	0001f517          	auipc	a0,0x1f
    800061f2:	f3a50513          	addi	a0,a0,-198 # 80025128 <disk+0x2128>
    800061f6:	ffffb097          	auipc	ra,0xffffb
    800061fa:	aa2080e7          	jalr	-1374(ra) # 80000c98 <release>
}
    800061fe:	70a6                	ld	ra,104(sp)
    80006200:	7406                	ld	s0,96(sp)
    80006202:	64e6                	ld	s1,88(sp)
    80006204:	6946                	ld	s2,80(sp)
    80006206:	69a6                	ld	s3,72(sp)
    80006208:	6a06                	ld	s4,64(sp)
    8000620a:	7ae2                	ld	s5,56(sp)
    8000620c:	7b42                	ld	s6,48(sp)
    8000620e:	7ba2                	ld	s7,40(sp)
    80006210:	7c02                	ld	s8,32(sp)
    80006212:	6ce2                	ld	s9,24(sp)
    80006214:	6d42                	ld	s10,16(sp)
    80006216:	6165                	addi	sp,sp,112
    80006218:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000621a:	0001f697          	auipc	a3,0x1f
    8000621e:	de66b683          	ld	a3,-538(a3) # 80025000 <disk+0x2000>
    80006222:	96ba                	add	a3,a3,a4
    80006224:	4609                	li	a2,2
    80006226:	00c69623          	sh	a2,12(a3)
    8000622a:	b5c9                	j	800060ec <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000622c:	f9042583          	lw	a1,-112(s0)
    80006230:	20058793          	addi	a5,a1,512
    80006234:	0792                	slli	a5,a5,0x4
    80006236:	0001d517          	auipc	a0,0x1d
    8000623a:	e7250513          	addi	a0,a0,-398 # 800230a8 <disk+0xa8>
    8000623e:	953e                	add	a0,a0,a5
  if(write)
    80006240:	e20d11e3          	bnez	s10,80006062 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006244:	20058713          	addi	a4,a1,512
    80006248:	00471693          	slli	a3,a4,0x4
    8000624c:	0001d717          	auipc	a4,0x1d
    80006250:	db470713          	addi	a4,a4,-588 # 80023000 <disk>
    80006254:	9736                	add	a4,a4,a3
    80006256:	0a072423          	sw	zero,168(a4)
    8000625a:	b505                	j	8000607a <virtio_disk_rw+0xf4>

000000008000625c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000625c:	1101                	addi	sp,sp,-32
    8000625e:	ec06                	sd	ra,24(sp)
    80006260:	e822                	sd	s0,16(sp)
    80006262:	e426                	sd	s1,8(sp)
    80006264:	e04a                	sd	s2,0(sp)
    80006266:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006268:	0001f517          	auipc	a0,0x1f
    8000626c:	ec050513          	addi	a0,a0,-320 # 80025128 <disk+0x2128>
    80006270:	ffffb097          	auipc	ra,0xffffb
    80006274:	974080e7          	jalr	-1676(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006278:	10001737          	lui	a4,0x10001
    8000627c:	533c                	lw	a5,96(a4)
    8000627e:	8b8d                	andi	a5,a5,3
    80006280:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006282:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006286:	0001f797          	auipc	a5,0x1f
    8000628a:	d7a78793          	addi	a5,a5,-646 # 80025000 <disk+0x2000>
    8000628e:	6b94                	ld	a3,16(a5)
    80006290:	0207d703          	lhu	a4,32(a5)
    80006294:	0026d783          	lhu	a5,2(a3)
    80006298:	06f70163          	beq	a4,a5,800062fa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000629c:	0001d917          	auipc	s2,0x1d
    800062a0:	d6490913          	addi	s2,s2,-668 # 80023000 <disk>
    800062a4:	0001f497          	auipc	s1,0x1f
    800062a8:	d5c48493          	addi	s1,s1,-676 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800062ac:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062b0:	6898                	ld	a4,16(s1)
    800062b2:	0204d783          	lhu	a5,32(s1)
    800062b6:	8b9d                	andi	a5,a5,7
    800062b8:	078e                	slli	a5,a5,0x3
    800062ba:	97ba                	add	a5,a5,a4
    800062bc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062be:	20078713          	addi	a4,a5,512
    800062c2:	0712                	slli	a4,a4,0x4
    800062c4:	974a                	add	a4,a4,s2
    800062c6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062ca:	e731                	bnez	a4,80006316 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062cc:	20078793          	addi	a5,a5,512
    800062d0:	0792                	slli	a5,a5,0x4
    800062d2:	97ca                	add	a5,a5,s2
    800062d4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800062d6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062da:	ffffc097          	auipc	ra,0xffffc
    800062de:	fb2080e7          	jalr	-78(ra) # 8000228c <wakeup>

    disk.used_idx += 1;
    800062e2:	0204d783          	lhu	a5,32(s1)
    800062e6:	2785                	addiw	a5,a5,1
    800062e8:	17c2                	slli	a5,a5,0x30
    800062ea:	93c1                	srli	a5,a5,0x30
    800062ec:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062f0:	6898                	ld	a4,16(s1)
    800062f2:	00275703          	lhu	a4,2(a4)
    800062f6:	faf71be3          	bne	a4,a5,800062ac <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800062fa:	0001f517          	auipc	a0,0x1f
    800062fe:	e2e50513          	addi	a0,a0,-466 # 80025128 <disk+0x2128>
    80006302:	ffffb097          	auipc	ra,0xffffb
    80006306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000630a:	60e2                	ld	ra,24(sp)
    8000630c:	6442                	ld	s0,16(sp)
    8000630e:	64a2                	ld	s1,8(sp)
    80006310:	6902                	ld	s2,0(sp)
    80006312:	6105                	addi	sp,sp,32
    80006314:	8082                	ret
      panic("virtio_disk_intr status");
    80006316:	00002517          	auipc	a0,0x2
    8000631a:	53a50513          	addi	a0,a0,1338 # 80008850 <syscalls+0x3c0>
    8000631e:	ffffa097          	auipc	ra,0xffffa
    80006322:	220080e7          	jalr	544(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
