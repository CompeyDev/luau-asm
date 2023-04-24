local fmt = {
	Scopes = {
		Debug = "DEBUG",
		Runtime = "RUNTIME"
	}
}


function fmt.log(msg: string, scope, dur: number?): nil
	if dur ~= nil then
		print(string.format("[%s] :: %s -> (%d)", msg, scope, dur))
	else
		print(string.format("[%s] :: %s", msg, dur))
	end
end


function fmt.warn(msg: string, scope, dur: number?)
	if dur ~= nil then
		warn(string.format("[%s] :: %s -> (%d)", msg, scope, dur))
	else
		warn(string.format("[%s] :: %s", msg, dur))
	end
end

return fmt