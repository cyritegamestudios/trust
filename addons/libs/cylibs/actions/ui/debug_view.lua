local ListItem = require('cylibs/ui/list_item')
local ListView = require('cylibs/ui/list_view')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')

local DebugView = setmetatable({}, {__index = ListView })
DebugView.__index = DebugView

function DebugView.new(action_queue, layout)
    local self = setmetatable(ListView.new(layout), DebugView)

    self.action_queue = action_queue

    self:updateActions()

    self.action_queued_id = action_queue:on_action_queued():addAction(function(_)
        self:updateActions()
    end)
    self.action_start_id = action_queue:on_action_start():addAction(function(_, _)
        self:updateActions()
    end)
    self.action_end_id = action_queue:on_action_end():addAction(function()
        self:updateActions()
    end)

    return self
end

function DebugView:destroy()
    ListView.destroy(self)

    self.action_queue:on_action_queued():removeAction(self.action_queued_id)
    self.action_queue:on_action_start():removeAction(self.action_start_id)
    self.action_queue:on_action_end():removeAction(self.action_end_id)
    self.action_queue = nil
end

function DebugView:render()
    ListView.render(self)
end

function DebugView:updateActions()
    if not self:is_visible() then
        return
    end

    self:removeAllItems()

    self:addItem(ListItem.new({text = "Actions", height = 20}, ListViewItemStyle.DarkMode.Text, "actions-header", TextListItemView.new))

    local actions = self.action_queue:get_actions()
    if actions:length() > 0 then
        for action in actions:it() do
            if action:tostring():len() > 0 then
                local style = ListViewItemStyle.DarkMode.Text
                if action:is_equal(actions[1]) then
                    style = ListViewItemStyle.DarkMode.HighlightedText
                end
                self:addItem(ListItem.new({text = '• '..action:tostring(), height = 20}, style, action:getidentifier(), TextListItemView.new))
            end
        end
    else
        self:addItem(ListItem.new({text = '• Idle', height = 20}, ListViewItemStyle.DarkMode.Text, 'idle', TextListItemView.new))
    end
end

return DebugView