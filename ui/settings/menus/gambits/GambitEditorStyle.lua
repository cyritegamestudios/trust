local GambitEditorStyle = {}
GambitEditorStyle.__index = GambitEditorStyle

function GambitEditorStyle.new(configItemForGambits, viewSize)
    local self = setmetatable({}, GambitEditorStyle)
    self.configItemForGambits = configItemForGambits
    self.viewSize = viewSize
    return self
end

function GambitEditorStyle:getConfigItem(gambits)
    return self.configItemForGambits(gambits)
end

function GambitEditorStyle:getViewSize()
    return self.viewSize
end

return GambitEditorStyle