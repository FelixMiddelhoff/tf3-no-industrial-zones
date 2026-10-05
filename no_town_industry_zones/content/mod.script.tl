
local mod = {}

mod.preRunFn = function(captureParams, _configDict : {{string, string}}, _allModParams : {string : {string : integer}}, baseConfig : BaseConfig)
	baseConfig.economy.industryDevelopment.spawnIndustries = false
end

return mod
