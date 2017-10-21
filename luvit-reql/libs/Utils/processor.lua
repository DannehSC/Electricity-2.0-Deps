local json=require('json')
local intlib=require('./intlib.lua')
local errors=require('../error.lua')
local logger=require('./logger.lua')
local emitter=require('./emitty.lua')
local protodef=require('./protodef.lua')
local cmanager=require('./coroutinemanager.lua')
local responses=protodef.Response
local errcodes={
	[16]={t='CLIENT_ERROR',f=errors.ReqlDriverError},
	[17]={t='COMPILE_ERROR',f=errors.ReqlCompileError},
	[18]={t='RUNTIME_ERROR',f=errors.ReqlRuntimeError}
}
local processor={
	cbs={},
}
local buffers={}
local function newBuffer(tx)
	local buffer={data=tx}
	function buffer:add(tx)
		buffer.data=buffer.data..tx
	end
	return buffer
end
local int=intlib.byte_to_int
function processor.processData(data)
	local token=int(data:sub(1,8))
	local length=int(data:sub(9,12))
	local resp=data:sub(13)
	local t,respn=data:sub(13):match('([t])":(%d?%d)')
	respn=tonumber(respn)
	if respn==1 then
		rest=data:sub(13)
		processor.cbs[token](json.decode(rest).r)
		processor.cbs[token]=nil
	elseif respn==2 then
		if not buffers[token]then
			buffers[token]=newBuffer('')
		end
		local buffer=buffers[token]
		buffer:add(data:sub(13))
		processor.cbs[token](json.decode(buffer.data).r)
		processor.cbs[token]=nil
		buffers[token]=nil
	elseif respn==3 then
		if not buffers[token]then
			buffers[token]=newBuffer(data:sub(13))
			return
		end
		buffers[token]:add(data:sub(13))
	elseif errcodes[respn]then
		local ec=errcodes[respn]
		local err=ec.f(ec.t)
		logger.warn.format('Error encountered. Error code: '..respn..' | Error info: '..tostring(err))
		processor.cbs[token](nil,err,json.decode(data:sub(13)))
	else
		logger.warn.format(string.format('Unknown response: %s',respn))
	end
end
return processor