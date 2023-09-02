local ListItem = require('cylibs/ui/list_item')
local ListView = require('cylibs/ui/list_view')
local View = require('cylibs/ui/view')

local ModesView = setmetatable({}, {__index = View })
ModesView.__index = ModesView

function ModesView.new(layout)
    local self = setmetatable(ListView.new(layout), ModesView)

    local modeNames = L(T(state):keyset()):sort()
    local modeTabs = L{}
    local modeTab = L{}

    for modeName in modeNames:it() do
        if modeTab:length() < 19 then
            modeTab:append(ListItem.new({text = modeName..': '..state[modeName].value, mode = state[modeName], modeName = modeName, height = 20}, ListViewItemStyle.DarkMode.TextSmall, modeName, TextListItemView.new))
        else
            modeTabs:append(modeTab)
            modeTab = L{}
            modeTab:append(ListItem.new({text = modeName..': '..state[modeName].value, mode = state[modeName], modeName = modeName, height = 20}, ListViewItemStyle.DarkMode.TextSmall, modeName, TextListItemView.new))
        end
    end
    if modeTab:length() > 0 then
        modeTabs:append(modeTab)
    end

    local modeTabIndex = 1
    for modeTab in modeTabs:it() do
        local modesView = ListView.new(VerticalListlayout.new(380, 0))
        modesView:addItems(modeTab)

        tabItems:append(TabItem.new("Modes "..modeTabIndex, modesView))

        modeTabIndex = modeTabIndex + 1

        modesView:onClick():addAction(function(item)
            item.data.mode:cycle()
            item.data.text = item.data.modeName..': '..state[item.data.modeName].value
            modesView:updateItemView(item)
        end)
    end

    return self
end

function ModesView:destroy()
    View.destroy(self)
end

function ModesView:render()
end

return ModesView