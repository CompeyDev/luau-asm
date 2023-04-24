local luau_asm = { }

--// Modules
local fmt = require("logger")

-- Implement a trimmer to get rid of whitespace chars
function _G.string.trim(s: string): string
	return string.gsub(s, "%s", "")
end

function luau_asm.load_asm(asm: string)
	call__start(asm)
end

-- Looks for some sort of a global start for the linker
function locate__start(input: string): (boolean, string)
	for _, match in string.gmatch(input, "global%s(_)(%w+)") do
		if match ~= nil then
			return true, match
		else 
			return false, nil
		end
	end
end

-- Trims the asm set from anything which is not an initializer
function trim_for_initializer(s: {[number]: string})
	for i, l in s do
		if i > 2 then
			table.remove(s, i)
		else
			continue
		end
	end
	
	assert(rawlen(s) == 2, "panic: located more than one start")
end


-- Calls the located start for execution with required asm
function call__start(asm: string)
	local possible_initializers = string.split(asm, "\n")
	
	trim_for_initializer(possible_initializers)
	
	for i, possible_initializer in possible_initializers do
		local is_match, matched = locate__start(possible_initializer)
		
		if is_match then
			exec(matched, asm)
		else
			if i == 2 then
				fmt.warn("found no start, panicking!", fmt.Scopes.Runtime)
			end
		end
	end
end


-- Parses and executes the assembly within a virtual memory space
function exec(start: string, asm: string)	
	-- TODO: Add more instructions

	local virt_mem = {
		["ecx"] = {}, 
		["edx"] = {}, 
	}
	
	setmetatable(virt_mem, {
		__newindex = function (_tbl, reg, val)
			fmt.log(
				string.format("registry %s updated with contents of size %x", #val), 
				fmt.Scopes.Runtime
			)
		end,
		
		__call = function (reg, ...)
			local offset = select(1, ...)
			local val = select(2, ...)
			
			reg[offset] = val
		end,
	})
	
	local available_instructions = {
		["INC"] = { 
			["args"] = { "MEM_REG", "REG_OFFSET", "INC_VAL" },
			["impl"] = function(...) 
				local reg = select(1, ...)
				local offset = select(2, ...)
				local val = select(3, ...)
				
				virt_mem[reg](offset, virt_mem[reg][offset] + val)
			end,
		},
		["MOV"] = { 
			["args"] = { "MEM_ORIG_REG", "MEM_FINAL_REG" },
			["impl"] = function(...)
				local orig_reg = select(1, ...)
				local final_reg = select(2, ...)
				
				final_reg = orig_reg
				orig_reg = {}
			end,
		},
		["ADDC"] = { 
			["args"] = { "MEM_VAR_1", "MEM_VAR_2" },
			["impl"] = function(...)
				return select(1, ...) + select(2, ...)
			end,
		}
	}
	
	local function parseNext(instruction: string)
		local instrs: string = string.trim(instruction)
		local splitted_instr = instrs:split(" ")
		local true_instr = splitted_instr[1]
		local args = table.remove(splitted_instr, 1)
		
		local expected_argc = #((available_instructions[true_instr])["args"])
		
		assert(
			#args == expected_argc,
			
			string.format(
				"instruction %s expects %d arguments, but %d arguments were supplied", 
				true_instr, expected_argc, #args
			)
		)
		
		local instr_impl: (...any) -> any = (available_instructions[true_instr])["impl"]
		
		instr_impl(table.unpack(args))
	end
	
	local instructions = string.split(asm, "\n")
	
	table.remove(instructions, 1)
	table.remove(instructions, 2)
	
	for pos, line in instructions do
		if string.match(line, "_" .. start .. ":") then
			break
		end
		
		table.remove(instructions, pos)
	end
	
	for _, instr in instructions do parseNext(instr) end
end

return luau_asm