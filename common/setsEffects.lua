local activeModule = "Sets effects";

-- --------------------------------------------------------------------
-- **                        Sets effects table                      **
-- --------------------------------------------------------------------

local list = {
    number = 0,
};

local lookupData = {};

--[[
*** Type list:
MULTIPLY_THREAT - The threat is multiplied by a coefficient. Coefficient can vary between ranks.
ADDITIVE_THREAT - A fixed value is added to threat, which can vary between ranks.
BASE_THREAT - The base threat is modified by a flat value. If initial base threat is > 0 then it won't be able to pass below the 0 threat threshold.
FINAL_THREAT - The final threat (after all multipliers are applied) is modified by a flat value. This type follows same threshold rules as BASE_THREAT.

*** Target list:
GLOBAL_THREAT - The set effect modifies the global threat multiplier of _INCOMING_ threatening actions.
ABILITIES - The set effect modifies the threat multiplier of some specific abilities.

*** Conditions:
[NO]SPECIAL:X - X can be CRITICAL, CRUSHING or GLANCING. The effect only operates in case of a special hit [or not].
[NO]TIMING:X - X can be INSTANT or OVERTIME.

]]

local DTM_Sets_Effects = {
    -- Druid sets effects

    ["THUNDERHEART_MANGLE_BEAR"] = { -- "Increases threat generated by your mangle (bear) ability by 15%."
        set = "THUNDERHEART",
        piecesRequirement = 2,
        effect = {
            type = "MULTIPLY_THREAT",
            value = 1.15,
            target = "ABILITIES",
            abilities = {
                number = 1,
                [1] = "MANGLE_BEAR",
            }
        }
    },

    -- Hunter sets effects
    -- <None>

    -- Mage sets effects

    ["ARCANIST_THREATMOD"] = { -- "Decreases the threat generated by your spells by 15%."
        set = "ARCANIST",
        piecesRequirement = 8,
        effect = {
            type = "MULTIPLY_THREAT",
            value = 0.85,
            target = "GLOBAL_THREAT",
        }
    },
    ["NETHERWIND_SPELLTHREATMOD_1"] = { -- "Reduces the threat generated by your [Scorch], Arcane Missiles, Fireball, and [Frostbolt] spells."
        set = "NETHERWIND",
        piecesRequirement = 3,
        effect = {
            type = "BASE_THREAT",
            value = -100,
            target = "ABILITIES",
            abilities = {
                number = 2,
                [1] = "SCORCH",
                [2] = "FROSTBOLT",
            }
        }
    },
    ["NETHERWIND_SPELLTHREATMOD_2"] = { -- "Reduces the threat generated by your Scorch, [Arcane Missiles], [Fireball], and Frostbolt spells."
        set = "NETHERWIND",
        piecesRequirement = 3,
        effect = {
            type = "BASE_THREAT",
            value = -20,
            target = "ABILITIES",
            abilities = {
                number = 2,
                [1] = "ARCANE_MISSILES",
                [2] = "FIREBALL",
            }
        }
    },

    -- Paladin sets effects
    -- <None>

    -- Priest sets effects
    -- <None>

    -- Rogue sets effects

    ["BLOODFANG_FEINTMOD"] = { -- "Improves the threat reduction of Feint by 25%."
        set = "BLOODFANG",
        piecesRequirement = 5,
        effect = {
            type = "MULTIPLY_THREAT",
            value = 1.25,
            target = "ABILITIES",
            abilities = {
                number = 1,
                [1] = "FEINT",
            }
        }
    },
    ["BONESCYTHE_THREATMOD"] = { -- "Reduces the threat from your Backstab, Sinister Strike, Hemorrhage, and Eviscerate abilities."
        set = "BONESCYTHE",
        piecesRequirement = 6,
        effect = {
            type = "MULTIPLY_THREAT",
            value = 0.92,
            target = "ABILITIES",
            abilities = {
                number = 4,
                [1] = "BACKSTAB",
                [2] = "SINISTER_STRIKE",
                [3] = "HEMORRHAGE",
                [4] = "EVISCERATE",
            }
        }
    },

    -- Shaman sets effects
    -- <None>

    -- Warlock sets effects

    ["NEMESIS_SPELLTHREATMOD"] = { -- "Reduces the threat generated by your Destruction spells by 20%."
        set = "NEMESIS",
        piecesRequirement = 8,
        effect = {
            type = "MULTIPLY_THREAT",
            value = 0.80,
            target = "ABILITIES",
            abilities = {
                number = 10,
                [1] = "SHADOW_BOLT",
                [2] = "IMMOLATE",
                [3] = "SEARING_PAIN",
                [4] = "RAIN_OF_FIRE",
                [5] = "HELLFIRE",
                [6] = "SOUL_FIRE",
                [7] = "INCINERATE",
                [8] = "SHADOWBURN",
                [9] = "CONFLAGRATE",
                [10] = "SHADOWFURY",
            }
        }
    },
    ["PLAGUEHEART_SPELLTHREATMOD"] = { -- "Critical hits generate 25% less threat. [In addition, Corruption, Immolate, Curse of Agony, and Siphon Life generate 25% less threat.]"
        set = "PLAGUEHEART",
        piecesRequirement = 6,
        effect = {
            type = "MULTIPLY_THREAT",
            value = 0.75,
            target = "ABILITIES",
            abilities = {
                number = 4,
                [1] = "CORRUPTION",
                [2] = "IMMOLATE",
                [3] = "CURSE_OF_AGONY",
                [4] = "SIPHON_LIFE",
            }
        }
    },
    ["PLAGUEHEART_CRITICALTHREATMOD"] = { -- "[Critical hits generate 25% less threat.] In addition, ..."
        set = "PLAGUEHEART",
        piecesRequirement = 6,
        effect = {
            type = "MULTIPLY_THREAT",
            value = 0.75,
            target = "GLOBAL_THREAT",
            condition = "SPECIAL:CRITICAL",
        }
    },

    -- Warrior sets effects

    ["MIGHT_ABILITYTHREATMOD"] = { -- "Increases the threat generated by Sunder Armor and Devastate by 15%."
        set = "MIGHT",
        piecesRequirement = 8,
        effect = {
            type = "MULTIPLY_THREAT",
            value = 1.15,
            target = "ABILITIES",
            abilities = {
                number = 2,
                [1] = "SUNDER_ARMOR",
                [2] = "DEVASTATE",
            }
        }
    },

    -- Testing sets effects (remove for normal builds)

};

-- --------------------------------------------------------------------
-- **                     Sets effects functions                     **
-- --------------------------------------------------------------------

-- ********************************************************************
-- * DTM_SetsEffects_GetData(setEffectInternal)                       *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> setEffectInternal: the internal name of the set effect.       *
-- ********************************************************************
-- * Get data about a set effect.                                     *
-- * Returns:                                                         *
-- *   - Internal name of the set the set effect belongs to.          *
-- *   - The number of pieces required to enable the set effect.      *
-- *   - .effect field of the set effect (a table). (See above)       *
-- ********************************************************************

function DTM_SetsEffects_GetData(setEffectInternal)
    local setEffectData = DTM_Sets_Effects[setEffectInternal];

    if ( setEffectData ) then
        return setEffectData.set, setEffectData.piecesRequirement, setEffectData.effect;
    end

    return "UNKNOWN", 0, nil;
end


-- ********************************************************************
-- * DTM_SetsEffects_DoListing(effect, target, ability)               *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> effect: the effect the set effect must have to be listed.     *
-- * >> target: what the set effect must affect to be listed.         *
-- * >> ability: the ability the set effect must affect to be listed. *
-- ********************************************************************

function DTM_SetsEffects_DoListing(effect, target, ability)
    for k, v in ipairs(list) do
        list[k] = nil;
    end

    -- Lookup feature to increase performance time.
    local lookupKey = (effect or "?")..":"..(target or "?")..":"..(ability or "?");
    local lookupTable = lookupData[lookupKey];
    if ( lookupTable ) then
        list.number = lookupTable.number;
        local i;
        for i=1, list.number do
            list[i] = lookupTable[i];
        end
        return;
    end

    -- Lookup not found, we'll do it this call.
    lookupData[lookupKey] = {};

    local matchFound = 0;
    local matching;

    for name, data in pairs(DTM_Sets_Effects) do
        local setEffect = data.effect;

        matching = 1;

        if ( effect ) then
            if ( setEffect.type ~= effect ) then
                matching = nil;
            end
        end

        if ( target ) then
            if ( setEffect.target ~= target ) then
                matching = nil;
            end
        end

        local abilityData = setEffect.abilities;
        if ( ability ) and ( abilityData ) then
            found = nil;
            for i=1, (abilityData.number or 0) do
                if abilityData[i] == ability then
                    found = 1;
                    break;
                end
            end
            if not found then
                matching = nil;
            end
        end
        if ( ability ) and not ( abilityData ) then matching = nil; end

        if ( matching ) then
            matchFound = matchFound + 1;
            list[matchFound] = name;
            lookupData[lookupKey][matchFound] = name;
        end
    end

    list.number = matchFound;
    lookupData[lookupKey].number = matchFound;
end

-- ********************************************************************
-- * DTM_SetsEffects_GetListSize()                                    *
-- ********************************************************************
-- * Arguments:                                                       *
-- *   <none>                                                         *
-- ********************************************************************
-- * Get the size of the list created with the set effect research    *
-- * function DoListing.                                              *
-- ********************************************************************

function DTM_SetsEffects_GetListSize()
    return list.number or 0;
end

-- ********************************************************************
-- * DTM_SetsEffects_GetListData(index)                               *
-- ********************************************************************
-- * Arguments:                                                       *
-- * >> index: ...of the set effect in the list to get.               *
-- ********************************************************************
-- * Get effect data from the list.                                   *
-- * Returns:                                                         *
-- *   - Internal name of the set effect.                             *
-- *   - Internal name of the set the set effect belongs to.          *
-- *   - The number of pieces required to enable the set effect.      *
-- *   - .effect field of the set effect (a table). (See above)       *
-- ********************************************************************

function DTM_SetsEffects_GetListData(index)
    local setEffectInternal = list[index] or "UNKNOWN";
    return setEffectInternal, DTM_SetsEffects_GetData(setEffectInternal);
end
