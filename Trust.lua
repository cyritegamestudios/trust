_addon.author = 'Cyrite'
_addon.commands = {'Trust','trust'}
_addon.name = 'Trust'
_addon.version = '10.0.8'
_addon.release_notes = [[
This update introduces Gambits, a powerful system inspired by Final Fantasy
12 that lets you customize the behavior of your Trust. Gambits are a
targeted "if X, then Y" conditional statement that can be used to cast
spells, perform job abilities and more.

	• Gambits
	    • There are 4 parts to a Gambit:
	        1. Ability Target (Self, Ally or Enemy)
	            • Self, Ally or Enemy.
	        2. Ability
	            • Spell, job ability or action to perform.
	        3. Conditions Target
	            • Target of conditions.
	        4. Conditions
	            • Conditions to check.

	• Conditions
	    • Customize when to perform Gambits with one or more conditions.
	    • Choose from HP %, MP %, TP, buffs, debuffs and more!

	• Puppetmaster
	    • Attachment sets can now be saved and loaded under
	      Settings > Automaton > Attachments, replacing
	      the need for the AutoControl addon!


	• Press escape or enter to exit.


	]]
_addon.release_url = "https://github.com/cyritegamestudios/trust/releases"

require('Trust-Include')

addon_settings = TrustAddonSettings.new()
addon_settings:loadSettings()

addon_enabled = ValueRelay.new(false)
addon_enabled:onValueChanged():addAction(function(_, isEnabled)
	if isEnabled then
		player.player:monitor()
		action_queue:enable()
	else
		action_queue:disable()
	end
end)

player = {}

local shortcuts = T{}

-- States

state.AutoEnableMode = M{['description'] = 'Auto Enable Mode', 'Auto', 'Off'}
state.AutoEnableMode:set_description('Auto', "Okay, I'll automatically get to work after the addon loads.")

state.AutoDisableMode = M{['description'] = 'Auto Disable Mode', 'Auto', 'Off'}
state.AutoDisableMode:set_description('Auto', "Okay, I'll automatically disable Trust after zoning.")

state.AutoUnloadOnDeathMode = M{['description'] = 'Auto Unload On Death Mode', 'Auto', 'Off'}
state.AutoUnloadOnDeathMode:set_description('Off', "Okay, I'll pause Trust after getting knocked out but won't unload it. DO NOT USE WHILE AFK!")
state.AutoUnloadOnDeathMode:set_description('Auto', "Okay, I'll automatically unload Trust after getting knocked out.")

state.AutoBuffMode = M{['description'] = 'Auto Buff Mode', 'Off', 'Auto'}
state.AutoBuffMode:set_description('Auto', "Okay, I'll automatically buff myself and the party.")

state.AutoEnmityReductionMode = M{['description'] = 'Auto Enmity Reduction Mode', 'Off', 'Auto'}
state.AutoEnmityReductionMode:set_description('Auto', "Okay, I'll automatically try to reduce my enmity.")

-- Main

function load_user_files(main_job_id, sub_job_id)
	load_logger_settings()

	notice('Loaded '.._addon.name..' ('.._addon.version..')')

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
		local mode_names = list.subtract(L(T(newSettings):keyset()), L{'Version'})
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
		local mode_names = list.subtract(L(T(newSettings):keyset()), L{'Version'})
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
		local mode_names = list.subtract(L(T(newSettings):keyset()), L{'Version'})
		state.WeaponSkillSettingsMode:options(T(mode_names):unpack())
		if mode_names:contains(oldValue) then
			state.WeaponSkillSettingsMode:set(oldValue)
		else
			state.WeaponSkillSettingsMode:set('Default')
		end
	end)

	player.trust = {}
	player.trust.main_job_settings = main_trust_settings:loadSettings()
	player.trust.sub_job_settings = sub_trust_settings:loadSettings()
	player.trust.weapon_skill_settings = weapon_skill_settings:loadSettings(true)

	state.MainTrustSettingsMode:on_state_change():addAction(function(_, new_value)
		player.trust.main_job:set_trust_settings(player.trust.main_job_settings[new_value])
	end)

	state.SubTrustSettingsMode:on_state_change():addAction(function(_, new_value)
		player.trust.sub_job:set_trust_settings(player.trust.sub_job_settings[new_value])
	end)

	main_job_trust, sub_job_trust = TrustFactory.trusts(trust_for_job_short(player.main_job_name_short, addon_settings:getSettings(), player.trust.main_job_settings.Default, action_queue, player.player, player.alliance, player.party), trust_for_job_short(player.sub_job_name_short, addon_settings:getSettings(), player.trust.sub_job_settings.Default, action_queue, player.player, player.alliance, player.party))

	main_job_trust:init()
	sub_job_trust:init()

	player.trust.main_job = main_job_trust
	player.trust.sub_job = sub_job_trust

	local skillchainer = Skillchainer.new(action_queue, weapon_skill_settings)

	player.trust.main_job:add_role(Attacker.new(action_queue))
	player.trust.main_job:add_role(CombatMode.new(action_queue, addon_settings:getSettings().battle.melee_distance, addon_settings:getSettings().battle.range_distance))
	player.trust.main_job:add_role(Eater.new(action_queue, main_job_trust:get_trust_settings().AutoFood))
	player.trust.main_job:add_role(Follower.new(action_queue, addon_settings:getSettings().follow.distance))
	player.trust.main_job:add_role(Pather.new(action_queue, 'data/paths/'))
	player.trust.main_job:add_role(skillchainer)
	player.trust.main_job:add_role(Gambiter.new(action_queue, player.trust.main_job_settings.Default.GambitSettings, skillchainer))
	player.trust.main_job:add_role(Spammer.new(action_queue, weapon_skill_settings))
	player.trust.main_job:add_role(Cleaver.new(action_queue, weapon_skill_settings))
	player.trust.main_job:add_role(Targeter.new(action_queue))
	player.trust.main_job:add_role(Truster.new(action_queue, addon_settings:getSettings().battle.trusts))
	player.trust.main_job:add_role(Aftermather.new(action_queue, player.trust.main_job:role_with_type("skillchainer")))
	player.trust.main_job:add_role(Assistant.new(action_queue))

	player.trust.sub_job:add_role(Gambiter.new(action_queue, player.trust.sub_job_settings.Default.GambitSettings, skillchainer))

	target_change_time = os.time()

	default_trust_name = string.gsub(string.lower(player.main_job_name), "%s+", "")

	load_trust_modes(player.main_job_name_short)
	load_trust_reactions(player.main_job_name_short)
	load_ui()
	load_trust_commands(player.main_job_name_short, player.trust.main_job, action_queue, player.party)

	main_trust_settings:copySettings()
	sub_trust_settings:copySettings()
	weapon_skill_settings:copySettings()

	if state.AutoEnableMode.value == 'Auto' then
		handle_start()
	else
		handle_stop()
	end

	check_version()
	check_files()
end

function load_trust_modes(job_name_short)
	trust_mode_settings = TrustModeSettings.new(job_name_short)
	trust_mode_settings:copySettings()

	local function update_for_new_modes(new_modes)
		for state_name, value in pairs(new_modes) do
			local state_var = get_state(state_name)
			if state_var then
				unregister_help_text(state_name, state_var)
				state_var:set(value)
				register_help_text(state_name, state_var)
			end
		end
	end

	state.TrustMode:on_state_change():addAction(function(_, new_value)
		logger.notice("TrustMode is now", new_value)
		local new_modes = trust_mode_settings:getSettings()[new_value]
		update_for_new_modes(new_modes)
	end)

	state.AutoUnloadOnDeathMode:on_state_change():addAction(function(_, new_value)
		if new_value == 'Off' then
			if addon_settings:getSettings().flags.show_death_warning then
				windower.add_to_chat(122, "---== WARNING ==---- Disabling unload on death may result in unexpected Trust behavior. It is not recommended that you use this setting while AFK.")
				addon_settings:getSettings().flags.show_death_warning = false
				addon_settings:saveSettings(true)
			end
		end
	end)

	trust_mode_settings:loadSettings()

	set_help_text_enabled(addon_settings:getSettings().help.mode_text_enabled)

	addon_message(207, 'Trust modes set to '..state.TrustMode.value)

	player.trust.trust_name = job_name_short
end

function load_trust_reactions(job_name_short)
	--trust_reactions = TrustReactions.new(job_name_short)
	--trust_reactions:loadReactions()
end

function load_trust_commands(job_name_short, trust, action_queue, party)
	local common_commands = L{
		AssistCommands.new(trust, action_queue),
		AttackCommands.new(trust, action_queue),
		FollowCommands.new(trust, action_queue),
		LoggingCommands.new(trust, action_queue),
		PathCommands.new(trust, action_queue),
		PullCommands.new(trust, action_queue),
		ScenarioCommands.new(trust, action_queue, party),
		SendAllCommands.new(trust, action_queue),
		SendCommands.new(trust, action_queue),
		SkillchainCommands.new(trust, weapon_skill_settings, action_queue),
		WidgetCommands.new(trust, action_queue, addon_settings, hud.widgetManager),
	}:extend(get_job_commands(job_name_short, trust, action_queue))

	local add_command = function(command)
		shortcuts[command:get_command_name()] = command
	end

	for command in common_commands:it() do
		add_command(command)
	end
end

function get_job_commands(job_name_short, trust, action_queue)
	local root_paths = L{windower.windower_path..'addons/libs/', windower.addon_path}
	for root_path in root_paths:it() do
		local file_prefix = root_path..'cylibs/trust/commands/'..job_name_short
		if windower.file_exists(file_prefix..'_'..windower.ffxi.get_player().name..'.lua') then
			local TrustCommands = require('cylibs/trust/commands/'..job_name_short..'_'..windower.ffxi.get_player().name)
			return L{ TrustCommands.new(trust, action_queue) }
		elseif windower.file_exists(file_prefix..'.lua') then
			local TrustCommands = require('cylibs/trust/commands/'..job_name_short)
			return L{ TrustCommands.new(trust, action_queue) }
		end
	end
	return L{}
end

function load_ui()
	hud = TrustHud.new(player, action_queue, addon_settings, trust_mode_settings, addon_enabled, 500, 500)
	hud:setNeedsLayout()
	hud:layoutIfNeeded()
end

function load_logger_settings()
	_libs.logger.settings.logtofile = addon_settings:getSettings().logging.logtofile
	_libs.logger.settings.defaultfile = 'logs/'..windower.ffxi.get_player().name..'_'..string.format("%s.log", os.date("%m-%d-%y"))

	logger.isEnabled = addon_settings:getSettings().logging.enabled
end

function trust_for_job_short(job_name_short, settings, trust_settings, action_queue, player, alliance, party)
	if job_name_short == 'WHM' then
		WhiteMageTrust = require('cylibs/trust/data/WHM')
		trust = WhiteMageTrust.new(settings.WHM, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'RDM' then
		RedMageTrust = require('cylibs/trust/data/RDM')
		trust = RedMageTrust.new(settings.RDM, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'COR' then
		CorsairTrust = require('cylibs/trust/data/COR')
		trust = CorsairTrust.new(settings.COR, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'GEO' then
		GeomancerTrust = require('cylibs/trust/data/GEO')
		trust = GeomancerTrust.new(settings.GEO, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'SMN' then
		SummonerTrust = require('cylibs/trust/data/SMN')
		trust = SummonerTrust.new(settings.SMN, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'SCH' then
		ScholarTrust = require('cylibs/trust/data/SCH')
		trust = ScholarTrust.new(settings.SCH, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'DRK' then
		DarkKnightTrust = require('cylibs/trust/data/DRK')
		trust = DarkKnightTrust.new(settings.DRK, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'PUP' then
		PuppetmasterTrust = require('cylibs/trust/data/PUP')
		trust = PuppetmasterTrust.new(settings.PUP, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'NIN' then
		NinjaTrust = require('cylibs/trust/data/NIN')
		trust = NinjaTrust.new(settings.NIN, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'WAR' then
		WarriorTrust = require('cylibs/trust/data/WAR')
		trust = WarriorTrust.new(settings.WAR, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'RUN' then
		RuneFencerTrust = require('cylibs/trust/data/RUN')
		trust = RuneFencerTrust.new(settings.RUN, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'BLM' then
		BlackMageTrust = require('cylibs/trust/data/BLM')
		trust = BlackMageTrust.new(settings.BLM, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'PLD' then
		PaladinTrust = require('cylibs/trust/data/PLD')
		trust = PaladinTrust.new(settings.PLD, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'BRD' then
		BardTrust = require('cylibs/trust/data/BRD')
		trust = BardTrust.new(settings.BRD, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'MNK' then
		MonkTrust = require('cylibs/trust/data/MNK')
		trust = MonkTrust.new(settings.MNK, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'BLU' then
		BlueMageTrust = require('cylibs/trust/data/BLU')
		trust = BlueMageTrust.new(settings.BLU, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'DNC' then
		DancerTrust = require('cylibs/trust/data/DNC')
		trust = DancerTrust.new(settings.DNC, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'SAM' then
		SamuraiTrust = require('cylibs/trust/data/SAM')
		trust = SamuraiTrust.new(settings.SAM, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'DRG' then
		DragoonTrust = require('cylibs/trust/data/DRG')
		trust = DragoonTrust.new(settings.DRG, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'RNG' then
		RangerTrust = require('cylibs/trust/data/RNG')
		trust = RangerTrust.new(settings.RNG, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'THF' then
		ThiefTrust = require('cylibs/trust/data/THF')
		trust = ThiefTrust.new(settings.THF, action_queue, settings.battle, trust_settings)
	elseif job_name_short == 'BST' then
		BeastmasterTrust = require('cylibs/trust/data/BST')
		trust = BeastmasterTrust.new(settings.BST, action_queue, settings.battle, trust_settings)
	else
		trust = Trust.new()
	end

	trust:set_player(player)
	trust:set_alliance(alliance)
	trust:set_party(party)

	return trust
end

function check_version()
	local version = addon_settings:getSettings().version
	if version ~= _addon.version then
		addon_settings:getSettings().version = _addon.version
		addon_settings:saveSettings()

		local Frame = require('cylibs/ui/views/frame')

		local updateView = TrustMessageView.new("Version ".._addon.version, "What's new", _addon.release_notes, "Click here for full release notes.", Frame.new(0, 0, 500, 625))

		updateView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
			updateView:getDelegate():deselectItemAtIndexPath(indexPath)
			windower.open_url(_addon.release_url)
		end)
		updateView:setDismissCallback(function()
			hud:getViewStack():dismiss()
		end)

		hud:getViewStack():present(updateView)
	end
end

function check_files()
	if addon_settings:getSettings().flags.check_files then
		if windower.file_exists(windower.windower_path..'/addons/libs/cylibs/Cylibs-Include.lua') then
			error('Please remove the', windower.windower_path..'addons/libs/cylibs/', 'folder and reload Trust.')
		end
	end
end

-- Helpers

function addon_message(color,str)
    windower.add_to_chat(color, _addon.name..': '..str)
end

-- Handlers

function handle_tic(old_time, new_time)
	if not trust or not windower.ffxi.get_player() or not addon_enabled:getValue() or not player or not player.trust then return end

	action_queue:set_mode(ActionQueue.Mode.Batch)

	player.trust.main_job:tic(old_time, new_time)
	player.trust.sub_job:tic(old_time, new_time)

	action_queue:set_mode(ActionQueue.Mode.Default)
end

function handle_status_change(new_status_id, old_status_id)
	player.status = res.statuses[new_status_id].english

	if player.status == 'Dead' then
		if state.AutoUnloadOnDeathMode.value == 'Off' then
			handle_stop()
		else
			handle_unload()
		end
	end
end

function handle_start()
	addon_enabled:setValue(true)
end

function handle_stop()
	addon_enabled:setValue(false)
end

function handle_toggle_addon()
	addon_enabled:setValue(not addon_enabled:getValue())
end

function handle_reload()
	main_trust_settings:loadSettings()
	sub_trust_settings:loadSettings()
end

function handle_unload()
	windower.chat.input('// lua unload trust')
end

function handle_job_change(_, _, _, _)
	handle_stop()
	unloaded()
	handle_unload()
	--windower.send_command('lua r trust')
end

function handle_zone_change(new_zone_id, old_zone_id)
	action_queue:clear()
	player.party:set_assist_target(player.party:get_player())
	if state.AutoDisableMode.value ~= 'Off' then
		handle_stop()
	end
end

function handle_save_trust(mode_name)
	trust_mode_settings:saveSettings(mode_name or state.TrustMode.value)
end

function handle_create_trust(job_name_short)
	main_trust_settings:copySettings()
	sub_trust_settings:copySettings()
end

function handle_migrate_settings()
	for job_name_short in job_util.all_jobs():it() do
		if windower.file_exists(windower.addon_path..'data/'..job_name_short..'_'..windower.ffxi.get_player().name..'.lua') then
			local legacy_trust_settings = TrustSettingsLoader.new(job_name_short)
			local settings = legacy_trust_settings:loadSettings()
			if settings then
				TrustSettingsLoader.migrateSettings(job_name_short, settings, true)
			end
		end
	end
	addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, all of my settings have been upgraded to the latest and greatest!")
end

function handle_trust_status()
	local statuses = L{}
	for key,var in pairs(state) do
		statuses:append(key..': '..var.value)
	end
	statuses:sort()

	for status in statuses:it() do
		addon_message(207, status)
	end

	if player.party:get_assist_target() then
		addon_message(209, 'Assisting '..player.party:get_assist_target():get_name())
	end
end

function handle_command(args)
	local actions = L{
		SpellAction.new(0, 0, 0, spell_util.spell_id('Cure'), nil, player.player),
		WaitAction.new(0, 0, 0, 2)
	}

	local action = SequenceAction.new(actions, 'test_action')
	action.priority = ActionPriority.highest

	action_queue:push_action(action, false)
end

function handle_toggle_menu()
	hud:toggleMenu()
end

function handle_debug()
	print(num_created)
	print('images', num_images_created)

	print(L(windower.ffxi.get_player().buffs):map(function(buff_id)
		return res.buffs:with('id', buff_id).en
	end))

	local alliance = player.alliance
	for i = 1, 3 do
		local party = alliance:get_parties()[i]
		logger.notice("Trust", "debug", "party", i, party:get_party_members(true):map(function(party_member) return party_member:get_name() end))
	end
end

function handle_command_list(command_name)
	addon_message(122, 'Addon Commands')

	local command_descriptions = shortcuts:filter(function(command)
		return command_name == nil or command:get_command_name() == command_name
	end):map(function(command)
		return command:description()
	end)

	for description in command_descriptions:it() do
		windower.add_to_chat(122, description)
	end
end

-- Setup

local commands = T{}

commands['start'] = handle_start
commands['stop'] = handle_stop
commands['toggle'] = handle_toggle_addon
commands['reload'] = handle_reload
commands['save'] = handle_save_trust
commands['create'] = handle_create_trust
commands['status'] = handle_trust_status
commands['command'] = handle_command
commands['debug'] = handle_debug
commands['tests'] = handle_tests
commands['help'] = handle_help
commands['migrate'] = handle_migrate_settings
commands['menu'] = handle_toggle_menu
commands['commands'] = handle_command_list

local function addon_command(cmd, ...)
    local cmd = cmd or 'help'

    if commands[cmd] then
		local msg = nil
		if not L{'cycle', 'set'}:contains(cmd) then
			msg = commands[cmd](unpack({...}))
		end
		if msg then
			error(msg)
		end
	elseif L{player.main_job_name_short, player.main_job_name_short:lower()}:contains(cmd) and player.trust.main_job_commands then
		player.trust.main_job_commands:handle_command(unpack({...}))
	elseif L{player.sub_job_name_short, player.sub_job_name_short:lower()}:contains(cmd) and player.trust.sub_job_commands then
		player.trust.sub_job_commands:handle_command(unpack({...}))
	elseif shortcuts[cmd] then
		shortcuts[cmd]:handle_command(...)
	else
		if not L{'cycle', 'set', 'help'}:contains(cmd) then
			error("Unknown command %s":format(cmd))
		end
    end
end

function load_chunk_event()
	load_user_files(windower.ffxi.get_player().main_job_id, windower.ffxi.get_player().sub_job_id)

	trust_remote_commands = TrustRemoteCommands.new(addon_settings:getSettings().remote_commands.whitelist, commands:keyset())

	IpcRelay.shared():on_message_received():addAction(function(ipc_message)
		if ipc_message.__class == CommandMessage.__class then
			local target_name = ipc_message:get_target_name()
			if target_name == 'all' or target_name == windower.ffxi.get_player().name then
				windower.send_command(ipc_message:get_windower_command())
			end
		end
	end)
end

function unload_chunk_event()
	for key in L{'up','down','left','right','enter', addon_settings:getSettings().menu_key}:extend(L{'a','w','s','d','f','e','h','i','k','l'}):it() do
		windower.send_command('unbind %s':format(key))
	end
	IpcRelay.shared():destroy()
end

function unloaded()
    if user_events then
        for _,event in pairs(user_events) do
            windower.unregister_event(event)
        end
        user_events = nil
    end
	if player.trust then
		if player.trust.main_job then
			player.trust.main_job:destroy()
		end
		if player.trust.sub_job then
			player.trust.sub_job:destroy()
		end
	end
	player.trust = nil
	unload_chunk_event()
end

function loaded()
    if not user_events then
		load_chunk_event()
        user_events = {}
		user_events.status = windower.register_event('time change', handle_tic)
		user_events.status = windower.register_event('status change', handle_status_change)
		user_events.job_change = windower.register_event('job change', handle_job_change)
		user_events.zone_change = windower.register_event('zone change', handle_zone_change)
    end
	
	windower.send_command('bind %s trust menu':format(addon_settings:getSettings().menu_key))
end

windower.register_event('addon command', addon_command)
windower.register_event('load', loaded)
windower.register_event('unload', unloaded)
windower.register_event('logout', function() windower.send_command('lua unload trust')  end)
