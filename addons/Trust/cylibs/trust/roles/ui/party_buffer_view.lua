local ListItem = require('cylibs/ui/list_item')
local ListView = require('cylibs/ui/list_view')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')
local View = require('cylibs/ui/view')

local PartyBufferView = setmetatable({}, {__index = ListView })
PartyBufferView.__index = PartyBufferView

function PartyBufferView.new(buffer, layout)
    local self = setmetatable(ListView.new(layout), PartyBufferView)

    local partySpells = buffer:get_party_spells()
    if partySpells:length() > 0 then
        self:addItem(ListItem.new({text = "Buffs", height = 20}, ListViewItemStyle.DarkMode.Text, "party-spells-header", TextListItemView.new))
        for spell in partySpells:it() do
            self:addItem(ListItem.new({text = '• '..spell:description(), height = 20}, ListViewItemStyle.DarkMode.Text, "party-"..spell:get_spell().name, TextListItemView.new))
        end
    end

    return self
end

function PartyBufferView:destroy()
    ListView.destroy(self)
end

function PartyBufferView:render()
    ListView.render(self)
end

return PartyBufferView