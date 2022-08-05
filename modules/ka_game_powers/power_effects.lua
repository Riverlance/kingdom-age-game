--[[Config]]

PowerBoostFadeIn     = 400
PowerBoostFadeOut    = 200
PowerBoostResizeX    = 0.5
PowerBoostResizeY    = 0.5
PowerBoostColorSpeed = 200

PowerBoostColor = {
  [PowerBoost.None]   = {255, 255, 255, 255},
  [PowerBoost.Low]    = {255, 255, 150, 255},
  [PowerBoost.Medium] = {255, 150, 150, 255},
  [PowerBoost.High]   = {150, 150, 255, 255}
}
PowerBoostColorDefault = PowerBoostColor[PowerBoost.None]


--[[Effects]]

function GamePowers.setBoostColor(boostLevel)
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    localPlayer:setColor(unpack(PowerBoostColor[boostLevel]))
  end
end

function GamePowers.removeBoostColor()
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    localPlayer:setColor(unpack(PowerBoostColorDefault))
  end
end

function GamePowers.setBoostImage(boostLevel)
  if modules.ka_game_screenimage then
    GameScreenImage.addImage(string.format('system/power_boost/normal_%d.png', boostLevel), PowerBoostFadeIn, 1, PowerBoostResizeX, PowerBoostResizeY, 0)
    GameScreenImage.addImage(string.format('system/power_boost/extra_%d.png', boostLevel), PowerBoostFadeIn, 1, PowerBoostResizeX, PowerBoostResizeY, 0)
  end
end

function GamePowers.removeBoostImage(boostLevel)
  if modules.ka_game_screenimage then
    GameScreenImage.removeImage(string.format('system/power_boost/normal_%d.png', boostLevel), PowerBoostFadeOut, 0)
    GameScreenImage.removeImage(string.format('system/power_boost/extra_%d.png', boostLevel), PowerBoostFadeOut, 0)
  end
end

function GamePowers.updateBoostEffects(boostLevel)
  -- remove current effects
  if lastBoost >= PowerBoostFirst and lastBoost <= PowerBoostLast then
    GamePowers.removeBoostImage(lastBoost)
    GamePowers.removeBoostColor(lastBoost)
  end
  -- add next effects
  if boostLevel and boostLevel >= PowerBoostFirst and boostLevel <= PowerBoostLast then
    GamePowers.setBoostImage(boostLevel)
    GamePowers.setBoostColor(boostLevel)
  end
end
