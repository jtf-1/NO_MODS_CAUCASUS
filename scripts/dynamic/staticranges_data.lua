env.info( "[JTF-1] staticranges_data" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- STATIC RANGES SETTINGS FOR MIZ
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER staticranges.lua
--
-- These values are specific to the miz and will override the default values in STATICRANGES.default
--

-- Error prevention. Create empty container if module core lua not loaded.
if not STATICRANGES then 
	_msg = "[JTF-1 STATICRANGES] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	STATICRANGES = {}
end

-- These values will overrides the default values in staticranges.lua
STATICRANGES.strafeMaxAlt             = 1530 -- [5000ft] in metres. Height of strafe box.
STATICRANGES.strafeBoxLength          = 3000 -- [10000ft] in metres. Length of strafe box.
STATICRANGES.strafeBoxWidth           = 300 -- [1000ft] in metres. Width of Strafe pit box (from 1st listed lane).
STATICRANGES.strafeFoullineDistance   = 610 -- [2000ft] in metres. Min distance for from target for rounds to be counted.
STATICRANGES.strafeGoodPass           = 20 -- Min hits for a good pass.

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
    
-- Start the STATICRANGES module
if STATICRANGES.Start then
	STATICRANGES:Start()
end