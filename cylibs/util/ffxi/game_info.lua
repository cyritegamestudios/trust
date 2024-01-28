local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local Renderer = require('cylibs/ui/views/render')

local GameInfo = {}
GameInfo.__index = GameInfo

--- Triggered when the in-game menu opens or closes
function GameInfo:onMenuChange()
    return self.menuChange
end

function GameInfo.new()
    local self = setmetatable({}, GameInfo)

    self.isMenuOpen = windower.ffxi.get_info().menu_open
    self.menuChange = Event.newEvent()

    self.disposeBag = DisposeBag.new()
    self.disposeBag:add(Renderer.shared():onPrerender():addAction(function()
        self:setIsMenuOpen(windower.ffxi.get_info().menu_open)
    end), Renderer.shared():onPrerender())

    return self
end

function GameInfo:destroy()
    self.disposeBag:destroy()

    self:onMenuChange():removeAllActions()
end

function GameInfo:setIsMenuOpen(isMenuOpen)
    if self.isMenuOpen == isMenuOpen then
        return
    end
    self.isMenuOpen = isMenuOpen

    self:onMenuChange():trigger(self, self.isMenuOpen)
end

return GameInfo