require "/scripts/util.lua"
require "/scripts/vec2.lua"

ExtinguisherSpray = {}
setmetatable(ExtinguisherSpray, extend(WeaponAbility))

function ExtinguisherSpray:init()
  self.weapon:setStance(self.stances.idle)
end

function ExtinguisherSpray:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if not self.weapon.currentAbility and fireMode == self.abilitySlot and not status.resourceLocked("energy") then
    self:setState(self.firing)
  end
end

function ExtinguisherSpray:firing()
  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)

  local cooldown = 0
  local stanceProgress = 0

  while self.fireMode == self.abilitySlot and status.overConsumeResource("energy", self.energyUsage * self.dt) do
    if stanceProgress < 1 then
      stanceProgress = math.min(1, stanceProgress + self.dt / self.stances.fire.duration)
      self:lerpStance(stanceProgress, self.stances.idle, self.stances.fire)
    end

    if cooldown > 0 then
      cooldown = cooldown - self.dt
    else
      cooldown = self.fireTime or 0
      self:fireProjectile()
    end

    coroutine.yield()
  end

  animator.stopAllSounds("fireLoop")
  animator.playSound("fireEnd")

  while stanceProgress > 0 do
    stanceProgress = math.max(0, stanceProgress - self.dt / self.stances.fire.duration)
    self:lerpStance(stanceProgress, self.stances.idle, self.stances.fire)
    coroutine.yield()
  end
end

function ExtinguisherSpray:fireProjectile()
  local params = sb.jsonMerge(self.projectileParameters, {})
  params.power = self:damagePerShot()
  params.powerMultiplier = self:damageMultiplier()
  params.referenceVelocity = mcontroller.velocity()
  params.speed = util.randomInRange(params.speed)

  world.spawnProjectile(self.projectileType, self:firePosition(), activeItem.ownerEntityId(), self:aimVector(), false, params)
end

function ExtinguisherSpray:firePosition()
  local offset = vec2.rotate(offset or self.weapon.muzzleOffset, self.weapon.relativeWeaponRotation)
  local mpos = mcontroller.position()
  local pos = vec2.add(mpos, activeItem.handPosition(offset))
  local collision = world.lineCollision(mpos, pos)
	return collision or pos
end

function ExtinguisherSpray:aimVector()
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(self.inaccuracy or 0, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function ExtinguisherSpray:damagePerShot()
  return self.baseDps * math.max(self.dt, self.fireTime)
end

function ExtinguisherSpray:damageMultiplier()
  return activeItem.ownerPowerMultiplier() * self.weapon.damageLevelMultiplier
end

function ExtinguisherSpray:lerpStance(ratio, stanceFrom, stanceTo)
  self.weapon.weaponOffset = vec2.lerp(ratio, stanceFrom.weaponOffset or {0, 0}, stanceTo.weaponOffset or {0, 0})
  self.weapon.relativeArmRotation = util.toRadians(util.lerp(ratio, stanceFrom.armRotation, stanceTo.armRotation))
  self.weapon.relativeWeaponRotation = util.toRadians(util.lerp(ratio, stanceFrom.weaponRotation, stanceTo.weaponRotation))
end
