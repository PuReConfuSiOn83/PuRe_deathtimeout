local ESX = exports['es_extended']:getSharedObject()

local AllowedGroups = {
    owner = true,
    admin = true,
    support = true 
}

RegisterCommand('timeout_reset', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not AllowedGroups[xPlayer.getGroup()] then return end

    local targetId = tonumber(args[1])
    if targetId then
        TriggerClientEvent('crp:combatTimeoutReset', targetId)
        TriggerClientEvent('esx:showNotification', source, 'Kampfsperre für ID '..targetId..' aufgehoben.')
    else
        TriggerClientEvent('esx:showNotification', source, 'Benutzung: /timeout_reset [ID]')
    end
end, false)