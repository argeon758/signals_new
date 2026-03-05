ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.PrintName		= "KGU MSA Detector"
ENT.Author			= "Gemini AI"
ENT.Category		= "Metrostroi Signalling"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false

ENT.Model 			= "models/metrostroi/signals/mus/kgu_detector.mdl"
ENT.PhysgunDisabled = true
ENT.SignalLink 		= "" -- читофор, к которому привязана КГУ
ENT.Lense 			= "0"  -- линзы которые будут включаться

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "KGUSignalLink")
    self:NetworkVar("String", 1, "KGULense")
    self:NetworkVar("Bool", 3, "KGUState")
end