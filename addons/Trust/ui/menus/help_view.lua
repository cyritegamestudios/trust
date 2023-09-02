local ListItem = require('cylibs/ui/list_item')
local ListView = require('cylibs/ui/list_view')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')

local HelpView = setmetatable({}, {__index = ListView })
HelpView.__index = HelpView

function HelpView.new(main_job_name_short, layout)
    local self = setmetatable(ListView.new(layout), HelpView)

    self:addItem(ListItem.new({text = "Wiki", height = 20}, ListViewItemStyle.DarkMode.Text, "wiki-header", TextListItemView.new))
    self:addItem(ListItem.new({text = "• "..main_job_name_short, height = 20}, ListViewItemStyle.DarkMode.TextSmall, "job", TextListItemView.new))
    self:addItem(ListItem.new({text = "• Commands", height = 20}, ListViewItemStyle.DarkMode.TextSmall, "commands", TextListItemView.new))
    self:addItem(ListItem.new({text = "• Shortcuts", height = 20}, ListViewItemStyle.DarkMode.TextSmall, "shortcuts", TextListItemView.new))

    self:addItem(ListItem.new({text = '', height = 20}, ListViewItemStyle.DarkMode.Text, "spacer-1", TextListItemView.new))

    self:addItem(ListItem.new({text = "Discord", height = 20}, ListViewItemStyle.DarkMode.Text, "discord-header", TextListItemView.new))
    self:addItem(ListItem.new({text = "• Join the Discord", height = 20}, ListViewItemStyle.DarkMode.TextSmall, "join-discord", TextListItemView.new))

    self:onClick():addAction(function(item)
        local identifier = item:getIdentifier()
        if identifier == 'job' then
            local urlSuffix = self:getJobWikiPageSuffix(main_job_name_short)
            self:openUrl(urlSuffix)
        elseif identifier == 'commands' then
            self:openUrl('Commands')
        elseif identifier == 'shortcuts' then
            self:openUrl('Shortcuts')
        elseif identifier == 'join-discord' then
            self:openUrl('#support')
        end
    end)

    return self
end

function HelpView:destroy()
    ListView.destroy(self)
end

function HelpView:render()
    ListView.render(self)
end

function HelpView:openUrl(url_suffix)
    windower.open_url(settings.help.wiki_base_url..'/'..url_suffix)
end

function HelpView:getJobWikiPageSuffix(job_name_short)
    local job = res.jobs:with('ens', job_name_short)
    if job then
        local url_suffix = job.name:gsub(" ", "-")
        return url_suffix
    end
    return 'Trusts'
end

return HelpView