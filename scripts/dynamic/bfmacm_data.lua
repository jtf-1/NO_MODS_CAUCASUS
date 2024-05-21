env.info( "[JTF-1] bfmacm_data" )
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- ACM/BFM
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER missiletrainer.lua
--
-- These values are specific to the miz and will override the default values in missiletrainer.lua
--

-- Error prevention. Create empty container if module core lua not loaded.
if not BFMACM then 
	_msg = "[JTF-1 BFMACM] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	BFMACM = {}
end

BFMACM.zoneBfmAcmName = "ZONE_BFMACM" -- The BFM/ACM Zone
BFMACM.zonesNoSpawnName = { -- zones inside BFM/ACM zone within which adversaries may NOT be spawned.
} 

BFMACM.adversary = {
    menu = { -- Adversary menu
		{template = "ADV_MIG21", menuText = "Adversary MiG-21"},
		{template = "ADV_MIG29", menuText = "Adversary MiG-29S"},
		{template = "ADV_SU27", menuText = "Adversary Su-27"},
		{template = "ADV_F16", menuText = "Adversary F-16"},
		{template = "ADV_F18", menuText = "Adversary F-18"},
    },
    range = {5, 10, 20}, -- ranges at which to spawn adversaries in nautical miles
    spawn = {}, -- container for aversary spawn objects
    defaultRadio = "251",
}


if BFMACM.Start then
	BFMACM:Start()
end