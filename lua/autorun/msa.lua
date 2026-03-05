

--thefuldeep_autorun_init.lua
local function InitAutorun(path, param)
    --if not file.Exists(string.sub(path,1,-2),"LUA") then return end
    local files, directories = file.Find(path.."*", "LUA")
    if files then
        if SERVER then
            for k, v in pairs(files) do
                local content = file.Read(path..v, "LUA")
                if not content:find("%a") then
                    files[k] = nil
                    MsgC(Color(255, 0, 0), "File "..path..v.." is empty. It will not be included.\n")
                end
            end
            if param == "sh" or param == "sv" then
                for k, v in pairs(files) do
                    MsgC(Color(0, 255, 0), "including "..path..v.." by TheFulDeep's autorun\n")
                    include(path..v)
                end
            end
            if param == "sh" or param == "cl" then
                for k, v in pairs(files) do
                    AddCSLuaFile(path..v)
                    MsgC(Color(255, 255, 0), "added "..path..v.." to download to clients by TheFulDeep's autorun\n")
                end
            end
        end
        
        if CLIENT and (param == "sh" or param == "cl") then
            for k, v in pairs(files) do
                include(path..v)
                MsgC(Color(0, 255, 0), "included "..path..v.." by TheFulDeep's autorun\n")
            end
        end
    end
    
    if directories then 
        for k, v in pairs(directories) do
            InitAutorun(path..v.."/", param)
        end
    end
end

print("TheFulDeep's autorun initializing")
if SERVER then return end

THEFULDEEP = THEFULDEEP or {}
local THEFULDEEP = THEFULDEEP

local FPSLimit = 20
local TimeLimit = 15
local LagsStarted
hook.Add("Think", "RecomendHideTrains", function()
    if not system.HasFocus() then return end
    local fps = 1 / RealFrameTime()
    if fps < FPSLimit then
        local currentTime = CurTime()
        if not LagsStarted then LagsStarted = currentTime end
        
        if currentTime - LagsStarted > TimeLimit then
            hook.Remove("Think", "RecomendHideTrains")
            chat.AddText(
                Color(255, 0, 0), "Low performance has been detected. To increase the framerate try these console commands ", 
                Color(255, 255, 0), "multi_thread_rendering_enabled 1", 
                Color(255, 0, 0), ", ", 
                Color(255, 255, 0), "hideothertrains 1", 
                Color(255, 0, 0), ", ", 
                Color(255, 255, 0), "hidealltrains 1", 
                Color(255, 0, 0), " or ", 
                Color(255, 255, 0), "gmod_mcore_test 1", 
                Color(255, 0, 0), ". Also make sure that screenshot mode is off (", 
                Color(255, 255, 0), "metrostroi_screenshotmode 0", 
                Color(255, 0, 0), ")!"
            )
        end
    else
        LagsStarted = nil
    end
end)


--поиск инициализированных значений
local C_ScreenshotMode
local DefaultShouldRenderClientEntsFunction

local hidealltrains = GetConVar("hidealltrains") or CreateClientConVar("hidealltrains", "0", true, false, "")
local hideothertrains = GetConVar("hideothertrains") or CreateClientConVar("hideothertrains", "0", true, false, "")
local hidetrains_behind_props = GetConVar("hidetrains_behind_props") or CreateClientConVar("hidetrains_behind_props", "1", true, false, "")
local hidetrains_behind_player = GetConVar("hidetrains_behind_player") or CreateClientConVar("hidetrains_behind_player", "1", true, false, "")

hook.Add("InitPostEntity", "Metrostroi hideothertrains", function()
    C_ScreenshotMode = GetConVar("metrostroi_screenshotmode") -- прогружаю конвары здесь, чтобы случайно не прогрузить Nil
    
    if not THEFULDEEP.RealViewPos then
        hook.Add("PreDrawEffects", "GetRealEyePos", function()
            THEFULDEEP.RealViewPos = EyePos()
        end)
        --PostDrawEffects
    end
    
    local base = scripted_ents.Get("gmod_subway_base")
    DefaultShouldRenderClientEntsFunction = base.ShouldRenderClientEnts
end)

local PlyInTrain
local PlyInSeat
timer.Create("PlyInTrainForHideCheck", 1, 0, function()
    local ply = LocalPlayer()
    if IsValid(ply) and ply:InVehicle() then
        PlyInSeat = ply:GetVehicle()
        if not IsValid(PlyInSeat) then
            PlyInSeat = nil
        end
        PlyInTrain = IsValid(PlyInSeat) and PlyInSeat:GetNW2Entity("TrainEntity", nil) or nil
        if not IsValid(PlyInTrain) then
            PlyInTrain = nil
        end
    else
        PlyInSeat = nil
        PlyInTrain = nil
    end
end)

local tracelinesetup = {
    mask = MASK_VISIBLE_AND_NPCS, --MASK_BLOCKLOS_AND_NPCS
    output = {},
    filter = function(ent)
        if ent == LocalPlayer() or ent == PlyInSeat or ent == PlyInTrain or (IsValid(ent) and PlyInTrain and PlyInTrain == ent:GetNW2Entity("TrainEntity")) then
            return false
        end
        return true
    end
}

local function SaveOBBMaxs(ent)
    local val = ent:OBBMaxs()
    ent.WagonSize = val
    --print("saving max size")
    return val
end

local function SaveOBBMins(ent)
    local val = ent:OBBMins()
    ent.WagonSize2 = val
    --print("saving min size")
    return val
end

-- Ensure vector_origin is defined
local vector_origin = Vector(0, 0, 0)

-- вершины
local angles = {
    Vector(1, 1, 1),
    Vector(1, -1, 1),
    Vector(1, -1, -1),
    Vector(1, 1, -1),
    
    Vector(-1, 1, 1),
    Vector(-1, -1, 1),
    Vector(-1, -1, -1),
    Vector(-1, 1, -1),
    
    vector_origin
}

-- ребра
local lines = {
    {angles[1], angles[2]},
    {angles[2], angles[3]},
    {angles[3], angles[4]},
    {angles[4], angles[1]},
    
    {angles[5], angles[6]},
    {angles[6], angles[7]},
    {angles[7], angles[8]},
    {angles[8], angles[5]},
    
    {angles[1], angles[5]},
    {angles[2], angles[6]},
    {angles[3], angles[7]},
    {angles[4], angles[8]},
}

local mindist = (256 + 16)^2
local utilTraceLine = util.TraceLine

local function ShouldRenderEnts(self)
    -- Всегда прогружать, если режим съемки
    if C_ScreenshotMode and C_ScreenshotMode:GetBool() then
        self.ShouldRenderClientEntsRes = true
        return
    end
    
    -- Метростроевские проверки
    if DefaultShouldRenderClientEntsFunction and not DefaultShouldRenderClientEntsFunction(self) then
        self.ShouldRenderClientEntsRes = false
        return
    end

    -- Если игрок сидит в составе, то всегда прогружать его
    if PlyInTrain == self then
        self.ShouldRenderClientEntsRes = true
        return
    end
    
    -- Проверка, находится ли состав за пропом и находится ли игрок рядом с диагоналями
    local StartPos = THEFULDEEP.RealViewPos or Vector(0)
    tracelinesetup.start = StartPos
    local TrainSize = self.WagonSize or SaveOBBMaxs(self)
    local hidetrains_behind_props_bool = hidetrains_behind_props:GetBool()
    local ShouldRender = false
    
    -- Прохожу 8 вершин и центр
    for _, point in pairs(angles) do
        local curvec = self:LocalToWorld(point * TrainSize)
        if StartPos:DistToSqr(curvec) < mindist then
            self.ShouldRenderClientEntsRes = true
            return
        end
        
        -- Если надо проверять, за пропами ли вагон
        if hidetrains_behind_props_bool then
            tracelinesetup.endpos = curvec
            local output = utilTraceLine(tracelinesetup)
            -- Если состав не за пропом, то однозначно прогрузить
            if output.Fraction == 1 or output.Entity == self or (IsValid(output.Entity) and output.Entity:GetNW2Entity("TrainEntity") == self) then
                ShouldRender = true
                break
            end
        end
    end
    
    -- Не прогружать, когда не вызывается Draw функция
    if hidetrains_behind_player:GetBool() and self.LastDrawCall and CurTime() - self.LastDrawCall > 1 then
        self.ShouldRenderClientEntsRes = false
        return
    end

    -- Если надо скрыть все составы
    if hidealltrains:GetBool() then
        self.ShouldRenderClientEntsRes = false
        return
    end

    -- Если надо скрыть все чужие составы
    if hideothertrains:GetBool() then
        local Owner = CPPI and self:CPPIGetOwner() or nil
        if Owner ~= LocalPlayer() then
            self.ShouldRenderClientEntsRes = false
            return
        end
    end
    
    -- Если надо скрыть за пропами
    if hidetrains_behind_props_bool then
        self.ShouldRenderClientEntsRes = ShouldRender
        return
    end
    
    self.ShouldRenderClientEntsRes = true
end

local function ChangeDrawFunctions(ent)
    local Draw = ent.Draw
    ent.Draw = function(self, ...)
        self.LastDrawCall = CurTime()
        Draw(self, ...)
    end
    ent.ShouldRenderClientEntsRes = false
    ent.ShouldRenderClientEnts = function(self)
        return self.ShouldRenderClientEntsRes
    end
end

local entsFindByClass = ents.FindByClass
timer.Create("Update ShouldRenderClientEntsRes variable", 0.5, 0, function()
    for _, ent in pairs(entsFindByClass("gmod_subway_*")) do
        if IsValid(ent) then
            ShouldRenderEnts(ent)
        end
    end
end)

Metrostroi = Metrostroi or {}
Metrostroi.ShouldHideTrain = ShouldRenderEnts

hook.Add("OnEntityCreated", "UpdateTrainsDrawFunction", function(ent)
    timer.Simple(2, function()
        if not IsValid(ent) or ent.Base ~= "gmod_subway_base" or not Metrostroi.TrainClasses or not table.HasValue(Metrostroi.TrainClasses, ent:GetClass()) or not ent.Draw or not ent.ShouldRenderClientEnts then
            return
        end
        print("changing drawing ClientEnts function on " .. tostring(ent))
        ChangeDrawFunctions(ent)
    end)
end)



if SERVER then return end

local multithread_enabled = CreateClientConVar("multi_thread_rendering_enabled", "1", true, false, "", 0, 1)
local dont_touch_multithread = CreateClientConVar("dont_touch_multi_thread_rendering", "1", true, false, "", 0, 1)

local disabling
local function Enable()
    if dont_touch_multithread:GetBool() then return end
    if disabling then
        timer.Create("enable multithread rendering", 1, 0, function()
            if disabling then 
                return
            else
                if multithread_enabled:GetBool() then Enable() end
                timer.Remove("enable multithread rendering")
            end
        end)
        --chat.AddText("Происходит отключение многопотока, подожди несколько секунд.")
        return
    end
    RunConsoleCommand("cl_threaded_client_leaf_system", "1")
    RunConsoleCommand("mat_queue_mode", "-1")
    RunConsoleCommand("cl_threaded_bone_setup", "1")
    RunConsoleCommand("gmod_mcore_test", "1")
    RunConsoleCommand("r_threaded_renderables", "1")
    RunConsoleCommand("r_threaded_particles", "1")
    RunConsoleCommand("r_queued_ropes", "1")
    RunConsoleCommand("studio_queue_mode", "1")
    RunConsoleCommand("r_threaded_client_shadow_manager", "1")
    chat.AddText("Многопоточный рендеринг включен.")
end

local function Disable()
    if dont_touch_multithread:GetBool() then return end
    if disabling then return end
    disabling = true

    local commands = {
        "cl_threaded_client_leaf_system 0",
        "mat_queue_mode 0",
        "cl_threaded_bone_setup 0",
        "gmod_mcore_test 0",
        "r_threaded_renderables 0",
        "r_threaded_particles 0",
        "r_queued_ropes 0",
        "studio_queue_mode 0",
        "r_threaded_client_shadow_manager 0"
    }

    for i, cmd in ipairs(commands) do
        timer.Simple(i * 0.5, function()
            RunConsoleCommand(unpack(string.Split(cmd, " ")))
            if i == #commands then
                chat.AddText("Многопоточный рендеринг выключен.")
                disabling = false
            end
        end)
    end
end

local function EnableOrDisable()
    if multithread_enabled:GetBool() then Enable() else Disable() end
end

cvars.AddChangeCallback("multi_thread_rendering_enabled", EnableOrDisable)
cvars.AddChangeCallback("dont_touch_multi_thread_rendering", EnableOrDisable)

timer.Simple(0, EnableOrDisable)

cvars.AddChangeCallback("multi_thread_rendering_enabled", EnableOrDisable)
cvars.AddChangeCallback("dont_touch_multi_thread_rendering", EnableOrDisable)

timer.Simple(0, EnableOrDisable)

if not GetConVar("hideothertrains") then
    CreateClientConVar("hideothertrains", "0", true, false, "", 0, 1)
end

if not GetConVar("hidealltrains") then
    CreateClientConVar("hidealltrains", "0", true, false, "", 0, 1)
end

if not GetConVar("hidetrains_behind_props") then
    CreateClientConVar("hidetrains_behind_props", "1", true, false, "", 0, 1)
end

if not GetConVar("hidetrains_behind_player") then
    CreateClientConVar("hidetrains_behind_player", "1", true, false, "", 0, 1)
end

if not GetConVar("draw_signal_routes") then
    CreateClientConVar("draw_signal_routes", "1", true, false, "", 0, 1)
end

if not GetConVar("msa_signal_dist") then
    CreateClientConVar("msa_signal_dist", 4096, true)
end

local langtbl = {
    ["en"] = {
        ["ScreenHotMod"] = {"Screenshot mode"},
        ["HideAllTrains"] = {"Do not load all trains"},
        ["HideOtherTrains"] = {"Do not load other trains"},
        ["HideTrainsPlayer"] = {"Do not load trains behind"},
        ["HideTrainsProps"] = {"Do not load trains behind props"},
        ["DrawSignalRoutes"] = {"Show signal commands"},
        ["MultiRendering"] = {"Enable multithread rendering"},
        ["DontMultiRendering"] = {"Do not touch multithread rendering"},
        ["SignalDist"] = {"Lens light render distance"}
    },
    ["ru"] = {
        ["ScreenHotMod"] = {"Режим съёмки"},
        ["HideAllTrains"] = {"Не прогружать все составы"},
        ["HideOtherTrains"] = {"Не прогружать чужие составы"},
        ["HideTrainsPlayer"] = {"Не прогружать составы за спиной"},
        ["HideTrainsProps"] = {"Не прогружать составы за пропами"},
        ["DrawSignalRoutes"] = {"Отображать команды светофоров"},
        ["MultiRendering"] = {"Вкл. многопоточный рендеринг"},
        ["DontMultiRendering"] = {"Не трогать многопоточный рендеринг"},
        ["SignalDist"] = {"Рендер света линз"}
    }
}


local function Optimization(panel)
    local player = LocalPlayer()
    local lang = "en"
    if player then
        lang = player:GetInfo("metrostroi_language") == "ru" and "ru" or "en"
    end
    local ltbl = langtbl[lang]
    panel:ClearControls()
    panel:CheckBox(ltbl["ScreenHotMod"][1], "metrostroi_screenshotmode")
    panel:CheckBox(ltbl["HideAllTrains"][1], "hidealltrains")
    panel:CheckBox(ltbl["HideOtherTrains"][1], "hideothertrains")
    panel:CheckBox(ltbl["HideTrainsPlayer"][1], "hidetrains_behind_player")
    panel:CheckBox(ltbl["HideTrainsProps"][1], "hidetrains_behind_props")
    panel:CheckBox(ltbl["DrawSignalRoutes"][1], "draw_signal_routes")
    panel:CheckBox(ltbl["MultiRendering"][1], "multi_thread_rendering_enabled")
    panel:CheckBox(ltbl["DontMultiRendering"][1], "dont_touch_multi_thread_rendering")
    panel:NumSlider(ltbl["SignalDist"][1], "msa_signal_dist", 0, 10240)
end
hook.Add("PopulateToolMenu", "MetrostroiCustomPanel", function()
    spawnmenu.AddToolMenuOption("Utilities", "Metrostroi", "metrostroi_optimization", "Optimization", "", "", Optimization)
end)