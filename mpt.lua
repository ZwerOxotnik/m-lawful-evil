local call = remote.call

EasyAPI = {}

function EasyAPI.is_loaded()
    return game.active_mods["EasyAPI"] ~= nil
end

function EasyAPI.add_to_balance(force, amount)
    if EasyAPI.is_loaded() then
        call("EasyAPI", "deposit_force_money", force, amount)
    end
end

function EasyAPI.get_balance(force)
    if EasyAPI.is_loaded() then
        return (call("EasyAPI", "get_force_money", force.index) or 0)
    end
    return 0
end
