local discordia=require('discordia')
local enums=discordia.enums()
local commander={
	_settings={
		prefix='/',
		ranking={
			rankCount=0,
			ranksEnabled=false,
			getRank=function(isGuild,author,guild)
				if author.id==commander._client.owner.id then
					return commander._settings.ranking.rankCount
				end
				return 0
			end--placeholder
		}
	},
	_guildSettings={},
	_commands={}
}
function commander:setPrefix(prefix)
	self._settings.prefix=prefix
end
function commander:setGuildPrefix(guild,prefix)
	if self._guildSettings[guild.id]==nil then
		self:setupGuild(guild)
	end
	self._guildSettings[guild.id].prefix=prefix
end
function commander:setRankNumber(count)
	assert(type(count)=='number','bad argument #1 to commander:setRankNumber, expected number')
	self._settings.ranking.rankCount=count
end
function commander:setRanksEnabled(bool)
	assert(type(bool)=='boolean','bad argument #1 to commander:setRanksEnabled, expected boolean')
	self._settings.ranking.ranksEnabled=bool
end
function commander:setRankFunction(func)
	assert(type(func)=='function','bad argument #1 to commander:setRankFunction, expected function')
	self._settings.ranking.getRank=func
end
function commander:new(name,desc,rank,cmds,func)
	self._commands[name]={
		name=name,
		desc=desc,
		rank=rank,
		cmds=(type(cmds)=='table'and cmds or{cmds}),
		func=func,
	}
end
function commander:get(name)
	return self._commands[name]
end
function commander:getAll()
	return self._commands
end
function commander:process(message)
	local isGuild
	if message.channelType=enums.channelType.private then
		isGuild=false
	elseif message.channelType=enums.channelType.text then
		isGuild=true
	end
	if self._settings.ranking.ranksEnabled then
		local rank=self._settings.ranking.getRank(isGuild,message.author,(isGuild and message.guild))
	end
end
return function(client)
	commander._client=client
	return commander
end