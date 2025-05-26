require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

function init()
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))
  
  self.weapon = Weapon:new()

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local altAbility = getAltAbility()
  if altAbility then
    self.weapon:addAbility(altAbility)
  end

  self.weapon:addTransformationGroup("weapon", {0, 0}, util.toRadians(config.getParameter("baseWeaponRotation", 0)))

  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
end

function uninit()
  self.weapon:uninit()
end
