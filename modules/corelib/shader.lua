ShaderUniforms = {
  Progress = 20
}

MapShaders = {
  -- Filters

  { name = '2xSaI Level 2', frag = 'shader/fragment/2xsai-level2.frag', antiAliasing = AntiAliasing.disabled },
  { name = '2xSaI', frag = 'shader/fragment/2xsai.frag', antiAliasing = AntiAliasing.disabled },
  { name = 'Anti-Aliasing Retro' }, -- No fragment
  { name = 'Anti-Aliasing', antiAliasing = AntiAliasing.enabled }, -- No fragment
  { name = 'No Anti-Aliasing', antiAliasing = AntiAliasing.disabled }, -- No fragment

  -- Shaders

  { name = 'Bloom', frag = 'shader/fragment/bloom.frag' },
  { name = 'Fog', frag = 'shader/fragment/fog.frag', tex1 = 'shader/images/clouds' },
  { name = 'Grayscale', frag = 'shader/fragment/grayscale.frag' },
  { name = 'Heat', frag = 'shader/fragment/heat.frag', drawViewportEdge = true },
  { name = 'Negative', frag = 'shader/fragment/negative.frag' },
  { name = 'Negative Grayscale', frag = 'shader/fragment/negative-grayscale.frag' },
  { name = 'Night', frag = 'shader/fragment/night.frag' }, -- Original name: Linearize
  { name = 'Noise', frag = 'shader/fragment/noise.frag' },
  { name = 'Old Tv', frag = 'shader/fragment/oldtv.frag' },
  { name = 'Painting', frag = 'shader/fragment/painting.frag', antiAliasing = AntiAliasing.disabled },
  { name = 'PAL', frag = 'shader/fragment/pal.frag' }, -- Original name: pal-singlepass (Phase Alternating Line)
  { name = 'Party', frag = 'shader/fragment/party.frag' },
  { name = 'Pulse', frag = 'shader/fragment/pulse.frag', drawViewportEdge = true },
  { name = 'Radial Blur', frag = 'shader/fragment/radialblur.frag', drawViewportEdge = true },
  { name = 'Sepia', frag = 'shader/fragment/sepia.frag' },
  { name = 'Snow', frag = 'shader/fragment/snow.frag', tex1 = 'shader/images/snow' },
  { name = 'Water', frag = 'shader/fragment/water.frag' },
  { name = 'Zomg', frag = 'shader/fragment/zomg.frag', drawViewportEdge = true },
}

OutfitShaders = {
  { name = 'None' }, -- No fragment
  { name = 'Bloom', frag = 'shader/fragment/bloom.frag' },
  { name = 'Bloom Grayscale', frag = 'shader/fragment/bloom.frag', drawColor = false },
  { name = 'Heat', frag = 'shader/fragment/heat.frag' },
  { name = 'Negative', frag = 'shader/fragment/negative.frag' },
  { name = 'Negative Grayscale', frag = 'shader/fragment/negative-grayscale.frag' },
  { name = 'Invisible', frag = 'shader/fragment/negative-grayscale.frag', drawColor = false },
  { name = 'Noise', frag = 'shader/fragment/noise.frag' },
  { name = 'Party', frag = 'shader/fragment/party.frag' },
  { name = 'Radial Blur Grayscale', frag = 'shader/fragment/radialblur.frag', drawColor = false },
  { name = 'Water', frag = 'shader/fragment/water.frag' },
}

MountShaders = {
  { name = 'None' }, -- No fragment
  { name = 'Bloom', frag = 'shader/fragment/bloom.frag' },
  { name = 'Negative Grayscale', frag = 'shader/fragment/negative-grayscale.frag' },
  { name = 'Noise', frag = 'shader/fragment/noise.frag' },
  { name = 'Party', frag = 'shader/fragment/party.frag' },
  { name = 'Radial Blur', frag = 'shader/fragment/radialblur.frag' },
}

ItemShaders = {
  { name = 'None' }, -- No fragment
  { name = 'Bloom', frag = 'shader/fragment/bloom.frag' },
  { name = 'Negative Grayscale', frag = 'shader/fragment/negative-grayscale.frag' },
  { name = 'Party', frag = 'shader/fragment/party.frag' },
  { name = 'Radial Blur', frag = 'shader/fragment/radialblur.frag' },
}

WidgetShaders = {
  { name = 'None' }, -- No fragment
  { name = 'Angular', frag = 'shader/fragment/angular.frag', uniforms = { [ShaderUniforms.Progress] = 'u_progress' } },
}

local function registerShader(shaderData, namePrefix, setupCallback)
  local fragmentShaderPath = resolvepath(shaderData.frag)
  -- local vertexShaderPath   = resolvepath(shaderData.frag ~= nil and shaderData.vert or "shader/core/vertex/default.vert")

  if fragmentShaderPath then
    local name = namePrefix .. ' - ' .. shaderData.name
    g_shaders.createFragmentShader(name, shaderData.frag)

    -- Add as many textures you want
    local textureId = 1
    while shaderData['tex' .. textureId] do
      g_shaders.addMultiTexture(name, resolvepath(shaderData['tex' .. textureId]))
      textureId = textureId + 1
    end

    -- Setup proper uniforms
    g_shaders[setupCallback](name, shaderData.uniforms or { })
  end
end

-- Map
for _, shaderData in ipairs(MapShaders) do
  registerShader(shaderData, 'Map', 'setupMapShader')
end

-- Outfit
for _, shaderData in ipairs(OutfitShaders) do
  registerShader(shaderData, 'Outfit', 'setupOutfitShader')
end

-- Mount
for _, shaderData in ipairs(MountShaders) do
  registerShader(shaderData, 'Mount', 'setupMountShader')
end

-- Item
for _, shaderData in ipairs(ItemShaders) do
  registerShader(shaderData, 'Item', 'setupItemShader')
end

-- Widget
for _, shaderData in ipairs(WidgetShaders) do
  registerShader(shaderData, 'Widget', 'setupWidgetShader')
end
