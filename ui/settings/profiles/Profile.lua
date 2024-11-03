local FileIO = require('files')
local serializer_util = require('cylibs/util/serializer_util')

local Profile = {}
Profile.__index = Profile

function Profile.new(trustVersion, setName, jobNameShort, modeSettings, jobSettings, weaponSkillSettings, subJobNameShort, subJobSettings)
    local self = setmetatable({}, Profile)

    self.trustVersion = trustVersion
    self.setName = setName
    self.jobNameShort = jobNameShort
    self.subJobNameShort = subJobNameShort
    self.settings = T{
        TrustVersion = trustVersion,
        SetName = setName,
        JobNameShort = jobNameShort,
        ModeSettings = modeSettings,
        JobSettings = jobSettings,
        WeaponSkillSettings = weaponSkillSettings,
    }
    if subJobNameShort and subJobSettings then
        self.settings.SubJobNameShort = subJobNameShort
        self.settings.SubJobSettings = subJobSettings
    end

    return self
end

function Profile:saveToFile()
    local file = FileIO.new(self:getFilePath())
    file:write('-- ===DO NOT MODIFY THIS FILE=== Profile for '..self.jobNameShort ..'\nreturn ' .. serializer_util.serialize(self.settings))
end

function Profile:getFilePath()
    if self.subJobNameShort then
        return 'data/export/profiles/'..self.jobNameShort..'_'..self.subJobNameShort..'_'..windower.ffxi.get_player().name..'_'..self.setName..'.lua'
    else
        return 'data/export/profiles/'..self.jobNameShort..'_'..windower.ffxi.get_player().name..'_'..self.setName..'.lua'
    end
end

return Profile