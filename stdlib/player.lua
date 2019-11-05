require 'stdlib/core'

Player = {}

function Player.get_data(player)
    fail_if_missing(player, "missing player argument")
    if global.player_data and global.player_data[player.index] then
        return global.player_data[player.index]
    else
        return {}
    end
end

function Player.set_data(player, data)
    fail_if_missing(player, "missing player argument")
    if not global.player_data then
        global.player_data = {}
    end
    local previous_data = Player.get_data(player)
    global.player_data[player.index] = data
    return previous_data
end