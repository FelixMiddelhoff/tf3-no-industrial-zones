local CheckIntervalSeconds <const> = 5.0
local IndustrialIndex <const> = 3

local ret : GameScript<{string : number}> = {
	update = function(_userParams : table, state : GameScriptState<{string : number}>, dt : number) : any
		if dt == 0.0 then
			return
		end

		local state2 = state:get() or { elapsed = 0.0 }
		state2.elapsed = (state2.elapsed or 0.0) + dt
		if state2.elapsed < CheckIntervalSeconds then
			state:set(state2)
			return
		end
		state2.elapsed = 0.0
		state:set(state2)

		api.engine.forEachEntityWithComponent(function(entity : Engine.Entity)
			local town = api.engine.getComponent(entity, api.type.ComponentType.TOWN) as Engine.Component.Town
			if town and town.initialLandUseCapacities and (town.initialLandUseCapacities[IndustrialIndex] or 0) > 0 then
				local capacities = { town.initialLandUseCapacities[1], town.initialLandUseCapacities[2], 0 }
				api.cmd.sendCommand(api.cmd.makeTownSetInitialLandUseCapacitiesCmd(entity, capacities))
			end
		end, api.type.ComponentType.TOWN)
	end,
}

return ret
