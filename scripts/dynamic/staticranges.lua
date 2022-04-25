-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN STATIC RANGE SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- @field #STATICRANGES
local STATICRANGES = {}

STATICRANGES.Defaults = {
  strafeMaxAlt             = 1530, -- [5000ft] in metres. Height of strafe box.
  strafeBoxLength          = 3000, -- [10000ft] in metres. Length of strafe box.
  strafeBoxWidth           = 300, -- [1000ft] in metres. Width of Strafe pit box (from 1st listed lane).
  strafeFoullineDistance   = 610, -- [2000ft] in metres. Min distance for from target for rounds to be counted.
  strafeGoodPass           = 20, -- Min hits for a good pass.
  rangeSoundFilesPath      = "Range Soundfiles/" -- Range sound files path in miz
}

-- Range targets table
STATICRANGES.Ranges = {
  { --RANGE GG33 START
    rangeId               = "GG33",
    rangeName             = "Range GG33",
    rangeZone             = "GG33",
    rangeControlFrequency = 250.000,
    groups = {
      "GG33_TAC_GROUP_01",
      "GG33_TAC_GROUP_02",
    },
    units = {
    },
    strafepits = {
    },
  },--RANGE GG33 END
  { --RANGE NL24 START
    rangeId               = "NL24",
    rangeName             = "Range NL24",
    rangeZone             = "NL24",
    rangeControlFrequency = 250.000,
    groups = {
      "NL24_TAC_GROUP_01",
      "NL24_TAC_GROUP_02",
      "NL24_TAC_GROUP_03",
    },
    units = {
    },
    statics = {
      "NL24_STATIC_01",
      "NL24_STATIC_02",
      "NL24_STATIC_03",
      "NL24_STATIC_04",
      "NL24_STATIC_05",
      "NL24_STATIC_06",
      "NL24_STATIC_07",
    },
    strafepits = {
    },
  },--RANGE NL24 END
}


function STATICRANGES:AddStaticRanges(TableRanges)

  for rangeIndex, rangeData in ipairs(TableRanges) do
  
    local rangeObject = "Range_" .. rangeData.rangeId

    local range_zone = ( ZONE:FindByName(rangeData.rangeZone) and ZONE:FindByName(rangeData.rangeZone) or ZONE_POLYGON:FindByName(rangeData.rangeZone))
    
    self[rangeObject] = RANGE:New(rangeData.rangeName)
    self[rangeObject]:DebugOFF()
    self[rangeObject]:SetMaxStrafeAlt(self.Defaults.strafeMaxAlt)
    self[rangeObject]:SetDefaultPlayerSmokeBomb(false)

    if range_zone then
      self[rangeObject]:SetRangeZone(range_zone)
    end
 
    if rangeData.groups ~= nil then -- add groups of targets
      for tgtIndex, tgtName in ipairs(rangeData.groups) do
        local tgtGroup = GROUP:FindByName(tgtName)
        tgtGroup:SetAIOff()
        self[rangeObject]:AddBombingTargetGroup(GROUP:FindByName(tgtName))
      end
    end
    
    if rangeData.units ~= nil then -- add individual targets
      for tgtIndex, tgtName in ipairs(rangeData.units) do
        local tgtUnit = UNIT:FindByName(tgtName)
        local tgtGroup = tgtUnit:GetGroup()
        tgtGroup:SetAIOff()
      end
      self[rangeObject]:AddBombingTargets( rangeData.units )
    end
    
    if rangeData.statics ~= nil then -- add individual static targets
      self[rangeObject]:AddBombingTargets( rangeData.statics )
    end

    if rangeData.strafepits ~= nil then -- add strafe targets
      for strafepitIndex, strafepit in ipairs(rangeData.strafepits) do
        self[rangeObject]:AddStrafePit(strafepit, self.Defaults.strafeBoxLength, self.Defaults.strafeBoxWidth, nil, true, self.Defaults.strafeGoodPass, self.Defaults.strafeFoullineDistance)
      end  
    end
    
    if rangeData.rangeControlFrequency ~= nil then
      
    end

    self[rangeObject]:Start()
  end

end

-- Create ranges
STATICRANGES:AddStaticRanges(STATICRANGES.Ranges)

--- END STATIC RANGES