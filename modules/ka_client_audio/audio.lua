_G.ClientAudio = { }



local ACTION_CHANNEL_PLAY                 = 0
local ACTION_CHANNEL_STOP                 = 1
local ACTION_CHANNEL_SETCHANNELAUDIOSGAIN = 2
local ACTION_CHANNEL_SETGAIN              = 3
local ACTION_CHANNEL_STOPAUDIOS           = 4
local ACTION_CHANNEL_AUDIOSSETGAIN        = 5

local channels = { }
for channelId = AudioChannels.First, AudioChannels.Last do
  channels[channelId] = { }
  channels[channelId].id      = channelId -- Same as its key
  channels[channelId].volume  = 0
  channels[channelId].channel = g_sounds.getChannel(channelId)
end

local function setChannelVolume(channelId, volume)
  if not channels[channelId] then
    return
  end

  channels[channelId].volume = volume
  channels[channelId].channel:setGain(volume)
end



function ClientAudio.init()
  -- Alias
  ClientAudio.m = modules.ka_client_audio

  local isAudioEnabled = ClientOptions.getOption('enableAudio')

  channels[AudioChannels.Music].volume   = isAudioEnabled and ClientOptions.getOption('enableMusic') and ClientOptions.getOption('musicVolume') or 0
  channels[AudioChannels.Ambient].volume = isAudioEnabled and ClientOptions.getOption('enableSoundAmbient') and ClientOptions.getOption('soundAmbientVolume') or 0
  channels[AudioChannels.Effect].volume  = isAudioEnabled and ClientOptions.getOption('enableSoundEffect') and ClientOptions.getOption('soundEffectVolume') or 0
  channels[AudioChannels.Voice].volume   = isAudioEnabled and ClientOptions.getOption('enableSoundVoice') and ClientOptions.getOption('soundVoiceVolume') or 0
  channels[AudioChannels.Gui].volume     = isAudioEnabled and ClientOptions.getOption('enableSoundGui') and ClientOptions.getOption('soundGuiVolume') or 0

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeAudio, ClientAudio.parseAudioRequest)

  connect(LocalPlayer, {
    onPositionChange = ClientAudio.onPositionChange,
    onWalk           = ClientAudio.onCreatureMove,
  })

  connect(Creature, {
    onWalk = ClientAudio.onCreatureMove,
  })

  connect(g_game, {
    onAddMagicEffect     = ClientAudio.onAddMagicEffect,
    onAddDistanceMissile = ClientAudio.onAddDistanceMissile,
    onItemTransform      = ClientAudio.onItemTransform,
    onCreatureMove       = ClientAudio.onCreatureMove,
    onGameEnd            = ClientAudio.onGameEnd,
  })
end

function ClientAudio.terminate()
  disconnect(g_game, {
    onAddMagicEffect     = ClientAudio.onAddMagicEffect,
    onAddDistanceMissile = ClientAudio.onAddDistanceMissile,
    onItemTransform      = ClientAudio.onItemTransform,
    onCreatureMove       = ClientAudio.onCreatureMove,
    onGameEnd            = ClientAudio.onGameEnd,
  })

  disconnect(LocalPlayer, {
    onPositionChange = ClientAudio.onPositionChange,
    onWalk           = ClientAudio.onCreatureMove,
  })

  disconnect(Creature, {
    onWalk = ClientAudio.onCreatureMove,
  })

  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeAudio)

  ClientAudio.clearAudios()

  _G.ClientAudio = nil
end

function ClientAudio.setMusicVolume(volume)
  setChannelVolume(AudioChannels.Music, volume)
end

function ClientAudio.setAmbientVolume(volume)
  setChannelVolume(AudioChannels.Ambient, volume)
end

function ClientAudio.setEffectVolume(volume)
  setChannelVolume(AudioChannels.Effect, volume)
end

function ClientAudio.setVoiceVolume(volume)
  setChannelVolume(AudioChannels.Voice, volume)
end

function ClientAudio.setGuiVolume(volume)
  setChannelVolume(AudioChannels.Gui, volume)
end

function ClientAudio.updateAudios()
  if not g_game.isOnline() then
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  local position    = localPlayer and localPlayer:getPosition()
  if not position then
    return
  end

  g_sounds.setPosition(position)
  for _, _channel in ipairs(channels) do
    local channel = _channel.channel
    if channel then
      channel:setThingPosition(position.x, position.y)
    end
  end
end

function ClientAudio.clearAudios()
  g_sounds.stopAll()
  for _, _channel in ipairs(channels) do
    local channel = _channel.channel
    if channel then
      channel:clear()
    end
  end
end

function ClientAudio.parseAudioRequest(protocolGame, opcode, msg)
  local buffer = msg:getString()
  local params = string.split(buffer, ':')

  local action = tonumber(params[1])
  if not action then
    return
  end

  if action == ACTION_CHANNEL_PLAY then
    local channelId = tonumber(params[2])
    local path = params[3]
    local gain = tonumber(params[4])
    local repetitions = tonumber(params[5])
    local fadeInTime = tonumber(params[6])
    local x = tonumber(params[7])
    local y = tonumber(params[8])
    local pitch = tonumber(params[9]) or 1.0
    if pitch <= 0 then
      pitch = 1.0
    end
    if not channelId or path == '' or not gain or not repetitions or not fadeInTime or not x or not y then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    path = f('%s%s', AudioChannelRootPath, path)
    local audio = channel:play(path, gain, repetitions, fadeInTime, pitch)
    if audio and x ~= 0 and y ~= 0 then
      audio:setPosition(x, y)
    end

  elseif action == ACTION_CHANNEL_STOP then
    local channelId = tonumber(params[2])
    local fadeOutTime = tonumber(params[3])
    if not channelId or not fadeOutTime then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    channel:stop(fadeOutTime)

  elseif action == ACTION_CHANNEL_SETCHANNELAUDIOSGAIN then
    local channelId = tonumber(params[2])
    local gain = tonumber(params[3])
    if not channelId or not gain then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    channel:setAudioGroupGain(gain)

  elseif action == ACTION_CHANNEL_SETGAIN then
    local channelId = tonumber(params[2])
    local gain = tonumber(params[3])
    if not channelId or not gain then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    channel:setGain(gain)

  elseif action == ACTION_CHANNEL_STOPAUDIOS then
    local channelId = tonumber(params[2])
    local path = params[3]
    local fadeOutTime = tonumber(params[4])
    if not channelId or path == '' or not fadeOutTime then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    path = f('%s%s', AudioChannelRootPath, path)
    channel:stopAudioGroup(path, fadeOutTime)

 elseif action == ACTION_CHANNEL_AUDIOSSETGAIN then
    local channelId = tonumber(params[2])
    local path = params[3]
    local gain = tonumber(params[4])
    if not channelId or path == '' or not gain then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    path = f('%s%s', AudioChannelRootPath, path)
    channel:setAudioGroupGain(path, gain)
  end
end





function ClientAudio.onPositionChange(creature, newPos, oldPos)
  ClientAudio.updateAudios()
end



-- Effect Audio

do
  local function canReleaseAudioEffect(pos)
    local localPlayer = g_game.getLocalPlayer()
    local playerPos   = localPlayer and localPlayer:getPosition()
    if not playerPos then
      return
    end

    -- Diff floor, then we need to check if has ground between
    if pos.z ~= playerPos.z then
      -- Effect is above
      if pos.z < playerPos.z then
        -- From effect floor to player floor
        for z = pos.z, playerPos.z do
          local tile = g_map.getTile{ x = pos.x, y = pos.y, z = z }
          if tile and (not tile:isLookPossible() or tile:isFullGround()) then
            return false
          end
        end

      -- Effect is below
      else
        -- From above effect floor to player floor
        for z = pos.z - 1, playerPos.z, -1 do
          local tile = g_map.getTile{ x = pos.x, y = pos.y, z = z }
          if tile and (not tile:isLookPossible() or tile:isFullGround()) then
            return false
          end
        end
      end
    end

    return true
  end



  -- Effect

  do
    local datFxPath = f('%s/dat/fx', getAudioChannelPath(AudioChannels.Effect))

    local effects = {
      [1] = { id = 1 },
      [2] = { id = 2 },
      [3] = { id = 3 },
      [4] = { id = 4 },
      [5] = { id = 5 },
      [6] = { id = 6 },
      [7] = { id = 7 },
      [8] = { id = 8 },
      [9] = { id = 9 },
      [10] = { id = 10 },
      [11] = { id = 11 },
      [12] = { id = 12 },
      [13] = { id = 13 },
      [14] = { id = 14, path = f('%s/13', datFxPath) },
      [15] = { id = 15, path = f('%s/13', datFxPath) },
      [16] = { id = 16 },
      [17] = { id = 17, path = f('%s/1', datFxPath) },
      [18] = { id = 18 },
      [19] = { id = 19 },
      [20] = { id = 20, path = f('%s/19', datFxPath) },
      [21] = { id = 21, path = f('%s/3', datFxPath) },
      [22] = { id = 22, path = f('%s/19', datFxPath) },
      [23] = { id = 23, path = f('%s/19', datFxPath) },
      [24] = { id = 24, path = f('%s/19', datFxPath) },
      [25] = { id = 25, path = f('%s/19', datFxPath) },
      [26] = { id = 26 },
      [27] = { id = 27 },
      [28] = { id = 28 },
      [29] = { id = 29 },
      [30] = { id = 30, path = f('%s/29', datFxPath) },
      [31] = { id = 31, path = f('%s/29', datFxPath) },
      [32] = { id = 32 },
      [33] = { id = 33 },
      [34] = { id = 34 },
      [35] = { id = 35 },
      [36] = { id = 36 },
      [37] = { id = 37 },
      [38] = { id = 38 },
      [39] = { id = 39 },
      [40] = { id = 40 },
      [41] = { id = 41 },
      [42] = { id = 42 },
      [43] = { id = 43 },
      [44] = { id = 44 },
      [45] = { id = 45 },
      [46] = { id = 46 },
      [47] = { id = 47 },
      [48] = { id = 48, path = f('%s/12', datFxPath) },
      [49] = { id = 49, path = f('%s/12', datFxPath) },
      [50] = { id = 50 },
      [51] = { id = 51 },
      [52] = { id = 52 },
      [53] = { id = 53 },
      [54] = { id = 54 },
      [55] = { id = 55 },
      [56] = { id = 56 },
      [57] = { id = 57 },
      [58] = { id = 58 },
      [59] = { id = 59, path = f('%s/58', datFxPath) },
      [60] = { id = 60 },
      [61] = { id = 61, path = f('%s/60', datFxPath) },
      -- 62
      [63] = { id = 63 },
      [64] = { id = 64 },
      [65] = { id = 65, path = f('%s/63', datFxPath) },
      [66] = { id = 66 },
      [67] = { id = 67 },
      [68] = { id = 68 },
      [69] = { id = 69 },
      -- 70
      -- 71
      -- 72
      [73] = { id = 73 },
      -- 74
      [75] = { id = 75, path = f('%s/28', datFxPath) },
      [76] = { id = 76, path = f('%s/28', datFxPath) },
      [77] = { id = 77, path = f('%s/41', datFxPath) },

      [158] = { id = 158 },

      [167] = { id = 167, path = f('%s/158', datFxPath) },
      [168] = { id = 168, path = f('%s/158', datFxPath) },
      [169] = { id = 169, path = f('%s/158', datFxPath) },
      [170] = { id = 170, path = f('%s/158', datFxPath) },

      -- 172
      [173] = { id = 173 },

      [175] = { id = 175 },

      [177] = { id = 177 },
      [178] = { id = 178, path = f('%s/177', datFxPath) },
      [179] = { id = 179, path = f('%s/177', datFxPath) },
      [180] = { id = 180, path = f('%s/177', datFxPath) },
      [181] = { id = 181 },
      [182] = { id = 182, path = f('%s/181', datFxPath) },
      [183] = { id = 183, path = f('%s/181', datFxPath) },
      [184] = { id = 184, path = f('%s/181', datFxPath) },
      [185] = { id = 185 },
      [186] = { id = 186, path = f('%s/185', datFxPath) },
      [187] = { id = 187, path = f('%s/185', datFxPath) },
      [188] = { id = 188, path = f('%s/185', datFxPath) },
      [189] = { id = 189 },
      [190] = { id = 190, path = f('%s/189', datFxPath) },
      [191] = { id = 191, path = f('%s/189', datFxPath) },
      [192] = { id = 192, path = f('%s/189', datFxPath) },
      [193] = { id = 193 },
      [194] = { id = 194, path = f('%s/193', datFxPath) },
      [195] = { id = 195, path = f('%s/193', datFxPath) },
      [196] = { id = 196, path = f('%s/193', datFxPath) },
      [197] = { id = 197 },
      [198] = { id = 198, path = f('%s/197', datFxPath) },
      [199] = { id = 199 },
      [200] = { id = 200, path = f('%s/199', datFxPath) },
      [201] = { id = 201, path = f('%s/199', datFxPath) },
      [202] = { id = 202, path = f('%s/199', datFxPath) },
      [203] = { id = 203, path = f('%s/199', datFxPath) },
      [204] = { id = 204, path = f('%s/199', datFxPath) },
      [205] = { id = 205, path = f('%s/199', datFxPath) },
      [206] = { id = 206, path = f('%s/199', datFxPath) },
      [207] = { id = 207, path = f('%s/199', datFxPath) },
      [208] = { id = 208, path = f('%s/199', datFxPath) },
      [209] = { id = 209, path = f('%s/199', datFxPath) },
      [210] = { id = 210, path = f('%s/199', datFxPath) },
      [211] = { id = 211 },
      [212] = { id = 212, path = f('%s/211', datFxPath) },
      [213] = { id = 213, path = f('%s/211', datFxPath) },
      [214] = { id = 214, path = f('%s/211', datFxPath) },
      [215] = { id = 215 },
      [216] = { id = 216 },
      [217] = { id = 217 },
      [218] = { id = 218 },
      [219] = { id = 219 },
      [220] = { id = 220 },
      [221] = { id = 221 },
      [222] = { id = 222 },
      [223] = { id = 223, path = f('%s/222', datFxPath) },
      [224] = { id = 224, path = f('%s/222', datFxPath) },
      [225] = { id = 225, path = f('%s/222', datFxPath) },
      [226] = { id = 226, path = f('%s/222', datFxPath) },
      [227] = { id = 227 },
      [228] = { id = 228, path = f('%s/227', datFxPath) },
      [229] = { id = 229, path = f('%s/227', datFxPath) },
      [230] = { id = 230, path = f('%s/227', datFxPath) },
      [231] = { id = 231, path = f('%s/227', datFxPath) },
      [232] = { id = 232 },
      [233] = { id = 233 },
      [234] = { id = 234 },
      [235] = { id = 235 },
      [236] = { id = 236 },
      [237] = { id = 237 },
      [238] = { id = 238 },
      [239] = { id = 239 },
      [240] = { id = 240 },
      [241] = { id = 241 },
      [242] = { id = 242 },
      [243] = { id = 243 },
      [244] = { id = 244 },
      [245] = { id = 245, path = f('%s/43', datFxPath) },
      [246] = { id = 246, path = f('%s/43', datFxPath) },
      [247] = { id = 247 },
      [248] = { id = 248 },
      [249] = { id = 249, path = f('%s/248', datFxPath) },
      [250] = { id = 250, path = f('%s/248', datFxPath) },
      [251] = { id = 251, path = f('%s/248', datFxPath) },
      [252] = { id = 252, path = f('%s/248', datFxPath) },
      [253] = { id = 253 },
      [254] = { id = 254 },
      [255] = { id = 255 },
      [256] = { id = 256 },
      [257] = { id = 257 },
      [258] = { id = 258, path = f('%s/257', datFxPath) },
      [259] = { id = 259 },
      [260] = { id = 260 },
      [261] = { id = 261, path = f('%s/237', datFxPath) },
      [262] = { id = 262 },
      [263] = { id = 263 },
      [264] = { id = 264 },
      [265] = { id = 265 },
      [266] = { id = 266 },
      [267] = { id = 267 },
      [268] = { id = 268 },
      [269] = { id = 269 },
      [270] = { id = 270, path = f('%s/269', datFxPath) },
      [271] = { id = 271, path = f('%s/269', datFxPath) },
      [272] = { id = 272, path = f('%s/269', datFxPath) },
      [273] = { id = 273, path = f('%s/269', datFxPath) },
      [274] = { id = 274, path = f('%s/269', datFxPath) },
      [275] = { id = 275, path = f('%s/269', datFxPath) },
      [276] = { id = 276, path = f('%s/269', datFxPath) },
      [277] = { id = 277, path = f('%s/269', datFxPath) },
      [279] = { id = 279, path = f('%s/269', datFxPath) },
      [280] = { id = 280, path = f('%s/269', datFxPath) },
      [281] = { id = 281, path = f('%s/269', datFxPath) },
      [282] = { id = 282, path = f('%s/269', datFxPath) },
      [283] = { id = 283, path = f('%s/269', datFxPath) },
      [284] = { id = 284, path = f('%s/269', datFxPath) },
      [285] = { id = 285, path = f('%s/269', datFxPath) },
      [286] = { id = 286, path = f('%s/269', datFxPath) },
      [287] = { id = 287, path = f('%s/269', datFxPath) },
      [288] = { id = 288, path = f('%s/269', datFxPath) },
      [289] = { id = 289, path = f('%s/269', datFxPath) },
      [290] = { id = 290, path = f('%s/269', datFxPath) },
      [291] = { id = 291, path = f('%s/269', datFxPath) },
      [292] = { id = 292, path = f('%s/269', datFxPath) },
      [293] = { id = 293, path = f('%s/269', datFxPath) },
      [294] = { id = 294, path = f('%s/269', datFxPath) },
      [295] = { id = 295, path = f('%s/269', datFxPath) },
      [296] = { id = 296, path = f('%s/269', datFxPath) },
      [297] = { id = 297, path = f('%s/269', datFxPath) },
      [298] = { id = 298, path = f('%s/269', datFxPath) },
      [299] = { id = 299, path = f('%s/269', datFxPath) },
      [300] = { id = 300, path = f('%s/269', datFxPath) },
      [301] = { id = 301, path = f('%s/269', datFxPath) },
      [302] = { id = 302, path = f('%s/269', datFxPath) },
      [303] = { id = 303, path = f('%s/269', datFxPath) },
      [304] = { id = 304, path = f('%s/269', datFxPath) },
      [305] = { id = 305, path = f('%s/269', datFxPath) },
      [306] = { id = 306, path = f('%s/269', datFxPath) },
      [307] = { id = 307, path = f('%s/269', datFxPath) },
      [308] = { id = 308, path = f('%s/269', datFxPath) },
      [309] = { id = 309 },
      [310] = { id = 310, path = f('%s/309', datFxPath) },
      [311] = { id = 311 },
      [312] = { id = 312 },
      [313] = { id = 313 },
      [314] = { id = 314 },
      [315] = { id = 315 },
      [316] = { id = 316 },
      [317] = { id = 317 },
      [318] = { id = 318 },
      [319] = { id = 319 },
      [320] = { id = 320 },
      [321] = { id = 321, path = f('%s/320', datFxPath) },
      [322] = { id = 322, path = f('%s/320', datFxPath) },
      [323] = { id = 323, path = f('%s/320', datFxPath) },
      [324] = { id = 324 },
      [325] = { id = 325 },
      [326] = { id = 326 },
      [327] = { id = 327 },
      [328] = { id = 328, path = f('%s/3', datFxPath) },
      [329] = { id = 329, path = f('%s/3', datFxPath) },
      [330] = { id = 330, path = f('%s/3', datFxPath) },
      [331] = { id = 331, path = f('%s/3', datFxPath) },
      [332] = { id = 332, path = f('%s/3', datFxPath) },
      [333] = { id = 333 },
      [335] = { id = 335 },
      [336] = { id = 336, path = f('%s/335', datFxPath) },
      [337] = { id = 337, path = f('%s/335', datFxPath) },
      [338] = { id = 338, path = f('%s/335', datFxPath) },
      [339] = { id = 339, path = f('%s/335', datFxPath) },
      [340] = { id = 340, path = f('%s/335', datFxPath) },
      [341] = { id = 341, path = f('%s/13', datFxPath) },
      [342] = { id = 342 },
      [343] = { id = 343 },
      [344] = { id = 344 },
      [345] = { id = 345, path = f('%s/66', datFxPath) },
      [346] = { id = 346 },
      [347] = { id = 347 },
      [348] = { id = 348 },
      [349] = { id = 349, path = f('%s/29', datFxPath) },
      [350] = { id = 350, path = f('%s/29', datFxPath) },
      [351] = { id = 351, path = f('%s/29', datFxPath) },
      [352] = { id = 352, path = f('%s/29', datFxPath) },
      [353] = { id = 353 },
      [354] = { id = 354, path = f('%s/1', datFxPath) },
      [355] = { id = 355, path = f('%s/13', datFxPath) },
      [356] = { id = 356 },
      [357] = { id = 357, path = f('%s/56', datFxPath) },
      [358] = { id = 358, path = f('%s/57', datFxPath) },
      [359] = { id = 359 },
      [360] = { id = 360 },
      [361] = { id = 361 },
      [362] = { id = 362 },
      [363] = { id = 363, path = f('%s/199', datFxPath) },
      [364] = { id = 364 },
      [365] = { id = 365 },
      [366] = { id = 366, path = f('%s/365', datFxPath) },
      [367] = { id = 367 },
      [368] = { id = 368, path = f('%s/11', datFxPath) },
      [369] = { id = 369, path = f('%s/11', datFxPath) },
      [370] = { id = 370, path = f('%s/11', datFxPath) },
      [371] = { id = 371, path = f('%s/11', datFxPath) },
      [372] = { id = 372, path = f('%s/11', datFxPath) },
      [373] = { id = 373 },
      [374] = { id = 374 },
      [375] = { id = 375 },
      [376] = { id = 376 },
      [377] = { id = 377 },
      [378] = { id = 378 },
      [379] = { id = 379 },
      [380] = { id = 380 },
      [381] = { id = 381 },
      [382] = { id = 382 },
      [383] = { id = 383 },
      [384] = { id = 384, path = f('%s/383', datFxPath) },
      [385] = { id = 385 },
      [386] = { id = 386 },
      [387] = { id = 387 },
      [388] = { id = 388 },
      [389] = { id = 389 },
      [390] = { id = 390, path = f('%s/389', datFxPath) },
      [391] = { id = 391 },

      -- [777] = { id = 777, path = f('%s/77', datPath) --[[, gain = 1, repetitions = 0, fadeInTime = 0]] },
    }

    local fxExhaustions = {
      -- [f('%s/77', datPath)]  = { singlePerTime = .1 }, -- example of custom singlePerTime
    }

    function ClientAudio.onAddMagicEffect(id, pos)
      local effect = effects[id]
      if not effect then
        return
      end
      local effectPath = effect.path or f('%s/%d', datFxPath, effect.id)
      effect.onPos     = effect.onPos == nil and true or effect.onPos

      if not fxExhaustions[effectPath] then
        fxExhaustions[effectPath] = { singlePerTime = .1 }
      end
      local exhaustion = fxExhaustions[effectPath]
      if exhaustion.singlePerTime and os.clock() - (exhaustion.lastExecution or 0) < exhaustion.singlePerTime or not canReleaseAudioEffect(pos) then
        return
      end

      local audio = g_sounds.getChannel(AudioChannels.Effect):play(f('%s.ogg', effectPath), effect.gain or 1, effect.repetitions or 0, effect.fadeInTime or 0)
      if audio and effect.onPos then
        audio:setPosition(pos.x, pos.y)
      end

      if exhaustion then
        exhaustion.lastExecution = os.clock()
      end
    end
  end



  -- Distance Effect

  do
    local datFxPath = f('%s/dat/fxdist', getAudioChannelPath(AudioChannels.Effect))

    local effects = {
      [1] = { id = 1 },
      [2] = { id = 2 },
      [3] = { id = 3 },
      [4] = { id = 4 },
      [5] = { id = 5 },
      [6] = { id = 6, path = f('%s/3', datFxPath) },
      [7] = { id = 7, path = f('%s/3', datFxPath) },
      [8] = { id = 8 },
      [9] = { id = 9 },
      [10] = { id = 10 },
      [11] = { id = 11 },
      [12] = { id = 12 },
      [13] = { id = 13, path = f('%s/10', datFxPath) },
      [14] = { id = 14, path = f('%s/2', datFxPath) },
      [15] = { id = 15 },
      [16] = { id = 16, path = f('%s/2', datFxPath) },
      [17] = { id = 17, path = f('%s/1', datFxPath) },
      [18] = { id = 18, path = f('%s/1', datFxPath) },
      [19] = { id = 19, path = f('%s/8', datFxPath) },
      [20] = { id = 20, path = f('%s/8', datFxPath) },
      [21] = { id = 21, path = f('%s/1', datFxPath) },
      [22] = { id = 22, path = f('%s/3', datFxPath) },
      [23] = { id = 23, path = f('%s/3', datFxPath) },
      [24] = { id = 24, path = f('%s/2', datFxPath) },
      [25] = { id = 25, path = f('%s/9', datFxPath) },
      [26] = { id = 26, path = f('%s/9', datFxPath) },
      [27] = { id = 27, path = f('%s/12', datFxPath) },
      [28] = { id = 28, path = f('%s/1', datFxPath) },
      [29] = { id = 29 },
      [30] = { id = 30, path = f('%s/12', datFxPath) },
      [31] = { id = 31 },
      [32] = { id = 32 },
      [33] = { id = 33, path = f('%s/3', datFxPath) },
      [34] = { id = 34, path = f('%s/3', datFxPath) },
      [35] = { id = 35, path = f('%s/3', datFxPath) },
      [36] = { id = 36, path = f('%s/4', datFxPath) },
      [37] = { id = 37 },
      [38] = { id = 38 },
      [39] = { id = 39, path = f('%s/10', datFxPath) },
      [40] = { id = 40, path = f('%s/3', datFxPath) },
      [41] = { id = 41 },
      [42] = { id = 42, path = f('%s/12', datFxPath) },

      [44] = { id = 44, path = f('%s/3', datFxPath) },
      [45] = { id = 45, path = f('%s/2', datFxPath) },

      [48] = { id = 48, path = f('%s/2', datFxPath) },
      [49] = { id = 49, path = f('%s/3', datFxPath) },
      [50] = { id = 50, path = f('%s/2', datFxPath) },
      [51] = { id = 51, path = f('%s/3', datFxPath) },

      [53] = { id = 53, path = f('%s/1', datFxPath) },
      [54] = { id = 54, path = f('%s/3', datFxPath) },
      [55] = { id = 55 },
      [56] = { id = 56 },
      [57] = { id = 57 },
      [58] = { id = 58 },
      [59] = { id = 59, path = f('%s/4', datFxPath) },
      [60] = { id = 60 },
      [61] = { id = 61, path = f('%s/12', datFxPath) },
      [62] = { id = 62, path = f('%s/10', datFxPath) },
      [63] = { id = 63 },
      [64] = { id = 64, path = f('%s/56', datFxPath) },
      [65] = { id = 65, path = f('%s/12', datFxPath) },
      [66] = { id = 66, path = f('%s/4', datFxPath) },
      [67] = { id = 67, path = f('%s/4', datFxPath) },
      [68] = { id = 68, path = f('%s/4', datFxPath) },
      [69] = { id = 69, path = f('%s/4', datFxPath) },
      [70] = { id = 70, path = f('%s/4', datFxPath) },
      [71] = { id = 71, path = f('%s/4', datFxPath) },
      [72] = { id = 72, path = f('%s/4', datFxPath) },
      [73] = { id = 73 },
      [74] = { id = 74 },
      [75] = { id = 75, path = f('%s/55', datFxPath) },
      [76] = { id = 76, path = f('%s/9', datFxPath) },
      [77] = { id = 77, path = f('%s/8', datFxPath) },
      [78] = { id = 78, path = f('%s/3', datFxPath) },
      [79] = { id = 79, path = f('%s/3', datFxPath) },
      [80] = { id = 80, path = f('%s/8', datFxPath) },
      [81] = { id = 81, path = f('%s/8', datFxPath) },
      [82] = { id = 82, path = f('%s/8', datFxPath) },
      [83] = { id = 83, path = f('%s/8', datFxPath) },
      [84] = { id = 84, path = f('%s/8', datFxPath) },
      [85] = { id = 85, path = f('%s/8', datFxPath) },
      [86] = { id = 86, path = f('%s/8', datFxPath) },
      [87] = { id = 87, path = f('%s/8', datFxPath) },
      [88] = { id = 88, path = f('%s/8', datFxPath) },
      [89] = { id = 89, path = f('%s/8', datFxPath) },
      [90] = { id = 90, path = f('%s/8', datFxPath) },

      -- [777] = { id = 777, path = f('%s/77', datPath) --[[, gain = 1, repetitions = 0, fadeInTime = 0]] },
    }

    local fxExhaustions = {
      -- [f('%s/77', datPath)]  = { singlePerTime = .1 }, -- example of custom singlePerTime
    }

    function ClientAudio.onAddDistanceMissile(id, fromPos, toPos)
      local effect = effects[id]
      if not effect then
        return
      end
      local effectPath = effect.path or f('%s/%d', datFxPath, effect.id)
      effect.onPos     = effect.onPos == nil and true or effect.onPos

      if not fxExhaustions[effectPath] then
        fxExhaustions[effectPath] = { singlePerTime = .1 }
      end
      local exhaustion = fxExhaustions[effectPath]
      if exhaustion.singlePerTime and os.clock() - (exhaustion.lastExecution or 0) < exhaustion.singlePerTime or not canReleaseAudioEffect(fromPos) then
        return
      end

      local audio = g_sounds.getChannel(AudioChannels.Effect):play(f('%s.ogg', effectPath), effect.gain or 1, effect.repetitions or 0, effect.fadeInTime or 0)
      if audio and effect.onPos then
        audio:setPosition(fromPos.x, fromPos.y)
      end

      if exhaustion then
        exhaustion.lastExecution = os.clock()
      end
    end
  end
end



-- Walking step audio

local function createItemIdSet(itemIds)
  local itemIdSet = { }
  for _, itemId in ipairs(itemIds) do
    itemIdSet[itemId] = true
  end
  return itemIdSet
end

local walkAudioGrounds = {
  stone = createItemIdSet{ 409, 410, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 429, 430, 431, 436, 437, 438, 463, 479, 481, 596, 597, 598, 599, 601, 600, 604, 605, 609, 610, 800, 870, 923, 924, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935, 936, 1210, 1211, 1212, 1213, 1214, 1215, 1216, 1217, 1218, 1219, 1220, 1221, 1222, 1223, 1224, 1225, 1226, 1227, 1228, 1229, 1230, 1231, 1232, 1233, 1234, 1235, 1236, 1237, 1238, 1239, 1240, 1241, 1242, 1243, 1244, 1245, 1246, 1247, 1248, 1249, 1250, 1251, 1252, 1253, 1254, 1255, 1256, 1257, 1258, 1259, 1260, 1261, 1262, 1263, 1264, 1265, 1266, 1267, 1268, 1269, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 566, 567, 4394, 4395, 4396, 4397, 4398, 4399, 4400, 4401, 4402, 4403, 4404, 4405, 4406, 4407, 4408, 4409, 4410, 4555, 4559, 4560, 4561, 4562, 4563, 4564, 4565, 4566, 4567, 4568, 4584, 4823, 859, 4825, 4826, 9291, 5405, 5406, 5407, 5408, 5409, 6127, 6128, 6129, 6130, 6683, 6684, 6685, 6686, 6967, 7062, 7063, 7064, 7065, 7066, 7350, 7351, 7353, 7355, 7356, 7358, 4824, 7593, 7594, 7595, 7596, 7597, 7598, 7599, 7600, 7601, 7602, 7603, 7604, 7729, 7730, 7731, 7732, 7733, 7734, 7735, 7736, 7739, 7740, 7760, 7770, 7880, 8131, 8228, 8229, 8230, 8276, 8277, 8278, 8279, 8280, 8281, 8283, 8284, 8285, 8286, 8287, 8288, 8289, 8290, 8658, 8690, 8755, 8756, 8757, 8932, 5404, 9257, 9290, 9305, 9481, 9482, 9483, 9484, 9485, 9486, 9487, 9575, 9576, 9577, 9578, 9579, 9580, 9581, 9848, 9849, 9850, 9851, 9852, 9853, 9854, 9855, 9856, 9857, 9929, 9930, 9931, 9932, 9933, 9934, 9935, 9936, 9937, 9938, 9939, 10145, 10146, 10180, 10548, 10549, 10550, 10551, 10552, 10553, 10986, 10989, 10991, 10997, 10998, 10999, 11000, 11001, 11002, 11038, 11278, 11279, 11280, 11281, 11282, 11283, 11284, 11285, 11417, 11418, 11419, 11420, 11421, 11422, 11423, 11424, 11425, 11843, 11844, 11845, 11846, 11847, 11848, 11849, 11850, 11851, 11852, 11853, 11854, 11855, 11856, 11857, 11858, 11926, 11927, 11928, 11929, 11930, 11931, 11932, 11933, 11934, 11935, 11936, 11937, 11938, 11939, 11940, 11941, 11943, 11944, 11945, 11946, 11947, 11948, 11949, 11950, 12285, 12286, 12287, 12288, 12289, 12290, 12291, 12292, 12293, 12059, 12060, 12061, 12062, 12063, 12065, 12066, 12068, 12845, 13430, 13431, 13432, 13433, 13434, 13435, 13436, 13437, 13438, 13439, 13440, 13441, 13442, 13443, 13444, 13445, 13446, 13447, 13448, 13449, 13450, 13451, 13452, 13453, 13455, 13456, 13457, 13458, 13459, 13460, 13461, 13462, 13463, 13464, 13465, 13533, 13534, 13535, 13536, 13537, 13538, 13805, 13806, 13807, 13808, 13809, 13810, 14137, 14138, 14139, 14140, 14770, 14771, 14772, 14773, 14774, 14775, 14776, 14777, 15000, 15001, 15002, 15003, 15145, 15146, 15468, 15469, 15470, 15471, 15472, 15641, 15642, 15643, 15644, 15645, 15646, 15647, 15648, 15649, 15650, 15717, 15785, 16174, 17316, 17464, 17465, 17466, 17467, 17468, 17505, 17506, 17507, 17508, 17509, 17510, 17544, 17545, 17546, 17547, 17666, 17968, 18013, 19145, 19147, 19608, 19609, 19610, 19611, 19612, 19613, 19614, 19615, 19825, 19826, 19827, 19828, 19829, 19830, 19831, 19832, 19833, 19834, 19835, 19836, 19837, 19838, 19839, 19840, 19841, 19842, 19843, 19844, 19845, 19846, 19847, 19848, 20125, 20136, 20232, 20259, 20260, 20261, 20262, 20263, 20374, 20375, 20376, 20377, 20378, 20379, 20488, 20489, 20490, 20533, 20534, 20535, 20536, 20537, 20538, 20539, 20540, 20541, 20542, 20544, 20545, 20712, 20888, 21034, 21035, 21138, 21139, 21345, 21346, 21406, 21407, 21408, 21409, 21437, 21440, 21441, 21442, 21575, 21576, 21577, 21578, 21579, 21580, 21581, 21582, 21583, 21584, 21585, 21676, 21677, 21678, 21679, 21680, 21681, 21693, 21694, 21696, 21697, 21698, 21699, 21700, 21701, 21702, 21703, 21704, 21705, 21706, 21707, 21708, 21709, 21710, 21711, 21712, 21713, 21714, 21715, 21716, 21717, 21718, 21719, 21720, 21721, 21722, 21723, 21724, 21725, 21726, 21727, 21728, 21729, 21730, 21731, 21732, 21733, 21734, 21735, 21736, 21737, 21971, 22157, 22538, 22539, 22540, 22541, 22688, 22716, 22717, 22718, 22719, 22748, 22793, 22795, 22872, 22877, 22878, 22892, 22893, 22894, 23048, 23049, 23050, 23051, 23052, 23053, 23054, 23055, 23056, 23111, 23112, 23113, 23363, 23364, 23463, 25167, 25221 },
  wood  = createItemIdSet{ 369, 370, 408, 411, 412, 413, 414, 428, 432, 433, 434, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 464, 475, 8709, 1771, 482, 483, 484, 485, 486, 563, 564, 2253, 2254, 2259, 2260, 2261, 2262, 4971, 5544, 5691, 5743, 5744, 5763, 5764, 5768, 5769, 5770, 6209, 6212, 7053, 7272, 7357, 7767, 7768, 905, 7769, 7867, 7886, 8308, 8309, 8310, 8311, 8312, 8313, 8314, 8315, 8316, 8708, 8766, 8767, 8768, 8769, 10900, 10901, 10902, 10903, 10904, 10905, 10906, 10907, 11316, 476, 11731, 11732, 11733, 11734, 11735, 11736, 11737, 11738, 11739, 12129, 12799, 12846, 15596, 16203, 16484, 16485, 16486, 16487, 16488, 16489, 16584, 17516, 17517, 17518, 17937, 17982, 17985, 20658, 20713, 20714, 21294, 21374, 22750 },
  mud   = createItemIdSet{ 194, 950, 952, 4821, 4822, 6352, 10113, 10494, 10605, 11348, 11366, 12090, 12091, 12092, 12093, 12094, 12095, 12112, 12113, 12253, 12254, 12255, 12256, 12257, 12258, 12277, 12278, 12279, 12280, 12281, 12721, 13184, 13988, 13989, 15040, 15041, 15042, 15043, 15044, 15045, 15046, 15047, 16280, 16281, 16282, 16283, 16284, 16285, 16286, 16287, 17667, 18838, 18839, 18840, 18841, 19477, 19478, 19970, 19971, 19972, 19973, 20012, 20013, 20014, 20015, 20025, 20137, 23461, 23472 },
  snow  = createItemIdSet{ 799, 6580, 6581, 6582, 6583, 6584, 6585, 6586, 6587, 6588, 6589, 6590, 6591, 6592, 6593, 6594, 6595, 6596, 6597, 6598, 6599, 6600, 6601, 6602, 6603, 6604, 6605, 6606, 6607, 6608 },
}

local walkAudioExhaustion = { }
local walkAudioFileExists = { }
local walkAudioInterval = 200

function ClientAudio.onGameEnd()
  walkAudioExhaustion = { }
end

function ClientAudio.onCreatureMove(creature, oldPos, newPos)
  if not creature or not creature:isPlayer() or creature:isInGhostMode() or (oldPos.x == newPos.x and oldPos.y == newPos.y) then
    return
  end

  local ambientChannel = channels[AudioChannels.Ambient]
  if ambientChannel.volume <= 0 then
    return
  end

  local tile = g_map.getTile(newPos)
  local ground = tile and tile:getGround()
  if not ground then
    return
  end

  local groundId = ground:getId()
  local creatureId = creature:getId()
  local now = g_clock.millis()
  if (walkAudioExhaustion[creatureId] or 0) > now then
    return
  end
  walkAudioExhaustion[creatureId] = now + walkAudioInterval

  local material
  if walkAudioGrounds.stone[groundId] or tile:hasElevation(1) then
    material = 'stone'
  elseif walkAudioGrounds.wood[groundId] then
    material = 'wood'
  elseif walkAudioGrounds.mud[groundId] then
    material = 'mud'
  elseif walkAudioGrounds.snow[groundId] then
    material = 'snow'
  else
    material = 'default'
  end

  local path = f('%s/walk/%s_%d.ogg', getAudioChannelPath(AudioChannels.Ambient), material, math.random(4))
  if walkAudioFileExists[path] == nil then
    walkAudioFileExists[path] = g_resources.fileExists(path)
  end
  if not walkAudioFileExists[path] then
    return
  end

  local audio = ambientChannel.channel:play(path, 1, 0, 0)
  if audio then
    audio:setPosition(newPos.x, newPos.y)
  end
end



-- Elevator audio

local elevatorItemClientIds = {
  upStartBottom  = { 25140, 25154 },
  downStartTop   = { 25140, 25146 },
  downStartBottom = { 25165, 25164 },
}

local elevatorSoundCooldowns = { }
local elevatorSoundCooldown = 250

local function playElevatorSound(direction, position, elevatorFloor)
  local ambientChannel = channels[AudioChannels.Ambient]
  if ambientChannel.volume <= 0 then
    return
  end

  local key = f('%d:%d:%d:%s', position.x, position.y, elevatorFloor, direction)
  local now = g_clock.millis()
  if (elevatorSoundCooldowns[key] or 0) > now then
    return
  end

  local expiresAt = now + elevatorSoundCooldown
  elevatorSoundCooldowns[key] = expiresAt
  addEvent(function(key, expectedExpiresAt)
    if elevatorSoundCooldowns[key] == expectedExpiresAt then
      elevatorSoundCooldowns[key] = nil
    end
  end, elevatorSoundCooldown, key, expiresAt)

  local path = f('%s/item/elevator_stone_%s.ogg', getAudioChannelPath(AudioChannels.Ambient), direction)
  local audio = ambientChannel.channel:play(path, 1, 0, 0)
  if audio then
    audio:setPosition(position.x, position.y)
  end
end

function ClientAudio.onItemTransform(oldItem, newItem, position)
  local oldItemId = oldItem:getId()
  local newItemId = newItem:getId()

  if oldItemId == elevatorItemClientIds.upStartBottom[1] and newItemId == elevatorItemClientIds.upStartBottom[2] then
    playElevatorSound('up', position, position.z)
  elseif oldItemId == elevatorItemClientIds.downStartTop[1] and newItemId == elevatorItemClientIds.downStartTop[2] then
    playElevatorSound('down', position, position.z + 1)
  elseif oldItemId == elevatorItemClientIds.downStartBottom[1] and newItemId == elevatorItemClientIds.downStartBottom[2] then
    playElevatorSound('down', position, position.z)
  end
end
