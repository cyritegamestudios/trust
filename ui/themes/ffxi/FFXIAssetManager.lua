local ImageItem = require('cylibs/ui/collection_view/items/image_item')

local FFXIAssetManager = {}
FFXIAssetManager.__index = FFXIAssetManager
FFXIAssetManager.__type = "FFXIAssetManager"

function FFXIAssetManager.imageItemForSpell(spellName)
    local spell = res.spells:with('en', spellName)
    if spell then
        local element = res.elements[spell.element].en
        local skill = res.skills[spell.skill].en
        local imageName = string.gsub('icon_'..skill..'_'..element..'.png', " ", "_"):lower()
        if not windower.file_exists(windower.addon_path..'assets/icons/'..imageName) then
            imageName = string.gsub('icon_'..element..'.png', " ", "_"):lower()
        end
        return ImageItem.new(windower.addon_path..'assets/icons/'..imageName, 15, 15)
    end
    return ImageItem.new(windower.addon_path..'assets/icons/icon_elemental_magic_ice.png', 15, 15)
end

function FFXIAssetManager.imageItemForJobAbility(jobAbilityName)
    return ImageItem.new(windower.addon_path..'assets/icons/icon_job_ability_light.png', 15, 15)
end

return FFXIAssetManager