
include '../../examples/x86/include/80386.inc'

iterate instr, push,pop
	macro instr? op
		local sequence
		sequence equ op --
		while 1
			match --, sequence
				break
			else match car= cdr, sequence
				redefine sequence cdr
				match :sz, x86.car
					match --, sequence
						instr car
						break
					else match head= tail, sequence
						redefine sequence tail
						instr car head
					end match
				else
					instr car
				end match
			end match
		end while
	end macro
end iterate

macro format? clause
	match =ELF?, clause
		include '../../examples/x86/include/format/elf32.inc'
		use32
	else
		err 'invalid argument'
	end match
end macro

macro struct? name
	macro ends?!
			end namespace
		end struc
		virtual at 0
			name name
			sizeof.name = $
		end virtual
		purge ends?
	end macro
	struc name
		label . : sizeof.name
		namespace .
end macro

macro ccall? proc*,args&
	local size
	size = 0
	match any, args
		iterate arg, args
			indx 1+%%-%
			pushd arg
			size = size + 4
		end iterate
	end match
	call proc
	if size
		add esp,size
	end if
end macro
