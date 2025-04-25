;;; Payload for i386 systems.
;;; Reads words from input and executes them

;;; Register usage
;;; SP = return stack
;;; BP = parameter stack

	;; TODO: Understand these macros better
	;; Macros
	%macro pspush 1
	sub bp, 2
	mov [bp], %1
	%endmacro

	%macro pspop 1
	mov %1, [bp]
	add bp, 2
	%endmacro

	%macro firstword 2	; name, namelen
	db %1
	dw 0
	db %2
	%push dict
%$prev_word:
	%endmacro

	%macro defword 2	; name, namelen
	db %1
	dw %$prev_word-3
	db %2
	%pop
	%push dict
%$prev_word:
	%endmacro

	%macro lastword 2	; name, namelen
	db %1
dictionary:
	dw %$prev_word-3
	db %2
	%endmacro
	
	BITS 16
	org 0x500

	cld
	mov sp, 0
	mov bp, 0xF800
loop:
	call readword
	mov si, curword
	call parsedecimal
	jnz .nan
	pspush ax
	jmp loop

	.nan:
	mov di, curword
	call strlen
	mov ax, cx
	mov dx, curword
	call dictfind
	cmp bx, 0
	jz .wordnotfound
	add bx, 3
	call bx
	jmp loop

	.wordnotfound:
	mov di, curword
	call printmsg
	mov di, wordnotfoundmsg
	call printmsg
	jmp loop

wordnotfoundmsg:
	db ' word not found!', 0

;;; in: di = null-terminated string
;;; out: cx = len
strlen:
	mov cx, 0xffff
	mov ax, 0
	repnz scasb
	neg cx
	sub cx, 2		; 1 for starting at 0xffff, 1 for the null
	ret

;;; in: al = char
;;; preserves: bx
printchar:
	mov ah, 0x02		; BIOS INT 0x10 function: Set cursor pos
	mov bh, 0		; page number
	mov dx, [pos]
	inc word [pos]
	int 0x10
	mov ah, 0x09		; BIOS INT 0x10 function: Write char at pos
	mov bl, [color]
	mov cx, 1
	int 0x10
	ret

;;; in: di = null-terminated string
;;; out: n/a
printmsg:
	mov al, [di]		; dereference msg pointer
	inc di
	cmp al, 0
	jz .done
	call printchar
	jmp printmsg

	.done:
	ret

;;; in: n/a
;;; out: al = entered char
readkey:
	mov ah, 0		; BIOS INT 0x16 function: Read key
	int 0x16
	ret

;;; Read chars from input and write to output until whitespace, at which point
;;; write the whole word to teletype output
readword:
	call readkey
	cmp al, 0x21		; is al whitespace?
	jb readword		; if yes, read another key

	mov bp, curword

	.2:			; accumulate until whitespace
	call printchar
	mov [bp], al		; write char to curword	
	inc bp
	call readkey
	cmp al, 0x21		; is key whitespace?
	jnb .2			; if no, write another char
	mov byte [bp], 0	; eise, add null-terminator
	ret

;;; in:  si = zname
;;; out: ax = num, zf: success
parsedecimal:
	xor ax, ax
	xor bh, bh
	mov cx, 10

	.loop:
	mul cx			; multiply ax by cx, store in ax
	mov bl, [si]
	inc si
	sub bl, '0'
	jc .nan
	cmp bl, 10
	jnc .nan
	add ax, bx
	cmp byte [si], 0
	jnz .loop
	ret			;success, zf is set
	
	.nan:
	cmp bl, 0		; failure, zf is unset
	ret
	
;;; in:  dx = name, ax = name len
;;; out: bx = entry or 0
dictfind:
	mov bx, dictionary

	.loop:
	cmp al, [bx + 2]	; same length?
	jnz .skip
	mov si, dx
	mov di, bx
	sub di, ax		; point di to begin of name
	mov cx, ax
	repz cmpsb
	jz .done		; word found
	
	.skip:
	mov bx, [bx]		; go to next entry
	cmp bx, 0
	jnz .loop
	
	.done:
	ret
	

;;; in: di = msg addr
;;; 	si = word to compare
;;; out: n/a
cmpwords:
	mov al, [di]
	mov bl, [si]
	inc di
	inc si
	cmp al, 0
	je .endword
	cmp bl, 0
	je .done
	cmp al, bl
	je cmpwords

	.done:
	mov di, curword
	ret

	.endword:
	cmp al, bl
	jne .done
	mov di, match
	call printmsg
	jmp .done

;;; Variables
color:
	db 0xf			; white
pos:
	dw 0
curword:
	times 0x40 db 0
	
;;; Forth Dictionary:
;;; 	Xb name (where X is length of name)
;;; 	2b link to previous word
;;; 	1b name length
;;; 	payload
hellomsg:
	db 'Hello there', 0

	db 'hello'
hello:
	dw 0			; no previous word
	db 5
	mov di, hellomsg
	call printmsg
	ret


goodbyemsg:
	db 'See ya!', 0

	db 'goodbye'
goodbye:
	dw hello
	db 7
	mov di, goodbyemsg
	call printmsg
	ret

archonmsg:
	db 'Power Overwhelming', 0

	db 'archon'
archon:
	dw goodbye
	db 6
	mov di, archonmsg
	call printmsg
	ret
	
	db 'red'
red:
	dw archon
	db 3
	mov byte [color], 0xc
	ret

	db 'green'
green:
	dw red
	db 5
	mov byte [color], 0xa
	ret

	db 'blue'
blue:
	dw green
	db 4
	mov byte [color], 0x9
	ret

	db 'rewind'
rewind:
	dw blue
	db 6
	mov word [pos], 0
	ret

	db 'overload'
dictionary:
	dw rewind
	db 8
	mov bp, red
	add bp, 3
	call bp
	mov bp, archon
	add bp, 3
	call bp
	ret
	


match:
	db 'yay', 0
	
