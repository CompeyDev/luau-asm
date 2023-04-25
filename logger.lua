local fmt = {
	Scopes = {
		Debug = "DEBUG",
		Runtime = "RUNTIME"
	}
}


function fmt.log(msg: string, scope, dur: number?)
	if dur then
		print(string.format("[%s] :: %s -> (%d)", scope, msg, dur))
	else
		print(string.format("[%s] :: %s", scope, msg))
	end
end


function fmt.warn(msg: string, scope, dur: number?)
	if dur then
		warn(string.format("[%s] :: %s -> (%d)", scope, msg, dur))
	else
		warn(string.format("[%s] :: %s", scope, msg))
	end
end

return fmt
