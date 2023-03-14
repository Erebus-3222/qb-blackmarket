local QBCore = exports["qb-core"]:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local inChips = false
local currentShop, currentData
local pedSpawned = false
local listen = false
local ShopPed = {}
local NewZones = {}
-- Functions
local function createBlips()
    if pedSpawned then return end

    for store in pairs(Config.Locations) do
        if Config.Locations[store]["showblip"] then
            local StoreBlip = AddBlipForCoord(Config.Locations[store]["coords"]["x"], Config.Locations[store]["coords"]["y"], Config.Locations[store]["coords"]["z"])
            SetBlipSprite(StoreBlip, Config.Locations[store]["blipsprite"])
            SetBlipScale(StoreBlip, Config.Locations[store]["blipscale"])
            SetBlipDisplay(StoreBlip, 4)
            SetBlipColour(StoreBlip, Config.Locations[store]["blipcolor"])
            SetBlipAsShortRange(StoreBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Config.Locations[store]["label"])
            EndTextCommandSetBlipName(StoreBlip)
        end
    end
end

local function openShop(shop, data)
    QBCore.Functions.TriggerCallback('A-blackmarket:server:SetShopInv', function(shopInvJson)
        local function SetupItems(checkLicense)
            local products =  Config.Locations[shop].products
            local items = {}
            local curJob
            local curGang
            shopInvJson = json.decode(shopInvJson)
            if Config.UseTruckerJob and next(shopInvJson) and shopInvJson[shop] then
                if next(shopInvJson) then
                    for k, v in pairs(shopInvJson[shop].products) do
                        products[k].amount = v.amount
                    end
                else print('No shop inventory found -- defaults enabled') end
            end
            for i = 1, #products do
            curJob = products[i].requiredJob
            curGang = products[i].requiredGang
            if curJob then goto jobCheck end
            if curGang then goto gangCheck end
            if checkLicense then goto licenseCheck end
            items[#items + 1] = products[i]
            goto nextIteration
            :: jobCheck ::
            for i2 = 1, #curJob do
                if PlayerData.job.name == curJob[i2] then
                    items[#items + 1] = products[i]
                end
            end
            goto nextIteration
            :: gangCheck ::
            for i2 = 1, #curGang do
                if PlayerData.gang.name == curGang[i2] then
                    items[#items + 1] = products[i]
                end
            end
            goto nextIteration
            :: licenseCheck ::
            if not products[i].requiresLicense then
                items[#items + 1] = products[i]
            end
            :: nextIteration ::
            end
            return items
        end
        TriggerServerEvent('A-blackmarket:server:SetShopList')
        local ShopItems = {}
        ShopItems.items = {}
        ShopItems.label = data["label"]
        if data.type == "weapon" and Config.FirearmsLicenseCheck then
            if PlayerData.metadata["licenses"] and PlayerData.metadata["licenses"].weapon and QBCore.Functions.HasItem("weaponlicense") then
                ShopItems.items = SetupItems()
                QBCore.Functions.Notify(Lang:t("success.dealer_verify"), "success")
                Wait(500)
            else
                ShopItems.items = SetupItems(true)
                QBCore.Functions.Notify(Lang:t("error.dealer_decline"), "error")
                Wait(500)
                QBCore.Functions.Notify(Lang:t("error.talk_cop"), "error")
                Wait(1000)
            end
        else
            ShopItems.items = SetupItems()
        end

        for k in pairs(ShopItems.items) do
            ShopItems.items[k].slot = k
        end
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "Itemshop_" .. shop, ShopItems)
    end)
end

local function listenForControl()
    if listen then return end
    CreateThread(function()
        listen = true
        while listen do
            TriggerServerEvent('A-blackmarket:server:SetShopList')
            if IsControlJustPressed(0, 38) then -- E
                if inChips then
                    exports["qb-core"]:KeyPressed()
                    TriggerServerEvent("A-blackmarket:server:sellChips")
                else
                    exports["qb-core"]:KeyPressed()
                    openShop(currentShop, currentData)
                end
                listen = false
                break
            end
            Wait(0)
        end
    end)
end

local function createPeds()
    if pedSpawned then return end

    for k, v in pairs(Config.Locations) do
        local current = type(v["ped"]) == "number" and v["ped"] or joaat(v["ped"])

        RequestModel(current)
        while not HasModelLoaded(current) do
            Wait(0)
        end

        ShopPed[k] = CreatePed(0, current, v["coords"].x, v["coords"].y, v["coords"].z-1, v["coords"].w, false, false)
        TaskStartScenarioInPlace(ShopPed[k], v["scenario"], 0, true)
        FreezeEntityPosition(ShopPed[k], true)
        SetEntityInvincible(ShopPed[k], true)
        SetBlockingOfNonTemporaryEvents(ShopPed[k], true)

        if Config.UseTarget then
            -- exports['qb-target']:AddTargetEntity(ShopPed[k], {
            --     options = {
            --         {
            --             label = v["targetLabel"],
            --             icon = v["targetIcon"],
            --             item = v["item"],
            --             action = function()
            --                 openShop(k, Config.Locations[k])
            --             end,
            --             job = v.requiredJob,
            --             gang = v.requiredGang
            --         }
            --     },
            --     distance = 2.0
            -- })

            exports['qb-target']:AddTargetEntity(ShopPed[k], {
                options = {
                    {
                        num = 1,
                        type = "client",
                        event = "A-blackmarket:OpenShop",
                        label = v["targetLabel"],
                        job = v.requiredJob,
                        gang = v.requiredGang
                        icon = v["targetIcon"],
                    }
                },
                distance = 1.5
            })
        end
    end


    RequestModel(current)
    while not HasModelLoaded(current) do
        Wait(0)
    end

    pedSpawned = true
end

local function deletePeds()
    if not pedSpawned then return end

    for _, v in pairs(ShopPed) do
        DeletePed(v)
    end
    pedSpawned = false
end

RegisterNetEvent('A-blackmarket:OpenShop', function()
    local BlackMarket = {
        {
            header = Config.Text['PedHeader'],
            isMenuHeader = true,
            icon = Config.Icons["Header"]
        },
        {
            header = Config.Text['Pistols'],
            icon = Config.Icons['Pistol'],
            params = {
                event = "A-blackmarket:PistolShop",
            }
        },
        {
            header = Config.Text['SubMachineGuns'],
            icon = Config.Icons['SubMachineGuns'],
            params = {
                event = "A-blackmarket:SubMachineGunsShop",
            }
        },
        {
            header = Config.Text['Shotguns'],
            icon = Config.Icons['Shotguns'],
            params = {
                event = "A-blackmarket:ShotGunsShop",
            }
        },
        {
            header = Config.Text['AssaultWeapons'],
            icon = Config.Icons['AssaultWeapons'],
            params = {
                event = "A-blackmarket:AssaultWeaponsShop",
            }
        },
        {
            header = Config.Text['Miscellanceous'],
            icon = Config.Icons['Miscellanceous'],
            params = {
                event = "A-blackmarket:MiscellanceousShop",
            }
        },
    }
    exports['qb-menu']:openMenu(BlackMarket)
end)

-- Events
RegisterNetEvent("A-blackmarket:client:UpdateShop", function(shop, itemData, amount)
    TriggerServerEvent("A-blackmarket:server:UpdateShopItems", shop, itemData, amount)
end)

RegisterNetEvent("A-blackmarket:client:SetShopItems", function(shop, shopProducts)
    Config.Locations[shop]["products"] = shopProducts
end)

RegisterNetEvent("A-blackmarket:client:RestockShopItems", function(shop, amount)
    if not Config.Locations[shop].products then return end
    for k in pairs(Config.Locations[shop].products) do
        Config.Locations[shop].products[k].amount = Config.Locations[shop]["products"][k].amount + amount
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    createBlips()
    createPeds()
    TriggerServerEvent('A-blackmarket:server:SetShopList')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    deletePeds()
    PlayerData = nil
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    createBlips()
    createPeds()
    TriggerServerEvent('A-blackmarket:server:SetShopList')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    deletePeds()
end)

-- Threads
if not Config.UseTarget then
    CreateThread(function()
        for shop in pairs(Config.Locations) do
            NewZones[#NewZones+1] = CircleZone:Create(vector3(Config.Locations[shop]["coords"]["x"], Config.Locations[shop]["coords"]["y"], Config.Locations[shop]["coords"]["z"]), Config.Locations[shop]["radius"], {
                useZ = true,
                debugPoly = false,
                name = shop,
            })
        end

        local combo = ComboZone:Create(NewZones, {name = "RandomZOneName", debugPoly = false})
        combo:onPlayerInOut(function(isPointInside, _, zone)
            if isPointInside then
                currentShop = zone.name
                TriggerServerEvent('A-blackmarket:server:SetShopList')
                currentData = Config.Locations[zone.name]
                exports["qb-core"]:DrawText(Lang:t("info.open_shop"))
                listenForControl()
            else
                exports["qb-core"]:HideText()
                listen = false
            end
        end)

    end)
end

CreateThread(function()
    for k1, v in pairs(Config.Locations) do
        if v.requiredJob and next(v.requiredJob) then
            for k in pairs(v.requiredJob) do
                Config.Locations[k1].requiredJob[k] = 0
            end
        end
        if v.requiredGang and next(v.requiredGang) then
            for k in pairs(v.requiredGang) do
                Config.Locations[k1].requiredGang[k] = 0
            end
        end
    end
end)
