_G.GameThings = { }



function GameThings.init()
  -- Alias
  GameThings.m = modules.game_things
end

function GameThings.terminate()
  _G.GameThings = nil
end

function GameThings.setFileName(name)
  filename = name
end
