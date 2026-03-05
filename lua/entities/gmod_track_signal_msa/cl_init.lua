if checkMSAblacklist() then return end
include("shared.lua")
include("cl_font.lua")
--------------------------------------------------------------------------------
local C_MSARenderDistance      = GetConVar("msa_signal_dist")


function ENT:Initialize()
    self.Sig = ""
    self.OldName = ""
    self.Models = {{},{},{},{}}
    self.Signals = {}
    self.Anims = {}
    self.PixVisibleHandlers = {}
	self.Sprites = {}
	self.Lights = {}
	self.PTs = {}
    self.NumLit = {}
end

--ДЛЯ АВТОСТОПОВ
function ENT:Animate(clientProp, value, min, max, speed, damping, stickyness)
    local id = clientProp
    if not self.Anims[id] then
        self.Anims[id] = {}
        self.Anims[id].val = value
        self.Anims[id].V = 0.0
    end

    if damping == false then
        local dX = speed * self.DeltaTime
        if value > self.Anims[id].val then
            self.Anims[id].val = self.Anims[id].val + dX
        end
        if value < self.Anims[id].val then
            self.Anims[id].val = self.Anims[id].val - dX
        end
        if math.abs(value - self.Anims[id].val) < dX then
            self.Anims[id].val = value
        end
    else
        -- Prepare speed limiting
        local delta = math.abs(value - self.Anims[id].val)
        local max_speed = 1.5*delta / self.DeltaTime
        local max_accel = 0.5 / self.DeltaTime

        -- Simulate
        local dX2dT = (speed or 128)*(value - self.Anims[id].val) - self.Anims[id].V * (damping or 8.0)
        if dX2dT >  max_accel then dX2dT =  max_accel end
        if dX2dT < -max_accel then dX2dT = -max_accel end

        self.Anims[id].V = self.Anims[id].V + dX2dT * self.DeltaTime
        if self.Anims[id].V >  max_speed then self.Anims[id].V =  max_speed end
        if self.Anims[id].V < -max_speed then self.Anims[id].V = -max_speed end

        self.Anims[id].val = math.max(0,math.min(1,self.Anims[id].val + self.Anims[id].V * self.DeltaTime))

        -- Check if value got stuck
        if (math.abs(dX2dT) < 0.001) and stickyness and (self.DeltaTime > 0) then
            self.Anims[id].stuck = true
        end
    end
    return min + (max-min)*self.Anims[id].val
end
--------------------------
-- MAIN SPAWN FUNCTIONS --
--------------------------

function ENT:SpawnBoxNumbers(i,model,pos,letter,angle)
	angle = angle or Angle(0, 0, 0)
    local model_tbl = self.Models[4] 
    if not IsValid(model_tbl[i]) then
        local client_model = ClientsideModel(model, RENDERGROUP_OPAQUE)
        model_tbl[i] = client_model
        client_model:SetAngles(self:LocalToWorldAngles(Angle(0, 180, 0) + angle))
        client_model:SetPos(self:LocalToWorld(self.BasePosition + pos))
        client_model:SetParent(self)
        local new_material = "models/metrostroi/signals/let/" .. letter
        for k, v in ipairs(client_model:GetMaterials()) do
            if v:find("models/metrostroi/signals/let/let_start") then
                client_model:SetSubMaterial(k - 1, new_material)
            end
        end
    end
end

function ENT:SpawnMainModels(pos,ang,LenseNum,add)
    local TLM = self.TrafficLightModels[self.LightType]
    for k,v in pairs(TLM) do
        if type(v) == "string" and not k:find("long") then
            local idx = add and v..add or v
            if IsValid(self.Models[1][idx]) then break else
                local k_long = k.."_long"
                if TLM[k_long] and LenseNum > (self.LongThreshold[self.LightType] or 2) then
                    self.Models[1][idx] = ClientsideModel(TLM[k_long],RENDERGROUP_OPAQUE)
                    self.LongOffset = TLM[k.."_long_pos"]
                else
                    self.Models[1][idx] = ClientsideModel(v,RENDERGROUP_OPAQUE)
                end
                self.Models[1][idx]:SetPos(self:LocalToWorld(pos))
                self.Models[1][idx]:SetAngles(self:LocalToWorldAngles(ang))
                self.Models[1][idx]:SetParent(self)
            end
        end
    end
end

function ENT:SpawnHead(ID,head,pos,ang,isLeft,isLast,lenses)
    local TLM = table.Copy(self.TrafficLightModels[self.LightType])
    local model = (not TLM.noleft and isLeft) and TLM[head][2]:Replace(".mdl","_mirror.mdl") or TLM[head][2]
    local longKron = #self.RouteNumbers > 0 and (#self.RouteNumbers ~= 1 or not self.RouteNumbers.sep)
    local function GlassConventer(data, heads)
        for i = 1, #heads do
            if heads[i] == "X" then
                data[3].glass[i] = TLM.X_glasses[head][i]
            end
        end
        return data
    end
    if lenses and (head == 1 or head == 2 or head == 3) then glass = GlassConventer(TLM[head], lenses)[head][3] end

    if not IsValid(self.Models[1][ID]) then
        self.Models[1][ID] = ClientsideModel(model,RENDERGROUP_OPAQUE)
        self.Models[1][ID]:SetPos(self:LocalToWorld(pos))
        self.Models[1][ID]:SetAngles(self:LocalToWorldAngles(ang))
        self.Models[1][ID]:SetParent(self)
    end
    if self.RN and self.RN == self.RouteNumbers.sep then
        self.RN = self.RN + 1
    end
    local id = self.RN
    local rouid = id and "rou"..id
    if rouid and not IsValid(self.Models[1][rouid]) then
        local rnadd = ((self.RouteNumbers[id] and self.RouteNumbers[id][1] ~= "X") and (self.RouteNumbers[id][3] and not self.RouteNumbers[id][2] and 2 or 1) or 5)
        local LampIndicator = self.TrafficLightModels[self.LightType].LampIndicator
        if LampIndicator.models[rnadd] then
            self.Models[1][rouid] = ClientsideModel(LampIndicator.models[rnadd],RENDERGROUP_OPAQUE)
            self.Models[1][rouid]:SetPos(self:LocalToWorld(pos-self.RouteNumberOffset+(isLeft and LampIndicator[1] or LampIndicator[2])))
            self.Models[1][rouid]:SetAngles(self:GetAngles())
            self.Models[1][rouid]:SetParent(self)
        end
        if self.RouteNumbers[id] then self.RouteNumbers[id].pos = pos-self.RouteNumberOffset+(isLeft and LampIndicator[1] or LampIndicator[2]) end
        self.RN = self.RN + 1
    end
    for k,v in pairs(TLM[head][3]) do
        local ID_model = tostring(ID).."_"..k
        if type(k) ~= "string" then continue end
        for i,tbl in pairs(TLM[head][3][k]) do
            local ID_modeli = ID_model..i
            if IsValid(self.Models[1][ID_modeli]) then continue end
            if tbl.left and not isLeft then continue end
            if tbl.right and isLeft then continue end
            if tbl.long and not longKron then continue end
            if tbl.short and longKron then continue end
            if tbl.middle and isLast then continue end
            if tbl.last and not isLast then continue end
            self.Models[1][ID_modeli] = ClientsideModel(tbl[1],RENDERGROUP_OPAQUE)
            self.Models[1][ID_modeli]:SetPos(self:LocalToWorld(pos+tbl[2]*(isLeft and vector_mirror or 1)))
            self.Models[1][ID_modeli]:SetAngles(self:LocalToWorldAngles(ang))
            self.Models[1][ID_modeli]:SetParent(self)
            self.Models[1][ID_modeli]:SetModelScale(tbl[3] or 1)
        end
    end
end

function ENT:SetLight(ID,ID2,pos,ang,skin,State,Change)
    local TLM = self.TrafficLightModels[self.LightType]
    local IsStateAboveZero = State > 0
    local IDID2 = ID..ID2
    local IsModelValid = IsValid(self.Models[3][IDID2])
    if IsModelValid then
        if IsStateAboveZero then 
            if Change then 
                self.Models[3][IDID2]:SetColor(Color(255,255,255,State*255))
            end
        else
            self.Models[3][IDID2]:Remove()
        end
    elseif IsStateAboveZero then
        self.Models[3][IDID2] = ClientsideModel(self.TrafficLightModels[self.LightType].LampBase.model,RENDERGROUP_OPAQUE)
        self.Models[3][IDID2]:SetPos(self:LocalToWorld(pos))
        self.Models[3][IDID2]:SetAngles(self:LocalToWorldAngles(ang))
        self.Models[3][IDID2]:SetSkin(skin)
        self.Models[3][IDID2]:SetParent(self)
        self.Models[3][IDID2]:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self.Models[3][IDID2]:SetColor(Color(255,255,255,State*255))
        self.Models[3][IDID2]:SetModelScale(TLM.lense_scale or 1)
    end
	
	self.Sprites[IDID2] = {
        pos = self:LocalToWorld(pos+Metrostroi.SigSpriteOffset+(TLM.sprite_offset or vector_origin)), 
        bri = State, col = Metrostroi.Lenses[self.SpriteConverter[skin+1]], 
        mul = Metrostroi.SigTypeSpriteMul[self.LightType] * self.SpriteMultiplier[skin+1]
    }
	
	local distSqr = (EyePos() - self.Sprites[IDID2].pos):LengthSqr()
	local distZ = math.abs(EyePos().z - self.Sprites[IDID2].pos.z)

    local msasigdist = C_MSARenderDistance:GetFloat()
    if true and IsStateAboveZero and distZ < 256 and (distSqr < msasigdist*msasigdist) then
		if not IsValid(self.PTs[IDID2]) then self.PTs[IDID2] = ProjectedTexture() end
		if IsValid(self.PTs[IDID2]) then 
			self.PTs[IDID2]:SetEnableShadows( (distSqr < 1024*1024) and true or false )
			self.PTs[IDID2]:SetTexture( "effects/flashlight001" )
            self.Sprites[IDID2].col.a = 125
			self.PTs[IDID2]:SetColor( self.Sprites[IDID2].col )
			self.PTs[IDID2]:SetFarZ( 128 )
			self.PTs[IDID2]:SetFOV( 100 )
			self.PTs[IDID2]:SetPos( self.Sprites[IDID2].pos )
			self.PTs[IDID2]:SetBrightness( self.Sprites[IDID2].bri -0.9)
			local ptAng = self:LocalToWorldAngles(ang)
			ptAng:Add(Angle(0,90,0))
			self.PTs[IDID2]:SetAngles( ptAng )
			self.PTs[IDID2]:Update()
		end
	else
		if IsValid(self.PTs[IDID2]) then self.PTs[IDID2]:Remove() end
	end
end

function ENT:SpawnLetter(i,model,pos,letter,double)
    local LetMaterials = self.TrafficLightModels[self.LightType].LetMaterials.str
    local LetMaterialsStart = LetMaterials.."let_start"
    local LetMaterialsletter = LetMaterials..letter
    if double ~= false and not IsValid(self.Models[2][i]) and (self.Double or not self.Left) and (not letter:match("s[1-3]") or letter == "s3" or self.Double and self.Left) then
        self.Models[2][i] = ClientsideModel(model,RENDERGROUP_OPAQUE)
        self.Models[2][i]:SetAngles(self:LocalToWorldAngles(Angle(0,180,0)))
        self.Models[2][i]:SetPos(self:LocalToWorld(self.BasePos[self.LightType]+pos))
        self.Models[2][i]:SetParent(self)
        for k,v in pairs(self.Models[2][i]:GetMaterials()) do
            if v:find(LetMaterialsStart) then
                self.Models[2][i]:SetSubMaterial(k-1,LetMaterialsletter)
            end
        end
    end
    local id = i.."d"
    if not double and not IsValid(self.Models[2][id]) and (self.Double or self.Left) and (not letter:match("s[1-3]") or letter == "s3" or self.Double and not self.Left) then
        self.Models[2][id] = ClientsideModel(model,RENDERGROUP_OPAQUE)
        self.Models[2][id]:SetAngles(self:LocalToWorldAngles(Angle(0,180,0)))
        self.Models[2][id]:SetPos(self:LocalToWorld((self.BasePos[self.LightType]+pos)*vector_mirror))
        self.Models[2][id]:SetParent(self)
        for k,v in pairs(self.Models[2][id]:GetMaterials()) do
            if v:find(LetMaterialsStart) then
                self.Models[2][id]:SetSubMaterial(k-1,LetMaterialsletter)
            end
        end
    end
end

function ENT:OnRemove()
    self:RemoveModels()
	hook.Remove( "PostDrawTranslucentRenderables", self)
	self:RemovePTs()
end

function ENT:RemoveModels(final)
    if self.Models and  self.Models.have then
        for _,v in pairs(self.Models) do if type(v) == "table" then for _,v1 in pairs(v) do v1:Remove() end end end
    end
    self.NumLit = {}
    self.Models = {{},{},{},{}}
    self.ModelsCreated = false
end

function ENT:RemovePTs()
	if not self.PTs then return end
    for k,v in pairs(self.PTs) do
        if IsValid(v) then v:Remove() end
    end
end

net.Receive("metrostroi-signal", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    ent.LightType = net.ReadInt(4)
    ent.Name = net.ReadString()
    --ent.Name = " BUDAPEiT"..string.gsub(ent.Name,"[A-Za-z]*","")
    ent.Lenses = net.ReadString()
    ent.ARSOnly = ent.Lenses == "ARSOnly"
    ent.RouteNumberSetup = net.ReadString()
    ent.Left = net.ReadBool()
    ent.BigLetter = net.ReadBool()
    ent.Double = net.ReadBool()
    ent.DoubleL = net.ReadBool()
    ent.AutostopPresent = net.ReadBool()
    ent.BoxName = net.ReadString()
    ent.BoxNameStart = net.ReadString()
	ent.StationTrack = net.ReadBool()
    if not ent.ARSOnly then
        ent.LensesTBL = string.Explode("-",ent.Lenses)
    end
    if ent.RemoveModels then ent:RemoveModels() end
end)

function ENT:CreateModels()
    local TLM = self.TrafficLightModels[self.LightType]
    local ID = 0
    local ID2 = 0
    -- Create new clientside models
    if not self.ARSOnly then
        --SPAWN A OLD ROUTE Numbers
        --оператор # съедает больше производительности, чем исопльзование своей переменной с хранением количества элементов в таблице
        --поэтому добавляю каунтеры
        --TODO вообще сравнить бы это здесь xD
        local rn1 = {}
        local rn1N = 0
        local rn2 = {}
        self.RouteNumbers = {}
        self.SpecRouteNumbers = {}
        for i=1,#self.RouteNumberSetup do
            local CurRN = self.RouteNumberSetup[i]
            --[[
                self.OldRouteNumberSetup[1] = "1234D",
                self.OldRouteNumberSetup[2] = "WKFX",
                self.OldRouteNumberSetup[3] = "LR"
                rn1 заполняется если CurRN содержит что либо из self.OldRouteNumberSetup[1]
                rn2 заполняется если CurRN содержит что либо из self.OldRouteNumberSetup[2]
                SpecRouteNumbers заполняется если CurRN содержит что либо из self.OldRouteNumberSetup[3]
                rn1 - цифробуквенные
                rn2 - W-20КМ, K-КГУ, F-стрела вверх, X-пустой (для длинного кронштейна)
                и SpecRouteNumbers - особые маршрутники, редко используются (стрелы влево вправо)
            ]]--
            if self.OldRouteNumberSetup[1]:find(CurRN) then
                rn1N = table.insert(rn1,CurRN)
            elseif self.OldRouteNumberSetup[2]:find(CurRN) then
                table.insert(rn2,CurRN)
            elseif self.OldRouteNumberSetup[3]:find(CurRN) then
                table.insert(self.SpecRouteNumbers,{CurRN,CurRN == "F"})
            end
        end
        for i=1,rn1N,2 do
            table.insert(self.RouteNumbers,{rn1[i],rn1[i+1],true})
        end
        for k,v in pairs(rn2) do
            table.insert(self.RouteNumbers,{v})
        end
        self.Arrow = nil

        for k,v in pairs(self.SpecRouteNumbers) do
            if not v[2] then
                self.Arrow = k
                self.SpecRouteNumbers = v
                break
            end
        end
        local LenseNum = self.Arrow and 1 or 0
        local OneLense = self.Arrow == nil
        for k,v in ipairs(self.LensesTBL) do
            if k > 1 and v:find("[RGBWYMX]+") then
                OneLense = false
            end
            for i=1,#v do
                if v[i]:find("[RGBWYMX]") then
                    LenseNum = LenseNum+1
                end
            end
        end
        if LenseNum == 0 then OneLense = false end
        LenseNum = 0
        local oneItemHeadCount = 0
        for k,v in pairs(self.LensesTBL) do
            if #v > 1 then
                LenseNum = LenseNum + 1
            else
                oneItemHeadCount = oneItemHeadCount + 1
            end
        end
        -- if oneItemHeadCount > 1 then 
        --     LenseNum = LenseNum + oneItemHeadCount
        -- end
        local offset = self.RenderOffset[self.LightType] or vector_origin
        self.LongOffset = self.LongOffset or vector_origin
        if not self.Left or self.Double then self:SpawnMainModels(self.BasePos[self.LightType],angle_zero,LenseNum) end
        if self.Left or self.Double then self:SpawnMainModels(self.BasePos[self.LightType]*vector_mirror,Angle(0,180,0),LenseNum,self.Double and "d" or nil) end

        if not self.RouteNumbers.sep and #self.RouteNumbers > 1 then
            self.RouteNumbers.sep = 2
        elseif not self.RouteNumbers.sep and #self.RouteNumbers > 0 then
            self.RouteNumbers.sep = 1
        end
        if self.RouteNumbers.sep and self.RouteNumbers[self.RouteNumbers.sep][1] ~= "X" then
            local id = self.RouteNumbers.sep
            local rnadd = self.RouteNumbers[id][3] and not self.RouteNumbers[id][2] and 3 or 4
            self.Models[1]["rous"] = ClientsideModel(TLM.LampIndicator.models[rnadd],RENDERGROUP_OPAQUE)
            self.RouteNumbers[id].pos = (self.BasePos[self.LightType]+offset+self.LongOffset-TLM.LampIndicator[3])
            if self.Left then self.RouteNumbers[id].pos = self.RouteNumbers[id].pos*vector_mirror+TLM.LampIndicator[4] end
            self.Models[1]["rous"]:SetPos(self:LocalToWorld(self.RouteNumbers[id].pos))
            self.Models[1]["rous"]:SetAngles(self:GetAngles())
            self.Models[1]["rous"]:SetParent(self)
        end
        if #self.RouteNumbers > 0 and (#self.RouteNumbers ~= 1 or not self.RouteNumbers.sep) then
            self.RN = 1
            self.RouteNumberOffset = TLM.RouteNumberOffset
            offset = offset + self.RouteNumberOffset
        else
            self.RouteNumberOffset = nil
            self.RN = nil
        end
        if self.AutostopPresent then
            if not IsValid(self.Models[1]["autostop"]) then
                self.Models[1]["autostop"] = ClientsideModel(self.AutostopModel[1],RENDERGROUP_OPAQUE)
                self.Models[1]["autostop"]:SetPos(self:LocalToWorld(self.BasePos[self.LightType]+self.AutostopModel[2]))
                self.Models[1]["autostop"]:SetAngles(self:GetAngles())
                self.Models[1]["autostop"]:SetParent(self)
            end
        end
        self.NamesOffset = vector_origin
        -- Create traffic light models
        --if self.LightType > 2 then self.LightType = 2 end
        --if self.LightType < 0 then self.LightType = 0 end
        local first = true
        local assembled = false
        self.RouteHeads = self.RouteHeads or {}

        for _,v in ipairs(self.LensesTBL) do
            local data
            local head
            local _, MUcount = string.gsub(v, "M", "")
            if not TLM[v] then
                if not TLM['single'] then
                    data = TLM[#v-1]
                    head = #v-1
                else
                    data = TLM[0]
                    head = 0
                    assembled = true
                end
            else
                data = TLM[v]
                head = v
            end
            if assembled and v[#v] == "X" then 
                data = TLM["X"]
                head = "X"
            end
            if assembled and v[#v] == 'M' then 
                data = TLM['M']
                if MUcount == 2 then head = 'M_double' else head = 'M' end
            end
            if not data then continue end			
            local vec = data[1]
            if assembled then curoffset = TLM['kronOff'] + TLM['step'] * #v end
            if first then
                first = false
            else
                if not assembled then offset = offset - vec
                else offset = offset - curoffset end
            end
            self.NamesOffset = self.NamesOffset + vec
            local offsetAndLongOffset = offset + self.LongOffset
            --SpawnHead(ID,model,pos,ang,isLeft,isLast)
            if self.SignalType != 5 then
                if not self.Left or self.Double then self:SpawnHead(ID,head,self.BasePos[self.LightType] + offsetAndLongOffset,angle_zero,false,#v == 1,v) end
                if self.Left or self.Double then self:SpawnHead((self.Double and ID.."d" or ID),head,(self.BasePos[self.LightType] + offsetAndLongOffset)*vector_mirror,angle_zero,true,#v == 1,v) end
            else
                if not self.Left or self.Double then self:SpawnHead(ID,head,self.BasePos[self.LightType] + offsetAndLongOffset,angle_zero,false,#v == 1) end
                if self.Left or self.Double then self:SpawnHead((self.Double and ID.."d" or ID),head,(self.BasePos[self.LightType] + offsetAndLongOffset)*vector_mirror,angle_zero,true,#v == 1) end
            end
            if v != "M" then
                for i = 1,#v do
                    local lnum = assembled and 1 or i
                    local lenOff = data[3][i-1]
                    local head = 'single'
                    if v[i] == 'M' then head = 'M_single'  end
                    if v[i] == "X" then head = "X"  end
                    if assembled then lenOff = TLM['single'][3][0] - TLM['step'] * (i-#v) end
                    --if assembled then lenOff = Vector(0,0,100) end
                    ID2 = ID2 + 1
                    if assembled and i < #v then
                        if not self.Left or self.Double then self:SpawnHead(ID..ID2,head,self.BasePos[self.LightType] + offsetAndLongOffset + TLM['step']*(#v-i),angle_zero,false,i == #v-1) end
                        if self.Left or self.Double then self:SpawnHead((self.Double and ID..ID2.."d" or ID..ID2),head,(self.BasePos[self.LightType] + offsetAndLongOffset)*vector_mirror + TLM['step']*(#v-i),angle_zero,true,i == #v-1) end					
                    end						
                    if not self.Signals[ID2] then self.Signals[ID2] = {} end
                    
                    self.PixVisibleHandlers[ID..ID2] = util.GetPixelVisibleHandle()
                    if self.DoubleL then 
                        self.PixVisibleHandlers[ID..ID2.."x"] = util.GetPixelVisibleHandle()
                    end
                end
            end
            ID = ID + 1
        end
        if self.Arrow then
            local id = self.Arrow
            self.Models[1]["roua"] = ClientsideModel(TLM.LampIndicator.models[4],RENDERGROUP_OPAQUE)
            self.SpecRouteNumbers.pos = (self.BasePos[self.LightType]+offset+self.LongOffset-TLM.LampIndicator[5])+(self.Left and TLM.LampIndicator[6] or vector_origin) - (self.RouteNumberOffset or vector_origin)
            if self.Left then self.SpecRouteNumbers.pos = self.SpecRouteNumbers.pos * vector_mirror end
            self.Models[1]["roua"]:SetPos(self:LocalToWorld(self.SpecRouteNumbers.pos))
            self.Models[1]["roua"]:SetAngles(self:LocalToWorldAngles(self.Left and Angle(-90,0,0) or Angle(90,0,0)))
            self.Models[1]["roua"]:SetParent(self)
        end
        offset = self.RenderOffset[self.LightType]+(OneLense and TLM.name_one or TLM.name)+(OneLense and self.RouteNumberOffset or vector_origin)
        if self.LightType == 1 then
            offset = offset - self.NamesOffset
        end
        --local double = self.LightType ~= 1 and string.find(self.Name,"^[A-Z][A-Z]")
        local double = self.LightType != 1 and self.LightType != 2 and string.find(self.Name,"^[%a%p][%a%p]")
        local min = 0
        for i = double and 2 or 0,#self.Name-1 do
            local id = (double and i-1 or i) - min
            if double and self.BigLetter then
                if not self.Left or self.Double then
                    self:SpawnLetter(0,TLM.SignLetter.model,offset - Vector(0,0,id*TLM.SignLetter.z-5.3),(Metrostroi.LiterWarper[self.Name[0+1]] or self.Name[0+1]),true)
                    self:SpawnLetter(1,TLM.SignLetter.model,offset - Vector(0,0,id*TLM.SignLetter.z+0.5),(Metrostroi.LiterWarper[self.Name[1+1]] or self.Name[1+1]),true)
                end
                if self.Left or self.Double then
                    self:SpawnLetter(0,TLM.SignLetter.model,offset - Vector(0,0,id*TLM.SignLetter.z-5.3),(Metrostroi.LiterWarper[self.Name[0+1]] or self.Name[0+1]),false)
                    self:SpawnLetter(1,TLM.SignLetter.model,offset - Vector(0,0,id*TLM.SignLetter.z+0.5),(Metrostroi.LiterWarper[self.Name[1+1]] or self.Name[1+1]),false)
                end
            elseif double then
                if not self.Left or self.Double then
                    self:SpawnLetter(0,TLM.SignLetterSmall.model,offset - TLM.SignLetterSmall[2],(Metrostroi.LiterWarper[self.Name[0+1]] or self.Name[0+1]),true)
                    self:SpawnLetter(1,TLM.SignLetterSmall.model,offset - TLM.SignLetterSmall[1],(Metrostroi.LiterWarper[self.Name[1+1]] or self.Name[1+1]),true)
                end
                if self.Left or self.Double then
                    self:SpawnLetter(0,TLM.SignLetterSmall.model,offset - TLM.SignLetterSmall[1],(Metrostroi.LiterWarper[self.Name[0+1]] or self.Name[0+1]),false)
                    self:SpawnLetter(1,TLM.SignLetterSmall.model,offset - TLM.SignLetterSmall[2],(Metrostroi.LiterWarper[self.Name[1+1]] or self.Name[1+1]),false)
                end
            end
            if double and i == 2 then offset = offset + TLM.DoubleOffset end
            if self.Name[i+1] == " " then continue end
            if self.Name[i+1] == "/" then min = min + 1; continue end
            if self.BigLetter and self.LightType == 2 then
                self:SpawnLetter(i,TLM.SignLetter.model,offset - Vector(0,0,id*TLM.SignLetter.z),(Metrostroi.LiterWarper[self.Name[i+1]] or self.Name[i+1]))
            elseif self.BigLetter then
                self:SpawnLetter(i,TLM.SignLetter.model,offset - Vector(0,0,id*TLM.SignLetter.z+7.9),(Metrostroi.LiterWarper[self.Name[i+1]] or self.Name[i+1]))
            else
                self:SpawnLetter(i,TLM.SignLetter.model,offset - Vector(0,0,id*TLM.SignLetter.z),(Metrostroi.LiterWarper[self.Name[i+1]] or self.Name[i+1]))
            end

        end
        if self.Name and self.Name:match("(/+)$") then
            local i = #self.Name
            local id = (double and i-1 or i) - min
            self:SpawnLetter(i,TLM.SignLetter.model,offset - Vector(0,0,id*TLM.SignLetter.z),Format("s%d",math.min(3,#self.Name:match("(/+)$"))))
        end
        OffBoxName = TLM.boxname or Vector(0,0,0)
        OffBoxNameStart = TLM.boxnamestart or Vector(0,0,0)
        if self.BoxName == nil then self.BoxName = "" end
        if self.BoxNameStart == nil then self.BoxNameStart = "" end
        LeftLengOffBNE = Vector(#self.BoxName*4.55,0,0)
        LeftLengOffBNS = Vector(9.1,0,0)
        local safe_angle = Angle(0, 0, 0)
        if angle and type(angle) == "Angle" then
            safe_angle = angle
        end
        local base_angle = Angle(safe_angle.p, safe_angle.y, safe_angle.r)
        local reversed_angle = Angle(base_angle.p, base_angle.y + 180, base_angle.r)
        for i = 0, #self.BoxName-1 do
            local pos = Vector(0, 0, 0)
            if self.BoxName[i+1] and (self.BoxName[i+1] ~= " " and self.BoxName[i+1] ~= "/") then
                if self.LightType == 3 then
                    if self.AutostopPresent then
                        pos = numoffsetautostopbox - Vector(0, 0, i * 5.85)
                    end
                else    
                    if not self.Left then
                        pos = OffBoxName - Vector(i * 4.55, 0, 0)
                    elseif self.Left then 
                        pos = OffBoxName - Vector(-188.5 + i * 4.55, -1, 0) + LeftLengOffBNE
                    end
                end
                self:SpawnBoxNumbers(
                    i,
                    TLM.SignLetter.model,
                    pos,
                    (Metrostroi.LiterWarper[self.BoxName[i+1]] or self.BoxName[i+1]),
                    base_angle
                )
            end
        end
        for i = 0, #self.BoxNameStart-1 do
            if self.BoxNameStart[i+1] and (self.BoxNameStart[i+1] != " " and self.BoxNameStart[i+1] != "/") then
                local pos_start = Vector(0, 0, 0)
                if self.LightType == 3 then
                    if self.AutostopPresent then
                        pos_start = numoffsetautostopbox - Vector(0, 0, i * 5.85)
                    end
                else    
                    if self.LightType != 5 then
                        if not self.Left then
                            pos_start = OffBoxNameStart - Vector(14+i*-4.55,69,0)
                        else
                            pos_start = OffBoxNameStart - Vector(-175.5+i*-4.55,69-1,0) + LeftLengOffBNS*2
                        end
                    else
                        if not self.Left then
                            pos_start = OffBoxNameStart - Vector(14+i*-4.55,80,0)
                        else
                            pos_start = OffBoxNameStart - Vector(-184.5+i*-4.55,80,0) + LeftLengOffBNS
                        end
                    end
                end
                self:SpawnBoxNumbers(
                    i + 1000,
                    TLM.SignLetter.model,
                    pos_start,
                    (Metrostroi.LiterWarper[self.BoxNameStart[i+1]] or self.BoxNameStart[i+1]),
                    reversed_angle
                )
            end
        end
        if self.Name and self.Name:match("(/+)$") then
            local i = #self.Name
            local id = (double and i-1 or i) - min
            self:SpawnLetter(i,TLM.SignLetter.model,offset - Vector(0,0.,id*5.85),Format("s%d",math.min(3,#self.Name:match("(/+)$"))))
        end
    elseif self.StationTrack then
        local k = "m1"
        OffBoxName = TLM.boxname or Vector(0,0,0)
        OffBoxNameStart = TLM.boxnamestart or Vector(0,0,0)
        if self.BoxName == nil then self.BoxName = "" end
        if self.BoxNameStart == nil then self.BoxNameStart = "" end
        OffBNE = Vector(#self.BoxName*2.275,0,0)
        OffBNS = Vector(#self.BoxNameStart*2.275,0,0)
        local base_angle_st = Angle(0, 0, -30)
        local reversed_angle_st = Angle(0, 180, -30)
        for i = 0,#self.BoxName-1 do
            if self.BoxName[i+1] == " " or self.BoxName[i+1] == "/" then continue end
            local pos
            if self.LightType == 2 or self.LightType == 3 then
                pos = OffBoxName - Vector(i*5.55-94.225, 20.75, 48) + OffBNE
            else
                pos = OffBoxName - Vector(i*4.55-94.225, 24, 48) + OffBNE
            end
            self:SpawnBoxNumbers(i,TLM.SignLetter.model,pos,(Metrostroi.LiterWarper[self.BoxName[i+1]] or self.BoxName[i+1]), base_angle_st)
        end
        for i = 0, #self.BoxNameStart-1 do
            if self.BoxNameStart[i+1] and (self.BoxNameStart[i+1] ~= " " and self.BoxNameStart[i+1] ~= "/") then
                local pos_start
                if self.LightType ~= 5 then
                    pos_start = OffBoxNameStart - Vector(i*-4.55-84.225, 64, 48) + OffBNS
                else pos_start = OffBoxNameStart - Vector(i*-4.55-84.225, 62, 48) + OffBNS end
                self:SpawnBoxNumbers(
                    i + 1000,
                    TLM.SignLetter.model,
                    pos_start,
                    (Metrostroi.LiterWarper[self.BoxNameStart[i+1]] or self.BoxNameStart[i+1]),
                    reversed_angle_st
                )
            end
        end
        if not IsValid(self.Models[1][k]) then
            local v = TLM["m1"]
            self.Models[1][k] = ClientsideModel(v,RENDERGROUP_OPAQUE)
            self.Models[1][k]:SetPos(self:LocalToWorld(self.BasePos[self.LightType]*(self.Left and Vector(-1*0.9,1,0) or 1)))
            self.Models[1][k]:SetAngles(self:LocalToWorldAngles(self.Left and Angle(-1,1,1) or Angle(1,1,1)))
            self.Models[1][k]:SetParent(self)
        end
    else
        local k = "m1"
        numoffsetbox = TLM.boxname or Vector(0,0,0)
        if self.BoxName == nil then self.BoxName = "" end
        if self.BoxNameStart == nil then self.BoxNameStart = "" end
        leftlengthoffset = Vector(#self.BoxName*4.55,0,0)
        stroff = Vector(#self.BoxName*2.275,0,0)
        local safe_angle = Angle(0, 0, 0)
        if angle and type(angle) == "Angle" then
            safe_angle = angle
        end
        local current_angle = Angle(safe_angle.p, safe_angle.y, safe_angle.r)
        local reversed_angle_final = Angle(current_angle.p, current_angle.y + 180, current_angle.r)
        for i = 0,#self.BoxName-1 do
            if self.BoxName[i+1] == " " or self.BoxName[i+1] == "/" then continue end
            local pos = numoffsetbox - Vector(i*4.55,0,0)
            if self.Left then
                pos = pos - Vector(103*-2+i*0,0,-0.5)
            end
            self:SpawnBoxNumbers(i, TLM.SignLetter.model, pos, (Metrostroi.LiterWarper[self.BoxName[i+1]] or self.BoxName[i+1]), current_angle)
        end
        for i = 0, #self.BoxNameStart-1 do
            if self.BoxNameStart[i+1] and (self.BoxNameStart[i+1] ~= " " and self.BoxNameStart[i+1] ~= "/") then
                local pos_start = Vector(0, 0, 0)
                local reversed_angle_final = Angle(current_angle.p, current_angle.y + 180, current_angle.r)
                if self.LightType != 5 then
                    pos_start = numoffsetbox - Vector(13.9+i*-4.55,69,1) 
                    if self.Left then
                        pos_start = pos_start - Vector(104*-2+i*0,-1,-0.5)
                    end
                else
                    pos_start = numoffsetbox - Vector(13.9+i*-4.55,80,0.75) 
                    if self.Left then
                        pos_start = pos_start - Vector(104*-2+i*0,-1,-0.5)
                    end
                end
                self:SpawnBoxNumbers(
                    i + 1000,
                    TLM.SignLetter.model,
                    pos_start,
                    (Metrostroi.LiterWarper[self.BoxNameStart[i+1]] or self.BoxNameStart[i+1]),
                    reversed_angle_final
                )
            end
        end
        if TLM.arsletter and (self.Name:StartWith('TC') or self.Name:StartWith('  ')) then
            local name = self.Name
            local offset = TLM.name 
            local angle = TLM.name_s_ang
            
            name = string.Replace(name, " ", "")
            name = string.Replace(name, "/", "")
            name = string.Replace(name, "TC", "")
            name = string.Replace(name, "REP", "")
            name = string.Replace(name, "CH", "")
            name = string.Replace(name, "J", "")
            if (self.Left) then name = string.reverse(name) end

            offset = TLM.name_out
            
            if self.Left then offset = offset - Vector(10, 0, 0) end
            offset = offset - Vector((5.85/2) * (3 - (#name)), 0, 0)

            for i = 0, #name-1 do
                local id = i
                self:SpawnLetter(i, TLM.SignLetter.model, offset - Vector(id*5.85,0,0),(Metrostroi.LiterWarper[name[i+1]] or name[i+1]), not self.Left and true or false, angle)
            end
        end

        if not IsValid(self.Models[1][k]) then
            local v = TLM["m1"]
            self.Models[1][k] = ClientsideModel(v,RENDERGROUP_OPAQUE)
            self.Models[1][k]:SetPos(self:LocalToWorld(self.BasePos[self.LightType]*(self.Left and Vector(-1*0.9,1,0) or 1)))
            self.Models[1][k]:SetAngles(self:LocalToWorldAngles(self.Left and Angle(-1,1,1) or Angle(1,1,1)))
            self.Models[1][k]:SetParent(self)
        end
    end
    self.Models.have = true
    self.ModelsCreated = true
    hook.Add( "PostDrawTranslucentRenderables", self, self.LightSprites)

    return true
end

function ENT:UpdateModels(CurrentTime)
    local TLM = self.TrafficLightModels[self.LightType]
    local blink = RealTime() % 3 > 0.8

    --TODO
    if self.AutostopPresent then
        if IsValid(self.Models[1]["autostop"]) then
            self.Models[1]["autostop"]:SetPoseParameter("position",self:Animate("Autostop", self:GetNW2Bool("Autostop") and 1 or 0, 0,1, 0.4,false))
        end
    end

    local sig = self:GetNW2String("Signal","")
    local num = self:GetNW2String("Number",nil)
    self.Sig = sig
    self.Num = num
    
    if self.ARSOnly then return true end
    local offset = (self.RenderOffset[self.LightType] or vector_origin)
    if self.RouteNumberOffset then
        offset = offset + self.RouteNumberOffset
    end
    local ID = 0
    local ID2 = 0
    local lID2 = 0
    local first = true
    local assembled = false
    local firstYellowFound
    for _,v in ipairs(self.LensesTBL) do
        local data		
        if not TLM[v] then
            if not TLM['single'] then 
                data = TLM[#v-1]
            else
                data = TLM[0]
                assembled = true
            end
        else
            data = TLM[v]
        end
        if not data then continue end
        if assembled and v[#v] == 'M' then data = TLM['M'] end			
        local vec = data[1]
        
        if assembled then curoffset = TLM['kronOff'] + TLM['step'] * #v end
        if first then
            first = false
        else
            if not assembled then offset = offset - vec
            else offset = offset - curoffset end
        end			
        
        if v~="M" then
            for i = 1,#v do
                ID2 = ID2 + 1
                if v[i] == "X" then continue end
                if v[i] ~= "M" then
                    lID2 = lID2 + 1
                end
                local lenOff = data[3][i-1]
                if assembled then lenOff = TLM['single'][3][0] - TLM['step'] * (i-#v) end

                if v[i] == "M" then
                    if i == #v then continue end
                    self:UpdateRoutePointer(ID..ID2, self.Num, 1)
                    continue
                end
                local n = tonumber(self.Sig[ID2])
                local n = tonumber(self.Sig[lID2])
                    -- условия для короткого погасания сигнала
                    local fadeCondition = n == 1 or n == 2
                    if n ~= nil and self.Signals[lID2].RealState ~= fadeCondition then
                        self.Signals[lID2].RealState = fadeCondition
                        self.Signals[lID2].Stop = CurrentTime + 0.1
                    end
                    if self.Signals[lID2].Stop and CurrentTime - self.Signals[lID2].Stop > 0 then
                        self.Signals[lID2].Stop = nil
                    end
                --Animate(clientProp, value, min, max, speed, damping, stickyness)
                --local State = self:Animate(ID.."/"..i,  ((n == 1 or (n == 2 and blink)) and not self.Signals[ID2].Stop) and 1 or 0,  0,1, blink and 256 or 128)
                local enableLense = ((n == 1 or n == 3) or (n == 2 and blink)) and not self.Signals[ID2].Stop
                    local State = 0
                    if not self.IsLed then
                        if v[i] == "Y" and n == 2 and blink then firstYellowFound = true end
                        local lightK = firstYellowFound and 0.85 or 1
                        State = self:Animate(ID.."/"..i, enableLense and 1*lightK or 0, 0,1, enableLense and 64 or 32)
                    else
                        State = enableLense and 1 or 0
                    end
                    if not IsValid(self.Models[3][ID..ID2]) and State > 0 then self.Signals[lID2].State = nil end
                local offsetAndLongOffset = offset + self.LongOffset
                if not self.DoubleL then
                    self:SetLight(ID,ID2,(self.BasePos[self.LightType] + offsetAndLongOffset)*(self.Left and vector_mirror or 1) + lenOff*(self.Left and vector_mirror or 1),angle_zero,self.SignalConverter[v[i]]-1,State,self.Signals[lID2].State ~= State)
                else
                    self:SetLight(ID,ID2,self.BasePos[self.LightType] + offsetAndLongOffset + lenOff,angle_zero,self.SignalConverter[v[i]]-1,State,self.Signals[lID2].State ~= State)
                    self:SetLight(ID,ID2.."x",(self.BasePos[self.LightType]+offsetAndLongOffset)*vector_mirror + lenOff*vector_mirror,angle_zero,self.SignalConverter[v[i]]-1,State,self.Signals[lID2].State ~= State)
                end
                self.Signals[ID2].State = State
            end
        else
            self:UpdateRoutePointer(ID, self.Num, 1)
        end
        local _, MUcount = string.gsub(v, "M", "")
        if v[#v] == "M" and assembled and #self.Num == 2 then
            self:UpdateRoutePointer(ID, self.Num, 2)
        elseif v[#v] == "M" and assembled and MUcount == 2 then
            self:UpdateRoutePointer(ID, self.Num, 0)
        elseif v[#v] == "M" and assembled and MUcount == 1 then
            self:UpdateRoutePointer(ID, self.Num, 1)
        end
        ID = ID + 1
    end

    local LampIndicatorModels_numb_mdl = TLM.LampIndicator.models['numb']
    local LampIndicatorModels_lamp_mdl = TLM.LampIndicator.models['lamp']
    for k,v in pairs(self.RouteNumbers) do
        if k == "sep" then continue end
        local rou1k = "rou1"..k
        local State1 = self:Animate(rou1k,self.Num:find(v[1]) and 1 or 0,   0,1, 256)
        local State2
        --if v[3] then
        local rou2k = "rou2"..k
        if v[2] then State2 = self:Animate(rou2k,self.Num:find(v[2])and 1 or 0,     0,1, 256) end
        if not IsValid(self.Models[3][rou1k]) and State1 > 0 then
            self.Models[3][rou1k] = ClientsideModel(v[3] and LampIndicatorModels_numb_mdl or LampIndicatorModels_lamp_mdl,RENDERGROUP_OPAQUE)
            self.Models[3][rou1k]:SetPos(self:LocalToWorld(v.pos + self.OldRouteNumberSetup[4]))
            self.Models[3][rou1k]:SetAngles(self:GetAngles())
            self.Models[3][rou1k]:SetParent(self)
            self.Models[3][rou1k]:SetSkin(v[3] and self.OldRouteNumberSetup[5][v[1]] or self.OldRouteNumberSetup[6][v[1]] or tonumber(v[1])-1)
            self.Models[3][rou1k]:SetRenderMode(RENDERMODE_TRANSCOLOR)
            self.Models[3][rou1k]:SetColor(Color(255, 255, 255, 0))
        end
        if IsValid(self.Models[3][rou1k]) then
            if State1 > 0 then
                self.Models[3][rou1k]:SetColor(Color(255,255,255,State1*255))
            elseif State1 == 0 then
                self.Models[3][rou1k]:Remove()
            end
        end
        if not IsValid(self.Models[3][rou2k]) and v[3] and v[2] and State2 > 0 then
            self.Models[3][rou2k] = ClientsideModel(LampIndicatorModels_numb_mdl,RENDERGROUP_OPAQUE)
            self.Models[3][rou2k]:SetPos(self:LocalToWorld(v.pos + self.OldRouteNumberSetup[4] + TLM.RouteNumberOffset2))
            self.Models[3][rou2k]:SetAngles(self:GetAngles())
            self.Models[3][rou2k]:SetParent(self)
            self.Models[3][rou2k]:SetSkin(self.OldRouteNumberSetup[5][v[2]] or tonumber(v[2])-1)
            self.Models[3][rou2k]:SetRenderMode(RENDERMODE_TRANSCOLOR)
            self.Models[3][rou2k]:SetColor(Color(255, 255, 255, 0))
        end
        if IsValid(self.Models[3][rou2k]) then
            if State2 > 0 then
                self.Models[3][rou2k]:SetColor(Color(255,255,255,State2*255))
            elseif State2 == 0 then
                self.Models[3][rou2k]:Remove()
            end
        end
    end
    if self.Arrow then
        local State = self:Animate("roua",self.Num:find(self.SpecRouteNumbers[1]) and 1 or 0,   0,1, 256)
        if not IsValid(self.Models[3]["roua"]) and State > 0 then
            self.Models[3]["roua"] = ClientsideModel(LampIndicatorModels_lamp_mdl,RENDERGROUP_OPAQUE)
            self.SpecRouteNumbers.pos = (self.BasePos[self.LightType]+offset-TLM.SpecRouteNumberOffset)-(self.RouteNumberOffset or vector_origin)+TLM.RouteNumberOffset3
            if self.Left then self.SpecRouteNumbers.pos = self.SpecRouteNumbers.pos*TLM.SpecRouteNumberOffset2 end
            self.Models[3]["roua"]:SetPos(self.Models[1]["roua"]:LocalToWorld(TLM.RouaOffset))
            self.Models[3]["roua"]:SetAngles(self.Models[1]["roua"]:LocalToWorldAngles(Angle(180,0,0)))
            self.Models[3]["roua"]:SetParent(self)
            if self.Left then
                if self.Num[1] == "L" then
                    self.Models[3]["roua"]:SetSkin(self.OldRouteNumberSetup[6]["R"] or 0)
                else
                    self.Models[3]["roua"]:SetSkin(self.OldRouteNumberSetup[6]["L"] or 0)
                end
            else
                self.Models[3]["roua"]:SetSkin(self.OldRouteNumberSetup[6][self.Num[1]] or 0)
            end
            self.Models[3]["roua"]:SetRenderMode(RENDERMODE_TRANSCOLOR)
            self.Models[3]["roua"]:SetColor(Color(255, 255, 255, 0))
        end
        if IsValid(self.Models[3]["roua"]) then
            if State > 0 then
                self.Models[3]["roua"]:SetColor(Color(255,255,255,State*255))
            elseif State == 0 then
                self.Models[3]["roua"]:Remove()
            end
        end
    end
    --self.SpecRouteNumbers
end

function ENT:Think()
    local CurrentTime = CurTime()
    --self:SetNextClientThink(CurTime + 0.027)
    self.PrevTime = self.PrevTime or RealTime()
    self.DeltaTime = (RealTime() - self.PrevTime)
    self.PrevTime = RealTime()
	
    if self:IsDormant() or Metrostroi and Metrostroi.ReloadClientside then
        if not self.ReloadModels and self.ModelsCreated then
            self:OnRemove()
        end
        return true
    end

    if self.ReloadModels then
        self.ReloadModels = false
        self:RemoveModels()
    end

    if not self.Name then
        if self.sended and (CurrentTime - self.sended) > 0 then
            self.sended = nil
        end
        if not self.sended then
            net.Start("metrostroi-signal")
                net.WriteEntity(self)
            net.SendToServer()
            self.sended = CurrentTime + 1.5
        end
        return true
    end

    if not self.ModelsCreated then
        local created = self:CreateModels()
        self.Models.have = created
        self.ModelsCreated = created
    else
        self:UpdateModels(CurrentTime)
    end
    return true
end

local cols = {
    R = Color(255,0,0),
    Y = Color(255,255,0),
    G = Color(0,255,0),
    W = Color(255,255,255),
    B = Color(0,0,255),
}

function ENT:Draw()
    -- Draw model
    self:DrawModel()
end

function ENT:LightSprites()
	if not self.Sprites then return end
	for k,v in pairs(self.Sprites) do
		self:Sprite(v.pos, self:GetAngles(), v.col, v.bri, v.mul, k)
	end	
end

function ENT:Sprite(pos, ang, col, bri, mul, handlerKey )
    local TLM = self.TrafficLightModels[self.LightType]
    if bri <= 0 then return end
    local Visible = 0
    if self.PixVisibleHandlers[handlerKey] then
	    Visible = util.PixelVisible( pos, 1, self.PixVisibleHandlers[handlerKey] )
    end
	if ( ( Visible ) and ( Visible > 0.2 ) ) then
		local fw = ang:Forward()
		fw:Rotate(Angle(0,90,0))
		local view = EyePos() - pos
		local dist = view:LengthSqr()
		view:Normalize()
		local viewdot = view:Dot( fw )
		viewdot = viewdot
		if ( viewdot > 0 ) then
			Visible = Visible * viewdot
			local s = bri ^ 0.5 * math.Clamp(dist ^ 0.5 /32,64,384) * mul * (TLM.lense_scale or 1)
			--local s = bri ^ 0.5 * math.Clamp(dist/20,48,256)
			s = s * Visible
			render.SetMaterial( self.SpriteMat )
			render.DrawSprite( pos, s, s, col )
		end
	end	
end

function ENT:UpdatePointerLamps(ID, rnState, SpriteColor, SpriteMultiplier)
    local pos = Vector(0,SpriteMultiplier*2,0)
    pos:Rotate(self:GetAngles())

    for i=1,#self.Font[""] do
        local IDi = ID.."i"..i
        if not IsValid(self.Models[4][IDi]) then return end
        local state = self.Font[rnState][i]
        local mIDi = ID..'s'..i
        self.Models[4][IDi]:SetSkin(state and 1 or 0)
        self.Models[4][IDi]:SetNoDraw(not state)
        if state or self.Sprites[mIDi] then
            self.Sprites[mIDi] = {
                pos = self.Models[4][IDi]:GetPos() + pos, 
                bri = state and 1 or 0, 
                col = Metrostroi.Lenses[SpriteColor], 
                mul = SpriteMultiplier
            }
        end
    end
end

function ENT:UpdateRoutePointer(ID, rnState, MU_LOCAL_ID)
    --print("SignalName: ",self.Name,"ID: ",ID, "rnState: ", rnState, "MU_LOCAL_ID: ", MU_LOCAL_ID)
    rnState = self.NewRouteNumberSetup[string.sub(tostring(rnState), MU_LOCAL_ID, MU_LOCAL_ID)]
    local TLM = self.TrafficLightModels[self.LightType]
    if not self.UseRoutePointerFont[self.LightType] then
        local skin_id = Metrostroi.RoutePointer[rnState]
        if skin_id == nil then
            skin_id = tonumber(rnState) or 0
        end
        if IsValid(self.Models[1][ID]) then
            if not self.Double or self.DoubleL or not self.Left then
                self.Models[1][ID]:SetSkin(skin_id) 
            end
        end
        if IsValid(self.Models[1][ID.."d"]) then
            if self.Double and self.DoubleL or self.Left then
                self.Models[1][ID.."d"]:SetSkin(skin_id)
            end
        end
    elseif self.Font[rnState] and (not self.NumLit[ID] or self.NumLit[ID] ~= rnState) then
        if (not self.Double or self.DoubleL or not self.Left) then self:UpdatePointerLamps(ID, rnState, TLM.M[9], TLM.M[10]) end
        if (self.Double and self.DoubleL or self.Left) then self:UpdatePointerLamps(ID.."d", rnState, TLM.M[9], TLM.M[10]) end
        self.NumLit[ID] = rnState
    end
end

local debug = GetConVar("metrostroi_drawsignaldebug")

local ars = {
    {"275 Hz", "0 km/h"},
    {"N/A Hz",  "NF"},
    {"275-N/A", "Absolute stop"},
    nil,
    {"225 Hz",  "40 km/h"},
    nil,
    {"175 Hz",  "60 km/h"},
    {"125 Hz",  "70 km/h"},
    {"75   Hz", "80 km/h"},
}
local function enableDebug()
    if debug:GetBool() then
        hook.Add("PreDrawEffects","MetrostroiSignalDebug",function()
            for _,sig in pairs(ents.FindByClass("gmod_track_signal")) do
                if IsValid(sig) and LocalPlayer():GetPos():DistToSqr(sig:GetPos()) < 384*384 then
                    local pos = sig:LocalToWorld(Vector(48,0,150))
                    local ang = sig:LocalToWorldAngles(Angle(0,180,90))
                    local colorRed          = Color(255,    0,      0)
                    local colorGreen        = Color(0,      255,    0)
                    local colorYellow       = Color(255,    255,    0)
                    local colorBlue         = Color(0,      0,      255)
                    local colorWhite        = Color(255,    255,    255)
                    local colorBlack        = Color(0,      0,      0)
                    local colorBlackRed     = Color(50,     0,      0)
                    local colorBlackGreen   = Color(0,      50,     0)
                    local font = "Trebuchet24"
                    local autostop_debug = not sig.ARSOnly and sig.AutostopPresent
                    local msk_325 = sig:GetNW2Bool("CurrentARS325", false)
                    local spb_325 = sig:GetNW2Bool("CurrentARS325_2", false)
                    local hz_325 = msk_325 or spb_325
                    cam.Start3D2D(pos, ang, 0.25)
                        if sig:GetNW2Bool("Debug",false) then
                            surface.SetDrawColor(sig.ARSOnly and 255 or 125, 125, 0, 255)
                            surface.DrawRect(0, -70, 364, 220)
                            if not sig.ARSOnly then
                                surface.DrawRect(0, 155, 240, 170)
                                surface.DrawRect(0, 330, 240, 190)
                                surface.SetDrawColor(colorBlack)
                                surface.DrawRect(245, 155, 119, 365)
                            else
                                surface.DrawRect(0, 155, 364, 170)
                                surface.DrawRect(0, 330, 364, 190)
                            end

                            if sig.Name then                                
                                --==================================================================================
                                draw.DrawText(  Format( "Joint main info (%d)", sig:EntIndex()),                            font,   5,  -70,colorRed)

                                draw.DrawText(          "Signal name: "..       sig.Name,                                   font,  15,  -50,colorBlack)
                                draw.DrawText(          "TrackID: "..           sig:GetNW2Int("PosID",0),                   font,  15,  -30,colorBlack)
                                draw.DrawText(  Format( "PosX: %.02f",          sig:GetNW2Float("Pos",0)),                  font, 125,  -30,colorBlack)

                                draw.DrawText(  Format( "Next Signal Name: %s", sig:GetNW2String("NextSignalName","N/A")),  font,   15, -5, colorBlackGreen)
                                draw.DrawText(  Format( "TrackID: %s",          sig:GetNW2Int("NextPosID",0)),              font,   15, 15, colorBlackGreen)
                                draw.DrawText(  Format( "Dist: %.02f meters",   sig:GetNW2Float("DistanceToNext",0)),       font,   15, 35, colorBlackGreen)

                                draw.DrawText(  Format( "Prev Signal Name: %s", sig:GetNW2String("PrevSignalName","N/A")),  font,   15, 60, colorBlackRed)
                                draw.DrawText(  Format( "TrackID: %s",          sig:GetNW2Int("PrevPosID",0)),              font,   15, 80, colorBlackRed)
                                draw.DrawText(  Format( "DistPrev: %.02f meters",sig:GetNW2Float("DistanceToPrev",0)),      font,   15, 100,colorBlackRed)

                                draw.DrawText(  Format( "Current route: %d",    sig:GetNW2Int("CurrentRoute",-1)),          font,   15, 125,colorBlack)
                                --==================================================================================
                                draw.DrawText(          "AB info",                                                          font,   5,  160,colorRed)
                                draw.DrawText(  Format( "Occupied: %s", sig:GetNW2Bool("Occupied",false) and "Y" or "N"),   font,   5,  180,colorBlack)
                                draw.DrawText(  Format( "Autostop: %s",
                                autostop_debug and (sig:GetNW2Bool("Autostop") and "Up" or "Down") or "Absent"),            font,   5,  200,colorBlack)
                                draw.DrawText(  Format( "2/6: %s",              sig:GetNW2Bool("2/6",false) and "Y" or "N"),font,   5,  220,colorBlack)
                                draw.DrawText(  Format( "ARS Next: %d",         sig:GetNW2Int("ArsNext")),                  font,   5,  240,colorBlack)
                                draw.DrawText(  Format( "ARS Current: %d",      sig:GetNW2Int("ArsThis")),                  font,   5,  260,colorBlack)
                                draw.DrawText(  Format( "Free BS: %d",          sig:GetNW2Int("FreeBS")),                   font,   5,  280,colorBlack)
                                --==================================================================================
                                draw.DrawText(          "ARS info",                                                         font,   5,  335,colorRed)
                                local num = 0
                                for i,tbl in pairs(ars) do
                                    if not tbl then continue end
                                    local isActive = sig:GetNW2Bool("CurrentARS" .. (i - 1), false)
                                    draw.DrawText("(" .. tbl[1] .. ")",             font, 5,   355+num*20, isActive and colorWhite or colorBlack)
                                    draw.DrawText(tbl[2],                           font, 105, 355+num*20, isActive and colorWhite or colorBlack)
                                    num = num+1
                                end
                                draw.DrawText(  "(325 Hz)",                         font, 5,    355+num*20, hz_325  and colorWhite or colorBlack)
                                draw.DrawText(  "RS:".. (msk_325 and "Y" or "N"),   font, 105,  355+num*20, msk_325 and colorWhite or colorBlack)
                                draw.DrawText(  "RD:".. (spb_325 and "Y" or "N"),   font, 165,  355+num*20, spb_325 and colorWhite or colorBlack)
                                --==================================================================================
                                if not sig.ARSOnly then
                                    draw.DrawText("Signal info",font,250,160,colorRed)
                                    local ID = 0
                                    local ID2 = 0
                                    local first = true
                                    for _,v in ipairs(sig.LensesTBL) do
                                        if not v then continue end
                                        for i = 1, #v do
                                            ID2 = ID2 + 1
                                            if v[i] == "M" then
                                                draw.DrawText("M", font, 250, 160 + (ID + ID2) * 20, colorWhite)
                                                draw.DrawText(sig.Num or "", font, 280, 160 + (ID + ID2) * 20, colorWhite)
                                            else
                                                local n = tonumber(sig.Sig[ID2])
                                                local char = v:sub(i, i)                                                
                                                local State = n == 1 and "x" or (n == 2 and (RealTime() % 1.25 > 0.6)) and "b" or false
                                                local textColor = cols[v[i]] or colorWhite
                                                draw.DrawText(v[i], font, 250, 160 + (ID + ID2) * 20, textColor)
                                                if State then
                                                    draw.DrawText(State, font, 280, 160 + (ID + ID2) * 20, textColor)
                                                end
                                            end
                                        end
                                        ID = ID + 1
                                    end
                                end
                                --==================================================================================
                            else
                                draw.DrawText("No data...",font,5,0,colorBlack)
                            end
                        else
                            surface.SetDrawColor(sig.ARSOnly and 255 or 125, 125, 0, 255)
                            surface.DrawRect(0, 0, 364, 25)
                            draw.DrawText("Debug disabled...",font,5,0,colorBlack)
                        end
                    cam.End3D2D()
                end
            end
        end)
    else
        hook.Remove("PreDrawEffects","MetrostroiSignalDebug")
    end
end
hook.Remove("PreDrawEffects","MetrostroiSignalDebug")
cvars.AddChangeCallback( "metrostroi_drawsignaldebug", enableDebug)
enableDebug()

--Metrostroi.OptimisationPatch()