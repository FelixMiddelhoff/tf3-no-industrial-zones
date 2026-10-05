local CheckIntervalSeconds <const> = 5.0
local IndustrialIndex <const> = 3
local MinIndustrialCapacity <const> = 10

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

		api.engine.forEachEntityWithComponent(function(entity : Engine.Entity)
			local town = api.engine.getComponent(entity, api.type.ComponentType.TOWN) as Engine.Component.Town
			if town and town.initialLandUseCapacities and (town.initialLandUseCapacities[IndustrialIndex] or 0) <= 0 then
				local key = "t" .. tostring(entity)
				local attempts = state2[key] or 0
				state2[key] = attempts + 1
				if attempts == 0 then
					-- let the game recalculate the capacities itself
					api.cmd.sendCommand(api.cmd.makeTownSetInitialLandUseCapacitiesCmd(entity))
				else
					-- fallback: the game did not restore an industrial capacity, set a modest one
					local residential = town.initialLandUseCapacities[1] or 0
					local commercial = town.initialLandUseCapacities[2] or 0
					local industrial = math.floor((residential + commercial) * 0.25 + 0.5)
					if industrial < MinIndustrialCapacity then
						industrial = MinIndustrialCapacity
					end
					api.cmd.sendCommand(api.cmd.makeTownSetInitialLandUseCapacitiesCmd(entity, { residential, commercial, industrial }))
				end
			end
		end, api.type.ComponentType.TOWN)

		state:set(state2)
	end,
}

return ret
