MultiplayerTrading = {
    mod_id = "m-multiplayer-trading"
}

function MultiplayerTrading.is_loaded()
    return game.active_mods["m-multiplayertrading"] ~= nil
end

function MultiplayerTrading.add_to_balance(force, amount)
    if MultiplayerTrading.is_loaded() then
        remote.call(MultiplayerTrading.mod_id, "add-money", force, amount)
    end
end

function MultiplayerTrading.get_balance(force)
    if MultiplayerTrading.is_loaded() then
        return remote.call(MultiplayerTrading.mod_id, "get-money", force)
    end
    return 0
end