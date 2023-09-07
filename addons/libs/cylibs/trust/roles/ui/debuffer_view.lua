local ListItem = require('cylibs/ui/list_item')
local ListView = require('cylibs/ui/list_view')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')

local DebufferView = setmetatable({}, {__index = ListView })
DebufferView.__index = DebufferView

function DebufferView.new(debuffer, battle_target, layout)
    local self = setmetatable(ListView.new(layout), DebufferView)

    self:addItem(ListItem.new({text = "Spells", height = 20}, ListViewItemStyle.DarkMode.Text, "spells-header", TextListItemView.new))
    for spell in debuffer:get_debuff_spells():it() do
        local style = ListViewItemStyle.DarkMode.Text
        local debuff = buff_util.debuff_for_spell(spell:get_spell().id)
        if debuff and battle_target and battle_target:has_debuff(debuff.id) then
            style = ListViewItemStyle.DarkMode.HighlightedText
        end
        self:addItem(ListItem.new({text = '• '..spell:description(), height = 20}, style, spell:get_spell().name, TextListItemView.new))
    end

    return self
end

function DebufferView:destroy()
    ListView.destroy(self)
end

function DebufferView:render()
    ListView.render(self)
end

return DebufferView