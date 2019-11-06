WHEN_PLAYER_BUILDS = "player-builds"
WHEN_PLAYER_MINES = "player-mines"
WHEN_PLAYER_DAMAGES = "player-damages"
WHEN_PLAYER_DESTROYS = "player-destroys"
WHEN_PLAYER_CRAFTS = "player-crafts"
WHEN_PLAYER_TILES = "player-tiles"
WHEN_PLAYER_MINES_TILE = "player-mines-tiles"
WHEN_PLAYER_KILLS = "player-kills-player"
WHEN_FORCE_RESEARCHES = "force-researches"
WHEN_ROCKET_LAUNCHES = "rocket-launched"
WHEN_PLAYER_CHATS = "player-chats"
WHEN_THIS_LAW_PASSED = "this-law-passed"
WHEN_VALUE = "value"
WHEN_DAY = "daytime"
WHEN_NIGHT = "nighttime"

CLAUSE_TYPES = {
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
}

ELEM_ENTITY = 1
ELEM_ITEM = 2
ELEM_FLUID = 3

EFFECT_TYPE_ITEMS = {
    "fine", 
    "reward", 
    "alert", 
    "disallow*",
    "license",
    "death penalty",
    "kick from server",
    "ban from server",
    "mute player",
    "unmute player",
    "if fine fails,",
    "if nth offence,",
    "reset offence count"
}
EFFECT_TYPE_FINE = 1
EFFECT_TYPE_REWARD = 2
EFFECT_TYPE_ALERT = 3
EFFECT_TYPE_DISALLOW = 4
EFFECT_TYPE_LICENSE = 5
EFFECT_TYPE_KILL = 6
EFFECT_TYPE_KICK = 7
EFFECT_TYPE_BAN = 8
EFFECT_TYPE_MUTE = 9
EFFECT_TYPE_UNMUTE = 10
EFFECT_TYPE_FINE_FAIL = 11
EFFECT_TYPE_NTH_OFFENCE = 12
EFFECT_TYPE_RESET_OFFENCE = 13

EFFECT_LICENSE_TYPE_ITEMS = {
    "car license",
    "tank license",
    "train license",
    "gun license",
    "artillery license"
}
EFFECT_LICENSE_TYPE_CAR = 1
EFFECT_LICENSE_TYPE_TANK = 2
EFFECT_LICENSE_TYPE_TRAIN = 3
EFFECT_LICENSE_TYPE_GUN = 4
EFFECT_LICENSE_TYPE_ARTILLERY = 5

EFFECT_FINE_TYPE_ITEMS = {
    "player inventory",
    "item",
    "money"
}
-- TODO: Check it
-- EFFECT_FINE_TYPE_ITEMS = {
--     {"player-inventory"},
--     {"item"},
--     {"money"}
-- }
EFFECT_FINE_TYPE_INVENTORY = 1
EFFECT_FINE_TYPE_ITEM = 2
EFFECT_FINE_TYPE_MONEY = 3

EFFECT_REWARD_TYPE_ITEMS = {
    "item",
    "money"
}
EFFECT_REWARD_TYPE_ITEM = 1
EFFECT_REWARD_TYPE_MONEY = 2

VALUE_TYPE_ITEMS = {"percent of", "fixed amount"}
VALUE_TYPE_PERCENTAGE = 1
VALUE_TYPE_FIXED = 2

OPERATION_TYPE_ITEMS = {"equals", "not equal", "greater than", "less than"}
OPERATION_TYPE_EQUAL = 1
OPERATION_TYPE_NOT_EQUAL = 2
OPERATION_TYPE_GREATER_THAN = 3
OPERATION_TYPE_LESS_THAN = 4

PERCENTAGE_TYPE_ITEMS = {
    "players", "force's players", 
    "balance", 
    "evolution factor", 
    "rockets launched", 
    "total production", "production per min", 
    "total consumption", "consumption per min",
    "technologies researched",
    "trains", "force's trains",
    "construction robots",
    "force's construction robots",
    "logistic robots",
    "force's logistic robots",
    "player's time online",
    "player's afk time",
    "game tick",
    "time of day"
}
PERCENTAGE_TYPE_PLAYER_COUNT = 1
PERCENTAGE_TYPE_FORCE_PLAYER_COUNT = 2
PERCENTAGE_TYPE_BALANCE = 3
PERCENTAGE_TYPE_EVOLUTION_FACTOR = 4
PERCENTAGE_TYPE_ROCKETS_LAUNCHED = 5
PERCENTAGE_TYPE_TOTAL_PRODUCTION = 6
PERCENTAGE_TYPE_RATE_PRODUCTION = 7
PERCENTAGE_TYPE_TOTAL_CONSUMPTION = 8
PERCENTAGE_TYPE_RATE_CONSUMPTION = 9
PERCENTAGE_TYPE_TECHNOLOGIES_RESEARCHED = 10
PERCENTAGE_TYPE_TRAINS = 11
PERCENTAGE_TYPE_FORCE_TRAINS = 12
PERCENTAGE_TYPE_CONSTRUCTION_ROBOTS = 13
PERCENTAGE_TYPE_FORCE_CONSTRUCTION_ROBOTS = 14
PERCENTAGE_TYPE_LOGISTIC_ROBOTS = 15
PERCENTAGE_TYPE_FORCE_LOGISTIC_ROBOTS = 16
PERCENTAGE_TYPE_PLAYER_TIME_ONLINE = 17
PERCENTAGE_TYPE_PLAYER_TIME_AFK = 18
PERCENTAGE_TYPE_GAME_TICK = 19
PERCENTAGE_TYPE_DAYTIME = 20

LOGIC_TYPE_ITEMS = {"and", "or"}
LOGIC_TYPE_AND = 1
LOGIC_TYPE_OR = 2
LOGIC_TYPE_BASE = 3

VOTE_AYE = 1
VOTE_NAY = 2