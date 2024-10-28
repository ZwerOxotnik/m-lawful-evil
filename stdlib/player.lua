require 'stdlib/core'

Player = {}

function Player.get_data(player)
    fail_if_missing(player, "missing player argument")
    if storage.player_data and storage.player_data[player.index] then
        return storage.player_data[player.index]
    else
        return {}
    end
end

function Player.set_data(player, data)
    fail_if_missing(player, "missing player argument")
    if not storage.player_data then
        storage.player_data = {}
    end
    local previous_data = Player.get_data(player)
    storage.player_data[player.index] = data
    return previous_data
end
