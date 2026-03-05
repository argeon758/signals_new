AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

util.AddNetworkString("KGU_Chat_Trigger")

function ENT:WriteTable(table)
    table.kgu_link      = self:GetKGUSignalLink()
    table.kgu_lense     = self:GetKGULense()
end

function ENT:ReadTable(table)
    local link      = table.kgu_link or self.SignalLink
    local lense     = table.kgu_lense or self.Lense
    
    self:SetKGUSignalLink(link)
    self:SetKGULense(lense)
end

local THINK_RATE = 0.1
function Metrostroi.ForceKGUState(link, state)
    local found = false
    for _, ent in pairs(ents.FindByClass("gmod_track_kgu_msa")) do
        if ent:GetKGUSignalLink() == link then
            ent:SetState(state, true)
            found = true
        end
    end
    return found
end
function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    self:SetCollisionBounds(Vector(-10,-10,0), Vector(10,10,10))
    if self.SignalLink and self.SignalLink ~= "" then
        self:SetKGUSignalLink(self.SignalLink)
    end
    self:SetKGULense(self.Lense)

    self.Triggered = false
    self:SetKGUState(false)
    
    self:NextThink(CurTime() + THINK_RATE)
    if self.Lense then
        self:SetKGULense(tostring(self.Lense))
    end
end
function ENT:WriteTable(table)
    table.kgu_link      = self:GetKGUSignalLink()
    table.kgu_lense     = self:GetKGULense()
end
function ENT:ReadTable(table)
    local link      = table.kgu_link or self.SignalLink
    local lense     = table.kgu_lense or self.Lense
    
    self:SetKGUSignalLink(link)
    self:SetKGULense(tostring(lense))
end
function ENT:SetState(state, suppress_chat) 
    if self.Triggered == state then return end 

    self.Triggered = state
    self:SetKGUState(state)
    local sig_link = self:GetKGUSignalLink()
    local target_lense = self:GetKGULense()
    local signal_ent = Metrostroi.GetSignalByName(sig_link)
    self:NotifyClients(state)

    if not state then
        if IsValid(signal_ent) and signal_ent.SetKGUOverride then
            signal_ent:SetKGUOverride(false)
        end
    else
        if IsValid(signal_ent) then
            if signal_ent.SetKGUOverride then
                signal_ent:SetKGUOverride(true, target_lense)
            end
        end
    end
end

function ENT:CheckRaycast()
    local height = 8  --смещение центра вверх
    local side = -32 --смещение центра вправо
    local startPos = self:GetPos() + (self:GetRight() * side) + (self:GetUp() * height)
    local length = 64 --длина влево
    local endPos = startPos + self:GetRight() * length

    local trace = util.TraceLine({
        start = startPos,
        endpos = endPos,
        filter = self,
        mask = MASK_ALL 
    })

    local lineContextColor = trace.Hit and Color(0, 0, 255) or Color(0, 255, 0)
    debugoverlay.Line(startPos, trace.HitPos, 1, lineContextColor, true)
    
    if trace.Hit then
        debugoverlay.Cross(trace.HitPos, 2, 0.1, Color(255, 255, 0), true)
    end

    if IsValid(trace.Entity) then
        if not trace.Entity:IsPlayer() then
            if not self.Triggered then
                self:SetState(true)
            end
        end
    end
end


function ENT:Think()
    if not self.Triggered then
        self:CheckRaycast()
    end
    
    self:NextThink(CurTime() + THINK_RATE)
    return true
end

function ENT:NotifyClients(is_triggered)
    local link = self:GetKGUSignalLink()
    if link == "" or link == " " then return end
    
    net.Start("KGU_Chat_Trigger")
    net.WriteString(link)
    net.WriteBool(is_triggered)
    net.Broadcast()
end

local function ForceState(link, state)
    local found = false
    for _, ent in pairs(ents.FindByClass("gmod_track_kgu_msa")) do
        if ent:GetKGUSignalLink() == link then
            ent:SetState(state, true)
            found = true
        end
    end
    return found
end 