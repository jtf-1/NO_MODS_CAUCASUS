env.info( "*** JTF-1 MOOSE MISSION SCRIPT START ***" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN INIT
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


---- remove default MOOSE player menu
_SETTINGS:SetPlayerMenuOff()

--- debug on/off
BASE:TraceOnOff(false) 

JTF1 = {
    missionRestart = "ADMIN9999", -- Message to trigger mission restart via jtf1-hooks
    flagLoadMission = 9999, -- flag for load misison trigger
}
--- END INIT

-- ---- remove default MOOSE player menu
-- _SETTINGS:SetPlayerMenuOff()

-- --- debug on/off
-- BASE:TraceOnOff(false) 
-- if BASE:IsTrace() then
--   BASE:TraceLevel(1)
--   --BASE:TraceAll(true)
--   BASE:TraceClass("setGroupGroundActive")
-- end

-- JTF = {}
-- --- activate admin menu option in admin slots if true
-- JtfAdmin = true 

-- -- mission flag for triggering reload/loading of missions
-- flagLoadMission = 9999

-- -- value for triggering loading of base mission
-- flagBaseMissionValue = 1

-- -- value for triggering loading of dev mission
-- flagDevMissionValue = 99

-- --- Name of client unit used for admin control
-- adminUnitName = "XX_" -- string to locate within unit name for admin slots

-- --- Dynamic list of all clients
-- --JTF.SetClient = SET_CLIENT:New():FilterStart()

-- -- flag value to trigger reloading of DEV mission
-- devMission = 99

-- --- END INIT