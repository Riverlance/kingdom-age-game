_G.GameFeatures = { }



function GameFeatures.init()
  -- Alias
  GameFeatures.m = modules.game_features

  connect(g_game, {
    onClientVersionChange = GameFeatures.onClientVersionChange,
  })
end

function GameFeatures.terminate()
  disconnect(g_game, {
    onClientVersionChange = GameFeatures.onClientVersionChange,
  })

  _G.GameFeatures = nil
end



function GameFeatures.onClientVersionChange(version)
  -- g_game.enableFeature(GameKeepUnawareTiles)
  -- g_game.enableFeature(GameNegativeOffset)
  -- g_game.enableFeature(GameAllowCustomBotScripts)

  g_game.enableFeature(GameFormatCreatureName)

  -- For Walk
  g_game.enableFeature(GameAllowPreWalk)
  g_game.enableFeature(GameMapCache)
  -- g_game.enableFeature(GameSmoothWalkElevation)

  -- 770
  g_game.enableFeature(GameLooktypeU16)
  g_game.enableFeature(GameMessageStatements)
  g_game.enableFeature(GameLoginPacketEncryption)

  -- 780
  g_game.enableFeature(GamePlayerAddons)
  g_game.enableFeature(GamePlayerStamina)
  g_game.enableFeature(GameNewFluids)
  g_game.enableFeature(GameMessageLevel)
  g_game.enableFeature(GamePlayerStateU16)
  g_game.enableFeature(GameNewOutfitProtocol)

  -- 790
  g_game.enableFeature(GameWritableDate)

  -- 840
  g_game.enableFeature(GameProtocolChecksum)
  g_game.enableFeature(GameAccountNames)
  g_game.enableFeature(GameDoubleFreeCapacity)

  -- 841
  g_game.enableFeature(GameChallengeOnLogin)
  g_game.enableFeature(GameMessageSizeCheck)

  -- 854
  g_game.enableFeature(GameCreatureEmblems)

  -- 860
  g_game.enableFeature(GameAttackSeq)

  -- 862
  g_game.enableFeature(GamePenalityOnDeath)

  -- 870
  g_game.enableFeature(GameDoubleExperience)
  g_game.enableFeature(GamePlayerMounts)

  -- 910
  g_game.enableFeature(GameNameOnNpcTrade)
  g_game.enableFeature(GameTotalCapacity)
  g_game.enableFeature(GameSkillsBase)
  g_game.enableFeature(GamePlayerRegenerationTime)
  g_game.enableFeature(GameChannelPlayerList)
  g_game.enableFeature(GameEnvironmentEffect)

  -- 953
  g_game.enableFeature(GameClientPing)

  -- 960
  g_game.enableFeature(GameSpritesU32)
  g_game.enableFeature(GameOfflineTrainingTime)

  -- 963
  g_game.enableFeature(GameAdditionalVipInfo)

  -- 980
  g_game.enableFeature(GamePreviewState)
  g_game.enableFeature(GameClientVersion)

  -- 981
  g_game.enableFeature(GameLoginPending)
  g_game.enableFeature(GameNewSpeedLaw)

  -- 984
  g_game.enableFeature(GameContainerPagination)

  -- 1000
  g_game.enableFeature(GameThingMarks)

  -- 1035
  g_game.enableFeature(GameDoubleSkills)

  -- 1036
  g_game.enableFeature(GameSpeechBubble)

  -- 1038
  g_game.enableFeature(GamePremiumExpiration)

  -- 1050
  g_game.enableFeature(GameEnhancedAnimations)

  -- 1053
  g_game.enableFeature(GameUnjustifiedPointsPacket)

  -- 1054
  g_game.enableFeature(GameExperienceBonus)

  -- 1055
  g_game.enableFeature(GameDeathType)

  -- 1057
  g_game.enableFeature(GameIdleAnimations)

  -- 1061
  g_game.enableFeature(GameOGLInformation)

  -- 1071
  g_game.enableFeature(GameContentRevision)

  -- 1072
  g_game.enableFeature(GameAuthenticator)

  -- 1074
  g_game.enableFeature(GameSessionKey)

  -- 1080
  g_game.enableFeature(GameIngameStore)

  -- 1092
  g_game.enableFeature(GameIngameStoreServiceType)

  -- 1093
  g_game.enableFeature(GameIngameStoreHighlights)
  g_game.enableFeature(GameSequencedPackets)

  -- 1099
  g_game.enableFeature(GameEnterGameShowAppearance)
  g_game.enableFeature(GameVipGroups)
  g_game.enableFeature(GameCreaturePaperdoll)
end
