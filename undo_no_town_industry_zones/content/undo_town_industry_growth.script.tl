-- Undo: Towns Without Industrial Zones, revision 2
local CheckIntervalSeconds <const> = 5.0
local BuildCheckIntervalSeconds <const> = 60.0
local IndustrialIndex <const> = 3
local MinIndustrialCapacity <const> = 10
local RestoredIndustrialSize <const> = 1.0
local MaxRebuildAttempts <const> = 3

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

			local capacity = town.initialLandUseCapacities[IndustrialIndex] or 0
			local size = town.sizeFactors[IndustrialIndex] or 0

			if capacity <= 0 then
				-- step 1: restore the industrial capacity
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
			elseif size <= 0 then
				-- step 2: the industrial district is still scaled to zero, scale it back up
				api.cmd.sendCommand(api.cmd.makeTownUpdateSizeCmd(entity, { town.sizeFactors[1], town.sizeFactors[2], RestoredIndustrialSize }, true))
			elseif checkBuilt then
				-- step 3: capacity and size are fine but nothing is built, ask the town to update its buildings
				local built = api.engine.system.townBuildingSystem.getLandUsePersonCapacities(entity)
				local builtIndustrial = built and built[IndustrialIndex] or 0
				local rebuildKey = "r" .. tostring(entity)
				local rebuilds = state2[rebuildKey] or 0
				if builtIndustrial <= 0 and rebuilds < MaxRebuildAttempts then
					state2[rebuildKey] = rebuilds + 1
					api.cmd.sendCommand(api.cmd.makeTownUpdateSizeCmd(entity, { town.sizeFactors[1], town.sizeFactors[2], size }, true))
				end
			end
		end, api.type.ComponentType.TOWN)

		state:set(state2)
	end,
}

return ret
