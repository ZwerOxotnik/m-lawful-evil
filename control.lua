if script.level.campaign_name then return end

require 'stdlib/event/event'
require 'stdlib/gui/gui'
require 'stdlib/player'
require 'stdlib/game'
local mod_gui = require("mod-gui")


local get_player_data = Player.get_data
local set_player_data = Player.set_data


local WHEN_PLAYER_BUILDS = "player-builds"
local WHEN_PLAYER_MINES = "player-mines"
local WHEN_PLAYER_DAMAGES = "player-damages"
local WHEN_PLAYER_DESTROYS = "player-destroys"
local WHEN_PLAYER_CRAFTS = "player-crafts"
local WHEN_PLAYER_TILES = "player-tiles"
local WHEN_PLAYER_MINES_TILE = "player-mines-tiles"
local WHEN_PLAYER_KILLS = "player-kills-player"
local WHEN_FORCE_RESEARCHES = "force-researches"
local WHEN_ROCKET_LAUNCHES = "rocket-launched"
local WHEN_PLAYER_CHATS = "player-chats"
local WHEN_PLAYER_RESPAWNS = "player-respawns"
local WHEN_THIS_LAW_PASSED = "this-law-passed"
local WHEN_VALUE = "value"
local WHEN_DAY = "daytime"
local WHEN_NIGHT = "nighttime"

local CLAUSE_TYPES = {
    [WHEN_PLAYER_BUILDS] = {
        localised_text = "a player builds",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        order = "a",
        has_elem_picker = true,
        elem_picker_type = "entity",
        inverse_rule = WHEN_PLAYER_MINES
    },
    [WHEN_PLAYER_MINES] = {
        localised_text = "a player mines",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        order = "b",
        has_elem_picker = true,
        elem_picker_type = "entity",
        inverse_rule = WHEN_PLAYER_BUILDS
    },
    [WHEN_PLAYER_DAMAGES] = {
        localised_text = "a player damages",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        has_elem_picker = true,
        elem_picker_type = "entity",
        order = "c"
    },
    [WHEN_PLAYER_DESTROYS] = {
        localised_text = "a player destroys",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        has_elem_picker = true,
        elem_picker_type = "entity",
        order = "d"
    },
    [WHEN_PLAYER_CRAFTS] = {
        localised_text = "a player destroys",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        has_elem_picker = true,
        elem_picker_type = "item",
        order = "e"
    },
    [WHEN_PLAYER_TILES] = {
        localised_text = "a player tiles",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        order = "fa",
        has_elem_picker = true,
        elem_picker_type = "item",
        inverse_rule = WHEN_PLAYER_MINES_TILE
    },
    [WHEN_PLAYER_MINES_TILE] = {
        localised_text = "a player mines tiles",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        order = "fb",
        has_elem_picker = true,
        elem_picker_type = "item",
        inverse_rule = WHEN_PLAYER_TILES
    },
    [WHEN_PLAYER_KILLS] = {
        localised_text = "a player kills a player",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        order = "g"
    },
    [WHEN_PLAYER_CHATS] = {
        localised_text = "a player chats",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        order = "ha"
    },
    [WHEN_FORCE_RESEARCHES] = {
        localised_text = "force researches",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        order = "hb"
    },
    [WHEN_ROCKET_LAUNCHES] = {
        localised_text = "a rocket is launched",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        order = "i"
    },
    [WHEN_THIS_LAW_PASSED] = {
        localised_text = "this law is passed",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        order = "j"
    },
    [WHEN_VALUE] = {
        localised_text = "a value",
        base_allowed = false,
        and_allowed = true,
        or_allowed = true,
        order = "k"
    },
    [WHEN_DAY] = {
        localised_text = "it's daytime",
        base_allowed = false,
        and_allowed = true,
        or_allowed = true,
        order = "l"
    },
    [WHEN_NIGHT] = {
        localised_text = "it's nighttime",
        base_allowed = false,
        and_allowed = true,
        or_allowed = true,
        order = "m"
    },
    [WHEN_PLAYER_RESPAWNS] = {
        localised_text = "a player respawns",
        base_allowed = true,
        and_allowed = false,
        or_allowed = true,
        order = "n"
    },
}

-- local ELEM_ENTITY = 1
-- local ELEM_ITEM = 2
-- local ELEM_FLUID = 3

local EFFECT_TYPE_ITEMS = {
    {"lawful-evil.effect_type.fine"},
    {"lawful-evil.effect_type.reward"},
    {"lawful-evil.effect_type.alert"},
    {"lawful-evil.effect_type.disallow"},
    {"lawful-evil.effect_type.license"},
    {"lawful-evil.effect_type.death-penalty"},
    {"lawful-evil.effect_type.kick-from-server"},
    {"lawful-evil.effect_type.ban-from-server"},
    {"lawful-evil.effect_type.mute-player"},
    {"lawful-evil.effect_type.unmute-player"},
    {"lawful-evil.effect_type.if-fine-fails"},
    {"lawful-evil.effect_type.if-nth-offence"},
    {"lawful-evil.effect_type.reset-offence-count"},
    {"lawful-evil.effect_type.revoke-law"},
    {"lawful-evil.effect_type.custom-script"}
}
local EFFECT_TYPE_FINE = 1
local EFFECT_TYPE_REWARD = 2
local EFFECT_TYPE_ALERT = 3
local EFFECT_TYPE_DISALLOW = 4
local EFFECT_TYPE_LICENSE = 5
local EFFECT_TYPE_KILL = 6
local EFFECT_TYPE_KICK = 7
local EFFECT_TYPE_BAN = 8
local EFFECT_TYPE_MUTE = 9
local EFFECT_TYPE_UNMUTE = 10
local EFFECT_TYPE_FINE_FAIL = 11
local EFFECT_TYPE_NTH_OFFENCE = 12
local EFFECT_TYPE_RESET_OFFENCE = 13
local EFFECT_TYPE_REVOKE_LAW = 14
local EFFECT_TYPE_CUSTOM_SCRIPT = 15

local EFFECT_LICENSE_TYPE_ITEMS = {
    {"lawful-evil.effect_license_type.car-license"},
    {"lawful-evil.effect_license_type.tank-license"},
    {"lawful-evil.effect_license_type.train-license"},
    {"lawful-evil.effect_license_type.gun-license"},
    {"lawful-evil.effect_license_type.artillery-license"}
}
local EFFECT_LICENSE_TYPE_CAR = 1
local EFFECT_LICENSE_TYPE_TANK = 2
local EFFECT_LICENSE_TYPE_TRAIN = 3
local EFFECT_LICENSE_TYPE_GUN = 4
local EFFECT_LICENSE_TYPE_ARTILLERY = 5

local EFFECT_FINE_TYPE_ITEMS = {
    {"lawful-evil.gui.player-inventory"},
    {"lawful-evil.gui.item"},
    {"lawful-evil.gui.money"}
}
local EFFECT_FINE_TYPE_INVENTORY = 1
local EFFECT_FINE_TYPE_ITEM = 2
local EFFECT_FINE_TYPE_MONEY = 3

local EFFECT_REWARD_TYPE_ITEMS = {
    {"lawful-evil.gui.item"},
    {"lawful-evil.gui.money"}
}
local EFFECT_REWARD_TYPE_ITEM = 1
local EFFECT_REWARD_TYPE_MONEY = 2

local VALUE_TYPE_ITEMS = {
    {"lawful-evil.gui.percent-of"},
    {"lawful-evil.gui.fixed-amount"}
}
local VALUE_TYPE_PERCENTAGE = 1
local VALUE_TYPE_FIXED = 2

local OPERATION_TYPE_ITEMS = {"=", "!=", ">", "<"}
local OPERATION_TYPE_EQUAL = 1
local OPERATION_TYPE_NOT_EQUAL = 2
local OPERATION_TYPE_GREATER_THAN = 3
local OPERATION_TYPE_LESS_THAN = 4

local PERCENTAGE_TYPE_ITEMS = {
    {"lawful-evil.percentage-type-items.players"},
    {"lawful-evil.percentage-type-items.forces-players"},
    {"lawful-evil.percentage-type-items.balance"},
    {"lawful-evil.percentage-type-items.evolution-factor"},
    {"lawful-evil.percentage-type-items.rockets-launched"},
    {"lawful-evil.percentage-type-items.total-production"},
    {"lawful-evil.percentage-type-items.production-per-min"},
    {"lawful-evil.percentage-type-items.total-consumption"},
    {"lawful-evil.percentage-type-items.consumption-per-min"},
    {"lawful-evil.percentage-type-items.technologies-researched"},
    {"lawful-evil.percentage-type-items.trains"},
    {"lawful-evil.percentage-type-items.forces-trains"},
    {"lawful-evil.percentage-type-items.construction-robots"},
    {"lawful-evil.percentage-type-items.forces-construction-robots"},
    {"lawful-evil.percentage-type-items.logistic-robots"},
    {"lawful-evil.percentage-type-items.forces-logistic-robots"},
    {"lawful-evil.percentage-type-items.players-time-online"},
    {"lawful-evil.percentage-type-items.players-afk-time"},
    {"lawful-evil.percentage-type-items.game-tick"},
    {"lawful-evil.percentage-type-items.time-of-day"}
}
local PERCENTAGE_TYPE_PLAYER_COUNT = 1
local PERCENTAGE_TYPE_FORCE_PLAYER_COUNT = 2
local PERCENTAGE_TYPE_BALANCE = 3
local PERCENTAGE_TYPE_EVOLUTION_FACTOR = 4
local PERCENTAGE_TYPE_ROCKETS_LAUNCHED = 5
local PERCENTAGE_TYPE_TOTAL_PRODUCTION = 6
local PERCENTAGE_TYPE_RATE_PRODUCTION = 7
local PERCENTAGE_TYPE_TOTAL_CONSUMPTION = 8
local PERCENTAGE_TYPE_RATE_CONSUMPTION = 9
local PERCENTAGE_TYPE_TECHNOLOGIES_RESEARCHED = 10
local PERCENTAGE_TYPE_TRAINS = 11
local PERCENTAGE_TYPE_FORCE_TRAINS = 12
local PERCENTAGE_TYPE_CONSTRUCTION_ROBOTS = 13
local PERCENTAGE_TYPE_FORCE_CONSTRUCTION_ROBOTS = 14
local PERCENTAGE_TYPE_LOGISTIC_ROBOTS = 15
local PERCENTAGE_TYPE_FORCE_LOGISTIC_ROBOTS = 16
local PERCENTAGE_TYPE_PLAYER_TIME_ONLINE = 17
local PERCENTAGE_TYPE_PLAYER_TIME_AFK = 18
local PERCENTAGE_TYPE_GAME_TICK = 19
local PERCENTAGE_TYPE_DAYTIME = 20

local LOGIC_TYPE_ITEMS = {{"and"}, {"or"}}
local LOGIC_TYPE_AND = 1
local LOGIC_TYPE_OR = 2
local LOGIC_TYPE_BASE = 3

local VOTE_AYE = 1
local VOTE_NAY = 2


local TRASH_BIN = {
    type = "sprite-button",
    sprite = "utility/trash_white",
    hovered_sprite = "utility/trash",
    clicked_sprite = "utility/trash"
}


local call = remote.call
local floor = math.floor
local ceil = math.ceil


local HORIZONTAL_FLOW = {
    type = "flow",
    direction = "horizontal"
}


-- TODO: add admin mode and then extend the mode
-- TODO: make several tables for laws
-- TODO: store last n laws in another variable for revoting by players
-- TODO: filter picking of entity

local module = {}
module.self_events = require 'self_events'


local function is_EasyAPI_loaded()
    return game.active_mods["EasyAPI"] ~= nil
end

local function EasyAPI_add_to_balance(force, amount)
    if is_EasyAPI_loaded() then
        call("EasyAPI", "deposit_force_money", force, amount)
    end
end

local function EasyAPI_get_balance(force)
    if is_EasyAPI_loaded() then
        return (call("EasyAPI", "get_force_money", force.index) or 0)
    end
    return 0
end

script.on_init(function()
    global.laws = {}
    global.last_id = 0
    local example_law = GetNewLaw(nil)
    example_law.title = "Example Law"
    example_law.description = "This law is an example"
    example_law.clauses[1] = {
        base_clause = true,
        when_type = WHEN_PLAYER_CHATS,
        when_text = "Lawful Evil"
    }
    example_law.effects[1] = {
        effect_type = EFFECT_TYPE_ALERT,
        effect_text = "Example Law"
    }
    table.insert(global.laws, example_law)

    local no_driving = game.permissions.get_group("no_driving") or game.permissions.create_group("no_driving")
    no_driving.set_allows_action(defines.input_action.toggle_driving, false)
    local no_artillery = game.permissions.get_group("no_artillery") or game.permissions.create_group("no_artillery")
    no_artillery.set_allows_action(defines.input_action.use_artillery_remote, false)
    local no_shooting = game.permissions.get_group("no_shooting") or game.permissions.create_group("no_shooting")
    no_shooting.set_allows_action(defines.input_action.change_shooting_state, false)
end)

-- commands.add_command("pass-laws", "pass laws", function()    local laws = global.laws
--     for i=1, #laws do
--         law = laws[i]
--         if not law.passed then
--             PassLaw(law)
--         end
--     end
-- end)

local function AddLawfulButton(player)
    local flow = mod_gui.get_button_flow(player)
    local button = flow.lawful_evil_button
    if button then
        button.destroy()
    end

    flow.add{
        type = "sprite-button",
        name = "lawful_evil_button",
        sprite = "lawful-button-sprite",
        style = "slot_button"
    }
end

local function IsDaytime()
    local surface = game.get_surface(1)
    return not (surface.daytime > surface.evening and surface.daytime < surface.morning)
end

-- TODO: optimize
local function CalculatePercentageValue(value, type, item, force, player)
    local factor = value * 0.01
    if type == PERCENTAGE_TYPE_BALANCE then
        return EasyAPI_get_balance(force) * factor
    elseif type == PERCENTAGE_TYPE_PLAYER_COUNT then
        -- local count = 0
        -- for _, tech in pairs(game.players) do count = count + 1 end
        -- return count * factor
        return #game.players
    elseif type == PERCENTAGE_TYPE_FORCE_PLAYER_COUNT then
        return #force.players * factor
    elseif type == PERCENTAGE_TYPE_EVOLUTION_FACTOR then
        return force.evolution_factor * factor
    elseif type == PERCENTAGE_TYPE_ROCKETS_LAUNCHED then
        return force.rockets_launched * factor
    elseif type == PERCENTAGE_TYPE_TOTAL_PRODUCTION then
        if item then
            return force.item_production_statistics.get_input_count(item) * factor
        else
            return 0
        end
    elseif type == PERCENTAGE_TYPE_RATE_PRODUCTION then
        if item and global.production_rates then
            local item_production = global.production_rates[force.name].production[item]
            if item_production then
                return item_production.rate
            end
        end
        return 0
    elseif type == PERCENTAGE_TYPE_TOTAL_CONSUMPTION then
        if item then
            return force.item_production_statistics.get_output_count(item) * factor
        else
            return 0
        end
    elseif type == PERCENTAGE_TYPE_RATE_CONSUMPTION then
        if item and global.production_rates then
            local item_consumption = global.production_rates[force.name].consumption[item]
            if item_consumption then
                return item_consumption.rate
            end
        end
        return 0
    elseif type == PERCENTAGE_TYPE_TECHNOLOGIES_RESEARCHED then
        -- local count = 0
        -- for _, tech in pairs(force.technologies) do count = count + 1 end
        -- return count * factor
        return #force.technologies * factor
    elseif type == PERCENTAGE_TYPE_TRAINS then
        local count = 0
        for _, _force in pairs(game.forces) do
            count = count + #_force.get_trains()
        end
        return count * factor
    elseif type == PERCENTAGE_TYPE_FORCE_TRAINS then
        return #force.get_trains() * factor
    elseif type == PERCENTAGE_TYPE_CONSTRUCTION_ROBOTS then
        local count = 0
        for _, _force in pairs(game.forces) do
            for _, network in pairs(_force.logistic_networks) do
                count = count + network.all_construction_robots
            end
        end
        return count * factor
    elseif type == PERCENTAGE_TYPE_FORCE_CONSTRUCTION_ROBOTS then
        local count = 0
        for _, network in pairs(force.logistic_networks) do
            count = count + network.all_construction_robots
        end
        return count * factor
    elseif type == PERCENTAGE_TYPE_LOGISTIC_ROBOTS then
        local count = 0
        for _, _force in pairs(game.forces) do
            for _, network in pairs(_force.logistic_networks) do
                count = count + network.all_logistic_robots
            end
        end
        return count * factor
    elseif type == PERCENTAGE_TYPE_FORCE_LOGISTIC_ROBOTS then
        local count = 0
        for _, network in pairs(force.logistic_networks) do
            count = count + network.all_logistic_robots
        end
        return count * factor
    elseif type == PERCENTAGE_TYPE_PLAYER_TIME_ONLINE then
        if player then
            return player.online_time * factor
        else
            return 0
        end
    elseif type == PERCENTAGE_TYPE_PLAYER_TIME_AFK then
        if player then
            return player.afk_time * factor
        else
            return 0
        end
    elseif type == PERCENTAGE_TYPE_GAME_TICK then
        return game.tick * factor
    elseif type == PERCENTAGE_TYPE_DAYTIME then
        return game.surfaces[1].daytime * factor
    end
end

-- TODO: check
local _technologies = nil
local function GetTechnologies()
    if _technologies == nil then
        _technologies = {}
        local i = 0
        for tech_name, tech in pairs(game.technology_prototypes) do
            i = i + 1
            _technologies[i] = tech.localised_name
        end
    end
    return _technologies
end

-- TODO: optimize
local function CalculateWithOperation(value_1, value_2, operation)
    if operation == OPERATION_TYPE_EQUAL then
        return value_1 == value_2
    elseif operation == OPERATION_TYPE_NOT_EQUAL then
        return value_1 ~= value_2
    elseif operation == OPERATION_TYPE_GREATER_THAN then
        return value_1 > value_2
    elseif operation == OPERATION_TYPE_LESS_THAN then
        return value_1 < value_2
    else
        return false
    end
end

-- TODO: optimize
local function ClauseMatch(law, clause, type, target, force, player)
    if clause.when_type == WHEN_THIS_LAW_PASSED and clause.base_clause then
        return law.id == target
    elseif clause.when_type == WHEN_DAY then
        return IsDaytime()
    elseif clause.when_type == WHEN_NIGHT then
        return not IsDaytime()
    elseif clause.when_type == WHEN_VALUE then
        local value_1 = clause.when_value
        local value_2 = clause.when_2_value
        if clause.when_value_type == VALUE_TYPE_PERCENTAGE then
            value_1 = CalculatePercentageValue(
                value_1,
                clause.when_value_percentage_type,
                clause.when_value_percentage_item,
                force,
                player
            )
        end
        if clause.when_2_value_type == VALUE_TYPE_PERCENTAGE then
            value_2 = CalculatePercentageValue(
                value_2,
                clause.when_2_value_percentage_type,
                clause.when_2_value_percentage_item,
                force,
                player
            )
        end
        return CalculateWithOperation(value_1, value_2, clause.when_operation_type)
    elseif clause.when_type == type then
        if clause.when_type == WHEN_PLAYER_CHATS then
            if string.match(target, clause.when_text) then
                return true
            end
        elseif clause.when_type == WHEN_FORCE_RESEARCHES then
            local tech = GetTechnologies()[clause.when_research]
            if tech[1] == target[1] then
                return true
            end
        elseif clause.when_type == WHEN_PLAYER_CRAFTS then
            return clause.when_elem == target
        else
            if clause.when_entity_similar_type == true then
                return game.entity_prototypes[target].type == game.entity_prototypes[clause.when_elem].type
            else
                return clause.when_elem == target
            end
        end
    end
    return false
end

local function LawMatch(type, target, force, player)
    local matched_laws = {}
    local ml_count = 0
    local laws = global.laws
    for i=1, #laws do
        law = laws[i]
        if law.passed then
            law.inverse_effects = false
            local results = {}
            local results_size = 0
            local clauses = law.clauses
            for j = 1, #clauses do
                local clause = clauses[j]
                local result = ClauseMatch(law, clause, type, target, force, player)
                results_size = results_size + 1
                results[results_size] = {
                    success = result,
                    logic = clause.base_clause and LOGIC_TYPE_BASE or clause.logic_type
                }
            end
            if results_size == 1 and results[1].success then
                ml_count = ml_count + 1
                matched_laws[ml_count] = law
            elseif results_size > 1 then
                local state = results[1].success
                for j = 2, results_size do
                    local result = results[j]
                    local logic_type = result.logic
                    if logic_type == LOGIC_TYPE_AND then
                        state = (state and result.success)
                    elseif logic_type == LOGIC_TYPE_OR then
                        if state then
                            break
                        else
                            state = (state or result.success)
                        end
                    end
                end
                if state then
                    ml_count = ml_count + 1
                    matched_laws[ml_count] = law
                end
            end
        end
    end
    return matched_laws
end

-- TODO: Optimize
local function ExecuteEffect(law, effect, event)
    local force = event.force
    local player_index = event.player_index
    local player = game.get_player(player_index)
    local offence_count = law.offences[player_index]
    local value = effect.effect_value
    if value ~= nil and effect.effect_value_type == VALUE_TYPE_PERCENTAGE then
        value = CalculatePercentageValue(
            value,
            effect.effect_value_percentage_type,
            effect.effect_value_percentage_item,
            force,
            player
        )
    end

    local effect_type = effect.effect_type
    if effect_type == EFFECT_TYPE_NTH_OFFENCE then
        event.stop_effects = (offence_count ~= effect.effect_nth_offence)
        -- game.print(offence_count.." == "..effect.effect_nth_offence)
    end

    if event.stop_effects then
        return
    end

    if effect_type == EFFECT_TYPE_RESET_OFFENCE then
        law.offences[player_index] = 0
    elseif effect_type == EFFECT_TYPE_REWARD then
        if effect.effect_reward_type == EFFECT_REWARD_TYPE_ITEM then
            player.insert{
                name = effect.effect_reward_item,
                count = floor(value)
            }
        elseif effect.effect_reward_type == EFFECT_REWARD_TYPE_MONEY then
            EasyAPI_add_to_balance(force, value)
        end
    elseif effect_type == EFFECT_TYPE_FINE then
        if effect.effect_fine_type == EFFECT_FINE_TYPE_INVENTORY then
            event.fine_success = true
            player.clear_items_inside()
        elseif effect.effect_fine_type == EFFECT_FINE_TYPE_ITEM then
            local count = player.get_item_count(effect.effect_fine_item)
            event.fine_success = (count >= floor(value))
            player.remove_item{
                name = effect.effect_fine_item,
                count = floor(value)
            }
        elseif effect.effect_fine_type == EFFECT_FINE_TYPE_MONEY then
            local balance = EasyAPI_get_balance(force)
            event.fine_success = (balance >= value)
            EasyAPI_add_to_balance(force, -value)
        end
    elseif effect_type == EFFECT_TYPE_FINE_FAIL then
        event.stop_effects = (event.fine_success == true or event.fine_success == nil)
    elseif effect_type == EFFECT_TYPE_DISALLOW then
        if event.item_stack and event.recipe then
            set_player_data(player, {
                remove_item = event.item_stack
            })
            for _, ingredient in pairs(event.recipe.ingredients) do
                player.insert{name = ingredient.name, count = ingredient.amount}
            end
        elseif event.research then
            force.current_research = nil
        elseif event.mined then
            local entity = event.entity
            player.surface.create_entity{
                name = entity.name,
                position = entity.position,
                direction = entity.direction,
                force = entity.force
            }
            -- buffer.clear() -- TODO: check
        elseif event.built then
            player.mine_entity(event.entity, true)
        end
    elseif effect_type == EFFECT_TYPE_ALERT then
        local msg = effect.effect_text or ""
        if player then
            game.print({"lawful-evil.messages.player-triggered-a-law", player.name, msg})
        elseif force then
            game.print({"lawful-evil.messages.force-triggered-a-law", force.name, msg})
        end
    elseif effect_type == EFFECT_TYPE_KILL then
        if player then
            player.character.die(nil)
        end
    elseif effect_type == EFFECT_TYPE_KICK then
        if player then
            game.kick_player(player, "Broke the law: "..law.title)
        end
    elseif effect_type == EFFECT_TYPE_BAN then
        if player then
            game.ban_player(player, "Broke the law: "..law.title)
        end
    elseif effect_type == EFFECT_TYPE_MUTE then
        if player then
            game.mute_player(player)
        end
    elseif effect_type == EFFECT_TYPE_UNMUTE then
        if player then
            game.unmute_player(player)
        end
    elseif effect_type == EFFECT_TYPE_LICENSE and player then
        local player_data = get_player_data(player)
        local effect_license_type = effect.effect_license_type
        if effect_license_type == EFFECT_LICENSE_TYPE_CAR then
            player_data.disallow_car = not effect.effect_license_state
        elseif effect_license_type == EFFECT_LICENSE_TYPE_TANK then
            player_data.disallow_tank = not effect.effect_license_state
        elseif effect_license_type == EFFECT_LICENSE_TYPE_TRAIN then
            player_data.disallow_locomotive = not effect.effect_license_state
        elseif effect_license_type == EFFECT_LICENSE_TYPE_GUN then
            player_data.disallow_gun = not effect.effect_license_state
            if effect.effect_license_state then
                game.permissions.get_group("no_shooting").remove_player(player)
            else
                game.permissions.get_group("no_shooting").add_player(player)
            end
        elseif effect_license_type == EFFECT_LICENSE_TYPE_ARTILLERY then
            player_data.disallow_artillery = not effect.effect_license_state
            if effect.effect_license_state then
                game.permissions.get_group("no_artillery").remove_player(player)
            else
                game.permissions.get_group("no_artillery").add_player(player)
            end
        end
        set_player_data(player, player_data)
    elseif effect_type == EFFECT_TYPE_REVOKE_LAW then
        RevokeLaw(law)
    elseif effect_type == EFFECT_TYPE_CUSTOM_SCRIPT and effect.script_text then
        load(effect.script_text)()(event)
    end
end

local function ExecuteLaws(laws, event)
    local player_index = event.player_index
    local player
    if player_index then
        player = game.get_player(player_index) -- TODO: change
    end

    for i=1, #laws do
        local law = laws[i]
        -- local clause = law.clauses[1] -- TODO: check

        -- TODO: Optimize
        -- Apply offense count
        if not law.offences then law.offences = {} end
        if player and not event.all_players then
            local count = law.offences[player_index]
            if count then
                law.offences[player_index] = count + 1
            else
                law.offences[player_index] = 1
            end
        end

        local effects = law.effects
        for j = 1, #effects do
            local effect = effects[j]
            if event.all_players then
                for _, _player in pairs(game.players) do
                    ExecuteEffect(law, effect, {
                        player_index = _player.index,
                        force = _player.force
                    })
                end
            else
                ExecuteEffect(law, effect, event)
            end
        end
    end
end

Event.register(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    AddLawfulButton(player)
end)

Event.register(defines.events.on_console_chat, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end
    local laws = LawMatch(WHEN_PLAYER_CHATS, event.message, player.force, player)
    event.force = player.force
    ExecuteLaws(laws, event)
end)

local function law_on_entity_died(event, player)
    if player.is_player() then
        event.player_index = player.index
    end
    local laws = LawMatch(WHEN_PLAYER_DESTROYS, event.entity.name, event.force, player)
    event.force = event.cause.force
    ExecuteLaws(laws, event)
end

local function on_entity_died(event)
    local cause = event.cause

    if cause.type == "character" then
        law_on_entity_died(event, cause.player)
    elseif cause.type == "car" then
        local passenger = cause.get_passenger()
        local driver = cause.get_driver()
        if passenger and driver then
            law_on_entity_died(event, passenger.player)
            law_on_entity_died(event, driver.player)
        elseif passenger then
            law_on_entity_died(event, passenger.player)
        elseif driver then
            law_on_entity_died(event, driver.player)
        end
    end
end
Event.register(defines.events.on_entity_died, function(event)
    pcall(on_entity_died, event)
end)

local function law_on_entity_damaged(event, player)
    if player.is_player() then
        event.player_index = player.index
    end
    local laws = LawMatch(WHEN_PLAYER_DAMAGES, event.entity.name, event.force, player)
    event.force = event.cause.force
    ExecuteLaws(laws, event)
end

local function on_entity_damaged(event)
    local cause = event.cause

    if cause.type == "character" then
        law_on_entity_damaged(event, cause.player)
    elseif cause.type == "car" then
        local passenger = cause.get_passenger()
        local driver = cause.get_driver()
        if passenger and driver then
            law_on_entity_damaged(event, passenger.player)
            law_on_entity_damaged(event, driver.player)
        elseif passenger then
            law_on_entity_damaged(event, passenger.player)
        elseif driver then
            law_on_entity_damaged(event, driver.player)
        end
    end
end
Event.register(defines.events.on_entity_damaged, function(event)
    pcall(on_entity_damaged, event)
end)

Event.register(defines.events.on_built_entity, function(event)
    local player = game.get_player(event.player_index)
    if player.controller_type == defines.controllers.editor then return end

    local laws = LawMatch(WHEN_PLAYER_BUILDS, event.created_entity.name, player.force, player)
    event.entity = event.created_entity
    event.built = true
    event.force = player.force
    ExecuteLaws(laws, event)
end)

Event.register(defines.events.on_player_mined_entity, function(event)
    local player = game.get_player(event.player_index)
    if player.controller_type == defines.controllers.editor then return end

    local laws = LawMatch(WHEN_PLAYER_MINES, event.entity.name, player.force, player)
    event.mined = true
    event.force = player.force
    ExecuteLaws(laws, event)
end)

Event.register(defines.events.on_player_crafted_item, function(event)
    local player = game.get_player(event.player_index)
    if player.controller_type == defines.controllers.editor then return end

    local laws = LawMatch(WHEN_PLAYER_CRAFTS, event.item_stack.name, player.force, player)
    event.force = player.force
    ExecuteLaws(laws, event)
end)

Event.register(defines.events.on_player_built_tile, function(event)
    local player = game.get_player(event.player_index)
    if player.controller_type == defines.controllers.editor then return end

    for _, tile in pairs(event.tiles) do
        local laws = LawMatch(WHEN_PLAYER_TILES, event.item.name, player.force, player)
        event.force = player.force
        ExecuteLaws(laws, event)
    end
end)

Event.register(defines.events.on_player_mined_tile, function(event)
    local player = game.get_player(event.player_index)
    if player.controller_type == defines.controllers.editor then return end

    for _, tile in pairs(event.tiles) do
        event.item = tile.old_tile.items_to_place_this
        local laws = LawMatch(WHEN_PLAYER_MINES_TILE, event.item.name, player.force, player)
        event.force = player.force
        ExecuteLaws(laws, event)
    end
end)

Event.register(defines.events.on_research_started, function(event)
    local laws = LawMatch(WHEN_FORCE_RESEARCHES, event.research.localised_name, event.research.force, nil)
    event.force = event.research.force
    ExecuteLaws(laws, event)
end)

Event.register(defines.events.on_rocket_launched, function(event)
    local laws = LawMatch(
        WHEN_ROCKET_LAUNCHES,
        event.rocket,
        event.rocket.force,
        nil
    )
    event.force = event.rocket.force
    ExecuteLaws(laws, event)
end)

Event.register(defines.events.on_player_died, function(event)
    local cause = event.cause
    if not (cause and cause.is_player()) then return end

    local laws = LawMatch(
        WHEN_PLAYER_KILLS,
        cause,
        cause.force,
        nil
    )
    event.force = cause.force
    event.player_index = cause.associated_player.index
    ExecuteLaws(laws, event)
end)

Event.register(defines.events.on_player_driving_changed_state, function(event)
    local vehicle = event.entity
    if vehicle == nil then return end

    local player = game.get_player(event.player_index)
    local driver = vehicle.get_driver()
    if driver and driver.player == player then
        local player_data = get_player_data(player)
        if player_data.disallow_car and vehicle.name == "car" then
            vehicle.set_driver(nil)
        elseif player_data.disallow_tank and vehicle.name == "tank" then
            vehicle.set_driver(nil)
        elseif player_data.disallow_locomotive and vehicle.name == "locomotive" then
            vehicle.set_driver(nil)
        end
    end
end)

Event.register(defines.events.on_player_respawned, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then return end

    local laws = LawMatch(WHEN_PLAYER_RESPAWNS, message, player.force, player) -- TODO: check
    event.force = player.force
    ExecuteLaws(laws, event)
end)

script.on_nth_tick(3, function(event)
    -- Remove items (queued up via law effects)
    for _, player in pairs(game.connected_players) do
        local data = get_player_data(player)
        if data.remove_item then
            player.remove_item(data.remove_item)
            data.remove_item = nil
        end
    end
end)

local function RefreshAllLawfulEvilGui()
    for _, player in pairs(game.players) do
        local lawful_gui = player.gui.center["lawful_evil_gui"]
        if lawful_gui then
            lawful_gui.destroy()
            CreateLawfulEvilGUI(player)
        end
    end
end

local function CheckVotes()
    local laws = global.laws
    for i=1, #laws do
        law = laws[i]
        if not law.passed and not law.linked_law and game.tick >= law.vote_end_tick then
            local votes = GetLawVotes(law)
            if votes.ayes > votes.noes then
                game.print({"lawful-evil.messages.law-is-passed", law.title, votes.ayes, votes.noes})
                PassLaw(law)
            else
                game.print({"lawful-evil.messages.law-is-not-passed", law.title, votes.ayes, votes.noes})
                RevokeLaw(law, law.index)
            end
        end
    end

    -- Refresh Lawful Gui.
    RefreshAllLawfulEvilGui()
end

 -- For specilizations
local function CheckProductionRates()
    if not global.production_rates then
        global.production_rates = {}
    end

    local production_rates = global.production_rates
    for _, force in pairs(game.forces) do
        local force_name = force.name
        if not production_rates[force_name] then
            production_rates[force_name] = {
                production = {},
                consumption = {}
            }
        end
        local rates = production_rates[force_name]
        for item, count in pairs(force.item_production_statistics.input_counts) do
            local production = rates.production[item]
            if production then
                production.rate = count - production.last
            else
                rates.production[item] = {
                    rate = 0,
                    last = count
                }
            end
        end
        for item, count in pairs(force.item_production_statistics.output_counts) do
            local consumption = rates.consumption[item]
            if consumption then
                consumption.rate = count - consumption.last
            else
                rates.consumption[item] = {
                    rate = 0,
                    last = count
                }
            end
        end
    end
end

script.on_nth_tick(3600, function(event)
    CheckVotes()
    CheckProductionRates()
end)

Gui.on_click("lawful_evil_button", function(event)
    local player = game.get_player(event.player_index)
    local lawful_gui = player.gui.center.lawful_evil_gui
    if lawful_gui then
        lawful_gui.destroy()
    else
        local law_gui = player.gui.center.lawful_evil_law_gui
        if law_gui then
            law_gui.destroy()
        else
            CreateLawfulEvilGUI(player)
        end
    end
end)

Gui.on_click("close_lawful_gui", function(event)
    local player = game.get_player(event.player_index)
    local lawful_gui = player.gui.center.lawful_evil_gui
    if lawful_gui then
        lawful_gui.destroy()
    end
end)

Gui.on_click("propose_law", function(event)
    local player = game.get_player(event.player_index)
    local lawful_gui = player.gui.center.lawful_evil_gui
    if lawful_gui then
        lawful_gui.destroy()
    end
    CreateLawGUI({
        player = player,
        law = GetNewLaw(player),
        read_only = false,
        can_vote = false
    })
end)

local function CreateSubClause()
    return {
        base_clause = false,
        logic_type = LOGIC_TYPE_AND,
        when_type = WHEN_VALUE,
        when_value = 0,
        when_value_type = VALUE_TYPE_FIXED,
        when_2_value = 0,
        when_2_value_type = VALUE_TYPE_FIXED,
        when_operation_type = OPERATION_TYPE_EQUAL
    }
end

Gui.on_click("add_clause", function(event)
    local player = game.get_player(event.player_index)
    local law_gui = player.gui.center.lawful_evil_law_gui
    if law_gui then
        local subclause = CreateSubClause()
        CreateClauseGUI(law_gui.clauses_frame.clauses, subclause)
        SaveLaw(law_gui)
    end
end)

Gui.on_click("add_effect", function(event)
    local player = game.get_player(event.player_index)
    local law_gui = player.gui.center.lawful_evil_law_gui
    if law_gui then
        local effect = {
            base_effect = false,
            effect_type = EFFECT_TYPE_FINE,
            effect_value = 0,
            effect_value_type = VALUE_TYPE_FIXED
        }
        CreateEffectGUI(law_gui.effects_frame.effects, effect)
        SaveLaw(law_gui)
    end
end)

Gui.on_click("delete_.+", function(event)
    local player = game.get_player(event.player_index)
    local law_gui = player.gui.center.lawful_evil_law_gui
    local elem = event.element
    if law_gui then
        elem.parent.destroy()
        SaveLaw(law_gui)
    end
end)

Gui.on_click("vote_law_([0-9]+)", function(event)
    local player = game.get_player(event.player_index)
    local law_gui = player.gui.center["lawful_evil_gui"]
    if law_gui then
        law_gui.destroy()
    else
        law_gui = player.gui.center.lawful_evil_law_gui
        if law_gui then
            law_gui.destroy()
        end
    end
    local law_id = tonumber(event.match)
    local law = global.laws[law_id]
    if law then
        CreateLawGUI({
            player = player,
            law = law,
            can_vote = true,
            read_only = true
        })
    end
end)

Gui.on_click("view_law_([0-9]+)", function(event)
    local player = game.get_player(event.player_index)
    local law_gui = player.gui.center["lawful_evil_gui"]
    if law_gui then
        law_gui.destroy()
    else
        law_gui = player.gui.center.lawful_evil_law_gui
        if law_gui then
            law_gui.destroy()
        end
    end
    local law_id = tonumber(event.match)
    local law = global.laws[law_id]
    if law then
        CreateLawGUI({
            player = player,
            law = law,
            can_vote = false,
            read_only = true
        })
    end
end)

function ParseVoteEvent(event)
    local law_index = tonumber(event.match)
    return {
        player = game.get_player(event.player_index),
        law_index = law_index,
        law = global.laws[law_index]
    }
end

Gui.on_click("vote_law_aye_([0-9]+)", function(event)
    local vote_event = ParseVoteEvent(event)
    VoteLaw(vote_event.law, vote_event.player, VOTE_AYE)
    CloseLawGui(vote_event.player)
end)

Gui.on_click("vote_law_nay_([0-9]+)", function(event)
    local vote_event = ParseVoteEvent(event)
    VoteLaw(vote_event.law, vote_event.player, VOTE_NAY)
    CloseLawGui(vote_event.player)
end)

Gui.on_click("revoke_law_([0-9]+)", function(event)
    local vote_event = ParseVoteEvent(event)
    RevokeVoteLaw(vote_event.law, vote_event.player, VOTE_AYE)
    CloseLawGui(vote_event.player)
end)

Gui.on_click("close_law", function(event)
    local player = game.get_player(event.player_index)
    CloseLawGui(player)
end)

local ADMIN_EFFECTS = {
    [EFFECT_TYPE_CUSTOM_SCRIPT] = true,
    [EFFECT_TYPE_UNMUTE] = true,
    [EFFECT_TYPE_MUTE] = true,
    [EFFECT_TYPE_KILL] = true,
    [EFFECT_TYPE_KICK] = true,
    [EFFECT_TYPE_BAN] = true
}
---@return boolean
local function check_admin_effects_in_law(law)
    local effects = law.effects
    for i = 1, #effects do
        if ADMIN_EFFECTS[effects[i].effect_type] then
            return true
        end
    end

    return false
end

Gui.on_click("submit_law", function(event)
    local player = game.get_player(event.player_index)
    local gui = player.gui.center.lawful_evil_law_gui
    if gui == nil then return end

    local law = SaveLaw(gui)
    game.print({"lawful-evil.messages.law-is-submitted", law.title})
    local is_law_have_admin_effects = check_admin_effects_in_law(law)
    if is_law_have_admin_effects then
        if not player.admin then
            player.print({"lawful-evil.messages.cant-add-admin-law"})
            return
        end
        law.passed = true
    end
    table.insert(global.laws, law)
    gui.destroy()
    CreateLawfulEvilGUI(player)
end)

Gui.on_selection_state_changed("when_elem_type", function(event)
    local elem = event.element
    -- local law = global.laws[] -- TODO: check
    local law = nil
    if law.when_elem_type ~= elem.selected_index then
        law.when_elem = nil
    end
    law.when_elem_type = elem.selected_index
end)

Gui.on_selection_state_changed(".+", function(event)
    local elem = event.element
    if elem.parent.parent.name == "clauses" then
        local player = game.get_player(event.player_index)
        local gui = player.gui.center.lawful_evil_law_gui
        local law = SaveLaw(gui)
        gui.clauses_frame.clauses.clear()
        local clauses = law.clauses
        for i = 1, #clauses do
            CreateClauseGUI(gui.clauses_frame.clauses, clauses[i])
        end
    elseif elem.parent.parent.name == "effects" then
        local player = game.get_player(event.player_index)
        local gui = player.gui.center.lawful_evil_law_gui
        local law = SaveLaw(gui)
        gui.effects_frame.effects.clear()
        local effects = law.effects
        for i = 1, #effects do
            CreateEffectGUI(gui.effects_frame.effects, effects[i])
        end
    end
end)

function GetNewLaw(player)
    global.last_id = global.last_id + 1
    return {
        id = global.last_id,
        title = "Title...",
        description = "State your intent...",
        creator = player and player.name or "?",
        passed = false,
        votes = {},
        vote_end_tick = game.tick + settings.global['voting-duration'].value * 60 * 60,
        revoke_votes = {},
        clauses = {
            {
                base_clause = true,
                when_type = WHEN_PLAYER_BUILDS,
            }
        },
        effects = {
            {
                base_effect = true,
                effect_type = EFFECT_TYPE_FINE,
                effect_value = 0,
                effect_value_type = VALUE_TYPE_FIXED
            }
        }
    }
end

local function GetLawById(id)
    local laws = global.laws
    for i=1, #laws do
        law = laws[i]
        if law.id == id then
            return law
        end
    end
end

local function GetClauseTypes(logic_type)
    local collected_types = {}
    local ct_count = 0
    for id, type in pairs(CLAUSE_TYPES) do
        if  (type.base_allowed and logic_type == LOGIC_TYPE_BASE)
            or (type.and_allowed and logic_type == LOGIC_TYPE_AND)
            or (type.or_allowed and logic_type == LOGIC_TYPE_OR)
        then
            ct_count = ct_count + 1
            collected_types[ct_count] = id
        end
    end
    table.sort(collected_types, function(a,b)
        return CLAUSE_TYPES[a].order < CLAUSE_TYPES[b].order
    end)
    return collected_types
end

local function SaveClause(gui, law, clause)
    if not gui.when_type then
        return nil
    end
    if gui.logic_type then
        clause.logic_type = gui.logic_type.selected_index
    else
        clause.logic_type = LOGIC_TYPE_BASE
    end
    clause.when_type = GetClauseTypes(clause.logic_type)[gui.when_type.selected_index]
    if gui.when_value then
        clause.when_value = tonumber(gui.when_value.text) or 0
        clause.when_value_type = gui.when_value_type.selected_index
        if gui.when_value_percentage_type then
            clause.when_value_percentage_type = gui.when_value_percentage_type.selected_index
            if gui.when_value_percentage_item then
                clause.when_value_percentage_item = gui.when_value_percentage_item.elem_value
            end
        end
        clause.when_operation_type = gui.when_operation_type.selected_index
        clause.when_2_value = tonumber(gui.when_2_value.text) or 0
        clause.when_2_value_type = gui.when_2_value_type.selected_index
        if gui.when_2_value_percentage_type then
            clause.when_2_value_percentage_type = gui.when_2_value_percentage_type.selected_index
            if gui.when_2_value_percentage_item then
                clause.when_2_value_percentage_item = gui.when_2_value_percentage_item.elem_value
            end
        end
    end
    if gui.when_entity_similar_type then
        clause.when_entity_similar_type = gui.when_entity_similar_type.state
    end
    if gui.when_elem then
        clause.when_elem = gui.when_elem.elem_value
    end
    if gui.when_research then
        clause.when_research = gui.when_research.selected_index
    end
    if gui.when_text then
        clause.when_text = gui.when_text.text
    end
    return clause
end

local function SaveEffect(gui, effect, player)
    local effect_type = gui.effect_type.selected_index
    effect.effect_type = effect_type
    if gui.effect_value then
        effect.effect_value = tonumber(gui.effect_value.text) or 0
        effect.effect_value_type = gui.effect_value_type.selected_index
        if gui.effect_value_percentage_type then
            effect.effect_value_percentage_type = gui.effect_value_percentage_type.selected_index
            if gui.effect_value_percentage_item then
                effect.effect_value_percentage_item = gui.effect_value_percentage_item.elem_value
            end
        end
    else
        effect.effect_value = 0
    end
    if gui.effect_fine_type then
        effect.effect_fine_type = gui.effect_fine_type.selected_index
        if gui.effect_fine_item then
            effect.effect_fine_item = gui.effect_fine_item.elem_value
        end
    end
    if gui.effect_reward_type then
        effect.effect_reward_type = gui.effect_reward_type.selected_index
        if gui.effect_reward_item then
            effect.effect_reward_item = gui.effect_reward_item.elem_value
        end
    end
    if gui.effect_text then
        effect.effect_text = gui.effect_text.text
    elseif gui.parent.script_text then
        local script = load(gui.parent.script_text.text)
        if type(script) == "function" then
            effect.script_text = gui.parent.script_text.text
        else
            player.print("Added custom script doesn't compile in the law")
        end
    end
    if gui.effect_license_type and gui.effect_license_state then
        effect.effect_license_type = gui.effect_license_type.selected_index
        effect.effect_license_state = gui.effect_license_state.state
    end
    if gui.effect_nth_offence then
        effect.effect_nth_offence = tonumber(gui.effect_nth_offence.text) or 1
    end
    return effect
end

function SaveLaw(gui)
    local player = game.get_player(gui.player_index)
    local law = GetNewLaw(player)
    if gui.law_title then
        if string.len(gui.law_title.text) > 38 then
            law.title = string.sub(gui.law_title.text, 1, 38)
        else
            law.title = gui.law_title.text
        end
    end
    if gui.law_description then
        if string.len(gui.law_description.text) > 310 then
            law.description = string.sub(gui.law_description.text, 1, 310)
        else
            law.description = gui.law_description.text
        end
    end
    law.clauses = {}
    for i, elem in pairs(gui.clauses_frame.clauses.children) do
        local clause = SaveClause(elem, law, {
            base_clause = (i == 1)
        })
        if clause then
            law.clauses[i] = clause
        end
    end
    law.effects = {}
    for i, elem in pairs(gui.effects_frame.effects.children) do
        if elem.effect_type then
            local effect = {
                base_effect = (i == 1)
            }
            law.effects[i] = SaveEffect(elem, effect, player)
        end
    end
    if gui.buttons.linked_law.selected_index > 1 then
        local options = {0}
        local laws = global.laws
        for i=1, #laws do
            law = laws[i]
            if not law.passed then
                table.insert(options, law.id)
            end
        end
        -- TODO: add extra time to the laws because the law changed
        law.linked_law = options[gui.buttons.linked_law.selected_index]
    else
        law.linked_law = nil
    end
    return law
end

function CloseLawGui(player)
    local gui = player.gui.center.lawful_evil_law_gui
    if gui then
        gui.destroy()
        CreateLawfulEvilGUI(player)
    end
end

function VoteLaw(law, player, vote)
    if law and law.votes[player.name] == nil then
        law.votes[player.name] = vote
    end
end

function PassLaw(law)
    law.passed = true
    local matched_laws = LawMatch(WHEN_THIS_LAW_PASSED, law.id, nil, nil)
    script.raise_event(module.self_events.on_passed_law, {law_id = law.id})
    ExecuteLaws(matched_laws, {
        all_players = true
    })
    local laws = global.laws
    for i=1, #laws do
        other_law = laws[i]
        if not other_law.passed and other_law.linked_law == law.id then
            PassLaw(other_law)
        end
    end
end

function RevokeLaw(law, index)
    game.print({"lawful-evil.messages.law-is-revoked", law.title})
    local law_id = law.id
    script.raise_event(module.self_events.on_pre_revoke_law, {law_id = law_id})
    table.remove(global.laws, index)
    local laws = global.laws
    for i=1, #laws do
        other_law = laws[i]
        if other_law.linked_law == law_id then
            RevokeLaw(other_law, i)
        end
    end
end

function RevokeVoteLaw(law, player, vote)
    if law and law.revoke_votes[player.name] == nil then
        law.revoke_votes[player.name] = vote
        local votes = GetLawVotes(law)
        local revoke_count = GetLawRevokeVotes(law)
        if revoke_count >= votes.ayes then
            RevokeLaw(law, law.index)
        end
    end
end

function GetLawVotes(law)
    local ayes_count = 0
    local noes_count = 0
    for player_name, vote in pairs(law.votes) do
        if vote == VOTE_AYE then
            ayes_count = ayes_count + 1
        elseif vote == VOTE_NAY then
            noes_count = noes_count + 1
        end
    end
    return {
        ayes = ayes_count,
        noes = noes_count
    }
end

function GetLawRevokeVotes(law)
    local revoke_count = 0
    for player_name, vote in pairs(law.revoke_votes) do
        if vote == VOTE_AYE then
            revoke_count = revoke_count + 1
        end
    end
    return revoke_count
end

-- TODO: check
local _entity_types = nil
function GetEntityTypes()
    if _entity_types == nil then
        _entity_types = {}
        local type_map = {}
        for name, entity in pairs(game.entity_prototypes) do
            local type = entity.type
            if not type_map[type] then
                type_map[type] = 1
            else
                type_map[type] = type_map[type] + 1
            end
        end
        for type, count in pairs(type_map) do
            if count > 1 then
                _entity_types[#_entity_types + 1] = type
            end
        end
    end
    return _entity_types
end

local function GetClauseIndexByID(clause_type_id, clause_types)
    if clause_type_id ~= nil then
        for i = 1, #clause_types do
            if clause_types[i] == clause_type_id then
                return i
            end
        end
    end
    return 1
end

function CreateDropDown(params)
    if params.read_only then
        return params.parent.add{
            type = "label",
            caption = params.items[params.selected_index],
            style = params.label_style
        }
    else
        return params.parent.add{
            type = "drop-down",
            name = params.name,
            items = params.items,
            selected_index = params.selected_index
        }
    end
end

function CreateLawfulEvilGUI(player)
    local gui = player.gui.center.add{
        type = "frame",
        name = "lawful_evil_gui",
        caption = {"mod-name.m-lawful-evil"},
        direction = "vertical"
    }

    local passed_laws = {}
    local proposed_laws = {}
    local laws = global.laws
    for i=1, #laws do
        law = laws[i]
        law.index = i
        if law.passed then
            passed_laws[#passed_laws + 1] = law
        else
            proposed_laws[#proposed_laws + 1] = law
        end
    end

    gui.add{
        type = "label",
        caption = {"lawful-evil.gui.passed-laws"},
        style = "large_caption_label"
    }
    local passed_laws_scroll = gui.add{
        type = "scroll-pane",
        name = "passed_laws_scroll"
    }
    passed_laws_scroll.style.minimal_width = 500
    passed_laws_scroll.style.minimal_height = 150
    passed_laws_scroll.style.maximal_height = 300
    if next(passed_laws) == nil then
        passed_laws_scroll.add{
            type = "label",
            caption = {"size.none"}
        }
    end
    for i = 1, #passed_laws do
        local law = passed_laws[i]
        local law_frame = passed_laws_scroll.add{
            type = "frame",
            direction = "vertical",
            caption = law.title
        }
        law_frame.style.horizontally_stretchable = true
        local flow1 = law_frame.add(HORIZONTAL_FLOW)
        local flow2 = flow1.add(HORIZONTAL_FLOW)
        flow2.style.horizontally_stretchable = true
        flow2.add{
            type = "label",
            caption = law.description
        }
        flow1.add{
            type = "button",
            name = "view_law_" .. law.index,
            caption = {"view"}
        }
    end
    gui.add{
        type = "label",
        caption = {"lawful-evil.gui.proposed-laws"},
        style = "large_caption_label"
    }
    local laws_scroll = gui.add{
        type = "scroll-pane",
        name = "laws_scroll"
    }
    laws_scroll.style.minimal_width = 500
    laws_scroll.style.minimal_height = 150
    laws_scroll.style.maximal_height = 300
    if next(proposed_laws) == nil then
        laws_scroll.add{
            type = "label",
            caption = {"size.none"}
        }
    end
    for i = 1, #proposed_laws do
        local law = proposed_laws[i]
        local law_frame = laws_scroll.add{
            type = "frame",
            direction = "vertical",
            caption = law.title
        }
        law_frame.style.horizontally_stretchable = true
        law_frame.style.vertically_stretchable = true
        law_frame.style.maximal_height = 150
        local flow1 = law_frame.add(HORIZONTAL_FLOW)
        local flow2 = flow1.add(HORIZONTAL_FLOW)
        flow2.style.horizontally_stretchable = true
        local description = flow2.add{
            type = "text-box",
            text = law.description
        }
        description.read_only = true
        description.style.horizontally_stretchable = true
        description.style.vertically_stretchable = true
        description.style.maximal_width = 800
        description.style.minimal_height = 50
        description.style.maximal_height = 60
        flow1.add{
            type = "button",
            name = "vote_law_" .. law.index,
            caption = {"view"}
        }
        local voting_mins_left = 1
        local voting_ticks_left = law.vote_end_tick - game.tick
        if voting_ticks_left > 3600 then
            voting_mins_left = ceil((voting_ticks_left) / 3600)
        end
        local meta_flow = law_frame.add(HORIZONTAL_FLOW)
        meta_flow.name = "meta_flow"
        meta_flow.style.horizontally_stretchable = true
        meta_flow.style.horizontal_align = "center"
        if not law.linked_law then
            meta_flow.add{
                type = "label",
                name = "mins_left",
                caption = {"lawful-evil.gui.voting-mins-left", voting_mins_left},
                style = "description_value_label"
            }
        else
            meta_flow.add{
                type = "label",
                caption = {"lawful-evil.gui.linked-to", GetLawById(law.linked_law).title},
                style = "description_value_label"
            }
        end
        meta_flow.add{
            type = "label",
            caption = {"lawful-evil.gui.proposed-by", law.creator or "?"},
            style = "menu_message"
        }
        if not law.linked_law then
            local votes = GetLawVotes(law)
            local ayes = meta_flow.add{
                type = "label",
                name = "yay_votes",
                caption = {"lawful-evil.gui.n-ayes", votes.ayes}
            }
            ayes.style.font_color = {g=1}
            local noes = meta_flow.add{
                type = "label",
                name = "noes_votes",
                caption = {"lawful-evil.gui.n-noes", votes.noes}
            }
            noes.style.font_color = {r=1}
        end
    end

    local bottom_buttons_flow = gui.add(HORIZONTAL_FLOW)
    local propose_law_button = bottom_buttons_flow.add{
        type = "button",
        name = "propose_law",
        caption = {"lawful-evil.gui.propose-new-law"}
    }
    propose_law_button.style.horizontally_stretchable = true
    bottom_buttons_flow.add{
        type = "button",
        name = "close_lawful_gui",
        caption = {"gui.close"}
    }
end

function CreateLawGUI(event)
    local law = event.law
    local player = event.player
    local read_only = event.read_only
    local gui = player.gui.center.add{
        type = "frame",
        name = "lawful_evil_law_gui",
        caption = read_only and law.title or {"lawful-evil.gui.propose-law"},
        direction = "vertical"
    }
    if not read_only then
        local title = gui.add{
            type = "textfield",
            name = "law_title",
            text = law.title or "Title...",
            enabled = not read_only
        }
        title.style.maximal_width = 0
        title.style.horizontally_stretchable = true
    end
    local description = gui.add{
        type = "text-box",
        name = "law_description",
        text = law.description or "State your intent...",
        enabled = not read_only
    }
    description.style.maximal_width = 0
    description.style.horizontally_stretchable = true
    description.style.height = 50

    local clauses_frame = gui.add{
        type = "frame",
        name = "clauses_frame"
    }
    clauses_frame.style.minimal_width = 500
    local clauses_gui = clauses_frame.add{
        type = "scroll-pane",
        name = "clauses"
    }
    clauses_gui.style.minimal_width = clauses_frame.style.minimal_width
    clauses_gui.style.maximal_height = 350
    local effects_frame = gui.add{
        type = "frame",
        name = "effects_frame"
    }
    effects_frame.style.minimal_width = clauses_frame.style.minimal_width
    local effects_gui = effects_frame.add{
        type = "scroll-pane",
        name = "effects"
    }
    effects_gui.style.minimal_width = clauses_frame.style.minimal_width
    effects_gui.style.maximal_height = 200

    local clauses = law.clauses
    for i = 1, #clauses do
        CreateClauseGUI(clauses_gui, clauses[i], read_only)
    end
    local effects = law.effects
    for i = 1, #effects do
        CreateEffectGUI(effects_gui, effects[i], read_only)
    end

    local buttons = gui.add(HORIZONTAL_FLOW)
    buttons.name = "buttons"
    if not read_only then
        buttons.add{
            type = "button",
            name = "add_clause",
            caption = {"lawful-evil.gui.add-clause"}
        }
        buttons.add{
            type = "button",
            name = "add_effect",
            caption = {"lawful-evil.gui.add-effect"}
        }
        buttons.add{
            type = "label",
            caption = {"lawful-evil.gui.link-with"}
        }
        local options = {{"lawful-evil.gui.none"}}
        local options_indexed = {}
        local j = 2
        local laws = global.laws
        for i=1, #laws do
            law = laws[i]
            if not law.passed then
                options[#options+1] = law.title
                options_indexed[law.id] = j
                j = j + 1
            end
        end
        CreateDropDown{
            parent = buttons,
            name = "linked_law",
            items = options,
            selected_index = options_indexed[law.linked_law] or 1
        }
        buttons.add{
            type = "button",
            name = "submit_law",
            caption = {"submit"}
        }
    elseif event.can_vote and law.votes[player.name] == nil then
        if law.linked_law then
            local target_law = GetLawById(law.linked_law)
            buttons.add{
                type = "label",
                caption = {"lawful-evil.gui.double_link"}
            }
            buttons.add{
                type = "button",
                name = "vote_law_" .. target_law.index,
                caption = target_law.title
            }
        else
            buttons.add{
                type = "button",
                name = "vote_law_aye_" .. law.index,
                caption = {"lawful-evil.gui.vote-aye"}
            }
            buttons.add{
                type = "button",
                name = "vote_law_nay_" .. law.index,
                caption = {"lawful-evil.gui.vote-nay"}
            }
        end
    end
    buttons.add{
        type = "button",
        name = "close_law",
        caption = {"gui.close"}
    }
    if not event.can_vote and read_only then
        if law.linked_law then
            local target_law = GetLawById(law.linked_law)
            buttons.add{
                type = "label",
                caption = {"lawful-evil.gui.linked-law"}
            }
            buttons.add{
                type = "button",
                name = "view_law_" .. target_law.index,
                caption = target_law.title
            }
        end
        if law.revoke_votes[player.name] == nil and not law.linked_law then
            buttons.add{
                type = "button",
                name = "revoke_law_" .. law.index,
                caption = {"lawful-evil.gui.revoke-law"}
            }
            local votes = GetLawVotes(law)
            local revoke_votes = GetLawRevokeVotes(law)
            buttons.add{
                type = "label",
                caption = {"lawful-evil.gui.votes-left-to-revoke", (votes.ayes - revoke_votes)}
            }
            buttons.style.vertical_align = "center"
        end
    end
end

function CreateClauseGUI(parent, clause, read_only)
    local gui = parent.add{
        type = "flow",
        flow = "horizontal" -- TODO: check
    }
    gui.style.horizontally_stretchable = true
    gui.style.height = 32
    if clause.base_clause then
        gui.add{
            type = "label",
            caption = {"when"}
        }
        clause.logic_type = LOGIC_TYPE_BASE
    else
        CreateDropDown{
            parent = gui,
            name = "logic_type",
            items = LOGIC_TYPE_ITEMS,
            selected_index = clause.logic_type,
            read_only = read_only
        }
    end
    local clause_types = GetClauseTypes(clause.logic_type)
    local selected_clause_type_index = GetClauseIndexByID(clause.when_type, clause_types)
    local clause_type_drop_down_options = {}
    for i = 1, #clause_types do
        clause_type_drop_down_options[i] = {"lawful-evil.clause-type." .. clause_types[i]}
    end
    CreateDropDown{
        parent = gui,
        name = "when_type",
        items = clause_type_drop_down_options,
        selected_index = selected_clause_type_index,
        read_only = read_only,
        label_style = "menu_message"
    }
    local when_type = clause.when_type
    if when_type == WHEN_THIS_LAW_PASSED then
        if clause.base_clause then
            gui.add{
                type = "label",
                caption = {"lawful-evil.gui.when_has_base_clause"}
            }
        else
            gui.add{
                type = "label",
                caption = {"lawful-evil.gui.when_has_not_base_clause"}
            }
        end
    elseif when_type == WHEN_VALUE then
        CreateValueFields(gui, clause, "when_", read_only)
        CreateDropDown{
            parent = gui,
            name = "when_operation_type",
            items = OPERATION_TYPE_ITEMS,
            selected_index = clause.when_operation_type,
            read_only = read_only,
            label_style = "menu_message"
        }
        CreateValueFields(gui, clause, "when_2_", read_only)
    elseif when_type == WHEN_FORCE_RESEARCHES then
        local clause_when_research = CreateDropDown{
            parent = gui,
            name = "when_research",
            items = GetTechnologies(),
            selected_index = clause.when_research or 1,
            read_only = read_only
        }
    elseif when_type == WHEN_PLAYER_CHATS  then
        gui.add{
            type = "textfield",
            name = "when_text",
            text = clause.when_text or "",
            enabled = not read_only
        }
    elseif CLAUSE_TYPES[when_type].has_elem_picker then
        local elem_type = CLAUSE_TYPES[when_type].elem_picker_type
        local clause_when_elem = gui.add{
            type = "choose-elem-button",
            name = "when_elem",
            elem_type = elem_type,
            enabled = not read_only
        }
        pcall(function()
            clause_when_elem.elem_value = clause.when_elem
        end)
        if elem_type == "entity" then
            gui.add{
                type = "label",
                caption = {"lawful-evil.gui.include-similar-types"}
            }
            if clause.when_entity_similar_type == nil then
                clause.when_entity_similar_type = false
            end
            gui.add{
                type = "checkbox",
                name = "when_entity_similar_type",
                state = clause.when_entity_similar_type,
                enabled = not read_only
            }
            gui.style.vertical_align = "center"
        end
    end
    if not clause.base_clause and not read_only then
        local delete_button = gui.add(TRASH_BIN)
        delete_button.name = "delete_clause"
        delete_button.style.width = 24
        delete_button.style.height = 24
    end
end

function CreateEffectGUI(parent, effect, read_only)
    local gui = parent.add{
        type = "flow",
        flow = "horizontal" -- TODO: check
    }
    gui.style.horizontally_stretchable = true
    gui.style.height = 32
    gui.add{
        type = "label",
        caption = {"then"}
    }
    CreateDropDown{
        parent = gui,
        name = "effect_type",
        items = EFFECT_TYPE_ITEMS,
        selected_index = effect.effect_type,
        read_only = read_only,
        label_style = "menu_message"
    }
    if effect.effect_type == EFFECT_TYPE_DISALLOW then
        gui.add{
            type = "label",
            caption = {"lawful-evil.gui.disallow-description"}
        }
    elseif effect.effect_type == EFFECT_TYPE_REVOKE_LAW then
        gui.add{
            type = "label",
            caption = {"lawful-evil.gui.revoke-law-description"}
        }
    elseif effect.effect_type == EFFECT_TYPE_CUSTOM_SCRIPT then
        local script_text = parent.add{
            type = "text-box",
            name = "script_text",
            text = effect.script_text or "return function(event)\n game.print(\"Event:\" .. event.name)\nend",
            enabled = not read_only
        }
        script_text.style.minimal_height = 90
        script_text.style.maximal_width = 0
        script_text.style.horizontally_stretchable = true
    elseif effect.effect_type == EFFECT_TYPE_ALERT then
        gui.add{
            type = "textfield",
            name = "effect_text",
            text = effect.effect_text or "Alert text.",
            enabled = not read_only
        }
    elseif effect.effect_type == EFFECT_TYPE_FINE then
        if not effect.effect_fine_type then
            effect.effect_fine_type = EFFECT_FINE_TYPE_INVENTORY
        end
        CreateDropDown{
            parent = gui,
            name = "effect_fine_type",
            items = EFFECT_FINE_TYPE_ITEMS,
            selected_index = effect.effect_fine_type,
            read_only = read_only
        }
        if effect.effect_fine_type == EFFECT_FINE_TYPE_ITEM then
            if not effect.effect_fine_item then
                effect.effect_fine_item = nil
            end
            gui.add{
                type = "choose-elem-button",
                name = "effect_fine_item",
                elem_type = "item",
                item = effect.effect_fine_item,
                enabled = not read_only
            }
            CreateValueFields(gui, effect, "effect_", read_only)
        elseif effect.effect_fine_type == EFFECT_FINE_TYPE_MONEY then
            if is_EasyAPI_loaded() then
                CreateValueFields(gui, effect, "effect_", read_only)
            else
                gui.add{
                    type = "label",
                    caption = {"lawful-evilgui.requires-multiplayer-trading-mod"}
                }
            end
        end
    elseif effect.effect_type == EFFECT_TYPE_REWARD then
        if not effect.effect_reward_type then
            effect.effect_reward_type = EFFECT_FINE_TYPE_ITEM
        end
        CreateDropDown{
            parent = gui,
            name = "effect_reward_type",
            items = EFFECT_REWARD_TYPE_ITEMS,
            selected_index = effect.effect_reward_type,
            read_only = read_only
        }
        if effect.effect_reward_type == EFFECT_REWARD_TYPE_ITEM then
            if not effect.effect_reward_item then
                effect.effect_reward_item = nil
            end
            gui.add{
                type = "choose-elem-button",
                name = "effect_reward_item",
                elem_type = "item",
                item = effect.effect_reward_item,
                enabled = not read_only
            }
            CreateValueFields(gui, effect, "effect_", read_only)
        else
            if is_EasyAPI_loaded() then
                CreateValueFields(gui, effect, "effect_", read_only)
            else
                gui.add{
                    type = "label",
                    caption = {"lawful-evilgui.requires-multiplayer-trading-mod"}
                }
            end
        end
    elseif effect.effect_type == EFFECT_TYPE_LICENSE then
        CreateDropDown{
            parent = gui,
            name = "effect_license_type",
            items = EFFECT_LICENSE_TYPE_ITEMS,
            selected_index = effect.effect_license_type,
            read_only = read_only
        }
        gui.add{
            type = "label",
            caption = {"", {"lawful-evil.gui.allow"}, {"colon"}}
        }
        if effect.effect_license_state == nil then
            effect.effect_license_state = false
        end
        gui.add{
            type = "checkbox",
            name = "effect_license_state",
            state = effect.effect_license_state,
            enabled = not read_only
        }
        gui.style.vertical_align = "center"
    elseif effect.effect_type == EFFECT_TYPE_FINE_FAIL then
        gui.add{
            type = "label",
            caption = {"lawful-evil.gui.fine-fail-description"}
        }
    elseif effect.effect_type == EFFECT_TYPE_NTH_OFFENCE then
        gui.add{
            type = "textfield",
            name = "effect_nth_offence",
            text = effect.effect_nth_offence and tostring(effect.effect_nth_offence) or 1,
            numeric = true,
            allow_decimal = false,
            allow_negative = false
        }
    elseif effect.effect_type == EFFECT_TYPE_RESET_OFFENCE then
        gui.add{
            type = "label",
            caption = {"lawful-evil.gui.reset-offence-description"}
        }
    end
    if not effect.base_effect and not read_only then
        local delete_button = gui.add(TRASH_BIN)
        delete_button.name = "delete_effect"
        delete_button.style.width = 24
        delete_button.style.height = 24
    end
end

function CreateValueFields(gui, clause, prefix, read_only)
    local textfield = gui.add{
        type = "textfield",
        name = prefix.."value",
        text = tostring(clause[prefix.."value"]) or "0",
        enabled = not read_only,
        numeric = true,
        allow_decimal = false,
        allow_negative = false
    }
    textfield.style.width = 50
    local value_type = clause[prefix.."value_type"]
    if not value_type then
        value_type = 1
    end
    CreateDropDown{
        parent = gui,
        name = prefix.."value_type",
        items = VALUE_TYPE_ITEMS,
        selected_index = value_type,
        read_only = read_only,
        label_style = "description_value_label"
    }
    if value_type == VALUE_TYPE_PERCENTAGE then
        local pct_type = clause[prefix.."value_percentage_type"]
        if not pct_type then
            pct_type = 1
        end
        CreateDropDown{
            parent = gui,
            name = prefix.."value_percentage_type",
            items = PERCENTAGE_TYPE_ITEMS,
            selected_index = pct_type,
            read_only = read_only,
            label_style = "menu_message"
        }
        if pct_type == PERCENTAGE_TYPE_BALANCE and not is_EasyAPI_loaded() then
            local missing = gui.add{
                type = "label",
                caption = {"lawful-evil.multiplayer-trading.missing"}
            }
            missing.style.font_color = {r = 1}
        elseif pct_type == PERCENTAGE_TYPE_TOTAL_PRODUCTION
            or pct_type == PERCENTAGE_TYPE_TOTAL_CONSUMPTION
            or pct_type == PERCENTAGE_TYPE_RATE_PRODUCTION
            or pct_type == PERCENTAGE_TYPE_RATE_CONSUMPTION
            then
                gui.add{
                    type = "choose-elem-button",
                    name = prefix.."value_percentage_item",
                    elem_type = "item",
                    item = clause[prefix.."value_percentage_item"],
                    enabled = not read_only
                }
        end
    end
end

local function on_configuration_changed(event)
    local mod_changes = event.mod_changes["m-lawful-evil"]
    if not (mod_changes and mod_changes.old_version) then return end

    local version = tonumber(string.gmatch(mod_changes.old_version, "%d+.%d+")())

    if version < 0.9 then
        for _, player in pairs(game.players) do
            AddLawfulButton(player)
        end
    end
end
script.on_configuration_changed(on_configuration_changed)

remote.remove_interface('lawful-evil')
remote.add_interface('lawful-evil', {
    get_event_name = function(name)
        return module.self_events[name]
    end,
    get_law_by_id = function(target_id)
        local laws = global.laws
        for i=1, #laws do
            law = laws[i]
            if law.id == target_id then
                return law
            end
        end
        return nil
    end,
    get_new_law = GetNewLaw,
    InsertNewLaw = function(new_law)
        game.print({"lawful-evil.messages.law-is-submitted", new_law.title})
        table.insert(global.laws, new_law)
    end,
    revoke_law = RevokeLaw
})
