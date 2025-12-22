local ESX = exports['es_extended']:getSharedObject()
local combatBlocked = false
local combatEnd = 0
local isThreadRunning = false
local isDead = false

-- Zeichnet den Timer
local function DrawTimerText(text)
    SetTextFont(4)
    SetTextScale(0.5, 0.5)
    SetTextColour(255, 0, 0, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.85, 0.5)
end

-- Startet die Sperre
local function StartCombatBlock(seconds)
    if combatBlocked then 
        combatEnd = GetGameTimer() + (seconds * 1000)
        return 
    end

    combatBlocked = true
    combatEnd = GetGameTimer() + (seconds * 1000)
    
    -- Offizieller ox_inventory Disarm
    TriggerServerEvent('ox_inventory:disarm', true)

    if isThreadRunning then return end
    isThreadRunning = true

    CreateThread(function()
        if Config.Debug then print('[REVIVE-COMBAT] Sperre aktiv für ' .. seconds .. ' Sekunden.') end
        
        while combatBlocked do
            local playerPed = PlayerPedId()
            local timeLeft = math.ceil((combatEnd - GetGameTimer()) / 1000)

            if timeLeft <= 0 then 
                combatBlocked = false 
                break 
            end

            DrawTimerText("KAMPFUNFÄHIG: " .. timeLeft .. "s")
            
            -- Waffe wegstecken erzwingen (falls über Inventar gezogen)
            if GetSelectedPedWeapon(playerPed) ~= `WEAPON_UNARMED` then
                SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
            end

            -- Angriffs-Steuerung blockieren
            DisablePlayerFiring(playerPed, true)
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 140, true) -- Melee
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            
            -- Hotkeys 1-6 blockieren
            for i = 157, 163 do 
                DisableControlAction(0, i, true) 
            end

            Wait(0)
        end
        
        isThreadRunning = false
        -- Benachrichtigung bei Ablauf
        ESX.ShowNotification("Du fühlst dich wieder stark genug für einen Kampf.")
        if Config.Debug then print('[REVIVE-COMBAT] Sperre abgelaufen.') end
    end)
end

-- Warten auf Config & Initialisierung
CreateThread(function()
    while Config == nil do Wait(100) end
    
    -- Automatischer Check
    CreateThread(function()
        while true do
            local playerPed = PlayerPedId()
            local isCurrentlyDead = IsEntityDead(playerPed) or GetEntityHealth(playerPed) <= 0
            if isCurrentlyDead and not isDead then
                isDead = true
            elseif not isCurrentlyDead and isDead then
                isDead = false
                Wait(800) -- Kurz warten bis das Ped stabil ist
                if not Config.OnlyBucketZero or (Entity(playerPed).state.routingBucket or 0) == 0 then
                    StartCombatBlock(Config.CombatBlockTime)
                end
            end
            Wait(1000)
        end
    end)

    -- Event Handler
    RegisterNetEvent(Config.ReviveEvent, function()
        StartCombatBlock(Config.CombatBlockTime)
    end)
end)

RegisterNetEvent('crp:combatTimeoutReset', function()
    combatBlocked = false
end)