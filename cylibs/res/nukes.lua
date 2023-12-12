local nukes = {}
local ele = {}

_libs = _libs or {}
_libs.nukes = nukes

_raw = _raw or {}

-- Element Variables & Functions

Earth = 0
Water = 0
Wind = 0
Fire = 0
Ice = 0
Thunder = 0
Darkness = 0
Lightness = 0

function nukes.toggle(element)
    if element == 'earth' then
        ele.earth()
        return Earth == 0
    elseif element == 'lightning' then
        ele.thunder()
        return Thunder == 0
    elseif element == 'water' then
        ele.water()
        return Water == 0
    elseif element == 'fire' then
        ele.fire()
        return Fire == 0
    elseif element == 'ice' then
        ele.ice()
        return Ice == 0
    elseif element == 'wind' then
        ele.wind()
        return Wind == 0
    elseif element == 'light' then
        ele.lightness()
        return Lightness == 0
    elseif element == 'dark' then
        ele.darkness()
        return Darkness == 0
    end
    return false
end

function nukes.get_disabled_elements()
    local elements = L{}

    if Earth == 1 then
        elements:append('earth')
    end
    if Thunder == 1 then
        elements:append('lightning')
    end
    if Water == 1 then
        elements:append('water')
    end
    if Fire == 1 then
        elements:append('fire')
    end
    if Ice == 1 then
        elements:append('ice')
    end
    if Wind == 1 then
        elements:append('wind')
    end
    if Lightness == 1 then
        elements:append('light')
    end
    if Darkness == 1 then
        elements:append('dark')
    end

    return elements
end


function nukes.reset()
    Earth = 0
    Water = 0
    Wind = 0
    Fire = 0
    Ice = 0
    Thunder = 0
    Darkness = 0
    Lightness = 0
end

function nukes.disable()
    Earth = 1
    Water = 1
    Wind = 1
    Fire = 1
    Ice = 1
    Thunder = 1
    Darkness = 1
    Lightness = 1
end

function ele.earth()

  if Earth == 0 then
    Earth = 1
    windower.add_to_chat(207, '%s: Disabled Earth Spells':format(_addon.name))
  else
    Earth = 0
    windower.add_to_chat(207, '%s: Enabled Earth Spells':format(_addon.name))
  end

end

function ele.water()

  if Water == 0 then
    Water = 1
    windower.add_to_chat(207, '%s: Disabled Water Spells':format(_addon.name))
  else
    Water = 0
    windower.add_to_chat(207, '%s: Enabled Water Spells':format(_addon.name))
  end

end

function ele.wind()

  if Wind == 0 then
    Wind = 1
    windower.add_to_chat(207, '%s: Disabled Wind Spells':format(_addon.name))
  else
    Wind = 0
    windower.add_to_chat(207, '%s: Enabled Wind Spells':format(_addon.name))
  end

end

function ele.fire()

  if Fire == 0 then
    Fire = 1
    windower.add_to_chat(207, '%s: Disabled Fire Spells':format(_addon.name))
  else
    Fire = 0
    windower.add_to_chat(207, '%s: Enabled Fire Spells':format(_addon.name))
  end

end

function ele.ice()

  if Ice == 0 then
    Ice = 1
    windower.add_to_chat(207, '%s: Disabled Ice Spells':format(_addon.name))
  else
    Ice = 0
    windower.add_to_chat(207, '%s: Enabled Ice Spells':format(_addon.name))
  end

end

function ele.thunder()

  if Thunder == 0 then
    Thunder = 1
    windower.add_to_chat(207, '%s: Disabled Thunder Spells':format(_addon.name))
  else
    Thunder = 0
    windower.add_to_chat(207, '%s: Enabled Thunder Spells':format(_addon.name))
  end

end

function ele.darkness()

  if Darkness == 0 then
    Darkness = 1
    windower.add_to_chat(207, '%s: Disabled Dark Spells':format(_addon.name))
  else
    Darkness = 0
    windower.add_to_chat(207, '%s: Enabled Dark Spells':format(_addon.name))
  end

end

function ele.lightness()

  if Lightness == 0 then
    Lightness = 1
    windower.add_to_chat(207, '%s: Disabled Light Spells':format(_addon.name))
  else
    Lightness = 0
    windower.add_to_chat(207, '%s: Enabled Light Spells':format(_addon.name))
  end

end


-- Nuke Functions

function nukes.dark()
    if Darkness == 1 then
        return nil
    end
  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[219] * 0.66) < 1) then
   return "Comet"
  elseif (nukes.blm() and (windower.ffxi.get_spell_recasts()[881] * 0.66) < 1) then
   return "Aspir III"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() or nukes.whm() then
    if ((windower.ffxi.get_spell_recasts()[248] * 0.66) < 1) then
       return "Aspir II"
    elseif ((windower.ffxi.get_spell_recasts()[247] * 0.66) < 1) then
       return "Aspir"
    else
       return nil
    end
  end

  if nukes.nin() then
    return nil
  end

end


function nukes.holy()
    if Lightness == 1 then
        return nil
    end
  if nukes.whm() then
   if (windower.ffxi.get_spell_recasts()[22] * 0.66) < 1 then
    return "Holy II"
   elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() or nukes.whm() then
    if ((windower.ffxi.get_spell_recasts()[21] * 0.66) < 1) then
       return "Holy"
    else
       return nil
    end
   end
  end

  if nukes.nin() then
    return nil
  end

end


function nukes.thunder()
    if Thunder == 1 then
        return nil
    end
  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[853] * 0.66) < 1) then
   return "Thunder VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[168] * 0.66) < 1) then
       return "Thunder V"
    elseif ((windower.ffxi.get_spell_recasts()[167] * 0.66) < 1) then
       return "Thunder IV"
    elseif ((windower.ffxi.get_spell_recasts()[166] * 0.66) < 1) then
       return "Thunder III"
    elseif ((windower.ffxi.get_spell_recasts()[165] * 0.66) < 1) then
       return "Thunder II"
    else
       return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[333] * 0.25) < 1) then
      return "Raiton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[334] * 0.25) < 1) then
      return "Raiton: San"
    elseif ((windower.ffxi.get_spell_recasts()[332] * 0.25) < 1) then
      return "Raiton: Ichi"
    else
       return nil
    end
  end

end


function nukes.blizzard()
    if Ice == 1 then
        return nil
    end
  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[850] * 0.66) < 1) then
	 return "Blizzard VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[153] * 0.66) < 1) then
       return "Blizzard V"
    elseif ((windower.ffxi.get_spell_recasts()[152] * 0.66) < 1) then
       return "Blizzard IV"
    elseif ((windower.ffxi.get_spell_recasts()[151] * 0.66) < 1) then
       return "Blizzard III"
    elseif ((windower.ffxi.get_spell_recasts()[150] * 0.66) < 1) then
       return "Blizzard II"
    else
       return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[324] * 0.25) < 1) then
      return "Hyoton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[325] * 0.25) < 1) then
      return "Hyoton: San"
    elseif ((windower.ffxi.get_spell_recasts()[323] * 0.25) < 1) then
      return "Hyoton: Ichi"
    else
       return nil
    end
  end

end


function nukes.fire()
    if Fire == 1 then
        return nil
    end
  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[849] * 0.66) < 1) then
	 return "Fire VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[148] * 0.66) < 1) then
       return "Fire V"
    elseif ((windower.ffxi.get_spell_recasts()[147] * 0.66) < 1) then
       return "Fire IV"
    elseif ((windower.ffxi.get_spell_recasts()[146] * 0.66) < 1) then
       return "Fire III"
    elseif ((windower.ffxi.get_spell_recasts()[145] * 0.66) < 1) then
       return "Fire II"
    else
       return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[321] * 0.25) < 1) then
      return "Katon: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[322] * 0.25) < 1) then
      return "Katon: San"
    elseif ((windower.ffxi.get_spell_recasts()[320] * 0.25) < 1) then
      return "Katon: Ichi"
    else
       return nil
    end
  end

end


function nukes.aero()
    if Wind == 1 then
        return nil
    end
  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[851] * 0.66) < 1) then
     return "Aero VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[158] * 0.66) < 1) then
       return "Aero V"
    elseif ((windower.ffxi.get_spell_recasts()[157] * 0.66) < 1) then
       return "Aero IV"
    elseif ((windower.ffxi.get_spell_recasts()[156] * 0.66) < 1) then
       return "Aero III"
    elseif ((windower.ffxi.get_spell_recasts()[155] * 0.66) < 1) then
       return "Aero II"
    else
       return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[327] * 0.25) < 1) then
      return "Huton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[328] * 0.25) < 1) then
      return "Huton: San"
    elseif ((windower.ffxi.get_spell_recasts()[326] * 0.25) < 1) then
      return "Huton: Ichi"
    else
       return nil
    end
  end

end


function nukes.water()
    if Water == 1 then
        return nil
    end
  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[854] * 0.66) < 1) then
	 return "Water VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[173] * 0.66) < 1) then
       return "Water V"
    elseif ((windower.ffxi.get_spell_recasts()[172] * 0.66) < 1) then
       return "Water IV"
    elseif ((windower.ffxi.get_spell_recasts()[171] * 0.66) < 1) then
       return "Water III"
    elseif ((windower.ffxi.get_spell_recasts()[170] * 0.66) < 1) then
  	 return "Water II"
    else
     return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[336] * 0.25) < 1) then
      return "Suiton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[337] * 0.25) < 1) then
      return "Suiton: San"
    elseif ((windower.ffxi.get_spell_recasts()[335] * 0.25) < 1) then
      return "Suiton: Ichi"
    else
       return nil
    end
  end

end


function nukes.stone()
    if Earth == 1 then
        return nil
    end
  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[852] * 0.66) < 1) then
	 return "Stone VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[163] * 0.66) < 1) then
  	 return "Stone V"
    elseif ((windower.ffxi.get_spell_recasts()[162] * 0.66) < 1) then
  	 return "Stone IV"
    elseif ((windower.ffxi.get_spell_recasts()[161] * 0.66) < 1) then
  	 return "Stone III"
    elseif ((windower.ffxi.get_spell_recasts()[160] * 0.66) < 1) then
  	 return "Stone II"
    else
     return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[330] * 0.25) < 1) then
      return "Doton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[331] * 0.25) < 1) then
      return "Doton: San"
    elseif ((windower.ffxi.get_spell_recasts()[329] * 0.25) < 1) then
      return "Doton: Ichi"
    else
       return nil
    end
  end

end


function nukes.ongo()

  if nukes.blm() then
    if ((windower.ffxi.get_spell_recasts()[852] * 0.66) < 1) then
     return "Stone VI"
    elseif ((windower.ffxi.get_spell_recasts()[499] * 0.66) < 1) then
     return "Stoneja"
    elseif ((windower.ffxi.get_spell_recasts()[163] * 0.66) < 1) then
  	 return "Stone V"
    elseif ((windower.ffxi.get_spell_recasts()[162] * 0.66) < 1) then
  	 return "Stone IV"
    elseif ((windower.ffxi.get_spell_recasts()[191] * 0.66) < 1) then
     return "Stonega III"
   elseif ((windower.ffxi.get_spell_recasts()[211] * 0.66) < 1) then
     return "Quake II"
    elseif ((windower.ffxi.get_spell_recasts()[161] * 0.66) < 1) then
  	 return "Stone III"
    elseif ((windower.ffxi.get_spell_recasts()[190] * 0.66) < 1) then
      return "Stonega II"
    elseif ((windower.ffxi.get_spell_recasts()[210] * 0.66) < 1) then
     return "Quake"
    elseif ((windower.ffxi.get_spell_recasts()[160] * 0.66) < 1) then
  	 return "Stone II"
    else
     return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[330] * 0.25) < 1) then
      return "Doton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[331] * 0.25) < 1) then
      return "Doton: San"
    elseif ((windower.ffxi.get_spell_recasts()[329] * 0.25) < 1) then
      return "Doton: Ichi"
    else
       return nil
    end
  end

end


function nukes.fusion()

  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[849] * 0.67) < 1) and Fire == 0 then
	 return "Fire VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[148] * 0.66) < 1) and Fire == 0 then
  	 return "Fire V"
    elseif ((windower.ffxi.get_spell_recasts()[147] * 0.66) < 1) and Fire == 0  then
  	 return "Fire IV"
    elseif ((windower.ffxi.get_spell_recasts()[146] * 0.66) < 1) and Fire == 0 then
  	 return "Fire III"
    elseif ((windower.ffxi.get_spell_recasts()[145] * 0.66) < 1) and Fire == 0 then
  	 return "Fire II"
    else
     return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[321] * 0.25) < 1) and Fire == 0 then
      return "Katon: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[322] * 0.25) < 1) and Fire == 0 then
      return "Katon: San"
    elseif ((windower.ffxi.get_spell_recasts()[320] * 0.25) < 1) and Fire == 0 then
      return "Katon: Ichi"
    else
       return nil
    end
  end

end


function nukes.disto()

  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[850] * 0.66) < 1) and Ice == 0 then
	 return "Blizzard VI"
  elseif (nukes.blm() and (windower.ffxi.get_spell_recasts()[854] * 0.66) < 1) and Water == 0 then
    return "Water VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[153] * 0.66) < 1) and Ice == 0 then
       return "Blizzard V"
    elseif ((windower.ffxi.get_spell_recasts()[173] * 0.66) < 1) and Water == 0 then
       return "Water V"
    elseif ((windower.ffxi.get_spell_recasts()[152] * 0.66) < 1) and Ice == 0 then
       return "Blizzard IV"
    elseif ((windower.ffxi.get_spell_recasts()[172] * 0.66) < 1) and Water == 0 then
       return "Water IV"
    elseif ((windower.ffxi.get_spell_recasts()[151] * 0.66) < 1) and Ice == 0 then
       return "Blizzard III"
    elseif ((windower.ffxi.get_spell_recasts()[171] * 0.66) < 1) and Water == 0 then
       return "Water III"
    elseif ((windower.ffxi.get_spell_recasts()[150] * 0.66) < 1) and Ice == 0 then
       return "Blizzard II"
    elseif ((windower.ffxi.get_spell_recasts()[170] * 0.66) < 1) and Water == 0 then
       return "Water II"
    else
       return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[324] * 0.25) < 1) and Ice == 0 then
      return "Hyoton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[336] * 0.25) < 1) and Water == 0 then
      return "Suiton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[325] * 0.25) < 1) and Ice == 0 then
      return "Hyoton: San"
    elseif ((windower.ffxi.get_spell_recasts()[337] * 0.25) < 1) and Water == 0 then
      return "Suiton: San"
    elseif ((windower.ffxi.get_spell_recasts()[323] * 0.25) < 1) and Ice == 0 then
      return "Hyoton: Ichi"
    elseif ((windower.ffxi.get_spell_recasts()[335] * 0.25) < 1) and Water == 0 then
      return "Suiton: Ichi"
    else
       return nil
    end
  end

    if nukes.smn() then
        if (windower.ffxi.get_ability_recasts()[173] < 1) and Ice == 0 then
            return "Heavenly Strike"
        else
            return nil
        end
    end

end


function nukes.grav()

  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[219] * 0.66) < 1) and Darkness == 0 then
    return "Comet"
  elseif (nukes.blm() and (windower.ffxi.get_spell_recasts()[852] * 0.66) < 1) and Earth == 0 then
	  return "Stone VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[163] * 0.66) < 1) and Earth == 0 then
       return "Stone V"
    elseif ((windower.ffxi.get_spell_recasts()[162] * 0.66) < 1) and Earth == 0 then
       return "Stone IV"
    elseif ((windower.ffxi.get_spell_recasts()[161] * 0.66) < 1) and Earth == 0 then
       return "Stone III"
    elseif ((windower.ffxi.get_spell_recasts()[160] * 0.66) < 1) and Earth == 0 then
       return "Stone II"
    else
       return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[330] * 0.25) < 1) and Earth == 0 then
      return "Doton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[331] * 0.25) < 1) and Earth == 0 then
      return "Doton: San"
    elseif ((windower.ffxi.get_spell_recasts()[329] * 0.25) < 1) and Earth == 0 then
      return "Doton: Ichi"
    else
      return nil
    end
  end

    if nukes.drk() then
        if ((windower.ffxi.get_spell_recasts()[880] * 0.75) < 1 and windower.ffxi.get_player().vitals.hp < 4000) then
            return "Drain III"
        else
            return nil
        end
    end
end


function nukes.frag()

  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[853] * 0.66) < 1) and Thunder == 0 then
	 return "Thunder VI"
  elseif (nukes.blm() and (windower.ffxi.get_spell_recasts()[851] * 0.66) < 1) and Wind == 0 then
     return "Aero VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[168] * 0.66) < 1) and Thunder == 0 then
       return "Thunder V"
    elseif ((windower.ffxi.get_spell_recasts()[158] * 0.66) < 1) and Wind == 0 then
       return "Aero V"
    elseif ((windower.ffxi.get_spell_recasts()[167] * 0.66) < 1) and Thunder == 0 then
       return "Thunder IV"
    elseif ((windower.ffxi.get_spell_recasts()[157] * 0.66) < 1) and Wind == 0 then
       return "Aero IV"
    elseif ((windower.ffxi.get_spell_recasts()[166] * 0.66) < 1) and Thunder == 0 then
      return "Thunder III"
    elseif ((windower.ffxi.get_spell_recasts()[156] * 0.66) < 1) and Wind == 0 then
      return "Aero III"
    elseif ((windower.ffxi.get_spell_recasts()[165] * 0.66) < 1) and Thunder == 0 then
      return "Thunder II"
    elseif ((windower.ffxi.get_spell_recasts()[155] * 0.66) < 1) and Wind == 0 then
      return "Aero II"
    else
       return nil
    end
  elseif nukes.smn() then
      if (windower.ffxi.get_ability_recasts()[173] < 1) and Thunder == 0 then
          return "Thunderstorm"
      else
          return nil
      end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[333] * 0.25) < 1) and Thunder == 0 then
      return "Raiton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[327] * 0.25) < 1) and Wind == 0 then
      return "Huton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[334] * 0.25) < 1) and Thunder == 0 then
      return "Raiton: San"
    elseif ((windower.ffxi.get_spell_recasts()[328] * 0.25) < 1) and Wind == 0 then
      return "Huton: San"
    elseif ((windower.ffxi.get_spell_recasts()[332] * 0.25) < 1) and Thunder == 0 then
      return "Raiton: Ichi"
    elseif ((windower.ffxi.get_spell_recasts()[326] * 0.25) < 1) and Wind == 0 then
      return "Huton: Ichi"
    else
       return nil
    end
  end

end


function nukes.light()
  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[853] * 0.66) < 1) and Thunder == 0 then
  	 return "Thunder VI"
  elseif (nukes.blm() and (windower.ffxi.get_spell_recasts()[849] * 0.66) < 1) and Fire == 0 then
     return "Fire VI"
  elseif (nukes.blm() and (windower.ffxi.get_spell_recasts()[851] * 0.66) < 1) and Wind == 0 then
     return "Aero VI"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[168] * 0.66) < 1) and Thunder == 0 then
       return "Thunder V"
    elseif ((windower.ffxi.get_spell_recasts()[148] * 0.66) < 1) and Fire == 0 then
       return "Fire V"
    elseif ((windower.ffxi.get_spell_recasts()[158] * 0.66) < 1) and Wind == 0 then
       return "Aero V"
    elseif ((windower.ffxi.get_spell_recasts()[167] * 0.66) < 1) and Thunder == 0 then
       return "Thunder IV"
    elseif ((windower.ffxi.get_spell_recasts()[147] * 0.66) < 1) and Fire == 0 then
       return "Fire IV"
    elseif ((windower.ffxi.get_spell_recasts()[157] * 0.66) < 1) and Wind == 0 then
       return "Aero IV"
    elseif ((windower.ffxi.get_spell_recasts()[166] * 0.66) < 1) and Thunder == 0 then
       return "Thunder III"
    elseif ((windower.ffxi.get_spell_recasts()[146] * 0.66) < 1) and Fire == 0 then
       return "Fire III"
    elseif ((windower.ffxi.get_spell_recasts()[156] * 0.66) < 1) and Wind == 0 then
       return "Aero III"
    elseif ((windower.ffxi.get_spell_recasts()[165] * 0.66) < 1) and Thunder == 0 then
       return "Thunder II"
    elseif ((windower.ffxi.get_spell_recasts()[145] * 0.66) < 1) and Fire == 0 then
       return "Fire II"
    elseif ((windower.ffxi.get_spell_recasts()[155] * 0.66) < 1) and Wind == 0 then
       return "Aero II"
    else
       return nil
    end
  elseif nukes.whm() then
      if ((windower.ffxi.get_spell_recasts()[23] * 0.66) < 1) and Lightness == 0 then
          return "Holy II"
      elseif ((windower.ffxi.get_spell_recasts()[22] * 0.66) < 1) and Lightness == 0 then
          return "Holy"
      else
          return nil
      end
  elseif nukes.smn() then
      if (windower.ffxi.get_ability_recasts()[173] < 1) and Fire == 0 then
          return "Meteor Strike"
      else
          return nil
      end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[333] * 0.25) < 1) and Thunder == 0 then
      return "Raiton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[321] * 0.25) < 1) and Fire == 0 then
      return "Katon: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[327] * 0.25) < 1) and Wind == 0 then
      return "Huton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[334] * 0.25) < 1) and Thunder == 0 then
      return "Raiton: San"
    elseif ((windower.ffxi.get_spell_recasts()[322] * 0.25) < 1) and Fire == 0 then
      return "Katon: San"
    elseif ((windower.ffxi.get_spell_recasts()[328] * 0.25) < 1) and Wind == 0 then
      return "Huton: San"
    elseif ((windower.ffxi.get_spell_recasts()[332] * 0.25) < 1) and Thunder == 0 then
      return "Raiton: Ichi"
    elseif ((windower.ffxi.get_spell_recasts()[320] * 0.25) < 1) and Fire == 0 then
      return "Katon: Ichi"
    elseif ((windower.ffxi.get_spell_recasts()[326] * 0.25) < 1) and Wind == 0 then
      return "Huton: Ichi"
    else
       return nil
    end
  end

end


function nukes.darkness()

  if (nukes.blm() and (windower.ffxi.get_spell_recasts()[850] * 0.66) < 1) and Ice == 0 then
     return "Blizzard VI"
  elseif (nukes.blm() and (windower.ffxi.get_spell_recasts()[854] * 0.66) < 1) and Water == 0 then
     return "Water VI"
  elseif (nukes.blm() and (windower.ffxi.get_spell_recasts()[852] * 0.66) < 1) and Earth == 0 then
     return "Stone VI"
  elseif (nukes.blm() and (windower.ffxi.get_spell_recasts()[219] * 0.66) < 1) and Darkness == 0 then
     return "Comet"
  elseif nukes.blm() or nukes.sch() or nukes.geo() or nukes.rdm() then
    if ((windower.ffxi.get_spell_recasts()[153] * 0.66) < 1) and Ice == 0 then
       return "Blizzard V"
    elseif ((windower.ffxi.get_spell_recasts()[173] * 0.66) < 1) and Water == 0 then
       return "Water V"
    elseif ((windower.ffxi.get_spell_recasts()[163] * 0.66) < 1) and Earth == 0 then
       return "Stone V"
    elseif ((windower.ffxi.get_spell_recasts()[152] * 0.66) < 1) and Ice == 0 then
       return "Blizzard IV"
    elseif ((windower.ffxi.get_spell_recasts()[172] * 0.66) < 1) and Water == 0 then
       return "Water IV"
    elseif ((windower.ffxi.get_spell_recasts()[162] * 0.66) < 1) and Earth == 0 then
       return "Stone IV"
    elseif ((windower.ffxi.get_spell_recasts()[151] * 0.66) < 1) and Ice == 0 then
       return "Blizzard III"
    elseif ((windower.ffxi.get_spell_recasts()[171] * 0.66) < 1) and Water == 0 then
       return "Water III"
    elseif ((windower.ffxi.get_spell_recasts()[161] * 0.66) < 1) and Earth == 0 then
       return "Stone III"
    elseif ((windower.ffxi.get_spell_recasts()[150] * 0.66) < 1) and Ice == 0 then
       return "Blizzard II"
    elseif ((windower.ffxi.get_spell_recasts()[170] * 0.66) < 1) and Water == 0 then
       return "Water II"
    elseif ((windower.ffxi.get_spell_recasts()[160] * 0.66) < 1) and Earth == 0 then
       return "Stone II"
    else
       return nil
    end
  end

  if nukes.nin() then
    if ((windower.ffxi.get_spell_recasts()[324] * 0.25) < 1) and Ice == 0 then
      return "Hyoton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[336] * 0.25) < 1) and Water == 0 then
      return "Suiton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[330] * 0.25) < 1) and Earth == 0 then
      return "Doton: Ni"
    elseif ((windower.ffxi.get_spell_recasts()[325] * 0.25) < 1) and Ice == 0 then
      return "Hyoton: San"
    elseif ((windower.ffxi.get_spell_recasts()[337] * 0.25) < 1) and Water == 0 then
      return "Suiton: San"
    elseif ((windower.ffxi.get_spell_recasts()[331] * 0.25) < 1) and Earth == 0 then
      return "Doton: San"
    elseif ((windower.ffxi.get_spell_recasts()[323] * 0.25) < 1) and Ice == 0 then
      return "Hyoton: Ichi"
    elseif ((windower.ffxi.get_spell_recasts()[335] * 0.25) < 1) and Water == 0 then
      return "Suiton: Ichi"
    elseif ((windower.ffxi.get_spell_recasts()[329] * 0.25) < 1) and Earth == 0 then
      return "Doton: Ichi"
    else
       return nil
    end
  end

    if nukes.smn() then
        if (windower.ffxi.get_ability_recasts()[173] < 1) and Ice == 0 then
            return "Heavenly Strike"
        else
            return nil
        end
    end

    if nukes.drk() then
        if ((windower.ffxi.get_spell_recasts()[880] * 0.75) < 1 and windower.ffxi.get_player().vitals.hp < 4000) then
            return "Drain III"
        else
            return nil
        end
    end

end

function nukes.get_nuke(cmd)
	if L{'Lightning', 'thundermb'}:contains(cmd) then
		return nukes.thunder()
	elseif L{'Ice', 'blizzardmb'}:contains(cmd) then
		return nukes.blizzard()
	elseif L{'Fire', 'firemb'}:contains(cmd) then
		return nukes.fire()
	elseif L{'Wind', 'aeromb'}:contains(cmd) then
		return nukes.aero()
	elseif L{'Water', 'watermb'}:contains(cmd) then
		return nukes.water()
	elseif L{'Earth', 'stonemb'}:contains(cmd) then
		return nukes.stone()
	elseif cmd == 'gravmb' then
		return nukes.grav()
	elseif cmd == 'distomb' then
		return nukes.disto()
	elseif cmd == 'fragmb' then
		return nukes.frag()
	elseif cmd == 'fusionmb' then
		return nukes.fusion()
	elseif cmd == 'lightmb' then
		return nukes.light()
	elseif cmd == 'darknessmb' then
		return nukes.darkness()
  elseif L{'Dark', 'darkmb'}:contains(cmd) then
    return nukes.dark()
  elseif L{'Light', 'holymb'}:contains(cmd) then
    return nukes.holy()
  elseif cmd == 'ongomb' then
    return nukes.ongo()
	else
		return nil
	end
end

function nukes.blm()
	return windower.ffxi.get_player().main_job == 'BLM'
end

function nukes.sch()
  return windower.ffxi.get_player().main_job == 'SCH'
end

function nukes.geo()
  return windower.ffxi.get_player().main_job == 'GEO'
end

function nukes.rdm()
  return windower.ffxi.get_player().main_job == 'RDM'
end

function nukes.nin()
	return windower.ffxi.get_player().main_job == 'NIN'
end

function nukes.whm()
    return windower.ffxi.get_player().main_job == 'WHM'
end

function nukes.smn()
    return windower.ffxi.get_player().main_job == 'SMN'
end

function nukes.drk()
    return windower.ffxi.get_player().main_job == 'DRK'
end

windower.register_event('addon command', function(cmd, ...)

  local spell = nil

  if cmd == 'thundermb' then
    spell = nukes.thunder()
  elseif cmd == 'blizzardmb' then
    spell = nukes.blizzard()
  elseif cmd == 'firemb' then
    spell = nukes.fire()
  elseif cmd == 'aeromb' then
    spell = nukes.aero()
  elseif cmd == 'watermb' then
    spell = nukes.water()
  elseif cmd == 'stonemb' then
    spell = nukes.stone()
  elseif cmd == 'gravmb' then
    spell = nukes.grav()
  elseif cmd == 'distomb' then
    spell = nukes.disto()
  elseif cmd == 'fragmb' then
    spell = nukes.frag()
  elseif cmd == 'fusionmb' then
    spell = nukes.fusion()
  elseif cmd == 'lightmb' then
    spell = nukes.light()
  elseif cmd == 'darknessmb' then
    spell = nukes.darkness()
  elseif cmd == 'darkmb' then
    spell = nukes.dark()
  elseif cmd == 'holymb' then
    spell = nukes.holy()
  end

  if cmd == 'earth' then
      ele.earth()
  elseif cmd == 'water' then
      ele.water()
  elseif cmd == 'wind' then
      ele.wind()
  elseif cmd == 'fire' then
      ele.fire()
  elseif cmd == 'ice' then
      ele.ice()
  elseif cmd == 'thunder' then
      ele.thunder()
  elseif cmd == 'darkness' then
      ele.darkness()
  elseif cmd == 'lightness' then
      ele.lightness()
  end

  if spell then
	 windower.send_command('input /ma "'..spell..'" <t>')
  end

end)

return nukes
