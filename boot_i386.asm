;;; Boot sector for i386 systems.
;;; Loads the boot payload, where the rest of the environment will run,
;;; and then jumps to it
	BITS 16
	org 0x7c00

	PAYLOAD_DEST equ 0x500
	
_start:	

	;; init segment registers
	mov ax, 0
	mov ds, ax
	mov es, ax
	mov ss, ax
	
	mov sp, 0		; init stack
	mov ah, 0x02 		; BIOS INT 0x13 function: Read disk sectors
	mov al, 2		; number of sectors to load
	mov ch, 0		; cylinder
	mov cl, 2		; sector
	mov dh, 0		; head
	mov bx, PAYLOAD_DEST	; destination address for payload
	int 0x13		; execute

	mov ah, 0x04		; BIOS INT 0x13 function: Verify sectors
	int 0x13		; execute

	mov ah, 0x00		; BIOS 0x10 function: Set video mode
	mov al, 0x03		; 80x25 pixels
	int 0x10

	jnc payload		; check carry flag (set on error)

	;; TODO: Display sector error code (AH contains status)
	mov ah, 0x13
	mov al, 0
	mov bh, 0
	mov bl, 0xf
	mov cx, 19
	mov dh, 0
	mov dl, 0
	mov bp, error_msg
	int 0x10

error_loop:
	jmp error_loop
	
payload:
	jmp 0:PAYLOAD_DEST	; (far) jump to payload

error_msg:
	db 'Error: Failed to read sector(s)'
	
	times 510 - ($ - $$) db 0
	db 0x55, 0xaa
