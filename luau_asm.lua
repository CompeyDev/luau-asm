local luau_asm = { }

--// Modules
local fmt = require("logger")


--// Utils
local function deep_copy(orig)
	local copy = { }
	for k, v in pairs(orig) do
		if type(v) == "table" then
			v = deep_copy(v)
		end

		copy[k] = v
	end
	return copy
end

local string = deep_copy(_G.string)


-- Implement a trimmer to get rid of excess whitespace chars
function string.trim(s: string): string
	return string.gsub(s, "%s+", ";")
end

function string.split(s: string, sep: string)
	if sep == nil then
                sep = "%s"
        end

        local t={ }

        for str in string.gmatch(s, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
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
function trim_for_initializer(t: {[number]: string})
	for i, _ in t do
		if i > 2 then
			table.remove(t, i)
		else
			continue
		end
	end
	
	assert(#t >= 3, "panic: located more than one start")
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
		-- __newindex = function (_tbl, reg, val)
		-- 	fmt.log(
		-- 		string.format("registry %s updated with contents of size %x", reg, #val), 
		-- 		fmt.Scopes.Runtime
		-- 	)
		-- end,
		
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
				local reg = select(1, ...):gsub(",", "")
				local offset = select(2, ...):gsub(",", "")
				local val = select(3, ...):gsub(",", "")
				
				virt_mem[reg](offset, virt_mem[reg][offset] + val)
			end,
		},
		["MOV"] = { 
			["args"] = { "MEM_ORIG_REG_OR_VAR", "MEM_FINAL_REG" },
			["impl"] = function(...)
				local orig_val_or_reg = select(2, ...):gsub(",", "")
				local final_reg = select(1, ...):gsub(",", "")
				local orig_val = tonumber(orig_val_or_reg)
				
				virt_mem[final_reg] = virt_mem[orig_val_or_reg] or orig_val or orig_val_or_reg
			end,
		},
		["ADDC"] = { 
			["args"] = { "MEM_VAR_OR_REG_1", "MEM_VAR_OR_REG_2" },
			["impl"] = function(...)
				return select(1, ...):gsub(",", "") + select(2, ...):gsub(",", "")
			end,
		}
	}
	
	local function parse_next(instruction: string): ((...any) -> any, {[number]: string})
		local instrs: string = string.trim(instruction)
		local splitted_instr = string.split(instrs, ";")

		local true_instr = splitted_instr[1]

		table.remove(splitted_instr, 1)

		local args = splitted_instr
	
		local expected_argc = #available_instructions[true_instr]["args"]
		
		assert(
			#args == expected_argc,
			
			string.format(
				"instruction %s expects %d arguments, but %d arguments were supplied", 
				true_instr, expected_argc, #args
			)
		)
		
		local instr_impl: (...any) -> any = (available_instructions[true_instr])["impl"]
		
		return instr_impl, args
	end
	
	local instructions = string.split(asm, "\n")
	
	table.remove(instructions, 1)
	table.remove(instructions, 1)

	for pos, line in instructions do	
		table.remove(instructions, pos)

		if string.gmatch(line, "_" .. start .. ":") then
			table.remove(instructions, pos)
			break
		end
	end
	
	for _, instr in instructions do 
		local instr_impl, args = parse_next(instr)

		instr_impl(table.unpack(args))
	end
end

return luau_asm
