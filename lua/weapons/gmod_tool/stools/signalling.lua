TOOL.Category   = "Metro"
TOOL.Name	   = "Signalling Tool MSA"
TOOL.Command	= nil
TOOL.ConfigName = ""
TOOL.ClientConVar["signaldata"] = ""
TOOL.ClientConVar["signdata"] = ""
TOOL.ClientConVar["autodata"] = ""
TOOL.ClientConVar["autostopdata"] = ""
TOOL.ClientConVar["kgudata"] = ""
TOOL.ClientConVar["type"] = 1
TOOL.ClientConVar["routetype"] = 1
if SERVER then util.AddNetworkString "metrostroi-stool-signalling" end

TOOL.Type = 0
TOOL.TypeOfAuto = 0
TOOL.RouteType = 1
if SERVER then
    local langs = {"ru", "en"}
    local types = {"msa_parameters", "msa_signalling", "msa_signtype"}
    for _, l in ipairs(langs) do
        for _, t in ipairs(types) do
            AddCSLuaFile(string.format("metrostroi_data/languages/%s_%s.lua", l, t))
        end
    end
end
if CLIENT then
    local lang = GetConVar("metrostroi_language"):GetString() == "ru" and "ru" or "en"
    local files = {"msa_parameters", "msa_signalling", "msa_signtype"}
    for _, suffix in ipairs(files) do
        local path = string.format("metrostroi_data/languages/%s_%s.lua", lang, suffix)
        include(path)
    end
    hook.Add("InitPostEntity", "MetrostroiSignallingInit", function()
        language.Add("Tool.signalling.name", MSignaltool_Name or "Signalling")
        language.Add("Tool.signalling.desc", MSignaltool_Des or "")
        language.Add("Tool.signalling.0",    MSignaltool_nul or "")
        language.Add("Undone_signalling",    MSignaltool_Undo or "Undone Signalling")
    end)
end
function TOOL:SpawnSignal(ply,trace,param)
	local pos = trace.HitPos
	local tr = Metrostroi.RerailGetTrackData(pos,ply:GetAimVector())
	if not tr then return end
	local ent
	local found = false
	local entlist = ents.FindInSphere(pos,64)
	for k,v in pairs(entlist) do
		if v:GetClass() == "gmod_track_signal" then
			if v.Name==self.Signal.Name then
				ent = v
				found=0
				break
			end
			if not found or found > pos:Distance(v:GetPos()) then
				ent = v
				found = pos:Distance(v:GetPos())
			end
		end
	end
	if param == 2 then
		if not ent then return end
		self.Signal.Type = ent.SignalType + 1
		self.Signal.Name = ent.Name
		self.Signal.BoxName = ent.BoxName
		self.Signal.BoxNameStart = ent.BoxNameStart
		self.Signal.StationTrack = ent.StationTrack
		self.Signal.StationBox = ent.StationBox
		self.Signal.Lenses = ent.LensesStr
		self.Signal.RouteUnused =   ent.RouteUnused
		self.Signal.RouteNumberSetup =  ent.RouteNumberSetup
		self.Signal.IsolateSwitches = ent.IsolateSwitches
		self.Signal.RS_325Hz = ent.RS_325Hz
		self.Signal.SPB_325Hz = ent.SPB_325Hz
		self.Signal.TwoToSix = ent.TwoToSix
		self.Signal.ARSOnly = ent.ARSOnly
		self.Signal.NonAutoStop = ent.NonAutoStop
		self.Signal.PassOcc = ent.PassOcc
		self.Signal.Routes = ent.Routes
		self.Signal.BigLetter = ent.BigLetter
		self.Signal.Left = ent.Left
		self.Signal.Double = ent.Double
		self.Signal.DoubleL = ent.DoubleL
		net.Start("metrostroi-stool-signalling")
			net.WriteUInt(0,8)
			net.WriteTable(self.Signal)
		net.Send(self:GetOwner())
	else
		if not ent then ent = ents.Create("gmod_track_signal") end
		if IsValid(ent) then
			if param ~= 2 then
				result = (-tr.forward):Angle()
				ent:SetPos(tr.centerpos - tr.up * 9.5)
				ent:SetAngles((-tr.right):Angle()+Angle(0,0,-result[1]))
			end

			if not found then
				ent:Spawn()
				-- Add to undo
				undo.Create("signalling")
					undo.AddEntity(ent)
					undo.SetPlayer(ply)
				undo.Finish()
			end
			ent.SignalType = self.Signal.Type-1
			ent.ARSOnly = self.Signal.ARSOnly
			ent.Name = self.Signal.Name
			ent.BoxName = self.Signal.BoxName
			ent.BoxNameStart = self.Signal.BoxNameStart
			ent.StationTrack = self.Signal.StationTrack
			ent.StationBox = self.Signal.StationBox
			ent.LensesStr = self.Signal.Lenses
			ent.RouteUnused =   self.Signal.RouteUnused
			ent.RouteNumberSetup =  self.Signal.RouteNumberSetup
			ent.IsolateSwitches = self.Signal.IsolateSwitches
			ent.RS_325Hz = self.Signal.RS_325Hz
			ent.SPB_325Hz = self.Signal.SPB_325Hz
			ent.NonAutoStop = self.Signal.NonAutoStop
			ent.TwoToSix = self.Signal.TwoToSix
			ent.Routes = self.Signal.Routes
			ent.Left = self.Signal.Left
			ent.BigLetter = self.Signal.BigLetter
			ent.Double = self.Signal.Double
			ent.DoubleL = self.Signal.DoubleL
			ent.Lenses = string.Explode("-",ent.LensesStr)
			ent.PassOcc = self.Signal.PassOcc
			ent.InS = nil
			ent:SendUpdate()
			for i = 1,#ent.Lenses do
				if ent.Lenses[i]:find("W") then
					ent.InS = i
				end
			end
			Metrostroi.UpdateSignalEntities()
			Metrostroi.PostSignalInitialize()
		end
		return ent
	end
end
function TOOL:SpawnSign(ply,trace,param)
	local pos = trace.HitPos

	-- Use some code from rerailer --
	local tr = Metrostroi.RerailGetTrackData(pos,ply:GetAimVector())
	if not tr then return end
	-- Create self.Sign entity
	local ent
	local found = false
	local entlist = ents.FindInSphere(pos,64)
	for k,v in pairs(entlist) do
		if v:GetClass() == "gmod_track_signs" then
			ent = v
			found = true
		end
	end
	if param == 2 then
		if not ent then return end
		self.Sign.Type = ent.SignType
		self.Sign.YOffset = ent.YOffset
		self.Sign.ZOffset = ent.ZOffset
		self.Sign.Left = ent.Left
		net.Start("metrostroi-stool-signalling")
			net.WriteUInt(1,8)
			net.WriteTable(self.Sign)
		net.Send(self:GetOwner())
	else
		if not ent then ent = ents.Create("gmod_track_signs") end
		if IsValid(ent) then
			if param ~= 2 then
				ent:SetPos(tr.centerpos - tr.up * 9.5)
				ent:SetAngles((-tr.right):Angle() + Angle(0,90,0))
			end
			if not found then
				ent:Spawn()
				-- Add to undo
				undo.Create("signalling")
					undo.AddEntity(ent)
					undo.SetPlayer(ply)
				undo.Finish()
			end
			ent.SignType = self.Sign.Type
			ent.YOffset = self.Sign.YOffset
			ent.ZOffset = self.Sign.ZOffset
			ent.Left = self.Sign.Left
			ent:SendUpdate()
		end
		return ent
	end
end
function TOOL:SpawnAutoPlate(ply,trace,param)
	local pos = trace.HitPos

	-- Use some code from rerailer --
	local tr = Metrostroi.RerailGetTrackData(pos,ply:GetAimVector())
	if not tr then return end

	local ent
	local found = false
	local entlist = ents.FindInSphere(pos,self.Auto.Type == 5 and 192 or 64)
	for k,v in pairs(entlist) do
		if v:GetClass() == "gmod_track_pa_marker" and self.Auto.Type == 5 or v:GetClass() == "gmod_track_autodrive_plate" and v.PlateType == self.Auto.Type and not v.Linked then
			ent = v
			found = true
			break
		end
	end
	if param == 2 then
		if not ent then return end
		--self.Auto.Type = ent.PlateType

		if self.Auto.Type == METROSTROI_ACOIL_DRIVE then
			self.Auto.Right = ent.Right
			self.Auto.Mode = ent.Mode
			self.Auto.StationID = ent.StationID
			self.Auto.StationPath = ent.StationPath
		elseif self.Auto.Type == METROSTROI_ACOIL_DOOR then
			self.Auto.Right = ent.Right
		elseif self.Auto.Type == 5 then
			self.Auto.PAType = ent.PAType or 1
			if self.Auto.PAType == 1 then
				self.Auto.PAStationPath			 = ent.PAStationPath
				self.Auto.PAStationID			   = ent.PAStationID
				self.Auto.PAStationName			 = ent.PAStationName
				self.Auto.PALastStation			 = ent.PALastStation
				self.Auto.PAWrongPath			   = ent.PAWrongPath
				self.Auto.PADeadlockStart		   = ent.PADeadlockStart
				self.Auto.PADeadlockEnd			 = ent.PADeadlockEnd
				self.Auto.PALineChange			  = ent.PALineChange
				self.Auto.PALineChangeStationPath   = ent.PALineChangeStationPath
				self.Auto.PALineChangeStationID	 = ent.PALineChangeStationID
				self.Auto.PALastStationName		 = ent.PALastStationName
				self.Auto.PAStationHasSwtiches	  = ent.PAStationHasSwtiches
				self.Auto.PAStationRightDoors	   = ent.PAStationRightDoors
				self.Auto.PAStationHorlift		  = ent.PAStationHorlift
			end
		elseif self.Auto.Type == METROSTROI_SBPPSENSOR and not ent.Linked then
			self.Auto.SBPPType = ent.Type
			self.Auto.SBPPDeadlock = ent.IsDeadlock
			self.Auto.SBPPStationPath = ent.StationPath
			self.Auto.SBPPStationID = ent.StationID
			self.Auto.SBPPDriveMode = ent.DriveMode
			self.Auto.SBPPRightDoors = ent.RightDoors
			self.Auto.SBPPWTime = ent.WTime
			self.Auto.SBPPRK = ent.RKPos
			self.Auto.LXp = ent.DistanceToOPV
		end
		self.Auto.LXp = ent.DistanceToOPV or ent.LXp or self.Auto.LXp
		self.Auto.LYp = ent.LYp or self.Auto.LYp
		self.Auto.LZp = ent.LZp or self.Auto.LZp
		net.Start("metrostroi-stool-signalling")
			net.WriteUInt(2,8)
			net.WriteTable(self.Auto)
		net.Send(self:GetOwner())
	else
		if self.Auto.Type ~= 5 then
			if not ent then ent = ents.Create("gmod_track_autodrive_plate") end
			if IsValid(ent) then
				local angle = (-tr.right):Angle()
				angle:RotateAroundAxis(tr.up,90)

				ent.PlateType = self.Auto.Type
				local center = (tr.centerpos - tr.up * 9.5)
				if (self.Auto.Type or 1) == METROSTROI_ACOIL_DRIVE then
					local dist = 50
					if (self.Auto.Dist or 1) == 1 then
						ent.Model = "models/metrostroi/signals/autodrive/doska5.mdl"
						dist = 5
					elseif self.Auto.Dist == 2 then
						ent.Model = "models/metrostroi/signals/autodrive/doska20.mdl"
						dist = 20
					else
						ent.Model = "models/metrostroi/signals/autodrive/doska50.mdl"
					end
					ent.Right = self.Auto.Right
					ent.Mode = self.Auto.Mode
					if self.Auto.Mode == 3 or self.Auto.Mode == 4 then
						dist = -dist/2+2.5+1.5
						ent.StationID = self.Auto.StationID
						ent.StationPath = self.Auto.StationPath
					else
						dist = 0
						ent.StationID = nil
						ent.StationPath = nil
					end

					if (self.Auto.Mode or 1) < 3 or self.Auto.Mode == 5 or 6 < self.Auto.Mode then ent.Power = true end
					if ent.Right then
						ent:SetPos(center + (tr.forward*(-(dist)/0.01905)+tr.right*-66+tr.up*5))
					else
						ent:SetPos(center + (tr.forward*(-(dist)/0.01905)+tr.right*66+tr.up*5))
					end
				elseif self.Auto.Type == METROSTROI_ACOIL_SBRAKE then
					ent.Model = "models/metrostroi/signals/autodrive/doska160.mdl"
					ent:SetPos(center + (tr.forward*(-(80+2.5+1.5+0.4)/0.01905)+tr.right*66+tr.up*5)) ---75
				elseif self.Auto.Type == METROSTROI_ACOIL_DOOR then
					ent.Model = "models/metrostroi/signals/autodrive/doska5.mdl"
					ent.Right = self.Auto.Right
					if ent.Right then
						ent:SetPos(center + (tr.forward*(-(4-2.5)/0.01905)+tr.right*66+tr.up*5))
					else
						ent:SetPos(center + (tr.forward*(-(4-2.5)/0.01905)+tr.right*-66+tr.up*5))
					end
				elseif self.Auto.Type == METROSTROI_LSENSOR then
					ent.Model = "models/mus/metro/station_marker_4.mdl"
					ent:SetPos(center + (tr.forward*(-(self.Auto.LXp or 0)/0.01905)+tr.right*((self.Auto.LYp or 0)/0.01905+120)+tr.up*((self.Auto.LZp or 0)/0.01905+130)))
					angle:RotateAroundAxis(tr.up,90)
				elseif self.Auto.Type == METROSTROI_UPPSSENSOR then
					ent.Model = "models/metrostroi/upps.mdl"
					ent:SetPos(center + (tr.forward*(-(self.Auto.LXp or 0)/0.01905)+tr.right*((self.Auto.LYp or 0)/0.01905)+tr.up*((0.8+(self.Auto.LZp or 0))/0.01905)))
					ent.DistanceToOPV = self.Auto.LXp
					ent.UPPS=true
					angle:RotateAroundAxis(tr.forward,self.Auto.Roll or 0)
				elseif self.Auto.Type == METROSTROI_SBPPSENSOR then
					ent.SBPPType = self.Auto.SBPPType or 1
					ent.IsDeadlock = ent.SBPPType<=3 and self.Auto.SBPPDeadlock
					ent.StationPath = 2<=ent.SBPPType and ent.SBPPType<=3 and tonumber(self.Auto.SBPPStationPath)
					ent.StationID = 2<=ent.SBPPType and ent.SBPPType<=3 and tonumber(self.Auto.SBPPStationID)
					ent.DriveMode = ent.SBPPType==3 and self.Auto.SBPPDriveMode
					ent.RightDoors = ent.SBPPType==3 and self.Auto.SBPPRightDoors
					ent.WTime = (ent.SBPPType==3 or ent.SBPPType>=5) and self.Auto.SBPPWTime
					ent.RKPos = ent.SBPPType==7 and self.Auto.SBPPRK
					if ent.SBPPType<=2 then ent.DistanceToOPV = self.Auto.LXp end
					ent.Model = "models/metrostroi/signals/autodrive/rfid.mdl"
					local pos
					if ent.SBPPType==1 then
						pos = center
					else
						pos = center + (tr.forward*(-(self.Auto.LXp or 0)/0.01905)+tr.right*(-80+(self.Auto.LYp or 0)/0.01905)+tr.up*(52+(self.Auto.LZp or 0)/0.01905))
					end
					angle:RotateAroundAxis(tr.up,90)
					angle:RotateAroundAxis(tr.forward,90)
					if ent.SBPPType==1 then
						local rpos = Metrostroi.GetPositionOnTrack(pos,angle)
						local res = rpos[1]
						if res then
							local tpos, tang = Metrostroi.GetTrackPosition(res.path,res.x-self.Auto.LXp*(self.Auto.LInvX and -1 or 1))
							if tpos then
								tang = tang:Angle()
								pos = tpos + (tang:Right()*(-79+(self.Auto.LYp or 0)/0.01905)*(self.Auto.LRightP and -1 or 1)+tang:Up()*(-60+(self.Auto.LZp or 0)/0.01905))

								tang:RotateAroundAxis(tang:Up(),-90)
								tang:RotateAroundAxis(tang:Right(),self.Auto.LRightP and 90 or -90)
								angle = tang
							end
						end
					elseif ent.SBPPType==3 and not ent.BrakeProps then
						ent.BrakeProps = {}
						for i=-1,1,2 do
							local entL = ents.Create("gmod_track_autodrive_plate")
							entL.Model = "models/metrostroi/signals/autodrive/rfid.mdl"
							entL:SetPos(pos + (tr.forward*(-1.5*i)/0.01905))
							entL:SetModel(ent.Model)
							entL:SetAngles(angle)
							entL:Spawn()
							entL.Linked = ent
							entL.SBPPType = ent.SBPPType
							entL.PlateType = METROSTROI_SBPPSENSOR
							table.insert(ent.BrakeProps,entL)
						end
					end
					ent:SetPos(pos)
				end
				if not ent.DistanceToOPV then ent.LXp = self.Auto.LXp end
				ent.LYp = self.Auto.LYp
				ent.LZp = self.Auto.LZp
				ent:SetModel(ent.Model)
				ent:SetAngles(angle)
			end
		else
			if not ent then ent = ents.Create("gmod_track_pa_marker") end
			if IsValid(ent) then
				local angle = (tr.forward):Angle()
				local center = (tr.centerpos - tr.up * 9.5)
				--angle:RotateAroundAxis(tr.up,90)
				ent.PAType = self.Auto.PAType
				ent.PAStationPath = tonumber(self.Auto.PAStationPath)
				ent.PAStationID = tonumber(self.Auto.PAStationID)
				ent.PAStationName = self.Auto.PAStationName
				ent.PALastStation = self.Auto.PALastStation
				ent.PAWrongPath = self.Auto.PAWrongPath
				ent.PADeadlockStart = self.Auto.PADeadlockStart
				ent.PADeadlockEnd = self.Auto.PADeadlockEnd
				ent.PALineChange = self.Auto.PALineChange
				ent.PALineChangeStationPath = self.Auto.PALineChangeStationPath
				ent.PALineChangeStationID = self.Auto.PALineChangeStationID
				ent.PALastStationName = self.Auto.PALastStationName
				ent.PAStationRightDoors = self.Auto.PAStationRightDoors
				ent.PAStationHorlift = self.Auto.PAStationHorlift
				ent.PAStationHasSwtiches = self.Auto.PAStationHasSwtiches
				ent:UpdateTrackPos(center,angle)
			end
		end
		if not found then
			ent:Spawn()
			-- Add to undo
			undo.Create("signalling")
				undo.AddEntity(ent)
				undo.SetPlayer(ply)
			undo.Finish()
		end
		return ent
	end
end
function TOOL:SpawnAutostop(ply,trace,param)
	local pos = trace.HitPos
	local tr = Metrostroi.RerailGetTrackData(trace.HitPos,ply:GetAimVector())
	if not tr then return end
	local ent
	local found = false
	local entlist = ents.FindInSphere(pos,64)
	for k,v in pairs(entlist) do
		if v:GetClass() == "gmod_track_autostop_msa" then
			ent = v
			found = true
		end
	end
	local name = ""
	local speed = 0

	if self.Autostop.Type == 1 then
		name = self.Autostop.SignalLink or ""
		speed = 0
	elseif self.Autostop.Type == 2 or self.Autostop.Type == 4 then
		name = ""
		speed = self.Autostop.MaxSpeed or 0
	end
	if param == 2 then
		if not ent then return end
		self.Autostop.SignalLink = ent.ASSignalLink
		self.Autostop.MaxSpeed = ent.ASMaxSpeed
		self.Autostop.Type = ent.ASType
		net.Start("metrostroi-stool-signalling")
			net.WriteUInt(3,8)
			net.WriteTable(self.Autostop)
		net.Send(self:GetOwner())
	else
		if not ent then ent = ents.Create("gmod_track_autostop_msa") end
		if IsValid(ent) then
			if param ~= 2 then
				ent:SetPos(tr.centerpos - tr.up * 9.5)
				ent:SetAngles((-tr.right):Angle())
			end
			if not found then
				ent:Spawn()
				undo.Create("signalling")
					undo.AddEntity(ent)
					undo.SetPlayer(ply)
				undo.Finish()
			end
			ent.ASSignalLink = name
			ent.ASMaxSpeed = speed
			ent.ASType = self.Autostop.Type
			ent:SendUpdate()
		end
		return ent
	end
end
function TOOL:SpawnKGU(ply, trace, param)
	local pos = trace.HitPos
	local tr = Metrostroi.RerailGetTrackData(trace.HitPos,ply:GetAimVector())
	if not tr then return end
    local ang = (-tr.right):Angle()
    ang:RotateAroundAxis(ang:Up(), 90)
	local ent
	local found = false
	local entlist = ents.FindInSphere(pos,64)
	for k,v in pairs(entlist) do
		if v:GetClass() == "gmod_track_kgu_msa" then
			ent = v
			found = true
		end
	end
	if param == 2 then
		if not ent then return end
		self.KGU.SignalLink = ent.KGUSignalLink
		self.KGU.Lense = ent.KGULense
		net.Start("metrostroi-stool-signalling")
			net.WriteUInt(4,8)
			net.WriteTable(self.KGU)
		net.Send(self:GetOwner())
	else
		if not ent then ent = ents.Create("gmod_track_kgu_msa") end
		if IsValid(ent) then
			if param ~= 2 then
				ent:SetPos(tr.centerpos - tr.up * 9.5)
				ent:SetAngles(ang)
			end
			if not found then
				ent:Spawn()
				undo.Create("signalling")
					undo.AddEntity(ent)
					undo.SetPlayer(ply)
				undo.Finish()
			end
			ent.KGUSignalLink = self.KGU.SignalLink
			ent.KGULense = self.KGU.Lense
			ent:SendUpdate()
		end
		return ent
	end
end
function TOOL:LeftClick(trace)
	if CLIENT then
		return true
	end

	--self.Signal = util.JSONToTable(self:GetClientInfo("signaldata"):replace("''","\""))
	--if not self.Signal then return end
	local ply = self:GetOwner()
	if (ply:IsValid()) and (not ply:IsAdmin()) then return false end
	if not trace then return false end
	if trace.Entity and trace.Entity:IsPlayer() then return false end

	local ent
	if self.Type == 1 then
		ent = self:SpawnSignal(ply,trace)
	elseif self.Type == 2 then
		ent = self:SpawnSign(ply,trace)
	elseif self.Type == 3 then
		ent = self:SpawnAutoPlate(ply,trace)
	elseif self.Type == 4 then
		ent = self:SpawnAutostop(ply,trace)
	elseif self.Type == 5 then
		ent = self:SpawnKGU(ply,trace)
	end

	return true
end

function TOOL:RightClick(trace)
	if CLIENT then
		return true
	end

	local ply = self:GetOwner()
	if (ply:IsValid()) and (not ply:IsAdmin()) then return false end
	if not trace then return false end
	if trace.Entity and trace.Entity:IsPlayer() then return false end

	local entlist = ents.FindInSphere(trace.HitPos,(self.Type == 3 and self.Auto.Type == 5) and 192 or 64)
	for k,v in pairs(entlist) do
		if v:GetClass() == "gmod_track_signal" and self.Type == 1 then
			if IsValid(v) then SafeRemoveEntity(v) end
		end
		if v:GetClass() == "gmod_track_switch" then
			if IsValid(v) then SafeRemoveEntity(v) end
		end
		if v:GetClass() == "gmod_track_signs" and self.Type == 2 then
			if IsValid(v) then SafeRemoveEntity(v) end
		end
		if v:GetClass() == "gmod_track_autodrive_plate" and self.Type == 3 and self.Auto.Type == v.PlateType then
			if IsValid(v) then SafeRemoveEntity(v) end
		end
		if v:GetClass() == "gmod_track_pa_marker" and self.Type == 3 and self.Auto.Type == 5 then
			if IsValid(v) then SafeRemoveEntity(v) end
		end
		if v:GetClass() == "gmod_track_autostop_msa" and self.Type == 4 then
			if IsValid(v) then SafeRemoveEntity(v) end
		end
		if v:GetClass() == "gmod_track_kgu_msa" and self.Type == 5 then
			if IsValid(v) then SafeRemoveEntity(v) end
		end
	end

	return true
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	--self.Signal = util.JSONToTable(self:GetClientInfo("signaldata"):replace("''","\""))

	local ply = self:GetOwner()
	--if not (ply:IsValid()) and (not ply:IsAdmin()) then return false end
	if not trace then return false end
	if trace.Entity and trace.Entity:IsPlayer() then return false end
	local ent

	if self.Type == 1 then
		ent = self:SpawnSignal(ply,trace,2)
	elseif self.Type == 2 then
		ent = self:SpawnSign(ply,trace,2)
	elseif self.Type == 3 then
		ent = self:SpawnAutoPlate(ply,trace,2)
	elseif self.Type == 4 then
		ent = self:SpawnAutostop(ply,trace,2)
	elseif self.Type == 5 then
		ent = self:SpawnKGU(ply,trace,2)
	end
	return true
end

function TOOL:SendSettings()
	if self.Type == 1 then
		if not self.Signal then return end
		RunConsoleCommand("signalling_signaldata",util.TableToJSON(self.Signal))
		net.Start "metrostroi-stool-signalling"
			net.WriteUInt(0,8)
			--net.WriteEntity(self)
			net.WriteTable(self.Signal)
		net.SendToServer()

	elseif self.Type == 2 then
		if not self.Sign then return end
		RunConsoleCommand("signalling_signdata",util.TableToJSON(self.Sign))
		net.Start "metrostroi-stool-signalling"
			net.WriteUInt(1,8)
			--net.WriteEntity(self)
			net.WriteTable(self.Sign)
		net.SendToServer()
	elseif self.Type == 3 then
		if not self.Auto then return end
		RunConsoleCommand("signalling_autodata",util.TableToJSON(self.Auto))
		net.Start "metrostroi-stool-signalling"
			net.WriteUInt(2,8)
			--net.WriteEntity(self)
			net.WriteTable(self.Auto)
		net.SendToServer()
	elseif self.Type == 4 then
		if not self.Autostop then return end
		RunConsoleCommand("signalling_autostopdata",util.TableToJSON(self.Autostop))
		net.Start "metrostroi-stool-signalling"
			net.WriteUInt(3,8)
			--net.WriteEntity(self)
			net.WriteTable(self.Autostop)
		net.SendToServer()
	elseif self.Type == 5 then
		if not self.KGU then return end
		RunConsoleCommand("signalling_kgudata",util.TableToJSON(self.KGU))
		net.Start "metrostroi-stool-signalling"
			net.WriteUInt(4,8)
			net.WriteTable(self.KGU)
		net.SendToServer()
	end
end

net.Receive("metrostroi-stool-signalling", function(_, ply)
	local TOOL = LocalPlayer and LocalPlayer():GetTool("signalling") or ply:GetTool("signalling")
	local typ = net.ReadUInt(8)
	if typ == 4 then
		TOOL.KGU = net.ReadTable()
		if CLIENT then
			RunConsoleCommand("signalling_kgudata",util.TableToJSON(TOOL.KGU))
			NeedUpdate = true
		end
	elseif typ == 3 then
		TOOL.Autostop = net.ReadTable()
		if CLIENT then
			RunConsoleCommand("signalling_autostopdata",util.TableToJSON(TOOL.Autostop))
			NeedUpdate = true
		end
	elseif typ == 2 then
		TOOL.Auto = net.ReadTable()
		if CLIENT then
			RunConsoleCommand("signalling_signdata",util.TableToJSON(TOOL.Auto))
			NeedUpdate = true
		end
	elseif typ == 1 then
		TOOL.Sign = net.ReadTable()
		if CLIENT then
			RunConsoleCommand("signalling_signdata",util.TableToJSON(TOOL.Sign))
			NeedUpdate = true
		end
	elseif typ == 0 then
		TOOL.Signal = net.ReadTable()
		if CLIENT then
			RunConsoleCommand("signalling_signaldata",util.TableToJSON(TOOL.Signal))
			NeedUpdate = true
		end
	end
	TOOL.Type = typ+1
end)

--||==========================================================||
--||==========================================================||
--||==========================================================||
--||Начало для signalling tool.								  ||
--||==========================================================||
--||==========================================================||
--||==========================================================||

function TOOL:BuildCPanelCustom()
	local tool = self
	local CPanel = controlpanel.Get("signalling")
	if not CPanel then return end
	--("signalling_signaldata",util.TableToJSON(tool.Signal))
	--tool.Type = GetConVarNumber("signalling_type") or 1
	tool.RouteType = GetConVarNumber("signalling_routetype") or 1
	CPanel:ClearControls()
	CPanel:SetPadding(0)
	CPanel:SetSpacing(0)
	CPanel:Dock( FILL )
	local VType = vgui.Create("DComboBox")
	VType:ChooseOption(Type_Signals[tool.Type],tool.Type)
	VType:SetColor(color_black)
	for i = 1,#Type_Signals do
		VType:AddChoice(Type_Signals[i])
	end
	VType.OnSelect = function(_, index, name)
		VType:SetValue(name)
		tool.Type = index
		tool:SendSettings()
		tool:BuildCPanelCustom()
	end
	CPanel:AddItem(VType)
	if tool.Type == 1 then
		local VSType = vgui.Create("DComboBox")
			local signalType = tool.Signal.Type
			VSType:SetColor(color_black)
			for i = 1,#Type_Signal do
				VSType:AddChoice(Type_Signal[i][1], Type_Signal[i][2])
				if Type_Signal[i][2] == signalType then
					VSType:ChooseOption(Type_Signal[i][1], i)
				end
			end
			if not signalType or signalType == 0 then
				VSType:SetText(Select_Signals)
			end
			VSType.OnSelect = function(_, index, name)
				tool.Signal.Type = index
				tool:SendSettings()
				tool:BuildCPanelCustom()
			end
		CPanel:AddItem(VSType)
		if not signalType or signalType == 0 then
			return 
		end
		local VNameT,VNameN = CPanel:TextEntry(Signals_Name)
				VNameT:SetTooltip(Signals_Name_Des)
				VNameT:SetValue(tool.Signal.Name or "")
				VNameT:SetEnterAllowed(false)
				function VNameT:OnChange()
					local oldval = self:GetValue()
					local pos = self:GetCaretPos()
					local NewValue = ""
					local NewValue = oldval:gsub("[^%w%s/]", "")
					NewValue = NewValue:gsub("[A-Za-z]", function(c)
						return c:match("[isIS]") and c or c:upper()
					end)
					self:SetText(NewValue)
					self:SetCaretPos(pos < #NewValue and pos or #NewValue)
				end
				function VNameT:OnLoseFocus()
					tool.Signal.Name = self:GetValue()
					tool:SendSettings()
				end
		if not tool.Signal.ARSOnly then
			local VLensT,VLensN = CPanel:TextEntry(Lenses)
				VLensT:SetTooltip(Lenses_Des)
				VLensT:SetValue(tool.Signal.Lenses or "")
				VLensT:SetEnterAllowed(false)
				function VLensT:OnChange()
					local NewValue = ""
					if tool.Signal.Type == 4 or tool.Signal.Type == 7 then
						for i = 1,#self:GetValue() do
							NewValue = NewValue..((self:GetValue()[i] or ""):upper():match("[RYGWBX-]") or "")
						end
						local NewValueT = string.Explode("-",NewValue)
						local maxval = 3
						for id,text in ipairs(NewValueT) do
							if id > 2 then
								break
							end
							text = text:match("[RYGWBX]+") or ""
							NewValueT[id] = text:sub(1,maxval)
						end
						local NewValue = table.concat(NewValueT,"-")
						self:SetText(NewValue)
						self:SetCaretPos(#NewValue)
					else
						for i = 1,#self:GetValue() do
							NewValue = NewValue..((self:GetValue()[i] or ""):upper():match("[RYGWBMX-]") or "")
						end
						local NewValueT = string.Explode("-",NewValue)
						local maxval = tool.Signal.Type == 3 and 4 or (tool.Signal.Type == 6 and 6 or 3)
						for id,text in ipairs(NewValueT) do
							if id > 4 then
								for i = 5,#NewValueT do
									table.remove(NewValueT,i)
								end
								break
							end
							if text:find("M") then
								if text[1] == "M" then
									NewValueT[id] = "M"
								elseif tool.Signal.Type == 6 then
									id = id + id + 1
									NewValueT[id] = "M"
								else
									NewValueT[id] = text:gsub("M","")
									id = id + 1
									NewValueT[id] = "M"
								end
								for i = id+1,#NewValueT do
									table.remove(NewValueT, i)
								end
								break
							end
							text = text:match("[RYGWBX]+") or ""
							NewValueT[id] = text:sub(1,maxval)
							if #text > maxval then
								NewValueT[#NewValueT+1] = text:sub(maxval+1,#text)
							end
						end
						local NewValue = table.concat(NewValueT,"-")
						self:SetText(NewValue)
						self:SetCaretPos(#NewValue)
					end
				end
				function VLensT:OnLoseFocus()
					tool.Signal.Lenses = self:GetValue()
					tool:SendSettings()
				end
		end
		if tool.Signal.Type != 4 and tool.Signal.Type != 7 then
			local VBoxNameT,VBoxNameN = CPanel:TextEntry(RC_Number)
				VBoxNameT:SetTooltip(RC_Number_Des)
				VBoxNameT:SetValue(tool.Signal.BoxName or "")
				VBoxNameT:SetEnterAllowed(false)
				function VBoxNameT:OnChange()
					local oldval = self:GetValue()
					local pos = self:GetCaretPos()
					local NewValue = ""
					for i = 1,5 do
						NewValue = NewValue..((oldval[i] or ""):upper():match("^[%u%d%s]+") or "")
					end
					self:SetText(NewValue)
					self:SetCaretPos(pos < #NewValue and pos or #NewValue)
				end
				function VBoxNameT:OnLoseFocus()
					tool.Signal.BoxName = self:GetValue()
					tool:SendSettings()
				end
			local VBoxNameStartT,VBoxNameStartN = CPanel:TextEntry(RC_Number_Start)
				VBoxNameStartT:SetTooltip(RC_Number_Start_Des)
				VBoxNameStartT:SetValue(tool.Signal.BoxNameStart or "")
				VBoxNameStartT:SetEnterAllowed(false)
				function VBoxNameStartT:OnChange()
					local oldval = self:GetValue()
					local pos = self:GetCaretPos()
					local NewValue = ""
					for i = 1,5 do
						NewValue = NewValue..((oldval[i] or ""):upper():match("^[%u%d%s]+") or "")
					end
					self:SetText(NewValue)
					self:SetCaretPos(pos < #NewValue and pos or #NewValue)
				end
				function VBoxNameStartT:OnLoseFocus()
					tool.Signal.BoxNameStart = self:GetValue()
					tool:SendSettings()
				end
		else
			tool.Signal.BoxName = ""
			tool.Signal.BoxNameStart = ""
			tool:SendSettings()
		end
		if tool.Signal.Type == 1 then
			local VRoutT,VRoutN = CPanel:TextEntry(Custom_Route_Number)
				VRoutT:SetTooltip(CRN_Des)
				VRoutT:SetValue(tool.Signal.RouteNumberSetup or "")
				VRoutT:SetEnterAllowed(false)
				function VRoutT:OnChange()
					local oldval = self:GetValue()
					local NewValue = oldval:match("[1-4DABVGEIKMNPWFLRXQZdabvgeikmnpwflrxqz]+") or ""
					NewValue = NewValue:gsub("[A-Za-z]", function(c)
						return c:match("[DKdk]") and c or c:upper()
					end)
					local oldpos = self:GetCaretPos()
					self:SetText(NewValue:sub(1,5))
					self:SetCaretPos(math.min(5,oldpos))
				end
				function VRoutT:OnLoseFocus()
					tool.Signal.RouteNumberSetup = self:GetValue()
					tool:SendSettings()
				end
		end
		
		local VLeftC = CPanel:CheckBox(Left)
			VLeftC:SetTooltip(Left_Des)
			VLeftC:SetValue(tool.Signal.Left or false)
			function VLeftC:OnChange()
				tool.Signal.Left = self:GetChecked()
				tool:SendSettings()
				tool:BuildCPanelCustom()
			end
		local VDoubleC = CPanel:CheckBox(Double_Side)
		if tool.Signal.Double then
			local VDoubleLC = CPanel:CheckBox(Double_Light)
				VDoubleLC:SetTooltip(Double_Light_Des)
				VDoubleLC:SetValue(tool.Signal.DoubleL or false)
				function VDoubleLC:OnChange()
					tool.Signal.DoubleL = self:GetChecked() and tool.Signal.Double
					self:SetChecked(tool.Signal.DoubleL)
					tool:SendSettings()
					tool:BuildCPanelCustom()
				end
		end
		VDoubleC:SetTooltip(Double_Side_Des)
		VDoubleC:SetValue(tool.Signal.Double or false)
		function VDoubleC:OnChange()
			tool.Signal.Double = self:GetChecked()
			tool.Signal.DoubleL = tool.Signal.DoubleL and self:GetChecked()
			tool:BuildCPanelCustom()
			--if tool.Signal.Double then VDoubleLC:SetChecked(tool.Signal.DoubleL and tool.Signal.Double) end
			tool:SendSettings()
		end
		if tool.Signal.Type != 4 and tool.Signal.Type != 7 then
			local VARSOC = CPanel:CheckBox(ARSO)
				VARSOC:SetTooltip(ARSO_Des)
				VARSOC:SetValue(tool.Signal.ARSOnly or false)
				function VARSOC:OnChange()
					tool.Signal.ARSOnly = self:GetChecked()
					tool:SendSettings()
					tool:BuildCPanelCustom()
				end
		else
			if tool.Signal.ARSOnly then
				tool.Signal.ARSOnly = false
				tool:SendSettings()
			end
		end
		local VAuStC = CPanel:CheckBox(Autostop)
			VAuStC:SetTooltip(Autostop_Des)
			if tool.Signal.NonAutoStop ~= nil then
				VAuStC:SetValue(not tool.Signal.NonAutoStop)
			else
				VAuStC:SetValue(true)
			end
			function VAuStC:OnChange()
				tool.Signal.NonAutoStop = not self:GetChecked()
				tool:SendSettings()
			end
		local VDepC = CPanel:CheckBox(TandS)
			VDepC:SetTooltip(TandS_Des)
			VDepC:SetValue(tool.Signal.TwoToSix or false)
			function VDepC:OnChange()
				tool.Signal.TwoToSix = self:GetChecked()
				tool:SendSettings()
				tool:BuildCPanelCustom()
			end
		if tool.Signal.TwoToSix then
			local VRSHz = CPanel:CheckBox(MSK_325Hz_Gen)
				VRSHz:SetTooltip(MSK_325Hz_Des)
				VRSHz:SetValue(tool.Signal.RS_325Hz or false)
				function VRSHz:OnChange()
					tool.Signal.RS_325Hz = self:GetChecked()
					tool:SendSettings()
				end
		else
			tool.Signal.RS_325Hz = false
		end
		local VSPBHz = CPanel:CheckBox(SPB_325Hz_Gen)
			VSPBHz:SetTooltip(SPB_325Hz_Des)
			VSPBHz:SetValue(tool.Signal.SPB_325Hz or false)
			function VSPBHz:OnChange()
				tool.Signal.SPB_325Hz = self:GetChecked()
				tool:SendSettings()
			end
		local VPassOccC = CPanel:CheckBox(POS)
			VPassOccC:SetTooltip(POS_Des)
			VPassOccC:SetValue(tool.Signal.PassOcc or false)
			function VPassOccC:OnChange()
				tool.Signal.PassOcc = self:GetChecked()
				tool:SendSettings()
			end
		local VRouteUnusedC = CPanel:CheckBox(Route_Unused)
			VRouteUnusedC:SetTooltip(Route_Unused_Des)
			VRouteUnusedC:SetValue(tool.Signal.RouteUnused or false)
			function VRouteUnusedC:OnChange()
				tool.Signal.RouteUnused = self:GetChecked()
				tool:SendSettings()
			end
		local AddCustom = CPanel:Button(VisualSignals)
			local function UpdateButtonVisuals() AddCustom:SetText(VisualSignals) end
			UpdateButtonVisuals(AddCustom, tool.Signal.Add_Custom)
			AddCustom.DoClick = function(self)
				tool.Signal.Add_Custom = not tool.Signal.Add_Custom
				tool:SendSettings()
				UpdateButtonVisuals(self, tool.Signal.Add_Custom)
				tool:BuildCPanelCustom()
			end
		if tool.Signal.Add_Custom == true then
			local VBigLC = CPanel:CheckBox(Big_Letter)
				VBigLC:SetTooltip(Big_Letter_Des)
				VBigLC:SetValue(tool.Signal.BigLetter or false)
				function VBigLC:OnChange()
					tool.Signal.BigLetter = self:GetChecked()
					tool:SendSettings()
					tool:BuildCPanelCustom()
				end
			local VStationTrackC = CPanel:CheckBox(RC_ST_Number)
				VStationTrackC:SetTooltip(RC_ST_Number_Des)
				VStationTrackC:SetValue(tool.Signal.StationTrack or false)
				function VStationTrackC:OnChange()
					tool.Signal.StationTrack = self:GetChecked()
					tool:SendSettings()
					tool:BuildCPanelCustom()
				end
		end

		self.RouteListHeight = self.RouteListHeight or 75
		local RouteList
		local HeightChoice = vgui.Create("DComboBox")
		HeightChoice:SetValue(High_Table .. self.RouteListHeight)
		HeightChoice:AddChoice(High_Table.."075", 75)
		HeightChoice:AddChoice(High_Table.."100", 100)
		HeightChoice:AddChoice(High_Table.."150", 150)
		HeightChoice:AddChoice(High_Table.."250", 250)

		HeightChoice.OnSelect = function(_, index, name, data)
			self.RouteListHeight = data
			if ValidPanel(RouteList) then
				RouteList:SetTall(data)
				CPanel:InvalidateLayout(true)
				CPanel:GetParent():InvalidateLayout(true) 
			end
		end
		CPanel:AddItem(HeightChoice)
		self.SelectedRoute = self.SelectedRoute or 1
		RouteList = vgui.Create("DListView")
		RouteList:SetTall(self.RouteListHeight)
		RouteList:SetMultiSelect(false)
		RouteList:AddColumn("№"):SetFixedWidth(25)
		RouteList:AddColumn(Routes_Table)
		RouteList:AddColumn(Types_Table)
		local function FillRouteList()
			RouteList:Clear()
			if not tool.Signal.Routes then return end
			for k, v in ipairs(tool.Signal.Routes) do
				local typeName = Type_Signal_Route[v.Manual and 2 or v.Repeater and 3 or v.Emer and 4 or 1]
				RouteList:AddLine(k, v.RouteName or "", typeName)
			end
			if tool.Signal.Routes[self.SelectedRoute] then
				local line = RouteList:GetLine(self.SelectedRoute)
				if line then RouteList:SelectItem(line) end
			end
		end
		FillRouteList()
		RouteList.OnRowSelected = function(_, index)
			if self.SelectedRoute == index then return end
			self.SelectedRoute = index
			self:BuildCPanelCustom()
		end
		CPanel:AddItem(RouteList)

		local ControlBtnPnl = vgui.Create("DPanel")
		ControlBtnPnl:SetTall(25)
		local btnUp = vgui.Create("DButton", ControlBtnPnl)
			btnUp:SetText("▲")
			btnUp:Dock(LEFT)
			btnUp:SetWide(20)
			btnUp.DoClick = function()
				local idx = self.SelectedRoute
				if idx > 1 then
					local row = table.remove(tool.Signal.Routes, idx)
					table.insert(tool.Signal.Routes, idx - 1, row)
					self.SelectedRoute = idx - 1
					tool:SendSettings()
					self:BuildCPanelCustom()
				end
			end
		local btnCopy = vgui.Create("DButton", ControlBtnPnl)
			btnCopy:SetText("")
			btnCopy:SetIcon("icon16/page_copy.png")
			btnCopy:Dock(LEFT)
			btnCopy:DockMargin(1, 0, 0, 0)
			btnCopy:SetWide(25)
			btnCopy:SetTextColor(Color(0, 0, 0))
			btnCopy.DoClick = function()
				if #tool.Signal.Routes != 0 then
					local idx = self.SelectedRoute
					local sourceRoute = tool.Signal.Routes[idx]
					if sourceRoute then
						local newData = table.Copy(sourceRoute)
						local insertAt = idx + 1
						table.insert(tool.Signal.Routes, insertAt, newData)
						self.SelectedRoute = insertAt
						tool:SendSettings()
						self:BuildCPanelCustom()
					end
				end
			end
		local btnDown = vgui.Create("DButton", ControlBtnPnl)
			btnDown:SetText("▼")
			btnDown:Dock(LEFT)
			btnDown:DockMargin(1, 0, 0, 0)
			btnDown:SetWide(20)
			btnDown.DoClick = function()
				local idx = self.SelectedRoute
				if idx < #tool.Signal.Routes then
					local row = table.remove(tool.Signal.Routes, idx)
					table.insert(tool.Signal.Routes, idx + 1, row)
					self.SelectedRoute = idx + 1
					tool:SendSettings()
					self:BuildCPanelCustom()
				end
			end
		local btnDel = vgui.Create("DButton", ControlBtnPnl)
			btnDel:SetText(Remove_Route)
			btnDel:Dock(RIGHT)
			btnDel:SetWide(75)
			btnDel:SetTextColor(Color(200, 0, 0))
			btnDel.DoClick = function()
				if tool.Signal.Routes[self.SelectedRoute] then
					table.remove(tool.Signal.Routes, self.SelectedRoute)
					self.SelectedRoute = math.max(1, math.min(self.SelectedRoute, #tool.Signal.Routes))
					if #tool.Signal.Routes == 0 then self.SelectedRoute = 1 end
					tool:SendSettings()
					self:BuildCPanelCustom()
				end
			end
		local btnAdd = vgui.Create("DButton", ControlBtnPnl)
			btnAdd:SetText(Add_Route)
			btnAdd:Dock(RIGHT)
			btnAdd:DockMargin(0, 0, 1, 0)
			btnAdd:SetWide(75)
			btnAdd:SetTextColor(Color(0, 120, 0))
			btnAdd.DoClick = function()
				if not tool.Signal.Routes then tool.Signal.Routes = {} end
				local insertAt = #tool.Signal.Routes == 0 and 1 or (self.SelectedRoute + 1)
				table.insert(tool.Signal.Routes, insertAt, {
					Manual = tool.RouteType == 2,
					Repeater = tool.RouteType == 3,
					Emer = tool.RouteType == 4,
				})
				self.SelectedRoute = insertAt
				tool:SendSettings()
				self:BuildCPanelCustom()
			end
		CPanel:AddItem(ControlBtnPnl)
		local i = self.SelectedRoute
		if tool.Signal.Routes and tool.Signal.Routes[i] then
			local routeData = tool.Signal.Routes[i]
			local CollCat = vgui.Create("DForm")
			local rou = routeData.Manual and 2 or routeData.Repeater and 3 or routeData.Emer and 4 or 1
			CollCat:SetLabel((Type_Signal_Route[rou]) .. " #" .. i)
			CollCat:SetExpanded(true)
			local VTypeOfRouteI = vgui.Create("DComboBox")
			VTypeOfRouteI:ChooseOption(Type_Signal_Route[rou], rou)
			for i1 = 1, #Type_Signal_Route do
				VTypeOfRouteI:AddChoice(Type_Signal_Route[i1])
			end
			VTypeOfRouteI.OnSelect = function(_, index, name)
				routeData.Manual = index == 2
				routeData.Repeater = index == 3
				routeData.Emer = index == 4
				tool:SendSettings()
				self:BuildCPanelCustom()
			end
			CollCat:AddItem(VTypeOfRouteI)
			--Маршрут
			local VRNT, VRNN = CollCat:TextEntry(Routes)
				VRNT:SetTooltip(Routes_Des)
				VRNT:SetUpdateOnType(true)
				VRNT:SetText(routeData.RouteName or "")
				VRNT.OnValueChange = function(s, val)
					routeData.RouteName = val
					FillRouteList()
					tool:SendSettings()
				end
			--Следующий светофор
			local VNexT, VNexN = CollCat:TextEntry(NextSig)
				VNexT:SetTooltip(NextSig_Des)
				VNexT:SetUpdateOnType(true)
				VNexT:SetText(routeData.NextSignal or "")
				VNexT.OnValueChange = function(s, val)
					local pos = s:GetCaretPos()
					local NewValue = val:gsub("[^%w%s*/]", ""):gsub("[A-Za-z]", function(c)
						return c:match("[isIS]") and c or c:upper()
					end)
					routeData.NextSignal = NewValue
					if val != NewValue then
						s:SetText(NewValue)
						s:SetCaretPos(math.min(pos, #NewValue))
					end
					tool:SendSettings()
				end
			--Линзы
			if not tool.Signal.ARSOnly then
				local VLighT, VLighN = CollCat:TextEntry(Lenses_Route)
					VLighT:SetTooltip(Lenses_Route_Des)
					VLighT:SetUpdateOnType(true)
					VLighT:SetText(routeData.Lights or "")
					VLighT.OnValueChange = function(s, val)
						local NewValue = val:gsub("[^%d%-b]", "")
						routeData.Lights = NewValue
						if val != NewValue then s:SetText(NewValue) end
						tool:SendSettings()
					end
			end
			--АРС
			if not routeData.Repeater then
				local VARST, VARSN = CollCat:TextEntry(ARSC)
					VARST:SetTooltip(ARSC_Des)
					VARST:SetUpdateOnType(true)
					VARST:SetText(routeData.ARSCodes or "")
					VARST.OnValueChange = function(s, val)
						local NewValue = val:gsub("[^0124678]", "")
						routeData.ARSCodes = NewValue
						if val ~= NewValue then
							local pos = s:GetCaretPos()
							s:SetText(NewValue)
							s:SetCaretPos(math.min(pos, #NewValue)) 
						end
						tool:SendSettings()
					end
			end
			--Стрелки
			local VSwiT, VSwiN = CollCat:TextEntry(Switches)
				VSwiT:SetTooltip(Switches_Des)
				VSwiT:SetUpdateOnType(true)
				VSwiT:SetText(routeData.Switches or "")
				VSwiT.OnValueChange = function(s, val)
					routeData.Switches = val
					tool:SendSettings()
				end
			--Включение МУ
			local VEnRouC = CollCat:CheckBox(Enable_RN)
				VEnRouC:SetTooltip(Enable_RN_Des)
				VEnRouC:SetValue(routeData.EnRou or false)
				VEnRouC.OnChange = function(s, val)
					routeData.EnRou = val
					tool:SendSettings()
				end
			--Буква для МУ
			local VIndicT = CollCat:TextEntry(En_Routes)
				VIndicT:SetTooltip(En_Routes_Des)
				VIndicT:SetUpdateOnType(true)
				VIndicT:SetText(routeData.Ind or "")
				VIndicT.OnValueChange = function(s, val)
					local pos = s:GetCaretPos()
					local NewValue = val:match("[0-9DABVGEIKMNPWFLRXQZdabvgeikmnpwflrxqz]+") or ""
					NewValue = NewValue:gsub("[A-Za-z]", function(c)
						return c:match("[Dd]") and c or c:upper()
					end):sub(1, 2)
					routeData.Ind = NewValue
					if val != NewValue then
						s:SetText(NewValue)
						s:SetCaretPos(math.min(2, pos))
					end
					tool:SendSettings()
				end
			--Контрольный сигнал
			local VSigLink = CollCat:TextEntry(En_Routes_SigLink)
				VSigLink:SetTooltip(En_Routes_SigLink_Des)
				VSigLink:SetUpdateOnType(true)
				VSigLink:SetText(routeData.NSRou or "")
				VSigLink:SetTooltip(En_Routes_SigLink_Des)
				VSigLink.OnValueChange = function(s, val)
					local pos = s:GetCaretPos()
					local NewValue = val:gsub("[^%w%s/]", ""):gsub("[A-Za-z]", function(c)
						return c:match("[isIS]") and c or c:upper()
					end)
					routeData.NSRou = NewValue
					if val != NewValue then
						s:SetText(NewValue)
						s:SetCaretPos(pos)
					end
					tool:SendSettings()
				end
			--скрытие DRS
			--[[local VRouteVisible = CollCat:CheckBox(Enable_RV)
				VRouteVisible:SetTooltip(Enable_RV_Des)
				VRouteVisible:SetValue(tool.Signal.Routes[i].RVisible or false)
				function VRouteVisible:OnChange()
					tool.Signal.Routes[i].RVisible = self:GetChecked()
					tool:SendSettings()
				end]]--
			CPanel:AddItem(CollCat)
		end
	elseif tool.Type == 2 then
        local currentSignID = (tool.Sign.Type or 1) - 1
		local function FindSignInfo(targetID)
			for catID, subTable in pairs(Type_Signs_Choice) do
				for _, signData in ipairs(subTable) do
					if signData[2] == targetID then
						return catID, signData[1]
					end
				end
			end
			return nil, nil
		end
		local foundCatID, foundSignName = FindSignInfo(currentSignID)
		local VCatType = vgui.Create("DComboBox")
		local catName = Type_Signs[foundCatID] or Type_Signs[0]
		VCatType:SetValue(catName) 
		for i = 1, #Type_Signs do
			VCatType:AddChoice(Type_Signs[i], i)
		end
		CPanel:AddItem(VCatType)
		local VSType = vgui.Create("DComboBox")
		VSType:SetColor(color_black)
		CPanel:AddItem(VSType)
		local VYOffT = CPanel:NumSlider(Y_Off, nil, -100, 100, 0)
		VYOffT:SetValue(tool.Sign.YOffset or 0)
		VYOffT:SetVisible(false)
		VYOffT.OnValueChanged = function(num)
			tool.Sign.YOffset = VYOffT:GetValue()
			tool:SendSettings()
		end
		local VZOffT = CPanel:NumSlider(Z_Off, nil, -50, 50, 0)
		VZOffT:SetValue(tool.Sign.ZOffset or 0)
		VZOffT:SetVisible(false)
		VZOffT.OnValueChanged = function(num)
			tool.Sign.ZOffset = VZOffT:GetValue()
			tool:SendSettings()
		end

		local VLeftOC = CPanel:CheckBox(Left_Signs)
		VLeftOC:SetTooltip(Left_Signs_Des)
		VLeftOC:SetValue(tool.Sign.Left or false)
		VLeftOC:SetVisible(false)
		function VLeftOC:OnChange()
			tool.Sign.Left = self:GetChecked()
			tool:SendSettings()
		end
		local function FillSignChoices(catID, selectedSignID)
			VSType:Clear()
			VSType:SetValue(Select_Signs)
			local subTable = Type_Signs_Choice[catID]
			if subTable then
				for i = 1, #subTable do
					VSType:AddChoice(subTable[i][1], subTable[i][2])
				end
			end
			if selectedSignID then
				for i = 1, #subTable do
					if subTable[i][2] == selectedSignID then
						VSType:SetValue(subTable[i][1])
						VYOffT:SetVisible(true)
						VZOffT:SetVisible(true)
						VLeftOC:SetVisible(true)
						break
					end
				end
			end
		end
		if foundCatID then
			FillSignChoices(foundCatID, currentSignID)
		end
		VCatType.OnSelect = function(_, index, name, data)
			VYOffT:SetVisible(false)
			VZOffT:SetVisible(false)
			VLeftOC:SetVisible(false)
			FillSignChoices(data, nil)
		end
		VSType.OnSelect = function(_, index, name, realID)
			tool.Sign.Type = realID + 1
			tool:SendSettings()
			VYOffT:SetVisible(true)
			VZOffT:SetVisible(true)
			VLeftOC:SetVisible(true)
		end
	elseif tool.Type == 3 then
		local VAType = vgui.Create("DComboBox")
		VAType:ChooseOption(Type_PAM[tool.Auto.Type or 1],tool.Auto.Type or 1)
		VAType:SetColor(color_black)
		for i = 1,#Type_PAM do
			VAType:AddChoice(Type_PAM[i])
		end
		VAType.OnSelect = function(_, index, name)
			VAType:SetValue(name)
			tool.Auto.Type = index
			tool:SendSettings()
			tool:BuildCPanelCustom()
		end
		CPanel:AddItem(VAType)
		if tool.Auto.Type == METROSTROI_ACOIL_DOOR then
			local VRightOC = CPanel:CheckBox(OT_RD)
			VRightOC:SetValue(tool.Auto.Right or false)
			function VRightOC:OnChange()
				tool.Auto.Right = self:GetChecked()
				tool:SendSettings()
			end
		end
		if tool.Auto.Type == 4 or tool.Auto.Type == 6 or tool.Auto.Type == 7 then
			local VLXpT = CPanel:NumSlider(X_Off,nil,0,200,2)
			VLXpT:SetValue(tool.Auto.LXp or 0)
			VLXpT.OnValueChanged = function(num)
				tool.Auto.LXp = VLXpT:GetValue()
				tool:SendSettings()
			end
		end
		if tool.Auto.Type ~= 5 then
			local VLYpT = CPanel:NumSlider(Y_Off,nil,-10,10,2)
			VLYpT:SetValue(tool.Auto.LYp or 0)
			VLYpT.OnValueChanged = function(num)
				tool.Auto.LYp = VLYpT:GetValue()
				tool:SendSettings()
			end
			local VLZpT = CPanel:NumSlider(Z_Off,nil,-10,10,2)
			VLZpT:SetValue(tool.Auto.LZp or 0)
			VLZpT.OnValueChanged = function(num)
				tool.Auto.LZp = VLZpT:GetValue()
				tool:SendSettings()
			end
		end
		if tool.Auto.Type == 5 then
			local VAPAType = vgui.Create("DComboBox")
			CPanel:AddItem(VAPAType)
			VAPAType:SetColor(color_black)
			VAPAType:AddChoice(OT_OPV)
			VAPAType:ChooseOptionID(tool.Auto.PAType or 1)
			VAPAType.OnSelect = function(_, index, name)
				VAPAType:SetValue(name)
				tool.Auto.PAType = index
				tool:SendSettings()
				tool:BuildCPanelCustom()
			end
			if tool.Auto.PAType == 1 then
				local SPath = CPanel:TextEntry(OT_STT)
				SPath:SetTooltip(OT_STT_Des)
				SPath:SetValue(tool.Auto.PAStationPath or "")
				SPath:SetEnterAllowed(false)
				function SPath:OnChange()
					local oldval = self:GetValue()
					local NewValue = ""
					for i = 1,#oldval do
						if #NewValue > 0 then break end
						NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]") or "")
					end
					self:SetText(NewValue)
					self:SetCaretPos(0)
				end
				function SPath:OnLoseFocus()
					tool.Auto.PAStationPath = self:GetValue()
					tool:SendSettings()
				end
				local SID = CPanel:TextEntry(OT_STID)
				SID:SetTooltip(OT_STID_Des)
				SID:SetValue(tool.Auto.PAStationID or "")
				SID:SetEnterAllowed(false)
				function SID:OnChange()
					local oldval = self:GetValue()
					local NewValue = ""
					for i = 1,#oldval do
						NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]+") or "")
					end
					local oldpos = self:GetCaretPos()
					self:SetText(NewValue)
					self:SetCaretPos(math.min(#NewValue,oldpos))
				end
				function SID:OnLoseFocus()
					tool.Auto.PAStationID = self:GetValue()
					tool:SendSettings()
				end
				local SLast = CPanel:CheckBox(PA_Last_ST)
				SLast:SetTooltip(PA_Last_ST_Des)
				SLast:SetValue(tool.Auto.PALastStation or false)
				function SLast:OnChange()
					tool.Auto.PALastStation = self:GetChecked()
					tool:SendSettings()
					tool:BuildCPanelCustom()
				end
				if tool.Auto.PALastStation then
					local SLWrongPath = CPanel:CheckBox(PA_WP)
					SLWrongPath:SetValue(tool.Auto.PAWrongPath or false)
					function SLWrongPath:OnChange()
						tool.Auto.PAWrongPath = self:GetChecked()
						tool:SendSettings()
					end
					local SLDStart = CPanel:NumSlider(PA_Dist_Start,nil,0,1024,0)
					SLDStart:SetValue(tool.Auto.PADeadlockStart or 128)
					SLDStart.OnValueChanged = function(num)
						tool.Auto.PADeadlockStart = SLDStart:GetValue()
						tool:SendSettings()
					end
					local SLDEnd = CPanel:NumSlider(PA_Dist_End,nil,0,1024,0)
					SLDEnd:SetValue(tool.Auto.PADeadlockEnd or 512)
					SLDEnd.OnValueChanged = function(num)
						tool.Auto.PADeadlockEnd = SLDEnd:GetValue()
						tool:SendSettings()
					end
					local SLLChange = CPanel:CheckBox(PA_Line_Change)
					SLLChange:SetValue(tool.Auto.PALineChange or false)
					function SLLChange:OnChange()
						tool.Auto.PALineChange = self:GetChecked()
						tool:SendSettings()
						tool:BuildCPanelCustom()
					end
					if tool.Auto.PALineChange then
						local SLLCLine = CPanel:TextEntry(PA_Line_Change_Route)
						SLLCLine:SetValue(tool.Auto.PALineChangeStationPath or "")
						SLLCLine:SetEnterAllowed(false)
						function SLLCLine:OnChange()
							local oldval = self:GetValue()
							local NewValue = ""
							for i = 1,#oldval do
								if #NewValue > 0 then break end
								NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]") or "")
							end
							self:SetText(NewValue)
							self:SetCaretPos(0)
						end
						function SLLCLine:OnLoseFocus()
							tool.Auto.PALineChangeStationPath = self:GetValue()
							tool:SendSettings()
						end
						local SLLCID = CPanel:TextEntry(PA_Line_Change_STID)
						SLLCID:SetTooltip(OT_STID_Des)
						SLLCID:SetValue(tool.Auto.PALineChangeStationID or "")
						SLLCID:SetEnterAllowed(false)
						function SLLCID:OnChange()
							local oldval = self:GetValue()
							local NewValue = ""
							for i = 1,#oldval do
								NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]+") or "")
							end
							local oldpos = self:GetCaretPos()
							self:SetText(NewValue)
							self:SetCaretPos(math.min(#NewValue,oldpos))
						end
						function SLLCID:OnLoseFocus()
							tool.Auto.PALineChangeStationID = self:GetValue()
							tool:SendSettings()
						end
					end
				end
				local SName = CPanel:TextEntry(PA_ST_Name)
				SName:SetTooltip(PA_ST_Name_Des)
				SName:SetValue(tool.Auto.PAStationName or "")
				SName:SetEnterAllowed(false)
				function SName:OnLoseFocus()
					tool.Auto.PAStationName = self:GetValue()
					tool:SendSettings()
				end
				if tool.Auto.PALastStation then
					local SLName = CPanel:TextEntry(PA_Last_ST_Name)
					SLName:SetTooltip(PA_Last_ST_Name_Des)
					SLName:SetValue(tool.Auto.PALastStationName or "")
					SLName:SetEnterAllowed(false)
					function SLName:OnLoseFocus()
						tool.Auto.PALastStationName = self:GetValue()
						tool:SendSettings()
					end
				end
				local SHorlift = CPanel:CheckBox(PA_Has_Switches)
				SHorlift:SetValue(tool.Auto.PAStationHasSwtiches or false)
				function SHorlift:OnChange()
					tool.Auto.PAStationHasSwtiches = self:GetChecked()
					tool:SendSettings()
				end
				local SRDoors = CPanel:CheckBox(OT_RD)
				SRDoors:SetValue(tool.Auto.PAStationRightDoors or false)
				function SRDoors:OnChange()
					tool.Auto.PAStationRightDoors = self:GetChecked()
					tool:SendSettings()
				end
				local SHorlift = CPanel:CheckBox(PA_Horlift)
				SHorlift:SetTooltip(PA_Horlift_Des)
				SHorlift:SetValue(tool.Auto.PAStationHorlift or false)
				function SHorlift:OnChange()
					tool.Auto.PAStationHorlift = self:GetChecked()
					tool:SendSettings()
				end
			end
		end
		if tool.Auto.Type == 7 then
			local VASBPPType = vgui.Create("DComboBox")
			CPanel:AddItem(VASBPPType)
			VASBPPType:SetColor(color_black)
			VASBPPType:AddChoice(SBPP_ST1)
			VASBPPType:AddChoice(SBPP_ST2)
			VASBPPType:AddChoice(OT_OPV)
			VASBPPType:AddChoice(SBPP_OD)
			VASBPPType:AddChoice(OT_X2)
			VASBPPType:AddChoice(OT_X3)
			VASBPPType:AddChoice(SBPP_BrakPos)

			if tool.Auto.SBPPType == "anim" then
				tool.Auto.SBPPType = 2
				VASBPPType:ChooseOptionID(2)
			elseif tool.Auto.SBPPType == nil then
				tool.Auto.SBPPType = 2
				VASBPPType:ChooseOptionID(2)
			else
				VASBPPType:ChooseOptionID(tool.Auto.SBPPType)
			end
			
			VASBPPType.OnSelect = function(_, index, name)
				VASBPPType:SetValue(name)
				tool.Auto.SBPPType = index
				tool:SendSettings()
				tool:BuildCPanelCustom()
			end
			local SBPPType = tool.Auto.SBPPType or 1
			if SBPPType <= 3 then
				local SDeadlock = CPanel:CheckBox(SBPP_DL)
				SDeadlock:SetTooltip(SBPP_DL_Des)
				SDeadlock:SetValue(tool.Auto.SBPPDeadlock or false)
				function SDeadlock:OnChange()
					tool.Auto.SBPPDeadlock = self:GetChecked()
					tool:SendSettings()
					tool:BuildCPanelCustom()
				end
			end
			if SBPPType == 1 then
				local SRPos = CPanel:CheckBox(SBPP_RP)
				SRPos:SetTooltip(SBPP_RP_Des)
				SRPos:SetValue(tool.Auto.LRightP or false)
				function SRPos:OnChange()
					tool.Auto.LRightP = self:GetChecked()
					tool:SendSettings()
				end
				local SRInvX = CPanel:CheckBox(X_Inv)
				SRInvX:SetValue(tool.Auto.LInvX or false)
				function SRInvX:OnChange()
					tool.Auto.LInvX = self:GetChecked()
					tool:SendSettings()
				end
			end
			if 2<= SBPPType and SBPPType <= 3 and not tool.Auto.SBPPDeadlock then
				local SPath = CPanel:TextEntry(OT_STT)
				SPath:SetTooltip(OT_STT_Des)
				SPath:SetValue(tool.Auto.SBPPStationPath or "")
				SPath:SetEnterAllowed(false)
				function SPath:OnChange()
					local oldval = self:GetValue()
					local NewValue = ""
					for i = 1,#oldval do
						if #NewValue > 0 then break end
						NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]") or "")
					end
					self:SetText(NewValue)
					self:SetCaretPos(0)
				end
				function SPath:OnLoseFocus()
					tool.Auto.SBPPStationPath = self:GetValue()
					tool:SendSettings()
				end
				local SID = CPanel:TextEntry(OT_STID)
				SID:SetTooltip(OT_STID_Des)
				SID:SetValue(tool.Auto.SBPPStationID or "")
				SID:SetEnterAllowed(false)
				function SID:OnChange()
					local oldval = self:GetValue()
					local NewValue = ""
					for i = 1,#oldval do
						NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]+") or "")
					end
					local oldpos = self:GetCaretPos()
					self:SetText(NewValue)
					self:SetCaretPos(math.min(#NewValue,oldpos))
				end
				function SID:OnLoseFocus()
					tool.Auto.SBPPStationID = self:GetValue()
					tool:SendSettings()
				end
			end
			if SBPPType == 3 then
				local SRDoors = CPanel:CheckBox(OT_RD)
				SRDoors:SetValue(tool.Auto.SBPPRightDoors or false)
				function SRDoors:OnChange()
					tool.Auto.SBPPRightDoors = self:GetChecked()
					tool:SendSettings()
				end
				local SDriveMode = vgui.Create("DComboBox")
				CPanel:AddItem(SDriveMode)
				SDriveMode:SetColor(color_black)
				SDriveMode:AddChoice(SBPP_None)
				SDriveMode:AddChoice(OT_X2)
				SDriveMode:AddChoice(OT_X3)
				SDriveMode:ChooseOptionID(tool.Auto.SBPPDriveMode or 1)
				SDriveMode.OnSelect = function(_, index, name)
					SDriveMode:SetValue(name)
					tool.Auto.SBPPDriveMode = index
					tool:SendSettings()
				end
			end
			if SBPPType==7  then
				local SRK = CPanel:NumSlider(SBPP_RKP,nil,1,18,0)
				SRK:SetValue(tool.Auto.SBPPRK or 0)
				SRK.OnValueChanged = function(num)
					tool.Auto.SBPPRK = SRK:GetValue()
					tool:SendSettings()
				end
			end
			if SBPPType == 3 or SBPPType>=5 then
				local STime = CPanel:NumSlider(SBPP_WT,nil,0,120,2)
				STime:SetValue(tool.Auto.SBPPWTime or 0)
				STime.OnValueChanged = function(num)
					tool.Auto.SBPPWTime = STime:GetValue()
					tool:SendSettings()
				end
			end
		end
		if  tool.Auto.Type == 1 then
			local VRightOC = CPanel:CheckBox(PC_Right)
			VRightOC:SetValue(tool.Auto.Right or false)
			function VRightOC:OnChange()
				tool.Auto.Right = self:GetChecked()
				tool:SendSettings()
			end
			local VADist = vgui.Create("DComboBox")
			CPanel:AddItem(VADist)
			VADist:SetColor(color_black)
			VADist:AddChoice(PC_5M)
			VADist:AddChoice(PC_20M)
			VADist:AddChoice(PC_50M)
			VADist:ChooseOptionID(tool.Auto.Dist or 1)
			VADist.OnSelect = function(_, index, name)
				VADist:SetValue(name)
				tool.Auto.Dist = index
				tool:SendSettings()
			end
			local VAMode = vgui.Create("DComboBox")
			CPanel:AddItem(VAMode)
			VAMode:SetColor(color_black)
			VAMode:AddChoice(OT_X2)
			VAMode:AddChoice(OT_X3)
			VAMode:AddChoice(PC_STX2)
			VAMode:AddChoice(PC_STX3)
			VAMode:AddChoice(OT_0)
			VAMode:AddChoice(PC_0R)
			VAMode:AddChoice(OT_T)
			--VAMode:AddChoice("T-1a")
			VAMode:ChooseOptionID(tool.Auto.Mode or 1)
			VAMode.OnSelect = function(_, index, name)
				VAMode:SetValue(name)
				tool.Auto.Mode = index
				tool:SendSettings()
				tool:BuildCPanelCustom()
			end
			if tool.Auto.Mode == 3 or tool.Auto.Mode == 4 then
				local SID,VSIDN = CPanel:TextEntry(OT_STID)
				SID:SetTooltip(OT_STID_Des)
				SID:SetValue(tool.Auto.StationID or "")
				SID:SetEnterAllowed(false)
				function SID:OnChange()
					local oldval = self:GetValue()
					local NewValue = ""
					for i = 1,#oldval do
						NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]+") or "")
					end
					local oldpos = self:GetCaretPos()
					self:SetText(NewValue)
					self:SetCaretPos(math.min(#NewValue,oldpos))
				end
				function SID:OnLoseFocus()
					tool.Auto.StationID = self:GetValue()
					tool:SendSettings()
				end
				local SPath,VSPathN = CPanel:TextEntry(OT_STT)
				SPath:SetTooltip(OT_STT_Des)
				SPath:SetValue(tool.Auto.StationPath or "")
				SPath:SetEnterAllowed(false)
				function SPath:OnChange()
					local oldval = self:GetValue()
					local NewValue = ""
					for i = 1,#oldval do
						if #NewValue > 0 then break end
						NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]") or "")
					end
					self:SetText(NewValue)
					self:SetCaretPos(0)
				end
				function SPath:OnLoseFocus()
					tool.Auto.StationPath = self:GetValue()
					tool:SendSettings()
				end
			end
		end
		if tool.Auto.Type == 6 then
			local VRollT = CPanel:NumSlider(UPPS_Roll,nil,-180,180,0)
			VRollT:SetValue(tool.Auto.Roll or 0)
			VRollT.OnValueChanged = function(num)
				tool.Auto.Roll = VRollT:GetValue()
				tool:SendSettings()
			end
		end
	
	elseif tool.Type == 4 then
		local es = ""
		LocalPlayer().MetrostroiStoolAutostop = LocalPlayer().MetrostroiStoolAutostop or {}

		local VASType = vgui.Create("DComboBox")
		VASType:ChooseOption(Type_Autostops[tool.Autostop.Type or 1],tool.Autostop.Type or 1)
		VASType:SetColor(color_black)
		for i = 1,#Type_Autostops do
			VASType:AddChoice(Type_Autostops[i])
		end
		VASType.OnSelect = function(_, index, name)
			VASType:SetValue(name)
			tool.Autostop.Type = index
			tool:SendSettings()
			tool:BuildCPanelCustom()
		end
		CPanel:AddItem(VASType)

		if tool.Autostop.Type == 1 then
			-- Светофор
			VSNameT = CPanel:TextEntry(AS_Siglnal_Link)
			VSNameT:SetTooltip(AS_Siglnal_Link_Des)
			VSNameT:SetValue(tool.Autostop.SignalLink or es)
			VSNameT:SetEnterAllowed(false)
			function VSNameT:OnChange()
				local val = self:GetValue():upper()
				self:SetText(val)
				self:SetCaretPos(#val)
			end
			function VSNameT:OnLoseFocus()
				tool.Autostop.SignalLink = self:GetValue()
				tool:SendSettings()
			end
			-- Скорость
			local VMSpeedT = CPanel:TextEntry("")
			VMSpeedT:SetValue("0")
			VMSpeedT:SetEnterAllowed(false)
			VMSpeedT:SetVisible(false)
		elseif tool.Autostop.Type == 2 or tool.Autostop.Type == 4 then
			-- Скорость
			local VMSpeedT = CPanel:TextEntry(AS_MaxSpeed)
			VMSpeedT:SetValue(tool.Autostop.MaxSpeed or es)
			VMSpeedT:SetEnterAllowed(false)
			function VMSpeedT:OnChange()
				local val = self:GetValue():upper()
				local numval = tonumber(val)
				if not numval then 
					self:SetText(es)
				else
					self:SetText(val)
				end
				self:SetCaretPos(string.len(self:GetValue()))
			end
			function VMSpeedT:OnLoseFocus()
				tool.Autostop.MaxSpeed = self:GetValue()
				tool:SendSettings()
			end
		elseif tool.Autostop.Type == 3 then
			-- Светофор
			VSNameT = CPanel:TextEntry("")
			VSNameT:SetValue("RANDOM")
			VSNameT:SetEnterAllowed(false)
			VSNameT:SetVisible(false)
			-- Скорость
			local VMSpeedT = CPanel:TextEntry("")
			VMSpeedT:SetValue("0")
			VMSpeedT:SetEnterAllowed(false)
			VMSpeedT:SetVisible(false)
		end
	elseif tool.Type == 5 then 
		tool.KGU = tool.KGU or {}
		local es = ""
		local VSKGUSignal = CPanel:TextEntry(KGU_Signal_Link)
		VSKGUSignal:SetTooltip(KGU_Signal_Link_Des)
		VSKGUSignal:SetValue(tool.KGU.SignalLink or es)
		VSKGUSignal:SetEnterAllowed(false)
		function VSKGUSignal:OnChange()
			local val = self:GetValue()
			local clean = val:gsub("[^%w/]", ""):gsub("[A-Za-z]", function(c)
				return c:match("[isIS]") and c or c:upper()
			end)
			if val ~= clean then self:SetText(clean) self:SetCaretPos(#clean) end
		end
		function VSKGUSignal:OnLoseFocus()
			tool.KGU.SignalLink = self:GetValue()
			tool:SendSettings()
		end
		local VSKGULense = CPanel:TextEntry(KGU_Lenses_Link)
		VSKGULense:SetTooltip(KGU_Lenses_Link_Des)
		VSKGULense:SetValue(tool.KGU.Lense or es)
		VSKGULense:SetEnterAllowed(false) 
		function VSKGULense:OnChange()
			local val = self:GetValue()
			local clean = val:gsub("%D", ""):sub(1, 9)
			-- иначе зациклится к хренам и тулу пофиг на лимит будет
			if val ~= clean then self:SetText(clean) self:SetCaretPos(#clean) end
		end
		function VSKGULense:OnLoseFocus()
			tool.KGU.Lense = self:GetValue()
			tool:SendSettings()
		end
	end
end

TOOL.NotBuilt = true

function TOOL:Think()
	if CLIENT and (self.NotBuilt or NeedUpdate) then
		self.Signal = self.Signal or util.JSONToTable(string.Replace(GetConVarString("signalling_signaldata"),"'","\"")) or {}
		self.Sign = self.Sign or util.JSONToTable(string.Replace(GetConVarString("signalling_signdata"),"'","\"")) or {}
		self.Auto = self.Auto or util.JSONToTable(string.Replace(GetConVarString("signalling_autodata"),"'","\"")) or {}
		self.Autostop = self.Autostop or util.JSONToTable(string.Replace(GetConVarString("signalling_autostopdata"),"'","\"")) or {}
		self.KGU = self.KGU or util.JSONToTable(string.Replace(GetConVarString("signalling_kgudata"),"'","\"")) or {}
		self:SendSettings()
		self:BuildCPanelCustom()
		self.NotBuilt = nil
		NeedUpdate = nil
	end
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.signalling.name", Description = "#Tool.signalling.desc" })
	local tool = LocalPlayer():GetTool("signalling")
	if tool then
		tool:BuildCPanelCustom()
	end
end
