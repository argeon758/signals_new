local blackmaps = {
    "gm_metro_minsk_1984",
    "gm_metro_u1",
    "gm_metro_u5",
    "gm_metro_u6",
    "gm_berlin_u55",
    "gm_metro_ndr_val_v2r1",
    "gm_filevskya_line_4",
    "gm_zamoscvorescya_line_do_orehovo",
    "gm_zamoskvoretskaya_line_2",
}

function checkMSAblacklist()
    if table.HasValue(blackmaps, game.GetMap()) then return true end
    timer.Simple(1, function()
        scripted_ents.Alias ("gmod_track_signal", "gmod_track_signal_msa")
        scripted_ents.Alias ("gmod_track_signs", "gmod_track_signs_msa")
    end)
end