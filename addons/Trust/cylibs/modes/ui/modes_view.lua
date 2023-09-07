local Button = require('cylibs/ui/button')
local DisposeBag = require('cylibs/events/dispose_bag')
local ListItem = require('cylibs/ui/list_item')
local ListView = require('cylibs/ui/list_view')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')

local ModesView = setmetatable({}, {__index = ListView })
ModesView.__index = ModesView

function ModesView.new(layout)
    local self = setmetatable(ListView.new(layout), ModesView)

    self.disposeBag = DisposeBag.new()

    self.saveButton = Button.new("SAVE", 120, 50)
    self:addChild(self.saveButton)

    self.disposeBag:add(self.saveButton:onClick():addAction(function(_, x, y)
        windower.send_command('trust save '..state.TrustMode.value)
    end))

    self.disposeBag:add(self:onClick():addAction(function(item)
        item.data.mode:cycle()
        item.data.text = item.data.modeName..': '..state[item.data.modeName].value

        self:updateItemView(item)
    end), self:onClick())

    return self
end

function ModesView:destroy()
    ListView.destroy(self)

    self:removeChild(self.saveButton)

    self.saveButton:destroy()
    self.disposeBag:destroy()
end

function ModesView:render()
    ListView.render(self)

    local x, y = self:get_pos()
    local width, _ = self:get_size()

    self.saveButton:set_pos(x + width - 80, y)
    self.saveButton:set_visible(self:is_visible())
    self.saveButton:render()
end

return ModesView