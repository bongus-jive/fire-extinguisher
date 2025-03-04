require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

ExtinguisherWeapon = {}
setmetatable(ExtinguisherWeapon, extend(Weapon))

function init()
  setmetatable(self, extend(config.getParameter("scriptConfig")))
  
  activeItem.setCursor(self.cursor)

  self.weapon = ExtinguisherWeapon:new()

  local baseOffset = config.getParameter("baseOffset")
  self.tankGroup = self.weapon:addTransformationGroup("tank", baseOffset, 0, self.tankRotationCenter)
  self.weapon:addTransformationGroup("hose", baseOffset, 0)
  
  local function addAbility(slot, cfg)
    if not cfg then return end
    local ability = getAbility(slot, cfg)
    ability.stances = ability.stances or {}
    setmetatable(ability.stances, extend(self.stances))
    self.weapon:addAbility(ability)
  end

  addAbility("primary", config.getParameter("primaryAbility"))
  addAbility("alt", config.getParameter("altAbility"))

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
  self.weapon:setStance(self.stances.idle)

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  -- world.debugPoint(vec2.add(mcontroller.position(), activeItem.handPosition(self.tankRotationCenter)), "#F00")

  local angle = -(self.weapon.aimAngle + self.weapon.relativeArmRotation + self.weapon.relativeWeaponRotation)
  self.tankGroup.rotation = self.tankGroup.rotation + ((angle - self.tankGroup.rotation) * self.tankRotationSpeed) * dt
  self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
  self.weapon:uninit()
end

function ExtinguisherWeapon:addTransformationGroup(name, offset, rotation, rotationCenter)
  local group = {name = name, offset = offset, rotation = rotation, rotationCenter = rotationCenter}
  self.transformationGroups[name] = group
  return group
end

function ExtinguisherWeapon:lerpStance(ratio, stanceFrom, stanceTo)
  self.weaponOffset = vec2.lerp(ratio, stanceFrom.weaponOffset or {0, 0}, stanceTo.weaponOffset or {0, 0})
  self.relativeArmRotation = util.toRadians(util.lerp(ratio, stanceFrom.armRotation, stanceTo.armRotation))
  self.relativeWeaponRotation = util.toRadians(util.lerp(ratio, stanceFrom.weaponRotation, stanceTo.weaponRotation))
end

WeaponAbility.init = WeaponAbility.init or function() end
WeaponAbility.uninit = WeaponAbility.uninit or function() end
