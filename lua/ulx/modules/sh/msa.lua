local CATEGORY_NAME = "Metrostroi" 

function ulx.kgu_force_false(calling_ply, link)
    local link_safe = link 

    if link_safe == "" then
        ULib.tsayError( calling_ply, "You have not specified a signal!", true ) 
        return
    end
    if Metrostroi.ForceKGUState and Metrostroi.ForceKGUState(link_safe, false) then 
        ulx.fancyLogAdmin( calling_ply, "#A reset KGU #s", link_safe)
    else
        ULib.tsayError( calling_ply, "KGU " .. link_safe .. " not found.", true )
    end
end
local kgu_force_false = ulx.command( CATEGORY_NAME, "ulx kguoff", ulx.kgu_force_false, "!kguoff" )
kgu_force_false:addParam{ type=ULib.cmds.StringArg, hint="SignalLink", ULib.cmds.takeRestOfLine }
kgu_force_false:defaultAccess( ULib.ACCESS_ADMIN )
kgu_force_false:help("KGU Reset. Input signal names (OK133/134)")

function ulx.kgu_force_true(calling_ply, link)
    local link_safe = link

    if link_safe == "" then
        ULib.tsayError( calling_ply, "You have not specified a signal!", true ) 
        return
    end
    if Metrostroi.ForceKGUState and Metrostroi.ForceKGUState(link_safe, true) then
        ulx.fancyLogAdmin( calling_ply, "#A force triggered KGU #s", link_safe)
    else
        ULib.tsayError( calling_ply, "KGU " .. link_safe .. " not found.", true )
    end
end
local kgu_force_true = ulx.command( CATEGORY_NAME, "ulx kguon", ulx.kgu_force_true, "!kguon" )
kgu_force_true:addParam{ type=ULib.cmds.StringArg, hint="SignalLink", ULib.cmds.takeRestOfLine }
kgu_force_true:defaultAccess( ULib.ACCESS_ADMIN )
kgu_force_true:help("Force trigger KGU. Input signal names (OK133/134)")