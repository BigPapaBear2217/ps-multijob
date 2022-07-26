local QBCore = exports['qb-core']:GetCoreObject()

local function GetJobs()
    local p = promise.new()
    QBCore.Functions.TriggerCallback('ps-multijob:getJobs', function(result)
        p:resolve(result)
    end)
    return Citizen.Await(p)
end

local function OpenUI()
    local job = QBCore.Functions.GetPlayerData().job
    local jobs = GetJobs()
    local menuData = {
        {
            header = "My Jobs",
            isMenuHeader = true,
        },
    }
    for k,v in pairs(jobs) do 
        local selected = false
        if v["name"] == job["name"] then selected = true end
        menuData[#menuData+1] = {
            id = #menuData,
            header = v["label"],
            txt = ("Grade: %s | Salary: $%s | Selected: %s | Active: %s"):format(v["grade_label"], v["salary"], selected, v["active"]),
            params = {
                event = "ps-multijob:selectJob",
                args = {
                    job = v["name"],
                    grade = v["grade"],
                    label = ("%s %s"):format(v["label"], v["grade_label"]),
                }
            }
        }
    end
    exports['qb-menu']:openMenu(menuData)
end

RegisterNetEvent("ps-multijob:selectJob", function(data)
    local job = QBCore.Functions.GetPlayerData().job
    if data["job"] == job["name"] then return end
    exports['qb-menu']:openMenu({
        {
            header = data["label"],
            isMenuHeader = true,
        },
        {
            id = 1,
            header = "Select",
            txt = "",
            params = {
                isAction = true,
                event = function()
                    TriggerServerEvent("ps-multijob:changeJob", data["job"], data["grade"])
                end,
                args = {
                    job = data["job"],
                    grade = data["grade"]
                }
            }
        },
        {
            id = 2,
            header = "Remove",
            txt = "",
            params = {
                isAction = true,
                event = function()
                    TriggerServerEvent("ps-multijob:removeJob", data["job"], data["grade"])
                end,
                args = {
                    job = data["job"],
                    grade = data["grade"]
                }
            }
        }
    })
end)

-- Command Code
RegisterCommand("jobmenu", OpenUI)
RegisterKeyMapping('jobmenu', "Show Job Management", "keyboard", "l")
TriggerEvent('chat:removeSuggestion', '/jobmenu')

TriggerEvent('chat:addSuggestion', '/removejob', 'Community Service (Police Only)', {
    { name="ID", help="Player ID" },
    { name="Job", help="Job Name" },
    { name="Grade", help="Job Grade" },
})
TriggerEvent('chat:addSuggestion', '/addjob', 'Community Service (Police Only)', {
    { name="ID", help="Player ID" },
    { name="Job", help="Job Name" },
    { name="Grade", help="Job Grade" },
})