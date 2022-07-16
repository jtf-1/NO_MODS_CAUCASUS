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