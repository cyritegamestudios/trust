local ListItem = require('cylibs/ui/list_item')
local ListView = require('cylibs/ui/list_view')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')
local View = require('cylibs/ui/view')

local BufferView = setmetatable({}, {__index = ListView })
BufferView.__index = BufferView

function BufferView.new(buffer, layout)
    local self = setmetatable(ListView.new(layout), BufferView)

    local jobAbilityNames = buffer:get_job_ability_names()
    if jobAbilityNames:length() > 0 then
        self:addItem(ListItem.new({text = "Job Abilities", height = 20}, ListViewItemStyle.DarkMode.Text, "ja-header", TextListItemView.new))
        for job_ability_name in jobAbilityNames:it() do
            local style = ListViewItemStyle.DarkMode.Text
            if buffer:is_job_ability_buff_active(job_ability_name) then
                style = ListViewItemStyle.DarkMode.HighlightedText
            end
            self:addItem(ListItem.new({text = '• '..job_ability_name, height = 20}, style, job_ability_name, TextListItemView.new))
        end
    end

    self:addItem(ListItem.new({text = '', height = 20}, ListViewItemStyle.DarkMode.Text, "spacer-1", TextListItemView.new))

    local selfSpells = buffer:get_self_spells()
    if selfSpells:length() > 0 then
        self:addItem(ListItem.new({text = "Self Spells", height = 20}, ListViewItemStyle.DarkMode.Text, "self-spells-header", TextListItemView.new))
        for spell in selfSpells:it() do
            local style = ListViewItemStyle.DarkMode.Text
            if buffer:is_self_buff_active(spell) then
                style = ListViewItemStyle.DarkMode.HighlightedText
            end
            self:addItem(ListItem.new({text = '• '..spell:description(), height = 20}, style, spell:get_spell().name, TextListItemView.new))
        end
    end

    self:addItem(ListItem.new({text = '', height = 20}, ListViewItemStyle.DarkMode.Text, "spacer-2", TextListItemView.new))

    local partySpells = buffer:get_party_spells()
    if partySpells:length() > 0 then
        self:addItem(ListItem.new({text = "Party Spells", height = 20}, ListViewItemStyle.DarkMode.Text, "party-spells-header", TextListItemView.new))
        for spell in partySpells:it() do
            self:addItem(ListItem.new({text = '• '..spell:description(), height = 20}, ListViewItemStyle.DarkMode.Text, "party-"..spell:get_spell().name, TextListItemView.new))
        end
    end

    return self
end

function BufferView:destroy()
    ListView.destroy(self)
end

function BufferView:render()
    ListView.render(self)
end

return BufferView