local Action = require('cylibs/actions/action')
local EquipAttachmentAction = setmetatable({}, {__index = Action })
EquipAttachmentAction.__index = EquipAttachmentAction

function EquipAttachmentAction.new(attachment_id, slot_index)
    local conditions = L{
        NotCondition.new(L{ HasPetCondition.new() }),
    }

    local self = setmetatable(Action.new(0, 0, 0, windower.ffxi.get_player().index, conditions), EquipAttachmentAction)

    self.attachment_id = attachment_id
    self.slot_index = slot_index

    return self
end

function EquipAttachmentAction:perform()
    if self.slot_index then
        windower.ffxi.set_attachment(self.attachment_id, self.slot_index)
    else
        windower.ffxi.set_attachment(self.attachment_id)
    end

    coroutine.sleep(0.5)

    self:complete(true)
end

function EquipAttachmentAction:get_target()
    return windower.ffxi.get_mob_by_index(self.target_index)
end

function EquipAttachmentAction:gettype()
    return "equipattachmentaction"
end

function EquipAttachmentAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self.attachment_id == action.attachment_id
        and self.slot_index == action.slot_index
end

function EquipAttachmentAction:tostring()
    return ""
end

function EquipAttachmentAction:debug_string()
    return "EquipAttachmentAction: %d %d":format(self.attachment_id, self.slot_index)
end

return EquipAttachmentAction



