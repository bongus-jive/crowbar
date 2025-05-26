require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

CrowbarSwing = WeaponAbility:new()

function CrowbarSwing:init()
  self.weapon:setStance(self.stances.idle)
end

function CrowbarSwing:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if fireMode == "primary" and not self.weapon.currentState then
    self:setState(self.swing)
  end
end

require "/scripts/poly.lua"

function CrowbarSwing:swing()
  self.weapon:setStance(self.stances.swing)

  local damagePoly = {}
  local _, timestep = status.inflictedHitsSince()

  local progress = 0
  while progress < 1 do
    self:stanceLerp(progress, self.stances.idle, self.stances.swing)
    self.weapon:updateAim()

    local damageLine = animator.partPoly("crowbar", "damageLine")
    table.insert(damagePoly, activeItem.handPosition(damageLine[1]))
    table.insert(damagePoly, 1, activeItem.handPosition(damageLine[2]))
    self.weapon:setOwnerDamage(self.damageConfig, damagePoly)

    local notifs
    notifs, timestep = status.inflictedHitsSince(timestep)
    for _, notif in ipairs(notifs) do
      if notif.damageSourceKind == self.damageConfig.damageSourceKind then
        goto endSwing
      end
    end

    local point = animator.partPoint("crowbar", "collisionPoint")
    point = activeItem.handPosition(point)
    point = vec2.add(mcontroller.position(), point)
    world.debugPoint(point, "red")
    if world.pointTileCollision(point) then
      self:hitTile(point)
      goto endSwing
    end

    progress = math.min(1, progress + (self.dt / self.swingTime))
    coroutine.yield()
  end
  ::endSwing::

  local raiseTime = self.raiseTime
  if progress < 1 then
    local timeLeft = self.swingTime - (progress * self.swingTime)
    raiseTime = self.hitRaiseTime + timeLeft
  else
    animator.playSound("swing")
  end

  self:setState(self.raise, raiseTime)
end

function CrowbarSwing:raise(time)
  self:stanceTransition(time or self.raiseTime, self.stances.swing, self.stances.idle)
end

function CrowbarSwing:hitTile(point)
  point = util.tileCenter(point)
  local hitMaterial = self.defaultMaterial

  local mat = world.material(point, "foreground")
  if mat then
    local mod = world.mod(point, "foreground")
    local mining = root.materialMiningSound(mat, mod)
    if mining and self.miningMaterials[mining] then
      hitMaterial = self.miningMaterials[mining]
    else
      local footstep = root.materialFootstepSound(mat, mod)
      hitMaterial = footstep and self.footstepMaterials[footstep] or hitMaterial
    end
  end

  world.spawnProjectile(self.sparkProjectile, point)

  local sounds = self.materialSounds[hitMaterial] or {}
  for _, sound in pairs(sounds) do
    animator.playSound(sound)
  end
end

function CrowbarSwing:stanceTransition(time, stance, nextStance)
  local progress = 0
  while progress < 1 do
    progress = progress + (self.dt / time)
    self:stanceLerp(progress, stance, nextStance)
    coroutine.yield()
  end
end

function CrowbarSwing:stanceLerp(ratio, stance, nextStance)
  self.weapon.weaponOffset = vec2.lerp(ratio, stance.weaponOffset or {0, 0}, nextStance.weaponOffset or {0, 0})
  self.weapon.relativeArmRotation = util.toRadians(interp.sin(ratio, stance.armRotation or 0, nextStance.armRotation or 0))
  self.weapon.relativeWeaponRotation = util.toRadians(interp.sin(ratio, stance.weaponRotation or 0, nextStance.weaponRotation or 0))
end

function CrowbarSwing:uninit()
  self.weapon:setStance(self.stances.idle)
end
