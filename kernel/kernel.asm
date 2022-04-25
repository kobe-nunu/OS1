
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	92013103          	ld	sp,-1760(sp) # 80008920 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
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
    80000068:	e5c78793          	addi	a5,a5,-420 # 80005ec0 <timervec>
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
    80000130:	524080e7          	jalr	1316(ra) # 80002650 <either_copyin>
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
    80000190:	01450513          	addi	a0,a0,20 # 800111a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	00448493          	addi	s1,s1,4 # 800111a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	09290913          	addi	s2,s2,146 # 80011238 <cons+0x98>
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
    800001d8:	f74080e7          	jalr	-140(ra) # 80002148 <sleep>
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
    80000214:	3ea080e7          	jalr	1002(ra) # 800025fa <either_copyout>
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
    80000228:	f7c50513          	addi	a0,a0,-132 # 800111a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f6650513          	addi	a0,a0,-154 # 800111a0 <cons>
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
    80000276:	fcf72323          	sw	a5,-58(a4) # 80011238 <cons+0x98>
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
    800002d0:	ed450513          	addi	a0,a0,-300 # 800111a0 <cons>
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
    800002f6:	3b4080e7          	jalr	948(ra) # 800026a6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ea650513          	addi	a0,a0,-346 # 800111a0 <cons>
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
    80000322:	e8270713          	addi	a4,a4,-382 # 800111a0 <cons>
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
    8000034c:	e5878793          	addi	a5,a5,-424 # 800111a0 <cons>
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
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80011238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e1670713          	addi	a4,a4,-490 # 800111a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e0648493          	addi	s1,s1,-506 # 800111a0 <cons>
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
    800003da:	dca70713          	addi	a4,a4,-566 # 800111a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80011240 <cons+0xa0>
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
    80000416:	d8e78793          	addi	a5,a5,-626 # 800111a0 <cons>
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
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001123c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dfa50513          	addi	a0,a0,-518 # 80011238 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	eba080e7          	jalr	-326(ra) # 80002300 <wakeup>
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
    80000464:	d4050513          	addi	a0,a0,-704 # 800111a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	6c078793          	addi	a5,a5,1728 # 80021b38 <devsw>
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
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80011260 <pr+0x18>
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
    80000570:	d6c50513          	addi	a0,a0,-660 # 800082d8 <digits+0x298>
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
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80011260 <pr+0x18>
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
    800005fc:	c5050513          	addi	a0,a0,-944 # 80011248 <pr>
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
    80000760:	aec50513          	addi	a0,a0,-1300 # 80011248 <pr>
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
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80011248 <pr>
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
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80011268 <uart_tx_lock>
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
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80011268 <uart_tx_lock>
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
    800008a4:	a60080e7          	jalr	-1440(ra) # 80002300 <wakeup>
    
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
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80011268 <uart_tx_lock>
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
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80011268 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	81c080e7          	jalr	-2020(ra) # 80002148 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	92648493          	addi	s1,s1,-1754 # 80011268 <uart_tx_lock>
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
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80011268 <uart_tx_lock>
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
    80000a30:	87490913          	addi	s2,s2,-1932 # 800112a0 <kmem>
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
    80000acc:	7d850513          	addi	a0,a0,2008 # 800112a0 <kmem>
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
    80000b02:	7a248493          	addi	s1,s1,1954 # 800112a0 <kmem>
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
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800112a0 <kmem>
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
    80000b46:	75e50513          	addi	a0,a0,1886 # 800112a0 <kmem>
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
    80000ed8:	a4c080e7          	jalr	-1460(ra) # 80002920 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	024080e7          	jalr	36(ra) # 80005f00 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	020080e7          	jalr	32(ra) # 80001f04 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	3dc50513          	addi	a0,a0,988 # 800082d8 <digits+0x298>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	3bc50513          	addi	a0,a0,956 # 800082d8 <digits+0x298>
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
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	9ac080e7          	jalr	-1620(ra) # 800028f8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	9cc080e7          	jalr	-1588(ra) # 80002920 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	f8e080e7          	jalr	-114(ra) # 80005eea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f9c080e7          	jalr	-100(ra) # 80005f00 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	176080e7          	jalr	374(ra) # 800030e2 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	806080e7          	jalr	-2042(ra) # 8000377a <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	7b0080e7          	jalr	1968(ra) # 8000472c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	09e080e7          	jalr	158(ra) # 80006022 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d10080e7          	jalr	-752(ra) # 80001c9c <userinit>
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
    80001858:	e9c48493          	addi	s1,s1,-356 # 800116f0 <proc>
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
    80001872:	082a0a13          	addi	s4,s4,130 # 800178f0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
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
    800018a8:	18848493          	addi	s1,s1,392
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
    800018f4:	9d050513          	addi	a0,a0,-1584 # 800112c0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9d050513          	addi	a0,a0,-1584 # 800112d8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	dd848493          	addi	s1,s1,-552 # 800116f0 <proc>
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
    8000193e:	fb698993          	addi	s3,s3,-74 # 800178f0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	f0bc                	sd	a5,96(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	18848493          	addi	s1,s1,392
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
    800019a4:	95050513          	addi	a0,a0,-1712 # 800112f0 <cpus>
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
    800019cc:	8f870713          	addi	a4,a4,-1800 # 800112c0 <pid_lock>
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
    80001a04:	ed07a783          	lw	a5,-304(a5) # 800088d0 <first.1695>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	f46080e7          	jalr	-186(ra) # 80002950 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ea07ab23          	sw	zero,-330(a5) # 800088d0 <first.1695>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	cd6080e7          	jalr	-810(ra) # 800036fa <fsinit>
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
    80001a3e:	88690913          	addi	s2,s2,-1914 # 800112c0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	e8878793          	addi	a5,a5,-376 # 800088d4 <nextpid>
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
    80001ab0:	07893683          	ld	a3,120(s2)
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
    80001b6e:	7d28                	ld	a0,120(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001b7e:	78a8                	ld	a0,112(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	74ac                	ld	a1,104(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001b90:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001b9c:	16048c23          	sb	zero,376(s1)
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
    80001bca:	b2a48493          	addi	s1,s1,-1238 # 800116f0 <proc>
    80001bce:	00016917          	auipc	s2,0x16
    80001bd2:	d2290913          	addi	s2,s2,-734 # 800178f0 <tickslock>
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
    80001bee:	18848493          	addi	s1,s1,392
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a09d                	j	80001c5e <allocproc+0xa4>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c08:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001c0c:	0204ac23          	sw	zero,56(s1)
  p->sleeping_time = 0;
    80001c10:	0404a223          	sw	zero,68(s1)
  p->runnable_time = 0;
    80001c14:	0404a423          	sw	zero,72(s1)
  p->running_time = 0;
    80001c18:	0404a623          	sw	zero,76(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	ed8080e7          	jalr	-296(ra) # 80000af4 <kalloc>
    80001c24:	892a                	mv	s2,a0
    80001c26:	fca8                	sd	a0,120(s1)
    80001c28:	c131                	beqz	a0,80001c6c <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c2a:	8526                	mv	a0,s1
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	e48080e7          	jalr	-440(ra) # 80001a74 <proc_pagetable>
    80001c34:	892a                	mv	s2,a0
    80001c36:	f8a8                	sd	a0,112(s1)
  if(p->pagetable == 0){
    80001c38:	c531                	beqz	a0,80001c84 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c3a:	07000613          	li	a2,112
    80001c3e:	4581                	li	a1,0
    80001c40:	08048513          	addi	a0,s1,128
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	09c080e7          	jalr	156(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c4c:	00000797          	auipc	a5,0x0
    80001c50:	d9c78793          	addi	a5,a5,-612 # 800019e8 <forkret>
    80001c54:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c56:	70bc                	ld	a5,96(s1)
    80001c58:	6705                	lui	a4,0x1
    80001c5a:	97ba                	add	a5,a5,a4
    80001c5c:	e4dc                	sd	a5,136(s1)
}
    80001c5e:	8526                	mv	a0,s1
    80001c60:	60e2                	ld	ra,24(sp)
    80001c62:	6442                	ld	s0,16(sp)
    80001c64:	64a2                	ld	s1,8(sp)
    80001c66:	6902                	ld	s2,0(sp)
    80001c68:	6105                	addi	sp,sp,32
    80001c6a:	8082                	ret
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef4080e7          	jalr	-268(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	020080e7          	jalr	32(ra) # 80000c98 <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	bff1                	j	80001c5e <allocproc+0xa4>
    freeproc(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	edc080e7          	jalr	-292(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	008080e7          	jalr	8(ra) # 80000c98 <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	b7d1                	j	80001c5e <allocproc+0xa4>

0000000080001c9c <userinit>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	f14080e7          	jalr	-236(ra) # 80001bba <allocproc>
    80001cae:	84aa                	mv	s1,a0
  initproc = p;
    80001cb0:	00007797          	auipc	a5,0x7
    80001cb4:	38a7bc23          	sd	a0,920(a5) # 80009048 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb8:	03400613          	li	a2,52
    80001cbc:	00007597          	auipc	a1,0x7
    80001cc0:	c2458593          	addi	a1,a1,-988 # 800088e0 <initcode>
    80001cc4:	7928                	ld	a0,112(a0)
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	6a2080e7          	jalr	1698(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cce:	6785                	lui	a5,0x1
    80001cd0:	f4bc                	sd	a5,104(s1)
  sleeping_processes_mean = 0;
    80001cd2:	00007717          	auipc	a4,0x7
    80001cd6:	36072923          	sw	zero,882(a4) # 80009044 <sleeping_processes_mean>
  running_processes_mean = 0;
    80001cda:	00007717          	auipc	a4,0x7
    80001cde:	36072323          	sw	zero,870(a4) # 80009040 <running_processes_mean>
  runnable_processes_mean = 0;
    80001ce2:	00007717          	auipc	a4,0x7
    80001ce6:	34072d23          	sw	zero,858(a4) # 8000903c <runnable_processes_mean>
  p->trapframe->epc = 0;      // user program counter
    80001cea:	7cb8                	ld	a4,120(s1)
    80001cec:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf0:	7cb8                	ld	a4,120(s1)
    80001cf2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf4:	4641                	li	a2,16
    80001cf6:	00006597          	auipc	a1,0x6
    80001cfa:	50a58593          	addi	a1,a1,1290 # 80008200 <digits+0x1c0>
    80001cfe:	17848513          	addi	a0,s1,376
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	130080e7          	jalr	304(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d0a:	00006517          	auipc	a0,0x6
    80001d0e:	50650513          	addi	a0,a0,1286 # 80008210 <digits+0x1d0>
    80001d12:	00002097          	auipc	ra,0x2
    80001d16:	416080e7          	jalr	1046(ra) # 80004128 <namei>
    80001d1a:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001d1e:	478d                	li	a5,3
    80001d20:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80001d22:	00007797          	auipc	a5,0x7
    80001d26:	32e7a783          	lw	a5,814(a5) # 80009050 <ticks>
    80001d2a:	dcdc                	sw	a5,60(s1)
  start_time = ticks;
    80001d2c:	00007717          	auipc	a4,0x7
    80001d30:	30f72423          	sw	a5,776(a4) # 80009034 <start_time>
  release(&p->lock);
    80001d34:	8526                	mv	a0,s1
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	f62080e7          	jalr	-158(ra) # 80000c98 <release>
}
    80001d3e:	60e2                	ld	ra,24(sp)
    80001d40:	6442                	ld	s0,16(sp)
    80001d42:	64a2                	ld	s1,8(sp)
    80001d44:	6105                	addi	sp,sp,32
    80001d46:	8082                	ret

0000000080001d48 <growproc>:
{
    80001d48:	1101                	addi	sp,sp,-32
    80001d4a:	ec06                	sd	ra,24(sp)
    80001d4c:	e822                	sd	s0,16(sp)
    80001d4e:	e426                	sd	s1,8(sp)
    80001d50:	e04a                	sd	s2,0(sp)
    80001d52:	1000                	addi	s0,sp,32
    80001d54:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	c5a080e7          	jalr	-934(ra) # 800019b0 <myproc>
    80001d5e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d60:	752c                	ld	a1,104(a0)
    80001d62:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d66:	00904f63          	bgtz	s1,80001d84 <growproc+0x3c>
  } else if(n < 0){
    80001d6a:	0204cc63          	bltz	s1,80001da2 <growproc+0x5a>
  p->sz = sz;
    80001d6e:	1602                	slli	a2,a2,0x20
    80001d70:	9201                	srli	a2,a2,0x20
    80001d72:	06c93423          	sd	a2,104(s2)
  return 0;
    80001d76:	4501                	li	a0,0
}
    80001d78:	60e2                	ld	ra,24(sp)
    80001d7a:	6442                	ld	s0,16(sp)
    80001d7c:	64a2                	ld	s1,8(sp)
    80001d7e:	6902                	ld	s2,0(sp)
    80001d80:	6105                	addi	sp,sp,32
    80001d82:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d84:	9e25                	addw	a2,a2,s1
    80001d86:	1602                	slli	a2,a2,0x20
    80001d88:	9201                	srli	a2,a2,0x20
    80001d8a:	1582                	slli	a1,a1,0x20
    80001d8c:	9181                	srli	a1,a1,0x20
    80001d8e:	7928                	ld	a0,112(a0)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	692080e7          	jalr	1682(ra) # 80001422 <uvmalloc>
    80001d98:	0005061b          	sext.w	a2,a0
    80001d9c:	fa69                	bnez	a2,80001d6e <growproc+0x26>
      return -1;
    80001d9e:	557d                	li	a0,-1
    80001da0:	bfe1                	j	80001d78 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da2:	9e25                	addw	a2,a2,s1
    80001da4:	1602                	slli	a2,a2,0x20
    80001da6:	9201                	srli	a2,a2,0x20
    80001da8:	1582                	slli	a1,a1,0x20
    80001daa:	9181                	srli	a1,a1,0x20
    80001dac:	7928                	ld	a0,112(a0)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	62c080e7          	jalr	1580(ra) # 800013da <uvmdealloc>
    80001db6:	0005061b          	sext.w	a2,a0
    80001dba:	bf55                	j	80001d6e <growproc+0x26>

0000000080001dbc <fork>:
{
    80001dbc:	7179                	addi	sp,sp,-48
    80001dbe:	f406                	sd	ra,40(sp)
    80001dc0:	f022                	sd	s0,32(sp)
    80001dc2:	ec26                	sd	s1,24(sp)
    80001dc4:	e84a                	sd	s2,16(sp)
    80001dc6:	e44e                	sd	s3,8(sp)
    80001dc8:	e052                	sd	s4,0(sp)
    80001dca:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	be4080e7          	jalr	-1052(ra) # 800019b0 <myproc>
    80001dd4:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	de4080e7          	jalr	-540(ra) # 80001bba <allocproc>
    80001dde:	12050163          	beqz	a0,80001f00 <fork+0x144>
    80001de2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001de4:	06893603          	ld	a2,104(s2)
    80001de8:	792c                	ld	a1,112(a0)
    80001dea:	07093503          	ld	a0,112(s2)
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	780080e7          	jalr	1920(ra) # 8000156e <uvmcopy>
    80001df6:	04054663          	bltz	a0,80001e42 <fork+0x86>
  np->sz = p->sz;
    80001dfa:	06893783          	ld	a5,104(s2)
    80001dfe:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e02:	07893683          	ld	a3,120(s2)
    80001e06:	87b6                	mv	a5,a3
    80001e08:	0789b703          	ld	a4,120(s3)
    80001e0c:	12068693          	addi	a3,a3,288
    80001e10:	0007b803          	ld	a6,0(a5)
    80001e14:	6788                	ld	a0,8(a5)
    80001e16:	6b8c                	ld	a1,16(a5)
    80001e18:	6f90                	ld	a2,24(a5)
    80001e1a:	01073023          	sd	a6,0(a4)
    80001e1e:	e708                	sd	a0,8(a4)
    80001e20:	eb0c                	sd	a1,16(a4)
    80001e22:	ef10                	sd	a2,24(a4)
    80001e24:	02078793          	addi	a5,a5,32
    80001e28:	02070713          	addi	a4,a4,32
    80001e2c:	fed792e3          	bne	a5,a3,80001e10 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e30:	0789b783          	ld	a5,120(s3)
    80001e34:	0607b823          	sd	zero,112(a5)
    80001e38:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80001e3c:	17000a13          	li	s4,368
    80001e40:	a03d                	j	80001e6e <fork+0xb2>
    freeproc(np);
    80001e42:	854e                	mv	a0,s3
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	d1e080e7          	jalr	-738(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e4c:	854e                	mv	a0,s3
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	e4a080e7          	jalr	-438(ra) # 80000c98 <release>
    return -1;
    80001e56:	5a7d                	li	s4,-1
    80001e58:	a859                	j	80001eee <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5a:	00003097          	auipc	ra,0x3
    80001e5e:	964080e7          	jalr	-1692(ra) # 800047be <filedup>
    80001e62:	009987b3          	add	a5,s3,s1
    80001e66:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e68:	04a1                	addi	s1,s1,8
    80001e6a:	01448763          	beq	s1,s4,80001e78 <fork+0xbc>
    if(p->ofile[i])
    80001e6e:	009907b3          	add	a5,s2,s1
    80001e72:	6388                	ld	a0,0(a5)
    80001e74:	f17d                	bnez	a0,80001e5a <fork+0x9e>
    80001e76:	bfcd                	j	80001e68 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e78:	17093503          	ld	a0,368(s2)
    80001e7c:	00002097          	auipc	ra,0x2
    80001e80:	ab8080e7          	jalr	-1352(ra) # 80003934 <idup>
    80001e84:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e88:	4641                	li	a2,16
    80001e8a:	17890593          	addi	a1,s2,376
    80001e8e:	17898513          	addi	a0,s3,376
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	fa0080e7          	jalr	-96(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e9a:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e9e:	854e                	mv	a0,s3
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	df8080e7          	jalr	-520(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ea8:	0000f497          	auipc	s1,0xf
    80001eac:	43048493          	addi	s1,s1,1072 # 800112d8 <wait_lock>
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	d32080e7          	jalr	-718(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eba:	0529bc23          	sd	s2,88(s3)
  release(&wait_lock);
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	dd8080e7          	jalr	-552(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ec8:	854e                	mv	a0,s3
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	d1a080e7          	jalr	-742(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ed2:	478d                	li	a5,3
    80001ed4:	00f9ac23          	sw	a5,24(s3)
  np->last_runnable_time = ticks;
    80001ed8:	00007797          	auipc	a5,0x7
    80001edc:	1787a783          	lw	a5,376(a5) # 80009050 <ticks>
    80001ee0:	02f9ae23          	sw	a5,60(s3)
  release(&np->lock);
    80001ee4:	854e                	mv	a0,s3
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	db2080e7          	jalr	-590(ra) # 80000c98 <release>
}
    80001eee:	8552                	mv	a0,s4
    80001ef0:	70a2                	ld	ra,40(sp)
    80001ef2:	7402                	ld	s0,32(sp)
    80001ef4:	64e2                	ld	s1,24(sp)
    80001ef6:	6942                	ld	s2,16(sp)
    80001ef8:	69a2                	ld	s3,8(sp)
    80001efa:	6a02                	ld	s4,0(sp)
    80001efc:	6145                	addi	sp,sp,48
    80001efe:	8082                	ret
    return -1;
    80001f00:	5a7d                	li	s4,-1
    80001f02:	b7f5                	j	80001eee <fork+0x132>

0000000080001f04 <scheduler>:
{
    80001f04:	711d                	addi	sp,sp,-96
    80001f06:	ec86                	sd	ra,88(sp)
    80001f08:	e8a2                	sd	s0,80(sp)
    80001f0a:	e4a6                	sd	s1,72(sp)
    80001f0c:	e0ca                	sd	s2,64(sp)
    80001f0e:	fc4e                	sd	s3,56(sp)
    80001f10:	f852                	sd	s4,48(sp)
    80001f12:	f456                	sd	s5,40(sp)
    80001f14:	f05a                	sd	s6,32(sp)
    80001f16:	ec5e                	sd	s7,24(sp)
    80001f18:	e862                	sd	s8,16(sp)
    80001f1a:	e466                	sd	s9,8(sp)
    80001f1c:	1080                	addi	s0,sp,96
  printf("DAFULT MATAFAKA\n");
    80001f1e:	00006517          	auipc	a0,0x6
    80001f22:	2fa50513          	addi	a0,a0,762 # 80008218 <digits+0x1d8>
    80001f26:	ffffe097          	auipc	ra,0xffffe
    80001f2a:	662080e7          	jalr	1634(ra) # 80000588 <printf>
    80001f2e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f30:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f32:	00779c93          	slli	s9,a5,0x7
    80001f36:	0000f717          	auipc	a4,0xf
    80001f3a:	38a70713          	addi	a4,a4,906 # 800112c0 <pid_lock>
    80001f3e:	9766                	add	a4,a4,s9
    80001f40:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context); 
    80001f44:	0000f717          	auipc	a4,0xf
    80001f48:	3b470713          	addi	a4,a4,948 # 800112f8 <cpus+0x8>
    80001f4c:	9cba                	add	s9,s9,a4
      if(pause_ticks <= ticks ||  p->pid < 3) {
    80001f4e:	00007a97          	auipc	s5,0x7
    80001f52:	102a8a93          	addi	s5,s5,258 # 80009050 <ticks>
    80001f56:	00007a17          	auipc	s4,0x7
    80001f5a:	0d2a0a13          	addi	s4,s4,210 # 80009028 <pause_ticks>
          c->proc = 0;
    80001f5e:	079e                	slli	a5,a5,0x7
    80001f60:	0000fb97          	auipc	s7,0xf
    80001f64:	360b8b93          	addi	s7,s7,864 # 800112c0 <pid_lock>
    80001f68:	9bbe                	add	s7,s7,a5
        if(p->state == RUNNABLE )
    80001f6a:	4b0d                	li	s6,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f6c:	00016997          	auipc	s3,0x16
    80001f70:	98498993          	addi	s3,s3,-1660 # 800178f0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f74:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f78:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f7c:	10079073          	csrw	sstatus,a5
    80001f80:	0000f497          	auipc	s1,0xf
    80001f84:	77048493          	addi	s1,s1,1904 # 800116f0 <proc>
          p->state = RUNNING;
    80001f88:	4c11                	li	s8,4
    80001f8a:	a829                	j	80001fa4 <scheduler+0xa0>
        if(p->state == RUNNABLE )
    80001f8c:	4c98                	lw	a4,24(s1)
    80001f8e:	05670363          	beq	a4,s6,80001fd4 <scheduler+0xd0>
      release(&p->lock);
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	d04080e7          	jalr	-764(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f9c:	18848493          	addi	s1,s1,392
    80001fa0:	fd348ae3          	beq	s1,s3,80001f74 <scheduler+0x70>
      acquire(&p->lock);
    80001fa4:	8926                	mv	s2,s1
    80001fa6:	8526                	mv	a0,s1
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	c3c080e7          	jalr	-964(ra) # 80000be4 <acquire>
      if(pause_ticks <= ticks ||  p->pid < 3) {
    80001fb0:	000aa783          	lw	a5,0(s5)
    80001fb4:	000a2703          	lw	a4,0(s4)
    80001fb8:	fce7fae3          	bgeu	a5,a4,80001f8c <scheduler+0x88>
    80001fbc:	5898                	lw	a4,48(s1)
    80001fbe:	4789                	li	a5,2
    80001fc0:	fce7c9e3          	blt	a5,a4,80001f92 <scheduler+0x8e>
        if(p->state == RUNNABLE )
    80001fc4:	4c9c                	lw	a5,24(s1)
    80001fc6:	fd6796e3          	bne	a5,s6,80001f92 <scheduler+0x8e>
          p->state = RUNNING;
    80001fca:	0184ac23          	sw	s8,24(s1)
          c->proc = p;
    80001fce:	029bb823          	sd	s1,48(s7)
          if (p->pid>2) {
    80001fd2:	a839                	j	80001ff0 <scheduler+0xec>
          p->state = RUNNING;
    80001fd4:	0184ac23          	sw	s8,24(s1)
          c->proc = p;
    80001fd8:	029bb823          	sd	s1,48(s7)
          if (p->pid>2) {
    80001fdc:	5894                	lw	a3,48(s1)
    80001fde:	4709                	li	a4,2
    80001fe0:	00d75863          	bge	a4,a3,80001ff0 <scheduler+0xec>
            p->runnable_time = p->runnable_time + ticks - p->last_runnable_time;
    80001fe4:	44b8                	lw	a4,72(s1)
    80001fe6:	9f3d                	addw	a4,a4,a5
    80001fe8:	5cd4                	lw	a3,60(s1)
    80001fea:	9f15                	subw	a4,a4,a3
    80001fec:	c4b8                	sw	a4,72(s1)
            p->last_running_time = ticks;
    80001fee:	c0bc                	sw	a5,64(s1)
          swtch(&c->context, &p->context); 
    80001ff0:	08090593          	addi	a1,s2,128
    80001ff4:	8566                	mv	a0,s9
    80001ff6:	00001097          	auipc	ra,0x1
    80001ffa:	898080e7          	jalr	-1896(ra) # 8000288e <swtch>
          c->proc = 0;
    80001ffe:	020bb823          	sd	zero,48(s7)
    80002002:	bf41                	j	80001f92 <scheduler+0x8e>

0000000080002004 <sched>:
{
    80002004:	7179                	addi	sp,sp,-48
    80002006:	f406                	sd	ra,40(sp)
    80002008:	f022                	sd	s0,32(sp)
    8000200a:	ec26                	sd	s1,24(sp)
    8000200c:	e84a                	sd	s2,16(sp)
    8000200e:	e44e                	sd	s3,8(sp)
    80002010:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002012:	00000097          	auipc	ra,0x0
    80002016:	99e080e7          	jalr	-1634(ra) # 800019b0 <myproc>
    8000201a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	b4e080e7          	jalr	-1202(ra) # 80000b6a <holding>
    80002024:	c93d                	beqz	a0,8000209a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002026:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002028:	2781                	sext.w	a5,a5
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	0000f717          	auipc	a4,0xf
    80002030:	29470713          	addi	a4,a4,660 # 800112c0 <pid_lock>
    80002034:	97ba                	add	a5,a5,a4
    80002036:	0a87a703          	lw	a4,168(a5)
    8000203a:	4785                	li	a5,1
    8000203c:	06f71763          	bne	a4,a5,800020aa <sched+0xa6>
  if(p->state == RUNNING)
    80002040:	4c98                	lw	a4,24(s1)
    80002042:	4791                	li	a5,4
    80002044:	06f70b63          	beq	a4,a5,800020ba <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002048:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000204c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000204e:	efb5                	bnez	a5,800020ca <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002050:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002052:	0000f917          	auipc	s2,0xf
    80002056:	26e90913          	addi	s2,s2,622 # 800112c0 <pid_lock>
    8000205a:	2781                	sext.w	a5,a5
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	97ca                	add	a5,a5,s2
    80002060:	0ac7a983          	lw	s3,172(a5)
    80002064:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	0000f597          	auipc	a1,0xf
    8000206e:	28e58593          	addi	a1,a1,654 # 800112f8 <cpus+0x8>
    80002072:	95be                	add	a1,a1,a5
    80002074:	08048513          	addi	a0,s1,128
    80002078:	00001097          	auipc	ra,0x1
    8000207c:	816080e7          	jalr	-2026(ra) # 8000288e <swtch>
    80002080:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002082:	2781                	sext.w	a5,a5
    80002084:	079e                	slli	a5,a5,0x7
    80002086:	97ca                	add	a5,a5,s2
    80002088:	0b37a623          	sw	s3,172(a5)
}
    8000208c:	70a2                	ld	ra,40(sp)
    8000208e:	7402                	ld	s0,32(sp)
    80002090:	64e2                	ld	s1,24(sp)
    80002092:	6942                	ld	s2,16(sp)
    80002094:	69a2                	ld	s3,8(sp)
    80002096:	6145                	addi	sp,sp,48
    80002098:	8082                	ret
    panic("sched p->lock");
    8000209a:	00006517          	auipc	a0,0x6
    8000209e:	19650513          	addi	a0,a0,406 # 80008230 <digits+0x1f0>
    800020a2:	ffffe097          	auipc	ra,0xffffe
    800020a6:	49c080e7          	jalr	1180(ra) # 8000053e <panic>
    panic("sched locks");
    800020aa:	00006517          	auipc	a0,0x6
    800020ae:	19650513          	addi	a0,a0,406 # 80008240 <digits+0x200>
    800020b2:	ffffe097          	auipc	ra,0xffffe
    800020b6:	48c080e7          	jalr	1164(ra) # 8000053e <panic>
    panic("sched running");
    800020ba:	00006517          	auipc	a0,0x6
    800020be:	19650513          	addi	a0,a0,406 # 80008250 <digits+0x210>
    800020c2:	ffffe097          	auipc	ra,0xffffe
    800020c6:	47c080e7          	jalr	1148(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020ca:	00006517          	auipc	a0,0x6
    800020ce:	19650513          	addi	a0,a0,406 # 80008260 <digits+0x220>
    800020d2:	ffffe097          	auipc	ra,0xffffe
    800020d6:	46c080e7          	jalr	1132(ra) # 8000053e <panic>

00000000800020da <yield>:
{
    800020da:	1101                	addi	sp,sp,-32
    800020dc:	ec06                	sd	ra,24(sp)
    800020de:	e822                	sd	s0,16(sp)
    800020e0:	e426                	sd	s1,8(sp)
    800020e2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	8cc080e7          	jalr	-1844(ra) # 800019b0 <myproc>
    800020ec:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	af6080e7          	jalr	-1290(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020f6:	478d                	li	a5,3
    800020f8:	cc9c                	sw	a5,24(s1)
  if(p->pid>2){
    800020fa:	5898                	lw	a4,48(s1)
    800020fc:	4789                	li	a5,2
    800020fe:	02e7d263          	bge	a5,a4,80002122 <yield+0x48>
  program_time += ticks-p->last_running_time;
    80002102:	40b8                	lw	a4,64(s1)
    80002104:	00007797          	auipc	a5,0x7
    80002108:	f4c7a783          	lw	a5,-180(a5) # 80009050 <ticks>
    8000210c:	9f99                	subw	a5,a5,a4
    8000210e:	00007697          	auipc	a3,0x7
    80002112:	f2268693          	addi	a3,a3,-222 # 80009030 <program_time>
    80002116:	4298                	lw	a4,0(a3)
    80002118:	9f3d                	addw	a4,a4,a5
    8000211a:	c298                	sw	a4,0(a3)
  p->running_time += ticks-p->last_running_time;
    8000211c:	44f8                	lw	a4,76(s1)
    8000211e:	9fb9                	addw	a5,a5,a4
    80002120:	c4fc                	sw	a5,76(s1)
  p->last_runnable_time = ticks;
    80002122:	00007797          	auipc	a5,0x7
    80002126:	f2e7a783          	lw	a5,-210(a5) # 80009050 <ticks>
    8000212a:	dcdc                	sw	a5,60(s1)
  sched();
    8000212c:	00000097          	auipc	ra,0x0
    80002130:	ed8080e7          	jalr	-296(ra) # 80002004 <sched>
  release(&p->lock);
    80002134:	8526                	mv	a0,s1
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	b62080e7          	jalr	-1182(ra) # 80000c98 <release>
}
    8000213e:	60e2                	ld	ra,24(sp)
    80002140:	6442                	ld	s0,16(sp)
    80002142:	64a2                	ld	s1,8(sp)
    80002144:	6105                	addi	sp,sp,32
    80002146:	8082                	ret

0000000080002148 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002148:	7179                	addi	sp,sp,-48
    8000214a:	f406                	sd	ra,40(sp)
    8000214c:	f022                	sd	s0,32(sp)
    8000214e:	ec26                	sd	s1,24(sp)
    80002150:	e84a                	sd	s2,16(sp)
    80002152:	e44e                	sd	s3,8(sp)
    80002154:	1800                	addi	s0,sp,48
    80002156:	89aa                	mv	s3,a0
    80002158:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000215a:	00000097          	auipc	ra,0x0
    8000215e:	856080e7          	jalr	-1962(ra) # 800019b0 <myproc>
    80002162:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	a80080e7          	jalr	-1408(ra) # 80000be4 <acquire>
  release(lk);
    8000216c:	854a                	mv	a0,s2
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b2a080e7          	jalr	-1238(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002176:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000217a:	4789                	li	a5,2
    8000217c:	cc9c                	sw	a5,24(s1)
  if(p->pid>2){
    8000217e:	5898                	lw	a4,48(s1)
    80002180:	4789                	li	a5,2
    80002182:	02e7d463          	bge	a5,a4,800021aa <sleep+0x62>
    program_time += ticks-p->last_running_time;
    80002186:	00007697          	auipc	a3,0x7
    8000218a:	eca6a683          	lw	a3,-310(a3) # 80009050 <ticks>
    8000218e:	40bc                	lw	a5,64(s1)
    80002190:	40f687bb          	subw	a5,a3,a5
    80002194:	00007617          	auipc	a2,0x7
    80002198:	e9c60613          	addi	a2,a2,-356 # 80009030 <program_time>
    8000219c:	4218                	lw	a4,0(a2)
    8000219e:	9f3d                	addw	a4,a4,a5
    800021a0:	c218                	sw	a4,0(a2)
    p->running_time += ticks-p->last_running_time;
    800021a2:	44f8                	lw	a4,76(s1)
    800021a4:	9fb9                	addw	a5,a5,a4
    800021a6:	c4fc                	sw	a5,76(s1)
    p->sleep0 = ticks; // strting to sleep
    800021a8:	c8b4                	sw	a3,80(s1)
  }
  sched();
    800021aa:	00000097          	auipc	ra,0x0
    800021ae:	e5a080e7          	jalr	-422(ra) # 80002004 <sched>

  // Tidy up.
  p->chan = 0;
    800021b2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	ae0080e7          	jalr	-1312(ra) # 80000c98 <release>
  acquire(lk);
    800021c0:	854a                	mv	a0,s2
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	a22080e7          	jalr	-1502(ra) # 80000be4 <acquire>
}
    800021ca:	70a2                	ld	ra,40(sp)
    800021cc:	7402                	ld	s0,32(sp)
    800021ce:	64e2                	ld	s1,24(sp)
    800021d0:	6942                	ld	s2,16(sp)
    800021d2:	69a2                	ld	s3,8(sp)
    800021d4:	6145                	addi	sp,sp,48
    800021d6:	8082                	ret

00000000800021d8 <wait>:
{
    800021d8:	715d                	addi	sp,sp,-80
    800021da:	e486                	sd	ra,72(sp)
    800021dc:	e0a2                	sd	s0,64(sp)
    800021de:	fc26                	sd	s1,56(sp)
    800021e0:	f84a                	sd	s2,48(sp)
    800021e2:	f44e                	sd	s3,40(sp)
    800021e4:	f052                	sd	s4,32(sp)
    800021e6:	ec56                	sd	s5,24(sp)
    800021e8:	e85a                	sd	s6,16(sp)
    800021ea:	e45e                	sd	s7,8(sp)
    800021ec:	e062                	sd	s8,0(sp)
    800021ee:	0880                	addi	s0,sp,80
    800021f0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	7be080e7          	jalr	1982(ra) # 800019b0 <myproc>
    800021fa:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021fc:	0000f517          	auipc	a0,0xf
    80002200:	0dc50513          	addi	a0,a0,220 # 800112d8 <wait_lock>
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	9e0080e7          	jalr	-1568(ra) # 80000be4 <acquire>
    havekids = 0;
    8000220c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000220e:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002210:	00015997          	auipc	s3,0x15
    80002214:	6e098993          	addi	s3,s3,1760 # 800178f0 <tickslock>
        havekids = 1;
    80002218:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000221a:	0000fc17          	auipc	s8,0xf
    8000221e:	0bec0c13          	addi	s8,s8,190 # 800112d8 <wait_lock>
    havekids = 0;
    80002222:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002224:	0000f497          	auipc	s1,0xf
    80002228:	4cc48493          	addi	s1,s1,1228 # 800116f0 <proc>
    8000222c:	a0bd                	j	8000229a <wait+0xc2>
          pid = np->pid;
    8000222e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002232:	000b0e63          	beqz	s6,8000224e <wait+0x76>
    80002236:	4691                	li	a3,4
    80002238:	02c48613          	addi	a2,s1,44
    8000223c:	85da                	mv	a1,s6
    8000223e:	07093503          	ld	a0,112(s2)
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	430080e7          	jalr	1072(ra) # 80001672 <copyout>
    8000224a:	02054563          	bltz	a0,80002274 <wait+0x9c>
          freeproc(np);
    8000224e:	8526                	mv	a0,s1
    80002250:	00000097          	auipc	ra,0x0
    80002254:	912080e7          	jalr	-1774(ra) # 80001b62 <freeproc>
          release(&np->lock);
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	a3e080e7          	jalr	-1474(ra) # 80000c98 <release>
          release(&wait_lock);
    80002262:	0000f517          	auipc	a0,0xf
    80002266:	07650513          	addi	a0,a0,118 # 800112d8 <wait_lock>
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	a2e080e7          	jalr	-1490(ra) # 80000c98 <release>
          return pid;
    80002272:	a09d                	j	800022d8 <wait+0x100>
            release(&np->lock);
    80002274:	8526                	mv	a0,s1
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	a22080e7          	jalr	-1502(ra) # 80000c98 <release>
            release(&wait_lock);
    8000227e:	0000f517          	auipc	a0,0xf
    80002282:	05a50513          	addi	a0,a0,90 # 800112d8 <wait_lock>
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	a12080e7          	jalr	-1518(ra) # 80000c98 <release>
            return -1;
    8000228e:	59fd                	li	s3,-1
    80002290:	a0a1                	j	800022d8 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002292:	18848493          	addi	s1,s1,392
    80002296:	03348463          	beq	s1,s3,800022be <wait+0xe6>
      if(np->parent == p){
    8000229a:	6cbc                	ld	a5,88(s1)
    8000229c:	ff279be3          	bne	a5,s2,80002292 <wait+0xba>
        acquire(&np->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	942080e7          	jalr	-1726(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800022aa:	4c9c                	lw	a5,24(s1)
    800022ac:	f94781e3          	beq	a5,s4,8000222e <wait+0x56>
        release(&np->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9e6080e7          	jalr	-1562(ra) # 80000c98 <release>
        havekids = 1;
    800022ba:	8756                	mv	a4,s5
    800022bc:	bfd9                	j	80002292 <wait+0xba>
    if(!havekids || p->killed){
    800022be:	c701                	beqz	a4,800022c6 <wait+0xee>
    800022c0:	02892783          	lw	a5,40(s2)
    800022c4:	c79d                	beqz	a5,800022f2 <wait+0x11a>
      release(&wait_lock);
    800022c6:	0000f517          	auipc	a0,0xf
    800022ca:	01250513          	addi	a0,a0,18 # 800112d8 <wait_lock>
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	9ca080e7          	jalr	-1590(ra) # 80000c98 <release>
      return -1;
    800022d6:	59fd                	li	s3,-1
}
    800022d8:	854e                	mv	a0,s3
    800022da:	60a6                	ld	ra,72(sp)
    800022dc:	6406                	ld	s0,64(sp)
    800022de:	74e2                	ld	s1,56(sp)
    800022e0:	7942                	ld	s2,48(sp)
    800022e2:	79a2                	ld	s3,40(sp)
    800022e4:	7a02                	ld	s4,32(sp)
    800022e6:	6ae2                	ld	s5,24(sp)
    800022e8:	6b42                	ld	s6,16(sp)
    800022ea:	6ba2                	ld	s7,8(sp)
    800022ec:	6c02                	ld	s8,0(sp)
    800022ee:	6161                	addi	sp,sp,80
    800022f0:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022f2:	85e2                	mv	a1,s8
    800022f4:	854a                	mv	a0,s2
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	e52080e7          	jalr	-430(ra) # 80002148 <sleep>
    havekids = 0;
    800022fe:	b715                	j	80002222 <wait+0x4a>

0000000080002300 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002300:	7139                	addi	sp,sp,-64
    80002302:	fc06                	sd	ra,56(sp)
    80002304:	f822                	sd	s0,48(sp)
    80002306:	f426                	sd	s1,40(sp)
    80002308:	f04a                	sd	s2,32(sp)
    8000230a:	ec4e                	sd	s3,24(sp)
    8000230c:	e852                	sd	s4,16(sp)
    8000230e:	e456                	sd	s5,8(sp)
    80002310:	e05a                	sd	s6,0(sp)
    80002312:	0080                	addi	s0,sp,64
    80002314:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002316:	0000f497          	auipc	s1,0xf
    8000231a:	3da48493          	addi	s1,s1,986 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000231e:	4989                	li	s3,2
        p->sleeping_time += ticks - p->sleep0;
    80002320:	00007b17          	auipc	s6,0x7
    80002324:	d30b0b13          	addi	s6,s6,-720 # 80009050 <ticks>
        p->state = RUNNABLE;
    80002328:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000232a:	00015917          	auipc	s2,0x15
    8000232e:	5c690913          	addi	s2,s2,1478 # 800178f0 <tickslock>
    80002332:	a025                	j	8000235a <wakeup+0x5a>
        p->sleeping_time += ticks - p->sleep0;
    80002334:	000b2703          	lw	a4,0(s6)
    80002338:	40fc                	lw	a5,68(s1)
    8000233a:	9fb9                	addw	a5,a5,a4
    8000233c:	48b4                	lw	a3,80(s1)
    8000233e:	9f95                	subw	a5,a5,a3
    80002340:	c0fc                	sw	a5,68(s1)
        p->state = RUNNABLE;
    80002342:	0154ac23          	sw	s5,24(s1)
        p->last_runnable_time = ticks;
    80002346:	dcd8                	sw	a4,60(s1)
      }
      release(&p->lock);
    80002348:	8526                	mv	a0,s1
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	94e080e7          	jalr	-1714(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002352:	18848493          	addi	s1,s1,392
    80002356:	03248463          	beq	s1,s2,8000237e <wakeup+0x7e>
    if(p != myproc()){
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	656080e7          	jalr	1622(ra) # 800019b0 <myproc>
    80002362:	fea488e3          	beq	s1,a0,80002352 <wakeup+0x52>
      acquire(&p->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	87c080e7          	jalr	-1924(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002370:	4c9c                	lw	a5,24(s1)
    80002372:	fd379be3          	bne	a5,s3,80002348 <wakeup+0x48>
    80002376:	709c                	ld	a5,32(s1)
    80002378:	fd4798e3          	bne	a5,s4,80002348 <wakeup+0x48>
    8000237c:	bf65                	j	80002334 <wakeup+0x34>
    }
  }
}
    8000237e:	70e2                	ld	ra,56(sp)
    80002380:	7442                	ld	s0,48(sp)
    80002382:	74a2                	ld	s1,40(sp)
    80002384:	7902                	ld	s2,32(sp)
    80002386:	69e2                	ld	s3,24(sp)
    80002388:	6a42                	ld	s4,16(sp)
    8000238a:	6aa2                	ld	s5,8(sp)
    8000238c:	6b02                	ld	s6,0(sp)
    8000238e:	6121                	addi	sp,sp,64
    80002390:	8082                	ret

0000000080002392 <reparent>:
{
    80002392:	7179                	addi	sp,sp,-48
    80002394:	f406                	sd	ra,40(sp)
    80002396:	f022                	sd	s0,32(sp)
    80002398:	ec26                	sd	s1,24(sp)
    8000239a:	e84a                	sd	s2,16(sp)
    8000239c:	e44e                	sd	s3,8(sp)
    8000239e:	e052                	sd	s4,0(sp)
    800023a0:	1800                	addi	s0,sp,48
    800023a2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023a4:	0000f497          	auipc	s1,0xf
    800023a8:	34c48493          	addi	s1,s1,844 # 800116f0 <proc>
      pp->parent = initproc;
    800023ac:	00007a17          	auipc	s4,0x7
    800023b0:	c9ca0a13          	addi	s4,s4,-868 # 80009048 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023b4:	00015997          	auipc	s3,0x15
    800023b8:	53c98993          	addi	s3,s3,1340 # 800178f0 <tickslock>
    800023bc:	a029                	j	800023c6 <reparent+0x34>
    800023be:	18848493          	addi	s1,s1,392
    800023c2:	01348d63          	beq	s1,s3,800023dc <reparent+0x4a>
    if(pp->parent == p){
    800023c6:	6cbc                	ld	a5,88(s1)
    800023c8:	ff279be3          	bne	a5,s2,800023be <reparent+0x2c>
      pp->parent = initproc;
    800023cc:	000a3503          	ld	a0,0(s4)
    800023d0:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    800023d2:	00000097          	auipc	ra,0x0
    800023d6:	f2e080e7          	jalr	-210(ra) # 80002300 <wakeup>
    800023da:	b7d5                	j	800023be <reparent+0x2c>
}
    800023dc:	70a2                	ld	ra,40(sp)
    800023de:	7402                	ld	s0,32(sp)
    800023e0:	64e2                	ld	s1,24(sp)
    800023e2:	6942                	ld	s2,16(sp)
    800023e4:	69a2                	ld	s3,8(sp)
    800023e6:	6a02                	ld	s4,0(sp)
    800023e8:	6145                	addi	sp,sp,48
    800023ea:	8082                	ret

00000000800023ec <exit>:
{
    800023ec:	7179                	addi	sp,sp,-48
    800023ee:	f406                	sd	ra,40(sp)
    800023f0:	f022                	sd	s0,32(sp)
    800023f2:	ec26                	sd	s1,24(sp)
    800023f4:	e84a                	sd	s2,16(sp)
    800023f6:	e44e                	sd	s3,8(sp)
    800023f8:	e052                	sd	s4,0(sp)
    800023fa:	1800                	addi	s0,sp,48
    800023fc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	5b2080e7          	jalr	1458(ra) # 800019b0 <myproc>
    80002406:	892a                	mv	s2,a0
  if(p == initproc)
    80002408:	00007797          	auipc	a5,0x7
    8000240c:	c407b783          	ld	a5,-960(a5) # 80009048 <initproc>
    80002410:	0f050493          	addi	s1,a0,240
    80002414:	17050993          	addi	s3,a0,368
    80002418:	02a79363          	bne	a5,a0,8000243e <exit+0x52>
    panic("init exiting");
    8000241c:	00006517          	auipc	a0,0x6
    80002420:	e5c50513          	addi	a0,a0,-420 # 80008278 <digits+0x238>
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	11a080e7          	jalr	282(ra) # 8000053e <panic>
      fileclose(f);
    8000242c:	00002097          	auipc	ra,0x2
    80002430:	3e4080e7          	jalr	996(ra) # 80004810 <fileclose>
      p->ofile[fd] = 0;
    80002434:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002438:	04a1                	addi	s1,s1,8
    8000243a:	01348563          	beq	s1,s3,80002444 <exit+0x58>
    if(p->ofile[fd]){
    8000243e:	6088                	ld	a0,0(s1)
    80002440:	f575                	bnez	a0,8000242c <exit+0x40>
    80002442:	bfdd                	j	80002438 <exit+0x4c>
  begin_op();
    80002444:	00002097          	auipc	ra,0x2
    80002448:	f00080e7          	jalr	-256(ra) # 80004344 <begin_op>
  iput(p->cwd);
    8000244c:	17093503          	ld	a0,368(s2)
    80002450:	00001097          	auipc	ra,0x1
    80002454:	6dc080e7          	jalr	1756(ra) # 80003b2c <iput>
  end_op();
    80002458:	00002097          	auipc	ra,0x2
    8000245c:	f6c080e7          	jalr	-148(ra) # 800043c4 <end_op>
  p->cwd = 0;
    80002460:	16093823          	sd	zero,368(s2)
  acquire(&wait_lock);
    80002464:	0000f517          	auipc	a0,0xf
    80002468:	e7450513          	addi	a0,a0,-396 # 800112d8 <wait_lock>
    8000246c:	ffffe097          	auipc	ra,0xffffe
    80002470:	778080e7          	jalr	1912(ra) # 80000be4 <acquire>
  if(p->pid>2){
    80002474:	03092703          	lw	a4,48(s2)
    80002478:	4789                	li	a5,2
    8000247a:	0ae7d963          	bge	a5,a4,8000252c <exit+0x140>
    cpu_utilization = (100*program_time)/(ticks-start_time);
    8000247e:	00007897          	auipc	a7,0x7
    80002482:	bb288893          	addi	a7,a7,-1102 # 80009030 <program_time>
    80002486:	0008a503          	lw	a0,0(a7)
    8000248a:	00007697          	auipc	a3,0x7
    8000248e:	bc66a683          	lw	a3,-1082(a3) # 80009050 <ticks>
    80002492:	06400793          	li	a5,100
    80002496:	02a787bb          	mulw	a5,a5,a0
    8000249a:	00007717          	auipc	a4,0x7
    8000249e:	b9a72703          	lw	a4,-1126(a4) # 80009034 <start_time>
    800024a2:	40e6873b          	subw	a4,a3,a4
    800024a6:	02e7d7bb          	divuw	a5,a5,a4
    800024aa:	00007717          	auipc	a4,0x7
    800024ae:	b8f72123          	sw	a5,-1150(a4) # 8000902c <cpu_utilization>
    sleeping_processes_mean = ((sleeping_processes_mean*exited) + p->sleeping_time)/(exited+1);
    800024b2:	00007817          	auipc	a6,0x7
    800024b6:	b8680813          	addi	a6,a6,-1146 # 80009038 <exited>
    800024ba:	00082583          	lw	a1,0(a6)
    800024be:	0015861b          	addiw	a2,a1,1
    800024c2:	00007797          	auipc	a5,0x7
    800024c6:	b8278793          	addi	a5,a5,-1150 # 80009044 <sleeping_processes_mean>
    800024ca:	4398                	lw	a4,0(a5)
    800024cc:	02b7073b          	mulw	a4,a4,a1
    800024d0:	04492303          	lw	t1,68(s2)
    800024d4:	0067073b          	addw	a4,a4,t1
    800024d8:	02c7473b          	divw	a4,a4,a2
    800024dc:	c398                	sw	a4,0(a5)
    program_time += ticks-p->last_running_time;
    800024de:	04092703          	lw	a4,64(s2)
    800024e2:	40e6873b          	subw	a4,a3,a4
    800024e6:	9d39                	addw	a0,a0,a4
    800024e8:	00a8a023          	sw	a0,0(a7)
    p->running_time += ticks-p->last_running_time;
    800024ec:	04c92783          	lw	a5,76(s2)
    800024f0:	00e786bb          	addw	a3,a5,a4
    800024f4:	04d92623          	sw	a3,76(s2)
    runnable_processes_mean = ((runnable_processes_mean*exited) + p->runnable_time)/(exited+1);
    800024f8:	00007797          	auipc	a5,0x7
    800024fc:	b4478793          	addi	a5,a5,-1212 # 8000903c <runnable_processes_mean>
    80002500:	4398                	lw	a4,0(a5)
    80002502:	02b7073b          	mulw	a4,a4,a1
    80002506:	04892503          	lw	a0,72(s2)
    8000250a:	9f29                	addw	a4,a4,a0
    8000250c:	02c7473b          	divw	a4,a4,a2
    80002510:	c398                	sw	a4,0(a5)
    running_processes_mean = ((running_processes_mean*exited) + p->running_time)/(exited+1);
    80002512:	00007717          	auipc	a4,0x7
    80002516:	b2e70713          	addi	a4,a4,-1234 # 80009040 <running_processes_mean>
    8000251a:	431c                	lw	a5,0(a4)
    8000251c:	02b787bb          	mulw	a5,a5,a1
    80002520:	9fb5                	addw	a5,a5,a3
    80002522:	02c7c7bb          	divw	a5,a5,a2
    80002526:	c31c                	sw	a5,0(a4)
    exited += 1;
    80002528:	00c82023          	sw	a2,0(a6)
  reparent(p);
    8000252c:	854a                	mv	a0,s2
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	e64080e7          	jalr	-412(ra) # 80002392 <reparent>
  wakeup(p->parent);
    80002536:	05893503          	ld	a0,88(s2)
    8000253a:	00000097          	auipc	ra,0x0
    8000253e:	dc6080e7          	jalr	-570(ra) # 80002300 <wakeup>
  acquire(&p->lock);
    80002542:	854a                	mv	a0,s2
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	6a0080e7          	jalr	1696(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000254c:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    80002550:	4795                	li	a5,5
    80002552:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    80002556:	0000f517          	auipc	a0,0xf
    8000255a:	d8250513          	addi	a0,a0,-638 # 800112d8 <wait_lock>
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	73a080e7          	jalr	1850(ra) # 80000c98 <release>
  sched();
    80002566:	00000097          	auipc	ra,0x0
    8000256a:	a9e080e7          	jalr	-1378(ra) # 80002004 <sched>
  panic("zombie exit");
    8000256e:	00006517          	auipc	a0,0x6
    80002572:	d1a50513          	addi	a0,a0,-742 # 80008288 <digits+0x248>
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	fc8080e7          	jalr	-56(ra) # 8000053e <panic>

000000008000257e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000257e:	7179                	addi	sp,sp,-48
    80002580:	f406                	sd	ra,40(sp)
    80002582:	f022                	sd	s0,32(sp)
    80002584:	ec26                	sd	s1,24(sp)
    80002586:	e84a                	sd	s2,16(sp)
    80002588:	e44e                	sd	s3,8(sp)
    8000258a:	1800                	addi	s0,sp,48
    8000258c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000258e:	0000f497          	auipc	s1,0xf
    80002592:	16248493          	addi	s1,s1,354 # 800116f0 <proc>
    80002596:	00015997          	auipc	s3,0x15
    8000259a:	35a98993          	addi	s3,s3,858 # 800178f0 <tickslock>
    acquire(&p->lock);
    8000259e:	8526                	mv	a0,s1
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	644080e7          	jalr	1604(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025a8:	589c                	lw	a5,48(s1)
    800025aa:	01278d63          	beq	a5,s2,800025c4 <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025ae:	8526                	mv	a0,s1
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	6e8080e7          	jalr	1768(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b8:	18848493          	addi	s1,s1,392
    800025bc:	ff3491e3          	bne	s1,s3,8000259e <kill+0x20>
  }
  return -1;
    800025c0:	557d                	li	a0,-1
    800025c2:	a829                	j	800025dc <kill+0x5e>
      p->killed = 1;
    800025c4:	4785                	li	a5,1
    800025c6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025c8:	4c98                	lw	a4,24(s1)
    800025ca:	4789                	li	a5,2
    800025cc:	00f70f63          	beq	a4,a5,800025ea <kill+0x6c>
      release(&p->lock);
    800025d0:	8526                	mv	a0,s1
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	6c6080e7          	jalr	1734(ra) # 80000c98 <release>
      return 0;
    800025da:	4501                	li	a0,0
}
    800025dc:	70a2                	ld	ra,40(sp)
    800025de:	7402                	ld	s0,32(sp)
    800025e0:	64e2                	ld	s1,24(sp)
    800025e2:	6942                	ld	s2,16(sp)
    800025e4:	69a2                	ld	s3,8(sp)
    800025e6:	6145                	addi	sp,sp,48
    800025e8:	8082                	ret
        p->state = RUNNABLE;
    800025ea:	478d                	li	a5,3
    800025ec:	cc9c                	sw	a5,24(s1)
        p->last_runnable_time = ticks;
    800025ee:	00007797          	auipc	a5,0x7
    800025f2:	a627a783          	lw	a5,-1438(a5) # 80009050 <ticks>
    800025f6:	dcdc                	sw	a5,60(s1)
    800025f8:	bfe1                	j	800025d0 <kill+0x52>

00000000800025fa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025fa:	7179                	addi	sp,sp,-48
    800025fc:	f406                	sd	ra,40(sp)
    800025fe:	f022                	sd	s0,32(sp)
    80002600:	ec26                	sd	s1,24(sp)
    80002602:	e84a                	sd	s2,16(sp)
    80002604:	e44e                	sd	s3,8(sp)
    80002606:	e052                	sd	s4,0(sp)
    80002608:	1800                	addi	s0,sp,48
    8000260a:	84aa                	mv	s1,a0
    8000260c:	892e                	mv	s2,a1
    8000260e:	89b2                	mv	s3,a2
    80002610:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002612:	fffff097          	auipc	ra,0xfffff
    80002616:	39e080e7          	jalr	926(ra) # 800019b0 <myproc>
  if(user_dst){
    8000261a:	c08d                	beqz	s1,8000263c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000261c:	86d2                	mv	a3,s4
    8000261e:	864e                	mv	a2,s3
    80002620:	85ca                	mv	a1,s2
    80002622:	7928                	ld	a0,112(a0)
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	04e080e7          	jalr	78(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000262c:	70a2                	ld	ra,40(sp)
    8000262e:	7402                	ld	s0,32(sp)
    80002630:	64e2                	ld	s1,24(sp)
    80002632:	6942                	ld	s2,16(sp)
    80002634:	69a2                	ld	s3,8(sp)
    80002636:	6a02                	ld	s4,0(sp)
    80002638:	6145                	addi	sp,sp,48
    8000263a:	8082                	ret
    memmove((char *)dst, src, len);
    8000263c:	000a061b          	sext.w	a2,s4
    80002640:	85ce                	mv	a1,s3
    80002642:	854a                	mv	a0,s2
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	6fc080e7          	jalr	1788(ra) # 80000d40 <memmove>
    return 0;
    8000264c:	8526                	mv	a0,s1
    8000264e:	bff9                	j	8000262c <either_copyout+0x32>

0000000080002650 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002650:	7179                	addi	sp,sp,-48
    80002652:	f406                	sd	ra,40(sp)
    80002654:	f022                	sd	s0,32(sp)
    80002656:	ec26                	sd	s1,24(sp)
    80002658:	e84a                	sd	s2,16(sp)
    8000265a:	e44e                	sd	s3,8(sp)
    8000265c:	e052                	sd	s4,0(sp)
    8000265e:	1800                	addi	s0,sp,48
    80002660:	892a                	mv	s2,a0
    80002662:	84ae                	mv	s1,a1
    80002664:	89b2                	mv	s3,a2
    80002666:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002668:	fffff097          	auipc	ra,0xfffff
    8000266c:	348080e7          	jalr	840(ra) # 800019b0 <myproc>
  if(user_src){
    80002670:	c08d                	beqz	s1,80002692 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002672:	86d2                	mv	a3,s4
    80002674:	864e                	mv	a2,s3
    80002676:	85ca                	mv	a1,s2
    80002678:	7928                	ld	a0,112(a0)
    8000267a:	fffff097          	auipc	ra,0xfffff
    8000267e:	084080e7          	jalr	132(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002682:	70a2                	ld	ra,40(sp)
    80002684:	7402                	ld	s0,32(sp)
    80002686:	64e2                	ld	s1,24(sp)
    80002688:	6942                	ld	s2,16(sp)
    8000268a:	69a2                	ld	s3,8(sp)
    8000268c:	6a02                	ld	s4,0(sp)
    8000268e:	6145                	addi	sp,sp,48
    80002690:	8082                	ret
    memmove(dst, (char*)src, len);
    80002692:	000a061b          	sext.w	a2,s4
    80002696:	85ce                	mv	a1,s3
    80002698:	854a                	mv	a0,s2
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	6a6080e7          	jalr	1702(ra) # 80000d40 <memmove>
    return 0;
    800026a2:	8526                	mv	a0,s1
    800026a4:	bff9                	j	80002682 <either_copyin+0x32>

00000000800026a6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026a6:	715d                	addi	sp,sp,-80
    800026a8:	e486                	sd	ra,72(sp)
    800026aa:	e0a2                	sd	s0,64(sp)
    800026ac:	fc26                	sd	s1,56(sp)
    800026ae:	f84a                	sd	s2,48(sp)
    800026b0:	f44e                	sd	s3,40(sp)
    800026b2:	f052                	sd	s4,32(sp)
    800026b4:	ec56                	sd	s5,24(sp)
    800026b6:	e85a                	sd	s6,16(sp)
    800026b8:	e45e                	sd	s7,8(sp)
    800026ba:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026bc:	00006517          	auipc	a0,0x6
    800026c0:	c1c50513          	addi	a0,a0,-996 # 800082d8 <digits+0x298>
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	ec4080e7          	jalr	-316(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026cc:	0000f497          	auipc	s1,0xf
    800026d0:	19c48493          	addi	s1,s1,412 # 80011868 <proc+0x178>
    800026d4:	00015917          	auipc	s2,0x15
    800026d8:	39490913          	addi	s2,s2,916 # 80017a68 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026dc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026de:	00006997          	auipc	s3,0x6
    800026e2:	bba98993          	addi	s3,s3,-1094 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    800026e6:	00006a97          	auipc	s5,0x6
    800026ea:	bbaa8a93          	addi	s5,s5,-1094 # 800082a0 <digits+0x260>
    printf("\n");
    800026ee:	00006a17          	auipc	s4,0x6
    800026f2:	beaa0a13          	addi	s4,s4,-1046 # 800082d8 <digits+0x298>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f6:	00006b97          	auipc	s7,0x6
    800026fa:	c72b8b93          	addi	s7,s7,-910 # 80008368 <states.1732>
    800026fe:	a00d                	j	80002720 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002700:	eb86a583          	lw	a1,-328(a3)
    80002704:	8556                	mv	a0,s5
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	e82080e7          	jalr	-382(ra) # 80000588 <printf>
    printf("\n");
    8000270e:	8552                	mv	a0,s4
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	e78080e7          	jalr	-392(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002718:	18848493          	addi	s1,s1,392
    8000271c:	03248163          	beq	s1,s2,8000273e <procdump+0x98>
    if(p->state == UNUSED)
    80002720:	86a6                	mv	a3,s1
    80002722:	ea04a783          	lw	a5,-352(s1)
    80002726:	dbed                	beqz	a5,80002718 <procdump+0x72>
      state = "???";
    80002728:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000272a:	fcfb6be3          	bltu	s6,a5,80002700 <procdump+0x5a>
    8000272e:	1782                	slli	a5,a5,0x20
    80002730:	9381                	srli	a5,a5,0x20
    80002732:	078e                	slli	a5,a5,0x3
    80002734:	97de                	add	a5,a5,s7
    80002736:	6390                	ld	a2,0(a5)
    80002738:	f661                	bnez	a2,80002700 <procdump+0x5a>
      state = "???";
    8000273a:	864e                	mv	a2,s3
    8000273c:	b7d1                	j	80002700 <procdump+0x5a>
  }
}
    8000273e:	60a6                	ld	ra,72(sp)
    80002740:	6406                	ld	s0,64(sp)
    80002742:	74e2                	ld	s1,56(sp)
    80002744:	7942                	ld	s2,48(sp)
    80002746:	79a2                	ld	s3,40(sp)
    80002748:	7a02                	ld	s4,32(sp)
    8000274a:	6ae2                	ld	s5,24(sp)
    8000274c:	6b42                	ld	s6,16(sp)
    8000274e:	6ba2                	ld	s7,8(sp)
    80002750:	6161                	addi	sp,sp,80
    80002752:	8082                	ret

0000000080002754 <kill_system>:

/*-----------------------------------*********************-----------------------------------*********************-----------------------------------*/

int kill_system(void)
{
    80002754:	7179                	addi	sp,sp,-48
    80002756:	f406                	sd	ra,40(sp)
    80002758:	f022                	sd	s0,32(sp)
    8000275a:	ec26                	sd	s1,24(sp)
    8000275c:	e84a                	sd	s2,16(sp)
    8000275e:	e44e                	sd	s3,8(sp)
    80002760:	e052                	sd	s4,0(sp)
    80002762:	1800                	addi	s0,sp,48
  int syscall_status = 0;
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
    80002764:	0000f497          	auipc	s1,0xf
    80002768:	f8c48493          	addi	s1,s1,-116 # 800116f0 <proc>
  int syscall_status = 0;
    8000276c:	4901                	li	s2,0
  {
    acquire(&p->lock);
    if (p->pid > 2)
    8000276e:	4a09                	li	s4,2
  for(p = proc; p < &proc[NPROC]; p++)
    80002770:	00015997          	auipc	s3,0x15
    80002774:	18098993          	addi	s3,s3,384 # 800178f0 <tickslock>
    80002778:	a811                	j	8000278c <kill_system+0x38>
      release(&p->lock);
      syscall_status = kill(p->pid) || syscall_status;
    }
    else
    {
    release(&p->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	51c080e7          	jalr	1308(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80002784:	18848493          	addi	s1,s1,392
    80002788:	03348a63          	beq	s1,s3,800027bc <kill_system+0x68>
    acquire(&p->lock);
    8000278c:	8526                	mv	a0,s1
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	456080e7          	jalr	1110(ra) # 80000be4 <acquire>
    if (p->pid > 2)
    80002796:	589c                	lw	a5,48(s1)
    80002798:	fefa51e3          	bge	s4,a5,8000277a <kill_system+0x26>
      release(&p->lock);
    8000279c:	8526                	mv	a0,s1
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	4fa080e7          	jalr	1274(ra) # 80000c98 <release>
      syscall_status = kill(p->pid) || syscall_status;
    800027a6:	5888                	lw	a0,48(s1)
    800027a8:	00000097          	auipc	ra,0x0
    800027ac:	dd6080e7          	jalr	-554(ra) # 8000257e <kill>
    800027b0:	01256533          	or	a0,a0,s2
    800027b4:	2501                	sext.w	a0,a0
    800027b6:	00a03933          	snez	s2,a0
    800027ba:	b7e9                	j	80002784 <kill_system+0x30>
    }
  }
  return !syscall_status ? 0 : -1;
}
    800027bc:	41200533          	neg	a0,s2
    800027c0:	70a2                	ld	ra,40(sp)
    800027c2:	7402                	ld	s0,32(sp)
    800027c4:	64e2                	ld	s1,24(sp)
    800027c6:	6942                	ld	s2,16(sp)
    800027c8:	69a2                	ld	s3,8(sp)
    800027ca:	6a02                	ld	s4,0(sp)
    800027cc:	6145                	addi	sp,sp,48
    800027ce:	8082                	ret

00000000800027d0 <pause_system>:

int pause_system(int seconds)
{
    800027d0:	1141                	addi	sp,sp,-16
    800027d2:	e406                	sd	ra,8(sp)
    800027d4:	e022                	sd	s0,0(sp)
    800027d6:	0800                	addi	s0,sp,16
  pause_ticks = (seconds * 10) + ticks;
    800027d8:	0025179b          	slliw	a5,a0,0x2
    800027dc:	9fa9                	addw	a5,a5,a0
    800027de:	0017979b          	slliw	a5,a5,0x1
    800027e2:	00007517          	auipc	a0,0x7
    800027e6:	86e52503          	lw	a0,-1938(a0) # 80009050 <ticks>
    800027ea:	9fa9                	addw	a5,a5,a0
    800027ec:	00007717          	auipc	a4,0x7
    800027f0:	82f72e23          	sw	a5,-1988(a4) # 80009028 <pause_ticks>
  yield();
    800027f4:	00000097          	auipc	ra,0x0
    800027f8:	8e6080e7          	jalr	-1818(ra) # 800020da <yield>
  return 0;
}
    800027fc:	4501                	li	a0,0
    800027fe:	60a2                	ld	ra,8(sp)
    80002800:	6402                	ld	s0,0(sp)
    80002802:	0141                	addi	sp,sp,16
    80002804:	8082                	ret

0000000080002806 <print_stats>:

void print_stats(void)
{
    80002806:	1141                	addi	sp,sp,-16
    80002808:	e406                	sd	ra,8(sp)
    8000280a:	e022                	sd	s0,0(sp)
    8000280c:	0800                	addi	s0,sp,16
  printf("cpu_utilization: %d%% \n", cpu_utilization);
    8000280e:	00007597          	auipc	a1,0x7
    80002812:	81e5a583          	lw	a1,-2018(a1) # 8000902c <cpu_utilization>
    80002816:	00006517          	auipc	a0,0x6
    8000281a:	a9a50513          	addi	a0,a0,-1382 # 800082b0 <digits+0x270>
    8000281e:	ffffe097          	auipc	ra,0xffffe
    80002822:	d6a080e7          	jalr	-662(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    80002826:	00007597          	auipc	a1,0x7
    8000282a:	80a5a583          	lw	a1,-2038(a1) # 80009030 <program_time>
    8000282e:	00006517          	auipc	a0,0x6
    80002832:	a9a50513          	addi	a0,a0,-1382 # 800082c8 <digits+0x288>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	d52080e7          	jalr	-686(ra) # 80000588 <printf>
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    8000283e:	00007597          	auipc	a1,0x7
    80002842:	8065a583          	lw	a1,-2042(a1) # 80009044 <sleeping_processes_mean>
    80002846:	00006517          	auipc	a0,0x6
    8000284a:	a9a50513          	addi	a0,a0,-1382 # 800082e0 <digits+0x2a0>
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	d3a080e7          	jalr	-710(ra) # 80000588 <printf>
  printf("running_processes_mean: %d\n", running_processes_mean);
    80002856:	00006597          	auipc	a1,0x6
    8000285a:	7ea5a583          	lw	a1,2026(a1) # 80009040 <running_processes_mean>
    8000285e:	00006517          	auipc	a0,0x6
    80002862:	aa250513          	addi	a0,a0,-1374 # 80008300 <digits+0x2c0>
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	d22080e7          	jalr	-734(ra) # 80000588 <printf>
  printf("runnable_processes_mean: %d\n", runnable_processes_mean);
    8000286e:	00006597          	auipc	a1,0x6
    80002872:	7ce5a583          	lw	a1,1998(a1) # 8000903c <runnable_processes_mean>
    80002876:	00006517          	auipc	a0,0x6
    8000287a:	aaa50513          	addi	a0,a0,-1366 # 80008320 <digits+0x2e0>
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	d0a080e7          	jalr	-758(ra) # 80000588 <printf>
    80002886:	60a2                	ld	ra,8(sp)
    80002888:	6402                	ld	s0,0(sp)
    8000288a:	0141                	addi	sp,sp,16
    8000288c:	8082                	ret

000000008000288e <swtch>:
    8000288e:	00153023          	sd	ra,0(a0)
    80002892:	00253423          	sd	sp,8(a0)
    80002896:	e900                	sd	s0,16(a0)
    80002898:	ed04                	sd	s1,24(a0)
    8000289a:	03253023          	sd	s2,32(a0)
    8000289e:	03353423          	sd	s3,40(a0)
    800028a2:	03453823          	sd	s4,48(a0)
    800028a6:	03553c23          	sd	s5,56(a0)
    800028aa:	05653023          	sd	s6,64(a0)
    800028ae:	05753423          	sd	s7,72(a0)
    800028b2:	05853823          	sd	s8,80(a0)
    800028b6:	05953c23          	sd	s9,88(a0)
    800028ba:	07a53023          	sd	s10,96(a0)
    800028be:	07b53423          	sd	s11,104(a0)
    800028c2:	0005b083          	ld	ra,0(a1)
    800028c6:	0085b103          	ld	sp,8(a1)
    800028ca:	6980                	ld	s0,16(a1)
    800028cc:	6d84                	ld	s1,24(a1)
    800028ce:	0205b903          	ld	s2,32(a1)
    800028d2:	0285b983          	ld	s3,40(a1)
    800028d6:	0305ba03          	ld	s4,48(a1)
    800028da:	0385ba83          	ld	s5,56(a1)
    800028de:	0405bb03          	ld	s6,64(a1)
    800028e2:	0485bb83          	ld	s7,72(a1)
    800028e6:	0505bc03          	ld	s8,80(a1)
    800028ea:	0585bc83          	ld	s9,88(a1)
    800028ee:	0605bd03          	ld	s10,96(a1)
    800028f2:	0685bd83          	ld	s11,104(a1)
    800028f6:	8082                	ret

00000000800028f8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028f8:	1141                	addi	sp,sp,-16
    800028fa:	e406                	sd	ra,8(sp)
    800028fc:	e022                	sd	s0,0(sp)
    800028fe:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002900:	00006597          	auipc	a1,0x6
    80002904:	a9858593          	addi	a1,a1,-1384 # 80008398 <states.1732+0x30>
    80002908:	00015517          	auipc	a0,0x15
    8000290c:	fe850513          	addi	a0,a0,-24 # 800178f0 <tickslock>
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
}
    80002918:	60a2                	ld	ra,8(sp)
    8000291a:	6402                	ld	s0,0(sp)
    8000291c:	0141                	addi	sp,sp,16
    8000291e:	8082                	ret

0000000080002920 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002920:	1141                	addi	sp,sp,-16
    80002922:	e422                	sd	s0,8(sp)
    80002924:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002926:	00003797          	auipc	a5,0x3
    8000292a:	50a78793          	addi	a5,a5,1290 # 80005e30 <kernelvec>
    8000292e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002932:	6422                	ld	s0,8(sp)
    80002934:	0141                	addi	sp,sp,16
    80002936:	8082                	ret

0000000080002938 <yield_wrap>:

#ifdef DEFAULT
void
yield_wrap(){
    80002938:	1141                	addi	sp,sp,-16
    8000293a:	e406                	sd	ra,8(sp)
    8000293c:	e022                	sd	s0,0(sp)
    8000293e:	0800                	addi	s0,sp,16
  yield();
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	79a080e7          	jalr	1946(ra) # 800020da <yield>
}
    80002948:	60a2                	ld	ra,8(sp)
    8000294a:	6402                	ld	s0,0(sp)
    8000294c:	0141                	addi	sp,sp,16
    8000294e:	8082                	ret

0000000080002950 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002950:	1141                	addi	sp,sp,-16
    80002952:	e406                	sd	ra,8(sp)
    80002954:	e022                	sd	s0,0(sp)
    80002956:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002958:	fffff097          	auipc	ra,0xfffff
    8000295c:	058080e7          	jalr	88(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002960:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002964:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002966:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000296a:	00004617          	auipc	a2,0x4
    8000296e:	69660613          	addi	a2,a2,1686 # 80007000 <_trampoline>
    80002972:	00004697          	auipc	a3,0x4
    80002976:	68e68693          	addi	a3,a3,1678 # 80007000 <_trampoline>
    8000297a:	8e91                	sub	a3,a3,a2
    8000297c:	040007b7          	lui	a5,0x4000
    80002980:	17fd                	addi	a5,a5,-1
    80002982:	07b2                	slli	a5,a5,0xc
    80002984:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002986:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000298a:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000298c:	180026f3          	csrr	a3,satp
    80002990:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002992:	7d38                	ld	a4,120(a0)
    80002994:	7134                	ld	a3,96(a0)
    80002996:	6585                	lui	a1,0x1
    80002998:	96ae                	add	a3,a3,a1
    8000299a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000299c:	7d38                	ld	a4,120(a0)
    8000299e:	00000697          	auipc	a3,0x0
    800029a2:	13868693          	addi	a3,a3,312 # 80002ad6 <usertrap>
    800029a6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029a8:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029aa:	8692                	mv	a3,tp
    800029ac:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ae:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029b2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029b6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ba:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029be:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029c0:	6f18                	ld	a4,24(a4)
    800029c2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029c6:	792c                	ld	a1,112(a0)
    800029c8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029ca:	00004717          	auipc	a4,0x4
    800029ce:	6c670713          	addi	a4,a4,1734 # 80007090 <userret>
    800029d2:	8f11                	sub	a4,a4,a2
    800029d4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029d6:	577d                	li	a4,-1
    800029d8:	177e                	slli	a4,a4,0x3f
    800029da:	8dd9                	or	a1,a1,a4
    800029dc:	02000537          	lui	a0,0x2000
    800029e0:	157d                	addi	a0,a0,-1
    800029e2:	0536                	slli	a0,a0,0xd
    800029e4:	9782                	jalr	a5
}
    800029e6:	60a2                	ld	ra,8(sp)
    800029e8:	6402                	ld	s0,0(sp)
    800029ea:	0141                	addi	sp,sp,16
    800029ec:	8082                	ret

00000000800029ee <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029ee:	1101                	addi	sp,sp,-32
    800029f0:	ec06                	sd	ra,24(sp)
    800029f2:	e822                	sd	s0,16(sp)
    800029f4:	e426                	sd	s1,8(sp)
    800029f6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029f8:	00015497          	auipc	s1,0x15
    800029fc:	ef848493          	addi	s1,s1,-264 # 800178f0 <tickslock>
    80002a00:	8526                	mv	a0,s1
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	1e2080e7          	jalr	482(ra) # 80000be4 <acquire>
  ticks++;
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	64650513          	addi	a0,a0,1606 # 80009050 <ticks>
    80002a12:	411c                	lw	a5,0(a0)
    80002a14:	2785                	addiw	a5,a5,1
    80002a16:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a18:	00000097          	auipc	ra,0x0
    80002a1c:	8e8080e7          	jalr	-1816(ra) # 80002300 <wakeup>
  release(&tickslock);
    80002a20:	8526                	mv	a0,s1
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	276080e7          	jalr	630(ra) # 80000c98 <release>
}
    80002a2a:	60e2                	ld	ra,24(sp)
    80002a2c:	6442                	ld	s0,16(sp)
    80002a2e:	64a2                	ld	s1,8(sp)
    80002a30:	6105                	addi	sp,sp,32
    80002a32:	8082                	ret

0000000080002a34 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a34:	1101                	addi	sp,sp,-32
    80002a36:	ec06                	sd	ra,24(sp)
    80002a38:	e822                	sd	s0,16(sp)
    80002a3a:	e426                	sd	s1,8(sp)
    80002a3c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a42:	00074d63          	bltz	a4,80002a5c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a46:	57fd                	li	a5,-1
    80002a48:	17fe                	slli	a5,a5,0x3f
    80002a4a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a4c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a4e:	06f70363          	beq	a4,a5,80002ab4 <devintr+0x80>
  }
}
    80002a52:	60e2                	ld	ra,24(sp)
    80002a54:	6442                	ld	s0,16(sp)
    80002a56:	64a2                	ld	s1,8(sp)
    80002a58:	6105                	addi	sp,sp,32
    80002a5a:	8082                	ret
     (scause & 0xff) == 9){
    80002a5c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a60:	46a5                	li	a3,9
    80002a62:	fed792e3          	bne	a5,a3,80002a46 <devintr+0x12>
    int irq = plic_claim();
    80002a66:	00003097          	auipc	ra,0x3
    80002a6a:	4d2080e7          	jalr	1234(ra) # 80005f38 <plic_claim>
    80002a6e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a70:	47a9                	li	a5,10
    80002a72:	02f50763          	beq	a0,a5,80002aa0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a76:	4785                	li	a5,1
    80002a78:	02f50963          	beq	a0,a5,80002aaa <devintr+0x76>
    return 1;
    80002a7c:	4505                	li	a0,1
    } else if(irq){
    80002a7e:	d8f1                	beqz	s1,80002a52 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a80:	85a6                	mv	a1,s1
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	91e50513          	addi	a0,a0,-1762 # 800083a0 <states.1732+0x38>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	afe080e7          	jalr	-1282(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a92:	8526                	mv	a0,s1
    80002a94:	00003097          	auipc	ra,0x3
    80002a98:	4c8080e7          	jalr	1224(ra) # 80005f5c <plic_complete>
    return 1;
    80002a9c:	4505                	li	a0,1
    80002a9e:	bf55                	j	80002a52 <devintr+0x1e>
      uartintr();
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	f08080e7          	jalr	-248(ra) # 800009a8 <uartintr>
    80002aa8:	b7ed                	j	80002a92 <devintr+0x5e>
      virtio_disk_intr();
    80002aaa:	00004097          	auipc	ra,0x4
    80002aae:	992080e7          	jalr	-1646(ra) # 8000643c <virtio_disk_intr>
    80002ab2:	b7c5                	j	80002a92 <devintr+0x5e>
    if(cpuid() == 0){
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	ed0080e7          	jalr	-304(ra) # 80001984 <cpuid>
    80002abc:	c901                	beqz	a0,80002acc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002abe:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ac2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ac4:	14479073          	csrw	sip,a5
    return 2;
    80002ac8:	4509                	li	a0,2
    80002aca:	b761                	j	80002a52 <devintr+0x1e>
      clockintr();
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	f22080e7          	jalr	-222(ra) # 800029ee <clockintr>
    80002ad4:	b7ed                	j	80002abe <devintr+0x8a>

0000000080002ad6 <usertrap>:
{
    80002ad6:	1101                	addi	sp,sp,-32
    80002ad8:	ec06                	sd	ra,24(sp)
    80002ada:	e822                	sd	s0,16(sp)
    80002adc:	e426                	sd	s1,8(sp)
    80002ade:	e04a                	sd	s2,0(sp)
    80002ae0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ae6:	1007f793          	andi	a5,a5,256
    80002aea:	e3ad                	bnez	a5,80002b4c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aec:	00003797          	auipc	a5,0x3
    80002af0:	34478793          	addi	a5,a5,836 # 80005e30 <kernelvec>
    80002af4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	eb8080e7          	jalr	-328(ra) # 800019b0 <myproc>
    80002b00:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b02:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b04:	14102773          	csrr	a4,sepc
    80002b08:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b0a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b0e:	47a1                	li	a5,8
    80002b10:	04f71c63          	bne	a4,a5,80002b68 <usertrap+0x92>
    if(p->killed)
    80002b14:	551c                	lw	a5,40(a0)
    80002b16:	e3b9                	bnez	a5,80002b5c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b18:	7cb8                	ld	a4,120(s1)
    80002b1a:	6f1c                	ld	a5,24(a4)
    80002b1c:	0791                	addi	a5,a5,4
    80002b1e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b24:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b28:	10079073          	csrw	sstatus,a5
    syscall();
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	2e0080e7          	jalr	736(ra) # 80002e0c <syscall>
  if(p->killed)
    80002b34:	549c                	lw	a5,40(s1)
    80002b36:	ebc1                	bnez	a5,80002bc6 <usertrap+0xf0>
  usertrapret();
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	e18080e7          	jalr	-488(ra) # 80002950 <usertrapret>
}
    80002b40:	60e2                	ld	ra,24(sp)
    80002b42:	6442                	ld	s0,16(sp)
    80002b44:	64a2                	ld	s1,8(sp)
    80002b46:	6902                	ld	s2,0(sp)
    80002b48:	6105                	addi	sp,sp,32
    80002b4a:	8082                	ret
    panic("usertrap: not from user mode");
    80002b4c:	00006517          	auipc	a0,0x6
    80002b50:	87450513          	addi	a0,a0,-1932 # 800083c0 <states.1732+0x58>
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	9ea080e7          	jalr	-1558(ra) # 8000053e <panic>
      exit(-1);
    80002b5c:	557d                	li	a0,-1
    80002b5e:	00000097          	auipc	ra,0x0
    80002b62:	88e080e7          	jalr	-1906(ra) # 800023ec <exit>
    80002b66:	bf4d                	j	80002b18 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b68:	00000097          	auipc	ra,0x0
    80002b6c:	ecc080e7          	jalr	-308(ra) # 80002a34 <devintr>
    80002b70:	892a                	mv	s2,a0
    80002b72:	c501                	beqz	a0,80002b7a <usertrap+0xa4>
  if(p->killed)
    80002b74:	549c                	lw	a5,40(s1)
    80002b76:	c3a1                	beqz	a5,80002bb6 <usertrap+0xe0>
    80002b78:	a815                	j	80002bac <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b7a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b7e:	5890                	lw	a2,48(s1)
    80002b80:	00006517          	auipc	a0,0x6
    80002b84:	86050513          	addi	a0,a0,-1952 # 800083e0 <states.1732+0x78>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	a00080e7          	jalr	-1536(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b90:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b94:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b98:	00006517          	auipc	a0,0x6
    80002b9c:	87850513          	addi	a0,a0,-1928 # 80008410 <states.1732+0xa8>
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	9e8080e7          	jalr	-1560(ra) # 80000588 <printf>
    p->killed = 1;
    80002ba8:	4785                	li	a5,1
    80002baa:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002bac:	557d                	li	a0,-1
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	83e080e7          	jalr	-1986(ra) # 800023ec <exit>
  if(which_dev == 2){
    80002bb6:	4789                	li	a5,2
    80002bb8:	f8f910e3          	bne	s2,a5,80002b38 <usertrap+0x62>
  yield();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	51e080e7          	jalr	1310(ra) # 800020da <yield>
}
    80002bc4:	bf95                	j	80002b38 <usertrap+0x62>
  int which_dev = 0;
    80002bc6:	4901                	li	s2,0
    80002bc8:	b7d5                	j	80002bac <usertrap+0xd6>

0000000080002bca <kerneltrap>:
{
    80002bca:	7179                	addi	sp,sp,-48
    80002bcc:	f406                	sd	ra,40(sp)
    80002bce:	f022                	sd	s0,32(sp)
    80002bd0:	ec26                	sd	s1,24(sp)
    80002bd2:	e84a                	sd	s2,16(sp)
    80002bd4:	e44e                	sd	s3,8(sp)
    80002bd6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bdc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002be4:	1004f793          	andi	a5,s1,256
    80002be8:	cb85                	beqz	a5,80002c18 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bee:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bf0:	ef85                	bnez	a5,80002c28 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	e42080e7          	jalr	-446(ra) # 80002a34 <devintr>
    80002bfa:	cd1d                	beqz	a0,80002c38 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bfc:	4789                	li	a5,2
    80002bfe:	06f50a63          	beq	a0,a5,80002c72 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c02:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c06:	10049073          	csrw	sstatus,s1
}
    80002c0a:	70a2                	ld	ra,40(sp)
    80002c0c:	7402                	ld	s0,32(sp)
    80002c0e:	64e2                	ld	s1,24(sp)
    80002c10:	6942                	ld	s2,16(sp)
    80002c12:	69a2                	ld	s3,8(sp)
    80002c14:	6145                	addi	sp,sp,48
    80002c16:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c18:	00006517          	auipc	a0,0x6
    80002c1c:	81850513          	addi	a0,a0,-2024 # 80008430 <states.1732+0xc8>
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	91e080e7          	jalr	-1762(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c28:	00006517          	auipc	a0,0x6
    80002c2c:	83050513          	addi	a0,a0,-2000 # 80008458 <states.1732+0xf0>
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c38:	85ce                	mv	a1,s3
    80002c3a:	00006517          	auipc	a0,0x6
    80002c3e:	83e50513          	addi	a0,a0,-1986 # 80008478 <states.1732+0x110>
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	946080e7          	jalr	-1722(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c4a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c4e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c52:	00006517          	auipc	a0,0x6
    80002c56:	83650513          	addi	a0,a0,-1994 # 80008488 <states.1732+0x120>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	92e080e7          	jalr	-1746(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c62:	00006517          	auipc	a0,0x6
    80002c66:	83e50513          	addi	a0,a0,-1986 # 800084a0 <states.1732+0x138>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	8d4080e7          	jalr	-1836(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	d3e080e7          	jalr	-706(ra) # 800019b0 <myproc>
    80002c7a:	d541                	beqz	a0,80002c02 <kerneltrap+0x38>
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	d34080e7          	jalr	-716(ra) # 800019b0 <myproc>
    80002c84:	4d18                	lw	a4,24(a0)
    80002c86:	4791                	li	a5,4
    80002c88:	f6f71de3          	bne	a4,a5,80002c02 <kerneltrap+0x38>
  yield();
    80002c8c:	fffff097          	auipc	ra,0xfffff
    80002c90:	44e080e7          	jalr	1102(ra) # 800020da <yield>
}
    80002c94:	b7bd                	j	80002c02 <kerneltrap+0x38>

0000000080002c96 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c96:	1101                	addi	sp,sp,-32
    80002c98:	ec06                	sd	ra,24(sp)
    80002c9a:	e822                	sd	s0,16(sp)
    80002c9c:	e426                	sd	s1,8(sp)
    80002c9e:	1000                	addi	s0,sp,32
    80002ca0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	d0e080e7          	jalr	-754(ra) # 800019b0 <myproc>
  switch (n) {
    80002caa:	4795                	li	a5,5
    80002cac:	0497e163          	bltu	a5,s1,80002cee <argraw+0x58>
    80002cb0:	048a                	slli	s1,s1,0x2
    80002cb2:	00006717          	auipc	a4,0x6
    80002cb6:	82670713          	addi	a4,a4,-2010 # 800084d8 <states.1732+0x170>
    80002cba:	94ba                	add	s1,s1,a4
    80002cbc:	409c                	lw	a5,0(s1)
    80002cbe:	97ba                	add	a5,a5,a4
    80002cc0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cc2:	7d3c                	ld	a5,120(a0)
    80002cc4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cc6:	60e2                	ld	ra,24(sp)
    80002cc8:	6442                	ld	s0,16(sp)
    80002cca:	64a2                	ld	s1,8(sp)
    80002ccc:	6105                	addi	sp,sp,32
    80002cce:	8082                	ret
    return p->trapframe->a1;
    80002cd0:	7d3c                	ld	a5,120(a0)
    80002cd2:	7fa8                	ld	a0,120(a5)
    80002cd4:	bfcd                	j	80002cc6 <argraw+0x30>
    return p->trapframe->a2;
    80002cd6:	7d3c                	ld	a5,120(a0)
    80002cd8:	63c8                	ld	a0,128(a5)
    80002cda:	b7f5                	j	80002cc6 <argraw+0x30>
    return p->trapframe->a3;
    80002cdc:	7d3c                	ld	a5,120(a0)
    80002cde:	67c8                	ld	a0,136(a5)
    80002ce0:	b7dd                	j	80002cc6 <argraw+0x30>
    return p->trapframe->a4;
    80002ce2:	7d3c                	ld	a5,120(a0)
    80002ce4:	6bc8                	ld	a0,144(a5)
    80002ce6:	b7c5                	j	80002cc6 <argraw+0x30>
    return p->trapframe->a5;
    80002ce8:	7d3c                	ld	a5,120(a0)
    80002cea:	6fc8                	ld	a0,152(a5)
    80002cec:	bfe9                	j	80002cc6 <argraw+0x30>
  panic("argraw");
    80002cee:	00005517          	auipc	a0,0x5
    80002cf2:	7c250513          	addi	a0,a0,1986 # 800084b0 <states.1732+0x148>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	848080e7          	jalr	-1976(ra) # 8000053e <panic>

0000000080002cfe <fetchaddr>:
{
    80002cfe:	1101                	addi	sp,sp,-32
    80002d00:	ec06                	sd	ra,24(sp)
    80002d02:	e822                	sd	s0,16(sp)
    80002d04:	e426                	sd	s1,8(sp)
    80002d06:	e04a                	sd	s2,0(sp)
    80002d08:	1000                	addi	s0,sp,32
    80002d0a:	84aa                	mv	s1,a0
    80002d0c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	ca2080e7          	jalr	-862(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d16:	753c                	ld	a5,104(a0)
    80002d18:	02f4f863          	bgeu	s1,a5,80002d48 <fetchaddr+0x4a>
    80002d1c:	00848713          	addi	a4,s1,8
    80002d20:	02e7e663          	bltu	a5,a4,80002d4c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d24:	46a1                	li	a3,8
    80002d26:	8626                	mv	a2,s1
    80002d28:	85ca                	mv	a1,s2
    80002d2a:	7928                	ld	a0,112(a0)
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	9d2080e7          	jalr	-1582(ra) # 800016fe <copyin>
    80002d34:	00a03533          	snez	a0,a0
    80002d38:	40a00533          	neg	a0,a0
}
    80002d3c:	60e2                	ld	ra,24(sp)
    80002d3e:	6442                	ld	s0,16(sp)
    80002d40:	64a2                	ld	s1,8(sp)
    80002d42:	6902                	ld	s2,0(sp)
    80002d44:	6105                	addi	sp,sp,32
    80002d46:	8082                	ret
    return -1;
    80002d48:	557d                	li	a0,-1
    80002d4a:	bfcd                	j	80002d3c <fetchaddr+0x3e>
    80002d4c:	557d                	li	a0,-1
    80002d4e:	b7fd                	j	80002d3c <fetchaddr+0x3e>

0000000080002d50 <fetchstr>:
{
    80002d50:	7179                	addi	sp,sp,-48
    80002d52:	f406                	sd	ra,40(sp)
    80002d54:	f022                	sd	s0,32(sp)
    80002d56:	ec26                	sd	s1,24(sp)
    80002d58:	e84a                	sd	s2,16(sp)
    80002d5a:	e44e                	sd	s3,8(sp)
    80002d5c:	1800                	addi	s0,sp,48
    80002d5e:	892a                	mv	s2,a0
    80002d60:	84ae                	mv	s1,a1
    80002d62:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	c4c080e7          	jalr	-948(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d6c:	86ce                	mv	a3,s3
    80002d6e:	864a                	mv	a2,s2
    80002d70:	85a6                	mv	a1,s1
    80002d72:	7928                	ld	a0,112(a0)
    80002d74:	fffff097          	auipc	ra,0xfffff
    80002d78:	a16080e7          	jalr	-1514(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002d7c:	00054763          	bltz	a0,80002d8a <fetchstr+0x3a>
  return strlen(buf);
    80002d80:	8526                	mv	a0,s1
    80002d82:	ffffe097          	auipc	ra,0xffffe
    80002d86:	0e2080e7          	jalr	226(ra) # 80000e64 <strlen>
}
    80002d8a:	70a2                	ld	ra,40(sp)
    80002d8c:	7402                	ld	s0,32(sp)
    80002d8e:	64e2                	ld	s1,24(sp)
    80002d90:	6942                	ld	s2,16(sp)
    80002d92:	69a2                	ld	s3,8(sp)
    80002d94:	6145                	addi	sp,sp,48
    80002d96:	8082                	ret

0000000080002d98 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d98:	1101                	addi	sp,sp,-32
    80002d9a:	ec06                	sd	ra,24(sp)
    80002d9c:	e822                	sd	s0,16(sp)
    80002d9e:	e426                	sd	s1,8(sp)
    80002da0:	1000                	addi	s0,sp,32
    80002da2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	ef2080e7          	jalr	-270(ra) # 80002c96 <argraw>
    80002dac:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dae:	4501                	li	a0,0
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6105                	addi	sp,sp,32
    80002db8:	8082                	ret

0000000080002dba <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dba:	1101                	addi	sp,sp,-32
    80002dbc:	ec06                	sd	ra,24(sp)
    80002dbe:	e822                	sd	s0,16(sp)
    80002dc0:	e426                	sd	s1,8(sp)
    80002dc2:	1000                	addi	s0,sp,32
    80002dc4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dc6:	00000097          	auipc	ra,0x0
    80002dca:	ed0080e7          	jalr	-304(ra) # 80002c96 <argraw>
    80002dce:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dd0:	4501                	li	a0,0
    80002dd2:	60e2                	ld	ra,24(sp)
    80002dd4:	6442                	ld	s0,16(sp)
    80002dd6:	64a2                	ld	s1,8(sp)
    80002dd8:	6105                	addi	sp,sp,32
    80002dda:	8082                	ret

0000000080002ddc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ddc:	1101                	addi	sp,sp,-32
    80002dde:	ec06                	sd	ra,24(sp)
    80002de0:	e822                	sd	s0,16(sp)
    80002de2:	e426                	sd	s1,8(sp)
    80002de4:	e04a                	sd	s2,0(sp)
    80002de6:	1000                	addi	s0,sp,32
    80002de8:	84ae                	mv	s1,a1
    80002dea:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	eaa080e7          	jalr	-342(ra) # 80002c96 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002df4:	864a                	mv	a2,s2
    80002df6:	85a6                	mv	a1,s1
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	f58080e7          	jalr	-168(ra) # 80002d50 <fetchstr>
}
    80002e00:	60e2                	ld	ra,24(sp)
    80002e02:	6442                	ld	s0,16(sp)
    80002e04:	64a2                	ld	s1,8(sp)
    80002e06:	6902                	ld	s2,0(sp)
    80002e08:	6105                	addi	sp,sp,32
    80002e0a:	8082                	ret

0000000080002e0c <syscall>:
[SYS_print_stats] sys_print_stats
};

void
syscall(void)
{
    80002e0c:	1101                	addi	sp,sp,-32
    80002e0e:	ec06                	sd	ra,24(sp)
    80002e10:	e822                	sd	s0,16(sp)
    80002e12:	e426                	sd	s1,8(sp)
    80002e14:	e04a                	sd	s2,0(sp)
    80002e16:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	b98080e7          	jalr	-1128(ra) # 800019b0 <myproc>
    80002e20:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e22:	07853903          	ld	s2,120(a0)
    80002e26:	0a893783          	ld	a5,168(s2)
    80002e2a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e2e:	37fd                	addiw	a5,a5,-1
    80002e30:	475d                	li	a4,23
    80002e32:	00f76f63          	bltu	a4,a5,80002e50 <syscall+0x44>
    80002e36:	00369713          	slli	a4,a3,0x3
    80002e3a:	00005797          	auipc	a5,0x5
    80002e3e:	6b678793          	addi	a5,a5,1718 # 800084f0 <syscalls>
    80002e42:	97ba                	add	a5,a5,a4
    80002e44:	639c                	ld	a5,0(a5)
    80002e46:	c789                	beqz	a5,80002e50 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e48:	9782                	jalr	a5
    80002e4a:	06a93823          	sd	a0,112(s2)
    80002e4e:	a839                	j	80002e6c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e50:	17848613          	addi	a2,s1,376
    80002e54:	588c                	lw	a1,48(s1)
    80002e56:	00005517          	auipc	a0,0x5
    80002e5a:	66250513          	addi	a0,a0,1634 # 800084b8 <states.1732+0x150>
    80002e5e:	ffffd097          	auipc	ra,0xffffd
    80002e62:	72a080e7          	jalr	1834(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e66:	7cbc                	ld	a5,120(s1)
    80002e68:	577d                	li	a4,-1
    80002e6a:	fbb8                	sd	a4,112(a5)
  }
}
    80002e6c:	60e2                	ld	ra,24(sp)
    80002e6e:	6442                	ld	s0,16(sp)
    80002e70:	64a2                	ld	s1,8(sp)
    80002e72:	6902                	ld	s2,0(sp)
    80002e74:	6105                	addi	sp,sp,32
    80002e76:	8082                	ret

0000000080002e78 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e80:	fec40593          	addi	a1,s0,-20
    80002e84:	4501                	li	a0,0
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	f12080e7          	jalr	-238(ra) # 80002d98 <argint>
    return -1;
    80002e8e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e90:	00054963          	bltz	a0,80002ea2 <sys_exit+0x2a>
  exit(n);
    80002e94:	fec42503          	lw	a0,-20(s0)
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	554080e7          	jalr	1364(ra) # 800023ec <exit>
  return 0;  // not reached
    80002ea0:	4781                	li	a5,0
}
    80002ea2:	853e                	mv	a0,a5
    80002ea4:	60e2                	ld	ra,24(sp)
    80002ea6:	6442                	ld	s0,16(sp)
    80002ea8:	6105                	addi	sp,sp,32
    80002eaa:	8082                	ret

0000000080002eac <sys_getpid>:

uint64
sys_getpid(void)
{
    80002eac:	1141                	addi	sp,sp,-16
    80002eae:	e406                	sd	ra,8(sp)
    80002eb0:	e022                	sd	s0,0(sp)
    80002eb2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	afc080e7          	jalr	-1284(ra) # 800019b0 <myproc>
}
    80002ebc:	5908                	lw	a0,48(a0)
    80002ebe:	60a2                	ld	ra,8(sp)
    80002ec0:	6402                	ld	s0,0(sp)
    80002ec2:	0141                	addi	sp,sp,16
    80002ec4:	8082                	ret

0000000080002ec6 <sys_fork>:

uint64
sys_fork(void)
{
    80002ec6:	1141                	addi	sp,sp,-16
    80002ec8:	e406                	sd	ra,8(sp)
    80002eca:	e022                	sd	s0,0(sp)
    80002ecc:	0800                	addi	s0,sp,16
  return fork();
    80002ece:	fffff097          	auipc	ra,0xfffff
    80002ed2:	eee080e7          	jalr	-274(ra) # 80001dbc <fork>
}
    80002ed6:	60a2                	ld	ra,8(sp)
    80002ed8:	6402                	ld	s0,0(sp)
    80002eda:	0141                	addi	sp,sp,16
    80002edc:	8082                	ret

0000000080002ede <sys_wait>:

uint64
sys_wait(void)
{
    80002ede:	1101                	addi	sp,sp,-32
    80002ee0:	ec06                	sd	ra,24(sp)
    80002ee2:	e822                	sd	s0,16(sp)
    80002ee4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ee6:	fe840593          	addi	a1,s0,-24
    80002eea:	4501                	li	a0,0
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	ece080e7          	jalr	-306(ra) # 80002dba <argaddr>
    80002ef4:	87aa                	mv	a5,a0
    return -1;
    80002ef6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ef8:	0007c863          	bltz	a5,80002f08 <sys_wait+0x2a>
  return wait(p);
    80002efc:	fe843503          	ld	a0,-24(s0)
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	2d8080e7          	jalr	728(ra) # 800021d8 <wait>
}
    80002f08:	60e2                	ld	ra,24(sp)
    80002f0a:	6442                	ld	s0,16(sp)
    80002f0c:	6105                	addi	sp,sp,32
    80002f0e:	8082                	ret

0000000080002f10 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f10:	7179                	addi	sp,sp,-48
    80002f12:	f406                	sd	ra,40(sp)
    80002f14:	f022                	sd	s0,32(sp)
    80002f16:	ec26                	sd	s1,24(sp)
    80002f18:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f1a:	fdc40593          	addi	a1,s0,-36
    80002f1e:	4501                	li	a0,0
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	e78080e7          	jalr	-392(ra) # 80002d98 <argint>
    80002f28:	87aa                	mv	a5,a0
    return -1;
    80002f2a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f2c:	0207c063          	bltz	a5,80002f4c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f30:	fffff097          	auipc	ra,0xfffff
    80002f34:	a80080e7          	jalr	-1408(ra) # 800019b0 <myproc>
    80002f38:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80002f3a:	fdc42503          	lw	a0,-36(s0)
    80002f3e:	fffff097          	auipc	ra,0xfffff
    80002f42:	e0a080e7          	jalr	-502(ra) # 80001d48 <growproc>
    80002f46:	00054863          	bltz	a0,80002f56 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f4a:	8526                	mv	a0,s1
}
    80002f4c:	70a2                	ld	ra,40(sp)
    80002f4e:	7402                	ld	s0,32(sp)
    80002f50:	64e2                	ld	s1,24(sp)
    80002f52:	6145                	addi	sp,sp,48
    80002f54:	8082                	ret
    return -1;
    80002f56:	557d                	li	a0,-1
    80002f58:	bfd5                	j	80002f4c <sys_sbrk+0x3c>

0000000080002f5a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f5a:	7139                	addi	sp,sp,-64
    80002f5c:	fc06                	sd	ra,56(sp)
    80002f5e:	f822                	sd	s0,48(sp)
    80002f60:	f426                	sd	s1,40(sp)
    80002f62:	f04a                	sd	s2,32(sp)
    80002f64:	ec4e                	sd	s3,24(sp)
    80002f66:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f68:	fcc40593          	addi	a1,s0,-52
    80002f6c:	4501                	li	a0,0
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	e2a080e7          	jalr	-470(ra) # 80002d98 <argint>
    return -1;
    80002f76:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f78:	06054563          	bltz	a0,80002fe2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f7c:	00015517          	auipc	a0,0x15
    80002f80:	97450513          	addi	a0,a0,-1676 # 800178f0 <tickslock>
    80002f84:	ffffe097          	auipc	ra,0xffffe
    80002f88:	c60080e7          	jalr	-928(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f8c:	00006917          	auipc	s2,0x6
    80002f90:	0c492903          	lw	s2,196(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80002f94:	fcc42783          	lw	a5,-52(s0)
    80002f98:	cf85                	beqz	a5,80002fd0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f9a:	00015997          	auipc	s3,0x15
    80002f9e:	95698993          	addi	s3,s3,-1706 # 800178f0 <tickslock>
    80002fa2:	00006497          	auipc	s1,0x6
    80002fa6:	0ae48493          	addi	s1,s1,174 # 80009050 <ticks>
    if(myproc()->killed){
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	a06080e7          	jalr	-1530(ra) # 800019b0 <myproc>
    80002fb2:	551c                	lw	a5,40(a0)
    80002fb4:	ef9d                	bnez	a5,80002ff2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fb6:	85ce                	mv	a1,s3
    80002fb8:	8526                	mv	a0,s1
    80002fba:	fffff097          	auipc	ra,0xfffff
    80002fbe:	18e080e7          	jalr	398(ra) # 80002148 <sleep>
  while(ticks - ticks0 < n){
    80002fc2:	409c                	lw	a5,0(s1)
    80002fc4:	412787bb          	subw	a5,a5,s2
    80002fc8:	fcc42703          	lw	a4,-52(s0)
    80002fcc:	fce7efe3          	bltu	a5,a4,80002faa <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fd0:	00015517          	auipc	a0,0x15
    80002fd4:	92050513          	addi	a0,a0,-1760 # 800178f0 <tickslock>
    80002fd8:	ffffe097          	auipc	ra,0xffffe
    80002fdc:	cc0080e7          	jalr	-832(ra) # 80000c98 <release>
  return 0;
    80002fe0:	4781                	li	a5,0
}
    80002fe2:	853e                	mv	a0,a5
    80002fe4:	70e2                	ld	ra,56(sp)
    80002fe6:	7442                	ld	s0,48(sp)
    80002fe8:	74a2                	ld	s1,40(sp)
    80002fea:	7902                	ld	s2,32(sp)
    80002fec:	69e2                	ld	s3,24(sp)
    80002fee:	6121                	addi	sp,sp,64
    80002ff0:	8082                	ret
      release(&tickslock);
    80002ff2:	00015517          	auipc	a0,0x15
    80002ff6:	8fe50513          	addi	a0,a0,-1794 # 800178f0 <tickslock>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	c9e080e7          	jalr	-866(ra) # 80000c98 <release>
      return -1;
    80003002:	57fd                	li	a5,-1
    80003004:	bff9                	j	80002fe2 <sys_sleep+0x88>

0000000080003006 <sys_kill>:

uint64
sys_kill(void)
{
    80003006:	1101                	addi	sp,sp,-32
    80003008:	ec06                	sd	ra,24(sp)
    8000300a:	e822                	sd	s0,16(sp)
    8000300c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000300e:	fec40593          	addi	a1,s0,-20
    80003012:	4501                	li	a0,0
    80003014:	00000097          	auipc	ra,0x0
    80003018:	d84080e7          	jalr	-636(ra) # 80002d98 <argint>
    8000301c:	87aa                	mv	a5,a0
    return -1;
    8000301e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003020:	0007c863          	bltz	a5,80003030 <sys_kill+0x2a>
  return kill(pid);
    80003024:	fec42503          	lw	a0,-20(s0)
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	556080e7          	jalr	1366(ra) # 8000257e <kill>
}
    80003030:	60e2                	ld	ra,24(sp)
    80003032:	6442                	ld	s0,16(sp)
    80003034:	6105                	addi	sp,sp,32
    80003036:	8082                	ret

0000000080003038 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003038:	1101                	addi	sp,sp,-32
    8000303a:	ec06                	sd	ra,24(sp)
    8000303c:	e822                	sd	s0,16(sp)
    8000303e:	e426                	sd	s1,8(sp)
    80003040:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003042:	00015517          	auipc	a0,0x15
    80003046:	8ae50513          	addi	a0,a0,-1874 # 800178f0 <tickslock>
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	b9a080e7          	jalr	-1126(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003052:	00006497          	auipc	s1,0x6
    80003056:	ffe4a483          	lw	s1,-2(s1) # 80009050 <ticks>
  release(&tickslock);
    8000305a:	00015517          	auipc	a0,0x15
    8000305e:	89650513          	addi	a0,a0,-1898 # 800178f0 <tickslock>
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	c36080e7          	jalr	-970(ra) # 80000c98 <release>
  return xticks;
}
    8000306a:	02049513          	slli	a0,s1,0x20
    8000306e:	9101                	srli	a0,a0,0x20
    80003070:	60e2                	ld	ra,24(sp)
    80003072:	6442                	ld	s0,16(sp)
    80003074:	64a2                	ld	s1,8(sp)
    80003076:	6105                	addi	sp,sp,32
    80003078:	8082                	ret

000000008000307a <sys_killsystem>:
/*-----------------------------------*********************-----------------------------------*********************-----------------------------------*/

//kills all processes in the system except for sh and init
uint64
sys_killsystem(void)
{
    8000307a:	1141                	addi	sp,sp,-16
    8000307c:	e406                	sd	ra,8(sp)
    8000307e:	e022                	sd	s0,0(sp)
    80003080:	0800                	addi	s0,sp,16
 kill_system();
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	6d2080e7          	jalr	1746(ra) # 80002754 <kill_system>
 return 0;
}
    8000308a:	4501                	li	a0,0
    8000308c:	60a2                	ld	ra,8(sp)
    8000308e:	6402                	ld	s0,0(sp)
    80003090:	0141                	addi	sp,sp,16
    80003092:	8082                	ret

0000000080003094 <sys_pausesystem>:

uint64
sys_pausesystem(void)
{
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	1000                	addi	s0,sp,32
  int seconds;
  if(argint(0, &seconds) < 0)
    8000309c:	fec40593          	addi	a1,s0,-20
    800030a0:	4501                	li	a0,0
    800030a2:	00000097          	auipc	ra,0x0
    800030a6:	cf6080e7          	jalr	-778(ra) # 80002d98 <argint>
    return -1;
    800030aa:	57fd                	li	a5,-1
  if(argint(0, &seconds) < 0)
    800030ac:	00054963          	bltz	a0,800030be <sys_pausesystem+0x2a>
  pause_system(seconds);
    800030b0:	fec42503          	lw	a0,-20(s0)
    800030b4:	fffff097          	auipc	ra,0xfffff
    800030b8:	71c080e7          	jalr	1820(ra) # 800027d0 <pause_system>
  return 0;
    800030bc:	4781                	li	a5,0
}
    800030be:	853e                	mv	a0,a5
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	6105                	addi	sp,sp,32
    800030c6:	8082                	ret

00000000800030c8 <sys_print_stats>:

uint64
sys_print_stats(void)
{
    800030c8:	1141                	addi	sp,sp,-16
    800030ca:	e406                	sd	ra,8(sp)
    800030cc:	e022                	sd	s0,0(sp)
    800030ce:	0800                	addi	s0,sp,16
  print_stats();
    800030d0:	fffff097          	auipc	ra,0xfffff
    800030d4:	736080e7          	jalr	1846(ra) # 80002806 <print_stats>
  return 0;
    800030d8:	4501                	li	a0,0
    800030da:	60a2                	ld	ra,8(sp)
    800030dc:	6402                	ld	s0,0(sp)
    800030de:	0141                	addi	sp,sp,16
    800030e0:	8082                	ret

00000000800030e2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030e2:	7179                	addi	sp,sp,-48
    800030e4:	f406                	sd	ra,40(sp)
    800030e6:	f022                	sd	s0,32(sp)
    800030e8:	ec26                	sd	s1,24(sp)
    800030ea:	e84a                	sd	s2,16(sp)
    800030ec:	e44e                	sd	s3,8(sp)
    800030ee:	e052                	sd	s4,0(sp)
    800030f0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030f2:	00005597          	auipc	a1,0x5
    800030f6:	4c658593          	addi	a1,a1,1222 # 800085b8 <syscalls+0xc8>
    800030fa:	00015517          	auipc	a0,0x15
    800030fe:	80e50513          	addi	a0,a0,-2034 # 80017908 <bcache>
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	a52080e7          	jalr	-1454(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000310a:	0001c797          	auipc	a5,0x1c
    8000310e:	7fe78793          	addi	a5,a5,2046 # 8001f908 <bcache+0x8000>
    80003112:	0001d717          	auipc	a4,0x1d
    80003116:	a5e70713          	addi	a4,a4,-1442 # 8001fb70 <bcache+0x8268>
    8000311a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000311e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003122:	00014497          	auipc	s1,0x14
    80003126:	7fe48493          	addi	s1,s1,2046 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    8000312a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000312c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000312e:	00005a17          	auipc	s4,0x5
    80003132:	492a0a13          	addi	s4,s4,1170 # 800085c0 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003136:	2b893783          	ld	a5,696(s2)
    8000313a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000313c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003140:	85d2                	mv	a1,s4
    80003142:	01048513          	addi	a0,s1,16
    80003146:	00001097          	auipc	ra,0x1
    8000314a:	4bc080e7          	jalr	1212(ra) # 80004602 <initsleeplock>
    bcache.head.next->prev = b;
    8000314e:	2b893783          	ld	a5,696(s2)
    80003152:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003154:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003158:	45848493          	addi	s1,s1,1112
    8000315c:	fd349de3          	bne	s1,s3,80003136 <binit+0x54>
  }
}
    80003160:	70a2                	ld	ra,40(sp)
    80003162:	7402                	ld	s0,32(sp)
    80003164:	64e2                	ld	s1,24(sp)
    80003166:	6942                	ld	s2,16(sp)
    80003168:	69a2                	ld	s3,8(sp)
    8000316a:	6a02                	ld	s4,0(sp)
    8000316c:	6145                	addi	sp,sp,48
    8000316e:	8082                	ret

0000000080003170 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003170:	7179                	addi	sp,sp,-48
    80003172:	f406                	sd	ra,40(sp)
    80003174:	f022                	sd	s0,32(sp)
    80003176:	ec26                	sd	s1,24(sp)
    80003178:	e84a                	sd	s2,16(sp)
    8000317a:	e44e                	sd	s3,8(sp)
    8000317c:	1800                	addi	s0,sp,48
    8000317e:	89aa                	mv	s3,a0
    80003180:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003182:	00014517          	auipc	a0,0x14
    80003186:	78650513          	addi	a0,a0,1926 # 80017908 <bcache>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	a5a080e7          	jalr	-1446(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003192:	0001d497          	auipc	s1,0x1d
    80003196:	a2e4b483          	ld	s1,-1490(s1) # 8001fbc0 <bcache+0x82b8>
    8000319a:	0001d797          	auipc	a5,0x1d
    8000319e:	9d678793          	addi	a5,a5,-1578 # 8001fb70 <bcache+0x8268>
    800031a2:	02f48f63          	beq	s1,a5,800031e0 <bread+0x70>
    800031a6:	873e                	mv	a4,a5
    800031a8:	a021                	j	800031b0 <bread+0x40>
    800031aa:	68a4                	ld	s1,80(s1)
    800031ac:	02e48a63          	beq	s1,a4,800031e0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031b0:	449c                	lw	a5,8(s1)
    800031b2:	ff379ce3          	bne	a5,s3,800031aa <bread+0x3a>
    800031b6:	44dc                	lw	a5,12(s1)
    800031b8:	ff2799e3          	bne	a5,s2,800031aa <bread+0x3a>
      b->refcnt++;
    800031bc:	40bc                	lw	a5,64(s1)
    800031be:	2785                	addiw	a5,a5,1
    800031c0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031c2:	00014517          	auipc	a0,0x14
    800031c6:	74650513          	addi	a0,a0,1862 # 80017908 <bcache>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	ace080e7          	jalr	-1330(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031d2:	01048513          	addi	a0,s1,16
    800031d6:	00001097          	auipc	ra,0x1
    800031da:	466080e7          	jalr	1126(ra) # 8000463c <acquiresleep>
      return b;
    800031de:	a8b9                	j	8000323c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031e0:	0001d497          	auipc	s1,0x1d
    800031e4:	9d84b483          	ld	s1,-1576(s1) # 8001fbb8 <bcache+0x82b0>
    800031e8:	0001d797          	auipc	a5,0x1d
    800031ec:	98878793          	addi	a5,a5,-1656 # 8001fb70 <bcache+0x8268>
    800031f0:	00f48863          	beq	s1,a5,80003200 <bread+0x90>
    800031f4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031f6:	40bc                	lw	a5,64(s1)
    800031f8:	cf81                	beqz	a5,80003210 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031fa:	64a4                	ld	s1,72(s1)
    800031fc:	fee49de3          	bne	s1,a4,800031f6 <bread+0x86>
  panic("bget: no buffers");
    80003200:	00005517          	auipc	a0,0x5
    80003204:	3c850513          	addi	a0,a0,968 # 800085c8 <syscalls+0xd8>
    80003208:	ffffd097          	auipc	ra,0xffffd
    8000320c:	336080e7          	jalr	822(ra) # 8000053e <panic>
      b->dev = dev;
    80003210:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003214:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003218:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000321c:	4785                	li	a5,1
    8000321e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003220:	00014517          	auipc	a0,0x14
    80003224:	6e850513          	addi	a0,a0,1768 # 80017908 <bcache>
    80003228:	ffffe097          	auipc	ra,0xffffe
    8000322c:	a70080e7          	jalr	-1424(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003230:	01048513          	addi	a0,s1,16
    80003234:	00001097          	auipc	ra,0x1
    80003238:	408080e7          	jalr	1032(ra) # 8000463c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000323c:	409c                	lw	a5,0(s1)
    8000323e:	cb89                	beqz	a5,80003250 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003240:	8526                	mv	a0,s1
    80003242:	70a2                	ld	ra,40(sp)
    80003244:	7402                	ld	s0,32(sp)
    80003246:	64e2                	ld	s1,24(sp)
    80003248:	6942                	ld	s2,16(sp)
    8000324a:	69a2                	ld	s3,8(sp)
    8000324c:	6145                	addi	sp,sp,48
    8000324e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003250:	4581                	li	a1,0
    80003252:	8526                	mv	a0,s1
    80003254:	00003097          	auipc	ra,0x3
    80003258:	f12080e7          	jalr	-238(ra) # 80006166 <virtio_disk_rw>
    b->valid = 1;
    8000325c:	4785                	li	a5,1
    8000325e:	c09c                	sw	a5,0(s1)
  return b;
    80003260:	b7c5                	j	80003240 <bread+0xd0>

0000000080003262 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003262:	1101                	addi	sp,sp,-32
    80003264:	ec06                	sd	ra,24(sp)
    80003266:	e822                	sd	s0,16(sp)
    80003268:	e426                	sd	s1,8(sp)
    8000326a:	1000                	addi	s0,sp,32
    8000326c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000326e:	0541                	addi	a0,a0,16
    80003270:	00001097          	auipc	ra,0x1
    80003274:	466080e7          	jalr	1126(ra) # 800046d6 <holdingsleep>
    80003278:	cd01                	beqz	a0,80003290 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000327a:	4585                	li	a1,1
    8000327c:	8526                	mv	a0,s1
    8000327e:	00003097          	auipc	ra,0x3
    80003282:	ee8080e7          	jalr	-280(ra) # 80006166 <virtio_disk_rw>
}
    80003286:	60e2                	ld	ra,24(sp)
    80003288:	6442                	ld	s0,16(sp)
    8000328a:	64a2                	ld	s1,8(sp)
    8000328c:	6105                	addi	sp,sp,32
    8000328e:	8082                	ret
    panic("bwrite");
    80003290:	00005517          	auipc	a0,0x5
    80003294:	35050513          	addi	a0,a0,848 # 800085e0 <syscalls+0xf0>
    80003298:	ffffd097          	auipc	ra,0xffffd
    8000329c:	2a6080e7          	jalr	678(ra) # 8000053e <panic>

00000000800032a0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032a0:	1101                	addi	sp,sp,-32
    800032a2:	ec06                	sd	ra,24(sp)
    800032a4:	e822                	sd	s0,16(sp)
    800032a6:	e426                	sd	s1,8(sp)
    800032a8:	e04a                	sd	s2,0(sp)
    800032aa:	1000                	addi	s0,sp,32
    800032ac:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ae:	01050913          	addi	s2,a0,16
    800032b2:	854a                	mv	a0,s2
    800032b4:	00001097          	auipc	ra,0x1
    800032b8:	422080e7          	jalr	1058(ra) # 800046d6 <holdingsleep>
    800032bc:	c92d                	beqz	a0,8000332e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032be:	854a                	mv	a0,s2
    800032c0:	00001097          	auipc	ra,0x1
    800032c4:	3d2080e7          	jalr	978(ra) # 80004692 <releasesleep>

  acquire(&bcache.lock);
    800032c8:	00014517          	auipc	a0,0x14
    800032cc:	64050513          	addi	a0,a0,1600 # 80017908 <bcache>
    800032d0:	ffffe097          	auipc	ra,0xffffe
    800032d4:	914080e7          	jalr	-1772(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032d8:	40bc                	lw	a5,64(s1)
    800032da:	37fd                	addiw	a5,a5,-1
    800032dc:	0007871b          	sext.w	a4,a5
    800032e0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032e2:	eb05                	bnez	a4,80003312 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032e4:	68bc                	ld	a5,80(s1)
    800032e6:	64b8                	ld	a4,72(s1)
    800032e8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032ea:	64bc                	ld	a5,72(s1)
    800032ec:	68b8                	ld	a4,80(s1)
    800032ee:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032f0:	0001c797          	auipc	a5,0x1c
    800032f4:	61878793          	addi	a5,a5,1560 # 8001f908 <bcache+0x8000>
    800032f8:	2b87b703          	ld	a4,696(a5)
    800032fc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032fe:	0001d717          	auipc	a4,0x1d
    80003302:	87270713          	addi	a4,a4,-1934 # 8001fb70 <bcache+0x8268>
    80003306:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003308:	2b87b703          	ld	a4,696(a5)
    8000330c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000330e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003312:	00014517          	auipc	a0,0x14
    80003316:	5f650513          	addi	a0,a0,1526 # 80017908 <bcache>
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	97e080e7          	jalr	-1666(ra) # 80000c98 <release>
}
    80003322:	60e2                	ld	ra,24(sp)
    80003324:	6442                	ld	s0,16(sp)
    80003326:	64a2                	ld	s1,8(sp)
    80003328:	6902                	ld	s2,0(sp)
    8000332a:	6105                	addi	sp,sp,32
    8000332c:	8082                	ret
    panic("brelse");
    8000332e:	00005517          	auipc	a0,0x5
    80003332:	2ba50513          	addi	a0,a0,698 # 800085e8 <syscalls+0xf8>
    80003336:	ffffd097          	auipc	ra,0xffffd
    8000333a:	208080e7          	jalr	520(ra) # 8000053e <panic>

000000008000333e <bpin>:

void
bpin(struct buf *b) {
    8000333e:	1101                	addi	sp,sp,-32
    80003340:	ec06                	sd	ra,24(sp)
    80003342:	e822                	sd	s0,16(sp)
    80003344:	e426                	sd	s1,8(sp)
    80003346:	1000                	addi	s0,sp,32
    80003348:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000334a:	00014517          	auipc	a0,0x14
    8000334e:	5be50513          	addi	a0,a0,1470 # 80017908 <bcache>
    80003352:	ffffe097          	auipc	ra,0xffffe
    80003356:	892080e7          	jalr	-1902(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000335a:	40bc                	lw	a5,64(s1)
    8000335c:	2785                	addiw	a5,a5,1
    8000335e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003360:	00014517          	auipc	a0,0x14
    80003364:	5a850513          	addi	a0,a0,1448 # 80017908 <bcache>
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	930080e7          	jalr	-1744(ra) # 80000c98 <release>
}
    80003370:	60e2                	ld	ra,24(sp)
    80003372:	6442                	ld	s0,16(sp)
    80003374:	64a2                	ld	s1,8(sp)
    80003376:	6105                	addi	sp,sp,32
    80003378:	8082                	ret

000000008000337a <bunpin>:

void
bunpin(struct buf *b) {
    8000337a:	1101                	addi	sp,sp,-32
    8000337c:	ec06                	sd	ra,24(sp)
    8000337e:	e822                	sd	s0,16(sp)
    80003380:	e426                	sd	s1,8(sp)
    80003382:	1000                	addi	s0,sp,32
    80003384:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003386:	00014517          	auipc	a0,0x14
    8000338a:	58250513          	addi	a0,a0,1410 # 80017908 <bcache>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	856080e7          	jalr	-1962(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003396:	40bc                	lw	a5,64(s1)
    80003398:	37fd                	addiw	a5,a5,-1
    8000339a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000339c:	00014517          	auipc	a0,0x14
    800033a0:	56c50513          	addi	a0,a0,1388 # 80017908 <bcache>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
}
    800033ac:	60e2                	ld	ra,24(sp)
    800033ae:	6442                	ld	s0,16(sp)
    800033b0:	64a2                	ld	s1,8(sp)
    800033b2:	6105                	addi	sp,sp,32
    800033b4:	8082                	ret

00000000800033b6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033b6:	1101                	addi	sp,sp,-32
    800033b8:	ec06                	sd	ra,24(sp)
    800033ba:	e822                	sd	s0,16(sp)
    800033bc:	e426                	sd	s1,8(sp)
    800033be:	e04a                	sd	s2,0(sp)
    800033c0:	1000                	addi	s0,sp,32
    800033c2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033c4:	00d5d59b          	srliw	a1,a1,0xd
    800033c8:	0001d797          	auipc	a5,0x1d
    800033cc:	c1c7a783          	lw	a5,-996(a5) # 8001ffe4 <sb+0x1c>
    800033d0:	9dbd                	addw	a1,a1,a5
    800033d2:	00000097          	auipc	ra,0x0
    800033d6:	d9e080e7          	jalr	-610(ra) # 80003170 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033da:	0074f713          	andi	a4,s1,7
    800033de:	4785                	li	a5,1
    800033e0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033e4:	14ce                	slli	s1,s1,0x33
    800033e6:	90d9                	srli	s1,s1,0x36
    800033e8:	00950733          	add	a4,a0,s1
    800033ec:	05874703          	lbu	a4,88(a4)
    800033f0:	00e7f6b3          	and	a3,a5,a4
    800033f4:	c69d                	beqz	a3,80003422 <bfree+0x6c>
    800033f6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033f8:	94aa                	add	s1,s1,a0
    800033fa:	fff7c793          	not	a5,a5
    800033fe:	8ff9                	and	a5,a5,a4
    80003400:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003404:	00001097          	auipc	ra,0x1
    80003408:	118080e7          	jalr	280(ra) # 8000451c <log_write>
  brelse(bp);
    8000340c:	854a                	mv	a0,s2
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	e92080e7          	jalr	-366(ra) # 800032a0 <brelse>
}
    80003416:	60e2                	ld	ra,24(sp)
    80003418:	6442                	ld	s0,16(sp)
    8000341a:	64a2                	ld	s1,8(sp)
    8000341c:	6902                	ld	s2,0(sp)
    8000341e:	6105                	addi	sp,sp,32
    80003420:	8082                	ret
    panic("freeing free block");
    80003422:	00005517          	auipc	a0,0x5
    80003426:	1ce50513          	addi	a0,a0,462 # 800085f0 <syscalls+0x100>
    8000342a:	ffffd097          	auipc	ra,0xffffd
    8000342e:	114080e7          	jalr	276(ra) # 8000053e <panic>

0000000080003432 <balloc>:
{
    80003432:	711d                	addi	sp,sp,-96
    80003434:	ec86                	sd	ra,88(sp)
    80003436:	e8a2                	sd	s0,80(sp)
    80003438:	e4a6                	sd	s1,72(sp)
    8000343a:	e0ca                	sd	s2,64(sp)
    8000343c:	fc4e                	sd	s3,56(sp)
    8000343e:	f852                	sd	s4,48(sp)
    80003440:	f456                	sd	s5,40(sp)
    80003442:	f05a                	sd	s6,32(sp)
    80003444:	ec5e                	sd	s7,24(sp)
    80003446:	e862                	sd	s8,16(sp)
    80003448:	e466                	sd	s9,8(sp)
    8000344a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000344c:	0001d797          	auipc	a5,0x1d
    80003450:	b807a783          	lw	a5,-1152(a5) # 8001ffcc <sb+0x4>
    80003454:	cbd1                	beqz	a5,800034e8 <balloc+0xb6>
    80003456:	8baa                	mv	s7,a0
    80003458:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000345a:	0001db17          	auipc	s6,0x1d
    8000345e:	b6eb0b13          	addi	s6,s6,-1170 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003462:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003464:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003466:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003468:	6c89                	lui	s9,0x2
    8000346a:	a831                	j	80003486 <balloc+0x54>
    brelse(bp);
    8000346c:	854a                	mv	a0,s2
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	e32080e7          	jalr	-462(ra) # 800032a0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003476:	015c87bb          	addw	a5,s9,s5
    8000347a:	00078a9b          	sext.w	s5,a5
    8000347e:	004b2703          	lw	a4,4(s6)
    80003482:	06eaf363          	bgeu	s5,a4,800034e8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003486:	41fad79b          	sraiw	a5,s5,0x1f
    8000348a:	0137d79b          	srliw	a5,a5,0x13
    8000348e:	015787bb          	addw	a5,a5,s5
    80003492:	40d7d79b          	sraiw	a5,a5,0xd
    80003496:	01cb2583          	lw	a1,28(s6)
    8000349a:	9dbd                	addw	a1,a1,a5
    8000349c:	855e                	mv	a0,s7
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	cd2080e7          	jalr	-814(ra) # 80003170 <bread>
    800034a6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a8:	004b2503          	lw	a0,4(s6)
    800034ac:	000a849b          	sext.w	s1,s5
    800034b0:	8662                	mv	a2,s8
    800034b2:	faa4fde3          	bgeu	s1,a0,8000346c <balloc+0x3a>
      m = 1 << (bi % 8);
    800034b6:	41f6579b          	sraiw	a5,a2,0x1f
    800034ba:	01d7d69b          	srliw	a3,a5,0x1d
    800034be:	00c6873b          	addw	a4,a3,a2
    800034c2:	00777793          	andi	a5,a4,7
    800034c6:	9f95                	subw	a5,a5,a3
    800034c8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034cc:	4037571b          	sraiw	a4,a4,0x3
    800034d0:	00e906b3          	add	a3,s2,a4
    800034d4:	0586c683          	lbu	a3,88(a3)
    800034d8:	00d7f5b3          	and	a1,a5,a3
    800034dc:	cd91                	beqz	a1,800034f8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034de:	2605                	addiw	a2,a2,1
    800034e0:	2485                	addiw	s1,s1,1
    800034e2:	fd4618e3          	bne	a2,s4,800034b2 <balloc+0x80>
    800034e6:	b759                	j	8000346c <balloc+0x3a>
  panic("balloc: out of blocks");
    800034e8:	00005517          	auipc	a0,0x5
    800034ec:	12050513          	addi	a0,a0,288 # 80008608 <syscalls+0x118>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	04e080e7          	jalr	78(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034f8:	974a                	add	a4,a4,s2
    800034fa:	8fd5                	or	a5,a5,a3
    800034fc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003500:	854a                	mv	a0,s2
    80003502:	00001097          	auipc	ra,0x1
    80003506:	01a080e7          	jalr	26(ra) # 8000451c <log_write>
        brelse(bp);
    8000350a:	854a                	mv	a0,s2
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	d94080e7          	jalr	-620(ra) # 800032a0 <brelse>
  bp = bread(dev, bno);
    80003514:	85a6                	mv	a1,s1
    80003516:	855e                	mv	a0,s7
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	c58080e7          	jalr	-936(ra) # 80003170 <bread>
    80003520:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003522:	40000613          	li	a2,1024
    80003526:	4581                	li	a1,0
    80003528:	05850513          	addi	a0,a0,88
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	7b4080e7          	jalr	1972(ra) # 80000ce0 <memset>
  log_write(bp);
    80003534:	854a                	mv	a0,s2
    80003536:	00001097          	auipc	ra,0x1
    8000353a:	fe6080e7          	jalr	-26(ra) # 8000451c <log_write>
  brelse(bp);
    8000353e:	854a                	mv	a0,s2
    80003540:	00000097          	auipc	ra,0x0
    80003544:	d60080e7          	jalr	-672(ra) # 800032a0 <brelse>
}
    80003548:	8526                	mv	a0,s1
    8000354a:	60e6                	ld	ra,88(sp)
    8000354c:	6446                	ld	s0,80(sp)
    8000354e:	64a6                	ld	s1,72(sp)
    80003550:	6906                	ld	s2,64(sp)
    80003552:	79e2                	ld	s3,56(sp)
    80003554:	7a42                	ld	s4,48(sp)
    80003556:	7aa2                	ld	s5,40(sp)
    80003558:	7b02                	ld	s6,32(sp)
    8000355a:	6be2                	ld	s7,24(sp)
    8000355c:	6c42                	ld	s8,16(sp)
    8000355e:	6ca2                	ld	s9,8(sp)
    80003560:	6125                	addi	sp,sp,96
    80003562:	8082                	ret

0000000080003564 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003564:	7179                	addi	sp,sp,-48
    80003566:	f406                	sd	ra,40(sp)
    80003568:	f022                	sd	s0,32(sp)
    8000356a:	ec26                	sd	s1,24(sp)
    8000356c:	e84a                	sd	s2,16(sp)
    8000356e:	e44e                	sd	s3,8(sp)
    80003570:	e052                	sd	s4,0(sp)
    80003572:	1800                	addi	s0,sp,48
    80003574:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003576:	47ad                	li	a5,11
    80003578:	04b7fe63          	bgeu	a5,a1,800035d4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000357c:	ff45849b          	addiw	s1,a1,-12
    80003580:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003584:	0ff00793          	li	a5,255
    80003588:	0ae7e363          	bltu	a5,a4,8000362e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000358c:	08052583          	lw	a1,128(a0)
    80003590:	c5ad                	beqz	a1,800035fa <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003592:	00092503          	lw	a0,0(s2)
    80003596:	00000097          	auipc	ra,0x0
    8000359a:	bda080e7          	jalr	-1062(ra) # 80003170 <bread>
    8000359e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035a0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035a4:	02049593          	slli	a1,s1,0x20
    800035a8:	9181                	srli	a1,a1,0x20
    800035aa:	058a                	slli	a1,a1,0x2
    800035ac:	00b784b3          	add	s1,a5,a1
    800035b0:	0004a983          	lw	s3,0(s1)
    800035b4:	04098d63          	beqz	s3,8000360e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035b8:	8552                	mv	a0,s4
    800035ba:	00000097          	auipc	ra,0x0
    800035be:	ce6080e7          	jalr	-794(ra) # 800032a0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035c2:	854e                	mv	a0,s3
    800035c4:	70a2                	ld	ra,40(sp)
    800035c6:	7402                	ld	s0,32(sp)
    800035c8:	64e2                	ld	s1,24(sp)
    800035ca:	6942                	ld	s2,16(sp)
    800035cc:	69a2                	ld	s3,8(sp)
    800035ce:	6a02                	ld	s4,0(sp)
    800035d0:	6145                	addi	sp,sp,48
    800035d2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035d4:	02059493          	slli	s1,a1,0x20
    800035d8:	9081                	srli	s1,s1,0x20
    800035da:	048a                	slli	s1,s1,0x2
    800035dc:	94aa                	add	s1,s1,a0
    800035de:	0504a983          	lw	s3,80(s1)
    800035e2:	fe0990e3          	bnez	s3,800035c2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035e6:	4108                	lw	a0,0(a0)
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	e4a080e7          	jalr	-438(ra) # 80003432 <balloc>
    800035f0:	0005099b          	sext.w	s3,a0
    800035f4:	0534a823          	sw	s3,80(s1)
    800035f8:	b7e9                	j	800035c2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035fa:	4108                	lw	a0,0(a0)
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	e36080e7          	jalr	-458(ra) # 80003432 <balloc>
    80003604:	0005059b          	sext.w	a1,a0
    80003608:	08b92023          	sw	a1,128(s2)
    8000360c:	b759                	j	80003592 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000360e:	00092503          	lw	a0,0(s2)
    80003612:	00000097          	auipc	ra,0x0
    80003616:	e20080e7          	jalr	-480(ra) # 80003432 <balloc>
    8000361a:	0005099b          	sext.w	s3,a0
    8000361e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003622:	8552                	mv	a0,s4
    80003624:	00001097          	auipc	ra,0x1
    80003628:	ef8080e7          	jalr	-264(ra) # 8000451c <log_write>
    8000362c:	b771                	j	800035b8 <bmap+0x54>
  panic("bmap: out of range");
    8000362e:	00005517          	auipc	a0,0x5
    80003632:	ff250513          	addi	a0,a0,-14 # 80008620 <syscalls+0x130>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	f08080e7          	jalr	-248(ra) # 8000053e <panic>

000000008000363e <iget>:
{
    8000363e:	7179                	addi	sp,sp,-48
    80003640:	f406                	sd	ra,40(sp)
    80003642:	f022                	sd	s0,32(sp)
    80003644:	ec26                	sd	s1,24(sp)
    80003646:	e84a                	sd	s2,16(sp)
    80003648:	e44e                	sd	s3,8(sp)
    8000364a:	e052                	sd	s4,0(sp)
    8000364c:	1800                	addi	s0,sp,48
    8000364e:	89aa                	mv	s3,a0
    80003650:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003652:	0001d517          	auipc	a0,0x1d
    80003656:	99650513          	addi	a0,a0,-1642 # 8001ffe8 <itable>
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	58a080e7          	jalr	1418(ra) # 80000be4 <acquire>
  empty = 0;
    80003662:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003664:	0001d497          	auipc	s1,0x1d
    80003668:	99c48493          	addi	s1,s1,-1636 # 80020000 <itable+0x18>
    8000366c:	0001e697          	auipc	a3,0x1e
    80003670:	42468693          	addi	a3,a3,1060 # 80021a90 <log>
    80003674:	a039                	j	80003682 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003676:	02090b63          	beqz	s2,800036ac <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000367a:	08848493          	addi	s1,s1,136
    8000367e:	02d48a63          	beq	s1,a3,800036b2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003682:	449c                	lw	a5,8(s1)
    80003684:	fef059e3          	blez	a5,80003676 <iget+0x38>
    80003688:	4098                	lw	a4,0(s1)
    8000368a:	ff3716e3          	bne	a4,s3,80003676 <iget+0x38>
    8000368e:	40d8                	lw	a4,4(s1)
    80003690:	ff4713e3          	bne	a4,s4,80003676 <iget+0x38>
      ip->ref++;
    80003694:	2785                	addiw	a5,a5,1
    80003696:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003698:	0001d517          	auipc	a0,0x1d
    8000369c:	95050513          	addi	a0,a0,-1712 # 8001ffe8 <itable>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	5f8080e7          	jalr	1528(ra) # 80000c98 <release>
      return ip;
    800036a8:	8926                	mv	s2,s1
    800036aa:	a03d                	j	800036d8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036ac:	f7f9                	bnez	a5,8000367a <iget+0x3c>
    800036ae:	8926                	mv	s2,s1
    800036b0:	b7e9                	j	8000367a <iget+0x3c>
  if(empty == 0)
    800036b2:	02090c63          	beqz	s2,800036ea <iget+0xac>
  ip->dev = dev;
    800036b6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036ba:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036be:	4785                	li	a5,1
    800036c0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036c4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036c8:	0001d517          	auipc	a0,0x1d
    800036cc:	92050513          	addi	a0,a0,-1760 # 8001ffe8 <itable>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	5c8080e7          	jalr	1480(ra) # 80000c98 <release>
}
    800036d8:	854a                	mv	a0,s2
    800036da:	70a2                	ld	ra,40(sp)
    800036dc:	7402                	ld	s0,32(sp)
    800036de:	64e2                	ld	s1,24(sp)
    800036e0:	6942                	ld	s2,16(sp)
    800036e2:	69a2                	ld	s3,8(sp)
    800036e4:	6a02                	ld	s4,0(sp)
    800036e6:	6145                	addi	sp,sp,48
    800036e8:	8082                	ret
    panic("iget: no inodes");
    800036ea:	00005517          	auipc	a0,0x5
    800036ee:	f4e50513          	addi	a0,a0,-178 # 80008638 <syscalls+0x148>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	e4c080e7          	jalr	-436(ra) # 8000053e <panic>

00000000800036fa <fsinit>:
fsinit(int dev) {
    800036fa:	7179                	addi	sp,sp,-48
    800036fc:	f406                	sd	ra,40(sp)
    800036fe:	f022                	sd	s0,32(sp)
    80003700:	ec26                	sd	s1,24(sp)
    80003702:	e84a                	sd	s2,16(sp)
    80003704:	e44e                	sd	s3,8(sp)
    80003706:	1800                	addi	s0,sp,48
    80003708:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000370a:	4585                	li	a1,1
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	a64080e7          	jalr	-1436(ra) # 80003170 <bread>
    80003714:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003716:	0001d997          	auipc	s3,0x1d
    8000371a:	8b298993          	addi	s3,s3,-1870 # 8001ffc8 <sb>
    8000371e:	02000613          	li	a2,32
    80003722:	05850593          	addi	a1,a0,88
    80003726:	854e                	mv	a0,s3
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	618080e7          	jalr	1560(ra) # 80000d40 <memmove>
  brelse(bp);
    80003730:	8526                	mv	a0,s1
    80003732:	00000097          	auipc	ra,0x0
    80003736:	b6e080e7          	jalr	-1170(ra) # 800032a0 <brelse>
  if(sb.magic != FSMAGIC)
    8000373a:	0009a703          	lw	a4,0(s3)
    8000373e:	102037b7          	lui	a5,0x10203
    80003742:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003746:	02f71263          	bne	a4,a5,8000376a <fsinit+0x70>
  initlog(dev, &sb);
    8000374a:	0001d597          	auipc	a1,0x1d
    8000374e:	87e58593          	addi	a1,a1,-1922 # 8001ffc8 <sb>
    80003752:	854a                	mv	a0,s2
    80003754:	00001097          	auipc	ra,0x1
    80003758:	b4c080e7          	jalr	-1204(ra) # 800042a0 <initlog>
}
    8000375c:	70a2                	ld	ra,40(sp)
    8000375e:	7402                	ld	s0,32(sp)
    80003760:	64e2                	ld	s1,24(sp)
    80003762:	6942                	ld	s2,16(sp)
    80003764:	69a2                	ld	s3,8(sp)
    80003766:	6145                	addi	sp,sp,48
    80003768:	8082                	ret
    panic("invalid file system");
    8000376a:	00005517          	auipc	a0,0x5
    8000376e:	ede50513          	addi	a0,a0,-290 # 80008648 <syscalls+0x158>
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	dcc080e7          	jalr	-564(ra) # 8000053e <panic>

000000008000377a <iinit>:
{
    8000377a:	7179                	addi	sp,sp,-48
    8000377c:	f406                	sd	ra,40(sp)
    8000377e:	f022                	sd	s0,32(sp)
    80003780:	ec26                	sd	s1,24(sp)
    80003782:	e84a                	sd	s2,16(sp)
    80003784:	e44e                	sd	s3,8(sp)
    80003786:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003788:	00005597          	auipc	a1,0x5
    8000378c:	ed858593          	addi	a1,a1,-296 # 80008660 <syscalls+0x170>
    80003790:	0001d517          	auipc	a0,0x1d
    80003794:	85850513          	addi	a0,a0,-1960 # 8001ffe8 <itable>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	3bc080e7          	jalr	956(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037a0:	0001d497          	auipc	s1,0x1d
    800037a4:	87048493          	addi	s1,s1,-1936 # 80020010 <itable+0x28>
    800037a8:	0001e997          	auipc	s3,0x1e
    800037ac:	2f898993          	addi	s3,s3,760 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037b0:	00005917          	auipc	s2,0x5
    800037b4:	eb890913          	addi	s2,s2,-328 # 80008668 <syscalls+0x178>
    800037b8:	85ca                	mv	a1,s2
    800037ba:	8526                	mv	a0,s1
    800037bc:	00001097          	auipc	ra,0x1
    800037c0:	e46080e7          	jalr	-442(ra) # 80004602 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037c4:	08848493          	addi	s1,s1,136
    800037c8:	ff3498e3          	bne	s1,s3,800037b8 <iinit+0x3e>
}
    800037cc:	70a2                	ld	ra,40(sp)
    800037ce:	7402                	ld	s0,32(sp)
    800037d0:	64e2                	ld	s1,24(sp)
    800037d2:	6942                	ld	s2,16(sp)
    800037d4:	69a2                	ld	s3,8(sp)
    800037d6:	6145                	addi	sp,sp,48
    800037d8:	8082                	ret

00000000800037da <ialloc>:
{
    800037da:	715d                	addi	sp,sp,-80
    800037dc:	e486                	sd	ra,72(sp)
    800037de:	e0a2                	sd	s0,64(sp)
    800037e0:	fc26                	sd	s1,56(sp)
    800037e2:	f84a                	sd	s2,48(sp)
    800037e4:	f44e                	sd	s3,40(sp)
    800037e6:	f052                	sd	s4,32(sp)
    800037e8:	ec56                	sd	s5,24(sp)
    800037ea:	e85a                	sd	s6,16(sp)
    800037ec:	e45e                	sd	s7,8(sp)
    800037ee:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037f0:	0001c717          	auipc	a4,0x1c
    800037f4:	7e472703          	lw	a4,2020(a4) # 8001ffd4 <sb+0xc>
    800037f8:	4785                	li	a5,1
    800037fa:	04e7fa63          	bgeu	a5,a4,8000384e <ialloc+0x74>
    800037fe:	8aaa                	mv	s5,a0
    80003800:	8bae                	mv	s7,a1
    80003802:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003804:	0001ca17          	auipc	s4,0x1c
    80003808:	7c4a0a13          	addi	s4,s4,1988 # 8001ffc8 <sb>
    8000380c:	00048b1b          	sext.w	s6,s1
    80003810:	0044d593          	srli	a1,s1,0x4
    80003814:	018a2783          	lw	a5,24(s4)
    80003818:	9dbd                	addw	a1,a1,a5
    8000381a:	8556                	mv	a0,s5
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	954080e7          	jalr	-1708(ra) # 80003170 <bread>
    80003824:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003826:	05850993          	addi	s3,a0,88
    8000382a:	00f4f793          	andi	a5,s1,15
    8000382e:	079a                	slli	a5,a5,0x6
    80003830:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003832:	00099783          	lh	a5,0(s3)
    80003836:	c785                	beqz	a5,8000385e <ialloc+0x84>
    brelse(bp);
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	a68080e7          	jalr	-1432(ra) # 800032a0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003840:	0485                	addi	s1,s1,1
    80003842:	00ca2703          	lw	a4,12(s4)
    80003846:	0004879b          	sext.w	a5,s1
    8000384a:	fce7e1e3          	bltu	a5,a4,8000380c <ialloc+0x32>
  panic("ialloc: no inodes");
    8000384e:	00005517          	auipc	a0,0x5
    80003852:	e2250513          	addi	a0,a0,-478 # 80008670 <syscalls+0x180>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	ce8080e7          	jalr	-792(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000385e:	04000613          	li	a2,64
    80003862:	4581                	li	a1,0
    80003864:	854e                	mv	a0,s3
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	47a080e7          	jalr	1146(ra) # 80000ce0 <memset>
      dip->type = type;
    8000386e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003872:	854a                	mv	a0,s2
    80003874:	00001097          	auipc	ra,0x1
    80003878:	ca8080e7          	jalr	-856(ra) # 8000451c <log_write>
      brelse(bp);
    8000387c:	854a                	mv	a0,s2
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	a22080e7          	jalr	-1502(ra) # 800032a0 <brelse>
      return iget(dev, inum);
    80003886:	85da                	mv	a1,s6
    80003888:	8556                	mv	a0,s5
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	db4080e7          	jalr	-588(ra) # 8000363e <iget>
}
    80003892:	60a6                	ld	ra,72(sp)
    80003894:	6406                	ld	s0,64(sp)
    80003896:	74e2                	ld	s1,56(sp)
    80003898:	7942                	ld	s2,48(sp)
    8000389a:	79a2                	ld	s3,40(sp)
    8000389c:	7a02                	ld	s4,32(sp)
    8000389e:	6ae2                	ld	s5,24(sp)
    800038a0:	6b42                	ld	s6,16(sp)
    800038a2:	6ba2                	ld	s7,8(sp)
    800038a4:	6161                	addi	sp,sp,80
    800038a6:	8082                	ret

00000000800038a8 <iupdate>:
{
    800038a8:	1101                	addi	sp,sp,-32
    800038aa:	ec06                	sd	ra,24(sp)
    800038ac:	e822                	sd	s0,16(sp)
    800038ae:	e426                	sd	s1,8(sp)
    800038b0:	e04a                	sd	s2,0(sp)
    800038b2:	1000                	addi	s0,sp,32
    800038b4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038b6:	415c                	lw	a5,4(a0)
    800038b8:	0047d79b          	srliw	a5,a5,0x4
    800038bc:	0001c597          	auipc	a1,0x1c
    800038c0:	7245a583          	lw	a1,1828(a1) # 8001ffe0 <sb+0x18>
    800038c4:	9dbd                	addw	a1,a1,a5
    800038c6:	4108                	lw	a0,0(a0)
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	8a8080e7          	jalr	-1880(ra) # 80003170 <bread>
    800038d0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038d2:	05850793          	addi	a5,a0,88
    800038d6:	40c8                	lw	a0,4(s1)
    800038d8:	893d                	andi	a0,a0,15
    800038da:	051a                	slli	a0,a0,0x6
    800038dc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038de:	04449703          	lh	a4,68(s1)
    800038e2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038e6:	04649703          	lh	a4,70(s1)
    800038ea:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038ee:	04849703          	lh	a4,72(s1)
    800038f2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038f6:	04a49703          	lh	a4,74(s1)
    800038fa:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038fe:	44f8                	lw	a4,76(s1)
    80003900:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003902:	03400613          	li	a2,52
    80003906:	05048593          	addi	a1,s1,80
    8000390a:	0531                	addi	a0,a0,12
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	434080e7          	jalr	1076(ra) # 80000d40 <memmove>
  log_write(bp);
    80003914:	854a                	mv	a0,s2
    80003916:	00001097          	auipc	ra,0x1
    8000391a:	c06080e7          	jalr	-1018(ra) # 8000451c <log_write>
  brelse(bp);
    8000391e:	854a                	mv	a0,s2
    80003920:	00000097          	auipc	ra,0x0
    80003924:	980080e7          	jalr	-1664(ra) # 800032a0 <brelse>
}
    80003928:	60e2                	ld	ra,24(sp)
    8000392a:	6442                	ld	s0,16(sp)
    8000392c:	64a2                	ld	s1,8(sp)
    8000392e:	6902                	ld	s2,0(sp)
    80003930:	6105                	addi	sp,sp,32
    80003932:	8082                	ret

0000000080003934 <idup>:
{
    80003934:	1101                	addi	sp,sp,-32
    80003936:	ec06                	sd	ra,24(sp)
    80003938:	e822                	sd	s0,16(sp)
    8000393a:	e426                	sd	s1,8(sp)
    8000393c:	1000                	addi	s0,sp,32
    8000393e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003940:	0001c517          	auipc	a0,0x1c
    80003944:	6a850513          	addi	a0,a0,1704 # 8001ffe8 <itable>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	29c080e7          	jalr	668(ra) # 80000be4 <acquire>
  ip->ref++;
    80003950:	449c                	lw	a5,8(s1)
    80003952:	2785                	addiw	a5,a5,1
    80003954:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003956:	0001c517          	auipc	a0,0x1c
    8000395a:	69250513          	addi	a0,a0,1682 # 8001ffe8 <itable>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	33a080e7          	jalr	826(ra) # 80000c98 <release>
}
    80003966:	8526                	mv	a0,s1
    80003968:	60e2                	ld	ra,24(sp)
    8000396a:	6442                	ld	s0,16(sp)
    8000396c:	64a2                	ld	s1,8(sp)
    8000396e:	6105                	addi	sp,sp,32
    80003970:	8082                	ret

0000000080003972 <ilock>:
{
    80003972:	1101                	addi	sp,sp,-32
    80003974:	ec06                	sd	ra,24(sp)
    80003976:	e822                	sd	s0,16(sp)
    80003978:	e426                	sd	s1,8(sp)
    8000397a:	e04a                	sd	s2,0(sp)
    8000397c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000397e:	c115                	beqz	a0,800039a2 <ilock+0x30>
    80003980:	84aa                	mv	s1,a0
    80003982:	451c                	lw	a5,8(a0)
    80003984:	00f05f63          	blez	a5,800039a2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003988:	0541                	addi	a0,a0,16
    8000398a:	00001097          	auipc	ra,0x1
    8000398e:	cb2080e7          	jalr	-846(ra) # 8000463c <acquiresleep>
  if(ip->valid == 0){
    80003992:	40bc                	lw	a5,64(s1)
    80003994:	cf99                	beqz	a5,800039b2 <ilock+0x40>
}
    80003996:	60e2                	ld	ra,24(sp)
    80003998:	6442                	ld	s0,16(sp)
    8000399a:	64a2                	ld	s1,8(sp)
    8000399c:	6902                	ld	s2,0(sp)
    8000399e:	6105                	addi	sp,sp,32
    800039a0:	8082                	ret
    panic("ilock");
    800039a2:	00005517          	auipc	a0,0x5
    800039a6:	ce650513          	addi	a0,a0,-794 # 80008688 <syscalls+0x198>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	b94080e7          	jalr	-1132(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039b2:	40dc                	lw	a5,4(s1)
    800039b4:	0047d79b          	srliw	a5,a5,0x4
    800039b8:	0001c597          	auipc	a1,0x1c
    800039bc:	6285a583          	lw	a1,1576(a1) # 8001ffe0 <sb+0x18>
    800039c0:	9dbd                	addw	a1,a1,a5
    800039c2:	4088                	lw	a0,0(s1)
    800039c4:	fffff097          	auipc	ra,0xfffff
    800039c8:	7ac080e7          	jalr	1964(ra) # 80003170 <bread>
    800039cc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039ce:	05850593          	addi	a1,a0,88
    800039d2:	40dc                	lw	a5,4(s1)
    800039d4:	8bbd                	andi	a5,a5,15
    800039d6:	079a                	slli	a5,a5,0x6
    800039d8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039da:	00059783          	lh	a5,0(a1)
    800039de:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039e2:	00259783          	lh	a5,2(a1)
    800039e6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039ea:	00459783          	lh	a5,4(a1)
    800039ee:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039f2:	00659783          	lh	a5,6(a1)
    800039f6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039fa:	459c                	lw	a5,8(a1)
    800039fc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039fe:	03400613          	li	a2,52
    80003a02:	05b1                	addi	a1,a1,12
    80003a04:	05048513          	addi	a0,s1,80
    80003a08:	ffffd097          	auipc	ra,0xffffd
    80003a0c:	338080e7          	jalr	824(ra) # 80000d40 <memmove>
    brelse(bp);
    80003a10:	854a                	mv	a0,s2
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	88e080e7          	jalr	-1906(ra) # 800032a0 <brelse>
    ip->valid = 1;
    80003a1a:	4785                	li	a5,1
    80003a1c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a1e:	04449783          	lh	a5,68(s1)
    80003a22:	fbb5                	bnez	a5,80003996 <ilock+0x24>
      panic("ilock: no type");
    80003a24:	00005517          	auipc	a0,0x5
    80003a28:	c6c50513          	addi	a0,a0,-916 # 80008690 <syscalls+0x1a0>
    80003a2c:	ffffd097          	auipc	ra,0xffffd
    80003a30:	b12080e7          	jalr	-1262(ra) # 8000053e <panic>

0000000080003a34 <iunlock>:
{
    80003a34:	1101                	addi	sp,sp,-32
    80003a36:	ec06                	sd	ra,24(sp)
    80003a38:	e822                	sd	s0,16(sp)
    80003a3a:	e426                	sd	s1,8(sp)
    80003a3c:	e04a                	sd	s2,0(sp)
    80003a3e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a40:	c905                	beqz	a0,80003a70 <iunlock+0x3c>
    80003a42:	84aa                	mv	s1,a0
    80003a44:	01050913          	addi	s2,a0,16
    80003a48:	854a                	mv	a0,s2
    80003a4a:	00001097          	auipc	ra,0x1
    80003a4e:	c8c080e7          	jalr	-884(ra) # 800046d6 <holdingsleep>
    80003a52:	cd19                	beqz	a0,80003a70 <iunlock+0x3c>
    80003a54:	449c                	lw	a5,8(s1)
    80003a56:	00f05d63          	blez	a5,80003a70 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	00001097          	auipc	ra,0x1
    80003a60:	c36080e7          	jalr	-970(ra) # 80004692 <releasesleep>
}
    80003a64:	60e2                	ld	ra,24(sp)
    80003a66:	6442                	ld	s0,16(sp)
    80003a68:	64a2                	ld	s1,8(sp)
    80003a6a:	6902                	ld	s2,0(sp)
    80003a6c:	6105                	addi	sp,sp,32
    80003a6e:	8082                	ret
    panic("iunlock");
    80003a70:	00005517          	auipc	a0,0x5
    80003a74:	c3050513          	addi	a0,a0,-976 # 800086a0 <syscalls+0x1b0>
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	ac6080e7          	jalr	-1338(ra) # 8000053e <panic>

0000000080003a80 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a80:	7179                	addi	sp,sp,-48
    80003a82:	f406                	sd	ra,40(sp)
    80003a84:	f022                	sd	s0,32(sp)
    80003a86:	ec26                	sd	s1,24(sp)
    80003a88:	e84a                	sd	s2,16(sp)
    80003a8a:	e44e                	sd	s3,8(sp)
    80003a8c:	e052                	sd	s4,0(sp)
    80003a8e:	1800                	addi	s0,sp,48
    80003a90:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a92:	05050493          	addi	s1,a0,80
    80003a96:	08050913          	addi	s2,a0,128
    80003a9a:	a021                	j	80003aa2 <itrunc+0x22>
    80003a9c:	0491                	addi	s1,s1,4
    80003a9e:	01248d63          	beq	s1,s2,80003ab8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003aa2:	408c                	lw	a1,0(s1)
    80003aa4:	dde5                	beqz	a1,80003a9c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aa6:	0009a503          	lw	a0,0(s3)
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	90c080e7          	jalr	-1780(ra) # 800033b6 <bfree>
      ip->addrs[i] = 0;
    80003ab2:	0004a023          	sw	zero,0(s1)
    80003ab6:	b7dd                	j	80003a9c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ab8:	0809a583          	lw	a1,128(s3)
    80003abc:	e185                	bnez	a1,80003adc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003abe:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ac2:	854e                	mv	a0,s3
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	de4080e7          	jalr	-540(ra) # 800038a8 <iupdate>
}
    80003acc:	70a2                	ld	ra,40(sp)
    80003ace:	7402                	ld	s0,32(sp)
    80003ad0:	64e2                	ld	s1,24(sp)
    80003ad2:	6942                	ld	s2,16(sp)
    80003ad4:	69a2                	ld	s3,8(sp)
    80003ad6:	6a02                	ld	s4,0(sp)
    80003ad8:	6145                	addi	sp,sp,48
    80003ada:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003adc:	0009a503          	lw	a0,0(s3)
    80003ae0:	fffff097          	auipc	ra,0xfffff
    80003ae4:	690080e7          	jalr	1680(ra) # 80003170 <bread>
    80003ae8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003aea:	05850493          	addi	s1,a0,88
    80003aee:	45850913          	addi	s2,a0,1112
    80003af2:	a811                	j	80003b06 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003af4:	0009a503          	lw	a0,0(s3)
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	8be080e7          	jalr	-1858(ra) # 800033b6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b00:	0491                	addi	s1,s1,4
    80003b02:	01248563          	beq	s1,s2,80003b0c <itrunc+0x8c>
      if(a[j])
    80003b06:	408c                	lw	a1,0(s1)
    80003b08:	dde5                	beqz	a1,80003b00 <itrunc+0x80>
    80003b0a:	b7ed                	j	80003af4 <itrunc+0x74>
    brelse(bp);
    80003b0c:	8552                	mv	a0,s4
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	792080e7          	jalr	1938(ra) # 800032a0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b16:	0809a583          	lw	a1,128(s3)
    80003b1a:	0009a503          	lw	a0,0(s3)
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	898080e7          	jalr	-1896(ra) # 800033b6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b26:	0809a023          	sw	zero,128(s3)
    80003b2a:	bf51                	j	80003abe <itrunc+0x3e>

0000000080003b2c <iput>:
{
    80003b2c:	1101                	addi	sp,sp,-32
    80003b2e:	ec06                	sd	ra,24(sp)
    80003b30:	e822                	sd	s0,16(sp)
    80003b32:	e426                	sd	s1,8(sp)
    80003b34:	e04a                	sd	s2,0(sp)
    80003b36:	1000                	addi	s0,sp,32
    80003b38:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b3a:	0001c517          	auipc	a0,0x1c
    80003b3e:	4ae50513          	addi	a0,a0,1198 # 8001ffe8 <itable>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	0a2080e7          	jalr	162(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b4a:	4498                	lw	a4,8(s1)
    80003b4c:	4785                	li	a5,1
    80003b4e:	02f70363          	beq	a4,a5,80003b74 <iput+0x48>
  ip->ref--;
    80003b52:	449c                	lw	a5,8(s1)
    80003b54:	37fd                	addiw	a5,a5,-1
    80003b56:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b58:	0001c517          	auipc	a0,0x1c
    80003b5c:	49050513          	addi	a0,a0,1168 # 8001ffe8 <itable>
    80003b60:	ffffd097          	auipc	ra,0xffffd
    80003b64:	138080e7          	jalr	312(ra) # 80000c98 <release>
}
    80003b68:	60e2                	ld	ra,24(sp)
    80003b6a:	6442                	ld	s0,16(sp)
    80003b6c:	64a2                	ld	s1,8(sp)
    80003b6e:	6902                	ld	s2,0(sp)
    80003b70:	6105                	addi	sp,sp,32
    80003b72:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b74:	40bc                	lw	a5,64(s1)
    80003b76:	dff1                	beqz	a5,80003b52 <iput+0x26>
    80003b78:	04a49783          	lh	a5,74(s1)
    80003b7c:	fbf9                	bnez	a5,80003b52 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b7e:	01048913          	addi	s2,s1,16
    80003b82:	854a                	mv	a0,s2
    80003b84:	00001097          	auipc	ra,0x1
    80003b88:	ab8080e7          	jalr	-1352(ra) # 8000463c <acquiresleep>
    release(&itable.lock);
    80003b8c:	0001c517          	auipc	a0,0x1c
    80003b90:	45c50513          	addi	a0,a0,1116 # 8001ffe8 <itable>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	104080e7          	jalr	260(ra) # 80000c98 <release>
    itrunc(ip);
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	00000097          	auipc	ra,0x0
    80003ba2:	ee2080e7          	jalr	-286(ra) # 80003a80 <itrunc>
    ip->type = 0;
    80003ba6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003baa:	8526                	mv	a0,s1
    80003bac:	00000097          	auipc	ra,0x0
    80003bb0:	cfc080e7          	jalr	-772(ra) # 800038a8 <iupdate>
    ip->valid = 0;
    80003bb4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bb8:	854a                	mv	a0,s2
    80003bba:	00001097          	auipc	ra,0x1
    80003bbe:	ad8080e7          	jalr	-1320(ra) # 80004692 <releasesleep>
    acquire(&itable.lock);
    80003bc2:	0001c517          	auipc	a0,0x1c
    80003bc6:	42650513          	addi	a0,a0,1062 # 8001ffe8 <itable>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	01a080e7          	jalr	26(ra) # 80000be4 <acquire>
    80003bd2:	b741                	j	80003b52 <iput+0x26>

0000000080003bd4 <iunlockput>:
{
    80003bd4:	1101                	addi	sp,sp,-32
    80003bd6:	ec06                	sd	ra,24(sp)
    80003bd8:	e822                	sd	s0,16(sp)
    80003bda:	e426                	sd	s1,8(sp)
    80003bdc:	1000                	addi	s0,sp,32
    80003bde:	84aa                	mv	s1,a0
  iunlock(ip);
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	e54080e7          	jalr	-428(ra) # 80003a34 <iunlock>
  iput(ip);
    80003be8:	8526                	mv	a0,s1
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	f42080e7          	jalr	-190(ra) # 80003b2c <iput>
}
    80003bf2:	60e2                	ld	ra,24(sp)
    80003bf4:	6442                	ld	s0,16(sp)
    80003bf6:	64a2                	ld	s1,8(sp)
    80003bf8:	6105                	addi	sp,sp,32
    80003bfa:	8082                	ret

0000000080003bfc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bfc:	1141                	addi	sp,sp,-16
    80003bfe:	e422                	sd	s0,8(sp)
    80003c00:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c02:	411c                	lw	a5,0(a0)
    80003c04:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c06:	415c                	lw	a5,4(a0)
    80003c08:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c0a:	04451783          	lh	a5,68(a0)
    80003c0e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c12:	04a51783          	lh	a5,74(a0)
    80003c16:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c1a:	04c56783          	lwu	a5,76(a0)
    80003c1e:	e99c                	sd	a5,16(a1)
}
    80003c20:	6422                	ld	s0,8(sp)
    80003c22:	0141                	addi	sp,sp,16
    80003c24:	8082                	ret

0000000080003c26 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c26:	457c                	lw	a5,76(a0)
    80003c28:	0ed7e963          	bltu	a5,a3,80003d1a <readi+0xf4>
{
    80003c2c:	7159                	addi	sp,sp,-112
    80003c2e:	f486                	sd	ra,104(sp)
    80003c30:	f0a2                	sd	s0,96(sp)
    80003c32:	eca6                	sd	s1,88(sp)
    80003c34:	e8ca                	sd	s2,80(sp)
    80003c36:	e4ce                	sd	s3,72(sp)
    80003c38:	e0d2                	sd	s4,64(sp)
    80003c3a:	fc56                	sd	s5,56(sp)
    80003c3c:	f85a                	sd	s6,48(sp)
    80003c3e:	f45e                	sd	s7,40(sp)
    80003c40:	f062                	sd	s8,32(sp)
    80003c42:	ec66                	sd	s9,24(sp)
    80003c44:	e86a                	sd	s10,16(sp)
    80003c46:	e46e                	sd	s11,8(sp)
    80003c48:	1880                	addi	s0,sp,112
    80003c4a:	8baa                	mv	s7,a0
    80003c4c:	8c2e                	mv	s8,a1
    80003c4e:	8ab2                	mv	s5,a2
    80003c50:	84b6                	mv	s1,a3
    80003c52:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c54:	9f35                	addw	a4,a4,a3
    return 0;
    80003c56:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c58:	0ad76063          	bltu	a4,a3,80003cf8 <readi+0xd2>
  if(off + n > ip->size)
    80003c5c:	00e7f463          	bgeu	a5,a4,80003c64 <readi+0x3e>
    n = ip->size - off;
    80003c60:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c64:	0a0b0963          	beqz	s6,80003d16 <readi+0xf0>
    80003c68:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c6a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c6e:	5cfd                	li	s9,-1
    80003c70:	a82d                	j	80003caa <readi+0x84>
    80003c72:	020a1d93          	slli	s11,s4,0x20
    80003c76:	020ddd93          	srli	s11,s11,0x20
    80003c7a:	05890613          	addi	a2,s2,88
    80003c7e:	86ee                	mv	a3,s11
    80003c80:	963a                	add	a2,a2,a4
    80003c82:	85d6                	mv	a1,s5
    80003c84:	8562                	mv	a0,s8
    80003c86:	fffff097          	auipc	ra,0xfffff
    80003c8a:	974080e7          	jalr	-1676(ra) # 800025fa <either_copyout>
    80003c8e:	05950d63          	beq	a0,s9,80003ce8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c92:	854a                	mv	a0,s2
    80003c94:	fffff097          	auipc	ra,0xfffff
    80003c98:	60c080e7          	jalr	1548(ra) # 800032a0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c9c:	013a09bb          	addw	s3,s4,s3
    80003ca0:	009a04bb          	addw	s1,s4,s1
    80003ca4:	9aee                	add	s5,s5,s11
    80003ca6:	0569f763          	bgeu	s3,s6,80003cf4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003caa:	000ba903          	lw	s2,0(s7)
    80003cae:	00a4d59b          	srliw	a1,s1,0xa
    80003cb2:	855e                	mv	a0,s7
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	8b0080e7          	jalr	-1872(ra) # 80003564 <bmap>
    80003cbc:	0005059b          	sext.w	a1,a0
    80003cc0:	854a                	mv	a0,s2
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	4ae080e7          	jalr	1198(ra) # 80003170 <bread>
    80003cca:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ccc:	3ff4f713          	andi	a4,s1,1023
    80003cd0:	40ed07bb          	subw	a5,s10,a4
    80003cd4:	413b06bb          	subw	a3,s6,s3
    80003cd8:	8a3e                	mv	s4,a5
    80003cda:	2781                	sext.w	a5,a5
    80003cdc:	0006861b          	sext.w	a2,a3
    80003ce0:	f8f679e3          	bgeu	a2,a5,80003c72 <readi+0x4c>
    80003ce4:	8a36                	mv	s4,a3
    80003ce6:	b771                	j	80003c72 <readi+0x4c>
      brelse(bp);
    80003ce8:	854a                	mv	a0,s2
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	5b6080e7          	jalr	1462(ra) # 800032a0 <brelse>
      tot = -1;
    80003cf2:	59fd                	li	s3,-1
  }
  return tot;
    80003cf4:	0009851b          	sext.w	a0,s3
}
    80003cf8:	70a6                	ld	ra,104(sp)
    80003cfa:	7406                	ld	s0,96(sp)
    80003cfc:	64e6                	ld	s1,88(sp)
    80003cfe:	6946                	ld	s2,80(sp)
    80003d00:	69a6                	ld	s3,72(sp)
    80003d02:	6a06                	ld	s4,64(sp)
    80003d04:	7ae2                	ld	s5,56(sp)
    80003d06:	7b42                	ld	s6,48(sp)
    80003d08:	7ba2                	ld	s7,40(sp)
    80003d0a:	7c02                	ld	s8,32(sp)
    80003d0c:	6ce2                	ld	s9,24(sp)
    80003d0e:	6d42                	ld	s10,16(sp)
    80003d10:	6da2                	ld	s11,8(sp)
    80003d12:	6165                	addi	sp,sp,112
    80003d14:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d16:	89da                	mv	s3,s6
    80003d18:	bff1                	j	80003cf4 <readi+0xce>
    return 0;
    80003d1a:	4501                	li	a0,0
}
    80003d1c:	8082                	ret

0000000080003d1e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d1e:	457c                	lw	a5,76(a0)
    80003d20:	10d7e863          	bltu	a5,a3,80003e30 <writei+0x112>
{
    80003d24:	7159                	addi	sp,sp,-112
    80003d26:	f486                	sd	ra,104(sp)
    80003d28:	f0a2                	sd	s0,96(sp)
    80003d2a:	eca6                	sd	s1,88(sp)
    80003d2c:	e8ca                	sd	s2,80(sp)
    80003d2e:	e4ce                	sd	s3,72(sp)
    80003d30:	e0d2                	sd	s4,64(sp)
    80003d32:	fc56                	sd	s5,56(sp)
    80003d34:	f85a                	sd	s6,48(sp)
    80003d36:	f45e                	sd	s7,40(sp)
    80003d38:	f062                	sd	s8,32(sp)
    80003d3a:	ec66                	sd	s9,24(sp)
    80003d3c:	e86a                	sd	s10,16(sp)
    80003d3e:	e46e                	sd	s11,8(sp)
    80003d40:	1880                	addi	s0,sp,112
    80003d42:	8b2a                	mv	s6,a0
    80003d44:	8c2e                	mv	s8,a1
    80003d46:	8ab2                	mv	s5,a2
    80003d48:	8936                	mv	s2,a3
    80003d4a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d4c:	00e687bb          	addw	a5,a3,a4
    80003d50:	0ed7e263          	bltu	a5,a3,80003e34 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d54:	00043737          	lui	a4,0x43
    80003d58:	0ef76063          	bltu	a4,a5,80003e38 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d5c:	0c0b8863          	beqz	s7,80003e2c <writei+0x10e>
    80003d60:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d62:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d66:	5cfd                	li	s9,-1
    80003d68:	a091                	j	80003dac <writei+0x8e>
    80003d6a:	02099d93          	slli	s11,s3,0x20
    80003d6e:	020ddd93          	srli	s11,s11,0x20
    80003d72:	05848513          	addi	a0,s1,88
    80003d76:	86ee                	mv	a3,s11
    80003d78:	8656                	mv	a2,s5
    80003d7a:	85e2                	mv	a1,s8
    80003d7c:	953a                	add	a0,a0,a4
    80003d7e:	fffff097          	auipc	ra,0xfffff
    80003d82:	8d2080e7          	jalr	-1838(ra) # 80002650 <either_copyin>
    80003d86:	07950263          	beq	a0,s9,80003dea <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d8a:	8526                	mv	a0,s1
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	790080e7          	jalr	1936(ra) # 8000451c <log_write>
    brelse(bp);
    80003d94:	8526                	mv	a0,s1
    80003d96:	fffff097          	auipc	ra,0xfffff
    80003d9a:	50a080e7          	jalr	1290(ra) # 800032a0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d9e:	01498a3b          	addw	s4,s3,s4
    80003da2:	0129893b          	addw	s2,s3,s2
    80003da6:	9aee                	add	s5,s5,s11
    80003da8:	057a7663          	bgeu	s4,s7,80003df4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dac:	000b2483          	lw	s1,0(s6)
    80003db0:	00a9559b          	srliw	a1,s2,0xa
    80003db4:	855a                	mv	a0,s6
    80003db6:	fffff097          	auipc	ra,0xfffff
    80003dba:	7ae080e7          	jalr	1966(ra) # 80003564 <bmap>
    80003dbe:	0005059b          	sext.w	a1,a0
    80003dc2:	8526                	mv	a0,s1
    80003dc4:	fffff097          	auipc	ra,0xfffff
    80003dc8:	3ac080e7          	jalr	940(ra) # 80003170 <bread>
    80003dcc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dce:	3ff97713          	andi	a4,s2,1023
    80003dd2:	40ed07bb          	subw	a5,s10,a4
    80003dd6:	414b86bb          	subw	a3,s7,s4
    80003dda:	89be                	mv	s3,a5
    80003ddc:	2781                	sext.w	a5,a5
    80003dde:	0006861b          	sext.w	a2,a3
    80003de2:	f8f674e3          	bgeu	a2,a5,80003d6a <writei+0x4c>
    80003de6:	89b6                	mv	s3,a3
    80003de8:	b749                	j	80003d6a <writei+0x4c>
      brelse(bp);
    80003dea:	8526                	mv	a0,s1
    80003dec:	fffff097          	auipc	ra,0xfffff
    80003df0:	4b4080e7          	jalr	1204(ra) # 800032a0 <brelse>
  }

  if(off > ip->size)
    80003df4:	04cb2783          	lw	a5,76(s6)
    80003df8:	0127f463          	bgeu	a5,s2,80003e00 <writei+0xe2>
    ip->size = off;
    80003dfc:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e00:	855a                	mv	a0,s6
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	aa6080e7          	jalr	-1370(ra) # 800038a8 <iupdate>

  return tot;
    80003e0a:	000a051b          	sext.w	a0,s4
}
    80003e0e:	70a6                	ld	ra,104(sp)
    80003e10:	7406                	ld	s0,96(sp)
    80003e12:	64e6                	ld	s1,88(sp)
    80003e14:	6946                	ld	s2,80(sp)
    80003e16:	69a6                	ld	s3,72(sp)
    80003e18:	6a06                	ld	s4,64(sp)
    80003e1a:	7ae2                	ld	s5,56(sp)
    80003e1c:	7b42                	ld	s6,48(sp)
    80003e1e:	7ba2                	ld	s7,40(sp)
    80003e20:	7c02                	ld	s8,32(sp)
    80003e22:	6ce2                	ld	s9,24(sp)
    80003e24:	6d42                	ld	s10,16(sp)
    80003e26:	6da2                	ld	s11,8(sp)
    80003e28:	6165                	addi	sp,sp,112
    80003e2a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e2c:	8a5e                	mv	s4,s7
    80003e2e:	bfc9                	j	80003e00 <writei+0xe2>
    return -1;
    80003e30:	557d                	li	a0,-1
}
    80003e32:	8082                	ret
    return -1;
    80003e34:	557d                	li	a0,-1
    80003e36:	bfe1                	j	80003e0e <writei+0xf0>
    return -1;
    80003e38:	557d                	li	a0,-1
    80003e3a:	bfd1                	j	80003e0e <writei+0xf0>

0000000080003e3c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e3c:	1141                	addi	sp,sp,-16
    80003e3e:	e406                	sd	ra,8(sp)
    80003e40:	e022                	sd	s0,0(sp)
    80003e42:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e44:	4639                	li	a2,14
    80003e46:	ffffd097          	auipc	ra,0xffffd
    80003e4a:	f72080e7          	jalr	-142(ra) # 80000db8 <strncmp>
}
    80003e4e:	60a2                	ld	ra,8(sp)
    80003e50:	6402                	ld	s0,0(sp)
    80003e52:	0141                	addi	sp,sp,16
    80003e54:	8082                	ret

0000000080003e56 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e56:	7139                	addi	sp,sp,-64
    80003e58:	fc06                	sd	ra,56(sp)
    80003e5a:	f822                	sd	s0,48(sp)
    80003e5c:	f426                	sd	s1,40(sp)
    80003e5e:	f04a                	sd	s2,32(sp)
    80003e60:	ec4e                	sd	s3,24(sp)
    80003e62:	e852                	sd	s4,16(sp)
    80003e64:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e66:	04451703          	lh	a4,68(a0)
    80003e6a:	4785                	li	a5,1
    80003e6c:	00f71a63          	bne	a4,a5,80003e80 <dirlookup+0x2a>
    80003e70:	892a                	mv	s2,a0
    80003e72:	89ae                	mv	s3,a1
    80003e74:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e76:	457c                	lw	a5,76(a0)
    80003e78:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e7a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7c:	e79d                	bnez	a5,80003eaa <dirlookup+0x54>
    80003e7e:	a8a5                	j	80003ef6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e80:	00005517          	auipc	a0,0x5
    80003e84:	82850513          	addi	a0,a0,-2008 # 800086a8 <syscalls+0x1b8>
    80003e88:	ffffc097          	auipc	ra,0xffffc
    80003e8c:	6b6080e7          	jalr	1718(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e90:	00005517          	auipc	a0,0x5
    80003e94:	83050513          	addi	a0,a0,-2000 # 800086c0 <syscalls+0x1d0>
    80003e98:	ffffc097          	auipc	ra,0xffffc
    80003e9c:	6a6080e7          	jalr	1702(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea0:	24c1                	addiw	s1,s1,16
    80003ea2:	04c92783          	lw	a5,76(s2)
    80003ea6:	04f4f763          	bgeu	s1,a5,80003ef4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eaa:	4741                	li	a4,16
    80003eac:	86a6                	mv	a3,s1
    80003eae:	fc040613          	addi	a2,s0,-64
    80003eb2:	4581                	li	a1,0
    80003eb4:	854a                	mv	a0,s2
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	d70080e7          	jalr	-656(ra) # 80003c26 <readi>
    80003ebe:	47c1                	li	a5,16
    80003ec0:	fcf518e3          	bne	a0,a5,80003e90 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ec4:	fc045783          	lhu	a5,-64(s0)
    80003ec8:	dfe1                	beqz	a5,80003ea0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003eca:	fc240593          	addi	a1,s0,-62
    80003ece:	854e                	mv	a0,s3
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	f6c080e7          	jalr	-148(ra) # 80003e3c <namecmp>
    80003ed8:	f561                	bnez	a0,80003ea0 <dirlookup+0x4a>
      if(poff)
    80003eda:	000a0463          	beqz	s4,80003ee2 <dirlookup+0x8c>
        *poff = off;
    80003ede:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ee2:	fc045583          	lhu	a1,-64(s0)
    80003ee6:	00092503          	lw	a0,0(s2)
    80003eea:	fffff097          	auipc	ra,0xfffff
    80003eee:	754080e7          	jalr	1876(ra) # 8000363e <iget>
    80003ef2:	a011                	j	80003ef6 <dirlookup+0xa0>
  return 0;
    80003ef4:	4501                	li	a0,0
}
    80003ef6:	70e2                	ld	ra,56(sp)
    80003ef8:	7442                	ld	s0,48(sp)
    80003efa:	74a2                	ld	s1,40(sp)
    80003efc:	7902                	ld	s2,32(sp)
    80003efe:	69e2                	ld	s3,24(sp)
    80003f00:	6a42                	ld	s4,16(sp)
    80003f02:	6121                	addi	sp,sp,64
    80003f04:	8082                	ret

0000000080003f06 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f06:	711d                	addi	sp,sp,-96
    80003f08:	ec86                	sd	ra,88(sp)
    80003f0a:	e8a2                	sd	s0,80(sp)
    80003f0c:	e4a6                	sd	s1,72(sp)
    80003f0e:	e0ca                	sd	s2,64(sp)
    80003f10:	fc4e                	sd	s3,56(sp)
    80003f12:	f852                	sd	s4,48(sp)
    80003f14:	f456                	sd	s5,40(sp)
    80003f16:	f05a                	sd	s6,32(sp)
    80003f18:	ec5e                	sd	s7,24(sp)
    80003f1a:	e862                	sd	s8,16(sp)
    80003f1c:	e466                	sd	s9,8(sp)
    80003f1e:	1080                	addi	s0,sp,96
    80003f20:	84aa                	mv	s1,a0
    80003f22:	8b2e                	mv	s6,a1
    80003f24:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f26:	00054703          	lbu	a4,0(a0)
    80003f2a:	02f00793          	li	a5,47
    80003f2e:	02f70363          	beq	a4,a5,80003f54 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f32:	ffffe097          	auipc	ra,0xffffe
    80003f36:	a7e080e7          	jalr	-1410(ra) # 800019b0 <myproc>
    80003f3a:	17053503          	ld	a0,368(a0)
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	9f6080e7          	jalr	-1546(ra) # 80003934 <idup>
    80003f46:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f48:	02f00913          	li	s2,47
  len = path - s;
    80003f4c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f4e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f50:	4c05                	li	s8,1
    80003f52:	a865                	j	8000400a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f54:	4585                	li	a1,1
    80003f56:	4505                	li	a0,1
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	6e6080e7          	jalr	1766(ra) # 8000363e <iget>
    80003f60:	89aa                	mv	s3,a0
    80003f62:	b7dd                	j	80003f48 <namex+0x42>
      iunlockput(ip);
    80003f64:	854e                	mv	a0,s3
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	c6e080e7          	jalr	-914(ra) # 80003bd4 <iunlockput>
      return 0;
    80003f6e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f70:	854e                	mv	a0,s3
    80003f72:	60e6                	ld	ra,88(sp)
    80003f74:	6446                	ld	s0,80(sp)
    80003f76:	64a6                	ld	s1,72(sp)
    80003f78:	6906                	ld	s2,64(sp)
    80003f7a:	79e2                	ld	s3,56(sp)
    80003f7c:	7a42                	ld	s4,48(sp)
    80003f7e:	7aa2                	ld	s5,40(sp)
    80003f80:	7b02                	ld	s6,32(sp)
    80003f82:	6be2                	ld	s7,24(sp)
    80003f84:	6c42                	ld	s8,16(sp)
    80003f86:	6ca2                	ld	s9,8(sp)
    80003f88:	6125                	addi	sp,sp,96
    80003f8a:	8082                	ret
      iunlock(ip);
    80003f8c:	854e                	mv	a0,s3
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	aa6080e7          	jalr	-1370(ra) # 80003a34 <iunlock>
      return ip;
    80003f96:	bfe9                	j	80003f70 <namex+0x6a>
      iunlockput(ip);
    80003f98:	854e                	mv	a0,s3
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	c3a080e7          	jalr	-966(ra) # 80003bd4 <iunlockput>
      return 0;
    80003fa2:	89d2                	mv	s3,s4
    80003fa4:	b7f1                	j	80003f70 <namex+0x6a>
  len = path - s;
    80003fa6:	40b48633          	sub	a2,s1,a1
    80003faa:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fae:	094cd463          	bge	s9,s4,80004036 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fb2:	4639                	li	a2,14
    80003fb4:	8556                	mv	a0,s5
    80003fb6:	ffffd097          	auipc	ra,0xffffd
    80003fba:	d8a080e7          	jalr	-630(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003fbe:	0004c783          	lbu	a5,0(s1)
    80003fc2:	01279763          	bne	a5,s2,80003fd0 <namex+0xca>
    path++;
    80003fc6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fc8:	0004c783          	lbu	a5,0(s1)
    80003fcc:	ff278de3          	beq	a5,s2,80003fc6 <namex+0xc0>
    ilock(ip);
    80003fd0:	854e                	mv	a0,s3
    80003fd2:	00000097          	auipc	ra,0x0
    80003fd6:	9a0080e7          	jalr	-1632(ra) # 80003972 <ilock>
    if(ip->type != T_DIR){
    80003fda:	04499783          	lh	a5,68(s3)
    80003fde:	f98793e3          	bne	a5,s8,80003f64 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fe2:	000b0563          	beqz	s6,80003fec <namex+0xe6>
    80003fe6:	0004c783          	lbu	a5,0(s1)
    80003fea:	d3cd                	beqz	a5,80003f8c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fec:	865e                	mv	a2,s7
    80003fee:	85d6                	mv	a1,s5
    80003ff0:	854e                	mv	a0,s3
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	e64080e7          	jalr	-412(ra) # 80003e56 <dirlookup>
    80003ffa:	8a2a                	mv	s4,a0
    80003ffc:	dd51                	beqz	a0,80003f98 <namex+0x92>
    iunlockput(ip);
    80003ffe:	854e                	mv	a0,s3
    80004000:	00000097          	auipc	ra,0x0
    80004004:	bd4080e7          	jalr	-1068(ra) # 80003bd4 <iunlockput>
    ip = next;
    80004008:	89d2                	mv	s3,s4
  while(*path == '/')
    8000400a:	0004c783          	lbu	a5,0(s1)
    8000400e:	05279763          	bne	a5,s2,8000405c <namex+0x156>
    path++;
    80004012:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004014:	0004c783          	lbu	a5,0(s1)
    80004018:	ff278de3          	beq	a5,s2,80004012 <namex+0x10c>
  if(*path == 0)
    8000401c:	c79d                	beqz	a5,8000404a <namex+0x144>
    path++;
    8000401e:	85a6                	mv	a1,s1
  len = path - s;
    80004020:	8a5e                	mv	s4,s7
    80004022:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004024:	01278963          	beq	a5,s2,80004036 <namex+0x130>
    80004028:	dfbd                	beqz	a5,80003fa6 <namex+0xa0>
    path++;
    8000402a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000402c:	0004c783          	lbu	a5,0(s1)
    80004030:	ff279ce3          	bne	a5,s2,80004028 <namex+0x122>
    80004034:	bf8d                	j	80003fa6 <namex+0xa0>
    memmove(name, s, len);
    80004036:	2601                	sext.w	a2,a2
    80004038:	8556                	mv	a0,s5
    8000403a:	ffffd097          	auipc	ra,0xffffd
    8000403e:	d06080e7          	jalr	-762(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004042:	9a56                	add	s4,s4,s5
    80004044:	000a0023          	sb	zero,0(s4)
    80004048:	bf9d                	j	80003fbe <namex+0xb8>
  if(nameiparent){
    8000404a:	f20b03e3          	beqz	s6,80003f70 <namex+0x6a>
    iput(ip);
    8000404e:	854e                	mv	a0,s3
    80004050:	00000097          	auipc	ra,0x0
    80004054:	adc080e7          	jalr	-1316(ra) # 80003b2c <iput>
    return 0;
    80004058:	4981                	li	s3,0
    8000405a:	bf19                	j	80003f70 <namex+0x6a>
  if(*path == 0)
    8000405c:	d7fd                	beqz	a5,8000404a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000405e:	0004c783          	lbu	a5,0(s1)
    80004062:	85a6                	mv	a1,s1
    80004064:	b7d1                	j	80004028 <namex+0x122>

0000000080004066 <dirlink>:
{
    80004066:	7139                	addi	sp,sp,-64
    80004068:	fc06                	sd	ra,56(sp)
    8000406a:	f822                	sd	s0,48(sp)
    8000406c:	f426                	sd	s1,40(sp)
    8000406e:	f04a                	sd	s2,32(sp)
    80004070:	ec4e                	sd	s3,24(sp)
    80004072:	e852                	sd	s4,16(sp)
    80004074:	0080                	addi	s0,sp,64
    80004076:	892a                	mv	s2,a0
    80004078:	8a2e                	mv	s4,a1
    8000407a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000407c:	4601                	li	a2,0
    8000407e:	00000097          	auipc	ra,0x0
    80004082:	dd8080e7          	jalr	-552(ra) # 80003e56 <dirlookup>
    80004086:	e93d                	bnez	a0,800040fc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004088:	04c92483          	lw	s1,76(s2)
    8000408c:	c49d                	beqz	s1,800040ba <dirlink+0x54>
    8000408e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004090:	4741                	li	a4,16
    80004092:	86a6                	mv	a3,s1
    80004094:	fc040613          	addi	a2,s0,-64
    80004098:	4581                	li	a1,0
    8000409a:	854a                	mv	a0,s2
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	b8a080e7          	jalr	-1142(ra) # 80003c26 <readi>
    800040a4:	47c1                	li	a5,16
    800040a6:	06f51163          	bne	a0,a5,80004108 <dirlink+0xa2>
    if(de.inum == 0)
    800040aa:	fc045783          	lhu	a5,-64(s0)
    800040ae:	c791                	beqz	a5,800040ba <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040b0:	24c1                	addiw	s1,s1,16
    800040b2:	04c92783          	lw	a5,76(s2)
    800040b6:	fcf4ede3          	bltu	s1,a5,80004090 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040ba:	4639                	li	a2,14
    800040bc:	85d2                	mv	a1,s4
    800040be:	fc240513          	addi	a0,s0,-62
    800040c2:	ffffd097          	auipc	ra,0xffffd
    800040c6:	d32080e7          	jalr	-718(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800040ca:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ce:	4741                	li	a4,16
    800040d0:	86a6                	mv	a3,s1
    800040d2:	fc040613          	addi	a2,s0,-64
    800040d6:	4581                	li	a1,0
    800040d8:	854a                	mv	a0,s2
    800040da:	00000097          	auipc	ra,0x0
    800040de:	c44080e7          	jalr	-956(ra) # 80003d1e <writei>
    800040e2:	872a                	mv	a4,a0
    800040e4:	47c1                	li	a5,16
  return 0;
    800040e6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e8:	02f71863          	bne	a4,a5,80004118 <dirlink+0xb2>
}
    800040ec:	70e2                	ld	ra,56(sp)
    800040ee:	7442                	ld	s0,48(sp)
    800040f0:	74a2                	ld	s1,40(sp)
    800040f2:	7902                	ld	s2,32(sp)
    800040f4:	69e2                	ld	s3,24(sp)
    800040f6:	6a42                	ld	s4,16(sp)
    800040f8:	6121                	addi	sp,sp,64
    800040fa:	8082                	ret
    iput(ip);
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	a30080e7          	jalr	-1488(ra) # 80003b2c <iput>
    return -1;
    80004104:	557d                	li	a0,-1
    80004106:	b7dd                	j	800040ec <dirlink+0x86>
      panic("dirlink read");
    80004108:	00004517          	auipc	a0,0x4
    8000410c:	5c850513          	addi	a0,a0,1480 # 800086d0 <syscalls+0x1e0>
    80004110:	ffffc097          	auipc	ra,0xffffc
    80004114:	42e080e7          	jalr	1070(ra) # 8000053e <panic>
    panic("dirlink");
    80004118:	00004517          	auipc	a0,0x4
    8000411c:	6c850513          	addi	a0,a0,1736 # 800087e0 <syscalls+0x2f0>
    80004120:	ffffc097          	auipc	ra,0xffffc
    80004124:	41e080e7          	jalr	1054(ra) # 8000053e <panic>

0000000080004128 <namei>:

struct inode*
namei(char *path)
{
    80004128:	1101                	addi	sp,sp,-32
    8000412a:	ec06                	sd	ra,24(sp)
    8000412c:	e822                	sd	s0,16(sp)
    8000412e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004130:	fe040613          	addi	a2,s0,-32
    80004134:	4581                	li	a1,0
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	dd0080e7          	jalr	-560(ra) # 80003f06 <namex>
}
    8000413e:	60e2                	ld	ra,24(sp)
    80004140:	6442                	ld	s0,16(sp)
    80004142:	6105                	addi	sp,sp,32
    80004144:	8082                	ret

0000000080004146 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004146:	1141                	addi	sp,sp,-16
    80004148:	e406                	sd	ra,8(sp)
    8000414a:	e022                	sd	s0,0(sp)
    8000414c:	0800                	addi	s0,sp,16
    8000414e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004150:	4585                	li	a1,1
    80004152:	00000097          	auipc	ra,0x0
    80004156:	db4080e7          	jalr	-588(ra) # 80003f06 <namex>
}
    8000415a:	60a2                	ld	ra,8(sp)
    8000415c:	6402                	ld	s0,0(sp)
    8000415e:	0141                	addi	sp,sp,16
    80004160:	8082                	ret

0000000080004162 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004162:	1101                	addi	sp,sp,-32
    80004164:	ec06                	sd	ra,24(sp)
    80004166:	e822                	sd	s0,16(sp)
    80004168:	e426                	sd	s1,8(sp)
    8000416a:	e04a                	sd	s2,0(sp)
    8000416c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000416e:	0001e917          	auipc	s2,0x1e
    80004172:	92290913          	addi	s2,s2,-1758 # 80021a90 <log>
    80004176:	01892583          	lw	a1,24(s2)
    8000417a:	02892503          	lw	a0,40(s2)
    8000417e:	fffff097          	auipc	ra,0xfffff
    80004182:	ff2080e7          	jalr	-14(ra) # 80003170 <bread>
    80004186:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004188:	02c92683          	lw	a3,44(s2)
    8000418c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000418e:	02d05763          	blez	a3,800041bc <write_head+0x5a>
    80004192:	0001e797          	auipc	a5,0x1e
    80004196:	92e78793          	addi	a5,a5,-1746 # 80021ac0 <log+0x30>
    8000419a:	05c50713          	addi	a4,a0,92
    8000419e:	36fd                	addiw	a3,a3,-1
    800041a0:	1682                	slli	a3,a3,0x20
    800041a2:	9281                	srli	a3,a3,0x20
    800041a4:	068a                	slli	a3,a3,0x2
    800041a6:	0001e617          	auipc	a2,0x1e
    800041aa:	91e60613          	addi	a2,a2,-1762 # 80021ac4 <log+0x34>
    800041ae:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041b0:	4390                	lw	a2,0(a5)
    800041b2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041b4:	0791                	addi	a5,a5,4
    800041b6:	0711                	addi	a4,a4,4
    800041b8:	fed79ce3          	bne	a5,a3,800041b0 <write_head+0x4e>
  }
  bwrite(buf);
    800041bc:	8526                	mv	a0,s1
    800041be:	fffff097          	auipc	ra,0xfffff
    800041c2:	0a4080e7          	jalr	164(ra) # 80003262 <bwrite>
  brelse(buf);
    800041c6:	8526                	mv	a0,s1
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	0d8080e7          	jalr	216(ra) # 800032a0 <brelse>
}
    800041d0:	60e2                	ld	ra,24(sp)
    800041d2:	6442                	ld	s0,16(sp)
    800041d4:	64a2                	ld	s1,8(sp)
    800041d6:	6902                	ld	s2,0(sp)
    800041d8:	6105                	addi	sp,sp,32
    800041da:	8082                	ret

00000000800041dc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041dc:	0001e797          	auipc	a5,0x1e
    800041e0:	8e07a783          	lw	a5,-1824(a5) # 80021abc <log+0x2c>
    800041e4:	0af05d63          	blez	a5,8000429e <install_trans+0xc2>
{
    800041e8:	7139                	addi	sp,sp,-64
    800041ea:	fc06                	sd	ra,56(sp)
    800041ec:	f822                	sd	s0,48(sp)
    800041ee:	f426                	sd	s1,40(sp)
    800041f0:	f04a                	sd	s2,32(sp)
    800041f2:	ec4e                	sd	s3,24(sp)
    800041f4:	e852                	sd	s4,16(sp)
    800041f6:	e456                	sd	s5,8(sp)
    800041f8:	e05a                	sd	s6,0(sp)
    800041fa:	0080                	addi	s0,sp,64
    800041fc:	8b2a                	mv	s6,a0
    800041fe:	0001ea97          	auipc	s5,0x1e
    80004202:	8c2a8a93          	addi	s5,s5,-1854 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004206:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004208:	0001e997          	auipc	s3,0x1e
    8000420c:	88898993          	addi	s3,s3,-1912 # 80021a90 <log>
    80004210:	a035                	j	8000423c <install_trans+0x60>
      bunpin(dbuf);
    80004212:	8526                	mv	a0,s1
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	166080e7          	jalr	358(ra) # 8000337a <bunpin>
    brelse(lbuf);
    8000421c:	854a                	mv	a0,s2
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	082080e7          	jalr	130(ra) # 800032a0 <brelse>
    brelse(dbuf);
    80004226:	8526                	mv	a0,s1
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	078080e7          	jalr	120(ra) # 800032a0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004230:	2a05                	addiw	s4,s4,1
    80004232:	0a91                	addi	s5,s5,4
    80004234:	02c9a783          	lw	a5,44(s3)
    80004238:	04fa5963          	bge	s4,a5,8000428a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000423c:	0189a583          	lw	a1,24(s3)
    80004240:	014585bb          	addw	a1,a1,s4
    80004244:	2585                	addiw	a1,a1,1
    80004246:	0289a503          	lw	a0,40(s3)
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	f26080e7          	jalr	-218(ra) # 80003170 <bread>
    80004252:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004254:	000aa583          	lw	a1,0(s5)
    80004258:	0289a503          	lw	a0,40(s3)
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	f14080e7          	jalr	-236(ra) # 80003170 <bread>
    80004264:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004266:	40000613          	li	a2,1024
    8000426a:	05890593          	addi	a1,s2,88
    8000426e:	05850513          	addi	a0,a0,88
    80004272:	ffffd097          	auipc	ra,0xffffd
    80004276:	ace080e7          	jalr	-1330(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000427a:	8526                	mv	a0,s1
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	fe6080e7          	jalr	-26(ra) # 80003262 <bwrite>
    if(recovering == 0)
    80004284:	f80b1ce3          	bnez	s6,8000421c <install_trans+0x40>
    80004288:	b769                	j	80004212 <install_trans+0x36>
}
    8000428a:	70e2                	ld	ra,56(sp)
    8000428c:	7442                	ld	s0,48(sp)
    8000428e:	74a2                	ld	s1,40(sp)
    80004290:	7902                	ld	s2,32(sp)
    80004292:	69e2                	ld	s3,24(sp)
    80004294:	6a42                	ld	s4,16(sp)
    80004296:	6aa2                	ld	s5,8(sp)
    80004298:	6b02                	ld	s6,0(sp)
    8000429a:	6121                	addi	sp,sp,64
    8000429c:	8082                	ret
    8000429e:	8082                	ret

00000000800042a0 <initlog>:
{
    800042a0:	7179                	addi	sp,sp,-48
    800042a2:	f406                	sd	ra,40(sp)
    800042a4:	f022                	sd	s0,32(sp)
    800042a6:	ec26                	sd	s1,24(sp)
    800042a8:	e84a                	sd	s2,16(sp)
    800042aa:	e44e                	sd	s3,8(sp)
    800042ac:	1800                	addi	s0,sp,48
    800042ae:	892a                	mv	s2,a0
    800042b0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042b2:	0001d497          	auipc	s1,0x1d
    800042b6:	7de48493          	addi	s1,s1,2014 # 80021a90 <log>
    800042ba:	00004597          	auipc	a1,0x4
    800042be:	42658593          	addi	a1,a1,1062 # 800086e0 <syscalls+0x1f0>
    800042c2:	8526                	mv	a0,s1
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	890080e7          	jalr	-1904(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800042cc:	0149a583          	lw	a1,20(s3)
    800042d0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042d2:	0109a783          	lw	a5,16(s3)
    800042d6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042d8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042dc:	854a                	mv	a0,s2
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	e92080e7          	jalr	-366(ra) # 80003170 <bread>
  log.lh.n = lh->n;
    800042e6:	4d3c                	lw	a5,88(a0)
    800042e8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042ea:	02f05563          	blez	a5,80004314 <initlog+0x74>
    800042ee:	05c50713          	addi	a4,a0,92
    800042f2:	0001d697          	auipc	a3,0x1d
    800042f6:	7ce68693          	addi	a3,a3,1998 # 80021ac0 <log+0x30>
    800042fa:	37fd                	addiw	a5,a5,-1
    800042fc:	1782                	slli	a5,a5,0x20
    800042fe:	9381                	srli	a5,a5,0x20
    80004300:	078a                	slli	a5,a5,0x2
    80004302:	06050613          	addi	a2,a0,96
    80004306:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004308:	4310                	lw	a2,0(a4)
    8000430a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000430c:	0711                	addi	a4,a4,4
    8000430e:	0691                	addi	a3,a3,4
    80004310:	fef71ce3          	bne	a4,a5,80004308 <initlog+0x68>
  brelse(buf);
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	f8c080e7          	jalr	-116(ra) # 800032a0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000431c:	4505                	li	a0,1
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	ebe080e7          	jalr	-322(ra) # 800041dc <install_trans>
  log.lh.n = 0;
    80004326:	0001d797          	auipc	a5,0x1d
    8000432a:	7807ab23          	sw	zero,1942(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	e34080e7          	jalr	-460(ra) # 80004162 <write_head>
}
    80004336:	70a2                	ld	ra,40(sp)
    80004338:	7402                	ld	s0,32(sp)
    8000433a:	64e2                	ld	s1,24(sp)
    8000433c:	6942                	ld	s2,16(sp)
    8000433e:	69a2                	ld	s3,8(sp)
    80004340:	6145                	addi	sp,sp,48
    80004342:	8082                	ret

0000000080004344 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004344:	1101                	addi	sp,sp,-32
    80004346:	ec06                	sd	ra,24(sp)
    80004348:	e822                	sd	s0,16(sp)
    8000434a:	e426                	sd	s1,8(sp)
    8000434c:	e04a                	sd	s2,0(sp)
    8000434e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004350:	0001d517          	auipc	a0,0x1d
    80004354:	74050513          	addi	a0,a0,1856 # 80021a90 <log>
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	88c080e7          	jalr	-1908(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004360:	0001d497          	auipc	s1,0x1d
    80004364:	73048493          	addi	s1,s1,1840 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004368:	4979                	li	s2,30
    8000436a:	a039                	j	80004378 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000436c:	85a6                	mv	a1,s1
    8000436e:	8526                	mv	a0,s1
    80004370:	ffffe097          	auipc	ra,0xffffe
    80004374:	dd8080e7          	jalr	-552(ra) # 80002148 <sleep>
    if(log.committing){
    80004378:	50dc                	lw	a5,36(s1)
    8000437a:	fbed                	bnez	a5,8000436c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000437c:	509c                	lw	a5,32(s1)
    8000437e:	0017871b          	addiw	a4,a5,1
    80004382:	0007069b          	sext.w	a3,a4
    80004386:	0027179b          	slliw	a5,a4,0x2
    8000438a:	9fb9                	addw	a5,a5,a4
    8000438c:	0017979b          	slliw	a5,a5,0x1
    80004390:	54d8                	lw	a4,44(s1)
    80004392:	9fb9                	addw	a5,a5,a4
    80004394:	00f95963          	bge	s2,a5,800043a6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004398:	85a6                	mv	a1,s1
    8000439a:	8526                	mv	a0,s1
    8000439c:	ffffe097          	auipc	ra,0xffffe
    800043a0:	dac080e7          	jalr	-596(ra) # 80002148 <sleep>
    800043a4:	bfd1                	j	80004378 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043a6:	0001d517          	auipc	a0,0x1d
    800043aa:	6ea50513          	addi	a0,a0,1770 # 80021a90 <log>
    800043ae:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043b0:	ffffd097          	auipc	ra,0xffffd
    800043b4:	8e8080e7          	jalr	-1816(ra) # 80000c98 <release>
      break;
    }
  }
}
    800043b8:	60e2                	ld	ra,24(sp)
    800043ba:	6442                	ld	s0,16(sp)
    800043bc:	64a2                	ld	s1,8(sp)
    800043be:	6902                	ld	s2,0(sp)
    800043c0:	6105                	addi	sp,sp,32
    800043c2:	8082                	ret

00000000800043c4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043c4:	7139                	addi	sp,sp,-64
    800043c6:	fc06                	sd	ra,56(sp)
    800043c8:	f822                	sd	s0,48(sp)
    800043ca:	f426                	sd	s1,40(sp)
    800043cc:	f04a                	sd	s2,32(sp)
    800043ce:	ec4e                	sd	s3,24(sp)
    800043d0:	e852                	sd	s4,16(sp)
    800043d2:	e456                	sd	s5,8(sp)
    800043d4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043d6:	0001d497          	auipc	s1,0x1d
    800043da:	6ba48493          	addi	s1,s1,1722 # 80021a90 <log>
    800043de:	8526                	mv	a0,s1
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	804080e7          	jalr	-2044(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800043e8:	509c                	lw	a5,32(s1)
    800043ea:	37fd                	addiw	a5,a5,-1
    800043ec:	0007891b          	sext.w	s2,a5
    800043f0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043f2:	50dc                	lw	a5,36(s1)
    800043f4:	efb9                	bnez	a5,80004452 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043f6:	06091663          	bnez	s2,80004462 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043fa:	0001d497          	auipc	s1,0x1d
    800043fe:	69648493          	addi	s1,s1,1686 # 80021a90 <log>
    80004402:	4785                	li	a5,1
    80004404:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004406:	8526                	mv	a0,s1
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	890080e7          	jalr	-1904(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004410:	54dc                	lw	a5,44(s1)
    80004412:	06f04763          	bgtz	a5,80004480 <end_op+0xbc>
    acquire(&log.lock);
    80004416:	0001d497          	auipc	s1,0x1d
    8000441a:	67a48493          	addi	s1,s1,1658 # 80021a90 <log>
    8000441e:	8526                	mv	a0,s1
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004428:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000442c:	8526                	mv	a0,s1
    8000442e:	ffffe097          	auipc	ra,0xffffe
    80004432:	ed2080e7          	jalr	-302(ra) # 80002300 <wakeup>
    release(&log.lock);
    80004436:	8526                	mv	a0,s1
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	860080e7          	jalr	-1952(ra) # 80000c98 <release>
}
    80004440:	70e2                	ld	ra,56(sp)
    80004442:	7442                	ld	s0,48(sp)
    80004444:	74a2                	ld	s1,40(sp)
    80004446:	7902                	ld	s2,32(sp)
    80004448:	69e2                	ld	s3,24(sp)
    8000444a:	6a42                	ld	s4,16(sp)
    8000444c:	6aa2                	ld	s5,8(sp)
    8000444e:	6121                	addi	sp,sp,64
    80004450:	8082                	ret
    panic("log.committing");
    80004452:	00004517          	auipc	a0,0x4
    80004456:	29650513          	addi	a0,a0,662 # 800086e8 <syscalls+0x1f8>
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	0e4080e7          	jalr	228(ra) # 8000053e <panic>
    wakeup(&log);
    80004462:	0001d497          	auipc	s1,0x1d
    80004466:	62e48493          	addi	s1,s1,1582 # 80021a90 <log>
    8000446a:	8526                	mv	a0,s1
    8000446c:	ffffe097          	auipc	ra,0xffffe
    80004470:	e94080e7          	jalr	-364(ra) # 80002300 <wakeup>
  release(&log.lock);
    80004474:	8526                	mv	a0,s1
    80004476:	ffffd097          	auipc	ra,0xffffd
    8000447a:	822080e7          	jalr	-2014(ra) # 80000c98 <release>
  if(do_commit){
    8000447e:	b7c9                	j	80004440 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004480:	0001da97          	auipc	s5,0x1d
    80004484:	640a8a93          	addi	s5,s5,1600 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004488:	0001da17          	auipc	s4,0x1d
    8000448c:	608a0a13          	addi	s4,s4,1544 # 80021a90 <log>
    80004490:	018a2583          	lw	a1,24(s4)
    80004494:	012585bb          	addw	a1,a1,s2
    80004498:	2585                	addiw	a1,a1,1
    8000449a:	028a2503          	lw	a0,40(s4)
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	cd2080e7          	jalr	-814(ra) # 80003170 <bread>
    800044a6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044a8:	000aa583          	lw	a1,0(s5)
    800044ac:	028a2503          	lw	a0,40(s4)
    800044b0:	fffff097          	auipc	ra,0xfffff
    800044b4:	cc0080e7          	jalr	-832(ra) # 80003170 <bread>
    800044b8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044ba:	40000613          	li	a2,1024
    800044be:	05850593          	addi	a1,a0,88
    800044c2:	05848513          	addi	a0,s1,88
    800044c6:	ffffd097          	auipc	ra,0xffffd
    800044ca:	87a080e7          	jalr	-1926(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800044ce:	8526                	mv	a0,s1
    800044d0:	fffff097          	auipc	ra,0xfffff
    800044d4:	d92080e7          	jalr	-622(ra) # 80003262 <bwrite>
    brelse(from);
    800044d8:	854e                	mv	a0,s3
    800044da:	fffff097          	auipc	ra,0xfffff
    800044de:	dc6080e7          	jalr	-570(ra) # 800032a0 <brelse>
    brelse(to);
    800044e2:	8526                	mv	a0,s1
    800044e4:	fffff097          	auipc	ra,0xfffff
    800044e8:	dbc080e7          	jalr	-580(ra) # 800032a0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ec:	2905                	addiw	s2,s2,1
    800044ee:	0a91                	addi	s5,s5,4
    800044f0:	02ca2783          	lw	a5,44(s4)
    800044f4:	f8f94ee3          	blt	s2,a5,80004490 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044f8:	00000097          	auipc	ra,0x0
    800044fc:	c6a080e7          	jalr	-918(ra) # 80004162 <write_head>
    install_trans(0); // Now install writes to home locations
    80004500:	4501                	li	a0,0
    80004502:	00000097          	auipc	ra,0x0
    80004506:	cda080e7          	jalr	-806(ra) # 800041dc <install_trans>
    log.lh.n = 0;
    8000450a:	0001d797          	auipc	a5,0x1d
    8000450e:	5a07a923          	sw	zero,1458(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004512:	00000097          	auipc	ra,0x0
    80004516:	c50080e7          	jalr	-944(ra) # 80004162 <write_head>
    8000451a:	bdf5                	j	80004416 <end_op+0x52>

000000008000451c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000451c:	1101                	addi	sp,sp,-32
    8000451e:	ec06                	sd	ra,24(sp)
    80004520:	e822                	sd	s0,16(sp)
    80004522:	e426                	sd	s1,8(sp)
    80004524:	e04a                	sd	s2,0(sp)
    80004526:	1000                	addi	s0,sp,32
    80004528:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000452a:	0001d917          	auipc	s2,0x1d
    8000452e:	56690913          	addi	s2,s2,1382 # 80021a90 <log>
    80004532:	854a                	mv	a0,s2
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	6b0080e7          	jalr	1712(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000453c:	02c92603          	lw	a2,44(s2)
    80004540:	47f5                	li	a5,29
    80004542:	06c7c563          	blt	a5,a2,800045ac <log_write+0x90>
    80004546:	0001d797          	auipc	a5,0x1d
    8000454a:	5667a783          	lw	a5,1382(a5) # 80021aac <log+0x1c>
    8000454e:	37fd                	addiw	a5,a5,-1
    80004550:	04f65e63          	bge	a2,a5,800045ac <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004554:	0001d797          	auipc	a5,0x1d
    80004558:	55c7a783          	lw	a5,1372(a5) # 80021ab0 <log+0x20>
    8000455c:	06f05063          	blez	a5,800045bc <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004560:	4781                	li	a5,0
    80004562:	06c05563          	blez	a2,800045cc <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004566:	44cc                	lw	a1,12(s1)
    80004568:	0001d717          	auipc	a4,0x1d
    8000456c:	55870713          	addi	a4,a4,1368 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004570:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004572:	4314                	lw	a3,0(a4)
    80004574:	04b68c63          	beq	a3,a1,800045cc <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004578:	2785                	addiw	a5,a5,1
    8000457a:	0711                	addi	a4,a4,4
    8000457c:	fef61be3          	bne	a2,a5,80004572 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004580:	0621                	addi	a2,a2,8
    80004582:	060a                	slli	a2,a2,0x2
    80004584:	0001d797          	auipc	a5,0x1d
    80004588:	50c78793          	addi	a5,a5,1292 # 80021a90 <log>
    8000458c:	963e                	add	a2,a2,a5
    8000458e:	44dc                	lw	a5,12(s1)
    80004590:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004592:	8526                	mv	a0,s1
    80004594:	fffff097          	auipc	ra,0xfffff
    80004598:	daa080e7          	jalr	-598(ra) # 8000333e <bpin>
    log.lh.n++;
    8000459c:	0001d717          	auipc	a4,0x1d
    800045a0:	4f470713          	addi	a4,a4,1268 # 80021a90 <log>
    800045a4:	575c                	lw	a5,44(a4)
    800045a6:	2785                	addiw	a5,a5,1
    800045a8:	d75c                	sw	a5,44(a4)
    800045aa:	a835                	j	800045e6 <log_write+0xca>
    panic("too big a transaction");
    800045ac:	00004517          	auipc	a0,0x4
    800045b0:	14c50513          	addi	a0,a0,332 # 800086f8 <syscalls+0x208>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	f8a080e7          	jalr	-118(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800045bc:	00004517          	auipc	a0,0x4
    800045c0:	15450513          	addi	a0,a0,340 # 80008710 <syscalls+0x220>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	f7a080e7          	jalr	-134(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045cc:	00878713          	addi	a4,a5,8
    800045d0:	00271693          	slli	a3,a4,0x2
    800045d4:	0001d717          	auipc	a4,0x1d
    800045d8:	4bc70713          	addi	a4,a4,1212 # 80021a90 <log>
    800045dc:	9736                	add	a4,a4,a3
    800045de:	44d4                	lw	a3,12(s1)
    800045e0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045e2:	faf608e3          	beq	a2,a5,80004592 <log_write+0x76>
  }
  release(&log.lock);
    800045e6:	0001d517          	auipc	a0,0x1d
    800045ea:	4aa50513          	addi	a0,a0,1194 # 80021a90 <log>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	6aa080e7          	jalr	1706(ra) # 80000c98 <release>
}
    800045f6:	60e2                	ld	ra,24(sp)
    800045f8:	6442                	ld	s0,16(sp)
    800045fa:	64a2                	ld	s1,8(sp)
    800045fc:	6902                	ld	s2,0(sp)
    800045fe:	6105                	addi	sp,sp,32
    80004600:	8082                	ret

0000000080004602 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004602:	1101                	addi	sp,sp,-32
    80004604:	ec06                	sd	ra,24(sp)
    80004606:	e822                	sd	s0,16(sp)
    80004608:	e426                	sd	s1,8(sp)
    8000460a:	e04a                	sd	s2,0(sp)
    8000460c:	1000                	addi	s0,sp,32
    8000460e:	84aa                	mv	s1,a0
    80004610:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004612:	00004597          	auipc	a1,0x4
    80004616:	11e58593          	addi	a1,a1,286 # 80008730 <syscalls+0x240>
    8000461a:	0521                	addi	a0,a0,8
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	538080e7          	jalr	1336(ra) # 80000b54 <initlock>
  lk->name = name;
    80004624:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004628:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000462c:	0204a423          	sw	zero,40(s1)
}
    80004630:	60e2                	ld	ra,24(sp)
    80004632:	6442                	ld	s0,16(sp)
    80004634:	64a2                	ld	s1,8(sp)
    80004636:	6902                	ld	s2,0(sp)
    80004638:	6105                	addi	sp,sp,32
    8000463a:	8082                	ret

000000008000463c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000463c:	1101                	addi	sp,sp,-32
    8000463e:	ec06                	sd	ra,24(sp)
    80004640:	e822                	sd	s0,16(sp)
    80004642:	e426                	sd	s1,8(sp)
    80004644:	e04a                	sd	s2,0(sp)
    80004646:	1000                	addi	s0,sp,32
    80004648:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000464a:	00850913          	addi	s2,a0,8
    8000464e:	854a                	mv	a0,s2
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	594080e7          	jalr	1428(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004658:	409c                	lw	a5,0(s1)
    8000465a:	cb89                	beqz	a5,8000466c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000465c:	85ca                	mv	a1,s2
    8000465e:	8526                	mv	a0,s1
    80004660:	ffffe097          	auipc	ra,0xffffe
    80004664:	ae8080e7          	jalr	-1304(ra) # 80002148 <sleep>
  while (lk->locked) {
    80004668:	409c                	lw	a5,0(s1)
    8000466a:	fbed                	bnez	a5,8000465c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000466c:	4785                	li	a5,1
    8000466e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004670:	ffffd097          	auipc	ra,0xffffd
    80004674:	340080e7          	jalr	832(ra) # 800019b0 <myproc>
    80004678:	591c                	lw	a5,48(a0)
    8000467a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000467c:	854a                	mv	a0,s2
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	61a080e7          	jalr	1562(ra) # 80000c98 <release>
}
    80004686:	60e2                	ld	ra,24(sp)
    80004688:	6442                	ld	s0,16(sp)
    8000468a:	64a2                	ld	s1,8(sp)
    8000468c:	6902                	ld	s2,0(sp)
    8000468e:	6105                	addi	sp,sp,32
    80004690:	8082                	ret

0000000080004692 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004692:	1101                	addi	sp,sp,-32
    80004694:	ec06                	sd	ra,24(sp)
    80004696:	e822                	sd	s0,16(sp)
    80004698:	e426                	sd	s1,8(sp)
    8000469a:	e04a                	sd	s2,0(sp)
    8000469c:	1000                	addi	s0,sp,32
    8000469e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a0:	00850913          	addi	s2,a0,8
    800046a4:	854a                	mv	a0,s2
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	53e080e7          	jalr	1342(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800046ae:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046b2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046b6:	8526                	mv	a0,s1
    800046b8:	ffffe097          	auipc	ra,0xffffe
    800046bc:	c48080e7          	jalr	-952(ra) # 80002300 <wakeup>
  release(&lk->lk);
    800046c0:	854a                	mv	a0,s2
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	5d6080e7          	jalr	1494(ra) # 80000c98 <release>
}
    800046ca:	60e2                	ld	ra,24(sp)
    800046cc:	6442                	ld	s0,16(sp)
    800046ce:	64a2                	ld	s1,8(sp)
    800046d0:	6902                	ld	s2,0(sp)
    800046d2:	6105                	addi	sp,sp,32
    800046d4:	8082                	ret

00000000800046d6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046d6:	7179                	addi	sp,sp,-48
    800046d8:	f406                	sd	ra,40(sp)
    800046da:	f022                	sd	s0,32(sp)
    800046dc:	ec26                	sd	s1,24(sp)
    800046de:	e84a                	sd	s2,16(sp)
    800046e0:	e44e                	sd	s3,8(sp)
    800046e2:	1800                	addi	s0,sp,48
    800046e4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046e6:	00850913          	addi	s2,a0,8
    800046ea:	854a                	mv	a0,s2
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	4f8080e7          	jalr	1272(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046f4:	409c                	lw	a5,0(s1)
    800046f6:	ef99                	bnez	a5,80004714 <holdingsleep+0x3e>
    800046f8:	4481                	li	s1,0
  release(&lk->lk);
    800046fa:	854a                	mv	a0,s2
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	59c080e7          	jalr	1436(ra) # 80000c98 <release>
  return r;
}
    80004704:	8526                	mv	a0,s1
    80004706:	70a2                	ld	ra,40(sp)
    80004708:	7402                	ld	s0,32(sp)
    8000470a:	64e2                	ld	s1,24(sp)
    8000470c:	6942                	ld	s2,16(sp)
    8000470e:	69a2                	ld	s3,8(sp)
    80004710:	6145                	addi	sp,sp,48
    80004712:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004714:	0284a983          	lw	s3,40(s1)
    80004718:	ffffd097          	auipc	ra,0xffffd
    8000471c:	298080e7          	jalr	664(ra) # 800019b0 <myproc>
    80004720:	5904                	lw	s1,48(a0)
    80004722:	413484b3          	sub	s1,s1,s3
    80004726:	0014b493          	seqz	s1,s1
    8000472a:	bfc1                	j	800046fa <holdingsleep+0x24>

000000008000472c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000472c:	1141                	addi	sp,sp,-16
    8000472e:	e406                	sd	ra,8(sp)
    80004730:	e022                	sd	s0,0(sp)
    80004732:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004734:	00004597          	auipc	a1,0x4
    80004738:	00c58593          	addi	a1,a1,12 # 80008740 <syscalls+0x250>
    8000473c:	0001d517          	auipc	a0,0x1d
    80004740:	49c50513          	addi	a0,a0,1180 # 80021bd8 <ftable>
    80004744:	ffffc097          	auipc	ra,0xffffc
    80004748:	410080e7          	jalr	1040(ra) # 80000b54 <initlock>
}
    8000474c:	60a2                	ld	ra,8(sp)
    8000474e:	6402                	ld	s0,0(sp)
    80004750:	0141                	addi	sp,sp,16
    80004752:	8082                	ret

0000000080004754 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004754:	1101                	addi	sp,sp,-32
    80004756:	ec06                	sd	ra,24(sp)
    80004758:	e822                	sd	s0,16(sp)
    8000475a:	e426                	sd	s1,8(sp)
    8000475c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000475e:	0001d517          	auipc	a0,0x1d
    80004762:	47a50513          	addi	a0,a0,1146 # 80021bd8 <ftable>
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	47e080e7          	jalr	1150(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000476e:	0001d497          	auipc	s1,0x1d
    80004772:	48248493          	addi	s1,s1,1154 # 80021bf0 <ftable+0x18>
    80004776:	0001e717          	auipc	a4,0x1e
    8000477a:	41a70713          	addi	a4,a4,1050 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    8000477e:	40dc                	lw	a5,4(s1)
    80004780:	cf99                	beqz	a5,8000479e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004782:	02848493          	addi	s1,s1,40
    80004786:	fee49ce3          	bne	s1,a4,8000477e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000478a:	0001d517          	auipc	a0,0x1d
    8000478e:	44e50513          	addi	a0,a0,1102 # 80021bd8 <ftable>
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	506080e7          	jalr	1286(ra) # 80000c98 <release>
  return 0;
    8000479a:	4481                	li	s1,0
    8000479c:	a819                	j	800047b2 <filealloc+0x5e>
      f->ref = 1;
    8000479e:	4785                	li	a5,1
    800047a0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047a2:	0001d517          	auipc	a0,0x1d
    800047a6:	43650513          	addi	a0,a0,1078 # 80021bd8 <ftable>
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	4ee080e7          	jalr	1262(ra) # 80000c98 <release>
}
    800047b2:	8526                	mv	a0,s1
    800047b4:	60e2                	ld	ra,24(sp)
    800047b6:	6442                	ld	s0,16(sp)
    800047b8:	64a2                	ld	s1,8(sp)
    800047ba:	6105                	addi	sp,sp,32
    800047bc:	8082                	ret

00000000800047be <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047be:	1101                	addi	sp,sp,-32
    800047c0:	ec06                	sd	ra,24(sp)
    800047c2:	e822                	sd	s0,16(sp)
    800047c4:	e426                	sd	s1,8(sp)
    800047c6:	1000                	addi	s0,sp,32
    800047c8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047ca:	0001d517          	auipc	a0,0x1d
    800047ce:	40e50513          	addi	a0,a0,1038 # 80021bd8 <ftable>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	412080e7          	jalr	1042(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047da:	40dc                	lw	a5,4(s1)
    800047dc:	02f05263          	blez	a5,80004800 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047e0:	2785                	addiw	a5,a5,1
    800047e2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047e4:	0001d517          	auipc	a0,0x1d
    800047e8:	3f450513          	addi	a0,a0,1012 # 80021bd8 <ftable>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	4ac080e7          	jalr	1196(ra) # 80000c98 <release>
  return f;
}
    800047f4:	8526                	mv	a0,s1
    800047f6:	60e2                	ld	ra,24(sp)
    800047f8:	6442                	ld	s0,16(sp)
    800047fa:	64a2                	ld	s1,8(sp)
    800047fc:	6105                	addi	sp,sp,32
    800047fe:	8082                	ret
    panic("filedup");
    80004800:	00004517          	auipc	a0,0x4
    80004804:	f4850513          	addi	a0,a0,-184 # 80008748 <syscalls+0x258>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	d36080e7          	jalr	-714(ra) # 8000053e <panic>

0000000080004810 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004810:	7139                	addi	sp,sp,-64
    80004812:	fc06                	sd	ra,56(sp)
    80004814:	f822                	sd	s0,48(sp)
    80004816:	f426                	sd	s1,40(sp)
    80004818:	f04a                	sd	s2,32(sp)
    8000481a:	ec4e                	sd	s3,24(sp)
    8000481c:	e852                	sd	s4,16(sp)
    8000481e:	e456                	sd	s5,8(sp)
    80004820:	0080                	addi	s0,sp,64
    80004822:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004824:	0001d517          	auipc	a0,0x1d
    80004828:	3b450513          	addi	a0,a0,948 # 80021bd8 <ftable>
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	3b8080e7          	jalr	952(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004834:	40dc                	lw	a5,4(s1)
    80004836:	06f05163          	blez	a5,80004898 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000483a:	37fd                	addiw	a5,a5,-1
    8000483c:	0007871b          	sext.w	a4,a5
    80004840:	c0dc                	sw	a5,4(s1)
    80004842:	06e04363          	bgtz	a4,800048a8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004846:	0004a903          	lw	s2,0(s1)
    8000484a:	0094ca83          	lbu	s5,9(s1)
    8000484e:	0104ba03          	ld	s4,16(s1)
    80004852:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004856:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000485a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000485e:	0001d517          	auipc	a0,0x1d
    80004862:	37a50513          	addi	a0,a0,890 # 80021bd8 <ftable>
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	432080e7          	jalr	1074(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000486e:	4785                	li	a5,1
    80004870:	04f90d63          	beq	s2,a5,800048ca <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004874:	3979                	addiw	s2,s2,-2
    80004876:	4785                	li	a5,1
    80004878:	0527e063          	bltu	a5,s2,800048b8 <fileclose+0xa8>
    begin_op();
    8000487c:	00000097          	auipc	ra,0x0
    80004880:	ac8080e7          	jalr	-1336(ra) # 80004344 <begin_op>
    iput(ff.ip);
    80004884:	854e                	mv	a0,s3
    80004886:	fffff097          	auipc	ra,0xfffff
    8000488a:	2a6080e7          	jalr	678(ra) # 80003b2c <iput>
    end_op();
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	b36080e7          	jalr	-1226(ra) # 800043c4 <end_op>
    80004896:	a00d                	j	800048b8 <fileclose+0xa8>
    panic("fileclose");
    80004898:	00004517          	auipc	a0,0x4
    8000489c:	eb850513          	addi	a0,a0,-328 # 80008750 <syscalls+0x260>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	c9e080e7          	jalr	-866(ra) # 8000053e <panic>
    release(&ftable.lock);
    800048a8:	0001d517          	auipc	a0,0x1d
    800048ac:	33050513          	addi	a0,a0,816 # 80021bd8 <ftable>
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	3e8080e7          	jalr	1000(ra) # 80000c98 <release>
  }
}
    800048b8:	70e2                	ld	ra,56(sp)
    800048ba:	7442                	ld	s0,48(sp)
    800048bc:	74a2                	ld	s1,40(sp)
    800048be:	7902                	ld	s2,32(sp)
    800048c0:	69e2                	ld	s3,24(sp)
    800048c2:	6a42                	ld	s4,16(sp)
    800048c4:	6aa2                	ld	s5,8(sp)
    800048c6:	6121                	addi	sp,sp,64
    800048c8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048ca:	85d6                	mv	a1,s5
    800048cc:	8552                	mv	a0,s4
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	34c080e7          	jalr	844(ra) # 80004c1a <pipeclose>
    800048d6:	b7cd                	j	800048b8 <fileclose+0xa8>

00000000800048d8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048d8:	715d                	addi	sp,sp,-80
    800048da:	e486                	sd	ra,72(sp)
    800048dc:	e0a2                	sd	s0,64(sp)
    800048de:	fc26                	sd	s1,56(sp)
    800048e0:	f84a                	sd	s2,48(sp)
    800048e2:	f44e                	sd	s3,40(sp)
    800048e4:	0880                	addi	s0,sp,80
    800048e6:	84aa                	mv	s1,a0
    800048e8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048ea:	ffffd097          	auipc	ra,0xffffd
    800048ee:	0c6080e7          	jalr	198(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048f2:	409c                	lw	a5,0(s1)
    800048f4:	37f9                	addiw	a5,a5,-2
    800048f6:	4705                	li	a4,1
    800048f8:	04f76763          	bltu	a4,a5,80004946 <filestat+0x6e>
    800048fc:	892a                	mv	s2,a0
    ilock(f->ip);
    800048fe:	6c88                	ld	a0,24(s1)
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	072080e7          	jalr	114(ra) # 80003972 <ilock>
    stati(f->ip, &st);
    80004908:	fb840593          	addi	a1,s0,-72
    8000490c:	6c88                	ld	a0,24(s1)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	2ee080e7          	jalr	750(ra) # 80003bfc <stati>
    iunlock(f->ip);
    80004916:	6c88                	ld	a0,24(s1)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	11c080e7          	jalr	284(ra) # 80003a34 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004920:	46e1                	li	a3,24
    80004922:	fb840613          	addi	a2,s0,-72
    80004926:	85ce                	mv	a1,s3
    80004928:	07093503          	ld	a0,112(s2)
    8000492c:	ffffd097          	auipc	ra,0xffffd
    80004930:	d46080e7          	jalr	-698(ra) # 80001672 <copyout>
    80004934:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004938:	60a6                	ld	ra,72(sp)
    8000493a:	6406                	ld	s0,64(sp)
    8000493c:	74e2                	ld	s1,56(sp)
    8000493e:	7942                	ld	s2,48(sp)
    80004940:	79a2                	ld	s3,40(sp)
    80004942:	6161                	addi	sp,sp,80
    80004944:	8082                	ret
  return -1;
    80004946:	557d                	li	a0,-1
    80004948:	bfc5                	j	80004938 <filestat+0x60>

000000008000494a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000494a:	7179                	addi	sp,sp,-48
    8000494c:	f406                	sd	ra,40(sp)
    8000494e:	f022                	sd	s0,32(sp)
    80004950:	ec26                	sd	s1,24(sp)
    80004952:	e84a                	sd	s2,16(sp)
    80004954:	e44e                	sd	s3,8(sp)
    80004956:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004958:	00854783          	lbu	a5,8(a0)
    8000495c:	c3d5                	beqz	a5,80004a00 <fileread+0xb6>
    8000495e:	84aa                	mv	s1,a0
    80004960:	89ae                	mv	s3,a1
    80004962:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004964:	411c                	lw	a5,0(a0)
    80004966:	4705                	li	a4,1
    80004968:	04e78963          	beq	a5,a4,800049ba <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000496c:	470d                	li	a4,3
    8000496e:	04e78d63          	beq	a5,a4,800049c8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004972:	4709                	li	a4,2
    80004974:	06e79e63          	bne	a5,a4,800049f0 <fileread+0xa6>
    ilock(f->ip);
    80004978:	6d08                	ld	a0,24(a0)
    8000497a:	fffff097          	auipc	ra,0xfffff
    8000497e:	ff8080e7          	jalr	-8(ra) # 80003972 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004982:	874a                	mv	a4,s2
    80004984:	5094                	lw	a3,32(s1)
    80004986:	864e                	mv	a2,s3
    80004988:	4585                	li	a1,1
    8000498a:	6c88                	ld	a0,24(s1)
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	29a080e7          	jalr	666(ra) # 80003c26 <readi>
    80004994:	892a                	mv	s2,a0
    80004996:	00a05563          	blez	a0,800049a0 <fileread+0x56>
      f->off += r;
    8000499a:	509c                	lw	a5,32(s1)
    8000499c:	9fa9                	addw	a5,a5,a0
    8000499e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049a0:	6c88                	ld	a0,24(s1)
    800049a2:	fffff097          	auipc	ra,0xfffff
    800049a6:	092080e7          	jalr	146(ra) # 80003a34 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049aa:	854a                	mv	a0,s2
    800049ac:	70a2                	ld	ra,40(sp)
    800049ae:	7402                	ld	s0,32(sp)
    800049b0:	64e2                	ld	s1,24(sp)
    800049b2:	6942                	ld	s2,16(sp)
    800049b4:	69a2                	ld	s3,8(sp)
    800049b6:	6145                	addi	sp,sp,48
    800049b8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049ba:	6908                	ld	a0,16(a0)
    800049bc:	00000097          	auipc	ra,0x0
    800049c0:	3c8080e7          	jalr	968(ra) # 80004d84 <piperead>
    800049c4:	892a                	mv	s2,a0
    800049c6:	b7d5                	j	800049aa <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049c8:	02451783          	lh	a5,36(a0)
    800049cc:	03079693          	slli	a3,a5,0x30
    800049d0:	92c1                	srli	a3,a3,0x30
    800049d2:	4725                	li	a4,9
    800049d4:	02d76863          	bltu	a4,a3,80004a04 <fileread+0xba>
    800049d8:	0792                	slli	a5,a5,0x4
    800049da:	0001d717          	auipc	a4,0x1d
    800049de:	15e70713          	addi	a4,a4,350 # 80021b38 <devsw>
    800049e2:	97ba                	add	a5,a5,a4
    800049e4:	639c                	ld	a5,0(a5)
    800049e6:	c38d                	beqz	a5,80004a08 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049e8:	4505                	li	a0,1
    800049ea:	9782                	jalr	a5
    800049ec:	892a                	mv	s2,a0
    800049ee:	bf75                	j	800049aa <fileread+0x60>
    panic("fileread");
    800049f0:	00004517          	auipc	a0,0x4
    800049f4:	d7050513          	addi	a0,a0,-656 # 80008760 <syscalls+0x270>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	b46080e7          	jalr	-1210(ra) # 8000053e <panic>
    return -1;
    80004a00:	597d                	li	s2,-1
    80004a02:	b765                	j	800049aa <fileread+0x60>
      return -1;
    80004a04:	597d                	li	s2,-1
    80004a06:	b755                	j	800049aa <fileread+0x60>
    80004a08:	597d                	li	s2,-1
    80004a0a:	b745                	j	800049aa <fileread+0x60>

0000000080004a0c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a0c:	715d                	addi	sp,sp,-80
    80004a0e:	e486                	sd	ra,72(sp)
    80004a10:	e0a2                	sd	s0,64(sp)
    80004a12:	fc26                	sd	s1,56(sp)
    80004a14:	f84a                	sd	s2,48(sp)
    80004a16:	f44e                	sd	s3,40(sp)
    80004a18:	f052                	sd	s4,32(sp)
    80004a1a:	ec56                	sd	s5,24(sp)
    80004a1c:	e85a                	sd	s6,16(sp)
    80004a1e:	e45e                	sd	s7,8(sp)
    80004a20:	e062                	sd	s8,0(sp)
    80004a22:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a24:	00954783          	lbu	a5,9(a0)
    80004a28:	10078663          	beqz	a5,80004b34 <filewrite+0x128>
    80004a2c:	892a                	mv	s2,a0
    80004a2e:	8aae                	mv	s5,a1
    80004a30:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a32:	411c                	lw	a5,0(a0)
    80004a34:	4705                	li	a4,1
    80004a36:	02e78263          	beq	a5,a4,80004a5a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a3a:	470d                	li	a4,3
    80004a3c:	02e78663          	beq	a5,a4,80004a68 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a40:	4709                	li	a4,2
    80004a42:	0ee79163          	bne	a5,a4,80004b24 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a46:	0ac05d63          	blez	a2,80004b00 <filewrite+0xf4>
    int i = 0;
    80004a4a:	4981                	li	s3,0
    80004a4c:	6b05                	lui	s6,0x1
    80004a4e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a52:	6b85                	lui	s7,0x1
    80004a54:	c00b8b9b          	addiw	s7,s7,-1024
    80004a58:	a861                	j	80004af0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a5a:	6908                	ld	a0,16(a0)
    80004a5c:	00000097          	auipc	ra,0x0
    80004a60:	22e080e7          	jalr	558(ra) # 80004c8a <pipewrite>
    80004a64:	8a2a                	mv	s4,a0
    80004a66:	a045                	j	80004b06 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a68:	02451783          	lh	a5,36(a0)
    80004a6c:	03079693          	slli	a3,a5,0x30
    80004a70:	92c1                	srli	a3,a3,0x30
    80004a72:	4725                	li	a4,9
    80004a74:	0cd76263          	bltu	a4,a3,80004b38 <filewrite+0x12c>
    80004a78:	0792                	slli	a5,a5,0x4
    80004a7a:	0001d717          	auipc	a4,0x1d
    80004a7e:	0be70713          	addi	a4,a4,190 # 80021b38 <devsw>
    80004a82:	97ba                	add	a5,a5,a4
    80004a84:	679c                	ld	a5,8(a5)
    80004a86:	cbdd                	beqz	a5,80004b3c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a88:	4505                	li	a0,1
    80004a8a:	9782                	jalr	a5
    80004a8c:	8a2a                	mv	s4,a0
    80004a8e:	a8a5                	j	80004b06 <filewrite+0xfa>
    80004a90:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a94:	00000097          	auipc	ra,0x0
    80004a98:	8b0080e7          	jalr	-1872(ra) # 80004344 <begin_op>
      ilock(f->ip);
    80004a9c:	01893503          	ld	a0,24(s2)
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	ed2080e7          	jalr	-302(ra) # 80003972 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aa8:	8762                	mv	a4,s8
    80004aaa:	02092683          	lw	a3,32(s2)
    80004aae:	01598633          	add	a2,s3,s5
    80004ab2:	4585                	li	a1,1
    80004ab4:	01893503          	ld	a0,24(s2)
    80004ab8:	fffff097          	auipc	ra,0xfffff
    80004abc:	266080e7          	jalr	614(ra) # 80003d1e <writei>
    80004ac0:	84aa                	mv	s1,a0
    80004ac2:	00a05763          	blez	a0,80004ad0 <filewrite+0xc4>
        f->off += r;
    80004ac6:	02092783          	lw	a5,32(s2)
    80004aca:	9fa9                	addw	a5,a5,a0
    80004acc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ad0:	01893503          	ld	a0,24(s2)
    80004ad4:	fffff097          	auipc	ra,0xfffff
    80004ad8:	f60080e7          	jalr	-160(ra) # 80003a34 <iunlock>
      end_op();
    80004adc:	00000097          	auipc	ra,0x0
    80004ae0:	8e8080e7          	jalr	-1816(ra) # 800043c4 <end_op>

      if(r != n1){
    80004ae4:	009c1f63          	bne	s8,s1,80004b02 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ae8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aec:	0149db63          	bge	s3,s4,80004b02 <filewrite+0xf6>
      int n1 = n - i;
    80004af0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004af4:	84be                	mv	s1,a5
    80004af6:	2781                	sext.w	a5,a5
    80004af8:	f8fb5ce3          	bge	s6,a5,80004a90 <filewrite+0x84>
    80004afc:	84de                	mv	s1,s7
    80004afe:	bf49                	j	80004a90 <filewrite+0x84>
    int i = 0;
    80004b00:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b02:	013a1f63          	bne	s4,s3,80004b20 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b06:	8552                	mv	a0,s4
    80004b08:	60a6                	ld	ra,72(sp)
    80004b0a:	6406                	ld	s0,64(sp)
    80004b0c:	74e2                	ld	s1,56(sp)
    80004b0e:	7942                	ld	s2,48(sp)
    80004b10:	79a2                	ld	s3,40(sp)
    80004b12:	7a02                	ld	s4,32(sp)
    80004b14:	6ae2                	ld	s5,24(sp)
    80004b16:	6b42                	ld	s6,16(sp)
    80004b18:	6ba2                	ld	s7,8(sp)
    80004b1a:	6c02                	ld	s8,0(sp)
    80004b1c:	6161                	addi	sp,sp,80
    80004b1e:	8082                	ret
    ret = (i == n ? n : -1);
    80004b20:	5a7d                	li	s4,-1
    80004b22:	b7d5                	j	80004b06 <filewrite+0xfa>
    panic("filewrite");
    80004b24:	00004517          	auipc	a0,0x4
    80004b28:	c4c50513          	addi	a0,a0,-948 # 80008770 <syscalls+0x280>
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	a12080e7          	jalr	-1518(ra) # 8000053e <panic>
    return -1;
    80004b34:	5a7d                	li	s4,-1
    80004b36:	bfc1                	j	80004b06 <filewrite+0xfa>
      return -1;
    80004b38:	5a7d                	li	s4,-1
    80004b3a:	b7f1                	j	80004b06 <filewrite+0xfa>
    80004b3c:	5a7d                	li	s4,-1
    80004b3e:	b7e1                	j	80004b06 <filewrite+0xfa>

0000000080004b40 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b40:	7179                	addi	sp,sp,-48
    80004b42:	f406                	sd	ra,40(sp)
    80004b44:	f022                	sd	s0,32(sp)
    80004b46:	ec26                	sd	s1,24(sp)
    80004b48:	e84a                	sd	s2,16(sp)
    80004b4a:	e44e                	sd	s3,8(sp)
    80004b4c:	e052                	sd	s4,0(sp)
    80004b4e:	1800                	addi	s0,sp,48
    80004b50:	84aa                	mv	s1,a0
    80004b52:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b54:	0005b023          	sd	zero,0(a1)
    80004b58:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b5c:	00000097          	auipc	ra,0x0
    80004b60:	bf8080e7          	jalr	-1032(ra) # 80004754 <filealloc>
    80004b64:	e088                	sd	a0,0(s1)
    80004b66:	c551                	beqz	a0,80004bf2 <pipealloc+0xb2>
    80004b68:	00000097          	auipc	ra,0x0
    80004b6c:	bec080e7          	jalr	-1044(ra) # 80004754 <filealloc>
    80004b70:	00aa3023          	sd	a0,0(s4)
    80004b74:	c92d                	beqz	a0,80004be6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	f7e080e7          	jalr	-130(ra) # 80000af4 <kalloc>
    80004b7e:	892a                	mv	s2,a0
    80004b80:	c125                	beqz	a0,80004be0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b82:	4985                	li	s3,1
    80004b84:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b88:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b8c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b90:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b94:	00004597          	auipc	a1,0x4
    80004b98:	bec58593          	addi	a1,a1,-1044 # 80008780 <syscalls+0x290>
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	fb8080e7          	jalr	-72(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004ba4:	609c                	ld	a5,0(s1)
    80004ba6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004baa:	609c                	ld	a5,0(s1)
    80004bac:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bb0:	609c                	ld	a5,0(s1)
    80004bb2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bb6:	609c                	ld	a5,0(s1)
    80004bb8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bbc:	000a3783          	ld	a5,0(s4)
    80004bc0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bc4:	000a3783          	ld	a5,0(s4)
    80004bc8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bcc:	000a3783          	ld	a5,0(s4)
    80004bd0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bd4:	000a3783          	ld	a5,0(s4)
    80004bd8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bdc:	4501                	li	a0,0
    80004bde:	a025                	j	80004c06 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004be0:	6088                	ld	a0,0(s1)
    80004be2:	e501                	bnez	a0,80004bea <pipealloc+0xaa>
    80004be4:	a039                	j	80004bf2 <pipealloc+0xb2>
    80004be6:	6088                	ld	a0,0(s1)
    80004be8:	c51d                	beqz	a0,80004c16 <pipealloc+0xd6>
    fileclose(*f0);
    80004bea:	00000097          	auipc	ra,0x0
    80004bee:	c26080e7          	jalr	-986(ra) # 80004810 <fileclose>
  if(*f1)
    80004bf2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bf6:	557d                	li	a0,-1
  if(*f1)
    80004bf8:	c799                	beqz	a5,80004c06 <pipealloc+0xc6>
    fileclose(*f1);
    80004bfa:	853e                	mv	a0,a5
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	c14080e7          	jalr	-1004(ra) # 80004810 <fileclose>
  return -1;
    80004c04:	557d                	li	a0,-1
}
    80004c06:	70a2                	ld	ra,40(sp)
    80004c08:	7402                	ld	s0,32(sp)
    80004c0a:	64e2                	ld	s1,24(sp)
    80004c0c:	6942                	ld	s2,16(sp)
    80004c0e:	69a2                	ld	s3,8(sp)
    80004c10:	6a02                	ld	s4,0(sp)
    80004c12:	6145                	addi	sp,sp,48
    80004c14:	8082                	ret
  return -1;
    80004c16:	557d                	li	a0,-1
    80004c18:	b7fd                	j	80004c06 <pipealloc+0xc6>

0000000080004c1a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c1a:	1101                	addi	sp,sp,-32
    80004c1c:	ec06                	sd	ra,24(sp)
    80004c1e:	e822                	sd	s0,16(sp)
    80004c20:	e426                	sd	s1,8(sp)
    80004c22:	e04a                	sd	s2,0(sp)
    80004c24:	1000                	addi	s0,sp,32
    80004c26:	84aa                	mv	s1,a0
    80004c28:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	fba080e7          	jalr	-70(ra) # 80000be4 <acquire>
  if(writable){
    80004c32:	02090d63          	beqz	s2,80004c6c <pipeclose+0x52>
    pi->writeopen = 0;
    80004c36:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c3a:	21848513          	addi	a0,s1,536
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	6c2080e7          	jalr	1730(ra) # 80002300 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c46:	2204b783          	ld	a5,544(s1)
    80004c4a:	eb95                	bnez	a5,80004c7e <pipeclose+0x64>
    release(&pi->lock);
    80004c4c:	8526                	mv	a0,s1
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	04a080e7          	jalr	74(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c56:	8526                	mv	a0,s1
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	da0080e7          	jalr	-608(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c60:	60e2                	ld	ra,24(sp)
    80004c62:	6442                	ld	s0,16(sp)
    80004c64:	64a2                	ld	s1,8(sp)
    80004c66:	6902                	ld	s2,0(sp)
    80004c68:	6105                	addi	sp,sp,32
    80004c6a:	8082                	ret
    pi->readopen = 0;
    80004c6c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c70:	21c48513          	addi	a0,s1,540
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	68c080e7          	jalr	1676(ra) # 80002300 <wakeup>
    80004c7c:	b7e9                	j	80004c46 <pipeclose+0x2c>
    release(&pi->lock);
    80004c7e:	8526                	mv	a0,s1
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	018080e7          	jalr	24(ra) # 80000c98 <release>
}
    80004c88:	bfe1                	j	80004c60 <pipeclose+0x46>

0000000080004c8a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c8a:	7159                	addi	sp,sp,-112
    80004c8c:	f486                	sd	ra,104(sp)
    80004c8e:	f0a2                	sd	s0,96(sp)
    80004c90:	eca6                	sd	s1,88(sp)
    80004c92:	e8ca                	sd	s2,80(sp)
    80004c94:	e4ce                	sd	s3,72(sp)
    80004c96:	e0d2                	sd	s4,64(sp)
    80004c98:	fc56                	sd	s5,56(sp)
    80004c9a:	f85a                	sd	s6,48(sp)
    80004c9c:	f45e                	sd	s7,40(sp)
    80004c9e:	f062                	sd	s8,32(sp)
    80004ca0:	ec66                	sd	s9,24(sp)
    80004ca2:	1880                	addi	s0,sp,112
    80004ca4:	84aa                	mv	s1,a0
    80004ca6:	8aae                	mv	s5,a1
    80004ca8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	d06080e7          	jalr	-762(ra) # 800019b0 <myproc>
    80004cb2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	f2e080e7          	jalr	-210(ra) # 80000be4 <acquire>
  while(i < n){
    80004cbe:	0d405163          	blez	s4,80004d80 <pipewrite+0xf6>
    80004cc2:	8ba6                	mv	s7,s1
  int i = 0;
    80004cc4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cc6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cc8:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ccc:	21c48c13          	addi	s8,s1,540
    80004cd0:	a08d                	j	80004d32 <pipewrite+0xa8>
      release(&pi->lock);
    80004cd2:	8526                	mv	a0,s1
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	fc4080e7          	jalr	-60(ra) # 80000c98 <release>
      return -1;
    80004cdc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cde:	854a                	mv	a0,s2
    80004ce0:	70a6                	ld	ra,104(sp)
    80004ce2:	7406                	ld	s0,96(sp)
    80004ce4:	64e6                	ld	s1,88(sp)
    80004ce6:	6946                	ld	s2,80(sp)
    80004ce8:	69a6                	ld	s3,72(sp)
    80004cea:	6a06                	ld	s4,64(sp)
    80004cec:	7ae2                	ld	s5,56(sp)
    80004cee:	7b42                	ld	s6,48(sp)
    80004cf0:	7ba2                	ld	s7,40(sp)
    80004cf2:	7c02                	ld	s8,32(sp)
    80004cf4:	6ce2                	ld	s9,24(sp)
    80004cf6:	6165                	addi	sp,sp,112
    80004cf8:	8082                	ret
      wakeup(&pi->nread);
    80004cfa:	8566                	mv	a0,s9
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	604080e7          	jalr	1540(ra) # 80002300 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d04:	85de                	mv	a1,s7
    80004d06:	8562                	mv	a0,s8
    80004d08:	ffffd097          	auipc	ra,0xffffd
    80004d0c:	440080e7          	jalr	1088(ra) # 80002148 <sleep>
    80004d10:	a839                	j	80004d2e <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d12:	21c4a783          	lw	a5,540(s1)
    80004d16:	0017871b          	addiw	a4,a5,1
    80004d1a:	20e4ae23          	sw	a4,540(s1)
    80004d1e:	1ff7f793          	andi	a5,a5,511
    80004d22:	97a6                	add	a5,a5,s1
    80004d24:	f9f44703          	lbu	a4,-97(s0)
    80004d28:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d2c:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d2e:	03495d63          	bge	s2,s4,80004d68 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d32:	2204a783          	lw	a5,544(s1)
    80004d36:	dfd1                	beqz	a5,80004cd2 <pipewrite+0x48>
    80004d38:	0289a783          	lw	a5,40(s3)
    80004d3c:	fbd9                	bnez	a5,80004cd2 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d3e:	2184a783          	lw	a5,536(s1)
    80004d42:	21c4a703          	lw	a4,540(s1)
    80004d46:	2007879b          	addiw	a5,a5,512
    80004d4a:	faf708e3          	beq	a4,a5,80004cfa <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d4e:	4685                	li	a3,1
    80004d50:	01590633          	add	a2,s2,s5
    80004d54:	f9f40593          	addi	a1,s0,-97
    80004d58:	0709b503          	ld	a0,112(s3)
    80004d5c:	ffffd097          	auipc	ra,0xffffd
    80004d60:	9a2080e7          	jalr	-1630(ra) # 800016fe <copyin>
    80004d64:	fb6517e3          	bne	a0,s6,80004d12 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d68:	21848513          	addi	a0,s1,536
    80004d6c:	ffffd097          	auipc	ra,0xffffd
    80004d70:	594080e7          	jalr	1428(ra) # 80002300 <wakeup>
  release(&pi->lock);
    80004d74:	8526                	mv	a0,s1
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	f22080e7          	jalr	-222(ra) # 80000c98 <release>
  return i;
    80004d7e:	b785                	j	80004cde <pipewrite+0x54>
  int i = 0;
    80004d80:	4901                	li	s2,0
    80004d82:	b7dd                	j	80004d68 <pipewrite+0xde>

0000000080004d84 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d84:	715d                	addi	sp,sp,-80
    80004d86:	e486                	sd	ra,72(sp)
    80004d88:	e0a2                	sd	s0,64(sp)
    80004d8a:	fc26                	sd	s1,56(sp)
    80004d8c:	f84a                	sd	s2,48(sp)
    80004d8e:	f44e                	sd	s3,40(sp)
    80004d90:	f052                	sd	s4,32(sp)
    80004d92:	ec56                	sd	s5,24(sp)
    80004d94:	e85a                	sd	s6,16(sp)
    80004d96:	0880                	addi	s0,sp,80
    80004d98:	84aa                	mv	s1,a0
    80004d9a:	892e                	mv	s2,a1
    80004d9c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d9e:	ffffd097          	auipc	ra,0xffffd
    80004da2:	c12080e7          	jalr	-1006(ra) # 800019b0 <myproc>
    80004da6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004da8:	8b26                	mv	s6,s1
    80004daa:	8526                	mv	a0,s1
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	e38080e7          	jalr	-456(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004db4:	2184a703          	lw	a4,536(s1)
    80004db8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dbc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dc0:	02f71463          	bne	a4,a5,80004de8 <piperead+0x64>
    80004dc4:	2244a783          	lw	a5,548(s1)
    80004dc8:	c385                	beqz	a5,80004de8 <piperead+0x64>
    if(pr->killed){
    80004dca:	028a2783          	lw	a5,40(s4)
    80004dce:	ebc1                	bnez	a5,80004e5e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dd0:	85da                	mv	a1,s6
    80004dd2:	854e                	mv	a0,s3
    80004dd4:	ffffd097          	auipc	ra,0xffffd
    80004dd8:	374080e7          	jalr	884(ra) # 80002148 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ddc:	2184a703          	lw	a4,536(s1)
    80004de0:	21c4a783          	lw	a5,540(s1)
    80004de4:	fef700e3          	beq	a4,a5,80004dc4 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004de8:	09505263          	blez	s5,80004e6c <piperead+0xe8>
    80004dec:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dee:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004df0:	2184a783          	lw	a5,536(s1)
    80004df4:	21c4a703          	lw	a4,540(s1)
    80004df8:	02f70d63          	beq	a4,a5,80004e32 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dfc:	0017871b          	addiw	a4,a5,1
    80004e00:	20e4ac23          	sw	a4,536(s1)
    80004e04:	1ff7f793          	andi	a5,a5,511
    80004e08:	97a6                	add	a5,a5,s1
    80004e0a:	0187c783          	lbu	a5,24(a5)
    80004e0e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e12:	4685                	li	a3,1
    80004e14:	fbf40613          	addi	a2,s0,-65
    80004e18:	85ca                	mv	a1,s2
    80004e1a:	070a3503          	ld	a0,112(s4)
    80004e1e:	ffffd097          	auipc	ra,0xffffd
    80004e22:	854080e7          	jalr	-1964(ra) # 80001672 <copyout>
    80004e26:	01650663          	beq	a0,s6,80004e32 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e2a:	2985                	addiw	s3,s3,1
    80004e2c:	0905                	addi	s2,s2,1
    80004e2e:	fd3a91e3          	bne	s5,s3,80004df0 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e32:	21c48513          	addi	a0,s1,540
    80004e36:	ffffd097          	auipc	ra,0xffffd
    80004e3a:	4ca080e7          	jalr	1226(ra) # 80002300 <wakeup>
  release(&pi->lock);
    80004e3e:	8526                	mv	a0,s1
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	e58080e7          	jalr	-424(ra) # 80000c98 <release>
  return i;
}
    80004e48:	854e                	mv	a0,s3
    80004e4a:	60a6                	ld	ra,72(sp)
    80004e4c:	6406                	ld	s0,64(sp)
    80004e4e:	74e2                	ld	s1,56(sp)
    80004e50:	7942                	ld	s2,48(sp)
    80004e52:	79a2                	ld	s3,40(sp)
    80004e54:	7a02                	ld	s4,32(sp)
    80004e56:	6ae2                	ld	s5,24(sp)
    80004e58:	6b42                	ld	s6,16(sp)
    80004e5a:	6161                	addi	sp,sp,80
    80004e5c:	8082                	ret
      release(&pi->lock);
    80004e5e:	8526                	mv	a0,s1
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	e38080e7          	jalr	-456(ra) # 80000c98 <release>
      return -1;
    80004e68:	59fd                	li	s3,-1
    80004e6a:	bff9                	j	80004e48 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e6c:	4981                	li	s3,0
    80004e6e:	b7d1                	j	80004e32 <piperead+0xae>

0000000080004e70 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e70:	df010113          	addi	sp,sp,-528
    80004e74:	20113423          	sd	ra,520(sp)
    80004e78:	20813023          	sd	s0,512(sp)
    80004e7c:	ffa6                	sd	s1,504(sp)
    80004e7e:	fbca                	sd	s2,496(sp)
    80004e80:	f7ce                	sd	s3,488(sp)
    80004e82:	f3d2                	sd	s4,480(sp)
    80004e84:	efd6                	sd	s5,472(sp)
    80004e86:	ebda                	sd	s6,464(sp)
    80004e88:	e7de                	sd	s7,456(sp)
    80004e8a:	e3e2                	sd	s8,448(sp)
    80004e8c:	ff66                	sd	s9,440(sp)
    80004e8e:	fb6a                	sd	s10,432(sp)
    80004e90:	f76e                	sd	s11,424(sp)
    80004e92:	0c00                	addi	s0,sp,528
    80004e94:	84aa                	mv	s1,a0
    80004e96:	dea43c23          	sd	a0,-520(s0)
    80004e9a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	b12080e7          	jalr	-1262(ra) # 800019b0 <myproc>
    80004ea6:	892a                	mv	s2,a0

  begin_op();
    80004ea8:	fffff097          	auipc	ra,0xfffff
    80004eac:	49c080e7          	jalr	1180(ra) # 80004344 <begin_op>

  if((ip = namei(path)) == 0){
    80004eb0:	8526                	mv	a0,s1
    80004eb2:	fffff097          	auipc	ra,0xfffff
    80004eb6:	276080e7          	jalr	630(ra) # 80004128 <namei>
    80004eba:	c92d                	beqz	a0,80004f2c <exec+0xbc>
    80004ebc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ebe:	fffff097          	auipc	ra,0xfffff
    80004ec2:	ab4080e7          	jalr	-1356(ra) # 80003972 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ec6:	04000713          	li	a4,64
    80004eca:	4681                	li	a3,0
    80004ecc:	e5040613          	addi	a2,s0,-432
    80004ed0:	4581                	li	a1,0
    80004ed2:	8526                	mv	a0,s1
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	d52080e7          	jalr	-686(ra) # 80003c26 <readi>
    80004edc:	04000793          	li	a5,64
    80004ee0:	00f51a63          	bne	a0,a5,80004ef4 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ee4:	e5042703          	lw	a4,-432(s0)
    80004ee8:	464c47b7          	lui	a5,0x464c4
    80004eec:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ef0:	04f70463          	beq	a4,a5,80004f38 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ef4:	8526                	mv	a0,s1
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	cde080e7          	jalr	-802(ra) # 80003bd4 <iunlockput>
    end_op();
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	4c6080e7          	jalr	1222(ra) # 800043c4 <end_op>
  }
  return -1;
    80004f06:	557d                	li	a0,-1
}
    80004f08:	20813083          	ld	ra,520(sp)
    80004f0c:	20013403          	ld	s0,512(sp)
    80004f10:	74fe                	ld	s1,504(sp)
    80004f12:	795e                	ld	s2,496(sp)
    80004f14:	79be                	ld	s3,488(sp)
    80004f16:	7a1e                	ld	s4,480(sp)
    80004f18:	6afe                	ld	s5,472(sp)
    80004f1a:	6b5e                	ld	s6,464(sp)
    80004f1c:	6bbe                	ld	s7,456(sp)
    80004f1e:	6c1e                	ld	s8,448(sp)
    80004f20:	7cfa                	ld	s9,440(sp)
    80004f22:	7d5a                	ld	s10,432(sp)
    80004f24:	7dba                	ld	s11,424(sp)
    80004f26:	21010113          	addi	sp,sp,528
    80004f2a:	8082                	ret
    end_op();
    80004f2c:	fffff097          	auipc	ra,0xfffff
    80004f30:	498080e7          	jalr	1176(ra) # 800043c4 <end_op>
    return -1;
    80004f34:	557d                	li	a0,-1
    80004f36:	bfc9                	j	80004f08 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f38:	854a                	mv	a0,s2
    80004f3a:	ffffd097          	auipc	ra,0xffffd
    80004f3e:	b3a080e7          	jalr	-1222(ra) # 80001a74 <proc_pagetable>
    80004f42:	8baa                	mv	s7,a0
    80004f44:	d945                	beqz	a0,80004ef4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f46:	e7042983          	lw	s3,-400(s0)
    80004f4a:	e8845783          	lhu	a5,-376(s0)
    80004f4e:	c7ad                	beqz	a5,80004fb8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f50:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f52:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f54:	6c85                	lui	s9,0x1
    80004f56:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f5a:	def43823          	sd	a5,-528(s0)
    80004f5e:	a42d                	j	80005188 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f60:	00004517          	auipc	a0,0x4
    80004f64:	82850513          	addi	a0,a0,-2008 # 80008788 <syscalls+0x298>
    80004f68:	ffffb097          	auipc	ra,0xffffb
    80004f6c:	5d6080e7          	jalr	1494(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f70:	8756                	mv	a4,s5
    80004f72:	012d86bb          	addw	a3,s11,s2
    80004f76:	4581                	li	a1,0
    80004f78:	8526                	mv	a0,s1
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	cac080e7          	jalr	-852(ra) # 80003c26 <readi>
    80004f82:	2501                	sext.w	a0,a0
    80004f84:	1aaa9963          	bne	s5,a0,80005136 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f88:	6785                	lui	a5,0x1
    80004f8a:	0127893b          	addw	s2,a5,s2
    80004f8e:	77fd                	lui	a5,0xfffff
    80004f90:	01478a3b          	addw	s4,a5,s4
    80004f94:	1f897163          	bgeu	s2,s8,80005176 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f98:	02091593          	slli	a1,s2,0x20
    80004f9c:	9181                	srli	a1,a1,0x20
    80004f9e:	95ea                	add	a1,a1,s10
    80004fa0:	855e                	mv	a0,s7
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	0cc080e7          	jalr	204(ra) # 8000106e <walkaddr>
    80004faa:	862a                	mv	a2,a0
    if(pa == 0)
    80004fac:	d955                	beqz	a0,80004f60 <exec+0xf0>
      n = PGSIZE;
    80004fae:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fb0:	fd9a70e3          	bgeu	s4,s9,80004f70 <exec+0x100>
      n = sz - i;
    80004fb4:	8ad2                	mv	s5,s4
    80004fb6:	bf6d                	j	80004f70 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fb8:	4901                	li	s2,0
  iunlockput(ip);
    80004fba:	8526                	mv	a0,s1
    80004fbc:	fffff097          	auipc	ra,0xfffff
    80004fc0:	c18080e7          	jalr	-1000(ra) # 80003bd4 <iunlockput>
  end_op();
    80004fc4:	fffff097          	auipc	ra,0xfffff
    80004fc8:	400080e7          	jalr	1024(ra) # 800043c4 <end_op>
  p = myproc();
    80004fcc:	ffffd097          	auipc	ra,0xffffd
    80004fd0:	9e4080e7          	jalr	-1564(ra) # 800019b0 <myproc>
    80004fd4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fd6:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80004fda:	6785                	lui	a5,0x1
    80004fdc:	17fd                	addi	a5,a5,-1
    80004fde:	993e                	add	s2,s2,a5
    80004fe0:	757d                	lui	a0,0xfffff
    80004fe2:	00a977b3          	and	a5,s2,a0
    80004fe6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fea:	6609                	lui	a2,0x2
    80004fec:	963e                	add	a2,a2,a5
    80004fee:	85be                	mv	a1,a5
    80004ff0:	855e                	mv	a0,s7
    80004ff2:	ffffc097          	auipc	ra,0xffffc
    80004ff6:	430080e7          	jalr	1072(ra) # 80001422 <uvmalloc>
    80004ffa:	8b2a                	mv	s6,a0
  ip = 0;
    80004ffc:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ffe:	12050c63          	beqz	a0,80005136 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005002:	75f9                	lui	a1,0xffffe
    80005004:	95aa                	add	a1,a1,a0
    80005006:	855e                	mv	a0,s7
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	638080e7          	jalr	1592(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005010:	7c7d                	lui	s8,0xfffff
    80005012:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005014:	e0043783          	ld	a5,-512(s0)
    80005018:	6388                	ld	a0,0(a5)
    8000501a:	c535                	beqz	a0,80005086 <exec+0x216>
    8000501c:	e9040993          	addi	s3,s0,-368
    80005020:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005024:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	e3e080e7          	jalr	-450(ra) # 80000e64 <strlen>
    8000502e:	2505                	addiw	a0,a0,1
    80005030:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005034:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005038:	13896363          	bltu	s2,s8,8000515e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000503c:	e0043d83          	ld	s11,-512(s0)
    80005040:	000dba03          	ld	s4,0(s11)
    80005044:	8552                	mv	a0,s4
    80005046:	ffffc097          	auipc	ra,0xffffc
    8000504a:	e1e080e7          	jalr	-482(ra) # 80000e64 <strlen>
    8000504e:	0015069b          	addiw	a3,a0,1
    80005052:	8652                	mv	a2,s4
    80005054:	85ca                	mv	a1,s2
    80005056:	855e                	mv	a0,s7
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	61a080e7          	jalr	1562(ra) # 80001672 <copyout>
    80005060:	10054363          	bltz	a0,80005166 <exec+0x2f6>
    ustack[argc] = sp;
    80005064:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005068:	0485                	addi	s1,s1,1
    8000506a:	008d8793          	addi	a5,s11,8
    8000506e:	e0f43023          	sd	a5,-512(s0)
    80005072:	008db503          	ld	a0,8(s11)
    80005076:	c911                	beqz	a0,8000508a <exec+0x21a>
    if(argc >= MAXARG)
    80005078:	09a1                	addi	s3,s3,8
    8000507a:	fb3c96e3          	bne	s9,s3,80005026 <exec+0x1b6>
  sz = sz1;
    8000507e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005082:	4481                	li	s1,0
    80005084:	a84d                	j	80005136 <exec+0x2c6>
  sp = sz;
    80005086:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005088:	4481                	li	s1,0
  ustack[argc] = 0;
    8000508a:	00349793          	slli	a5,s1,0x3
    8000508e:	f9040713          	addi	a4,s0,-112
    80005092:	97ba                	add	a5,a5,a4
    80005094:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005098:	00148693          	addi	a3,s1,1
    8000509c:	068e                	slli	a3,a3,0x3
    8000509e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050a2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050a6:	01897663          	bgeu	s2,s8,800050b2 <exec+0x242>
  sz = sz1;
    800050aa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ae:	4481                	li	s1,0
    800050b0:	a059                	j	80005136 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050b2:	e9040613          	addi	a2,s0,-368
    800050b6:	85ca                	mv	a1,s2
    800050b8:	855e                	mv	a0,s7
    800050ba:	ffffc097          	auipc	ra,0xffffc
    800050be:	5b8080e7          	jalr	1464(ra) # 80001672 <copyout>
    800050c2:	0a054663          	bltz	a0,8000516e <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050c6:	078ab783          	ld	a5,120(s5)
    800050ca:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050ce:	df843783          	ld	a5,-520(s0)
    800050d2:	0007c703          	lbu	a4,0(a5)
    800050d6:	cf11                	beqz	a4,800050f2 <exec+0x282>
    800050d8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050da:	02f00693          	li	a3,47
    800050de:	a039                	j	800050ec <exec+0x27c>
      last = s+1;
    800050e0:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050e4:	0785                	addi	a5,a5,1
    800050e6:	fff7c703          	lbu	a4,-1(a5)
    800050ea:	c701                	beqz	a4,800050f2 <exec+0x282>
    if(*s == '/')
    800050ec:	fed71ce3          	bne	a4,a3,800050e4 <exec+0x274>
    800050f0:	bfc5                	j	800050e0 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050f2:	4641                	li	a2,16
    800050f4:	df843583          	ld	a1,-520(s0)
    800050f8:	178a8513          	addi	a0,s5,376
    800050fc:	ffffc097          	auipc	ra,0xffffc
    80005100:	d36080e7          	jalr	-714(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005104:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005108:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    8000510c:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005110:	078ab783          	ld	a5,120(s5)
    80005114:	e6843703          	ld	a4,-408(s0)
    80005118:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000511a:	078ab783          	ld	a5,120(s5)
    8000511e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005122:	85ea                	mv	a1,s10
    80005124:	ffffd097          	auipc	ra,0xffffd
    80005128:	9ec080e7          	jalr	-1556(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000512c:	0004851b          	sext.w	a0,s1
    80005130:	bbe1                	j	80004f08 <exec+0x98>
    80005132:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005136:	e0843583          	ld	a1,-504(s0)
    8000513a:	855e                	mv	a0,s7
    8000513c:	ffffd097          	auipc	ra,0xffffd
    80005140:	9d4080e7          	jalr	-1580(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80005144:	da0498e3          	bnez	s1,80004ef4 <exec+0x84>
  return -1;
    80005148:	557d                	li	a0,-1
    8000514a:	bb7d                	j	80004f08 <exec+0x98>
    8000514c:	e1243423          	sd	s2,-504(s0)
    80005150:	b7dd                	j	80005136 <exec+0x2c6>
    80005152:	e1243423          	sd	s2,-504(s0)
    80005156:	b7c5                	j	80005136 <exec+0x2c6>
    80005158:	e1243423          	sd	s2,-504(s0)
    8000515c:	bfe9                	j	80005136 <exec+0x2c6>
  sz = sz1;
    8000515e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005162:	4481                	li	s1,0
    80005164:	bfc9                	j	80005136 <exec+0x2c6>
  sz = sz1;
    80005166:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000516a:	4481                	li	s1,0
    8000516c:	b7e9                	j	80005136 <exec+0x2c6>
  sz = sz1;
    8000516e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005172:	4481                	li	s1,0
    80005174:	b7c9                	j	80005136 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005176:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000517a:	2b05                	addiw	s6,s6,1
    8000517c:	0389899b          	addiw	s3,s3,56
    80005180:	e8845783          	lhu	a5,-376(s0)
    80005184:	e2fb5be3          	bge	s6,a5,80004fba <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005188:	2981                	sext.w	s3,s3
    8000518a:	03800713          	li	a4,56
    8000518e:	86ce                	mv	a3,s3
    80005190:	e1840613          	addi	a2,s0,-488
    80005194:	4581                	li	a1,0
    80005196:	8526                	mv	a0,s1
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	a8e080e7          	jalr	-1394(ra) # 80003c26 <readi>
    800051a0:	03800793          	li	a5,56
    800051a4:	f8f517e3          	bne	a0,a5,80005132 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051a8:	e1842783          	lw	a5,-488(s0)
    800051ac:	4705                	li	a4,1
    800051ae:	fce796e3          	bne	a5,a4,8000517a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800051b2:	e4043603          	ld	a2,-448(s0)
    800051b6:	e3843783          	ld	a5,-456(s0)
    800051ba:	f8f669e3          	bltu	a2,a5,8000514c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051be:	e2843783          	ld	a5,-472(s0)
    800051c2:	963e                	add	a2,a2,a5
    800051c4:	f8f667e3          	bltu	a2,a5,80005152 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051c8:	85ca                	mv	a1,s2
    800051ca:	855e                	mv	a0,s7
    800051cc:	ffffc097          	auipc	ra,0xffffc
    800051d0:	256080e7          	jalr	598(ra) # 80001422 <uvmalloc>
    800051d4:	e0a43423          	sd	a0,-504(s0)
    800051d8:	d141                	beqz	a0,80005158 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800051da:	e2843d03          	ld	s10,-472(s0)
    800051de:	df043783          	ld	a5,-528(s0)
    800051e2:	00fd77b3          	and	a5,s10,a5
    800051e6:	fba1                	bnez	a5,80005136 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051e8:	e2042d83          	lw	s11,-480(s0)
    800051ec:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051f0:	f80c03e3          	beqz	s8,80005176 <exec+0x306>
    800051f4:	8a62                	mv	s4,s8
    800051f6:	4901                	li	s2,0
    800051f8:	b345                	j	80004f98 <exec+0x128>

00000000800051fa <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051fa:	7179                	addi	sp,sp,-48
    800051fc:	f406                	sd	ra,40(sp)
    800051fe:	f022                	sd	s0,32(sp)
    80005200:	ec26                	sd	s1,24(sp)
    80005202:	e84a                	sd	s2,16(sp)
    80005204:	1800                	addi	s0,sp,48
    80005206:	892e                	mv	s2,a1
    80005208:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000520a:	fdc40593          	addi	a1,s0,-36
    8000520e:	ffffe097          	auipc	ra,0xffffe
    80005212:	b8a080e7          	jalr	-1142(ra) # 80002d98 <argint>
    80005216:	04054063          	bltz	a0,80005256 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000521a:	fdc42703          	lw	a4,-36(s0)
    8000521e:	47bd                	li	a5,15
    80005220:	02e7ed63          	bltu	a5,a4,8000525a <argfd+0x60>
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	78c080e7          	jalr	1932(ra) # 800019b0 <myproc>
    8000522c:	fdc42703          	lw	a4,-36(s0)
    80005230:	01e70793          	addi	a5,a4,30
    80005234:	078e                	slli	a5,a5,0x3
    80005236:	953e                	add	a0,a0,a5
    80005238:	611c                	ld	a5,0(a0)
    8000523a:	c395                	beqz	a5,8000525e <argfd+0x64>
    return -1;
  if(pfd)
    8000523c:	00090463          	beqz	s2,80005244 <argfd+0x4a>
    *pfd = fd;
    80005240:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005244:	4501                	li	a0,0
  if(pf)
    80005246:	c091                	beqz	s1,8000524a <argfd+0x50>
    *pf = f;
    80005248:	e09c                	sd	a5,0(s1)
}
    8000524a:	70a2                	ld	ra,40(sp)
    8000524c:	7402                	ld	s0,32(sp)
    8000524e:	64e2                	ld	s1,24(sp)
    80005250:	6942                	ld	s2,16(sp)
    80005252:	6145                	addi	sp,sp,48
    80005254:	8082                	ret
    return -1;
    80005256:	557d                	li	a0,-1
    80005258:	bfcd                	j	8000524a <argfd+0x50>
    return -1;
    8000525a:	557d                	li	a0,-1
    8000525c:	b7fd                	j	8000524a <argfd+0x50>
    8000525e:	557d                	li	a0,-1
    80005260:	b7ed                	j	8000524a <argfd+0x50>

0000000080005262 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005262:	1101                	addi	sp,sp,-32
    80005264:	ec06                	sd	ra,24(sp)
    80005266:	e822                	sd	s0,16(sp)
    80005268:	e426                	sd	s1,8(sp)
    8000526a:	1000                	addi	s0,sp,32
    8000526c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	742080e7          	jalr	1858(ra) # 800019b0 <myproc>
    80005276:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005278:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    8000527c:	4501                	li	a0,0
    8000527e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005280:	6398                	ld	a4,0(a5)
    80005282:	cb19                	beqz	a4,80005298 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005284:	2505                	addiw	a0,a0,1
    80005286:	07a1                	addi	a5,a5,8
    80005288:	fed51ce3          	bne	a0,a3,80005280 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000528c:	557d                	li	a0,-1
}
    8000528e:	60e2                	ld	ra,24(sp)
    80005290:	6442                	ld	s0,16(sp)
    80005292:	64a2                	ld	s1,8(sp)
    80005294:	6105                	addi	sp,sp,32
    80005296:	8082                	ret
      p->ofile[fd] = f;
    80005298:	01e50793          	addi	a5,a0,30
    8000529c:	078e                	slli	a5,a5,0x3
    8000529e:	963e                	add	a2,a2,a5
    800052a0:	e204                	sd	s1,0(a2)
      return fd;
    800052a2:	b7f5                	j	8000528e <fdalloc+0x2c>

00000000800052a4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052a4:	715d                	addi	sp,sp,-80
    800052a6:	e486                	sd	ra,72(sp)
    800052a8:	e0a2                	sd	s0,64(sp)
    800052aa:	fc26                	sd	s1,56(sp)
    800052ac:	f84a                	sd	s2,48(sp)
    800052ae:	f44e                	sd	s3,40(sp)
    800052b0:	f052                	sd	s4,32(sp)
    800052b2:	ec56                	sd	s5,24(sp)
    800052b4:	0880                	addi	s0,sp,80
    800052b6:	89ae                	mv	s3,a1
    800052b8:	8ab2                	mv	s5,a2
    800052ba:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052bc:	fb040593          	addi	a1,s0,-80
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	e86080e7          	jalr	-378(ra) # 80004146 <nameiparent>
    800052c8:	892a                	mv	s2,a0
    800052ca:	12050f63          	beqz	a0,80005408 <create+0x164>
    return 0;

  ilock(dp);
    800052ce:	ffffe097          	auipc	ra,0xffffe
    800052d2:	6a4080e7          	jalr	1700(ra) # 80003972 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052d6:	4601                	li	a2,0
    800052d8:	fb040593          	addi	a1,s0,-80
    800052dc:	854a                	mv	a0,s2
    800052de:	fffff097          	auipc	ra,0xfffff
    800052e2:	b78080e7          	jalr	-1160(ra) # 80003e56 <dirlookup>
    800052e6:	84aa                	mv	s1,a0
    800052e8:	c921                	beqz	a0,80005338 <create+0x94>
    iunlockput(dp);
    800052ea:	854a                	mv	a0,s2
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	8e8080e7          	jalr	-1816(ra) # 80003bd4 <iunlockput>
    ilock(ip);
    800052f4:	8526                	mv	a0,s1
    800052f6:	ffffe097          	auipc	ra,0xffffe
    800052fa:	67c080e7          	jalr	1660(ra) # 80003972 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052fe:	2981                	sext.w	s3,s3
    80005300:	4789                	li	a5,2
    80005302:	02f99463          	bne	s3,a5,8000532a <create+0x86>
    80005306:	0444d783          	lhu	a5,68(s1)
    8000530a:	37f9                	addiw	a5,a5,-2
    8000530c:	17c2                	slli	a5,a5,0x30
    8000530e:	93c1                	srli	a5,a5,0x30
    80005310:	4705                	li	a4,1
    80005312:	00f76c63          	bltu	a4,a5,8000532a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005316:	8526                	mv	a0,s1
    80005318:	60a6                	ld	ra,72(sp)
    8000531a:	6406                	ld	s0,64(sp)
    8000531c:	74e2                	ld	s1,56(sp)
    8000531e:	7942                	ld	s2,48(sp)
    80005320:	79a2                	ld	s3,40(sp)
    80005322:	7a02                	ld	s4,32(sp)
    80005324:	6ae2                	ld	s5,24(sp)
    80005326:	6161                	addi	sp,sp,80
    80005328:	8082                	ret
    iunlockput(ip);
    8000532a:	8526                	mv	a0,s1
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	8a8080e7          	jalr	-1880(ra) # 80003bd4 <iunlockput>
    return 0;
    80005334:	4481                	li	s1,0
    80005336:	b7c5                	j	80005316 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005338:	85ce                	mv	a1,s3
    8000533a:	00092503          	lw	a0,0(s2)
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	49c080e7          	jalr	1180(ra) # 800037da <ialloc>
    80005346:	84aa                	mv	s1,a0
    80005348:	c529                	beqz	a0,80005392 <create+0xee>
  ilock(ip);
    8000534a:	ffffe097          	auipc	ra,0xffffe
    8000534e:	628080e7          	jalr	1576(ra) # 80003972 <ilock>
  ip->major = major;
    80005352:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005356:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000535a:	4785                	li	a5,1
    8000535c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005360:	8526                	mv	a0,s1
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	546080e7          	jalr	1350(ra) # 800038a8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000536a:	2981                	sext.w	s3,s3
    8000536c:	4785                	li	a5,1
    8000536e:	02f98a63          	beq	s3,a5,800053a2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005372:	40d0                	lw	a2,4(s1)
    80005374:	fb040593          	addi	a1,s0,-80
    80005378:	854a                	mv	a0,s2
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	cec080e7          	jalr	-788(ra) # 80004066 <dirlink>
    80005382:	06054b63          	bltz	a0,800053f8 <create+0x154>
  iunlockput(dp);
    80005386:	854a                	mv	a0,s2
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	84c080e7          	jalr	-1972(ra) # 80003bd4 <iunlockput>
  return ip;
    80005390:	b759                	j	80005316 <create+0x72>
    panic("create: ialloc");
    80005392:	00003517          	auipc	a0,0x3
    80005396:	41650513          	addi	a0,a0,1046 # 800087a8 <syscalls+0x2b8>
    8000539a:	ffffb097          	auipc	ra,0xffffb
    8000539e:	1a4080e7          	jalr	420(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800053a2:	04a95783          	lhu	a5,74(s2)
    800053a6:	2785                	addiw	a5,a5,1
    800053a8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053ac:	854a                	mv	a0,s2
    800053ae:	ffffe097          	auipc	ra,0xffffe
    800053b2:	4fa080e7          	jalr	1274(ra) # 800038a8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053b6:	40d0                	lw	a2,4(s1)
    800053b8:	00003597          	auipc	a1,0x3
    800053bc:	40058593          	addi	a1,a1,1024 # 800087b8 <syscalls+0x2c8>
    800053c0:	8526                	mv	a0,s1
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	ca4080e7          	jalr	-860(ra) # 80004066 <dirlink>
    800053ca:	00054f63          	bltz	a0,800053e8 <create+0x144>
    800053ce:	00492603          	lw	a2,4(s2)
    800053d2:	00003597          	auipc	a1,0x3
    800053d6:	3ee58593          	addi	a1,a1,1006 # 800087c0 <syscalls+0x2d0>
    800053da:	8526                	mv	a0,s1
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	c8a080e7          	jalr	-886(ra) # 80004066 <dirlink>
    800053e4:	f80557e3          	bgez	a0,80005372 <create+0xce>
      panic("create dots");
    800053e8:	00003517          	auipc	a0,0x3
    800053ec:	3e050513          	addi	a0,a0,992 # 800087c8 <syscalls+0x2d8>
    800053f0:	ffffb097          	auipc	ra,0xffffb
    800053f4:	14e080e7          	jalr	334(ra) # 8000053e <panic>
    panic("create: dirlink");
    800053f8:	00003517          	auipc	a0,0x3
    800053fc:	3e050513          	addi	a0,a0,992 # 800087d8 <syscalls+0x2e8>
    80005400:	ffffb097          	auipc	ra,0xffffb
    80005404:	13e080e7          	jalr	318(ra) # 8000053e <panic>
    return 0;
    80005408:	84aa                	mv	s1,a0
    8000540a:	b731                	j	80005316 <create+0x72>

000000008000540c <sys_dup>:
{
    8000540c:	7179                	addi	sp,sp,-48
    8000540e:	f406                	sd	ra,40(sp)
    80005410:	f022                	sd	s0,32(sp)
    80005412:	ec26                	sd	s1,24(sp)
    80005414:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005416:	fd840613          	addi	a2,s0,-40
    8000541a:	4581                	li	a1,0
    8000541c:	4501                	li	a0,0
    8000541e:	00000097          	auipc	ra,0x0
    80005422:	ddc080e7          	jalr	-548(ra) # 800051fa <argfd>
    return -1;
    80005426:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005428:	02054363          	bltz	a0,8000544e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000542c:	fd843503          	ld	a0,-40(s0)
    80005430:	00000097          	auipc	ra,0x0
    80005434:	e32080e7          	jalr	-462(ra) # 80005262 <fdalloc>
    80005438:	84aa                	mv	s1,a0
    return -1;
    8000543a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000543c:	00054963          	bltz	a0,8000544e <sys_dup+0x42>
  filedup(f);
    80005440:	fd843503          	ld	a0,-40(s0)
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	37a080e7          	jalr	890(ra) # 800047be <filedup>
  return fd;
    8000544c:	87a6                	mv	a5,s1
}
    8000544e:	853e                	mv	a0,a5
    80005450:	70a2                	ld	ra,40(sp)
    80005452:	7402                	ld	s0,32(sp)
    80005454:	64e2                	ld	s1,24(sp)
    80005456:	6145                	addi	sp,sp,48
    80005458:	8082                	ret

000000008000545a <sys_read>:
{
    8000545a:	7179                	addi	sp,sp,-48
    8000545c:	f406                	sd	ra,40(sp)
    8000545e:	f022                	sd	s0,32(sp)
    80005460:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005462:	fe840613          	addi	a2,s0,-24
    80005466:	4581                	li	a1,0
    80005468:	4501                	li	a0,0
    8000546a:	00000097          	auipc	ra,0x0
    8000546e:	d90080e7          	jalr	-624(ra) # 800051fa <argfd>
    return -1;
    80005472:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005474:	04054163          	bltz	a0,800054b6 <sys_read+0x5c>
    80005478:	fe440593          	addi	a1,s0,-28
    8000547c:	4509                	li	a0,2
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	91a080e7          	jalr	-1766(ra) # 80002d98 <argint>
    return -1;
    80005486:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005488:	02054763          	bltz	a0,800054b6 <sys_read+0x5c>
    8000548c:	fd840593          	addi	a1,s0,-40
    80005490:	4505                	li	a0,1
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	928080e7          	jalr	-1752(ra) # 80002dba <argaddr>
    return -1;
    8000549a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000549c:	00054d63          	bltz	a0,800054b6 <sys_read+0x5c>
  return fileread(f, p, n);
    800054a0:	fe442603          	lw	a2,-28(s0)
    800054a4:	fd843583          	ld	a1,-40(s0)
    800054a8:	fe843503          	ld	a0,-24(s0)
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	49e080e7          	jalr	1182(ra) # 8000494a <fileread>
    800054b4:	87aa                	mv	a5,a0
}
    800054b6:	853e                	mv	a0,a5
    800054b8:	70a2                	ld	ra,40(sp)
    800054ba:	7402                	ld	s0,32(sp)
    800054bc:	6145                	addi	sp,sp,48
    800054be:	8082                	ret

00000000800054c0 <sys_write>:
{
    800054c0:	7179                	addi	sp,sp,-48
    800054c2:	f406                	sd	ra,40(sp)
    800054c4:	f022                	sd	s0,32(sp)
    800054c6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c8:	fe840613          	addi	a2,s0,-24
    800054cc:	4581                	li	a1,0
    800054ce:	4501                	li	a0,0
    800054d0:	00000097          	auipc	ra,0x0
    800054d4:	d2a080e7          	jalr	-726(ra) # 800051fa <argfd>
    return -1;
    800054d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054da:	04054163          	bltz	a0,8000551c <sys_write+0x5c>
    800054de:	fe440593          	addi	a1,s0,-28
    800054e2:	4509                	li	a0,2
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	8b4080e7          	jalr	-1868(ra) # 80002d98 <argint>
    return -1;
    800054ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ee:	02054763          	bltz	a0,8000551c <sys_write+0x5c>
    800054f2:	fd840593          	addi	a1,s0,-40
    800054f6:	4505                	li	a0,1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	8c2080e7          	jalr	-1854(ra) # 80002dba <argaddr>
    return -1;
    80005500:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005502:	00054d63          	bltz	a0,8000551c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005506:	fe442603          	lw	a2,-28(s0)
    8000550a:	fd843583          	ld	a1,-40(s0)
    8000550e:	fe843503          	ld	a0,-24(s0)
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	4fa080e7          	jalr	1274(ra) # 80004a0c <filewrite>
    8000551a:	87aa                	mv	a5,a0
}
    8000551c:	853e                	mv	a0,a5
    8000551e:	70a2                	ld	ra,40(sp)
    80005520:	7402                	ld	s0,32(sp)
    80005522:	6145                	addi	sp,sp,48
    80005524:	8082                	ret

0000000080005526 <sys_close>:
{
    80005526:	1101                	addi	sp,sp,-32
    80005528:	ec06                	sd	ra,24(sp)
    8000552a:	e822                	sd	s0,16(sp)
    8000552c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000552e:	fe040613          	addi	a2,s0,-32
    80005532:	fec40593          	addi	a1,s0,-20
    80005536:	4501                	li	a0,0
    80005538:	00000097          	auipc	ra,0x0
    8000553c:	cc2080e7          	jalr	-830(ra) # 800051fa <argfd>
    return -1;
    80005540:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005542:	02054463          	bltz	a0,8000556a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005546:	ffffc097          	auipc	ra,0xffffc
    8000554a:	46a080e7          	jalr	1130(ra) # 800019b0 <myproc>
    8000554e:	fec42783          	lw	a5,-20(s0)
    80005552:	07f9                	addi	a5,a5,30
    80005554:	078e                	slli	a5,a5,0x3
    80005556:	97aa                	add	a5,a5,a0
    80005558:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000555c:	fe043503          	ld	a0,-32(s0)
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	2b0080e7          	jalr	688(ra) # 80004810 <fileclose>
  return 0;
    80005568:	4781                	li	a5,0
}
    8000556a:	853e                	mv	a0,a5
    8000556c:	60e2                	ld	ra,24(sp)
    8000556e:	6442                	ld	s0,16(sp)
    80005570:	6105                	addi	sp,sp,32
    80005572:	8082                	ret

0000000080005574 <sys_fstat>:
{
    80005574:	1101                	addi	sp,sp,-32
    80005576:	ec06                	sd	ra,24(sp)
    80005578:	e822                	sd	s0,16(sp)
    8000557a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000557c:	fe840613          	addi	a2,s0,-24
    80005580:	4581                	li	a1,0
    80005582:	4501                	li	a0,0
    80005584:	00000097          	auipc	ra,0x0
    80005588:	c76080e7          	jalr	-906(ra) # 800051fa <argfd>
    return -1;
    8000558c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000558e:	02054563          	bltz	a0,800055b8 <sys_fstat+0x44>
    80005592:	fe040593          	addi	a1,s0,-32
    80005596:	4505                	li	a0,1
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	822080e7          	jalr	-2014(ra) # 80002dba <argaddr>
    return -1;
    800055a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055a2:	00054b63          	bltz	a0,800055b8 <sys_fstat+0x44>
  return filestat(f, st);
    800055a6:	fe043583          	ld	a1,-32(s0)
    800055aa:	fe843503          	ld	a0,-24(s0)
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	32a080e7          	jalr	810(ra) # 800048d8 <filestat>
    800055b6:	87aa                	mv	a5,a0
}
    800055b8:	853e                	mv	a0,a5
    800055ba:	60e2                	ld	ra,24(sp)
    800055bc:	6442                	ld	s0,16(sp)
    800055be:	6105                	addi	sp,sp,32
    800055c0:	8082                	ret

00000000800055c2 <sys_link>:
{
    800055c2:	7169                	addi	sp,sp,-304
    800055c4:	f606                	sd	ra,296(sp)
    800055c6:	f222                	sd	s0,288(sp)
    800055c8:	ee26                	sd	s1,280(sp)
    800055ca:	ea4a                	sd	s2,272(sp)
    800055cc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ce:	08000613          	li	a2,128
    800055d2:	ed040593          	addi	a1,s0,-304
    800055d6:	4501                	li	a0,0
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	804080e7          	jalr	-2044(ra) # 80002ddc <argstr>
    return -1;
    800055e0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055e2:	10054e63          	bltz	a0,800056fe <sys_link+0x13c>
    800055e6:	08000613          	li	a2,128
    800055ea:	f5040593          	addi	a1,s0,-176
    800055ee:	4505                	li	a0,1
    800055f0:	ffffd097          	auipc	ra,0xffffd
    800055f4:	7ec080e7          	jalr	2028(ra) # 80002ddc <argstr>
    return -1;
    800055f8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055fa:	10054263          	bltz	a0,800056fe <sys_link+0x13c>
  begin_op();
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	d46080e7          	jalr	-698(ra) # 80004344 <begin_op>
  if((ip = namei(old)) == 0){
    80005606:	ed040513          	addi	a0,s0,-304
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	b1e080e7          	jalr	-1250(ra) # 80004128 <namei>
    80005612:	84aa                	mv	s1,a0
    80005614:	c551                	beqz	a0,800056a0 <sys_link+0xde>
  ilock(ip);
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	35c080e7          	jalr	860(ra) # 80003972 <ilock>
  if(ip->type == T_DIR){
    8000561e:	04449703          	lh	a4,68(s1)
    80005622:	4785                	li	a5,1
    80005624:	08f70463          	beq	a4,a5,800056ac <sys_link+0xea>
  ip->nlink++;
    80005628:	04a4d783          	lhu	a5,74(s1)
    8000562c:	2785                	addiw	a5,a5,1
    8000562e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005632:	8526                	mv	a0,s1
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	274080e7          	jalr	628(ra) # 800038a8 <iupdate>
  iunlock(ip);
    8000563c:	8526                	mv	a0,s1
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	3f6080e7          	jalr	1014(ra) # 80003a34 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005646:	fd040593          	addi	a1,s0,-48
    8000564a:	f5040513          	addi	a0,s0,-176
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	af8080e7          	jalr	-1288(ra) # 80004146 <nameiparent>
    80005656:	892a                	mv	s2,a0
    80005658:	c935                	beqz	a0,800056cc <sys_link+0x10a>
  ilock(dp);
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	318080e7          	jalr	792(ra) # 80003972 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005662:	00092703          	lw	a4,0(s2)
    80005666:	409c                	lw	a5,0(s1)
    80005668:	04f71d63          	bne	a4,a5,800056c2 <sys_link+0x100>
    8000566c:	40d0                	lw	a2,4(s1)
    8000566e:	fd040593          	addi	a1,s0,-48
    80005672:	854a                	mv	a0,s2
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	9f2080e7          	jalr	-1550(ra) # 80004066 <dirlink>
    8000567c:	04054363          	bltz	a0,800056c2 <sys_link+0x100>
  iunlockput(dp);
    80005680:	854a                	mv	a0,s2
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	552080e7          	jalr	1362(ra) # 80003bd4 <iunlockput>
  iput(ip);
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	4a0080e7          	jalr	1184(ra) # 80003b2c <iput>
  end_op();
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	d30080e7          	jalr	-720(ra) # 800043c4 <end_op>
  return 0;
    8000569c:	4781                	li	a5,0
    8000569e:	a085                	j	800056fe <sys_link+0x13c>
    end_op();
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	d24080e7          	jalr	-732(ra) # 800043c4 <end_op>
    return -1;
    800056a8:	57fd                	li	a5,-1
    800056aa:	a891                	j	800056fe <sys_link+0x13c>
    iunlockput(ip);
    800056ac:	8526                	mv	a0,s1
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	526080e7          	jalr	1318(ra) # 80003bd4 <iunlockput>
    end_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	d0e080e7          	jalr	-754(ra) # 800043c4 <end_op>
    return -1;
    800056be:	57fd                	li	a5,-1
    800056c0:	a83d                	j	800056fe <sys_link+0x13c>
    iunlockput(dp);
    800056c2:	854a                	mv	a0,s2
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	510080e7          	jalr	1296(ra) # 80003bd4 <iunlockput>
  ilock(ip);
    800056cc:	8526                	mv	a0,s1
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	2a4080e7          	jalr	676(ra) # 80003972 <ilock>
  ip->nlink--;
    800056d6:	04a4d783          	lhu	a5,74(s1)
    800056da:	37fd                	addiw	a5,a5,-1
    800056dc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	1c6080e7          	jalr	454(ra) # 800038a8 <iupdate>
  iunlockput(ip);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	4e8080e7          	jalr	1256(ra) # 80003bd4 <iunlockput>
  end_op();
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	cd0080e7          	jalr	-816(ra) # 800043c4 <end_op>
  return -1;
    800056fc:	57fd                	li	a5,-1
}
    800056fe:	853e                	mv	a0,a5
    80005700:	70b2                	ld	ra,296(sp)
    80005702:	7412                	ld	s0,288(sp)
    80005704:	64f2                	ld	s1,280(sp)
    80005706:	6952                	ld	s2,272(sp)
    80005708:	6155                	addi	sp,sp,304
    8000570a:	8082                	ret

000000008000570c <sys_unlink>:
{
    8000570c:	7151                	addi	sp,sp,-240
    8000570e:	f586                	sd	ra,232(sp)
    80005710:	f1a2                	sd	s0,224(sp)
    80005712:	eda6                	sd	s1,216(sp)
    80005714:	e9ca                	sd	s2,208(sp)
    80005716:	e5ce                	sd	s3,200(sp)
    80005718:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000571a:	08000613          	li	a2,128
    8000571e:	f3040593          	addi	a1,s0,-208
    80005722:	4501                	li	a0,0
    80005724:	ffffd097          	auipc	ra,0xffffd
    80005728:	6b8080e7          	jalr	1720(ra) # 80002ddc <argstr>
    8000572c:	18054163          	bltz	a0,800058ae <sys_unlink+0x1a2>
  begin_op();
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	c14080e7          	jalr	-1004(ra) # 80004344 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005738:	fb040593          	addi	a1,s0,-80
    8000573c:	f3040513          	addi	a0,s0,-208
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	a06080e7          	jalr	-1530(ra) # 80004146 <nameiparent>
    80005748:	84aa                	mv	s1,a0
    8000574a:	c979                	beqz	a0,80005820 <sys_unlink+0x114>
  ilock(dp);
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	226080e7          	jalr	550(ra) # 80003972 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005754:	00003597          	auipc	a1,0x3
    80005758:	06458593          	addi	a1,a1,100 # 800087b8 <syscalls+0x2c8>
    8000575c:	fb040513          	addi	a0,s0,-80
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	6dc080e7          	jalr	1756(ra) # 80003e3c <namecmp>
    80005768:	14050a63          	beqz	a0,800058bc <sys_unlink+0x1b0>
    8000576c:	00003597          	auipc	a1,0x3
    80005770:	05458593          	addi	a1,a1,84 # 800087c0 <syscalls+0x2d0>
    80005774:	fb040513          	addi	a0,s0,-80
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	6c4080e7          	jalr	1732(ra) # 80003e3c <namecmp>
    80005780:	12050e63          	beqz	a0,800058bc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005784:	f2c40613          	addi	a2,s0,-212
    80005788:	fb040593          	addi	a1,s0,-80
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	6c8080e7          	jalr	1736(ra) # 80003e56 <dirlookup>
    80005796:	892a                	mv	s2,a0
    80005798:	12050263          	beqz	a0,800058bc <sys_unlink+0x1b0>
  ilock(ip);
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	1d6080e7          	jalr	470(ra) # 80003972 <ilock>
  if(ip->nlink < 1)
    800057a4:	04a91783          	lh	a5,74(s2)
    800057a8:	08f05263          	blez	a5,8000582c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057ac:	04491703          	lh	a4,68(s2)
    800057b0:	4785                	li	a5,1
    800057b2:	08f70563          	beq	a4,a5,8000583c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057b6:	4641                	li	a2,16
    800057b8:	4581                	li	a1,0
    800057ba:	fc040513          	addi	a0,s0,-64
    800057be:	ffffb097          	auipc	ra,0xffffb
    800057c2:	522080e7          	jalr	1314(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057c6:	4741                	li	a4,16
    800057c8:	f2c42683          	lw	a3,-212(s0)
    800057cc:	fc040613          	addi	a2,s0,-64
    800057d0:	4581                	li	a1,0
    800057d2:	8526                	mv	a0,s1
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	54a080e7          	jalr	1354(ra) # 80003d1e <writei>
    800057dc:	47c1                	li	a5,16
    800057de:	0af51563          	bne	a0,a5,80005888 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057e2:	04491703          	lh	a4,68(s2)
    800057e6:	4785                	li	a5,1
    800057e8:	0af70863          	beq	a4,a5,80005898 <sys_unlink+0x18c>
  iunlockput(dp);
    800057ec:	8526                	mv	a0,s1
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	3e6080e7          	jalr	998(ra) # 80003bd4 <iunlockput>
  ip->nlink--;
    800057f6:	04a95783          	lhu	a5,74(s2)
    800057fa:	37fd                	addiw	a5,a5,-1
    800057fc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005800:	854a                	mv	a0,s2
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	0a6080e7          	jalr	166(ra) # 800038a8 <iupdate>
  iunlockput(ip);
    8000580a:	854a                	mv	a0,s2
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	3c8080e7          	jalr	968(ra) # 80003bd4 <iunlockput>
  end_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	bb0080e7          	jalr	-1104(ra) # 800043c4 <end_op>
  return 0;
    8000581c:	4501                	li	a0,0
    8000581e:	a84d                	j	800058d0 <sys_unlink+0x1c4>
    end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	ba4080e7          	jalr	-1116(ra) # 800043c4 <end_op>
    return -1;
    80005828:	557d                	li	a0,-1
    8000582a:	a05d                	j	800058d0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000582c:	00003517          	auipc	a0,0x3
    80005830:	fbc50513          	addi	a0,a0,-68 # 800087e8 <syscalls+0x2f8>
    80005834:	ffffb097          	auipc	ra,0xffffb
    80005838:	d0a080e7          	jalr	-758(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000583c:	04c92703          	lw	a4,76(s2)
    80005840:	02000793          	li	a5,32
    80005844:	f6e7f9e3          	bgeu	a5,a4,800057b6 <sys_unlink+0xaa>
    80005848:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000584c:	4741                	li	a4,16
    8000584e:	86ce                	mv	a3,s3
    80005850:	f1840613          	addi	a2,s0,-232
    80005854:	4581                	li	a1,0
    80005856:	854a                	mv	a0,s2
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	3ce080e7          	jalr	974(ra) # 80003c26 <readi>
    80005860:	47c1                	li	a5,16
    80005862:	00f51b63          	bne	a0,a5,80005878 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005866:	f1845783          	lhu	a5,-232(s0)
    8000586a:	e7a1                	bnez	a5,800058b2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000586c:	29c1                	addiw	s3,s3,16
    8000586e:	04c92783          	lw	a5,76(s2)
    80005872:	fcf9ede3          	bltu	s3,a5,8000584c <sys_unlink+0x140>
    80005876:	b781                	j	800057b6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005878:	00003517          	auipc	a0,0x3
    8000587c:	f8850513          	addi	a0,a0,-120 # 80008800 <syscalls+0x310>
    80005880:	ffffb097          	auipc	ra,0xffffb
    80005884:	cbe080e7          	jalr	-834(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005888:	00003517          	auipc	a0,0x3
    8000588c:	f9050513          	addi	a0,a0,-112 # 80008818 <syscalls+0x328>
    80005890:	ffffb097          	auipc	ra,0xffffb
    80005894:	cae080e7          	jalr	-850(ra) # 8000053e <panic>
    dp->nlink--;
    80005898:	04a4d783          	lhu	a5,74(s1)
    8000589c:	37fd                	addiw	a5,a5,-1
    8000589e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	004080e7          	jalr	4(ra) # 800038a8 <iupdate>
    800058ac:	b781                	j	800057ec <sys_unlink+0xe0>
    return -1;
    800058ae:	557d                	li	a0,-1
    800058b0:	a005                	j	800058d0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058b2:	854a                	mv	a0,s2
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	320080e7          	jalr	800(ra) # 80003bd4 <iunlockput>
  iunlockput(dp);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	316080e7          	jalr	790(ra) # 80003bd4 <iunlockput>
  end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	afe080e7          	jalr	-1282(ra) # 800043c4 <end_op>
  return -1;
    800058ce:	557d                	li	a0,-1
}
    800058d0:	70ae                	ld	ra,232(sp)
    800058d2:	740e                	ld	s0,224(sp)
    800058d4:	64ee                	ld	s1,216(sp)
    800058d6:	694e                	ld	s2,208(sp)
    800058d8:	69ae                	ld	s3,200(sp)
    800058da:	616d                	addi	sp,sp,240
    800058dc:	8082                	ret

00000000800058de <sys_open>:

uint64
sys_open(void)
{
    800058de:	7131                	addi	sp,sp,-192
    800058e0:	fd06                	sd	ra,184(sp)
    800058e2:	f922                	sd	s0,176(sp)
    800058e4:	f526                	sd	s1,168(sp)
    800058e6:	f14a                	sd	s2,160(sp)
    800058e8:	ed4e                	sd	s3,152(sp)
    800058ea:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058ec:	08000613          	li	a2,128
    800058f0:	f5040593          	addi	a1,s0,-176
    800058f4:	4501                	li	a0,0
    800058f6:	ffffd097          	auipc	ra,0xffffd
    800058fa:	4e6080e7          	jalr	1254(ra) # 80002ddc <argstr>
    return -1;
    800058fe:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005900:	0c054163          	bltz	a0,800059c2 <sys_open+0xe4>
    80005904:	f4c40593          	addi	a1,s0,-180
    80005908:	4505                	li	a0,1
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	48e080e7          	jalr	1166(ra) # 80002d98 <argint>
    80005912:	0a054863          	bltz	a0,800059c2 <sys_open+0xe4>

  begin_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	a2e080e7          	jalr	-1490(ra) # 80004344 <begin_op>

  if(omode & O_CREATE){
    8000591e:	f4c42783          	lw	a5,-180(s0)
    80005922:	2007f793          	andi	a5,a5,512
    80005926:	cbdd                	beqz	a5,800059dc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005928:	4681                	li	a3,0
    8000592a:	4601                	li	a2,0
    8000592c:	4589                	li	a1,2
    8000592e:	f5040513          	addi	a0,s0,-176
    80005932:	00000097          	auipc	ra,0x0
    80005936:	972080e7          	jalr	-1678(ra) # 800052a4 <create>
    8000593a:	892a                	mv	s2,a0
    if(ip == 0){
    8000593c:	c959                	beqz	a0,800059d2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000593e:	04491703          	lh	a4,68(s2)
    80005942:	478d                	li	a5,3
    80005944:	00f71763          	bne	a4,a5,80005952 <sys_open+0x74>
    80005948:	04695703          	lhu	a4,70(s2)
    8000594c:	47a5                	li	a5,9
    8000594e:	0ce7ec63          	bltu	a5,a4,80005a26 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	e02080e7          	jalr	-510(ra) # 80004754 <filealloc>
    8000595a:	89aa                	mv	s3,a0
    8000595c:	10050263          	beqz	a0,80005a60 <sys_open+0x182>
    80005960:	00000097          	auipc	ra,0x0
    80005964:	902080e7          	jalr	-1790(ra) # 80005262 <fdalloc>
    80005968:	84aa                	mv	s1,a0
    8000596a:	0e054663          	bltz	a0,80005a56 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000596e:	04491703          	lh	a4,68(s2)
    80005972:	478d                	li	a5,3
    80005974:	0cf70463          	beq	a4,a5,80005a3c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005978:	4789                	li	a5,2
    8000597a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000597e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005982:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005986:	f4c42783          	lw	a5,-180(s0)
    8000598a:	0017c713          	xori	a4,a5,1
    8000598e:	8b05                	andi	a4,a4,1
    80005990:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005994:	0037f713          	andi	a4,a5,3
    80005998:	00e03733          	snez	a4,a4
    8000599c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059a0:	4007f793          	andi	a5,a5,1024
    800059a4:	c791                	beqz	a5,800059b0 <sys_open+0xd2>
    800059a6:	04491703          	lh	a4,68(s2)
    800059aa:	4789                	li	a5,2
    800059ac:	08f70f63          	beq	a4,a5,80005a4a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059b0:	854a                	mv	a0,s2
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	082080e7          	jalr	130(ra) # 80003a34 <iunlock>
  end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	a0a080e7          	jalr	-1526(ra) # 800043c4 <end_op>

  return fd;
}
    800059c2:	8526                	mv	a0,s1
    800059c4:	70ea                	ld	ra,184(sp)
    800059c6:	744a                	ld	s0,176(sp)
    800059c8:	74aa                	ld	s1,168(sp)
    800059ca:	790a                	ld	s2,160(sp)
    800059cc:	69ea                	ld	s3,152(sp)
    800059ce:	6129                	addi	sp,sp,192
    800059d0:	8082                	ret
      end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	9f2080e7          	jalr	-1550(ra) # 800043c4 <end_op>
      return -1;
    800059da:	b7e5                	j	800059c2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059dc:	f5040513          	addi	a0,s0,-176
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	748080e7          	jalr	1864(ra) # 80004128 <namei>
    800059e8:	892a                	mv	s2,a0
    800059ea:	c905                	beqz	a0,80005a1a <sys_open+0x13c>
    ilock(ip);
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	f86080e7          	jalr	-122(ra) # 80003972 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059f4:	04491703          	lh	a4,68(s2)
    800059f8:	4785                	li	a5,1
    800059fa:	f4f712e3          	bne	a4,a5,8000593e <sys_open+0x60>
    800059fe:	f4c42783          	lw	a5,-180(s0)
    80005a02:	dba1                	beqz	a5,80005952 <sys_open+0x74>
      iunlockput(ip);
    80005a04:	854a                	mv	a0,s2
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	1ce080e7          	jalr	462(ra) # 80003bd4 <iunlockput>
      end_op();
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	9b6080e7          	jalr	-1610(ra) # 800043c4 <end_op>
      return -1;
    80005a16:	54fd                	li	s1,-1
    80005a18:	b76d                	j	800059c2 <sys_open+0xe4>
      end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	9aa080e7          	jalr	-1622(ra) # 800043c4 <end_op>
      return -1;
    80005a22:	54fd                	li	s1,-1
    80005a24:	bf79                	j	800059c2 <sys_open+0xe4>
    iunlockput(ip);
    80005a26:	854a                	mv	a0,s2
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	1ac080e7          	jalr	428(ra) # 80003bd4 <iunlockput>
    end_op();
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	994080e7          	jalr	-1644(ra) # 800043c4 <end_op>
    return -1;
    80005a38:	54fd                	li	s1,-1
    80005a3a:	b761                	j	800059c2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a3c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a40:	04691783          	lh	a5,70(s2)
    80005a44:	02f99223          	sh	a5,36(s3)
    80005a48:	bf2d                	j	80005982 <sys_open+0xa4>
    itrunc(ip);
    80005a4a:	854a                	mv	a0,s2
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	034080e7          	jalr	52(ra) # 80003a80 <itrunc>
    80005a54:	bfb1                	j	800059b0 <sys_open+0xd2>
      fileclose(f);
    80005a56:	854e                	mv	a0,s3
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	db8080e7          	jalr	-584(ra) # 80004810 <fileclose>
    iunlockput(ip);
    80005a60:	854a                	mv	a0,s2
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	172080e7          	jalr	370(ra) # 80003bd4 <iunlockput>
    end_op();
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	95a080e7          	jalr	-1702(ra) # 800043c4 <end_op>
    return -1;
    80005a72:	54fd                	li	s1,-1
    80005a74:	b7b9                	j	800059c2 <sys_open+0xe4>

0000000080005a76 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a76:	7175                	addi	sp,sp,-144
    80005a78:	e506                	sd	ra,136(sp)
    80005a7a:	e122                	sd	s0,128(sp)
    80005a7c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	8c6080e7          	jalr	-1850(ra) # 80004344 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a86:	08000613          	li	a2,128
    80005a8a:	f7040593          	addi	a1,s0,-144
    80005a8e:	4501                	li	a0,0
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	34c080e7          	jalr	844(ra) # 80002ddc <argstr>
    80005a98:	02054963          	bltz	a0,80005aca <sys_mkdir+0x54>
    80005a9c:	4681                	li	a3,0
    80005a9e:	4601                	li	a2,0
    80005aa0:	4585                	li	a1,1
    80005aa2:	f7040513          	addi	a0,s0,-144
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	7fe080e7          	jalr	2046(ra) # 800052a4 <create>
    80005aae:	cd11                	beqz	a0,80005aca <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	124080e7          	jalr	292(ra) # 80003bd4 <iunlockput>
  end_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	90c080e7          	jalr	-1780(ra) # 800043c4 <end_op>
  return 0;
    80005ac0:	4501                	li	a0,0
}
    80005ac2:	60aa                	ld	ra,136(sp)
    80005ac4:	640a                	ld	s0,128(sp)
    80005ac6:	6149                	addi	sp,sp,144
    80005ac8:	8082                	ret
    end_op();
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	8fa080e7          	jalr	-1798(ra) # 800043c4 <end_op>
    return -1;
    80005ad2:	557d                	li	a0,-1
    80005ad4:	b7fd                	j	80005ac2 <sys_mkdir+0x4c>

0000000080005ad6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ad6:	7135                	addi	sp,sp,-160
    80005ad8:	ed06                	sd	ra,152(sp)
    80005ada:	e922                	sd	s0,144(sp)
    80005adc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	866080e7          	jalr	-1946(ra) # 80004344 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ae6:	08000613          	li	a2,128
    80005aea:	f7040593          	addi	a1,s0,-144
    80005aee:	4501                	li	a0,0
    80005af0:	ffffd097          	auipc	ra,0xffffd
    80005af4:	2ec080e7          	jalr	748(ra) # 80002ddc <argstr>
    80005af8:	04054a63          	bltz	a0,80005b4c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005afc:	f6c40593          	addi	a1,s0,-148
    80005b00:	4505                	li	a0,1
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	296080e7          	jalr	662(ra) # 80002d98 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b0a:	04054163          	bltz	a0,80005b4c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b0e:	f6840593          	addi	a1,s0,-152
    80005b12:	4509                	li	a0,2
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	284080e7          	jalr	644(ra) # 80002d98 <argint>
     argint(1, &major) < 0 ||
    80005b1c:	02054863          	bltz	a0,80005b4c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b20:	f6841683          	lh	a3,-152(s0)
    80005b24:	f6c41603          	lh	a2,-148(s0)
    80005b28:	458d                	li	a1,3
    80005b2a:	f7040513          	addi	a0,s0,-144
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	776080e7          	jalr	1910(ra) # 800052a4 <create>
     argint(2, &minor) < 0 ||
    80005b36:	c919                	beqz	a0,80005b4c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	09c080e7          	jalr	156(ra) # 80003bd4 <iunlockput>
  end_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	884080e7          	jalr	-1916(ra) # 800043c4 <end_op>
  return 0;
    80005b48:	4501                	li	a0,0
    80005b4a:	a031                	j	80005b56 <sys_mknod+0x80>
    end_op();
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	878080e7          	jalr	-1928(ra) # 800043c4 <end_op>
    return -1;
    80005b54:	557d                	li	a0,-1
}
    80005b56:	60ea                	ld	ra,152(sp)
    80005b58:	644a                	ld	s0,144(sp)
    80005b5a:	610d                	addi	sp,sp,160
    80005b5c:	8082                	ret

0000000080005b5e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b5e:	7135                	addi	sp,sp,-160
    80005b60:	ed06                	sd	ra,152(sp)
    80005b62:	e922                	sd	s0,144(sp)
    80005b64:	e526                	sd	s1,136(sp)
    80005b66:	e14a                	sd	s2,128(sp)
    80005b68:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b6a:	ffffc097          	auipc	ra,0xffffc
    80005b6e:	e46080e7          	jalr	-442(ra) # 800019b0 <myproc>
    80005b72:	892a                	mv	s2,a0
  
  begin_op();
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	7d0080e7          	jalr	2000(ra) # 80004344 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b7c:	08000613          	li	a2,128
    80005b80:	f6040593          	addi	a1,s0,-160
    80005b84:	4501                	li	a0,0
    80005b86:	ffffd097          	auipc	ra,0xffffd
    80005b8a:	256080e7          	jalr	598(ra) # 80002ddc <argstr>
    80005b8e:	04054b63          	bltz	a0,80005be4 <sys_chdir+0x86>
    80005b92:	f6040513          	addi	a0,s0,-160
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	592080e7          	jalr	1426(ra) # 80004128 <namei>
    80005b9e:	84aa                	mv	s1,a0
    80005ba0:	c131                	beqz	a0,80005be4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	dd0080e7          	jalr	-560(ra) # 80003972 <ilock>
  if(ip->type != T_DIR){
    80005baa:	04449703          	lh	a4,68(s1)
    80005bae:	4785                	li	a5,1
    80005bb0:	04f71063          	bne	a4,a5,80005bf0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bb4:	8526                	mv	a0,s1
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	e7e080e7          	jalr	-386(ra) # 80003a34 <iunlock>
  iput(p->cwd);
    80005bbe:	17093503          	ld	a0,368(s2)
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	f6a080e7          	jalr	-150(ra) # 80003b2c <iput>
  end_op();
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	7fa080e7          	jalr	2042(ra) # 800043c4 <end_op>
  p->cwd = ip;
    80005bd2:	16993823          	sd	s1,368(s2)
  return 0;
    80005bd6:	4501                	li	a0,0
}
    80005bd8:	60ea                	ld	ra,152(sp)
    80005bda:	644a                	ld	s0,144(sp)
    80005bdc:	64aa                	ld	s1,136(sp)
    80005bde:	690a                	ld	s2,128(sp)
    80005be0:	610d                	addi	sp,sp,160
    80005be2:	8082                	ret
    end_op();
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	7e0080e7          	jalr	2016(ra) # 800043c4 <end_op>
    return -1;
    80005bec:	557d                	li	a0,-1
    80005bee:	b7ed                	j	80005bd8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bf0:	8526                	mv	a0,s1
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	fe2080e7          	jalr	-30(ra) # 80003bd4 <iunlockput>
    end_op();
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	7ca080e7          	jalr	1994(ra) # 800043c4 <end_op>
    return -1;
    80005c02:	557d                	li	a0,-1
    80005c04:	bfd1                	j	80005bd8 <sys_chdir+0x7a>

0000000080005c06 <sys_exec>:

uint64
sys_exec(void)
{
    80005c06:	7145                	addi	sp,sp,-464
    80005c08:	e786                	sd	ra,456(sp)
    80005c0a:	e3a2                	sd	s0,448(sp)
    80005c0c:	ff26                	sd	s1,440(sp)
    80005c0e:	fb4a                	sd	s2,432(sp)
    80005c10:	f74e                	sd	s3,424(sp)
    80005c12:	f352                	sd	s4,416(sp)
    80005c14:	ef56                	sd	s5,408(sp)
    80005c16:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c18:	08000613          	li	a2,128
    80005c1c:	f4040593          	addi	a1,s0,-192
    80005c20:	4501                	li	a0,0
    80005c22:	ffffd097          	auipc	ra,0xffffd
    80005c26:	1ba080e7          	jalr	442(ra) # 80002ddc <argstr>
    return -1;
    80005c2a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c2c:	0c054a63          	bltz	a0,80005d00 <sys_exec+0xfa>
    80005c30:	e3840593          	addi	a1,s0,-456
    80005c34:	4505                	li	a0,1
    80005c36:	ffffd097          	auipc	ra,0xffffd
    80005c3a:	184080e7          	jalr	388(ra) # 80002dba <argaddr>
    80005c3e:	0c054163          	bltz	a0,80005d00 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c42:	10000613          	li	a2,256
    80005c46:	4581                	li	a1,0
    80005c48:	e4040513          	addi	a0,s0,-448
    80005c4c:	ffffb097          	auipc	ra,0xffffb
    80005c50:	094080e7          	jalr	148(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c54:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c58:	89a6                	mv	s3,s1
    80005c5a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c5c:	02000a13          	li	s4,32
    80005c60:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c64:	00391513          	slli	a0,s2,0x3
    80005c68:	e3040593          	addi	a1,s0,-464
    80005c6c:	e3843783          	ld	a5,-456(s0)
    80005c70:	953e                	add	a0,a0,a5
    80005c72:	ffffd097          	auipc	ra,0xffffd
    80005c76:	08c080e7          	jalr	140(ra) # 80002cfe <fetchaddr>
    80005c7a:	02054a63          	bltz	a0,80005cae <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c7e:	e3043783          	ld	a5,-464(s0)
    80005c82:	c3b9                	beqz	a5,80005cc8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c84:	ffffb097          	auipc	ra,0xffffb
    80005c88:	e70080e7          	jalr	-400(ra) # 80000af4 <kalloc>
    80005c8c:	85aa                	mv	a1,a0
    80005c8e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c92:	cd11                	beqz	a0,80005cae <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c94:	6605                	lui	a2,0x1
    80005c96:	e3043503          	ld	a0,-464(s0)
    80005c9a:	ffffd097          	auipc	ra,0xffffd
    80005c9e:	0b6080e7          	jalr	182(ra) # 80002d50 <fetchstr>
    80005ca2:	00054663          	bltz	a0,80005cae <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ca6:	0905                	addi	s2,s2,1
    80005ca8:	09a1                	addi	s3,s3,8
    80005caa:	fb491be3          	bne	s2,s4,80005c60 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cae:	10048913          	addi	s2,s1,256
    80005cb2:	6088                	ld	a0,0(s1)
    80005cb4:	c529                	beqz	a0,80005cfe <sys_exec+0xf8>
    kfree(argv[i]);
    80005cb6:	ffffb097          	auipc	ra,0xffffb
    80005cba:	d42080e7          	jalr	-702(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cbe:	04a1                	addi	s1,s1,8
    80005cc0:	ff2499e3          	bne	s1,s2,80005cb2 <sys_exec+0xac>
  return -1;
    80005cc4:	597d                	li	s2,-1
    80005cc6:	a82d                	j	80005d00 <sys_exec+0xfa>
      argv[i] = 0;
    80005cc8:	0a8e                	slli	s5,s5,0x3
    80005cca:	fc040793          	addi	a5,s0,-64
    80005cce:	9abe                	add	s5,s5,a5
    80005cd0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cd4:	e4040593          	addi	a1,s0,-448
    80005cd8:	f4040513          	addi	a0,s0,-192
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	194080e7          	jalr	404(ra) # 80004e70 <exec>
    80005ce4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce6:	10048993          	addi	s3,s1,256
    80005cea:	6088                	ld	a0,0(s1)
    80005cec:	c911                	beqz	a0,80005d00 <sys_exec+0xfa>
    kfree(argv[i]);
    80005cee:	ffffb097          	auipc	ra,0xffffb
    80005cf2:	d0a080e7          	jalr	-758(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cf6:	04a1                	addi	s1,s1,8
    80005cf8:	ff3499e3          	bne	s1,s3,80005cea <sys_exec+0xe4>
    80005cfc:	a011                	j	80005d00 <sys_exec+0xfa>
  return -1;
    80005cfe:	597d                	li	s2,-1
}
    80005d00:	854a                	mv	a0,s2
    80005d02:	60be                	ld	ra,456(sp)
    80005d04:	641e                	ld	s0,448(sp)
    80005d06:	74fa                	ld	s1,440(sp)
    80005d08:	795a                	ld	s2,432(sp)
    80005d0a:	79ba                	ld	s3,424(sp)
    80005d0c:	7a1a                	ld	s4,416(sp)
    80005d0e:	6afa                	ld	s5,408(sp)
    80005d10:	6179                	addi	sp,sp,464
    80005d12:	8082                	ret

0000000080005d14 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d14:	7139                	addi	sp,sp,-64
    80005d16:	fc06                	sd	ra,56(sp)
    80005d18:	f822                	sd	s0,48(sp)
    80005d1a:	f426                	sd	s1,40(sp)
    80005d1c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d1e:	ffffc097          	auipc	ra,0xffffc
    80005d22:	c92080e7          	jalr	-878(ra) # 800019b0 <myproc>
    80005d26:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d28:	fd840593          	addi	a1,s0,-40
    80005d2c:	4501                	li	a0,0
    80005d2e:	ffffd097          	auipc	ra,0xffffd
    80005d32:	08c080e7          	jalr	140(ra) # 80002dba <argaddr>
    return -1;
    80005d36:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d38:	0e054063          	bltz	a0,80005e18 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d3c:	fc840593          	addi	a1,s0,-56
    80005d40:	fd040513          	addi	a0,s0,-48
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	dfc080e7          	jalr	-516(ra) # 80004b40 <pipealloc>
    return -1;
    80005d4c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d4e:	0c054563          	bltz	a0,80005e18 <sys_pipe+0x104>
  fd0 = -1;
    80005d52:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d56:	fd043503          	ld	a0,-48(s0)
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	508080e7          	jalr	1288(ra) # 80005262 <fdalloc>
    80005d62:	fca42223          	sw	a0,-60(s0)
    80005d66:	08054c63          	bltz	a0,80005dfe <sys_pipe+0xea>
    80005d6a:	fc843503          	ld	a0,-56(s0)
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	4f4080e7          	jalr	1268(ra) # 80005262 <fdalloc>
    80005d76:	fca42023          	sw	a0,-64(s0)
    80005d7a:	06054863          	bltz	a0,80005dea <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d7e:	4691                	li	a3,4
    80005d80:	fc440613          	addi	a2,s0,-60
    80005d84:	fd843583          	ld	a1,-40(s0)
    80005d88:	78a8                	ld	a0,112(s1)
    80005d8a:	ffffc097          	auipc	ra,0xffffc
    80005d8e:	8e8080e7          	jalr	-1816(ra) # 80001672 <copyout>
    80005d92:	02054063          	bltz	a0,80005db2 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d96:	4691                	li	a3,4
    80005d98:	fc040613          	addi	a2,s0,-64
    80005d9c:	fd843583          	ld	a1,-40(s0)
    80005da0:	0591                	addi	a1,a1,4
    80005da2:	78a8                	ld	a0,112(s1)
    80005da4:	ffffc097          	auipc	ra,0xffffc
    80005da8:	8ce080e7          	jalr	-1842(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dac:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dae:	06055563          	bgez	a0,80005e18 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005db2:	fc442783          	lw	a5,-60(s0)
    80005db6:	07f9                	addi	a5,a5,30
    80005db8:	078e                	slli	a5,a5,0x3
    80005dba:	97a6                	add	a5,a5,s1
    80005dbc:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dc0:	fc042503          	lw	a0,-64(s0)
    80005dc4:	0579                	addi	a0,a0,30
    80005dc6:	050e                	slli	a0,a0,0x3
    80005dc8:	9526                	add	a0,a0,s1
    80005dca:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005dce:	fd043503          	ld	a0,-48(s0)
    80005dd2:	fffff097          	auipc	ra,0xfffff
    80005dd6:	a3e080e7          	jalr	-1474(ra) # 80004810 <fileclose>
    fileclose(wf);
    80005dda:	fc843503          	ld	a0,-56(s0)
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	a32080e7          	jalr	-1486(ra) # 80004810 <fileclose>
    return -1;
    80005de6:	57fd                	li	a5,-1
    80005de8:	a805                	j	80005e18 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005dea:	fc442783          	lw	a5,-60(s0)
    80005dee:	0007c863          	bltz	a5,80005dfe <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005df2:	01e78513          	addi	a0,a5,30
    80005df6:	050e                	slli	a0,a0,0x3
    80005df8:	9526                	add	a0,a0,s1
    80005dfa:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005dfe:	fd043503          	ld	a0,-48(s0)
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	a0e080e7          	jalr	-1522(ra) # 80004810 <fileclose>
    fileclose(wf);
    80005e0a:	fc843503          	ld	a0,-56(s0)
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	a02080e7          	jalr	-1534(ra) # 80004810 <fileclose>
    return -1;
    80005e16:	57fd                	li	a5,-1
}
    80005e18:	853e                	mv	a0,a5
    80005e1a:	70e2                	ld	ra,56(sp)
    80005e1c:	7442                	ld	s0,48(sp)
    80005e1e:	74a2                	ld	s1,40(sp)
    80005e20:	6121                	addi	sp,sp,64
    80005e22:	8082                	ret
	...

0000000080005e30 <kernelvec>:
    80005e30:	7111                	addi	sp,sp,-256
    80005e32:	e006                	sd	ra,0(sp)
    80005e34:	e40a                	sd	sp,8(sp)
    80005e36:	e80e                	sd	gp,16(sp)
    80005e38:	ec12                	sd	tp,24(sp)
    80005e3a:	f016                	sd	t0,32(sp)
    80005e3c:	f41a                	sd	t1,40(sp)
    80005e3e:	f81e                	sd	t2,48(sp)
    80005e40:	fc22                	sd	s0,56(sp)
    80005e42:	e0a6                	sd	s1,64(sp)
    80005e44:	e4aa                	sd	a0,72(sp)
    80005e46:	e8ae                	sd	a1,80(sp)
    80005e48:	ecb2                	sd	a2,88(sp)
    80005e4a:	f0b6                	sd	a3,96(sp)
    80005e4c:	f4ba                	sd	a4,104(sp)
    80005e4e:	f8be                	sd	a5,112(sp)
    80005e50:	fcc2                	sd	a6,120(sp)
    80005e52:	e146                	sd	a7,128(sp)
    80005e54:	e54a                	sd	s2,136(sp)
    80005e56:	e94e                	sd	s3,144(sp)
    80005e58:	ed52                	sd	s4,152(sp)
    80005e5a:	f156                	sd	s5,160(sp)
    80005e5c:	f55a                	sd	s6,168(sp)
    80005e5e:	f95e                	sd	s7,176(sp)
    80005e60:	fd62                	sd	s8,184(sp)
    80005e62:	e1e6                	sd	s9,192(sp)
    80005e64:	e5ea                	sd	s10,200(sp)
    80005e66:	e9ee                	sd	s11,208(sp)
    80005e68:	edf2                	sd	t3,216(sp)
    80005e6a:	f1f6                	sd	t4,224(sp)
    80005e6c:	f5fa                	sd	t5,232(sp)
    80005e6e:	f9fe                	sd	t6,240(sp)
    80005e70:	d5bfc0ef          	jal	ra,80002bca <kerneltrap>
    80005e74:	6082                	ld	ra,0(sp)
    80005e76:	6122                	ld	sp,8(sp)
    80005e78:	61c2                	ld	gp,16(sp)
    80005e7a:	7282                	ld	t0,32(sp)
    80005e7c:	7322                	ld	t1,40(sp)
    80005e7e:	73c2                	ld	t2,48(sp)
    80005e80:	7462                	ld	s0,56(sp)
    80005e82:	6486                	ld	s1,64(sp)
    80005e84:	6526                	ld	a0,72(sp)
    80005e86:	65c6                	ld	a1,80(sp)
    80005e88:	6666                	ld	a2,88(sp)
    80005e8a:	7686                	ld	a3,96(sp)
    80005e8c:	7726                	ld	a4,104(sp)
    80005e8e:	77c6                	ld	a5,112(sp)
    80005e90:	7866                	ld	a6,120(sp)
    80005e92:	688a                	ld	a7,128(sp)
    80005e94:	692a                	ld	s2,136(sp)
    80005e96:	69ca                	ld	s3,144(sp)
    80005e98:	6a6a                	ld	s4,152(sp)
    80005e9a:	7a8a                	ld	s5,160(sp)
    80005e9c:	7b2a                	ld	s6,168(sp)
    80005e9e:	7bca                	ld	s7,176(sp)
    80005ea0:	7c6a                	ld	s8,184(sp)
    80005ea2:	6c8e                	ld	s9,192(sp)
    80005ea4:	6d2e                	ld	s10,200(sp)
    80005ea6:	6dce                	ld	s11,208(sp)
    80005ea8:	6e6e                	ld	t3,216(sp)
    80005eaa:	7e8e                	ld	t4,224(sp)
    80005eac:	7f2e                	ld	t5,232(sp)
    80005eae:	7fce                	ld	t6,240(sp)
    80005eb0:	6111                	addi	sp,sp,256
    80005eb2:	10200073          	sret
    80005eb6:	00000013          	nop
    80005eba:	00000013          	nop
    80005ebe:	0001                	nop

0000000080005ec0 <timervec>:
    80005ec0:	34051573          	csrrw	a0,mscratch,a0
    80005ec4:	e10c                	sd	a1,0(a0)
    80005ec6:	e510                	sd	a2,8(a0)
    80005ec8:	e914                	sd	a3,16(a0)
    80005eca:	6d0c                	ld	a1,24(a0)
    80005ecc:	7110                	ld	a2,32(a0)
    80005ece:	6194                	ld	a3,0(a1)
    80005ed0:	96b2                	add	a3,a3,a2
    80005ed2:	e194                	sd	a3,0(a1)
    80005ed4:	4589                	li	a1,2
    80005ed6:	14459073          	csrw	sip,a1
    80005eda:	6914                	ld	a3,16(a0)
    80005edc:	6510                	ld	a2,8(a0)
    80005ede:	610c                	ld	a1,0(a0)
    80005ee0:	34051573          	csrrw	a0,mscratch,a0
    80005ee4:	30200073          	mret
	...

0000000080005eea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eea:	1141                	addi	sp,sp,-16
    80005eec:	e422                	sd	s0,8(sp)
    80005eee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ef0:	0c0007b7          	lui	a5,0xc000
    80005ef4:	4705                	li	a4,1
    80005ef6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ef8:	c3d8                	sw	a4,4(a5)
}
    80005efa:	6422                	ld	s0,8(sp)
    80005efc:	0141                	addi	sp,sp,16
    80005efe:	8082                	ret

0000000080005f00 <plicinithart>:

void
plicinithart(void)
{
    80005f00:	1141                	addi	sp,sp,-16
    80005f02:	e406                	sd	ra,8(sp)
    80005f04:	e022                	sd	s0,0(sp)
    80005f06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f08:	ffffc097          	auipc	ra,0xffffc
    80005f0c:	a7c080e7          	jalr	-1412(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f10:	0085171b          	slliw	a4,a0,0x8
    80005f14:	0c0027b7          	lui	a5,0xc002
    80005f18:	97ba                	add	a5,a5,a4
    80005f1a:	40200713          	li	a4,1026
    80005f1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f22:	00d5151b          	slliw	a0,a0,0xd
    80005f26:	0c2017b7          	lui	a5,0xc201
    80005f2a:	953e                	add	a0,a0,a5
    80005f2c:	00052023          	sw	zero,0(a0)
}
    80005f30:	60a2                	ld	ra,8(sp)
    80005f32:	6402                	ld	s0,0(sp)
    80005f34:	0141                	addi	sp,sp,16
    80005f36:	8082                	ret

0000000080005f38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f38:	1141                	addi	sp,sp,-16
    80005f3a:	e406                	sd	ra,8(sp)
    80005f3c:	e022                	sd	s0,0(sp)
    80005f3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f40:	ffffc097          	auipc	ra,0xffffc
    80005f44:	a44080e7          	jalr	-1468(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f48:	00d5179b          	slliw	a5,a0,0xd
    80005f4c:	0c201537          	lui	a0,0xc201
    80005f50:	953e                	add	a0,a0,a5
  return irq;
}
    80005f52:	4148                	lw	a0,4(a0)
    80005f54:	60a2                	ld	ra,8(sp)
    80005f56:	6402                	ld	s0,0(sp)
    80005f58:	0141                	addi	sp,sp,16
    80005f5a:	8082                	ret

0000000080005f5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f5c:	1101                	addi	sp,sp,-32
    80005f5e:	ec06                	sd	ra,24(sp)
    80005f60:	e822                	sd	s0,16(sp)
    80005f62:	e426                	sd	s1,8(sp)
    80005f64:	1000                	addi	s0,sp,32
    80005f66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	a1c080e7          	jalr	-1508(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f70:	00d5151b          	slliw	a0,a0,0xd
    80005f74:	0c2017b7          	lui	a5,0xc201
    80005f78:	97aa                	add	a5,a5,a0
    80005f7a:	c3c4                	sw	s1,4(a5)
}
    80005f7c:	60e2                	ld	ra,24(sp)
    80005f7e:	6442                	ld	s0,16(sp)
    80005f80:	64a2                	ld	s1,8(sp)
    80005f82:	6105                	addi	sp,sp,32
    80005f84:	8082                	ret

0000000080005f86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f86:	1141                	addi	sp,sp,-16
    80005f88:	e406                	sd	ra,8(sp)
    80005f8a:	e022                	sd	s0,0(sp)
    80005f8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f8e:	479d                	li	a5,7
    80005f90:	06a7c963          	blt	a5,a0,80006002 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f94:	0001d797          	auipc	a5,0x1d
    80005f98:	06c78793          	addi	a5,a5,108 # 80023000 <disk>
    80005f9c:	00a78733          	add	a4,a5,a0
    80005fa0:	6789                	lui	a5,0x2
    80005fa2:	97ba                	add	a5,a5,a4
    80005fa4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fa8:	e7ad                	bnez	a5,80006012 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005faa:	00451793          	slli	a5,a0,0x4
    80005fae:	0001f717          	auipc	a4,0x1f
    80005fb2:	05270713          	addi	a4,a4,82 # 80025000 <disk+0x2000>
    80005fb6:	6314                	ld	a3,0(a4)
    80005fb8:	96be                	add	a3,a3,a5
    80005fba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fbe:	6314                	ld	a3,0(a4)
    80005fc0:	96be                	add	a3,a3,a5
    80005fc2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005fc6:	6314                	ld	a3,0(a4)
    80005fc8:	96be                	add	a3,a3,a5
    80005fca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005fce:	6318                	ld	a4,0(a4)
    80005fd0:	97ba                	add	a5,a5,a4
    80005fd2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005fd6:	0001d797          	auipc	a5,0x1d
    80005fda:	02a78793          	addi	a5,a5,42 # 80023000 <disk>
    80005fde:	97aa                	add	a5,a5,a0
    80005fe0:	6509                	lui	a0,0x2
    80005fe2:	953e                	add	a0,a0,a5
    80005fe4:	4785                	li	a5,1
    80005fe6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fea:	0001f517          	auipc	a0,0x1f
    80005fee:	02e50513          	addi	a0,a0,46 # 80025018 <disk+0x2018>
    80005ff2:	ffffc097          	auipc	ra,0xffffc
    80005ff6:	30e080e7          	jalr	782(ra) # 80002300 <wakeup>
}
    80005ffa:	60a2                	ld	ra,8(sp)
    80005ffc:	6402                	ld	s0,0(sp)
    80005ffe:	0141                	addi	sp,sp,16
    80006000:	8082                	ret
    panic("free_desc 1");
    80006002:	00003517          	auipc	a0,0x3
    80006006:	82650513          	addi	a0,a0,-2010 # 80008828 <syscalls+0x338>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	534080e7          	jalr	1332(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	82650513          	addi	a0,a0,-2010 # 80008838 <syscalls+0x348>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	524080e7          	jalr	1316(ra) # 8000053e <panic>

0000000080006022 <virtio_disk_init>:
{
    80006022:	1101                	addi	sp,sp,-32
    80006024:	ec06                	sd	ra,24(sp)
    80006026:	e822                	sd	s0,16(sp)
    80006028:	e426                	sd	s1,8(sp)
    8000602a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000602c:	00003597          	auipc	a1,0x3
    80006030:	81c58593          	addi	a1,a1,-2020 # 80008848 <syscalls+0x358>
    80006034:	0001f517          	auipc	a0,0x1f
    80006038:	0f450513          	addi	a0,a0,244 # 80025128 <disk+0x2128>
    8000603c:	ffffb097          	auipc	ra,0xffffb
    80006040:	b18080e7          	jalr	-1256(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006044:	100017b7          	lui	a5,0x10001
    80006048:	4398                	lw	a4,0(a5)
    8000604a:	2701                	sext.w	a4,a4
    8000604c:	747277b7          	lui	a5,0x74727
    80006050:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006054:	0ef71163          	bne	a4,a5,80006136 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006058:	100017b7          	lui	a5,0x10001
    8000605c:	43dc                	lw	a5,4(a5)
    8000605e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006060:	4705                	li	a4,1
    80006062:	0ce79a63          	bne	a5,a4,80006136 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006066:	100017b7          	lui	a5,0x10001
    8000606a:	479c                	lw	a5,8(a5)
    8000606c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000606e:	4709                	li	a4,2
    80006070:	0ce79363          	bne	a5,a4,80006136 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006074:	100017b7          	lui	a5,0x10001
    80006078:	47d8                	lw	a4,12(a5)
    8000607a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000607c:	554d47b7          	lui	a5,0x554d4
    80006080:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006084:	0af71963          	bne	a4,a5,80006136 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006088:	100017b7          	lui	a5,0x10001
    8000608c:	4705                	li	a4,1
    8000608e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006090:	470d                	li	a4,3
    80006092:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006094:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006096:	c7ffe737          	lui	a4,0xc7ffe
    8000609a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000609e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060a0:	2701                	sext.w	a4,a4
    800060a2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a4:	472d                	li	a4,11
    800060a6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a8:	473d                	li	a4,15
    800060aa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060ac:	6705                	lui	a4,0x1
    800060ae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060b4:	5bdc                	lw	a5,52(a5)
    800060b6:	2781                	sext.w	a5,a5
  if(max == 0)
    800060b8:	c7d9                	beqz	a5,80006146 <virtio_disk_init+0x124>
  if(max < NUM)
    800060ba:	471d                	li	a4,7
    800060bc:	08f77d63          	bgeu	a4,a5,80006156 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060c0:	100014b7          	lui	s1,0x10001
    800060c4:	47a1                	li	a5,8
    800060c6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060c8:	6609                	lui	a2,0x2
    800060ca:	4581                	li	a1,0
    800060cc:	0001d517          	auipc	a0,0x1d
    800060d0:	f3450513          	addi	a0,a0,-204 # 80023000 <disk>
    800060d4:	ffffb097          	auipc	ra,0xffffb
    800060d8:	c0c080e7          	jalr	-1012(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060dc:	0001d717          	auipc	a4,0x1d
    800060e0:	f2470713          	addi	a4,a4,-220 # 80023000 <disk>
    800060e4:	00c75793          	srli	a5,a4,0xc
    800060e8:	2781                	sext.w	a5,a5
    800060ea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060ec:	0001f797          	auipc	a5,0x1f
    800060f0:	f1478793          	addi	a5,a5,-236 # 80025000 <disk+0x2000>
    800060f4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060f6:	0001d717          	auipc	a4,0x1d
    800060fa:	f8a70713          	addi	a4,a4,-118 # 80023080 <disk+0x80>
    800060fe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006100:	0001e717          	auipc	a4,0x1e
    80006104:	f0070713          	addi	a4,a4,-256 # 80024000 <disk+0x1000>
    80006108:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000610a:	4705                	li	a4,1
    8000610c:	00e78c23          	sb	a4,24(a5)
    80006110:	00e78ca3          	sb	a4,25(a5)
    80006114:	00e78d23          	sb	a4,26(a5)
    80006118:	00e78da3          	sb	a4,27(a5)
    8000611c:	00e78e23          	sb	a4,28(a5)
    80006120:	00e78ea3          	sb	a4,29(a5)
    80006124:	00e78f23          	sb	a4,30(a5)
    80006128:	00e78fa3          	sb	a4,31(a5)
}
    8000612c:	60e2                	ld	ra,24(sp)
    8000612e:	6442                	ld	s0,16(sp)
    80006130:	64a2                	ld	s1,8(sp)
    80006132:	6105                	addi	sp,sp,32
    80006134:	8082                	ret
    panic("could not find virtio disk");
    80006136:	00002517          	auipc	a0,0x2
    8000613a:	72250513          	addi	a0,a0,1826 # 80008858 <syscalls+0x368>
    8000613e:	ffffa097          	auipc	ra,0xffffa
    80006142:	400080e7          	jalr	1024(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006146:	00002517          	auipc	a0,0x2
    8000614a:	73250513          	addi	a0,a0,1842 # 80008878 <syscalls+0x388>
    8000614e:	ffffa097          	auipc	ra,0xffffa
    80006152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006156:	00002517          	auipc	a0,0x2
    8000615a:	74250513          	addi	a0,a0,1858 # 80008898 <syscalls+0x3a8>
    8000615e:	ffffa097          	auipc	ra,0xffffa
    80006162:	3e0080e7          	jalr	992(ra) # 8000053e <panic>

0000000080006166 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006166:	7159                	addi	sp,sp,-112
    80006168:	f486                	sd	ra,104(sp)
    8000616a:	f0a2                	sd	s0,96(sp)
    8000616c:	eca6                	sd	s1,88(sp)
    8000616e:	e8ca                	sd	s2,80(sp)
    80006170:	e4ce                	sd	s3,72(sp)
    80006172:	e0d2                	sd	s4,64(sp)
    80006174:	fc56                	sd	s5,56(sp)
    80006176:	f85a                	sd	s6,48(sp)
    80006178:	f45e                	sd	s7,40(sp)
    8000617a:	f062                	sd	s8,32(sp)
    8000617c:	ec66                	sd	s9,24(sp)
    8000617e:	e86a                	sd	s10,16(sp)
    80006180:	1880                	addi	s0,sp,112
    80006182:	892a                	mv	s2,a0
    80006184:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006186:	00c52c83          	lw	s9,12(a0)
    8000618a:	001c9c9b          	slliw	s9,s9,0x1
    8000618e:	1c82                	slli	s9,s9,0x20
    80006190:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006194:	0001f517          	auipc	a0,0x1f
    80006198:	f9450513          	addi	a0,a0,-108 # 80025128 <disk+0x2128>
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	a48080e7          	jalr	-1464(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800061a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061a6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061a8:	0001db97          	auipc	s7,0x1d
    800061ac:	e58b8b93          	addi	s7,s7,-424 # 80023000 <disk>
    800061b0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800061b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061b4:	8a4e                	mv	s4,s3
    800061b6:	a051                	j	8000623a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800061b8:	00fb86b3          	add	a3,s7,a5
    800061bc:	96da                	add	a3,a3,s6
    800061be:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061c2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061c4:	0207c563          	bltz	a5,800061ee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061c8:	2485                	addiw	s1,s1,1
    800061ca:	0711                	addi	a4,a4,4
    800061cc:	25548063          	beq	s1,s5,8000640c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800061d0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061d2:	0001f697          	auipc	a3,0x1f
    800061d6:	e4668693          	addi	a3,a3,-442 # 80025018 <disk+0x2018>
    800061da:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061dc:	0006c583          	lbu	a1,0(a3)
    800061e0:	fde1                	bnez	a1,800061b8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061e2:	2785                	addiw	a5,a5,1
    800061e4:	0685                	addi	a3,a3,1
    800061e6:	ff879be3          	bne	a5,s8,800061dc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061ea:	57fd                	li	a5,-1
    800061ec:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061ee:	02905a63          	blez	s1,80006222 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061f2:	f9042503          	lw	a0,-112(s0)
    800061f6:	00000097          	auipc	ra,0x0
    800061fa:	d90080e7          	jalr	-624(ra) # 80005f86 <free_desc>
      for(int j = 0; j < i; j++)
    800061fe:	4785                	li	a5,1
    80006200:	0297d163          	bge	a5,s1,80006222 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006204:	f9442503          	lw	a0,-108(s0)
    80006208:	00000097          	auipc	ra,0x0
    8000620c:	d7e080e7          	jalr	-642(ra) # 80005f86 <free_desc>
      for(int j = 0; j < i; j++)
    80006210:	4789                	li	a5,2
    80006212:	0097d863          	bge	a5,s1,80006222 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006216:	f9842503          	lw	a0,-104(s0)
    8000621a:	00000097          	auipc	ra,0x0
    8000621e:	d6c080e7          	jalr	-660(ra) # 80005f86 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006222:	0001f597          	auipc	a1,0x1f
    80006226:	f0658593          	addi	a1,a1,-250 # 80025128 <disk+0x2128>
    8000622a:	0001f517          	auipc	a0,0x1f
    8000622e:	dee50513          	addi	a0,a0,-530 # 80025018 <disk+0x2018>
    80006232:	ffffc097          	auipc	ra,0xffffc
    80006236:	f16080e7          	jalr	-234(ra) # 80002148 <sleep>
  for(int i = 0; i < 3; i++){
    8000623a:	f9040713          	addi	a4,s0,-112
    8000623e:	84ce                	mv	s1,s3
    80006240:	bf41                	j	800061d0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006242:	20058713          	addi	a4,a1,512
    80006246:	00471693          	slli	a3,a4,0x4
    8000624a:	0001d717          	auipc	a4,0x1d
    8000624e:	db670713          	addi	a4,a4,-586 # 80023000 <disk>
    80006252:	9736                	add	a4,a4,a3
    80006254:	4685                	li	a3,1
    80006256:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000625a:	20058713          	addi	a4,a1,512
    8000625e:	00471693          	slli	a3,a4,0x4
    80006262:	0001d717          	auipc	a4,0x1d
    80006266:	d9e70713          	addi	a4,a4,-610 # 80023000 <disk>
    8000626a:	9736                	add	a4,a4,a3
    8000626c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006270:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006274:	7679                	lui	a2,0xffffe
    80006276:	963e                	add	a2,a2,a5
    80006278:	0001f697          	auipc	a3,0x1f
    8000627c:	d8868693          	addi	a3,a3,-632 # 80025000 <disk+0x2000>
    80006280:	6298                	ld	a4,0(a3)
    80006282:	9732                	add	a4,a4,a2
    80006284:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006286:	6298                	ld	a4,0(a3)
    80006288:	9732                	add	a4,a4,a2
    8000628a:	4541                	li	a0,16
    8000628c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000628e:	6298                	ld	a4,0(a3)
    80006290:	9732                	add	a4,a4,a2
    80006292:	4505                	li	a0,1
    80006294:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006298:	f9442703          	lw	a4,-108(s0)
    8000629c:	6288                	ld	a0,0(a3)
    8000629e:	962a                	add	a2,a2,a0
    800062a0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062a4:	0712                	slli	a4,a4,0x4
    800062a6:	6290                	ld	a2,0(a3)
    800062a8:	963a                	add	a2,a2,a4
    800062aa:	05890513          	addi	a0,s2,88
    800062ae:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800062b0:	6294                	ld	a3,0(a3)
    800062b2:	96ba                	add	a3,a3,a4
    800062b4:	40000613          	li	a2,1024
    800062b8:	c690                	sw	a2,8(a3)
  if(write)
    800062ba:	140d0063          	beqz	s10,800063fa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062be:	0001f697          	auipc	a3,0x1f
    800062c2:	d426b683          	ld	a3,-702(a3) # 80025000 <disk+0x2000>
    800062c6:	96ba                	add	a3,a3,a4
    800062c8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062cc:	0001d817          	auipc	a6,0x1d
    800062d0:	d3480813          	addi	a6,a6,-716 # 80023000 <disk>
    800062d4:	0001f517          	auipc	a0,0x1f
    800062d8:	d2c50513          	addi	a0,a0,-724 # 80025000 <disk+0x2000>
    800062dc:	6114                	ld	a3,0(a0)
    800062de:	96ba                	add	a3,a3,a4
    800062e0:	00c6d603          	lhu	a2,12(a3)
    800062e4:	00166613          	ori	a2,a2,1
    800062e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062ec:	f9842683          	lw	a3,-104(s0)
    800062f0:	6110                	ld	a2,0(a0)
    800062f2:	9732                	add	a4,a4,a2
    800062f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062f8:	20058613          	addi	a2,a1,512
    800062fc:	0612                	slli	a2,a2,0x4
    800062fe:	9642                	add	a2,a2,a6
    80006300:	577d                	li	a4,-1
    80006302:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006306:	00469713          	slli	a4,a3,0x4
    8000630a:	6114                	ld	a3,0(a0)
    8000630c:	96ba                	add	a3,a3,a4
    8000630e:	03078793          	addi	a5,a5,48
    80006312:	97c2                	add	a5,a5,a6
    80006314:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006316:	611c                	ld	a5,0(a0)
    80006318:	97ba                	add	a5,a5,a4
    8000631a:	4685                	li	a3,1
    8000631c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000631e:	611c                	ld	a5,0(a0)
    80006320:	97ba                	add	a5,a5,a4
    80006322:	4809                	li	a6,2
    80006324:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006328:	611c                	ld	a5,0(a0)
    8000632a:	973e                	add	a4,a4,a5
    8000632c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006330:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006334:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006338:	6518                	ld	a4,8(a0)
    8000633a:	00275783          	lhu	a5,2(a4)
    8000633e:	8b9d                	andi	a5,a5,7
    80006340:	0786                	slli	a5,a5,0x1
    80006342:	97ba                	add	a5,a5,a4
    80006344:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006348:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000634c:	6518                	ld	a4,8(a0)
    8000634e:	00275783          	lhu	a5,2(a4)
    80006352:	2785                	addiw	a5,a5,1
    80006354:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006358:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000635c:	100017b7          	lui	a5,0x10001
    80006360:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006364:	00492703          	lw	a4,4(s2)
    80006368:	4785                	li	a5,1
    8000636a:	02f71163          	bne	a4,a5,8000638c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000636e:	0001f997          	auipc	s3,0x1f
    80006372:	dba98993          	addi	s3,s3,-582 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006376:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006378:	85ce                	mv	a1,s3
    8000637a:	854a                	mv	a0,s2
    8000637c:	ffffc097          	auipc	ra,0xffffc
    80006380:	dcc080e7          	jalr	-564(ra) # 80002148 <sleep>
  while(b->disk == 1) {
    80006384:	00492783          	lw	a5,4(s2)
    80006388:	fe9788e3          	beq	a5,s1,80006378 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000638c:	f9042903          	lw	s2,-112(s0)
    80006390:	20090793          	addi	a5,s2,512
    80006394:	00479713          	slli	a4,a5,0x4
    80006398:	0001d797          	auipc	a5,0x1d
    8000639c:	c6878793          	addi	a5,a5,-920 # 80023000 <disk>
    800063a0:	97ba                	add	a5,a5,a4
    800063a2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063a6:	0001f997          	auipc	s3,0x1f
    800063aa:	c5a98993          	addi	s3,s3,-934 # 80025000 <disk+0x2000>
    800063ae:	00491713          	slli	a4,s2,0x4
    800063b2:	0009b783          	ld	a5,0(s3)
    800063b6:	97ba                	add	a5,a5,a4
    800063b8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063bc:	854a                	mv	a0,s2
    800063be:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063c2:	00000097          	auipc	ra,0x0
    800063c6:	bc4080e7          	jalr	-1084(ra) # 80005f86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063ca:	8885                	andi	s1,s1,1
    800063cc:	f0ed                	bnez	s1,800063ae <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063ce:	0001f517          	auipc	a0,0x1f
    800063d2:	d5a50513          	addi	a0,a0,-678 # 80025128 <disk+0x2128>
    800063d6:	ffffb097          	auipc	ra,0xffffb
    800063da:	8c2080e7          	jalr	-1854(ra) # 80000c98 <release>
}
    800063de:	70a6                	ld	ra,104(sp)
    800063e0:	7406                	ld	s0,96(sp)
    800063e2:	64e6                	ld	s1,88(sp)
    800063e4:	6946                	ld	s2,80(sp)
    800063e6:	69a6                	ld	s3,72(sp)
    800063e8:	6a06                	ld	s4,64(sp)
    800063ea:	7ae2                	ld	s5,56(sp)
    800063ec:	7b42                	ld	s6,48(sp)
    800063ee:	7ba2                	ld	s7,40(sp)
    800063f0:	7c02                	ld	s8,32(sp)
    800063f2:	6ce2                	ld	s9,24(sp)
    800063f4:	6d42                	ld	s10,16(sp)
    800063f6:	6165                	addi	sp,sp,112
    800063f8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063fa:	0001f697          	auipc	a3,0x1f
    800063fe:	c066b683          	ld	a3,-1018(a3) # 80025000 <disk+0x2000>
    80006402:	96ba                	add	a3,a3,a4
    80006404:	4609                	li	a2,2
    80006406:	00c69623          	sh	a2,12(a3)
    8000640a:	b5c9                	j	800062cc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000640c:	f9042583          	lw	a1,-112(s0)
    80006410:	20058793          	addi	a5,a1,512
    80006414:	0792                	slli	a5,a5,0x4
    80006416:	0001d517          	auipc	a0,0x1d
    8000641a:	c9250513          	addi	a0,a0,-878 # 800230a8 <disk+0xa8>
    8000641e:	953e                	add	a0,a0,a5
  if(write)
    80006420:	e20d11e3          	bnez	s10,80006242 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006424:	20058713          	addi	a4,a1,512
    80006428:	00471693          	slli	a3,a4,0x4
    8000642c:	0001d717          	auipc	a4,0x1d
    80006430:	bd470713          	addi	a4,a4,-1068 # 80023000 <disk>
    80006434:	9736                	add	a4,a4,a3
    80006436:	0a072423          	sw	zero,168(a4)
    8000643a:	b505                	j	8000625a <virtio_disk_rw+0xf4>

000000008000643c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000643c:	1101                	addi	sp,sp,-32
    8000643e:	ec06                	sd	ra,24(sp)
    80006440:	e822                	sd	s0,16(sp)
    80006442:	e426                	sd	s1,8(sp)
    80006444:	e04a                	sd	s2,0(sp)
    80006446:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006448:	0001f517          	auipc	a0,0x1f
    8000644c:	ce050513          	addi	a0,a0,-800 # 80025128 <disk+0x2128>
    80006450:	ffffa097          	auipc	ra,0xffffa
    80006454:	794080e7          	jalr	1940(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006458:	10001737          	lui	a4,0x10001
    8000645c:	533c                	lw	a5,96(a4)
    8000645e:	8b8d                	andi	a5,a5,3
    80006460:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006462:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006466:	0001f797          	auipc	a5,0x1f
    8000646a:	b9a78793          	addi	a5,a5,-1126 # 80025000 <disk+0x2000>
    8000646e:	6b94                	ld	a3,16(a5)
    80006470:	0207d703          	lhu	a4,32(a5)
    80006474:	0026d783          	lhu	a5,2(a3)
    80006478:	06f70163          	beq	a4,a5,800064da <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000647c:	0001d917          	auipc	s2,0x1d
    80006480:	b8490913          	addi	s2,s2,-1148 # 80023000 <disk>
    80006484:	0001f497          	auipc	s1,0x1f
    80006488:	b7c48493          	addi	s1,s1,-1156 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000648c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006490:	6898                	ld	a4,16(s1)
    80006492:	0204d783          	lhu	a5,32(s1)
    80006496:	8b9d                	andi	a5,a5,7
    80006498:	078e                	slli	a5,a5,0x3
    8000649a:	97ba                	add	a5,a5,a4
    8000649c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000649e:	20078713          	addi	a4,a5,512
    800064a2:	0712                	slli	a4,a4,0x4
    800064a4:	974a                	add	a4,a4,s2
    800064a6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064aa:	e731                	bnez	a4,800064f6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064ac:	20078793          	addi	a5,a5,512
    800064b0:	0792                	slli	a5,a5,0x4
    800064b2:	97ca                	add	a5,a5,s2
    800064b4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064b6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064ba:	ffffc097          	auipc	ra,0xffffc
    800064be:	e46080e7          	jalr	-442(ra) # 80002300 <wakeup>

    disk.used_idx += 1;
    800064c2:	0204d783          	lhu	a5,32(s1)
    800064c6:	2785                	addiw	a5,a5,1
    800064c8:	17c2                	slli	a5,a5,0x30
    800064ca:	93c1                	srli	a5,a5,0x30
    800064cc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064d0:	6898                	ld	a4,16(s1)
    800064d2:	00275703          	lhu	a4,2(a4)
    800064d6:	faf71be3          	bne	a4,a5,8000648c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064da:	0001f517          	auipc	a0,0x1f
    800064de:	c4e50513          	addi	a0,a0,-946 # 80025128 <disk+0x2128>
    800064e2:	ffffa097          	auipc	ra,0xffffa
    800064e6:	7b6080e7          	jalr	1974(ra) # 80000c98 <release>
}
    800064ea:	60e2                	ld	ra,24(sp)
    800064ec:	6442                	ld	s0,16(sp)
    800064ee:	64a2                	ld	s1,8(sp)
    800064f0:	6902                	ld	s2,0(sp)
    800064f2:	6105                	addi	sp,sp,32
    800064f4:	8082                	ret
      panic("virtio_disk_intr status");
    800064f6:	00002517          	auipc	a0,0x2
    800064fa:	3c250513          	addi	a0,a0,962 # 800088b8 <syscalls+0x3c8>
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	040080e7          	jalr	64(ra) # 8000053e <panic>
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
