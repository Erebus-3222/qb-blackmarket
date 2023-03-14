Config = {}
Config.UseTruckerJob = false -- true = The shops stock is based on when truckers refill it | false = shop inventory never runs out
Config.UseTarget = GetConvar('UseTarget', 'false') == 'false' -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)
-- Config.FirearmsLicenseCheck = true -- Whether a arms dealer checks for a firearms license
Config.ShopsInvJsonFile = './json/shops-inventory.json' -- json file location

Config.Products = {
    ["blackmarket"] = {
        [1] = {
            name = "weapon_knuckle",
            price = 250,
            amount = 100,
            info = {},
            type = "item",
            slot = 1,
        },
        [2] = {
            name = "weapon_assaultrifle",
            price = 250,
            amount = 100,
            info = {},
            type = "item",
            slot = 2,
        },
        [3] = {
            name = "lockpick",
            price = 250,
            amount = 100,
            info = {},
            type = "item",
            slot = 3,
        },  
    },

 ------------------- Skater park shop ----------------   

   
        ["blackmarket"] = {
            ["label"] = "Black Market",
            ["coords"] = vector4(4885.24, -4926.02, 3.35, 12.55),
            ["ped"] = 'cs_fbisuit_01',
            ["scenario"] = "WORLD_HUMAN_GUARD_STAND",
            ["radius"] = 2.5,
            ["targetIcon"] = "fas fa-gun",
            ["targetLabel"] = "Open Shop",
            ["products"] = Config.Products["blackmarket"],
            ["showblip"] = false,
            ["blipsprite"] = 120,
            ["blipscale"] = 0.8,
            ["blipcolor"] = 11,
        },
}
