include("shared.lua")
function ENT:Initialize()
    self.AnimationOn = self:GetNetworkedBool("KGUState", false) 
    self:SetAnimation(self.AnimationOn)
    self.PhysgunDisabled = true
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false) -- Замораживает объект в воздухе
    end
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:OnNetworkDataChanged(key, value)
    if key == "KGUState" then 
        self:SetAnimation(value)
    end
end

function ENT:SetAnimation(state)
    if state == self.AnimationOn then return end
    self.AnimationOn = state

    local sequenceName = state and "activate" or "idle"
    local seqID = self.KGU_Model:LookupSequence(sequenceName)
    
    if seqID == -1 then 
        self.KGU_Model:SetPoseParameter("hit_state", state and 1 or 0)
        return 
    end

    self.KGU_Model:SetSequence(seqID)
    self.KGU_Model:SetPlaybackRate(1)
    self.KGU_Model:SetCycle(0)
end

function ENT:Think()
    self:NextThink(CurTime())
    return true
end

net.Receive("KGU_Chat_Trigger", function()
    local lang = GetConVar("metrostroi_language"):GetString() == "en" and "en" or (GetConVar("metrostroi_language"):GetString() == "ru" and "ru" or "en")
    local files = {"msa_debug"}
    for _, suffix in ipairs(files) do
        local path = string.format("metrostroi_data/languages/%s_%s.lua", lang, suffix)
        include(path)
    end
    local link = net.ReadString()
    local state = net.ReadBool()

    local actionText_1 = state and Debug_KGU_Active_1 or Debug_KGU_DeActive_1
    local actionText_2 = state and Debug_KGU_Active_2 or Debug_KGU_DeActive_2
    local col = state and Color(255, 0, 0) or Color(0, 255, 0)
    
    chat.AddText(
        Color(0, 0, 255), "[MSA] ", 
        col, actionText_1, 
        col, link,
        col, actionText_2
    )
end)