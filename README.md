```
 __                                                      
|  |  __ _______   __ __          _____    ______ _____  
|  | |  |  \__  \ |  |  \  ______ \__  \  /  ___//     \ 
|  |_|  |  // __ \|  |  / /_____/  / __ \_\___ \|  Y Y  \
|____/____/(____  /____/          (____  /____  >__|_|  /
                \/                     \/     \/      \/ 
```

A tiny (~200 lines) assembly instruction set written in pure luau. Pretty much a small project I put together in a couple hours. 

## [Example Usage](init.lua)

```lua
luau_asm.load_asm([[
	section.text
		global _start
	
	_start:
		MOV ECX, EDX
]])
```

##### ✨ Psst... I first had this idea while looking at [LuaSyntaxTree](https://github.com/4x8Matrix/LuaSyntaxTree) by [@4x8matrix](https://github.com/4x8Matrix), go check it out!
