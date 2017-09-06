
struct AreaEntry
	definition dd ? 		; pointer to ValueDefinition
	next dd ?			; pointer to another AreaEntry
ends

struct AreaHeader
	flags dd ?			; AREA_#
	base_address_length dd ?
	uninitialized_data_length dd ?
ends

AREA_VIRTUAL = 1
AREA_VARIABLE = 2
AREA_SHIFT_TRACKING_DISABLED = 4

create_output_area:
; in:
;  esi - base address in format of VALTYPE_NUMERIC value
;  ecx = length of base address value
; out:
;  ebx - AreaHeader
;  edx - ValueDefinition
	mov	eax,[current_output_area_entry]
	test	eax,eax
	jnz	get_next_output_area_entry
	mov	eax,[first_output_area_entry]
	test	eax,eax
	jnz	new_output_entry_ready
	push	ecx
	mov	ecx,sizeof.AreaEntry
	call	create_tree_element
	pop	ecx
	mov	[first_output_area_entry],eax
	jmp	new_output_entry_ready
    get_next_output_area_entry:
	mov	edi,eax
	mov	eax,[eax+AreaEntry.next]
	test	eax,eax
	jnz	new_output_entry_ready
	push	ecx
	mov	ecx,sizeof.AreaEntry
	call	create_tree_element
	pop	ecx
	mov	[edi+AreaEntry.next],eax
    new_output_entry_ready:
	mov	ebx,eax
	xchg	eax,[current_output_area_entry]
	test	eax,eax
	jz	prepare_output_area
	mov	eax,[eax+AreaEntry.definition]
    prepare_output_area:
	push	eax
	call	create_area
	pop	[edx+ValueDefinition.previous]
	retn

create_area:
; in:
;  ebx - AreaEntry
;  esi - base address in format of VALTYPE_NUMERIC value
;  ecx = length of base address value
; out:
;  ebx - AreaHeader
;  edx - ValueDefinition
	mov	[address_length],ecx
	mov	edx,[ebx+AreaEntry.definition]
	test	edx,edx
	jz	current_area_definition_unusable
	cmp	[edx+ValueDefinition.reference_count],1
	je	area_definition_ready
	dec	[edx+ValueDefinition.reference_count]
    current_area_definition_unusable:
	mov	ecx,retired_definition
      retrieve_retired_detached_value:
	mov	edx,[ecx]
	test	edx,edx
	jz	create_area_definition
	cmp	[edx+ValueDefinition.reference_count],0
	jne	retired_detached_value_immutable
	xor	eax,eax
	xchg	eax,[edx+ValueDefinition.previous]
	mov	[ecx],eax
	jmp	adopt_area_definition
      retired_detached_value_immutable:
	lea	ecx,[edx+ValueDefinition.previous]
	jmp	retrieve_retired_detached_value
    create_area_definition:
	mov	ecx,sizeof.ValueDefinition
	call	create_tree_element
	jc	out_of_memory
	mov	ecx,eax
	xchg	ecx,[value_definition_chain]
	mov	[eax+ValueDefinition.interlink],ecx
	mov	edx,eax
    adopt_area_definition:
	mov	[ebx+AreaEntry.definition],edx
	or	[edx+ValueDefinition.flags],VAL_DETACHED
	inc	[edx+ValueDefinition.reference_count]
    area_definition_ready:
	mov	ecx,[address_length]
	add	ecx,sizeof.AreaHeader
	mov	eax,[edx+ValueDefinition.block_length]
	test	eax,eax
	jz	allocate_area_block
	cmp	ecx,eax
	jbe	initialize_area_block
	push	ecx edx
	xor	eax,eax
	xchg	eax,[edx+ValueDefinition.value]
	call	mfree
	pop	edx ecx
    allocate_area_block:
	push	edx
	call	malloc_growable
	pop	edx
	jc	out_of_memory
	mov	[edx+ValueDefinition.value],eax
	mov	[edx+ValueDefinition.block_length],ecx
    initialize_area_block:
	mov	ebx,[edx+ValueDefinition.value]
	lea	edi,[ebx+sizeof.AreaHeader]
	mov	ecx,[address_length]
	mov	[ebx+AreaHeader.base_address_length],ecx
	rep	movsb
	mov	[ebx+AreaHeader.uninitialized_data_length],ecx
	mov	[ebx+AreaHeader.flags],ecx
	sub	edi,ebx
	mov	[edx+ValueDefinition.value_length],edi
	mov	[edx+ValueDefinition.type],VALTYPE_AREA
	mov	ecx,[current_pass]
	mov	[edx+ValueDefinition.pass],ecx
	retn

initialize_output:
; in: ecx = number of bytes that should be added to output
; out: edi - output buffer to be filled with data
; preserves: esi
	mov	edx,[current_area]
	mov	ebx,[edx+ValueDefinition.value]
	add	ecx,[ebx+AreaHeader.uninitialized_data_length]
	jc	out_of_memory
	mov	eax,[edx+ValueDefinition.value_length]
	lea	edi,[ebx+eax]
	add	ecx,eax
	jc	out_of_memory
	mov	[edx+ValueDefinition.value_length],ecx
	cmp	ecx,[edx+ValueDefinition.block_length]
	jbe	area_reserve_sufficient
	mov	eax,[edx+ValueDefinition.value]
	sub	edi,eax
	push	edx
	bsr	edx,ecx
	xchg	ecx,edx
	dec	cl
	shr	edx,cl
	inc	edx
	shl	edx,cl
	mov	ecx,edx
	call	realloc
	pop	edx
	jc	out_of_memory
	mov	ebx,eax
	add	edi,eax
	mov	[edx+ValueDefinition.value],ebx
	mov	[edx+ValueDefinition.block_length],ecx
    area_reserve_sufficient:
	mov	ecx,[ebx+AreaHeader.uninitialized_data_length]
	jecxz	output_buffer_ready
	xor	eax,eax
	mov	dl,cl
	shr	ecx,2
	rep	stosd
	mov	cl,dl
	and	cl,11b
	rep	stosb
	mov	[ebx+AreaHeader.uninitialized_data_length],eax
    output_buffer_ready:
	retn

uninitialized_output:
; in: ecx = number of uninitialized bytes to be added to output
; preserves: ebx, ecx, esi, edi
	mov	edx,[current_area]
	mov	eax,[edx+ValueDefinition.value]
	add	[eax+AreaHeader.uninitialized_data_length],ecx
	jc	area_overflow
	mov	edx,[edx+ValueDefinition.value_length]
	sub	edx,sizeof.AreaHeader
	sub	edx,[eax+AreaHeader.base_address_length]
	add	edx,[eax+AreaHeader.uninitialized_data_length]
	jc	area_overflow
	retn
    area_overflow:
	mov	edx,_area_overflow
	call	register_error
	mov	edx,[current_area]
	or	ecx,-1
	mov	eax,[edx+ValueDefinition.value]
	sub	ecx,[edx+ValueDefinition.value_length]
	add	ecx,sizeof.AreaHeader
	add	ecx,[eax+AreaHeader.base_address_length]
	mov	[eax+AreaHeader.uninitialized_data_length],ecx
	retn

get_current_address_value:
; out:
;  esi - address in format of VALTYPE_NUMERIC value
;  ecx = length of address value
; note: the returned value is placed in assembly workspace
	mov	eax,[current_area]
	mov	esi,[eax+ValueDefinition.value]
	mov	ebx,[eax+ValueDefinition.value_length]
	mov	edx,assembly_workspace
	mov	edi,[edx+Workspace.memory_start]
	mov	ecx,[esi+AreaHeader.base_address_length]
	add	ecx,4
	call	reserve_workspace
	mov	ecx,[esi+AreaHeader.base_address_length]
	sub	ebx,ecx
	sub	ebx,sizeof.AreaHeader
	add	ebx,[esi+AreaHeader.uninitialized_data_length]
       ; jc	 internal_error
	add	esi,sizeof.AreaHeader
	xor	eax,eax
	stosd
	lodsd
	mov	ecx,eax
	xor	edx,edx
	jecxz	offset_added_to_base_address
    add_offset_to_base_address:
	lodsb
	add	al,bl
	setc	dl
	stosb
	shr	ebx,8
	add	ebx,edx
	loop	add_offset_to_base_address
    offset_added_to_base_address:
	mov	edx,[assembly_workspace.memory_start]
	add	edx,4
	mov	eax,ebx
	cmp	byte [esi-1],80h
	cmc
	sbb	eax,0
	stosd
    optimize_base_address:
	movsx	eax,byte [edi-2]
	cmp	ah,[edi-1]
	jne	base_address_ready
	dec	edi
	cmp	edi,edx
	jne	optimize_base_address
    base_address_ready:
	mov	ecx,edi
	sub	ecx,edx
	mov	[edx-4],ecx
	mov	ecx,esi
    measure_variable_terms:
	lodsd
	test	eax,eax
	jz	variable_terms_measured
	lodsd
	add	esi,eax
	jmp	measure_variable_terms
    variable_terms_measured:
	xchg	ecx,esi
	sub	ecx,esi
	mov	al,cl
	shr	ecx,2
	rep	movsd
	mov	cl,al
	and	cl,11b
	rep	movsb
	mov	esi,[assembly_workspace.memory_start]
	mov	ecx,edi
	sub	ecx,esi
	retn

get_output_length:
; out:
;  edx:eax = length of current output
;  [uninitialized_data_length] = length of uninitialized data following the current output
; preserves: esi
	mov	ebx,[first_output_area_entry]
	xor	eax,eax
	mov	edx,eax
	mov	dword [uninitialized_data_length],eax
	mov	dword [uninitialized_data_length+4],eax
    measure_area_length:
	mov	edi,[ebx+AreaEntry.definition]
	mov	ecx,[edi+ValueDefinition.value_length]
	mov	edi,[edi+ValueDefinition.value]
	sub	ecx,sizeof.AreaHeader
	sub	ecx,[edi+AreaHeader.base_address_length]
	add	eax,ecx
	test	ecx,ecx
	jz	measure_next_area
	add	eax,dword [uninitialized_data_length]
	adc	edx,dword [uninitialized_data_length+4]
	and	dword [uninitialized_data_length],0
	and	dword [uninitialized_data_length+4],0
    measure_next_area:
	mov	ecx,[edi+AreaHeader.uninitialized_data_length]
	add	dword [uninitialized_data_length],ecx
	adc	dword [uninitialized_data_length+4],0
	cmp	ebx,[current_output_area_entry]
	je	output_measured
	mov	ebx,[ebx+AreaEntry.next]
	jmp	measure_area_length
    output_measured:
	retn

write_output_file:
; in: edi - output path
; out:
;  cf set when write failed
	mov	edx,edi
	call	create
	jc	output_write_failed
	xor	eax,eax
	mov	dword [uninitialized_data_length],eax
	mov	dword [uninitialized_data_length+4],eax
	mov	esi,[first_output_area_entry]
    write_area:
	mov	edx,[esi+AreaEntry.definition]
	mov	eax,[edx+ValueDefinition.value]
	mov	ecx,[edx+ValueDefinition.value_length]
	sub	ecx,[eax+AreaHeader.base_address_length]
	sub	ecx,sizeof.AreaHeader
	jz	write_next_area
	mov	eax,dword [uninitialized_data_length]
	or	eax,dword [uninitialized_data_length+4]
	jz	write_initialized_data
    write_uninitialized_data:
	mov	edi,[assembly_workspace.memory_start]
	mov	ecx,1000h shr 2
	xor	eax,eax
	rep	stosd
	mov	ecx,1000h
	cmp	dword [uninitialized_data_length+4],0
	jne	portion_length_ok
	cmp	ecx,dword [uninitialized_data_length]
	jbe	portion_length_ok
	mov	ecx,dword [uninitialized_data_length]
    portion_length_ok:
	sub	dword [uninitialized_data_length],ecx
	sbb	dword [uninitialized_data_length+4],0
	mov	edx,[assembly_workspace.memory_start]
	call	write
	jc	file_write_failed
	mov	eax,dword [uninitialized_data_length]
	or	eax,dword [uninitialized_data_length+4]
	jnz	write_uninitialized_data
    write_initialized_data:
	mov	edx,[esi+AreaEntry.definition]
	mov	eax,[edx+ValueDefinition.value]
	mov	ecx,[edx+ValueDefinition.value_length]
	mov	edx,[eax+AreaHeader.base_address_length]
	add	edx,sizeof.AreaHeader
	sub	ecx,edx
	add	edx,eax
	call	write
	jc	file_write_failed
    write_next_area:
	mov	edx,[esi+AreaEntry.definition]
	mov	eax,[edx+ValueDefinition.value]
	mov	eax,[eax+AreaHeader.uninitialized_data_length]
	add	dword [uninitialized_data_length],eax
	adc	dword [uninitialized_data_length+4],0
	cmp	esi,[current_output_area_entry]
	je	close_output_file
	mov	esi,[esi+AreaEntry.next]
	jmp	write_area
    close_output_file:
	call	close
	retn
    file_write_failed:
	call	close
    output_write_failed:
	stc
	retn
