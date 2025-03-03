local function round(num, idp)
  local mult = 10 ^ (idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function build(directory, config, parameters, level, seed)
  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end

  local lvl = configParameter("level", 1)
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", lvl)
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", lvl)

  if not config.tooltipFields then config.tooltipFields = {} end
  local fields = config.tooltipFields

  local primary = config.primaryAbility or {}
  local baseDps = primary.baseDps or 0
  local fireTime = primary.fireTime or 1

  fields.levelLabel = round(lvl, 1)
  fields.damagePerShotLabel = round(baseDps * fireTime * config.damageLevelMultiplier, 1)
  fields.dpsLabel = round(baseDps * config.damageLevelMultiplier, 1)
  fields.speedLabel = round(1 / fireTime, 1)
  fields.energyPerShotLabel = round(primary.energyUsage or 0, 1)
  
  if config.primaryAbility then
    fields.primaryAbilityTitleLabel = "Primary:"
    fields.primaryAbilityLabel = config.primaryAbility.name or "unknown"
  end
  
  if config.altAbility then
    fields.altAbilityTitleLabel = "Special:"
    fields.altAbilityLabel = config.altAbility.name or "unknown"
  end

  return config, parameters
end
