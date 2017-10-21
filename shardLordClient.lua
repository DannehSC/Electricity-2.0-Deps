local json=require('json')
local print=_G.print
local client={
	events={
		guildCount={},
		raw={},
	}
}
local function splitter(str, delim)
	local ret = {}
	if not str then
		return ret
	end
	if not delim or delim == '' then
		for c in string.gmatch(str, '.') do
			table.insert(ret, c)
		end
		return ret
	end
	local n = 1
	while true do
		local i, j = string.find(str, delim, n)
		if not i then break end
		table.insert(ret, string.sub(str, n, i - 1))
		n = j + 1
	end
	table.insert(ret, string.sub(str, n))
	return ret
end
function client:send(data)
	assert(type(data)=='string','Bad argument #1 to client:send, string expected, got '..type(data))
	process.stdout:write(data)
end
function client:on(event,callback)
	assert(type(callback)=='function','Bad argument #1 to client:on, function expected, got '..type(callback))
	assert(client.events[event]~=nil,'Invalid event type')
	table.insert(client.events[event],callback)
end
function client:fire(event,...)
	assert(client.events[event]~=nil,'Invalid event type')
	for i,v in pairs(client.events[event])do
		v(...)
	end
end
return function(discordia,options)
	local farg,larg=1
	for i,v in pairs(args)do	
		local found,shard=v:match('(shard|)(%d?%d?%d)')
		if found then
			farg,larg=shard,shard
			break
		else
			local f2=v:match('(Mshard|)')
			if f2 then
				local rest=v:sub(#'Mshard|'+1)
				local decoded=json.decode(rest)
				farg=decoded[1]
				larg=decoded[#decoded]
				break
			end
		end
	end
	local tab={
		firstShard=tonumber(farg),
		lastShard=tonumber(larg),
	}
	options=options or{}
	for i,v in pairs(options)do
		if not tab[i]then
			tab[i]=v
		end
	end
	local d_client=discordia.Client(tab)
	client.discordia=d_client
	process.stdin:on('data',function(data)
		local spl=splitter(data,'||')
		if spl[1]=='REQUEST'then
			if spl[2]=='GUILD_COUNT'then
				if client.discordia then
					client:send('RESPONSE||GUILD_COUNT||'..tostring(#client.discordia.guilds))
				end
			end
		elseif spl[1]=='RESPONSE'then
			if spl[2]=='GUILD_COUNT'then
				client:fire('guildCount',spl[3])
			end
		else
			client:fire('raw',data)
		end
	end)
	return d_client,client
end