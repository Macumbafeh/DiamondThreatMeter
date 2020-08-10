local activeModule = "Engine units";

-- --------------------------------------------------------------------
-- ////////////////////////////////////////////////////////////////////
-- --                          ENGINE PART                           --
-- \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
-- --------------------------------------------------------------------

local UIDLookup = { };
local UnitList = { };
local complex = { };

-- --------------------------------------------------------------------
-- **                              API                               **
-- --------------------------------------------------------------------

-- ********************************************************************
-- * DTM_Unit_SearchEffect(unit, internalName)                        *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> unit: the unit that will be affected by the search.           *
-- * >> internalName: the internal name of the effect to find.        *
-- ********************************************************************
-- * Returns 1, rank, count, timeLeft if the specified effect is found*
-- * Elsewise nil, nil, nil, nil is returned.                         *
-- * The effect can be either a buff or debuff, it doesn't matter.    *
-- ********************************************************************
function DTM_Unit_SearchEffect(unit, internalName)
    if not ( unit ) or not ( internalName ) then
        return nil;
    end

    -- If this is a cached effect, check if we have cached data.
    local effectClass, effectAlwaysActive, effectEffect = DTM_Effects_GetData(internalName);
    if ( effectEffect ) then
        if ( effectEffect.cache ) then
            -- It is. Check if it is applied on the unit.
            local timeRemaining = DTM_Time_GetEffectCacheData(UnitGUID(unit), internalName);
            if ( timeRemaining ) then
                return 1, nil, nil, timeRemaining;
            end
            return nil, nil, nil, nil;
        end
    end

    -- It's preferable use the localised name, so unlocalize the internal name.
    local localisedName = DTM_ReverseInternal("effects", internalName);
    if not ( localisedName ) then return nil; end

    local i;
    for i=1, 50 do
        local name, rank, iconTexture, count, duration, timeLeft = UnitBuff(unit, i);
        if not ( name ) then
            break;
      elseif ( name == localisedName ) then
            return 1, rank, count, timeLeft;
        end
    end
    for i=1, 40 do
        local name, rank, texture, count, debuffType, duration, timeLeft = UnitDebuff(unit, i);
        if not ( name ) then
            break;
      elseif ( name == localisedName ) then
            return 1, rank, count, timeLeft;
        end
    end
    return nil, nil, nil, nil;
end

-- ********************************************************************
-- * DTM_CanGetHealth(unit)                                           *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> unit: the unit to check.                                      *
-- ********************************************************************
-- * Determinate if UnitHealth will return you exact HP of given unit.*
-- ********************************************************************
function DTM_CanGetHealth(unit)
    if not ( unit ) then return; end
    if ( DTM_OnWotLK() ) then return 1; end
    if (UnitHealthMax( unit ) ~= 100) then return 1; end
    return UnitIsUnit("player", unit);
end

-- ********************************************************************
-- * DTM_RebuildUnitList()                                            *
-- ********************************************************************
-- * Arguments:                                                       *
-- *    <none>                                                        *
-- ********************************************************************
-- * Calling this API will ask a complete reconstruction of           *
-- * accessable units by either their name or GUID.                   *
-- * RebuildUnitList should be called whenever any UID changes or at  *
-- * a reasonnable periodic update rate.                              *
-- ********************************************************************
function DTM_RebuildUnitList()
    local k, i;

    -- Clean up
    for k in ipairs(complex) do
        complex[k] = nil;
    end
    for k in ipairs(UnitList) do
        UnitList[k] = nil;
    end
    for k in pairs(UIDLookup) do
        UIDLookup[k] = nil;
    end

    -- Upvalue
    local Add = DTM_AddUnitToList;

    -- Simple unitIDs

    Add("player");
    if Add("pet") then complex[#complex+1] = "pet"; end
    if Add("target") then complex[#complex+1] = "target"; end
    if Add("focus") then complex[#complex+1] = "focus"; end
    if Add("mouseover") then complex[#complex+1] = "mouseover"; end

    -- Dynamic unitIDs

    local unitId, petUnitId;

    if ( GetNumRaidMembers() > 0 ) then
        for i=1, GetNumRaidMembers(), 1 do
            unitId = "raid"..i;
            if Add(unitId) then
                complex[#complex+1] = unitId;
                petUnitId = "raidpet"..i;
                if Add(petUnitId) then complex[#complex+1] = petUnitId; end
            end
        end
  else
        for i=1, GetNumPartyMembers(), 1 do
            unitId = "party"..i;
            if Add(unitId) then
                complex[#complex+1] = unitId;
                petUnitId = "partypet"..i;
                if Add(petUnitId) then complex[#complex+1] = petUnitId; end
            end
        end
    end

    -- Complex unitIDs

    local nest, safety;

    for i=1, #complex, 1 do
        nest = complex[i].."target";
        safety = 0;
        while Add(nest) and safety < 50 do
            nest = nest.."target";
            safety = safety + 1;
        end
    end
end

-- ********************************************************************
-- * DTM_AddUnitToList(unit)                                          *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> unit: the unit to add to the unit list and lookup table.      *
-- ********************************************************************
-- * This will add the given unit's name and guid to the lookup table *
-- * and create if it doesn't exist yet an entry for the unit in the  *
-- * global unit list.                                                *
-- * Returns nil if the unit has already been referenced (through     *
-- * another but equivalent UID for exemple) or if the unit doesn't   *
-- * exist.                                                           *
-- * Returns 1 if the unit has been added to the list successfully.   *
-- ********************************************************************
function DTM_AddUnitToList(unit)
    if not ( UnitExists(unit) ) then return nil; end
    local name = UnitName(unit);
    local guid = UnitGUID(unit);
    if not ( UIDLookup[name] ) then UIDLookup[name] = unit; end
    if not ( UIDLookup[guid] ) then
        -- GUID still not in the lookup. First occurence of this entity in the list.
        UIDLookup[guid] = unit;
        UnitList[#UnitList+1] = guid.."|"..name;
        return 1;
    end
    return nil;
end

-- ********************************************************************
-- * DTM_GetNumUnits()                                                *
-- ********************************************************************
-- * Arguments:                                                       *
-- *    <none>                                                        *
-- ********************************************************************
-- * Get the numbers of different units that are listed in the global *
-- * unit list. No unit apparears twice in this list, so if Bob can   *
-- * be accessed from "player" and "target" UIDs, the UID that will   *
-- * be kept to access Bob will be "player".                          *
-- ********************************************************************
function DTM_GetNumUnits()
    return #UnitList;
end

-- ********************************************************************
-- * DTM_GetUnitInfo(index)                                           *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> index: the index to get info about in the global unit list.   *
-- ********************************************************************
-- * This function allows you to explore the global unit list by      *
-- * passing the index of the element of the list you want to get     *
-- * infos from. GUID and name will then be returned.                 *
-- ********************************************************************
function DTM_GetUnitInfo(index)
    local info = UnitList[index];
    if info then
        return strsplit("|", info, 2);
    end
    return nil;
end

-- ********************************************************************
-- * DTM_GetUnitPointer(value)                                        *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> value: the name *OR* GUID to search an UID for.               *
-- ********************************************************************
-- * This function tries to find an unitId which points to the unit   *
-- * name or GUID you specified.                                      *
-- * Be aware that this function will fail most of the time,          *
-- * except if the unit you want to get info from is your current,    *
-- * target/focus your pet, yourself or a party/raid member.          *
-- * Return an UID (like 'player', 'targettargettarget') or nil.      *
-- ********************************************************************
function DTM_GetUnitPointer(value)
    if not ( value ) then return nil; end

    local expectedUID = UIDLookup[value];

    if ( expectedUID ) then
        local name = UnitName(expectedUID);
        local guid = UnitGUID(expectedUID);

        if ( value == name or value == guid ) then -- Safety check in case UIDs have changed in-between.
            return expectedUID;
        end
    end

    return nil;
end

-- ********************************************************************
-- * DTM_GetGroupPointer(value)                                       *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> value: the name *OR* GUID to search an UID for.               *
-- ********************************************************************
-- * This function tries to find an unitId which points to the unit   *
-- * name or GUID you specified that is in your party or raid.        *
-- * Return a self/party/raid UID (like 'player', 'party3') or nil.   *
-- ********************************************************************
function DTM_GetGroupPointer(value)
    if not ( value ) then return nil; end

    local uid = DTM_GetUnitPointer(value);

    if ( uid ) then
        if ( UnitInParty(uid) or UnitInRaid(uid) ) then
            return uid;
        end
    end

    return nil;
end

-- ********************************************************************
-- * DTM_GetPetMasterPointer(petUnitId)                               *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> petUnitId: the UID of the pet to get the master's UID from.   *
-- ********************************************************************
-- * This function tries to find the UID of the master of the given   *
-- * pet UID in the raid or party (including yourself).               *
-- ********************************************************************
function DTM_GetPetMasterPointer(petUnitId)
    if not ( petUnitId ) then return nil; end

    local i;

    -- Self pet ID

    if ( UnitIsUnit('pet', petUnitId) ) then return 'player'; end

    -- Raid/party pet ID

    if ( GetNumRaidMembers() > 0 ) then
        for i=1, GetNumRaidMembers(), 1 do
            if ( UnitIsUnit('raidpet'..i, petUnitId) ) then return 'raid'..i; end
        end
  else
        if ( GetNumPartyMembers() > 0 ) and not ( ignoreParty ) then
            for i=1, GetNumPartyMembers(), 1 do
                if ( UnitIsUnit('partypet'..i, petUnitId) ) then return 'party'..i; end
            end
        end 
    end

    return nil;
end

-- ********************************************************************
-- * DTM_GetUnitTypeFromGUID(guid)                                    *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> guid: the GUID of who is checked.                             *
-- ********************************************************************
-- * Determinates the unit type of the unit a GUID belongs to.        *
-- * Will either return "npc", "player" or "pet".                     *
-- * "unknown" may be returned in case of erroneous data.             *
-- ********************************************************************
function DTM_GetUnitTypeFromGUID(guid)
    if ( not guid ) then return "unknown"; end
    local typeCreature = tonumber(string.sub(guid, 5, 5), 16);
    local isPlayer = bit.band(typeCreature, 0x00f) == 0;
    local isNPC = bit.band(typeCreature, 0x00f) == 3;
    local isPet = bit.band(typeCreature, 0x00f) == 4;
    if ( isPlayer ) then return "player"; end
    if ( isNPC ) then return "npc"; end
    if ( isPet ) then return "pet"; end
    return "unknown";
end

-- ********************************************************************
-- * DTM_CanHoldThreatList(unit)                                      *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> unitId: the unit ID to check.                                 *
-- ********************************************************************
-- * Determinates if an unit can hold a threat list.                  *
-- * Will return nil for any player entity.                           *
-- * Will return nil for ignored/no-threat-list-flagged NPCs.         *
-- * Will return 1 for the rest.                                      *
-- ********************************************************************
function DTM_CanHoldThreatList(unit)
    if ( not unit ) then return nil; end
    if ( not UnitExists(unit) ) then return nil; end
    if ( UnitIsPlayer(unit) ) then return nil; end
    -- if ( UnitPlayerControlled(unit) ) then return nil; end

    local noThreatList = DTM_UnitThreatFlags(unit);
    if ( noThreatList == 1 ) then return nil; end

    local guid = UnitGUID(unit);
    if ( DTM_IsMobIgnored(guid) ) then return nil; end

    return 1;
end

-- ********************************************************************
-- * DTM_CanHoldThreatListLimited(guid)                               *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> guid: the GUID of who is checked.                             *
-- ********************************************************************
-- * Determinates if an unit can hold a threat list by knowing only   *
-- * its GUID. This function is well suited for combat events parsing *
-- * as it does not involve UIDs that could be not useable.           *
-- ********************************************************************
function DTM_CanHoldThreatListLimited(guid)
    if ( DTM_GetUnitTypeFromGUID(guid) == "player" ) then return nil; end
    if ( DTM_IsMobIgnored(guid) ) then return nil; end
    return 1;
end

-- --------------------------------------------------------------------
-- **                            Handlers                            **
-- --------------------------------------------------------------------

-- ********************************************************************
-- * DTM_UnitCheckCombatChange(unit)                                  *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> unit: the unit whose flags are changed.                       *
-- ********************************************************************
-- * Gets called when an unit's flags are changed, such as combat     *
-- * state. It's a good occasion to check an unit has changed its     *
-- * combat state.                                                    *
-- ********************************************************************
function DTM_UnitCheckCombatChange(unit)
    if not ( unit ) then return; end

    local guid, combat, previousCombat;

    guid = UnitGUID(unit);
    combat = UnitAffectingCombat(unit);
    previousCombat = DTM_Combat[guid] or nil;

    if ( combat ) and not ( previousCombat ) then
        DTM_UnitBeginCombat(unit);
elseif not ( combat ) and ( previousCombat ) then
        DTM_UnitLeaveCombat(unit);
    end

    DTM_Combat[guid] = combat;
end

-- ********************************************************************
-- * DTM_UnitBeginCombat(unit)                                        *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> unit: the unit who entered combat mode.                       *
-- ********************************************************************
-- * Gets called when a supported unit enters combat mode.            *
-- * Supported units: partyX, raidX, partypetX, raidpetX, player, pet * 
-- ********************************************************************
function DTM_UnitBeginCombat(unit)
    -- Nothing special to do.
end

-- ********************************************************************
-- * DTM_UnitLeaveCombat(unit)                                        *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> unit: the unit who left combat mode.                          *
-- ********************************************************************
-- * Gets called when a supported unit leaves combat mode.            *
-- * Supported units: partyX, raidX, partypetX, raidpetX, player, pet * 
-- ********************************************************************
function DTM_UnitLeaveCombat(unit)
    local leaverGUID = UnitGUID(unit);

    if ( leaverGUID ) then
        -- Delete the data of the unit and everything linked to it.
        -- Time events etc. will be implicitly removed as well.
        DTM_EntityData_DeleteByGUID(leaverGUID);
    end
end

-- ********************************************************************
-- * DTM_PlayerTargetChanged()                                        *
-- ********************************************************************
-- * Arguments:                                                       *
-- *    <none>                                                        *
-- ********************************************************************
-- * Gets called when local player's target has changed.              *
-- ********************************************************************
function DTM_PlayerTargetChanged()
    DTM_RequestUnitListRebuild();
    DTM_CheckUnitReset("target");
end

-- ********************************************************************
-- * DTM_PlayerFocusChanged()                                         *
-- ********************************************************************
-- * Arguments:                                                       *
-- *    <none>                                                        *
-- ********************************************************************
-- * Gets called when local player's focus has changed.               *
-- ********************************************************************
function DTM_PlayerFocusChanged()
    DTM_RequestUnitListRebuild();
    DTM_CheckUnitReset("focus");
end

-- ********************************************************************
-- * DTM_PlayerMouseoverChanged()                                     *
-- ********************************************************************
-- * Arguments:                                                       *
-- *    <none>                                                        *
-- ********************************************************************
-- * Gets called when local player's mouseover has changed.           *
-- ********************************************************************
function DTM_PlayerMouseoverChanged()
    DTM_RequestUnitListRebuild();
    DTM_CheckUnitReset("mouseover");
end

-- ********************************************************************
-- * DTM_UnitTargetChanged(unitId)                                    *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> unitId: the unit who has changed its target.                  *
-- ********************************************************************
-- * Gets called when an unit's target has changed.                   *
-- ********************************************************************
function DTM_UnitTargetChanged(unitId)
    DTM_RequestUnitListRebuild();
end

-- ********************************************************************
-- * DTM_RequestUnitListRebuild()                                     *
-- ********************************************************************
-- * Arguments:                                                       *
-- *    <none>                                                        *
-- ********************************************************************
-- * Gets called when we have to rebuild the unit list.               *
-- ********************************************************************
function DTM_RequestUnitListRebuild()
    DTM_RebuildUnitList();

    -- Browse the new unit list for combat change, target change, symbol change etc.

    local i, guid, name, ptr;
    for i=1, DTM_GetNumUnits() do
        guid, name = DTM_GetUnitInfo(i);
        ptr = DTM_GetUnitPointer(guid);

        if ( ptr ) then
            DTM_CheckTargetOfUnitChange(ptr);
            DTM_SymbolsBuffer_RaidTargetUpdated(ptr);
            DTM_UnitCheckCombatChange(ptr);
        end
    end

    -- Schedule the next update.

    DTM_Update["UNIT_LIST"] = GetTime() + DTM_GetSavedVariable("engine", "unitListUpdateInterval", "active");
end

-- ********************************************************************
-- * DTM_Unit_Update()                                                *
-- ********************************************************************
-- * Arguments:                                                       *
-- *   <none>                                                         *
-- ********************************************************************
-- * Does periodic operations on the unit list, like rebuilding it.   *
-- ********************************************************************
function DTM_Unit_Update()
    if ( GetTime() > (DTM_Update["UNIT_LIST"] or 0) ) then
        DTM_RequestUnitListRebuild();
    end
end