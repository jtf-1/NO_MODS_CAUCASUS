env.info( '*** MISSION FILE BUILD DATE: 2022-06-20T12:17:47.92Z ***') 
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
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Check for Static or Dynamic mission file loading flag
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- mission flag for setting dev mode
local devFlag = 8888

-- If missionflag is true, mission file will load from filesystem with an assert
local devState = trigger.misc.getUserFlag(devFlag)

if devState == 1 then
  env.warning('[JTF-1] *** JTF-1 - DEV flag is ON! ***')
  MESSAGE:New("Dev Mode is ON!"):ToAll()
  DEV_MENU = {
    traceOn = true, -- default tracestate false == trace off, true == trace on.
    flagLoadMission = (JTF1.flagLoadMission and JTF1.flagLoadMission or 9999), -- flag for load misison trigger
    missionRestartMsg = (JTF1.missionRestartMsg and JTF1.missionRestartMsg or "ADMIN9999"), -- Message to trigger mission restart via jtf1-hooks
  }
  
  function DEV_MENU:toggleTrace(traceOn)
    if traceOn then
      BASE:TraceOff()
    else
      BASE:TraceOn()
    end
    self.traceOn = not traceOn
  end

  function DEV_MENU:testLua()
    local base = _G
    local f = assert( base.loadfile( 'E:/GitHub/FUN-MAP_CAUCASUS/scripts/dynamic/test.lua' ) )
    if f == nil then
                        error ("Mission Loader: could not load test.lua." )
                else
                        env.info( "[JTF-1] Mission Loader: test.lua dynamically loaded." )
                        --return f()
                end
  end

  function DEV_MENU:restartMission()
    trigger.action.setUserFlag(ADMIN.flagLoadMission, 99)
  end

  -- Add Dev submenu to F10 Other
  DEV_MENU.topmenu = MENU_MISSION:New("DEVMENU")
  MENU_MISSION_COMMAND:New("Toggle TRACE.", DEV_MENU.topmenu, DEV_MENU.toggleTrace, DEV_MENU, DEV_MENU.traceOn)
  MENU_MISSION_COMMAND:New("Reload Test LUA.", DEV_MENU.topmenu, DEV_MENU.testLua)
  MENU_MISSION_COMMAND:New("Restart Mission", DEV_MENU.topmenu, DEV_MENU.restartMission)

  -- trace all events
  BASE:TraceAll(true)

  if DEV_MENU.traceOn then
    BASE:TraceOn()
  end  

else
  env.info('[JTF-1] *** JTF-1 - DEV flag is OFF. ***')
end

--- END DEVCHECK
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Default SRS Text-to-Speech
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Send messages through SRS using STTS
-- Script will try to load the file specified with LocalServerConfigFile [name of settings file] 
-- and LocalServerConfigPath [path to file]. This file should define the path to the SRS installation 
-- directory and the port used by the DCS server instance running the mission. 
--
-- If the settings file is not found, the defaults for srs_path and srs_port will be used.
--
-- Message text will be formatted as a SOUNDTEXT object.
-- 
-- Use MISSIONSRS:SendRadio() to transmit on SRS
--
-- msgText        - [required] STRING. Text of message. Can be plain text or a MOOSE SOUNDTEXT obkect
-- msfFreqs       - [optional] STRING. frequency, or table of frequencies (without any spaces). Default freqs AND modulations will be applied if this is not specified.
-- msgModulations - [optional] STRING. modulation, or table of modulations (without any spaces) if multiple freqs passed. Ignored if msgFreqs is not defined. Default modulations will be applied if this is not specified
--


MISSIONSRS = {
  fileName = "ServerLocalSettings.lua",                           -- name of file containing local server settings
  LocalServerConfigPath = nil,                                    -- path to server srs settings. nil if file is in root of server's savedgames profile.
  LocalServerConfigFile = "LocalServerSettings.txt",              -- srs server settings file name
  defaultSrsPath = "C:/Program Files/DCS-SimpleRadio-Standalone", -- default path to SRS install directory if setting file is not avaialable "C:/Program Files/DCS-SimpleRadio-Standalone"
  defaultSrsPort = 5002,                                          -- default SRS port to use if settings file is not available
  defaultText = "No Message Defined!",                            -- default message if text is nil
  defaultFreqs = "243,251,30",                          -- transmit on guard, CTAF and 30FM as default frequencies
  defaultModulations = "AM,AM,FM",                          -- default modulation (count *must* match qty of freqs)
  defaultVol = "1.0",                                             -- default to full volume
  defaultName = "Server",                                         -- default to server as sender
  defaultCoalition = 0,                                           -- default to spectators
  defaultVec3 = nil,                                              -- point from which transmission originates
  defaultSpeed = 2,                                               -- speed at which message should be played
  defaultGender = "female",                                       -- default gender of sender
  defaultCulture = "en-US",                                       -- default culture of sender
  defaultVoice = "",                                              -- default voice to use
}

function MISSIONSRS:LoadSettings()
  local loadFile  = self.LocalServerConfigFile
  if UTILS.CheckFileExists(self.LocalServerConfigPath, self.LocalServerConfigFile) then
    local loadFile, serverSettings = UTILS.LoadFromFile(self.LocalServerConfigPath, self.LocalServerConfigFile)
    BASE:T({"[MISSIONSRS] Load Server Settings",{serverSettings}})
    if not loadFile then
      BASE:E(string.format("[MISSIONSRS] ERROR: Could not load %s", loadFile))
    else
      self.SRS_DIRECTORY = serverSettings[1] or self.defaultSrsPath
      self.SRS_PORT = serverSettings[2] or self.defaultSrsPort
      self:AddRadio()
      BASE:T({"[MISSIONSRS]",{self}})
    end
  else
    BASE:E(string.format("[MISSIONSRS] ERROR: Could not find %s", loadFile))
  end
end

function MISSIONSRS:AddRadio()
  self.Radio = MSRS:New(self.SRS_DIRECTORY, self.defaultFreqs, self.defaultModulations)
  self.Radio:SetPort(self.SRS_PORT)
  self.Radio:SetGender(self.defaultGender)
  self.Radio:SetCulture(self.defaultCulture)
  self.Radio.name = self.defaultName
end

function MISSIONSRS:SendRadio(msgText, msgFreqs, msgModulations)

  BASE:T({"[MISSIONSRS] SendRadio", {msgText}, {msgFreqs}, {msgModulations}})
  if msgFreqs then
    BASE:T("[MISSIONSRS] tx with freqs change.")
    if msgModulations then
      BASE:T("[MISSIONSRS] tx with mods change.")
    end
  end
  if msgText == (nil or "") then 
    msgText = self.defaultText
  end
  local text = msgText
  local tempFreqs = (msgFreqs or self.defaultFreqs)
  local tempModulations = (msgModulations or self.defaultModulations)
  if not msgText.ClassName then
    BASE:T("[MISSIONSRS] msgText NOT SoundText object.")
    text = SOUNDTEXT:New(msgText) -- convert msgText to SOundText object
  end
  self.Radio:SetFrequencies(tempFreqs)
  self.Radio:SetModulations(tempModulations)
  self.Radio:PlaySoundText(text)
  self.Radio:SetFrequencies(self.defaultFreqs) -- reset freqs to default
  self.Radio:SetModulations(self.defaultModulations) -- rest modulation to default

end


MISSIONSRS:LoadSettings()

 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ADMIN MENU SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Admin menu
--
-- Add F10 command menus for selecting a mission to load, or restarting the current mission.
--
-- In the Mission Editor, add (a) switched condition trigger(s) with a 
-- FLAG EQUALS condition, where flag number is ADMIN.flagLoadMission value
-- and flag value is the ADMIN.missionList[x].missionFlagValue (see below).
-- A missionFlagValue == 0 is used to trigger restart of the current
-- mission using jtf1-hooks.lua.
--
-- If the menu should only appear for restricted client slots, set
-- ADMIN.menuAllSlots to FALSE and add a client slot with the group name
-- *prefixed* with the value set in ADMIN.adminMenuName.
--
-- If the menu should be available in all mission slots, set ADMIN.menuAllSlots
-- to TRUE.
--
-- 

ADMIN = EVENTHANDLER:New()
ADMIN:HandleEvent(EVENTS.PlayerEnterAircraft)

ADMIN.adminUnitName = "XX_" -- String to locate within unit name for admin slots
ADMIN.missionRestart = (JTF1.missionRestart and JTF1.missionRestart or "ADMIN9999") -- Message to trigger mission restart via jtf1-hooks
ADMIN.flagLoadMission = 9999
ADMIN.menuAllSlots = false -- Set to true for admin menu to appear for all players

ADMIN.missionList = { -- List of missions for load mission menu commands
  {menuText = "Restart current mission", missionFlagValue = 0},
  {menuText = "Load DAY Caucasus", missionFlagValue = 1},
  {menuText = "Load NIGHT Caucasus", missionFlagValue = 2},
  {menuText = "Load WEATHER DAY Caucasus", missionFlagValue = 3},
  {menuText = "Load WEATHER NIGHT Caucasus", missionFlagValue = 4},
}

function ADMIN:GetPlayerUnitAndName(unitName)
  if unitName ~= nil then
    -- Get DCS unit from its name.
    local DCSunit = Unit.getByName(unitName)
    if DCSunit then
      local playername=DCSunit:getPlayerName()
      local unit = UNIT:Find(DCSunit)
      if DCSunit and unit and playername then
        return unit, playername
      end
    end
  end
  -- Return nil if we could not find a player.
  return nil,nil
end

function ADMIN:OnEventPlayerEnterAircraft(EventData)
  if not ADMIN.menuAllSlots then
    local unitName = EventData.IniUnitName
    local unit, playername = ADMIN:GetPlayerUnitAndName(unitName)
    if unit and playername then
      local adminCheck = (string.find(unitName, ADMIN.adminUnitName) and "true" or "false")
      if string.find(unitName, ADMIN.adminUnitName) then
        SCHEDULER:New(nil, ADMIN.BuildAdminMenu, {self, unit, playername}, 0.5)
      end
    end
  end
end

--- Set mission flag to load a new mission.
--- If mapFlagValue is current mission, restart the mission via jtf1-hooks
-- @param #string playerName Name of client calling restart command.
-- @param #number mapFlagValue Mission number to which flag should be set.
function ADMIN:LoadMission(playerName, mapFlagValue)
  if playerName then
    env.info("[JTF-1] ADMIN Restart player name: " .. playerName)
  end
  if mapFlagValue == 0 then -- use jtf1-hooks to restart current mission
    MESSAGE:New(ADMIN.missionRestart):ToAll()
  else
    trigger.action.setUserFlag(ADMIN.flagLoadMission, mapFlagValue)
  end
end

--- Add admin menu and commands if client is in an ADMIN spawn
-- @param #object unit Unit of player.
-- @param #string playername Name of player
function ADMIN:BuildAdminMenu(unit,playername)
  if not (unit or playername) then
    -- create menu at Mission level
    local adminMenu = MENU_MISSION:New("Admin")
    for i, menuCommand in ipairs(ADMIN.missionList) do
      MENU_MISSION_COMMAND:New( menuCommand.menuText, adminMenu, ADMIN.LoadMission, self, playername, menuCommand.missionFlagValue )
    end
  else
    -- Create menu for admin slot
    local adminGroup = unit:GetGroup()
    local adminMenu = MENU_GROUP:New(adminGroup, "Admin")
    local testMenu = MENU_GROUP:New(adminGroup, "Test", adminMenu)
    for i, menuCommand in ipairs(ADMIN.missionList) do
      MENU_GROUP_COMMAND:New( adminGroup, menuCommand.menuText, adminMenu, ADMIN.LoadMission, self, playername, menuCommand.missionFlagValue )
      MENU_GROUP_COMMAND:New( adminGroup, "SRS Broadcast test", testMenu, MISSIONSRS.SendRadio, MISSIONSRS, "All Players, test broadcast over default radio.")
    end
  end
end

if ADMIN.menuAllSlots then
  ADMIN:BuildAdminMenu()
end

--- END ADMIN MENU SECTION
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MISSION TIMER
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Mission Timer
--
-- Add schedules to display messages at set intervals prior to restarting the base mission.
-- ME switched triggers should be set to a FLAG EQUALS condition for the flag flagLoadMission
-- value (defined in script header). Sending missionRestart text will trigger restarting the
-- current mission via jtf1-hooks.lua.
--

MISSIONTIMER = {
  durationHrs = 9, -- Mission run time in HOURS
  msgSchedule = {60, 30, 10, 5}, -- Schedule for mission restart warning messages. Time in minutes.
  msgWarning = {}, -- schedule container
  missionRestart = ( JTF1.missionRestart and JTF1.missionRestart or "ADMIN9999" ), -- Message to trigger mission restart via jtf1-hooks
  restartDelay =  4, -- time in minutes to delay restart if active clients are present.
}

MISSIONTIMER.durationSecs = MISSIONTIMER.durationHrs * 3600 -- Mission run time in seconds

BASE:T({"[MISSIONTIMER]",{MISSIONTIMER}})

--- add scheduled messages for mission restart warnings and restart at end of mission duration
function MISSIONTIMER:AddSchedules()
  if self.msgSchedule ~= nil then
    for i, msgTime in ipairs(self.msgSchedule) do
      self.msgWarning[i] = SCHEDULER:New( nil, 
        function()
          BASE:T("[MISSIONTIMER] TIMER WARNING CALLED at " .. tostring(msgTime) .. " minutes remaining.")
          local msg = "All Players, mission is scheduled to restart in  " .. msgTime .. " minutes!"
          if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
            MISSIONSRS:SendRadio(msg)
          else -- otherwise, send in-game text message
            MESSAGE:New(msg):ToAll()
          end
        end,
      {msgTime}, self.durationSecs - (msgTime * 60))
    end
  end
  self.msgWarning["restart"] = SCHEDULER:New( nil,
    function()
      MISSIONTIMER:Restart()
    end,
    { }, self.durationSecs)
end

function MISSIONTIMER:Restart()
  if not self.clientList then
    self.clientList = SET_CLIENT:New()
    self.clientList:FilterActive()
    self.clientList:FilterStart()
  end
  if self.clientList:CountAlive() > 0 then
    local delayTime = self.restartDelay
    local msg  = "All Players, mission will restart when no active clients are present. Next check will be in " .. tostring(delayTime) .." minutes." 
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS:SendRadio(msg)
    else -- otherwise, send in-game text message
      MESSAGE:New(msg):ToAll()
    end
    self.msgWarning["restart"] = SCHEDULER:New( nil,
      function()
        MISSIONTIMER:Restart()
      end,
      { }, (self.restartDelay * 60))
  else
    BASE:T("[MISSIONTIMER] RESTART MISSION")
    MESSAGE:New(self.missionRestart):ToAll()
  end
end

MISSIONTIMER:AddSchedules()

--- END MISSION TIMER
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MISSILE TRAINER
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MTRAINER = {
  menuadded = {},
  MenuF10   = {},
  safeZone = nil, -- safezone to use, otherwise nil --"ZONE_FOX"
  launchZone = nil, -- launchzone to use, otherwise nil --"ZONE_FOX"
  DefaultLaunchAlerts = false,
  DefaultMissileDestruction = false,
  DefaultLaunchMarks = false,
  ExplosionDistance = 300,
}
-- Create MTRAINER container and defaults

-- add event handler
MTRAINER.eventHandler = EVENTHANDLER:New()
MTRAINER.eventHandler:HandleEvent(EVENTS.PlayerEnterAircraft)
MTRAINER.eventHandler:HandleEvent(EVENTS.PlayerLeaveUnit)

-- check player is present and unit is alive
function MTRAINER:GetPlayerUnitAndName(unitname)
  if unitname ~= nil then
    local DCSunit = Unit.getByName(unitname)
    if DCSunit then
      local playername=DCSunit:getPlayerName()
      local unit = UNIT:Find(DCSunit)
      if DCSunit and unit and playername then
        return unit, playername
      end
    end
  end
  -- Return nil if we could not find a player.
  return nil,nil
end

-- add new FOX class to the Missile Trainer
MTRAINER.fox = FOX:New()

--- FOX Default Settings
MTRAINER.fox:SetDefaultLaunchAlerts(MTRAINER.DefaultLaunchAlerts)
MTRAINER.fox:SetDefaultMissileDestruction(MTRAINER.DefaultMissileDestruction)
MTRAINER.fox:SetDefaultLaunchMarks(MTRAINER.DefaultLaunchMarks)
MTRAINER.fox:SetExplosionDistance(MTRAINER.ExplosionDistance)
MTRAINER.fox:SetDebugOnOff()
MTRAINER.fox:SetDisableF10Menu()

-- zone in which players will be protected
if MTRAINER.safeZone then
  MTRAINER.fox:AddSafeZone(ZONE:New(MTRAINER.safeZone))
end

-- zone in which launches will be tracked
if MTRAINER.launchZone then
  MTRAINER.fox:AddLaunchZone(ZONE:New(MTRAINER.launchZone))
end

-- start the missile trainer
MTRAINER.fox:Start()

--- Toggle Launch Alerts and Destroy Missiles on/off
-- @param #string unitname name of client unit
function MTRAINER:ToggleTrainer(unitname)
  self.fox:_ToggleLaunchAlert(unitname)
  self.fox:_ToggleDestroyMissiles(unitname)
end

--- Add Missile Trainer for GROUP|UNIT in F10 root menu.
-- @param #string unitname Name of unit occupied by client
function MTRAINER:AddMenu(unitname)
  local unit, playername = self:GetPlayerUnitAndName(unitname)
  if unit and playername then
    local group = unit:GetGroup()
    local gid = group:GetID()
    local uid = unit:GetID()
    if group and gid then
      -- only add menu once!
      if MTRAINER.menuadded[uid] == nil then
        -- add GROUP menu if not already present
        if MTRAINER.MenuF10[gid] == nil then
          BASE:T("[MTRAINER] Adding menu for group: " .. group:GetName())
          MTRAINER.MenuF10[gid] = MENU_GROUP:New(group, "Missile Trainer")
        end
        if MTRAINER.MenuF10[gid][uid] == nil then
          BASE:T("[MTRAINER] Add submenu for player: " .. playername)
          MTRAINER.MenuF10[gid][uid] = MENU_GROUP:New(group, playername, MTRAINER.MenuF10[gid])
          BASE:T("[MTRAINER] Add commands for player: " .. playername)
          MENU_GROUP_COMMAND:New(group, "Missile Trainer On/Off", MTRAINER.MenuF10[gid][uid], MTRAINER.ToggleTrainer, MTRAINER, unitname)
          MENU_GROUP_COMMAND:New(group, "My Status", MTRAINER.MenuF10[gid][uid], MTRAINER.fox._MyStatus, MTRAINER.fox, unitname)
        end
        MTRAINER.menuadded[uid] = true
      end
    else
      BASE:T(string.format("[MTRAINER] ERROR: Could not find group or group ID in AddMenu() function. Unit name: %s.", unitname))
    end
  else
    BASE:T(string.format("[MTRAINER] ERROR: Player unit does not exist in AddMenu() function. Unit name: %s.", unitname))
  end
end

-- handler for PlayEnterAircraft event.
-- call function to add GROUP:UNIT menu.
function MTRAINER.eventHandler:OnEventPlayerEnterAircraft(EventData) 
  local unitname = EventData.IniUnitName
  local unit, playername = MTRAINER:GetPlayerUnitAndName(unitname)
  if unit and playername then
    SCHEDULER:New(nil, MTRAINER.AddMenu, {MTRAINER, unitname, true},0.1)
  end
end

-- handler for PlayerLeaveUnit event.
-- remove GROUP:UNIT menu.
function MTRAINER.eventHandler:OnEventPlayerLeaveUnit(EventData)
  local playername = EventData.IniPlayerName
  local unit = EventData.IniUnit
  local gid = EventData.IniGroup:GetID()
  local uid = EventData.IniUnit:GetID()
  BASE:T("[MTRAINER] " .. playername .. " left unit:" .. unit:GetName() .. " UID: " .. uid)
  if gid and uid then
    if MTRAINER.MenuF10[gid] then
      BASE:T("[MTRAINER] Removing menu for unit UID:" .. uid)
      MTRAINER.MenuF10[gid][uid]:Remove()
      MTRAINER.MenuF10[gid][uid] = nil
      MTRAINER.menuadded[uid] = nil
    end
  end
end

--- END MISSILE TRAINER
 
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
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ELECTRONIC COMBAT SIMULATOR RANGE
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- IADS
-- REQUIRES MIST if IADS is used

ECS = {}
ECS.ActiveSite = {}
ECS.rIADS = nil
ECS.UseIads = false -- NOTE*** requires MIST if Skynet is used

ECS.menuEscTop = MENU_COALITION:New(coalition.side.BLUE, "ECS")

-- SAM spawn emplates
ECS.templates = {
  {templateName = "ECS_SA11", threatName = "SA-11"},
  {templateName = "ECS_SA10", threatName = "SA-10"},
  {templateName = "ECS_SA2",  threatName = "SA-2"},
  {templateName = "ECS_SA3",  threatName = "SA-3"},
  {templateName = "ECS_SA6",  threatName = "SA-6"},
}
-- Zone in which threat will be spawned
ECS.zoneEcs = ZONE:FindByName("ECS_ZONE_1")


function activateEcsThreat(samTemplate, samZone, activeThreat, isReset)

  -- remove threat selection menu options
  if not isReset then
    ECS.menuEscTop:RemoveSubMenus()
  end
  
  -- spawn threat in ECS zone
  local ecsSpawn = SPAWN:New(samTemplate)
  ecsSpawn:OnSpawnGroup(
      function (spawnGroup)
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Deactivate ECS", ECS.menuEscTop, resetEcsThreat, spawnGroup, ecsSpawn, activeThreat, false)
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Reset ECS", ECS.menuEscTop, resetEcsThreat, spawnGroup, ecsSpawn, activeThreat, true, samZone)
        local msg = "All Players, Electronic Combat Simulator Range is active with " .. activeThreat
        if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
          MISSIONSRS:SendRadio(msg)
        else -- otherwise, send in-game text message
          MESSAGE:New(msg):ToAll()
        end
        --MESSAGE:New("EC South is active with " .. activeThreat):ToAll()
        if ECS.UseIads then
          ECS.rIADS = SkynetIADS:create("IadsECS")
          ECS.rIADS:setUpdateInterval(5)
          ECS.rIADS:addSAMSite(spawnGroup.GroupName)
          ECS.rIADS:getSAMSiteByGroupName(spawnGroup.GroupName):setGoLiveRangeInPercent(80)
          ECS.rIADS:activate()
        end        
      end
      , ECS.menuEscTop, ecsSpawn, activeThreat, samZone --, rangePrefix
    )
    :SpawnInZone(samZone, true)
end

function resetEcsThreat(spawnGroup, ecsSpawn, activeThreat, refreshEcs, samZone)

  ECS.menuEscTop:RemoveSubMenus()
  
  if (ECS.UseIads and ECS.rIADS ~= nil) then
    ECS.rIADS:deactivate()
    ECS.rIADS = nil
  end

  if spawnGroup:IsAlive() then
    spawnGroup:Destroy()
  end

  if refreshEcs then
    ecsSpawn:SpawnInZone(samZone, true)
  else
   addEcsThreatMenu()
    local msg = "All Players, ECS "  .. activeThreat .." has been deactivated."
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS:SendRadio(msg)
    else -- otherwise, send in-game text message
      MESSAGE:New(msg):ToAll()
    end
    --MESSAGE:New("EC South "  .. activeThreat .." has been deactived."):ToAll()
  end    

end

function addEcsThreatMenu()

  for i, template in ipairs(ECS.templates) do
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate " .. template.threatName, ECS.menuEscTop, activateEcsThreat, template.templateName, ECS.zoneEcs, template.threatName)
  end

end

addEcsThreatMenu()

--- END ELECTRONIC COMBAT SIMULATOR RANGE
 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ACM/BFM SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- AI ACM/BFM
--
-- ZONES: if zones are MOOSE polygon zones, zone name in mission editor MUST be suffixed with #ZONE_POLYGON
-- 

BFMACM = {
  menuAdded = {},
  menuF10 = {},
  zoneBfmAcmName = "ZONE_BFMACM", -- The BFM/ACM Zone
  zonesNoSpawnName = { -- zones inside BFM/ACM zone within which adversaries may NOT be spawned.
  },
  adversary = {
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
  },
}

BFMACM.rangeRadio = (JTF1.rangeRadio and JTF1.rangeRadio or BFMACM.defaultRadio)

-- add event handler
BFMACM.eventHandler = EVENTHANDLER:New()
BFMACM.eventHandler:HandleEvent(EVENTS.PlayerEnterAircraft)
BFMACM.eventHandler:HandleEvent(EVENTS.PlayerLeaveUnit)

-- check player is present and unit is alive
function BFMACM:GetPlayerUnitAndName(unitname)
  if unitname ~= nil then
    local DCSunit = Unit.getByName(unitname)
    if DCSunit then
      local playername=DCSunit:getPlayerName()
      local unit = UNIT:Find(DCSunit)
      if DCSunit and unit and playername then
        return unit, playername
      end
    end
  end
  -- Return nil if we could not find a player.
  return nil,nil
end

-- Add main BFMACM zone
 _zone = ( ZONE:FindByName(BFMACM.zoneBfmAcmName) and ZONE:FindByName(BFMACM.zoneBfmAcmName) or ZONE_POLYGON:FindByName(BFMACM.zoneBfmAcmName))
if _zone == nil then
  _msg = "[BFMACM] ERROR: BFM/ACM Zone: " .. tostring(BFMACM.zoneBfmAcmName) .. " not found!"
  BASE:E(_msg)
else
  BFMACM.zoneBfmAcm = _zone
  _msg = "[BFMACM] BFM/ACM Zone: " .. tostring(BFMACM.zoneBfmAcmName) .. " added."
  BASE:T(_msg)
end

-- Add spawn exclusion zone(s)
if BFMACM.zonesNoSpawnName then
  BFMACM.zonesNoSpawn = {}
  for i, zoneNoSpawnName in ipairs(BFMACM.zonesNoSpawnName) do
    _zone = (ZONE:FindByName(zoneNoSpawnName) and ZONE:FindByName(zoneNoSpawnName) or ZONE_POLYGON:FindByName(zoneNoSpawnName))
    if _zone == nil then
      _msg = "[BFMACM] ERROR: Exclusion zone: " .. tostring(zoneNoSpawnName) .. " not found!"
      BASE:E(_msg)
    else
      BFMACM.zonesNoSpawn[i] = _zone
      _msg = "[BFMACM] Exclusion zone: " .. tostring(zoneNoSpawnName) .. " added."
      BASE:T(_msg)
    end
  end
else
  BASE:T("[BFMACM] No exclusion zones defined")
end

-- Add spawn objects
for i, adversaryMenu in ipairs(BFMACM.adversary.menu) do
  _adv = GROUP:FindByName(adversaryMenu.template)
  if _adv then
    BFMACM.adversary.spawn[adversaryMenu.template] = SPAWN:New(adversaryMenu.template)
  else
    _msg = "[BFMACM] ERROR: spawn template: " .. tostring(adversaryMenu.template) .. " not found!" .. tostring(zoneNoSpawnName) .. " not found!"
    BASE:E(_msg)
  end
end

-- Spawn adversaries
function BFMACM.SpawnAdv(adv,qty,group,rng,unit)
  local playerName = (unit:GetPlayerName() and unit:GetPlayerName() or "Unknown") 
  local range = rng * 1852
  local hdg = unit:GetHeading()
  local pos = unit:GetPointVec2()
  local spawnPt = pos:Translate(range, hdg, true)
  local spawnVec3 = spawnPt:GetVec3()

  -- check player is in BFM ACM zone.
  local spawnAllowed = unit:IsInZone(BFMACM.zoneBfmAcm)
  local msgNoSpawn = ", Cannot spawn adversary aircraft if you are outside the BFM/ACM zone!"

  -- Check spawn location is not in an exclusion zone
  if spawnAllowed then
    if BFMACM.zonesNoSpawn then
      for i, zoneExclusion in ipairs(BFMACM.zonesNoSpawn) do
        spawnAllowed = not zoneExclusion:IsVec3InZone(spawnVec3)
      end
      msgNoSpawn = ", Cannot spawn adversary aircraft in an exclusion zone. Change course, or increase your range from the zone, and try again."
    end
  end

  -- Check spawn location is inside the BFM/ACM zone
  if spawnAllowed then
    spawnAllowed = BFMACM.zoneBfmAcm:IsVec3InZone(spawnVec3)
    msgNoSpawn = ", Cannot spawn adversary aircraft outside the BFM/ACM zone. Change course and try again."
  end

  -- Spawn the adversary, if not in an exclusion zone or outside the BFM/ACM zone.
  if spawnAllowed then
    BFMACM.adversary.spawn[adv]:InitGrouping(qty)
    :InitHeading(hdg + 180)
    :OnSpawnGroup(
      function ( SpawnGroup )
        local CheckAdversary = SCHEDULER:New( SpawnGroup, 
        function (CheckAdversary)
          if SpawnGroup then
            if SpawnGroup:IsNotInZone( BFMACM.zoneBfmAcm ) then
              local msg = "All Players, BFM Adversary left BFM Zone and was removed!"
              if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
                MISSIONSRS:SendRadio(msg,BFMACM.rangeRadio)
              else -- otherwise, send in-game text message
                MESSAGE:New(msg):ToAll()
              end
              --MESSAGE:New("Adversary left BFM Zone and was removed!"):ToAll()
              SpawnGroup:Destroy()
              SpawnGroup = nil
            end
          end
        end,
        {}, 0, 5 )
      end
    )
    :SpawnFromVec3(spawnVec3)
    local msg = "All Players, " .. playerName .. " has spawned BFM Adversary."
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS:SendRadio(msg,BFMACM.rangeRadio)
    else -- otherwise, send in-game text message
      MESSAGE:New(msg):ToAll()
    end
    --MESSAGE:New(playerName .. " has spawned Adversary."):ToGroup(group)
  else
    local msg = playerName .. msgNoSpawn
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS:SendRadio(msg,BFMACM.rangeRadio)
    else -- otherwise, send in-game text message
      MESSAGE:New(msg):ToAll()
    end
    --MESSAGE:New(playerName .. msgNoSpawn):ToGroup(group)
  end
end
  
function BFMACM:AddMenu(unitname)
  BASE:T("[BFMACM] AddMenu called.")
  local unit, playername = BFMACM:GetPlayerUnitAndName(unitname)
  if unit and playername then
    local group = unit:GetGroup()
    local gid = group:GetID()
    local uid = unit:GetID()
    if group and gid then
      -- only add menu once!
      if BFMACM.menuAdded[uid] == nil then
        -- add GROUP menu if not already present
        if BFMACM.menuF10[gid] == nil then
          BASE:T("[BFMACM] Adding menu for group: " .. group:GetName())
          BFMACM.menuF10[gid] = MENU_GROUP:New(group, "AI BFM/ACM")
        end
        if BFMACM.menuF10[gid][uid] == nil then
          -- add playername submenu
          BASE:T("[BFMACM] Add submenu for player: " .. playername)
          BFMACM.menuF10[gid][uid] = MENU_GROUP:New(group, playername, BFMACM.menuF10[gid])
          -- add adversary submenus and range selectors
          BASE:T("[BFMACM] Add submenus and range selectors for player: " .. playername)
          for iMenu, adversary in ipairs(BFMACM.adversary.menu) do
            -- Add adversary type menu
            BFMACM.menuF10[gid][uid][iMenu] = MENU_GROUP:New(group, adversary.menuText, BFMACM.menuF10[gid][uid])
            -- Add single or pair selection for adversary type
            BFMACM.menuF10[gid][uid][iMenu].single = MENU_GROUP:New(group, "Single", BFMACM.menuF10[gid][uid][iMenu])
            BFMACM.menuF10[gid][uid][iMenu].pair = MENU_GROUP:New(group, "Pair", BFMACM.menuF10[gid][uid][iMenu])
            -- select range at which to spawn adversary
            for iCommand, range in ipairs(BFMACM.adversary.range) do
                MENU_GROUP_COMMAND:New(group, tostring(range) .. " nm", BFMACM.menuF10[gid][uid][iMenu].single, BFMACM.SpawnAdv, adversary.template, 1, group, range, unit)
                MENU_GROUP_COMMAND:New(group, tostring(range) .. " nm", BFMACM.menuF10[gid][uid][iMenu].pair, BFMACM.SpawnAdv, adversary.template, 2, group, range, unit)
            end
          end
        end
        BFMACM.menuAdded[uid] = true
      end
    else
      BASE:T(string.format("[BFMACM] ERROR: Could not find group or group ID in AddMenu() function. Unit name: %s.", unitname))
    end
  else
    BASE:T(string.format("[BFMACM] ERROR: Player unit does not exist in AddMenu() function. Unit name: %s.", unitname))
  end
end
  
-- handler for PlayEnterAircraft event.
-- call function to add GROUP:UNIT menu.
function BFMACM.eventHandler:OnEventPlayerEnterAircraft(EventData)
  BASE:T("[BFMACM] PlayerEnterAircraft called.")
  local unitname = EventData.IniUnitName
  local unit, playername = BFMACM:GetPlayerUnitAndName(unitname)
  if unit and playername then
    BASE:T("[BFMACM] Player entered Aircraft: " .. playername)
    SCHEDULER:New(nil, BFMACM.AddMenu, {BFMACM, unitname},0.1)
  end
end

-- handler for PlayerLeaveUnit event.
-- remove GROUP:UNIT menu.
function BFMACM.eventHandler:OnEventPlayerLeaveUnit(EventData)
  local playername = EventData.IniPlayerName
  local unit = EventData.IniUnit
  local gid = EventData.IniGroup:GetID()
  local uid = EventData.IniUnit:GetID()
  BASE:T("[BFMACM] " .. playername .. " left unit:" .. unit:GetName() .. " UID: " .. uid)
  if gid and uid then
    if BFMACM.menuF10[gid] then
      BASE:T("[BFMACM] Removing menu for unit UID:" .. uid)
      BFMACM.menuF10[gid][uid]:Remove()
      BFMACM.menuF10[gid][uid] = nil
      BFMACM.menuAdded[uid] = nil
    end
  end
end

--- END ACMBFM SECTION
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MAIN
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- XXX BEGIN MENU DEFINITIONS



-- ## CAP CONTROL
MenuCapTop = MENU_COALITION:New( coalition.side.BLUE, " ENEMY CAP CONTROL" )
        MenuCapMaykop = MENU_COALITION:New( coalition.side.BLUE, "MAYKOP", MenuCapTop )
        MenuCapBeslan = MENU_COALITION:New( coalition.side.BLUE, "BESLAN", MenuCapTop )

-- ## GROUND ATTACK MISSIONS
MenuGroundTop = MENU_COALITION:New( coalition.side.BLUE, " GROUND ATTACK MISSIONS" )
        MenuCampAttack = MENU_COALITION:New( coalition.side.BLUE, " Camp Strike", MenuGroundTop )
        MenuConvoyAttack = MENU_COALITION:New( coalition.side.BLUE, " Convoy Strike", MenuGroundTop )
                MenuConvoyAttackWest = MENU_COALITION:New( coalition.side.BLUE, " West Region", MenuConvoyAttack )
                MenuConvoyAttackCentral = MENU_COALITION:New( coalition.side.BLUE, " Central Region", MenuConvoyAttack )
        MenuAirfieldAttack = MENU_COALITION:New(coalition.side.BLUE, " Airfield Strike", MenuGroundTop )
    MenuAirfieldAttackEast = MENU_COALITION:New( coalition.side.BLUE, " East Region", MenuAirfieldAttack )
    MenuAirfieldAttackCentral = MENU_COALITION:New( coalition.side.BLUE, " Central Region", MenuAirfieldAttack )
    MenuAirfieldAttackWest = MENU_COALITION:New( coalition.side.BLUE, " West Region", MenuAirfieldAttack )
        MenuFactoryAttack = MENU_COALITION:New(coalition.side.BLUE, " Factory Strike", MenuGroundTop )
    MenuFactoryAttackEast = MENU_COALITION:New( coalition.side.BLUE, " East Region", MenuFactoryAttack )
    MenuFactoryAttackCentral = MENU_COALITION:New( coalition.side.BLUE, " Central Region", MenuFactoryAttack )
    MenuFactoryAttackWest = MENU_COALITION:New( coalition.side.BLUE, " West Region", MenuFactoryAttack )
        MenuBridgeAttack = MENU_COALITION:New(coalition.side.BLUE, " Bridge Strike", MenuGroundTop )
    MenuBridgeAttackEast = MENU_COALITION:New( coalition.side.BLUE, " East Region", MenuBridgeAttack )
    MenuBridgeAttackCentral = MENU_COALITION:New( coalition.side.BLUE, " Central Region", MenuBridgeAttack )
    MenuBridgeAttackWest = MENU_COALITION:New( coalition.side.BLUE, " West Region", MenuBridgeAttack )
        MenuCommunicationsAttack = MENU_COALITION:New(coalition.side.BLUE, " WiP Communications Strike", MenuGroundTop )
        MenuC2Attack = MENU_COALITION:New(coalition.side.BLUE, " WiP C2 Strike", MenuGroundTop )

-- ## ANTI-SHIP MISSIONS
MenuAntiShipTop = MENU_COALITION:New(coalition.side.BLUE, " WiP ANTI-SHIP MISSIONS" ) -- WiP

-- ## STRIKE PACKAGE MISSIONS
--MenuStrikePackageTop = MENU_COALITION:New(coalition.side.BLUE, " WiP STRIKE PACKAGE MISSIONS" ) -- WiP

-- ## FLEET DEFENCE MISSIONS
--MenuFleetDefenceTop = MENU_COALITION:New(coalition.side.BLUE, " WiP FLEET DEFENCE MISSIONS" ) -- WiP
 

-- END MENU DEFINITIONS
-- BEGIN FUNCTIONS


-- XXX Message displayed if WiP menu options are selected
function MenuWip( _arg )
          MESSAGE:New( "The " .. _arg .. " menu option is currently under construction. " ,5,"" ):ToAll()
end --function

-- XXX Spawn Support aircraft
-- Scheduled function on spawn to check for presence of the support aircraft in its spawn zone. Repeat check every 60 seconds. Respawn if ac has left zone. 
-- also respawn on engine shutdown if an airfield is within the support zone.
function SpawnSupport (SupportSpawn) -- spawnobject, spawnzone

        --local SupportSpawn = _args[1]
        local SupportSpawnObject = SPAWN:New( SupportSpawn.spawnobject )

        SupportSpawnObject:InitLimit( 1, 50 )
                :OnSpawnGroup(
                        function ( SpawnGroup )
                                local SpawnIndex = SupportSpawnObject:GetSpawnIndexFromGroup( SpawnGroup )
                                local CheckTanker = SCHEDULER:New( nil, 
                                function()
                                        if SpawnGroup:IsNotInZone( SupportSpawn.spawnzone ) then
                                                SupportSpawnObject:ReSpawn( SpawnIndex )
                                        end
                                end,
                                {}, 0, 60 )
                        end
                )
                :InitRepeatOnEngineShutDown()
                :Spawn()

end -- function

--XXX ## Spawning CAP flights
-- max 8x CAP aircraft can be spawned at each location
function SpawnCap( _args ) -- spawnobject, spawntable { spawn, spawnzone, templates, patrolzone, aicapzone, engagerange }

  local SpawnCapTable = _args[1]
  
  SpawnCapTable.spawn:InitLimit( 8,9999 ) -- max 8x cap sections alive   
    :InitCleanUp( 60 ) -- remove aircraft that have landed
    :OnSpawnGroup(
      function ( SpawnGroup )
        AICapZone = AI_CAP_ZONE:New( SpawnCapTable.patrolzone , 1000, 6000, 500, 600 )
        AICapZone:SetControllable( SpawnGroup )
        AICapZone:SetEngageZone( SpawnCapTable.engagezone ) -- AICapZone:SetEngageRange( SpawnCapTable.engagerange )
        AICapZone:__Start( 1 ) -- start patrolling in the PatrolZone.
      end
    )
    :SpawnInZone( SpawnCapTable.spawnzone, true, 3000, 6000 )
    
end --function
  
--XXX ## Spawning enemy convoys
--  ( Central, West ) 
function SpawnConvoy ( _args ) -- ConvoyTemplates, SpawnHost {conv, dest, destzone, strikecoords, is_open}, ConvoyType, ConvoyThreats

        local TemplateTable = _args[1]
        local SpawnHostTable = _args[2]
        local ConvoyType = _args[3]
        local ConvoyThreats = _args[4]
        
        
        local SpawnIndex = math.random ( 1, #SpawnHostTable )
        local SpawnHost = SpawnHostTable[SpawnIndex].conv
        local DestZone = SpawnHostTable[SpawnIndex].destzone

  --------------------------------------
  --- Create Mission Mark on F10 map ---
  --------------------------------------
  
  --MissionMapMark(CampTableIndex)
  local StrikeMarkZone = SpawnHost -- ZONE object for zone named in strikezone 
  local StrikeMarkZoneCoord = StrikeMarkZone:GetCoordinate() -- get coordinates of strikezone

  local StrikeMarkType = "Convoy"
  local StrikeMarkCoordsLLDMS = StrikeMarkZoneCoord:ToStringLLDMS(_SETTINGS:SetLL_Accuracy(0)) --TableStrikeAttack[StrikeIndex].strikecoords
  local StrikeMarkCoordsLLDDM = StrikeMarkZoneCoord:ToStringLLDDM(_SETTINGS:SetLL_Accuracy(3)) --TableStrikeAttack[StrikeIndex].strikecoords

  local StrikeMarkLabel = StrikeMarkType 
    .. " Strike\n" 
    .. StrikeMarkCoordsLLDMS
        .. "\n"
        .. StrikeMarkCoordsLLDDM

  local StrikeMark = StrikeMarkZoneCoord:MarkToAll(StrikeMarkLabel, true) -- add mark to map

  --SpawnCampsTable[ CampTableIndex ].strikemarkid = StrikeMark -- add mark ID to table 

        
        SpawnHost:InitRandomizeTemplate( TemplateTable )
                :OnSpawnGroup(
                        function ( SpawnGroup )
                                CheckConvoy = SCHEDULER:New( nil, 
                                        function()
                                                if SpawnGroup:IsPartlyInZone( DestZone ) then
                                                        SpawnGroup:Destroy( false )
                                                end
                                        end,
                                        {}, 0, 60 
                                )
                        end
                )
                :Spawn()


        local ConvoyAttackBrief = "++++++++++++++++++++++++++++++++++++" 
                .."\n\nIntelligence is reporting an enemy "
                .. ConvoyType
                .. " convoy\nbelieved to be routing to "
                .. SpawnHostTable[SpawnIndex].dest .. "."
                .. "\n\nMission:  LOCATE AND DESTROY THE CONVOY."
                .. "\n\nLast Known Position:\n"
                .. StrikeMarkCoordsLLDMS
                .. "\n"
                .. StrikeMarkCoordsLLDDM
                .. "\n"
                .. ConvoyThreats
                .. "\n\n++++++++++++++++++++++++++++++++++++"
                
        MESSAGE:New( ConvoyAttackBrief, 30, "" ):ToAll()
        
                
end --function  
  
--XXX ## Spawning enemy camps 
function SpawnCamp( _args ) --TemplateTable, CampsTable [ loc, town, coords, is_open ], Region
        
        local SpawnTemplateTable = _args[1]
        local SpawnCampsTable = _args[2]
        local SpawnZoneRegion = _args[3]
        
        local count = 0
        for CampIndex, CampValue in ipairs(SpawnCampsTable) do -- Count number of unsed camp spawns available in region
                if CampValue.is_open then
                        count = count + 1
                        CampTableIndex = CampIndex -- default index is last open zone found
                end
        end
        
        if count > 1 then -- Randomize spawn location if more than 1 remaining
                CampTableIndex = math.random ( 1, #SpawnCampsTable )
                while ( not SpawnCampsTable[CampTableIndex].is_open ) do
                        CampTableIndex = math.random ( 1, #SpawnCampsTable )
                end
        elseif count == 0 then -- no open zones remaining
                msg = "++++++++++++++++++++++++++++++++++++" 
                        .. "\n\nMaximum number of camp strike missions for the " 
                        .. SpawnZoneRegion 
                        .. " region of the map has been reached. Please try a different one."
                        .. "\n\n++++++++++++++++++++++++++++++++++++"
                MESSAGE:New( msg, 10, "" ):ToAll()
                return
        end
        
        local SpawnCampZone = SpawnCampsTable[ CampTableIndex ].loc
        
        CampAttackSpawn:InitRandomizeTemplate( SpawnTemplateTable )
                :InitRandomizeUnits( true, 35, 5 )
                :InitHeading( 1,359 )
                :OnSpawnGroup(
                        function( SpawnGroup )
                                --local ZonePointVec2 = SpawnGroup:GetPointVec2()
                                SpawnTentGroup:InitRandomizeUnits( true, 77, 35 )
                                        :SpawnInZone ( SpawnCampZone )
                                SpawnInfGroup:InitRandomizeUnits( true, 77, 5 )
                                        :SpawnInZone ( SpawnCampZone )
                        end 
                )
        :SpawnInZone( SpawnCampZone )

    --------------------------------------
    --- Create Mission Mark on F10 map ---
    --------------------------------------
    
    --MissionMapMark(CampTableIndex)
    local StrikeMarkZone = SpawnCampZone -- ZONE object for zone named in strikezone 
    local StrikeMarkZoneCoord = StrikeMarkZone:GetCoordinate() -- get coordinates of strikezone

    local StrikeMarkName = SpawnCampsTable[ CampTableIndex ].town
    local StrikeMarkType = "Camp"
    local StrikeMarkRegion = SpawnZoneRegion
        local StrikeMarkCoordsLLDMS = StrikeMarkZoneCoord:ToStringLLDMS(_SETTINGS:SetLL_Accuracy(0)) --TableStrikeAttack[StrikeIndex].strikecoords
        local StrikeMarkCoordsLLDDM = StrikeMarkZoneCoord:ToStringLLDDM(_SETTINGS:SetLL_Accuracy(3)) --TableStrikeAttack[StrikeIndex].strikecoords

    local StrikeMarkLabel = StrikeMarkName .. " " 
      .. StrikeMarkType 
      .. " Strike " 
      .. StrikeMarkRegion 
      .. "\n" 
      .. StrikeMarkCoordsLLDMS
          .. "\n"
          .. StrikeMarkCoordsLLDDM
          

    local StrikeMark = StrikeMarkZoneCoord:MarkToAll(StrikeMarkLabel, true) -- add mark to map

    SpawnCampsTable[ CampTableIndex ].strikemarkid = StrikeMark -- add mark ID to table 
 
    
        local CampAttackBrief = "++++++++++++++++++++++++++++++++++++" 
                .."\n\nIntelligence is reporting an insurgent camp IVO "
                .. SpawnCampsTable[ CampTableIndex ].town
                .. "\n\nMission:  LOCATE AND DESTROY THE CAMP."
                .. "\n\nCoordinates:\n"
                .. StrikeMarkCoordsLLDMS
                .. "\n"
                .. StrikeMarkCoordsLLDDM
                .. "\n\nThreats:  INFANTRY, HEAVY MG, RPG, I/R SAM, LIGHT ARMOR, AAA"
                .. "\n\n++++++++++++++++++++++++++++++++++++"
                
        MESSAGE:New( CampAttackBrief, 30, "" ):ToAll()

        SpawnCampsTable[ CampTableIndex ].is_open = false
        
end --function

-- TODO: integrate camp attack, convoy strike
function SpawnStrikeAttack ( StrikeIndex ) -- "location name"
  -- TableStrikeAttack { { striketype [Airfield, Factory, Bridge, Communications, C2], strikeivo, strikecoords, strikemission, strikethreats, strikezone, striketargets, medzones { zone, is_open }, smallzones { zone, is_open }, defassets { sam, aaa, manpad, armour}, spawnobjects {}, is_open } 
  local FuncDebug = false

        BASE:TraceOnOff( false )
        BASE:TraceAll( true )

        if TableStrikeAttack[StrikeIndex].is_open then

                local MedZonesCount = #TableStrikeAttack[StrikeIndex].medzones -- number of medium defzones
                local SmallZonesCount = #TableStrikeAttack[StrikeIndex].smallzones -- number of small defzones
                local SamQty = math.random( 2, TableStrikeAttack[StrikeIndex].defassets.sam ) -- number of SAM defences min 2
                local AaaQty = math.random( 2, TableStrikeAttack[StrikeIndex].defassets.aaa ) -- number of AAA defences min 2
                local ManpadQty = math.random( 1, TableStrikeAttack[StrikeIndex].defassets.manpad ) -- number of manpad defences 1-max spawn in AAA zones. AaaQty + ManpadQty MUST NOT exceed SmallZonesCount
                local ArmourQty = math.random( 1, TableStrikeAttack[StrikeIndex].defassets.armour ) -- number of armour groups 1-max spawn in SAM zones. SamQty + ArmourQty MUST NOT exceed MedZonesCount
                local StrikeMarkZone = ZONE:FindByName( TableStrikeAttack[StrikeIndex].strikezone ) -- ZONE object for zone named in strikezone 
                
                -----------------------------------------------------------------
                --- Check sufficient zones exist for the mission air defences ---
                -----------------------------------------------------------------
                
                if SamQty + ArmourQty > MedZonesCount then
                        local msg = TableStrikeAttack[StrikeIndex].strikename .. " Error! SAM+Armour count exceedes medium zones count"
                        MESSAGE:New ( msg, 10, "" ):ToAll()
                        return
                elseif AaaQty + ManpadQty > SmallZonesCount then
                        local msg = TableStrikeAttack[StrikeIndex].strikename .. " Error! AAA+MANPAD count exceedes small zones count"
                        MESSAGE:New ( msg, 10, "" ):ToAll()
                        return
                end

    ------------------------------------------------------------------------
    --- Refresh static objects in case they've previously been destroyed ---
    ------------------------------------------------------------------------
                if #TableStrikeAttack[StrikeIndex].striketargets > 0 then 
                        for index, staticname in ipairs(TableStrikeAttack[StrikeIndex].striketargets) do
                                local AssetStrikeStaticName = staticname
                                local AssetStrikeStatic = STATIC:FindByName( AssetStrikeStaticName )
                                AssetStrikeStatic:ReSpawn( country.id.RUSSIA )
                        end
                end
                
                ---------------------------------
                --- add strike defence assets ---
                ---------------------------------
                
                function AddStrikeAssets (AssetType, AssetQty, AssetZoneType, AssetZonesCount ) -- AssetType ["sam", "aaa", "manpads", "armour"], AssetQty, AssetZoneType ["med", "small"], AssetZonesCount

                        if AssetQty > 0 then
                        
                        local TableStrikeAssetZones = {}
  
                        -- select indexes of zones in which to spawn assets 
                        for count=1, AssetQty do 
                                local zoneindex = math.random( 1, AssetZonesCount )
                                if AssetZoneType == "med" then
                                        while ( not TableStrikeAttack[StrikeIndex].medzones[zoneindex].is_open ) do -- ensure selected zone has not been used
                                                zoneindex = math.random ( 1, AssetZonesCount )
                                        end
                                        TableStrikeAttack[StrikeIndex].medzones[zoneindex].is_open = false -- close samzone for selection
                                else
                                        while ( not TableStrikeAttack[StrikeIndex].smallzones[zoneindex].is_open ) do -- ensure selected zone has not been used
                                                zoneindex = math.random ( 1, AssetZonesCount )
                                        end
                                        TableStrikeAttack[StrikeIndex].smallzones[zoneindex].is_open = false -- close aaazone for selection
                                end
                                TableStrikeAssetZones[count] = zoneindex -- add selected zone to list
                                
                        end
  
                        -- spawn assets
                        for count = 1, #TableStrikeAssetZones do
                                -- randomise template (MOOSE removes unit orientation in template)
                                local DefTemplateIndex = math.random( 1, #TableDefTemplates[AssetType] ) -- generate random index for template
                                local AssetTemplate = TableDefTemplates[AssetType][DefTemplateIndex] -- select indexed template
                                local AssetSpawnStub = _G["DEFSTUB_" .. AssetTemplate] -- _G[contenation for name of generated DEFSTUB_ spawn]
                                local assetzoneindex = TableStrikeAssetZones[count]
                                if AssetZoneType == "med" then -- medzone 
                                        assetspawnzone = ZONE:FindByName( TableStrikeAttack[StrikeIndex].medzones[assetzoneindex].loc ) -- _G[concatenation for name of generated spawnzone]
                                else -- smallzone
                                        assetspawnzone = ZONE:FindByName( TableStrikeAttack[StrikeIndex].smallzones[assetzoneindex].loc ) -- _G["SPAWN" .. TableStrikeAttack[StrikeIndex].smallzones[assetzoneindex].loc]
                                end
                                AssetSpawnStub:SpawnInZone( assetspawnzone ) -- spawn asset in zone in generated zone list
                                local assetspawngroup, assetspawngroupindex = AssetSpawnStub:GetLastAliveGroup()
                                table.insert(TableStrikeAttack[StrikeIndex].spawnobjects, assetspawngroup )
                        end

      end

                end
                
    -------------------------
    --- Call asset spawns ---
    -------------------------
  
                -- add SAM assets
                if SamQty ~= nil then
                  AddStrikeAssets( "sam", SamQty, "med", MedZonesCount ) -- AssetType ["sam", "aaa", "manpads", "armour"], AssetQty, AssetZoneType ["med", "small"], AssetZonesCount
                end
                -- add AAA assets
                if SamQty ~= nil then
                  AddStrikeAssets( "aaa", AaaQty, "small", SmallZonesCount )
                end
                -- add Manpad assets
                if ManPadQty ~= nil then
                                AddStrikeAssets( "manpads", ManpadQty, "small", SmallZonesCount )
                end
                -- add armour assets
                if ArmourQty ~= nil then
                  AddStrikeAssets( "armour", ArmourQty, "med", MedZonesCount )
    end
    
    --------------------------------------
    --- Create Mission Mark on F10 map ---
    --------------------------------------
    
    local StrikeMarkZone = ZONE:FindByName( TableStrikeAttack[StrikeIndex].strikezone ) -- ZONE object for zone named in strikezone 
    local StrikeMarkZoneCoord = StrikeMarkZone:GetCoordinate() -- get coordinates of strikezone

    local StrikeMarkName = TableStrikeAttack[StrikeIndex].strikename
    local StrikeMarkType = TableStrikeAttack[StrikeIndex].striketype
    local StrikeMarkRegion = TableStrikeAttack[StrikeIndex].strikeregion
    local StrikeMarkCoordsLLDMS = StrikeMarkZoneCoord:ToStringLLDMS(_SETTINGS:SetLL_Accuracy(0)) --TableStrikeAttack[StrikeIndex].strikecoords
    local StrikeMarkCoordsLLDDM = StrikeMarkZoneCoord:ToStringLLDDM(_SETTINGS:SetLL_Accuracy(3)) --TableStrikeAttack[StrikeIndex].strikecoords

    local StrikeMarkLabel = StrikeMarkName .. " " 
      .. StrikeMarkType 
      .. " Strike " 
      .. StrikeMarkRegion 
      .. "\n" 
      .. StrikeMarkCoordsLLDMS
          .. "\n"
      .. StrikeMarkCoordsLLDDM

    local StrikeMark = StrikeMarkZoneCoord:MarkToAll(StrikeMarkLabel, true) -- add mark to map
    
    TableStrikeAttack[StrikeIndex].strikemarkid = StrikeMark -- add mark ID to table 
    
                -----------------------------
                --- Send briefing message ---
                -----------------------------
                
                local strikeAttackBrief = "++++++++++++++++++++++++++++++++++++"
                        ..      "\n\nAir Interdiction mission against "
                        .. StrikeMarkName
                        .. " "
                        .. StrikeMarkType
                        .. "\n\nMission: "
                        .. TableStrikeAttack[StrikeIndex].strikemission
                        .. "\n\nCoordinates:\n"
                        .. StrikeMarkCoordsLLDMS
                        .. "\n"
                        .. StrikeMarkCoordsLLDDM
                        .. "\n\nThreats:  "
                        .. TableStrikeAttack[StrikeIndex].strikethreats
                        .. "\n\n++++++++++++++++++++++++++++++++++++"
                        
                MESSAGE:New ( strikeAttackBrief, 30, "" ):ToAll()
                
        
                TableStrikeAttack[StrikeIndex].is_open = false -- mark strike mission as active
                
                ------------------------------------------------------------------------------
                --- menu: add mission remove command and remove mission start command ---
                ------------------------------------------------------------------------------
                
    _G["Cmd" .. StrikeIndex .. "Attack"]:Remove()
                _G["Cmd" .. StrikeIndex .. "AttackRemove"] = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Remove Mission", _G["Menu" .. TableStrikeAttack[StrikeIndex].striketype .. "Attack" .. StrikeIndex], RemoveStrikeAttack, StrikeIndex )
                        
        else
                msg = "\n\nThe " 
                        .. TableStrikeAttack[StrikeIndex].strikename
                        .. " "
                        .. TableStrikeAttack[StrikeIndex].striketype
                        .. " strike attack mission is already active!"
                MESSAGE:New( msg, 10, "" ):ToAll()
        end

BASE:TraceOnOff( false )

end --function

------------------------------------
--- Remove strike attack mission ---
------------------------------------

function RemoveStrikeAttack ( StrikeIndex )
BASE:TraceOnOff( false )
BASE:TraceAll( true )

        if not TableStrikeAttack[StrikeIndex].is_open then
                local objectcount = #TableStrikeAttack[StrikeIndex].spawnobjects
                for count = 1, objectcount do
                        local removespawnobject = TableStrikeAttack[StrikeIndex].spawnobjects[count]
                        if removespawnobject:IsAlive() then
                                
                                removespawnobject:Destroy( false )
                        end
                end
                
                COORDINATE:RemoveMark( TableStrikeAttack[StrikeIndex].strikemarkid ) -- remove mark from map
                
                TableStrikeAttack[StrikeIndex].strikemarkid = nil -- reset map mark ID
                TableStrikeAttack[StrikeIndex].spawnobjects = {} -- clear list of now despawned objects
                TableStrikeAttack[StrikeIndex].is_open = true -- set strike mission as available
                
                -- ## menu: add mission start menu command and remove mission remove command
    _G["Cmd" .. StrikeIndex .. "AttackRemove"]:Remove()
                _G["Cmd" .. StrikeIndex .. "Attack"] = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Start Mission", _G["Menu" .. TableStrikeAttack[StrikeIndex].striketype .. "Attack" .. StrikeIndex], SpawnStrikeAttack, StrikeIndex )

    msg = "\n\nThe " 
      .. TableStrikeAttack[StrikeIndex].strikename
      .. " strike attack mission has been removed."
    MESSAGE:New( msg, 10, "" ):ToAll()

        else
                msg = "\n\nThe " 
                        .. TableStrikeAttack[StrikeIndex].strikename
                        .. " strike attack mission is not active!"
                MESSAGE:New( msg, 10, "" ):ToAll()
        end
BASE:TraceOnOff( false )

end --function


----------------------------------------
--- Remove oldest spawn in a mission ---
----------------------------------------

function RemoveSpawn( _args )

        local RemoveSpawnGroupTable = _args[1]

        local FirstSpawnGroup, Index = RemoveSpawnGroupTable.spawn:GetFirstAliveGroup()
        if FirstSpawnGroup then
                FirstSpawnGroup:Destroy( false )
        end
        
end --function

-- ## Remove oldest spawned group in a mission
function RemoveSpawnGroup( _args )

        for index, SpawnObject in pairs( _args ) do
                local FirstSpawnGroup, FirstSpawnIndex = SpawnObject:GetFirstAliveGroup()
                if FirstSpawnGroup then
                        FirstSpawnGroup:Destroy( false )
                end
        end
        
end --function

-- ## CAMP remove spawn
function RemoveCamp( _args )

        local FirstCampGroup, Index = _args[2]:GetFirstAliveGroup()
        if FirstCampGroup then
                FirstCampGroup:Destroy( false )
        end
        
end --function


local function InList( tbl, val )

    for index, value in ipairs(tbl) do
        if value == val then
            return true
        end
    end

    return false        

end --function


-- END FUNCTIONS
-- XXX BEGIN SUPPORT AC SECTION


---------------------------------------------------
--- Define spawn zones with trigger zones in ME ---
---------------------------------------------------

Zone_AAR_1 = ZONE:FindByName( "AAR_1_Zone" ) 
Zone_AAR_2 = ZONE:FindByName( "AAR_2_Zone" ) 
Zone_AWACS_1 = ZONE:FindByName( "AWACS_1_Zone" )
Zone_Red_AWACS_1 = ZONE:FindByName( "RED_AWACS_1_Zone" ) 

------------------------------------------------------
--- define table of support aircraft to be spawned ---
------------------------------------------------------

TableSpawnSupport = { -- {spawnobjectname, spawnzone}
        {spawnobject = "Tanker_C130_Arco1", spawnzone = Zone_AAR_1},
        {spawnobject = "Tanker_KC135_Shell1", spawnzone = Zone_AAR_1},
  {spawnobject = "Tanker_KC135_Shell2", spawnzone = Zone_AAR_2},
  {spawnobject = "Tanker_KC135_Texaco1", spawnzone = Zone_AAR_1},
        {spawnobject = "AWACS_Magic", spawnzone = Zone_AWACS_1},
        {spawnobject = "RED_AWACS_108", spawnzone = Zone_Red_AWACS_1},
}

------------------------------
--- spawn support aircraft ---
------------------------------

for i, v in ipairs( TableSpawnSupport ) do
        SpawnSupport ( v )
        
end


-- END SUPPORT AC SECTION

-- Recovery Tanker Lincoln ---

Spawn_Tanker_S3B_Texaco6 = RECOVERYTANKER:New( UNIT:FindByName( "CSG_CarrierGrp_Lincoln"), "Tanker_S3B_Texaco6" )

Spawn_Tanker_S3B_Texaco6:SetCallsign(CALLSIGN.Tanker.Texaco, 6)
Spawn_Tanker_S3B_Texaco6:SetTACAN(38, "TEX")
Spawn_Tanker_S3B_Texaco6:SetRadio(317.775)
Spawn_Tanker_S3B_Texaco6:SetModex(049)
Spawn_Tanker_S3B_Texaco6:SetTakeoffAir()
Spawn_Tanker_S3B_Texaco6:SetAltitude(6000)
Spawn_Tanker_S3B_Texaco6:SetRespawnInAir()
Spawn_Tanker_S3B_Texaco6:Start()

Spawn_Tanker_S3B_Texaco6:SetRecoveryAirboss( false )

-- Rescue Helo Lincoln ---

Spawn_Rescuehelo_Lincoln = RESCUEHELO:New(UNIT:FindByName("CSG_CarrierGrp_Lincoln"), "RescueHelo_Lincoln")

Spawn_Rescuehelo_Lincoln:SetTakeoffAir()
Spawn_Rescuehelo_Lincoln:SetRespawnInAir()
Spawn_Rescuehelo_Lincoln:SetHomeBase(AIRBASE:FindByName("CSG_CarrierGrp_Lincoln_03"))
Spawn_Rescuehelo_Lincoln:SetRescueStopBoatOff()
Spawn_Rescuehelo_Lincoln:SetOffsetZ(800)
--Spawn_Rescuehelo_Lincoln:Start()

-- Rescue Helo Tarawa ---

Spawn_Rescuehelo_Tarawa = RESCUEHELO:New(UNIT:FindByName("CSG_CarrierGrp_Tarawa"), "RescueHelo_Tarawa")

Spawn_Rescuehelo_Tarawa:SetTakeoffAir()
Spawn_Rescuehelo_Tarawa:SetRespawnInAir()
Spawn_Rescuehelo_Tarawa:SetHomeBase(AIRBASE:FindByName("CSG_CarrierGrp_Tarawa_03"))
Spawn_Rescuehelo_Tarawa:SetRescueStopBoatOff()
Spawn_Rescuehelo_Tarawa:SetOffsetZ(800)
--Spawn_Rescuehelo_Tarawa:Start()

-----------------------
--- Airboss Tarawa ---
-----------------------

airbossTarawa=AIRBOSS:New( "CSG_CarrierGrp_Tarawa", "Tarawa" )

airbossTarawa:Load(nil, "Cauc_Airboss-USS Tarawa_LSOgrades.csv")
airbossTarawa:SetAutoSave(nil, "Cauc_Airboss-USS Tarawa_LSOgrades.csv")

local tarawaCase = lincolnCase -- set daytime case according to weather, determined in Lincoln section. assumes statc weather accross whole map.
local tarawaOffset_deg = 0
local tarawaRadioRelayMarshall = UNIT:FindByName("RadioRelayMarshall_Tarawa")
local tarawaRadioRelayPaddles = UNIT:FindByName("RadioRelayPaddles_Tarawa")
 
airbossTarawa:SetMenuRecovery(30, 25, false, 30)
airbossTarawa:SetSoundfilesFolder("Airboss Soundfiles/")
airbossTarawa:SetTACAN(1,"X","TAR")
airbossTarawa:SetICLS( 1,"TAR" )
airbossTarawa:SetCarrierControlledArea( 50 )
airbossTarawa:SetDespawnOnEngineShutdown( true )
airbossTarawa:SetMarshalRadio( 285.675, "AM" )
airbossTarawa:SetLSORadio( 255.725, "AM" )
airbossTarawa:SetRadioRelayLSO( tarawaRadioRelayPaddles )
airbossTarawa:SetRadioRelayMarshal( tarawaRadioRelayMarshall  )
airbossTarawa:SetAirbossNiceGuy( true )
airbossTarawa:SetDefaultPlayerSkill(AIRBOSS.Difficulty.Normal)
airbossTarawa:SetRespawnAI()
airbossTarawa:SetMenuMarkZones( false ) -- disable marking zones using smoke or flares

--- Fun Map Recovery Windows 
-- dependent on mission start and finish times
-- Sunrise @ 08:00, Sunset @ 19:00, recovery @ sunrise+10 and sunset-10
-- otherwise, intiate recovery through F10 menu
airbossTarawa:AddRecoveryWindow( "8:10", "18:50", tarawaCase, tarawaOffset_deg, true, 30 ) -- sunrise to sunset 
airbossTarawa:AddRecoveryWindow( "18:50", "8:10+1", 3, tarawaOffset_deg, true, 30 ) -- sunset to sunrise D+1
airbossTarawa:AddRecoveryWindow( "8:10+1", "18:50+1", tarawaCase, tarawaOffset_deg, true, 30 ) -- sunrise D+1 to sunset D+1

-- Start AIRBOSS Tarawa
airbossTarawa:Start()

-- Recovery Tanker Tarawa ---

Spawn_Tanker_C130_Arco2 = RECOVERYTANKER:New( UNIT:FindByName( "CSG_CarrierGrp_Tarawa"), "Tanker_C130_Arco2" )

Spawn_Tanker_C130_Arco2:SetCallsign(CALLSIGN.Tanker.Arco, 2)
  :SetTACAN(39, "ARC")
  :SetRadio(276.1)
  :SetModex(999)
  :SetAltitude(10000)
  :SetTakeoffAir()
  :SetRespawnInAir()
  :SetHomeBase(AIRBASE:FindByName("Kobuleti"))
  :Start()

-- END BOAT SECTION

-- BEGIN CAP SECTION



-- Each CAP Location requires a Zone
-- CAP objects will be spawned at a random postion within the zone
-- A host aircraft ( late activation ) must be placed at each location
-- AICapZone is used to set the patrol and engage zones
-- On Spawning, the host will be replaced with a goup selected radomly from a list of templates


-----------------------
--- CAP spawn stubs ---
-----------------------

MaykopCapSpawn = SPAWN:New( "MaykopCap" )
BeslanCapSpawn = SPAWN:New( "BeslanCap" )

-----------------------
--- CAP spawn zones ---
-----------------------

MaykopCapSpawnZone = ZONE:FindByName( "ZONE_MaykopCapSpawn" )
BeslanCapSpawnZone = ZONE:FindByName( "ZONE_BeslanCapSpawn" )

---------------------------
--- CAP spawn templates ---
---------------------------

CapTemplates = {
        "Russia_Mig29",
        "Russia_Mig21",
        "Russia_Su27"
}

-----------------------------------------
--- AICapzone patrol and engage zones ---
-----------------------------------------

WestCapPatrolGroup = GROUP:FindByName( "PolyPatrolWest" )
WestCapPatrolZone = ZONE_POLYGON:New( "ZONE_PatrolWest", WestCapPatrolGroup )
WestCapEngageGroup = GROUP:FindByName( "PolyEngageWest" )
WestCapEngageZone = ZONE_POLYGON:New( "ZONE_EngageWest", WestCapEngageGroup )

EastCapPatrolGroup = GROUP:FindByName( "PolyPatrolEast" )
EastCapPatrolZone = ZONE_POLYGON:New( "ZONE_PatrolEast", EastCapPatrolGroup )
EastCapEngageGroup = GROUP:FindByName( "PolyEngageEast" )
EastCapEngageZone = ZONE_POLYGON:New( "ZONE_EngageEast", EastCapEngageGroup )

------------------------------------------------------
--- table containing CAP spawn config per location ---
------------------------------------------------------

CapTable = { -- spawn location, { spawn, spawnzone, templates, patrolzone, engagerange } ...
  maykop = { 
    spawn = MaykopCapSpawn, 
    spawnzone = MaykopCapSpawnZone, 
    templates = CapTemplates, 
    patrolzone = WestCapPatrolZone, 
    engagerange = 60000,
    engagezone = WestCapEngageZone,
  },
  beslan = { 
    spawn = BeslanCapSpawn, 
    spawnzone = BeslanCapSpawnZone, 
    templates = CapTemplates, 
    patrolzone = EastCapPatrolZone, 
    engagerange = 60000,
    engagezone = EastCapEngageZone,
  },
}

------------------
--- Maykop CAP ---
------------------

_maykop_args = { -- args passed to spawn menu option
        CapTable.maykop,
}

CmdMaykopCap = MENU_COALITION_COMMAND:New( coalition.side.BLUE,"Spawn Maykop CAP", MenuCapMaykop, SpawnCap, _maykop_args ) -- Spawn CAP flight
CmdMaykopCapRemove = MENU_COALITION_COMMAND:New( coalition.side.BLUE,"Remove Oldest Maykop CAP", MenuCapMaykop, RemoveSpawn, _maykop_args ) -- Remove the oldest CAP flight for location

------------------
--- Beslan CAP ---
------------------

_beslan_args = { 
        CapTable.beslan,
}

CmdBeslanCap = MENU_COALITION_COMMAND:New( coalition.side.BLUE,"Spawn Beslan CAP", MenuCapBeslan, SpawnCap, _beslan_args ) 
CmdBeslanCapRemove = MENU_COALITION_COMMAND:New( coalition.side.BLUE,"Remove oldest Beslan CAP", MenuCapBeslan, RemoveSpawn, _beslan_args )




-- END CAP SECTION
-- BEGIN CAMP ATTACK SECTION


-------------------------------------------------
--- table containing camp spawns per location ---
-------------------------------------------------

TableCamps = { -- map portion, { camp zone, nearest town, Lat Long, spawned status } ...
        east = {
                { 
                        loc = ZONE:New("ZoneCampEast01"), 
                        town = "Kvemo-Sba", 
                        coords = "42  34  02 N | 044  10  20 E", 
                        is_open = true 
                },
                { 
                        loc = ZONE:New("ZoneCampEast02"), 
                        town = "Kvemo-Roka", 
                        coords = "42  32  48 N | 044  07  01 E", 
                        is_open = true 
                }, 
                { 
                        loc = ZONE:New("ZoneCampEast03"), 
                        town = "Edisa", 
                        coords = "42  32  21 N | 044  12  10 E", 
                        is_open = true 
                },
                { 
                        loc = ZONE:New("ZoneCampEast04"), 
                        town = "Kvemo-Khoshka", 
                        coords = "42  27  07 N | 044  03  25 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampEast05"), 
                        town = "Elbakita", 
                        coords = "42  25  24 N | 044  00  40 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampEast06"), 
                        town = "Tsru", 
                        coords = "42  22  50 N | 044  01  55 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampEast07"), 
                        town = "Didi-Gupta", 
                        coords = "42  21 11 N | 043  54  18 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampEast08"), 
                        town = "Kekhvi", 
                        coords = "42  19  10 N | 043  56  09 E", 
                        is_open = true
                }
        },
        central = {
                { 
                        loc = ZONE:New("ZoneCampCentral01"), 
                        town = "Oni", 
                        coords = "42  35  53 N | 043  27  13 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampCentral02"), 
                        town = "Kvashkhieti", 
                        coords = "42  32  49 N | 043  23  10 E", 
                        is_open = true
                }, 
                { 
                        loc = ZONE:New("ZoneCampCentral03"), 
                        town = "Haristvala", 
                        coords = "42  23  46 N | 043  02  27 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampCentral04"), 
                        town = "Ahalsopeli", 
                        coords = "42  18  11 N | 042  56  57 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampCentral05"), 
                        town = "Mohva", 
                        coords = "42  22  35 N | 043  21  24 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampCentral06"), 
                        town = "Sadmeli", 
                        coords = "42  32  05 N | 043  06  36 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampCentral07"), 
                        town = "Zogishi", 
                        coords = "42  33  36 N | 042  51  18 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampCentral08"), 
                        town = "Namohvani", 
                        coords = "42  41  39 N | 042  41  39 E", 
                        is_open = true
                },
        },
        west = {
                { 
                        loc = ZONE:New("ZoneCampWest01"), 
                        town = "Dzhvari", 
                        coords = "42  43  01 N | 042  02  08 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampWest02"), 
                        town = "Tkvarcheli", 
                        coords = "42  51  45 N | 041  46  29 E", 
                        is_open = true
                }, 
                { 
                        loc = ZONE:New("ZoneCampWest03"), 
                        town = "Zemo-Azhara", 
                        coords = "43 06 26 N | 041  44 04 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampWest04"), 
                        town = "Amtkel", 
                        coords = "43  02  05 N | 041  27  16 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampWest05"), 
                        town = "Gora Mukhursha", 
                        coords = "43  19  16 N | 040  52  24 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampWest06"), 
                        town = "Ozero Ritsa", 
                        coords = "43  28  17 N | 040  32  01 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampWest07"), 
                        town = "Salhino", 
                        coords = "43  31  37 N | 040  05  31 E", 
                        is_open = true
                },
                { 
                        loc = ZONE:New("ZoneCampWest08"), 
                        town = "Leselidze", 
                        coords = "43  23  56 N | 040  00  35 E", 
                        is_open = true
                },
        }
}

------------------------
--- Camp spawn stubs ---
------------------------

CampAttackSpawn = SPAWN:New( "CAMP_Heavy" )
SpawnTent = SPAWN:New( "CAMP_Tent_01" )
SpawnHouse01 = SPAWN:New( "CAMP_House_01" )
SpawnHouse02 = SPAWN:New( "CAMP_House_02" )
SpawnHouse03 = SPAWN:New( "CAMP_House_03" )
SpawnHouse04 = SPAWN:New( "CAMP_House_04" )
SpawnHouse05 = SPAWN:New( "CAMP_House_05" )  
SpawnTower = SPAWN:New( "CAMP_Tower_01" )
SpawnInfSingle = SPAWN:New( "CAMP_Inf_01" )

SpawnTentGroup = SPAWN:New( "CAMP_Tent_Group" )
SpawnInfGroup = SPAWN:New( "CAMP_Inf_02" )

----------------------------
--- Camp spawn templates ---
----------------------------

ArmourTemplates = {
        "CAMP_Heavy_01",
        "CAMP_Heavy_02",
        "CAMP_Heavy_03",
        "CAMP_Heavy_04"
} 

-------------------------
--- Add menu commands ---
-------------------------

-- East zones
_east_args = {
        ArmourTemplates,
        TableCamps.east,
        "East"
}

cmdCampAttackEast = MENU_COALITION_COMMAND:New( coalition.side.BLUE," Eastern Zone",MenuCampAttack,SpawnCamp, _east_args )

-- Central Zones
_central_args = {
        ArmourTemplates,
        TableCamps.central,
        "Central"
}
cmdCampAttackCentral = MENU_COALITION_COMMAND:New( coalition.side.BLUE," Central Zone",MenuCampAttack,SpawnCamp, _central_args )

-- West Zones
 _West_args = {
        ArmourTemplates,
        TableCamps.west,
        "West"
}
cmdCampAttackWest = MENU_COALITION_COMMAND:New( coalition.side.BLUE," Western Zone",MenuCampAttack,SpawnCamp, _West_args )

-- TODO: Remove oldest Camp Attack mission
_campattackremove_args = { 
        CampAttackSpawn,
        SpawnTentGroup,
        SpawnInfGroup
}
--cmdCampAttackRemove = MENU_COALITION_COMMAND:New( coalition.side.BLUE, " Remove oldest mission", MenuCampAttack, RemoveSpawnGroup, _campattackremove_args )



-- END CAMP ATTACK SECTION
-- BEGIN CONVOY ATTACK SECTION

-- XXX ## Able Sentry Convoy
-- Convoy is spawned at mission start and will advance North->South on highway B3 towards Tbilisi
-- On reaching Mtskehta it will respawn at the start of the route.

function ResetAbleSentry()
  Spawn_Convoy_AbleSentry:ReSpawn(SpawnIndex_Convoy_AbleSentry) 
end -- function

Zone_ConvoyObjectiveAbleSentry = ZONE:FindByName( "ConvoyObjectiveAbleSentry" ) 

Spawn_Convoy_AbleSentry = SPAWN:New( "CONVOY_Hard_Able Sentry" )
        :InitLimit( 20, 50 )
        :OnSpawnGroup(
                function ( SpawnGroup )
                        -- SpawnIndex_Convoy_AbleSentry = Spawn_Convoy_AbleSentry:GetSpawnIndexFromGroup( SpawnGroup )
                        checkConvoyAbleSentry = SCHEDULER:New( SpawnGroup, 
                        function()
                                if SpawnGroup:IsPartlyInZone( Zone_ConvoyObjectiveAbleSentry ) then
                                        ResetAbleSentry()
                                end
                        end,
                        {}, 0, 60
                )
                  mapMarkConvoyAbleSentry = SCHEDULER:New( SpawnGroup, 
        function()
          if Spawn_Convoy_AbleSentry.mapmarkid then
            COORDINATE:RemoveMark( Spawn_Convoy_AbleSentry.mapmarkid )
          end    
          local coordsAbleSentry = SpawnGroup:GetCoordinate()
          local labelAbleSentry = "Able Sentry Convoy\nMost recent reported postion\n" .. coordsAbleSentry:ToStringLLDMS(_SETTINGS:SetLL_Accuracy(0)) .. "\n" .. coordsAbleSentry:ToStringLLDDM(_SETTINGS:SetLL_Accuracy(3))
          local mapMarkAbleSentry = coordsAbleSentry:MarkToAll(labelAbleSentry, true) -- add mark to map
          Spawn_Convoy_AbleSentry.mapmarkid = mapMarkAbleSentry -- add mark ID to SPAWN object 
        end,
        {}, 0, 180
      )
                end
        )
        :SpawnScheduled( 60 , .1 )

    


cmdConvoyAbleSentryReset = MENU_COALITION_COMMAND:New( coalition.side.BLUE," Able Sentry Reset",MenuConvoyAttack, ResetAbleSentry )

---------------------------------
--- On-demand convoy missions ---
---------------------------------

SpawnConvoys = { -- map portion, { spawn host, nearest town, Lat Long, destination zone, spawned status } ...
        west = {
                { 
                        conv = SPAWN:New( "CONVOY_01" ), 
                        dest = "Gudauta Airfield", 
                        destzone = ZONE:New("ConvoyObjective_01"), 
                        coords = "43  21  58 N | 040  06  31 E", 
                        is_open = true
                },
                { 
                        conv = SPAWN:New( "CONVOY_02" ), 
                        dest = "Gudauta Airfield", 
                        destzone = ZONE:New("ConvoyObjective_01"), 
                        coords = "43  27  58 N | 040  32  34 E", 
                        is_open = true
                },
                { 
                        conv = SPAWN:New( "CONVOY_03" ), 
                        dest = "Sukhumi Airfield", 
                        destzone = ZONE:New("ConvoyObjective_02"), 
                        coords = "43  02  07 N | 041  27  14 E", 
                        is_open = true
                },
                { 
                        conv = SPAWN:New( "CONVOY_04" ), 
                        dest = "Sukhumi Airfield", 
                        destzone = ZONE:New("ConvoyObjective_02"), 
                        coords = "42  51  35 N | 041  46  39 E", 
                        is_open = true
                },
        },
        central = {
                { 
                        conv = SPAWN:New( "CONVOY_05" ), 
                        dest = "Kutaisi Airfield", 
                        destzone = ZONE:New("ConvoyObjective_03"), 
                        coords = "42  33  39 N | 042  51  17 E", 
                        is_open = true
                },
                { 
                        conv = SPAWN:New( "CONVOY_06" ), 
                        dest = "Kutaisi Airfield", 
                        destzone = ZONE:New("ConvoyObjective_03"), 
                        coords = "42  23  52 N | 043  02  27 E", 
                        pen = true
                },
                { 
                        conv = SPAWN:New( "CONVOY_07" ), 
                        dest = "Khashuri", 
                        destzone = ZONE:New("ConvoyObjective_04"), 
                        coords = "42  19  59 N | 043  23  08 E", 
                        is_open = true
                },
                { 
                        conv = SPAWN:New( "CONVOY_08" ), 
                        dest = "Khashuri", 
                        destzone = ZONE:New("ConvoyObjective_04"), 
                        coords = "42  19  05 N | 043  56  01 E", 
                        is_open = true
                },
        }
}

ConvoyAttackSpawn = SPAWN:New( "CONVOY_Default" )

ConvoyHardTemplates = {
        "CONVOY_Hard_01",
        "CONVOY_Hard_02",
}
ConvoySoftTemplates = {
        "CONVOY_Soft_01",
        "CONVOY_Soft_02",
}

HardType = "Armoured"
SoftType = "Supply"
HardThreats = "\n\nThreats:  MBT, Radar SAM, I/R SAM, LIGHT ARMOR, AAA"
SoftThreats = "\n\nThreats:  LIGHT ARMOR, Radar SAM, I/R SAM, AAA"

-- ## Central Zones
_hard_central_args = {
        ConvoyHardTemplates,
        SpawnConvoys.central,
        HardType,
        HardThreats
}
cmdConvoyAttackHardCentral = MENU_COALITION_COMMAND:New( coalition.side.BLUE," Armoured Convoy",MenuConvoyAttackCentral, SpawnConvoy, _hard_central_args )

_soft_central_args = {
        ConvoySoftTemplates,
        SpawnConvoys.central,
        SoftType,
        SoftThreats
}
cmdConvoyAttackSoftCentral = MENU_COALITION_COMMAND:New( coalition.side.BLUE," Supply Convoy",MenuConvoyAttackCentral, SpawnConvoy, _soft_central_args )

-- ## West Zones
_hard_west_args = {
        ConvoyHardTemplates,
        SpawnConvoys.west,
        HardType,
        HardThreats
}
cmdConvoyAttackHardWest = MENU_COALITION_COMMAND:New( coalition.side.BLUE," Armoured Convoy",MenuConvoyAttackWest, SpawnConvoy, _hard_west_args )

_soft_west_args = {
        ConvoySoftTemplates,
        SpawnConvoys.west,
        SoftType,
        SoftThreats
}
cmdConvoyAttackSoftWest = MENU_COALITION_COMMAND:New( coalition.side.BLUE," Supply Convoy",MenuConvoyAttackWest, SpawnConvoy, _soft_west_args )



        
-- END CONVOY ATTACK SECTION
--BEGIN STRIKE ATTACK SECTION   



--- TableStrikeAttack table 
-- @type TableStrikeAttack
-- @field #string striketype type of strike; Airfield, Factory, Bridge, Communications, C2
-- @field #string strikeregion Region in which mission is located (East, Central, West)
-- @field #string strikename Friendly name for the location used in briefings, menus etc. Currently the same as the key, but will probably change
-- @field #string strikeivo "in the vacinity of" ("AFB" if airfield, "[TOWN/CITY]" other targets)
-- @field #string strikecoords LatLong
-- @field #string strikemission mission description
-- @field #string strikethreats threats description
-- @field #string ME zone at center of strike location
-- @field #table striketargets static objects to be respawned for object point strikes (Factory, refinery etc)
-- @field #table medzones ME zones in which medium assets will be spawned. (AAA batteries, vehicle groups, infantry groups etc)
-- @field #string loc ME defence zone at location
-- @field #boolean is_open tracks whether defence zone is occupied
-- @field #table ME zones in which small assets will be spawned
-- @field #string loc ME defence zone at location
-- @field #boolean is_open tracks whether defence zone is occupied
-- @field #table defassets max number of each defence asset. sum of zone types used must not exceed number of zone type available
-- @field #number sam uses medzones
-- @field #number aaa uses smallzones
-- @field #number manpads uses smallzones
-- @field #number armour uses medzones
-- @field #table spawnobjects table holding names of the spawned objects relating the mission
-- @field #boolean is_open mission status. true if mission is avilable for spawning. false if it is in-progress

-- XXX: TableStrikeAttack

TableStrikeAttack = {
        { --Beslan 
                striketype = "Airfield", 
    strikeregion = "East",                          
                strikename = "Beslan",
                strikeivo = "AFB", 
                strikecoords = "43  12  20 N | 044  36  20 E",
                strikemission = "CRATER RUNWAY AND ATTRITE AVIATION ASSETS ON THE GROUND",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_BeslanStrike",
                striketargets = {
                  "BESLAN_STATIC_01",
      "BESLAN_STATIC_02",
      "BESLAN_STATIC_03",
      "BESLAN_STATIC_04",
      "BESLAN_STATIC_05",
      "BESLAN_STATIC_06",
      "BESLAN_STATIC_07",
      "BESLAN_STATIC_08",
      "BESLAN_STATIC_09",
                },
                medzones = { 
                        { loc = "ZONE_BeslanMed_01", is_open = true },
                        { loc = "ZONE_BeslanMed_02", is_open = true },
                        { loc = "ZONE_BeslanMed_03", is_open = true },
                        { loc = "ZONE_BeslanMed_04", is_open = true },
                        { loc = "ZONE_BeslanMed_05", is_open = true },
                        { loc = "ZONE_BeslanMed_06", is_open = true },
                        { loc = "ZONE_BeslanMed_07", is_open = true },
                        { loc = "ZONE_BeslanMed_08", is_open = true },
                        { loc = "ZONE_BeslanMed_09", is_open = true },
                        { loc = "ZONE_BeslanMed_10", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_BeslanSmall_01", is_open = true },
                        { loc = "ZONE_BeslanSmall_02", is_open = true },
                        { loc = "ZONE_BeslanSmall_03", is_open = true },
                        { loc = "ZONE_BeslanSmall_04", is_open = true },
                        { loc = "ZONE_BeslanSmall_05", is_open = true },
                        { loc = "ZONE_BeslanSmall_06", is_open = true },
                        { loc = "ZONE_BeslanSmall_07", is_open = true },
                        { loc = "ZONE_BeslanSmall_08", is_open = true },
                        { loc = "ZONE_BeslanSmall_09", is_open = true },
                        { loc = "ZONE_BeslanSmall_10", is_open = true },
                },
                defassets = {
                        sam = 4,
                        aaa = 5,
                        manpad = 3, 
                        armour = 3,
                },
                spawnobjects = {},
                is_open = true,
        },
        { -- Sochi
                striketype = "Airfield",
    strikeregion = "West",                            
                strikename = "Sochi",
                strikeivo = "AFB",
                strikecoords = "43  26  41 N | 039  56  32 E",
                strikemission = "CRATER RUNWAY AND ATTRITE AVIATION ASSETS ON THE GROUND",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_SochiStrike",
                striketargets = {
                "SOCHI_STATIC_01",
    "SOCHI_STATIC_02",
    "SOCHI_STATIC_03",
    "SOCHI_STATIC_04",
    "SOCHI_STATIC_05",
    "SOCHI_STATIC_06",
    "SOCHI_STATIC_07",
    "SOCHI_STATIC_08",
    "SOCHI_STATIC_09",
    "SOCHI_STATIC_10",
                },
                medzones = {
                        { loc = "ZONE_SochiMed_01", is_open = true },
                        { loc = "ZONE_SochiMed_02", is_open = true },
                        { loc = "ZONE_SochiMed_03", is_open = true },
                        { loc = "ZONE_SochiMed_04", is_open = true },
                        { loc = "ZONE_SochiMed_05", is_open = true },
                        { loc = "ZONE_SochiMed_06", is_open = true },
                        { loc = "ZONE_SochiMed_07", is_open = true },
                        { loc = "ZONE_SochiMed_08", is_open = true },
                        { loc = "ZONE_SochiMed_09", is_open = true },
                        { loc = "ZONE_SochiMed_10", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_SochiSmall_01", is_open = true },
                        { loc = "ZONE_SochiSmall_02", is_open = true },
                        { loc = "ZONE_SochiSmall_03", is_open = true },
                        { loc = "ZONE_SochiSmall_04", is_open = true },
                        { loc = "ZONE_SochiSmall_05", is_open = true },
                        { loc = "ZONE_SochiSmall_06", is_open = true },
                        { loc = "ZONE_SochiSmall_07", is_open = true },
                        { loc = "ZONE_SochiSmall_08", is_open = true },
                        { loc = "ZONE_SochiSmall_09", is_open = true },
                        { loc = "ZONE_SochiSmall_10", is_open = true },
                },
                defassets = { -- max number of each defence asset
                        sam = 4,
                        aaa = 5,
                        manpad = 3,
                        armour = 3,
                },
                spawnobjects = {},
                is_open = true,
        },
        { -- Maykop
                striketype = "Airfield",
    strikeregion = "West",                            
                strikename = "Maykop",
                strikeivo = "AFB",
                strikecoords = "44  40  54 N | 040  02  08 E",
                strikemission = "CRATER RUNWAY AND ATTRITE AVIATION ASSETS ON THE GROUND",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_MaykopStrike",
                striketargets = {
                "MAYKOP_STATIC_01",
    "MAYKOP_STATIC_02",
    "MAYKOP_STATIC_03",
    "MAYKOP_STATIC_04",
    "MAYKOP_STATIC_05",
    "MAYKOP_STATIC_06",
    "MAYKOP_STATIC_07",
    "MAYKOP_STATIC_08",
    "MAYKOP_STATIC_09",
    "MAYKOP_STATIC_10",
    "MAYKOP_STATIC_11",
    "MAYKOP_STATIC_12",
                },
                medzones = {
                        { loc = "ZONE_MaykopMed_01", is_open = true },
                        { loc = "ZONE_MaykopMed_02", is_open = true },
                        { loc = "ZONE_MaykopMed_03", is_open = true },
                        { loc = "ZONE_MaykopMed_04", is_open = true },
                        { loc = "ZONE_MaykopMed_05", is_open = true },
                        { loc = "ZONE_MaykopMed_06", is_open = true },
                        { loc = "ZONE_MaykopMed_07", is_open = true },
                        { loc = "ZONE_MaykopMed_08", is_open = true },
                        { loc = "ZONE_MaykopMed_09", is_open = true },
                        { loc = "ZONE_MaykopMed_10", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_MaykopSmall_01", is_open = true },
                        { loc = "ZONE_MaykopSmall_02", is_open = true },
                        { loc = "ZONE_MaykopSmall_03", is_open = true },
                        { loc = "ZONE_MaykopSmall_04", is_open = true },
                        { loc = "ZONE_MaykopSmall_05", is_open = true },
                        { loc = "ZONE_MaykopSmall_06", is_open = true },
                        { loc = "ZONE_MaykopSmall_07", is_open = true },
                        { loc = "ZONE_MaykopSmall_08", is_open = true },
                        { loc = "ZONE_MaykopSmall_09", is_open = true },
                        { loc = "ZONE_MaykopSmall_10", is_open = true },
                },
                defassets = {
                        sam = 4,
                        aaa = 5,
                        manpad = 3,
                        armour = 3,
                },
                spawnobjects = {},
                is_open = true,
        },
        { -- Nalchik 
                striketype = "Airfield",
    strikeregion = "Central",                            
                strikename = "Nalchik",
                strikeivo = "AFB",
                strikecoords = "43  30  53 N | 043  38  17 E",
                strikemission = "CRATER RUNWAY AND ATTRITE AVIATION ASSETS ON THE GROUND",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_NalchikStrike",
                striketargets = {
                "NALCHIK_STATIC_01",
    "NALCHIK_STATIC_02",
    "NALCHIK_STATIC_03",
    "NALCHIK_STATIC_04",
    "NALCHIK_STATIC_05",
    "NALCHIK_STATIC_06",
    "NALCHIK_STATIC_07",
    "NALCHIK_STATIC_08",
    "NALCHIK_STATIC_09",
    "NALCHIK_STATIC_10",
                },
                medzones = {
                        { loc = "ZONE_NalchikMed_01", is_open = true },
                        { loc = "ZONE_NalchikMed_02", is_open = true },
                        { loc = "ZONE_NalchikMed_03", is_open = true },
                        { loc = "ZONE_NalchikMed_04", is_open = true },
                        { loc = "ZONE_NalchikMed_05", is_open = true },
                        { loc = "ZONE_NalchikMed_06", is_open = true },
                        { loc = "ZONE_NalchikMed_07", is_open = true },
                        { loc = "ZONE_NalchikMed_08", is_open = true },
                        { loc = "ZONE_NalchikMed_09", is_open = true },
                        { loc = "ZONE_NalchikMed_10", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_NalchikSmall_01", is_open = true },
                        { loc = "ZONE_NalchikSmall_02", is_open = true },
                        { loc = "ZONE_NalchikSmall_03", is_open = true },
                        { loc = "ZONE_NalchikSmall_04", is_open = true },
                        { loc = "ZONE_NalchikSmall_05", is_open = true },
                        { loc = "ZONE_NalchikSmall_06", is_open = true },
                        { loc = "ZONE_NalchikSmall_07", is_open = true },
                        { loc = "ZONE_NalchikSmall_08", is_open = true },
                        { loc = "ZONE_NalchikSmall_09", is_open = true },
                        { loc = "ZONE_NalchikSmall_10", is_open = true },
                },
                defassets = { 
                        sam = 4,
                        aaa = 5,
                        manpad = 3,
                        armour = 3,
                },
                spawnobjects = {},
                is_open = true,
        },
        { -- MN76 
                striketype = "Factory",
    strikeregion = "East",                            
                strikename = "MN76",
                strikeivo = "Vladikavkaz",
                strikecoords = "43  00  23 N | 044  39  02 E",
                strikemission = "DESTROY WEAPONS MANUFACTURING FACILITY\nAND ANCILLIARY SUPPORT INFRASTRUCTURE",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_MN76Strike",
                striketargets = {
                "MN76_STATIC_01",
    "MN76_STATIC_02",
    "MN76_STATIC_03",
    "MN76_STATIC_04",
    "MN76_STATIC_05",
                },
                medzones = {
                        { loc = "ZONE_MN76Med_01", is_open = true },
                        { loc = "ZONE_MN76Med_02", is_open = true },
                        { loc = "ZONE_MN76Med_03", is_open = true },
                        { loc = "ZONE_MN76Med_04", is_open = true },
                        { loc = "ZONE_MN76Med_05", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_MN76Small_01", is_open = true },
                        { loc = "ZONE_MN76Small_02", is_open = true },
                        { loc = "ZONE_MN76Small_03", is_open = true },
                        { loc = "ZONE_MN76Small_04", is_open = true },
                        { loc = "ZONE_MN76Small_05", is_open = true },
                },
                defassets = { 
                        sam = 2, 
                        aaa = 3, 
                        manpad = 2, 
                        armour = 2, 
                },
                spawnobjects = {},
                is_open = true,
        },
        { -- LN83 
                striketype = "Factory",
    strikeregion = "Central",                            
                strikename = "LN83",
                strikeivo = "Chiora",
                strikecoords = "42  44  56 N | 043  32  28 E",
                strikemission = "DESTROY WEAPONS MANUFACTURING FACILITY",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_LN83Strike",
                striketargets = {
                "LN83_STATIC_01",
                "LN83_STATIC_02",
                },
                medzones = {
                        { loc = "ZONE_LN83Med_01", is_open = true },
                        { loc = "ZONE_LN83Med_02", is_open = true },
                        { loc = "ZONE_LN83Med_03", is_open = true },
                        { loc = "ZONE_LN83Med_04", is_open = true },
                        { loc = "ZONE_LN83Med_05", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_LN83Small_01", is_open = true },
                        { loc = "ZONE_LN83Small_02", is_open = true },
                        { loc = "ZONE_LN83Small_03", is_open = true },
                        { loc = "ZONE_LN83Small_04", is_open = true },
                        { loc = "ZONE_LN83Small_05", is_open = true },
                },
                defassets = { 
                        sam = 2, 
                        aaa = 3, 
                        manpad = 2, 
                        armour = 2, 
                },
                spawnobjects = {},
                is_open = true,
        },
        { -- LN77 
                striketype = "Factory",
    strikeregion = "Central",                            
                strikename = "LN77",
                strikeivo = "Verh.Balkaria",
                strikecoords = "43  07  35 N | 043  27  24 E",
                strikemission = "DESTROY WEAPONS MANUFACTURING FACILITY\nAND COMMUNICATIONS INFRASTRUCTURE",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_LN77Strike",
                striketargets = {
                "LN77_STATIC_01",
    "LN77_STATIC_02",
    "LN77_STATIC_03",
    "LN77_STATIC_04",
                },
                medzones = {
                        { loc = "ZONE_LN77Med_01", is_open = true },
                        { loc = "ZONE_LN77Med_02", is_open = true },
                        { loc = "ZONE_LN77Med_03", is_open = true },
                        { loc = "ZONE_LN77Med_04", is_open = true },
                        { loc = "ZONE_LN77Med_05", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_LN77Small_01", is_open = true },
                        { loc = "ZONE_LN77Small_02", is_open = true },
                        { loc = "ZONE_LN77Small_03", is_open = true },
                        { loc = "ZONE_LN77Small_04", is_open = true },
                        { loc = "ZONE_LN77Small_05", is_open = true },
                },
                defassets = { 
                        sam = 2, 
                        aaa = 3, 
                        manpad = 1, 
                        armour = 3, 
                },
                spawnobjects = {},
                is_open = true,
        },
        { -- LP30 
                striketype = "Factory",
    strikeregion = "Central",                            
                strikename = "LP30",
                strikeivo = "Tyrnyauz",
                strikecoords = "43  23  43 N | 042  55  27 E",
                strikemission = "DESTROY WEAPONS MANUFACTURING FACILITY\nAND COMMUNICATIONS INFRASTRUCTURE",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_LP30Strike",
                striketargets = {
                "LP30_STATIC_01",
    "LP30_STATIC_02",
    "LP30_STATIC_03",
    "LP30_STATIC_04",
                },
                medzones = {
                        { loc = "ZONE_LP30Med_01", is_open = true },
                        { loc = "ZONE_LP30Med_02", is_open = true },
                        { loc = "ZONE_LP30Med_03", is_open = true },
                        { loc = "ZONE_LP30Med_04", is_open = true },
                        { loc = "ZONE_LP30Med_05", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_LP30Small_01", is_open = true },
                        { loc = "ZONE_LP30Small_02", is_open = true },
                        { loc = "ZONE_LP30Small_03", is_open = true },
                        { loc = "ZONE_LP30Small_04", is_open = true },
                        { loc = "ZONE_LP30Small_05", is_open = true },
                        { loc = "ZONE_LP30Small_06", is_open = true },
                        { loc = "ZONE_LP30Small_07", is_open = true },
                },
                defassets = { 
                        sam = 2, 
                        aaa = 3, 
                        manpad = 2, 
                        armour = 2, 
                },
                spawnobjects = {},
                is_open = true,
        },
        { -- GJ38 
                striketype = "Bridge",
    strikeregion = "Central",                            
                strikename = "GJ38",
                strikeivo = "Ust Dzheguta",
                strikecoords = "DMPI A 44  04  38 N | 041  58  15 E\n\nDMPI B 44  04  23 N | 041  58  34 E",
                strikemission = "DESTROY ROAD BRIDGE DMPI A AND\nRAIL BRIDGE DMPI B",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_GJ38Strike",
                striketargets = {
                        "GJ38_STATIC_01",
                },
                medzones = {
                        { loc = "ZONE_GJ38Med_01", is_open = true },
                        { loc = "ZONE_GJ38Med_02", is_open = true },
                        { loc = "ZONE_GJ38Med_03", is_open = true },
                        { loc = "ZONE_GJ38Med_04", is_open = true },
                        { loc = "ZONE_GJ38Med_05", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_GJ38Small_01", is_open = true },
                        { loc = "ZONE_GJ38Small_02", is_open = true },
                        { loc = "ZONE_GJ38Small_03", is_open = true },
                        { loc = "ZONE_GJ38Small_04", is_open = true },
                        { loc = "ZONE_GJ38Small_05", is_open = true },
                        { loc = "ZONE_GJ38Small_06", is_open = true },
                        { loc = "ZONE_GJ38Small_07", is_open = true },
                        { loc = "ZONE_GJ38Small_08", is_open = true },
                        { loc = "ZONE_GJ38Small_09", is_open = true },
                        { loc = "ZONE_GJ38Small_10", is_open = true },
                },
                defassets = { 
                        sam = 2, 
                        aaa = 4, 
                        manpad = 3, 
                        armour = 2, 
                },
                spawnobjects = {},
                is_open = true,
        },
        { -- MN72 
                striketype = "Bridge",
    strikeregion = "East",                            
                strikename = "MN72",
                strikeivo = "Kazbegi",
                strikecoords = "44  04  38 N | 041  58  15 E",
                strikemission = "DESTROY ROAD BRIDGE",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_MN72Strike",
                striketargets = {
                },
                medzones = {
                        { loc = "ZONE_MN72Med_01", is_open = true },
                        { loc = "ZONE_MN72Med_02", is_open = true },
                        { loc = "ZONE_MN72Med_03", is_open = true },
                        { loc = "ZONE_MN72Med_04", is_open = true },
                        { loc = "ZONE_MN72Med_05", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_MN72Small_01", is_open = true },
                        { loc = "ZONE_MN72Small_02", is_open = true },
                        { loc = "ZONE_MN72Small_03", is_open = true },
                        { loc = "ZONE_MN72Small_04", is_open = true },
                        { loc = "ZONE_MN72Small_05", is_open = true },
                        { loc = "ZONE_MN72Small_06", is_open = true },
                        { loc = "ZONE_MN72Small_07", is_open = true },
                        { loc = "ZONE_MN72Small_08", is_open = true },
                        { loc = "ZONE_MN72Small_09", is_open = true },
                        { loc = "ZONE_MN72Small_10", is_open = true },
                },
                defassets = { 
                        sam = 2, 
                        aaa = 4, 
                        manpad = 2, 
                        armour = 2, 
                },
                spawnobjects = {},
                is_open = true,
        },
        { -- GJ21 
                striketype = "Bridge",
    strikeregion = "Central",                            
                strikename = "GJ21",
                strikeivo = "Teberda",
                strikecoords = "43  26  47 N | 041  44  28 E",
                strikemission = "DESTROY ROAD BRIDGE",
                strikethreats = "RADAR SAM, I/R SAM, AAA, LIGHT ARMOUR",
                strikezone = "ZONE_GJ21Strike",
                striketargets = {
                },
                medzones = {
                        { loc = "ZONE_GJ21Med_01", is_open = true },
                        { loc = "ZONE_GJ21Med_02", is_open = true },
                        { loc = "ZONE_GJ21Med_03", is_open = true },
                        { loc = "ZONE_GJ21Med_04", is_open = true },
                        { loc = "ZONE_GJ21Med_05", is_open = true },
                },
                smallzones = {
                        { loc = "ZONE_GJ21Small_01", is_open = true },
                        { loc = "ZONE_GJ21Small_02", is_open = true },
                        { loc = "ZONE_GJ21Small_03", is_open = true },
                        { loc = "ZONE_GJ21Small_04", is_open = true },
                        { loc = "ZONE_GJ21Small_05", is_open = true },
                        { loc = "ZONE_GJ21Small_06", is_open = true },
                        { loc = "ZONE_GJ21Small_07", is_open = true },
                        { loc = "ZONE_GJ21Small_08", is_open = true },
                        { loc = "ZONE_GJ21Small_09", is_open = true },
                        { loc = "ZONE_GJ21Small_10", is_open = true },
                },
                defassets = { 
                        sam = 2, 
                        aaa = 4, 
                        manpad = 1, 
                        armour = 2, 
                },
                spawnobjects = {},
                is_open = true,
        },
}


--------------------------------------
--- strike Defence spawn templates ---
--------------------------------------

TableDefTemplates = {
        sam = {
                "SAM_Sa3Battery",
                "SAM_Sa6Battery",
        },
        aaa = {
                "AAA_Zu23Ural",
                "AAA_Zu23Emplacement",
                "AAA_Zu23Closed",
                "AAA_Zsu23Shilka",
        },
        manpads = {
                "SAM_Sa18Manpads",
                "SAM_Sa18sManpads",
        },
        armour = {
                "CAMP_Heavy_01",
                "CAMP_Heavy_02",
                "CAMP_Heavy_03",
                "CAMP_Heavy_04",
        },
}

-------------------------------------------
--- generate strike defence spawn stubs ---
-------------------------------------------

StrikeAttackSpawn = SPAWN:New( "DEF_Stub" )

for k, v in pairs(TableDefTemplates) do
        for count = 1, #v do
                        local templatename = v[ count ]
                        local stubname = "DEFSTUB_" .. templatename
                        _G[ stubname ] = SPAWN:New( templatename )
        end
end

TableStaticTemplates = {
        target = {
                "FACTORY_Workshop",
                "FACTORY_Techcombine",
        },
        buildings = {
                
        },
}

------------------------------------------
--- menu: generate strike attack menus ---
------------------------------------------

for strikeIndex, strikeValue in pairs(TableStrikeAttack) do -- step through TableStrikeAttack and grab the mission data for each key ( = "location")

        local strikeType = strikeValue.striketype
        local strikeRegion = strikeValue.strikeregion
        local strikeName = strikeValue.strikename
        local StrikeIvo = strikeValue.strikeivo

        _G["Menu" .. strikeType .. "Attack" .. strikeIndex] = MENU_COALITION:New( coalition.side.BLUE, strikeName .. " " .. StrikeIvo, _G["Menu" .. strikeType .. "Attack" .. strikeRegion] ) -- add menu for each mission location in the correct strike type sub menu
        _G["Cmd" .. strikeIndex .. "Attack"] = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Start Mission", _G["Menu" .. strikeType .. "Attack" .. strikeIndex], SpawnStrikeAttack, strikeIndex ) -- add menu command to launch the mission

end



-- END strike ATTACK SECTION    


--- END MAIN
 
env.info( '*** JTF-1 MOOSE MISSION SCRIPT END ***' )
 
