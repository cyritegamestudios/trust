local GambitEditorStyle = {}
GambitEditorStyle.__index = GambitEditorStyle

function GambitEditorStyle.new(configItemForGambits, viewSize, abilityCategory, abilityCategoryPlural)
    local self = setmetatable({}, GambitEditorStyle)
    self.configItemForGambits = configItemForGambits
    self.viewSize = viewSize
    self.abilityCategory = abilityCategory or "Gambit"
    self.abilityCategoryPlural = abilityCategoryPlural or "Gambits"
    return self
end

function GambitEditorStyle:getConfigItem(gambits)
    return self.configItemForGambits(gambits)
end

function GambitEditorStyle:getViewSize()
    return self.viewSize
end

function GambitEditorStyle:getDescription(plural, lower)
    local description
    if plural then
        description = self.abilityCategoryPlural
    else
        description = self.abilityCategory
    end
    if lower then
        description = description:lower()
    end
    return description
end

return GambitEditorStyle