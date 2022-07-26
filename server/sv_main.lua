local QBCore = exports['qb-core']:GetCoreObject()

local function AddJob(citizenid, job, grade)
    MySQL.Sync.execute("INSERT INTO `multijobs`(`citizenid`, `job`, `grade`) VALUES (@citizenid, @job, @grade)",{
        ["@citizenid"] = citizenid, 
        ["@job"] = job, 
        ["@grade"] = grade
    })
end

local function RemoveJob(citizenid, job, grade)
    MySQL.Sync.execute("DELETE FROM `multijobs` WHERE citizenid = @citizenid AND job = @job AND grade = @grade",{
        ["@citizenid"] = citizenid,
        ["@job"] = job, 
        ["@grade"] = grade
    })
end

local function GetJobs(citizenid)
    local p = promise.new()
    MySQL.Async.fetchAll("SELECT * FROM multijobs WHERE citizenid = @citizenid",{
        ["@citizenid"] = citizenid
    }, function(jobs)
        p:resolve(jobs)
    end)
    return Citizen.Await(p)
end

QBCore.Commands.Add('removejob', 'Remove Multi Job (Admin Only)', { { name = 'id', help = 'ID of player' }, { name = 'job', help = 'Job Name' }, { name = 'grade', help = 'Job Grade' } }, false, function(source, args)
    local source = source
    if source ~= 0 then
        if args[1] then
            local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
            if Player then
                if args[2]and args[3] then
                    RemoveJob(Player.PlayerData.citizenid, args[2], args[3])
                else
                    TriggerClientEvent("QBCore:Notify", source, "Wrong usage!")
                end
            else
                TriggerClientEvent("QBCore:Notify", source, "Wrong usage!")
            end
        else
            TriggerClientEvent("QBCore:Notify", source, "Wrong usage!")
        end
    else
        TriggerClientEvent("QBCore:Notify", source, "Wrong usage!")
    end
end, 'admin')

QBCore.Commands.Add('addjob', 'Add Multi Job (Admin Only)', { { name = 'id', help = 'ID of player' }, { name = 'job', help = 'Job Name' }, { name = 'grade', help = 'Job Grade' } }, false, function(source, args)
    local source = source
    if source ~= 0 then
        if args[1] then
            local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
            if Player then
                if args[2]and args[3] then
                    AddJob(Player.PlayerData.citizenid, args[2], args[3])
                else
                    TriggerClientEvent("QBCore:Notify", source, "Wrong usage!")
                end
            else
                TriggerClientEvent("QBCore:Notify", source, "Wrong usage!")
            end
        else
            TriggerClientEvent("QBCore:Notify", source, "Wrong usage!")
        end
    else
        TriggerClientEvent("QBCore:Notify", source, "Wrong usage!")
    end
end, 'admin')

QBCore.Functions.CreateCallback("ps-multijob:getJobs",function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    local jobs = GetJobs(Player.PlayerData.citizenid)
    print(jobs)
    local multijobs = {}
    local active = {}
    local Players = QBCore.Functions.GetPlayers()
    for i = 1, #Players, 1 do
        local Player = QBCore.Functions.GetPlayer(Players[i])
        if active[Player.PlayerData.job.name] ~= nil then
            active[Player.PlayerData.job.name] = active[Player.PlayerData.job.name] + 1
        else
            active[Player.PlayerData.job.name] = 1
        end
    end
    for k, v in pairs(jobs) do
        local online = active[v.job]
        if online == nil then
            online = 0
        end
        multijobs[#multijobs+1] = {
            name = v.job,
            grade = v.grade,
            label = QBCore.Shared.Jobs[v.job].label,
            grade_label = QBCore.Shared.Jobs[v.job].grades[tostring(v.grade)].name,
            salary = QBCore.Shared.Jobs[v.job].grades[tostring(v.grade)].payment,
            active = online
        }
    end
    cb(multijobs)
end)

RegisterNetEvent("ps-multijob:changeJob",function(job, grade)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    local jobs = GetJobs(Player.PlayerData.citizenid)
    print(jobs)
    for k, v in pairs(jobs) do
        print(k,v)
        if job == v.job and grade == v.grade then
            Player.Functions.SetJob(job, grade)
        end
    end
end)

RegisterNetEvent("ps-multijob:removeJob",function(job, grade)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    RemoveJob(Player.PlayerData.citizenid, job, grade)
end)

-- QBCORE EVENTS

RegisterNetEvent("qb-bossmenu:server:FireEmployee", function(target)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player.PlayerData.job.isboss then return end
    local Employee = QBCore.Functions.GetPlayerByCitizenId(target)
    if target ~= Player.PlayerData.citizenid then
        RemoveJob(target, Employee.PlayerData.job.name, Employee.PlayerData.job.grade.level)
    end
end)

RegisterNetEvent('QBCore:Server:OnJobUpdate', function(source, newJob)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    MySQL.Async.fetchAll("SELECT * FROM multijobs WHERE citizenid = @citizenid",{
        ["@citizenid"] = Player.PlayerData.citizenid
    },function(jobs)
        local add = true
        local amount = 0
        local job = newJob
        for _, v in pairs(jobs) do
            if job.name == v.job then
                add = false
            end
            amount = amount + 1
        end
        if add and amount < Config.MaxJobs and Config.IgnoredJobs[job] then
            AddJob(Player.PlayerData.citizenid, job.name, job.grade.level)
        end
    end)
end)