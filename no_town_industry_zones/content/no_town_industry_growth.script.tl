local CheckIntervalSeconds <const> = 5.0
local BuildCheckIntervalSeconds <const> = 30.0
local IndustrialIndex <const> = 3
local MaxRemovalAttempts <const> = 3

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

		state2.buildElapsed = (state2.buildElapsed or 0.0) + CheckIntervalSeconds
		local checkBuilt = false
		if state2.buildElapsed >= BuildCheckIntervalSeconds then
			state2.buildElapsed = 0.0
			checkBuilt = true
		end

		api.engine.forEachEntityWithComponent(function(entity : Engine.Entity)
			local town = api.engine.getComponent(entity, api.type.ComponentType.TOWN) as Engine.Component.Town
			if not (town and town.initialLandUseCapacities and town.sizeFactors) then
				return
			end

			if (town.initialLandUseCapacities[IndustrialIndex] or 0) > 0 then
				-- step 1: the industrial district of the town is set to zero
				local capacities = { town.initialLandUseCapacities[1], town.initialLandUseCapacities[2], 0 }
				api.cmd.sendCommand(api.cmd.makeTownSetInitialLandUseCapacitiesCmd(entity, capacities))
			elseif checkBuilt then
				-- step 2: industrial buildings still stand, ask the town to update its buildings so they are removed now
				local built = api.engine.system.townBuildingSystem.getLandUsePersonCapacities(entity)
				local builtIndustrial = built and built[IndustrialIndex] or 0
				local key = "r" .. tostring(entity)
				local attempts = state2[key] or 0
				if builtIndustrial > 0 and attempts < MaxRemovalAttempts then
					state2[key] = attempts + 1
					api.cmd.sendCommand(api.cmd.makeTownUpdateSizeCmd(entity, { town.sizeFactors[1], town.sizeFactors[2], town.sizeFactors[IndustrialIndex] }, true))
				end
			end
		end, api.type.ComponentType.TOWN)

		state:set(state2)
	end,
}

return ret
