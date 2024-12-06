---------------------------
-- Switch to another target.
-- @class module
-- @name LoadUserFilesAction

local alter_ego_util = require('cylibs/util/alter_ego_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local packets = require('packets')
local Timer = require('cylibs/util/timers/timer')

local Action = require('cylibs/actions/action')
local LoadUserFilesAction = setmetatable({}, {__index = Action })
LoadUserFilesAction.__index = LoadUserFilesAction

function LoadUserFilesAction.new(main_job_id, sub_job_id)
    local self = setmetatable(Action.new(0, 0, 0, nil, L{}), LoadUserFilesAction)

    self.main_job_id = main_job_id
    self.sub_job_id = sub_job_id

    return self
end

function LoadUserFilesAction:destroy()
    Action.destroy(self)
end

function LoadUserFilesAction:init()
    return coroutine.create(function()
        load_i18n_settings()
        load_logger_settings()

        addon_system_message("Loaded Trust v".._addon.version)

        action_queue = ActionQueue.new(nil, true, 5, false, true)

        main_job_id = tonumber(main_job_id)

        if main_job_id and res.jobs[main_job_id] then
            player.main_job_id = main_job_id
            if res.jobs[main_job_id] then
                player.main_job_name = res.jobs[main_job_id]['en']
                player.main_job_name_short = res.jobs[main_job_id]['ens']
            end
        end

        if sub_job_id and res.jobs[sub_job_id] then
            player.sub_job_id = sub_job_id
            if res.jobs[sub_job_id] then
                player.sub_job_name = res.jobs[sub_job_id]['en']
                player.sub_job_name_short = res.jobs[sub_job_id]['ens']
            end
        end

        player.player = Player.new(windower.ffxi.get_player().id)
        player.player:monitor()

        local party_chat = PartyChat.new(addon_settings:getSettings().chat.ipc_enabled)
        player.alliance = Alliance.new(party_chat)
        player.alliance:monitor()
        player.party = player.alliance:get_parties()[1]
        player.party:add_party_member(windower.ffxi.get_player().id, windower.ffxi.get_player().name)
        player.party:set_assist_target(player.party:get_player())

        handle_status_change(windower.ffxi.get_player().status, windower.ffxi.get_player().status)

        state.MainTrustSettingsMode = M{['description'] = 'Main Trust Settings Mode', 'Default'}

        main_trust_settings = TrustSettingsLoader.new(player.main_job_name_short)
        main_trust_settings:onSettingsChanged():addAction(function(newSettings)
            local oldValue = state.MainTrustSettingsMode.value
            player.trust.main_job_settings = newSettings
            local mode_names = list.subtract(L(T(newSettings):keyset()), L{'Migrations','Version'})
            if not mode_names:equals(state.MainTrustSettingsMode:options()) then
                state.MainTrustSettingsMode:options(T(mode_names):unpack())
            end
            if mode_names:contains(oldValue) then
                state.MainTrustSettingsMode:set(oldValue)
            else
                state.MainTrustSettingsMode:set('Default')
            end
        end)

        state.SubTrustSettingsMode = M{['description'] = 'Sub Trust Settings Mode', 'Default'}

        sub_trust_settings = TrustSettingsLoader.new(player.sub_job_name_short)
        sub_trust_settings:onSettingsChanged():addAction(function(newSettings)
            local oldValue = state.SubTrustSettingsMode.value
            player.trust.sub_job_settings = newSettings
            local mode_names = list.subtract(L(T(newSettings):keyset()), L{'Migrations','Version'})
            if not mode_names:equals(state.SubTrustSettingsMode:options()) then
                state.SubTrustSettingsMode:options(T(mode_names):unpack())
            end
            if mode_names:contains(oldValue) then
                state.SubTrustSettingsMode:set(oldValue)
            else
                state.SubTrustSettingsMode:set('Default')
            end
        end)

        state.WeaponSkillSettingsMode = M{['description'] = 'Weapon Skill Settings Mode', 'Default'}

        weapon_skill_settings = WeaponSkillSettings.new(player.main_job_name_short)
        weapon_skill_settings:onSettingsChanged():addAction(function(newSettings)
            local oldValue = state.WeaponSkillSettingsMode.value
            player.trust.weapon_skill_settings = newSettings
            local mode_names = list.subtract(L(T(newSettings):keyset()), L{'Migrations','Version'})
            state.WeaponSkillSettingsMode:options(T(mode_names):unpack())
            if mode_names:contains(oldValue) then
                state.WeaponSkillSettingsMode:set(oldValue)
            else
                state.WeaponSkillSettingsMode:set('Default')
            end
        end)

        print('finished')
        coroutine.yield(true)
    end)
end

function LoadUserFilesAction:perform()
    print('performing')
    local success = coroutine.resume(self:init())
    --self:complete(success)
end

function LoadUserFilesAction:gettype()
    return "switchtargetaction"
end

function LoadUserFilesAction:getrawdata()
    local res = {}
    return res
end

function LoadUserFilesAction:tostring()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    return 'Targeting → '..target.name
end

function LoadUserFilesAction:debug_string()
    local mob = windower.ffxi.get_mob_by_index(self.target_index)
    return "SwitchTargetAction: %s (%d)":format(mob.name, mob.id)
end

return LoadUserFilesAction



