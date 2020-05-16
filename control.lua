require 'stdlib/event/event'
require 'stdlib/gui/gui'
require 'stdlib/player'
require 'stdlib/game'
require 'mpt'
require 'mod-defines'

-- TODO: add admin mode and then extend the mode
-- TODO: make several tables for laws
-- TODO: store last n laws in another variable for revoting by players
-- TODO: filter picking of entity

local module = {}
module.self_events = require 'self_events'

script.on_init(function()
    global.laws = {}
    global.last_id = 0
    local example_law = GetNewLaw(nil)
    example_law.title = "Example Law"
    example_law.description = "This law is an example"
    example_law.clauses[1] =  {
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

-- commands.add_command("pass-laws", "pass laws", function()
--     for _, law in pairs(global.laws) do
--         if not law.passed then
--             PassLaw(law)
--         end
--     end
-- end)

local function AddLawfulButton(player)
    local gui = player.gui.top
    if gui.lawful_evil_button then
        gui.lawful_evil_button.destroy()
    end
    local button = gui.add{
        type = "sprite-button",
        name = "lawful_evil_button",
        sprite = "lawful-button-sprite"
    }
end

Event.register(defines.events.on_player_created, function(event)
    local player = Event.get_player(event)
    AddLawfulButton(player)
end)

Event.register(defines.events.on_console_chat, function(event)
    local player = Event.get_player(event)
    if not (player and player.valid) then return end
    local message = event.message
    local laws = LawMatch(WHEN_PLAYER_CHATS, message, player.force, player)
    event.force = player.force
    ExecuteLaws(laws, event)
end)

local function law_on_entity_died(event, player)
    if not (player and player.valid) then return end

    local laws = LawMatch(WHEN_PLAYER_DESTROYS, event.entity.name, event.force, player)
    if player.is_player() then
        event.player_index = player.index
    end
    event.force = event.cause.force
    ExecuteLaws(laws, event)
end

Event.register(defines.events.on_entity_died, function(event)
    local cause = event.cause
    if not (cause and cause.valid) then return end

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
end)

local function law_on_entity_damaged(event, player)
    if not (player and player.valid) then return end

    local laws = LawMatch(WHEN_PLAYER_DAMAGES, event.entity.name, event.force, player)
    if player.is_player() then
        event.player_index = player.index
    end
    event.force = event.cause.force
    ExecuteLaws(laws, event)
end

Event.register(defines.events.on_entity_damaged, function(event)
    local cause = event.cause
    if not (cause and cause.valid) then return end

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
end)

Event.register(defines.events.on_built_entity, function(event)
    local player = Event.get_player(event)
    local laws = LawMatch(WHEN_PLAYER_BUILDS, event.created_entity.name, player.force, player)
    event.entity = event.created_entity
    event.built = true
    event.force = player.force
    ExecuteLaws(laws, event)
end)

Event.register(defines.events.on_player_mined_entity, function(event)
    local player = Event.get_player(event)
    local laws = LawMatch(WHEN_PLAYER_MINES, event.entity.name, player.force, player)
    event.mined = true
    event.force = player.force
    ExecuteLaws(laws, event)
end)

Event.register(defines.events.on_player_crafted_item, function(event)
    local player = Event.get_player(event)
    local laws = LawMatch(WHEN_PLAYER_CRAFTS, event.item_stack.name, player.force, player)
    event.force = player.force
    ExecuteLaws(laws, event)
end)

Event.register(defines.events.on_player_built_tile, function(event)
    local player = Event.get_player(event)
    for _, tile in pairs(event.tiles) do
        local laws = LawMatch(WHEN_PLAYER_TILES, event.item.name, player.force, player)
        event.force = player.force
        ExecuteLaws(laws, event)
    end
end)

Event.register(defines.events.on_player_mined_tile, function(event)
    local player = Event.get_player(event)
    for _, tile in pairs(event.tiles) do
        event.item = tile.old_tile.items_to_place_this
        local laws = LawMatch(WHEN_PLAYER_MINES_TILES, event.item.name, player.force, player)
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
        nil)
    event.force = event.rocket.force
    ExecuteLaws(laws, event)
end)

Event.register(defines.events.on_player_died, function(event)
    if event.cause and event.cause.is_player() then
        local laws = LawMatch(
            WHEN_PLAYER_KILLS, 
            event.cause,
            event.cause.force,
            nil)
        event.force = event.cause.force
        event.player_index = event.cause.associated_player.index
        ExecuteLaws(laws, event)
    end
end)

Event.register(defines.events.on_player_driving_changed_state, function(event)
    local player = Event.get_player(event)
    local player_data = Player.get_data(player)
    local vehicle = event.entity
    if vehicle then
        local driver = vehicle.get_driver()
        if driver and driver.player == player then
            if vehicle.name == "car" and player_data.disallow_car then
                vehicle.set_driver(nil)
            elseif vehicle.name == "tank" and player_data.disallow_tank then
                vehicle.set_driver(nil)
            elseif vehicle.name == "locomotive" and player_data.disallow_locomotive then
                vehicle.set_driver(nil)
            end
        end
    end
end)

script.on_nth_tick(3, function(event)
    -- Remove items (queued up via law effects)
    for _, player in pairs(game.players) do -- TODO: change for connected players
        local data = Player.get_data(player)
        if data.remove_item then
            player.remove_item(data.remove_item)
            data.remove_item = nil
        end
    end
end)

local function CheckVotes()
    for _, law in pairs(global.laws) do
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

    for i, force in pairs(game.forces) do
        if not global.production_rates[force.name] then
            global.production_rates[force.name] = {
                production = {},
                consumption = {}
            }
        end
        local rates = global.production_rates[force.name]
        for item, count in pairs(force.item_production_statistics.input_counts) do
            if rates.production[item] then
                rates.production[item].rate = count - rates.production[item].last
            else
                rates.production[item] = {
                    rate = 0,
                    last = count
                }
            end
        end
        for item, count in pairs(force.item_production_statistics.output_counts) do
            if rates.consumption[item] then
                rates.consumption[item].rate = count - rates.consumption[item].last
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
    local player = Event.get_player(event)
    local lawful_gui = GetLawfulEvilGui(player)
    if lawful_gui then
        lawful_gui.destroy()
    else
        local law_gui = GetLawGui(player)
        if law_gui then
            law_gui.destroy()
        else
            CreateLawfulEvilGUI(player)
        end
    end
end)

Gui.on_click("close_lawful_gui", function(event)
    local player = Event.get_player(event)
    local lawful_gui = GetLawfulEvilGui(player)
    if lawful_gui then
        lawful_gui.destroy()
    end
end)

Gui.on_click("propose_law", function(event)
    local player = Event.get_player(event)
    local lawful_gui = GetLawfulEvilGui(player)
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

Gui.on_click("add_clause", function(event)
    local player = Event.get_player(event)
    local law_gui = GetLawGui(player)
    if law_gui then
        local subclause = CreateSubClause()
        CreateClauseGUI(law_gui.clauses_frame.clauses, subclause)
        SaveLaw(law_gui)
    end
end)

Gui.on_click("add_effect", function(event)
    local player = Event.get_player(event)
    local law_gui = GetLawGui(player)
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
    local player = Event.get_player(event)
    local law_gui = GetLawGui(player)
    local elem = event.element
    if law_gui then
        elem.parent.destroy()
        SaveLaw(law_gui)
    end
end)

Gui.on_click("vote_law_([0-9]+)", function(event)
    local player = Event.get_player(event)
    local law_gui = GetLawfulEvilGui(player)
    if law_gui then
        law_gui.destroy()
    else
        law_gui = GetLawGui(player)
        if law_gui then
            law_gui.destroy()
        end
    end
    local law_id = tonumber(event.match)
    local law = GetLaw(law_id)
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
    local player = Event.get_player(event)
    local law_gui = GetLawfulEvilGui(player)
    if law_gui then
        law_gui.destroy()
    else
        law_gui = GetLawGui(player)
        if law_gui then
            law_gui.destroy()
        end
    end
    local law_id = tonumber(event.match)
    local law = GetLaw(law_id)
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
        player = Event.get_player(event),
        law_index = law_index,
        law = GetLaw(law_index)
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
    local player = Event.get_player(event)
    CloseLawGui(player)
end)

Gui.on_click("submit_law", function(event)
    local player = Event.get_player(event)
    local gui = GetLawGui(player)
    if gui then
        local law = SaveLaw(gui)
        table.insert(global.laws, law)
        gui.destroy()
        CreateLawfulEvilGUI(player)
    end
end)

Gui.on_selection_state_changed("when_elem_type", function(event)
    local elem = event.element
    local law = GetLaw()
    if law.when_elem_type ~= elem.selected_index then
        law.when_elem = nil
    end
    law.when_elem_type = elem.selected_index
end)

Gui.on_selection_state_changed(".+", function(event)
    local elem = event.element
    local player = Event.get_player(event)
    if elem.parent.parent.name == "clauses" then
        local gui = GetLawGui(player)
        local law = SaveLaw(gui)
        gui.clauses_frame.clauses.clear()
        for _, clause in pairs(law.clauses) do
            CreateClauseGUI(gui.clauses_frame.clauses, clause)
        end
    elseif elem.parent.parent.name == "effects" then
        local gui = GetLawGui(player)
        local law = SaveLaw(gui)
        gui.effects_frame.effects.clear()
        for _, effect in pairs(law.effects) do
            CreateEffectGUI(gui.effects_frame.effects, effect)
        end
    end
end)

function IsDaytime()
    local surface = game.surfaces[1]
    return not (surface.daytime > surface.evening and surface.daytime < surface.morning)
end

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

function GetLaw(index)
    return global.laws[index]
end

function GetLawById(id)
    for _, law in pairs(global.laws) do
        if law.id == id then
            return law
        end
    end
end

function CreateSubClause()
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

function SaveLaw(gui)
    local player = game.players[gui.player_index]
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
        local effect = {
            base_effect = (i == 1)
        }
        law.effects[i] = SaveEffect(elem, law, effect)
    end
    if gui.buttons.linked_law.selected_index > 1 then
        local options = {0}
        for _, law in pairs(global.laws) do
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

function SaveClause(gui, law, clause)
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

function SaveEffect(gui, law, effect)
    effect.effect_type = gui.effect_type.selected_index
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

function LawMatch(type, target, force, player)
    local matched_laws = {}
    for _, law in pairs(global.laws) do
        if law.passed then
            law.inverse_effects = false
            local results = {}
            for _, clause in pairs(law.clauses) do
                local result = ClauseMatch(law, clause, type, target, force, player)
                table.insert(results, {
                    success = result,
                    logic = clause.base_clause and LOGIC_TYPE_BASE or clause.logic_type
                })
            end
            if #results == 1 and results[1].success then
                table.insert( matched_laws, law )
            end
            if #results > 1 then
                local state = results[1].success
                for i = 2, #results do
                    if results[i].logic == LOGIC_TYPE_AND then
                        state = (state and results[i].success)
                    elseif results[i].logic == LOGIC_TYPE_OR then
                        if state then
                            break
                        else
                            state = (state or results[i].success)
                        end
                    end
                end
                if state then
                    table.insert( matched_laws, law )
                end
            end
        end
    end
    return matched_laws
end

function ClauseMatch(law, clause, type, target, force, player)
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
                player)
        end
        if clause.when_2_value_type == VALUE_TYPE_PERCENTAGE then
            value_2 = CalculatePercentageValue(
                value_2, 
                clause.when_2_value_percentage_type, 
                clause.when_2_value_percentage_item,
                force,
                player)
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

function CalculatePercentageValue(value, type, item, force, player)
    local factor = value * 0.01
    if type == PERCENTAGE_TYPE_BALANCE then
        return MultiplayerTrading.get_balance(force) * factor
    elseif type == PERCENTAGE_TYPE_PLAYER_COUNT then
        local count = 0
        for _, tech in pairs(game.players) do count = count + 1 end
        return count * factor
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
            if global.production_rates[force.name].production[item] then
                return global.production_rates[force.name].production[item].rate
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
            if global.production_rates[force.name].consumption[item] then
                return global.production_rates[force.name].consumption[item].rate
            end
        end
        return 0
    elseif type == PERCENTAGE_TYPE_TECHNOLOGIES_RESEARCHED then
        local count = 0
        for _, tech in pairs(force.technologies) do count = count + 1 end
        return count * factor
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

function CalculateWithOperation(value_1, value_2, operation)
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

function ExecuteLaws(laws, event)
    for i, law in pairs(laws) do
        local clause = law.clauses[1]
        
        -- Apply offense count
        if not law.offences then law.offences = {} end
        local player = Event.get_player(event)
        if player and not event.all_players then
            local count = law.offences[event.player_index]
            if count then
                law.offences[event.player_index] = count + 1
            else
                law.offences[event.player_index] = 1
            end
        end

        for i, effect in pairs(law.effects) do
            if event.all_players then
                for _, player in pairs(game.players) do
                    ExecuteEffect(law, effect, {
                        player_index = player.index,
                        force = player.force
                    })
                end
            else
                ExecuteEffect(law, effect, event)
            end
        end
    end
end

function ExecuteEffect(law, effect, event)
    local force = event.force
    local player = Event.get_player(event)
    local offence_count = law.offences[event.player_index]
    local value = effect.effect_value
    if value ~= nil and effect.effect_value_type == VALUE_TYPE_PERCENTAGE then
        value = CalculatePercentageValue(
            value,
            effect.effect_value_percentage_type,
            effect.effect_value_percentage_item,
            force,
            player)
    end
    
    if effect.effect_type == EFFECT_TYPE_NTH_OFFENCE then
        event.stop_effects = (offence_count ~= effect.effect_nth_offence)
        -- game.print(offence_count.." == "..effect.effect_nth_offence)
    end

    if event.stop_effects then
        return
    end

    if effect_type == EFFECT_TYPE_RESET_OFFENCE then
        law.offences[event.player_index] = 0
    elseif effect.effect_type == EFFECT_TYPE_REWARD then
        if effect.effect_reward_type == EFFECT_REWARD_TYPE_ITEM then
            player.insert{
                name = effect.effect_reward_item,
                count = math.floor(value)
            }
        elseif effect.effect_reward_type == EFFECT_REWARD_TYPE_MONEY then
            MultiplayerTrading.add_to_balance(force, value)
        end
    elseif effect.effect_type == EFFECT_TYPE_FINE then
        if effect.effect_fine_type == EFFECT_FINE_TYPE_INVENTORY then
            event.fine_success = true
            player.clear_items_inside()
        elseif effect.effect_fine_type == EFFECT_FINE_TYPE_ITEM then
            local count = player.get_item_count(effect.effect_fine_item)
            event.fine_success = (count >= math.floor(value))
            player.remove_item{
                name = effect.effect_fine_item,
                count = math.floor(value)
            }
        elseif effect.effect_fine_type == EFFECT_FINE_TYPE_MONEY then
            local balance = MultiplayerTrading.get_balance(force)
            event.fine_success = (balance >= value)
            MultiplayerTrading.add_to_balance(force, -value)
        end
    elseif effect.effect_type == EFFECT_TYPE_FINE_FAIL then
        event.stop_effects = (event.fine_success == true or event.fine_success == nil)
    elseif effect.effect_type == EFFECT_TYPE_DISALLOW then
        if event.item_stack and event.recipe then
            Player.set_data(player, {
                remove_item = event.item_stack
            })
            for _, ingredient in pairs(event.recipe.ingredients) do
                player.insert{name = ingredient.name, count = ingredient.amount}
            end
        elseif event.research then
            force.current_research = nil
        elseif event.mined then
            player.surface.create_entity{
                name = event.entity.name,
                position = event.entity.position,
                direction = event.entity.direction,
                force = event.entity.force
            }
            buffer.clear()
        elseif event.built then
            player.mine_entity(event.entity, true)
        end
    elseif effect.effect_type == EFFECT_TYPE_ALERT then
        local msg = effect.effect_text or ""
        if player then
            game.print({"lawful-evil.messages.player-triggered-a-law", player.name, msg})
        elseif force then
            game.print({"lawful-evil.messages.force-triggered-a-law", force.name, msg})
        end
    elseif effect.effect_type == EFFECT_TYPE_KILL then
        if player then
            player.character.die(nil)
        end
    elseif effect.effect_type == EFFECT_TYPE_KICK then
        if player then
            game.kick_player(player, "Broke the law: "..law.title)
        end
    elseif effect.effect_type == EFFECT_TYPE_BAN then
        if player then
            game.ban_player(player, "Broke the law: "..law.title)
        end
    elseif effect.effect_type == EFFECT_TYPE_MUTE then
        if player then
            game.mute_player(player)
        end
    elseif effect.effect_type == EFFECT_TYPE_UNMUTE then
        if player then
            game.unmute_player(player)
        end
    elseif effect.effect_type == EFFECT_TYPE_LICENSE and player then
        local player_data = Player.get_data(player)
        if effect.effect_license_type == EFFECT_LICENSE_TYPE_CAR then
            player_data.disallow_car = not effect.effect_license_state
        elseif effect.effect_license_type == EFFECT_LICENSE_TYPE_TANK then
            player_data.disallow_tank = not effect.effect_license_state
        elseif effect.effect_license_type == EFFECT_LICENSE_TYPE_TRAIN then
            player_data.disallow_locomotive = not effect.effect_license_state
        elseif effect.effect_license_type == EFFECT_LICENSE_TYPE_GUN then
            player_data.disallow_gun = not effect.effect_license_state
            if effect.effect_license_state then
                game.permissions.get_group("no_shooting").remove_player(player)
            else
                game.permissions.get_group("no_shooting").add_player(player)
            end
        elseif effect.effect_license_type == EFFECT_LICENSE_TYPE_ARTILLERY then
            player_data.disallow_artillery = not effect.effect_license_state
            if effect.effect_license_state then
                game.permissions.get_group("no_artillery").remove_player(player)
            else
                game.permissions.get_group("no_artillery").add_player(player)
            end
        end
        Player.set_data(player, player_data)
    end
end

function GetLawfulEvilGui(player)
    return player.gui.center["lawful_evil_gui"]
end

function GetLawGui(player)
    return player.gui.center["lawful_evil_law_gui"]
end

function RefreshAllLawfulEvilGui()
    for _, player in pairs(game.players) do
        local lawful_gui = GetLawfulEvilGui(player)
        if lawful_gui then
            lawful_gui.destroy()
            CreateLawfulEvilGUI(player)
        end
    end
end

function CloseLawGui(player)
    local gui = GetLawGui(player)
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
    for _, other_law in pairs(global.laws) do
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
    for i, other_law in pairs(global.laws) do
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

local _technologies = nil
function GetTechnologies()
    if _technologies == nil then
        _technologies = {}
        for tech_name, tech in pairs(game.technology_prototypes) do
            table.insert(_technologies, tech.localised_name)
        end
    end
    return _technologies
end

local _entity_types = nil
function GetEntityTypes()
    if _entity_types == nil then
        _entity_types = {}
        local type_map = {}
        for name, entity in pairs(game.entity_prototypes) do
            if not type_map[entity.type] then
                type_map[entity.type] = 1
            else
                type_map[entity.type] = type_map[entity.type] + 1
            end
        end
        for type, count in pairs(type_map) do
            if count > 1 then
                table.insert(_entity_types, type)
            end
        end
    end
    return _entity_types
end

function GetClauseTypes(logic_type)
    local collected_types = {}
    for id, type in pairs(CLAUSE_TYPES) do
        if  (type.base_allowed and logic_type == LOGIC_TYPE_BASE) 
            or (type.and_allowed and logic_type == LOGIC_TYPE_AND) 
            or (type.or_allowed and logic_type == LOGIC_TYPE_OR)
            then
                table.insert(collected_types, id)
        end
    end
    table.sort(collected_types, function(a,b)
        return CLAUSE_TYPES[a].order < CLAUSE_TYPES[b].order
    end)
    return collected_types
end

function GetClauseIndexByID(clause_type_id, clause_types)
    if clause_type_id ~= nil then
        for i, id in pairs(clause_types) do
            if id == clause_type_id then
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
    for i, law in pairs(global.laws) do
        law.index = i
        if law.passed then
            table.insert(passed_laws, law)
        else
            table.insert(proposed_laws, law)
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
    if #passed_laws == 0 then
        passed_laws_scroll.add{
            type = "label",
            caption = {"size.none"}
        }
    end
    for i, law in pairs(passed_laws) do
        local law_frame = passed_laws_scroll.add{
            type = "frame",
            direction = "vertical",
            caption = law.title
        }
        law_frame.style.horizontally_stretchable = true
        local flow1 = law_frame.add{
            type = "flow",
            direction = "horizontal"
        }
        local flow2 = flow1.add{
            type = "flow",
            direction = "horizontal"
        }
        flow2.style.horizontally_stretchable = true
        local description = flow2.add{
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
    if #proposed_laws == 0 then
        laws_scroll.add{
            type = "label",
            caption = {"size.none"}
        }
    end
    for i, law in pairs(proposed_laws) do
        local law_frame = laws_scroll.add{
            type = "frame",
            direction = "vertical",
            caption = law.title
        }
        law_frame.style.horizontally_stretchable = true
        law_frame.style.vertically_stretchable = true
        law_frame.style.maximal_height = 150
        local flow1 = law_frame.add{
            type = "flow",
            direction = "horizontal"
        }
        local flow2 = flow1.add{
            type = "flow",
            direction = "horizontal"
        }
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
        local vote_button = flow1.add{
            type = "button",
            name = "vote_law_" .. law.index,
            caption = {"view"}
        }
        local voting_mins_left = 1
        local voting_ticks_left = law.vote_end_tick - game.tick
        if voting_ticks_left > 3600 then
            voting_mins_left = math.ceil((voting_ticks_left) / 3600)
        end
        local meta_flow = law_frame.add{
            type = "flow",
            name = "meta_flow",
            direction = "horizontal"
        }
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

    local bottom_buttons_flow = gui.add{
        type = "flow",
        direction = "horizontal"
    }
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
        gui.add{
            type = "textfield",
            name = "law_title",
            text = law.title or "Title...",
            enabled = not read_only
        }
    end
    local description = gui.add{
        type = "text-box",
        name = "law_description",
        text = law.description or "State your intent...",
        enabled = not read_only
    }
    description.style.height = 50
    description.style.width = 500

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

    for i, clause in pairs(law.clauses) do
        CreateClauseGUI(clauses_gui, clause, read_only)
    end
    for i, effect in pairs(law.effects) do
        CreateEffectGUI(effects_gui, effect, read_only)
    end

    local buttons = gui.add{
        type = "flow",
        name = "buttons",
        direction = "horizontal"
    }
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
        local i = 2
        for _, law in pairs(global.laws) do
            if not law.passed then
                table.insert(options, law.title)
                options_indexed[law.id] = i
                i = i + 1
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
        flow = "horizontal"
    }
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
    for i, type in pairs(clause_types) do
        clause_type_drop_down_options[i] = {"lawful-evil.clause-type." .. type}
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
        local delete_button = gui.add{
            type = "sprite-button",
            name = "delete_clause",
            sprite = "utility/trash_bin"
        }
        delete_button.style.width = 24
        delete_button.style.height = 24
    end
end

function CreateEffectGUI(parent, effect, read_only)
    local gui = parent.add{
        type = "flow",
        flow = "horizontal"
    }
    gui.style.height = 32
    local main_label = gui.add{
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
            local item_picker = gui.add{
                type = "choose-elem-button",
                name = "effect_fine_item",
                elem_type = "item",
                item = effect.effect_fine_item,
                enabled = not read_only
            }
            CreateValueFields(gui, effect, "effect_", read_only)
        elseif effect.effect_fine_type == EFFECT_FINE_TYPE_MONEY then
            if MultiplayerTrading.is_loaded() then
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
            local item_picker = gui.add{
                type = "choose-elem-button",
                name = "effect_reward_item",
                elem_type = "item",
                item = effect.effect_reward_item,
                enabled = not read_only
            }
            CreateValueFields(gui, effect, "effect_", read_only)
        else
            if MultiplayerTrading.is_loaded() then
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
        local delete_button = gui.add{
            type = "sprite-button",
            name = "delete_effect",
            sprite = "utility/trash_bin"
        }
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
        if pct_type == PERCENTAGE_TYPE_BALANCE and not MultiplayerTrading.is_loaded() then
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
    for _, player in pairs(game.players) do
        AddLawfulButton(player)
    end
end

script.on_configuration_changed(on_configuration_changed)

remote.remove_interface('lawful-evil')
remote.add_interface('lawful-evil', {
    get_event_name = function(name)
		return module.self_events[name]
    end,
    get_law_by_id = function(target_id)
        for _, law in pairs(global.laws) do
            if law.id == target_id then
                return law
            end
        end
        return nil
    end,
    get_new_law = GetNewLaw,
    InsertNewLaw = function(new_law)
        table.insert(global.laws, new_law)
    end,
    revoke_law = RevokeLaw
})
