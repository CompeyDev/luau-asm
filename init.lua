--// Modules
local luau_asm = require("luau_asm")

luau_asm.load_asm([[
	section.text
		global _start
	
	_start:
		MOV ECX, EDX
]])