_addon.author = 'Cyrite'
_addon.commands = {'Trust','trust'}
_addon.name = 'Trust'
_addon.version = '15.5.5'
_addon.release_notes = ""
_addon.release_url = "https://github.com/cyritegamestudios/trust/releases"

windower.trust = {}
windower.trust.get_temp_dir = function(file_name)
	if file_name then
		return string.format("%s/temp/%s", windower.addon_path..'data', file_name)
	else
		return string.format("%s/temp", windower.addon_path..'data')
	end
end

-- Main

function load_user_files(main_job_id, sub_job_id)
	local start_time = os.clock()

	addon_system_message("Loaded Trust v".._addon.version)

	action_queue = ActionQueue.new(nil, true, 5, false, true, true)

	addon_enabled = ValueRelay.new(false)
	addon_enabled:onValueChanged():addAction(function(_, isEnabled)
		if isEnabled then
			player.player:monitor()
			action_queue:enable()
		else
			action_queue:disable()
		end
	end)

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

	local MigrationManager = require('settings/migrations/migration_manager')

	migration_manager = MigrationManager.new(main_trust_settings, addon_settings, weapon_skill_settings)
	migration_manager:perform()

	if player.sub_job_name ~= 'None' then
		sub_job_migration_manager = MigrationManager.new(sub_trust_settings, addon_settings, nil)
		sub_job_migration_manager:perform()
	end

	state.MainTrustSettingsMode:on_state_change():addAction(function(_, new_value)
		i18n.set_current_gearswap_locale(player.trust.main_job_settings[new_value].GearSwapSettings.Language or i18n.Locale.English)
		player.trust.main_job:set_trust_settings(player.trust.main_job_settings[new_value])
	end)

	state.SubTrustSettingsMode:on_state_change():addAction(function(_, new_value)
		player.trust.sub_job:set_trust_settings(player.trust.sub_job_settings[new_value])
	end)

	local TrustFactory = require('cylibs/trust/trust_factory')
	main_job_trust, sub_job_trust = TrustFactory.trusts(
			trust_for_job_short(player.main_job_name_short, addon_settings:getSettings(), player.trust.main_job_settings.Default, addon_settings, action_queue, player.player, player.alliance, player.party),
			trust_for_job_short(player.sub_job_name_short, addon_settings:getSettings(), player.trust.sub_job_settings.Default, addon_settings, action_queue, player.player, player.alliance, player.party)
	)

	main_job_trust:init()
	sub_job_trust:init()

	player.trust.main_job = main_job_trust
	player.trust.sub_job = sub_job_trust

	local skillchainer = Skillchainer.new(action_queue, weapon_skill_settings, player.trust.main_job:get_job())

	if player.trust.main_job:role_with_type("puller") == nil and player.trust.sub_job:role_with_type("puller") == nil then
		local pull_abilities = player.trust.main_job_settings.Default.PullSettings.Abilities
		if pull_abilities == nil or pull_abilities:length() == 0 then
			pull_abilities = L{ Approach.new() }
		end
		player.trust.main_job:add_role(Puller.new(action_queue, player.trust.main_job_settings.Default.PullSettings, player.trust.main_job))
	end

	player.trust.main_job:add_role(Reacter.new(action_queue, player.trust.main_job_settings.Default.ReactionSettings, skillchainer))
	player.trust.main_job:add_role(Gambiter.new(action_queue, player.trust.main_job_settings.Default.GambitSettings))
	player.trust.main_job:add_role(Attacker.new(action_queue))
	player.trust.main_job:add_role(CombatMode.new(action_queue, addon_settings:getSettings().battle.melee_distance, addon_settings:getSettings().battle.range_distance, addon_enabled))
	local follower = Follower.new(action_queue, addon_settings:getSettings().follow.distance, addon_settings)
	player.trust.main_job:add_role(follower)
	player.trust.main_job:add_role(Pather.new(action_queue, 'data/paths/', follower))
	player.trust.main_job:add_role(skillchainer)
	player.trust.main_job:add_role(Spammer.new(action_queue, weapon_skill_settings))
	player.trust.main_job:add_role(Cleaver.new(action_queue, weapon_skill_settings))
	player.trust.main_job:add_role(Truster.new(action_queue, addon_settings:getSettings().battle.trusts))
	player.trust.main_job:add_role(Aftermather.new(action_queue, player.trust.main_job:role_with_type("skillchainer")))

	if player.sub_job_name_short ~= 'NON' then
		player.trust.sub_job:add_role(Reacter.new(action_queue, player.trust.sub_job_settings.Default.ReactionSettings, skillchainer))
		player.trust.sub_job:add_role(Gambiter.new(action_queue, player.trust.sub_job_settings.Default.GambitSettings))
	end

	player.trust.main_job:on_trust_roles_changed():addAction(function(trust, roles_added, roles_removed)
		TrustFactory.dedupe_roles(player.trust.main_job, player.trust.sub_job)
	end)

	player.trust.sub_job:on_trust_roles_changed():addAction(function(trust, roles_added, roles_removed)
		TrustFactory.dedupe_roles(player.trust.main_job, player.trust.sub_job)
	end)

	default_trust_name = string.gsub(string.lower(player.main_job_name), "%s+", "")

	load_trust_modes(player.main_job_name_short)

	windower.trust.settings = {}
	windower.trust.settings.get_addon_settings = function()
		return addon_settings
	end
	windower.trust.settings.get_mode_settings = function()
		return trust_mode_settings
	end
	windower.trust.settings.get_job_settings = function(job_name_short)
		for job_settings in L{ main_trust_settings, sub_trust_settings }:it() do
			if job_settings.jobNameShort == job_name_short then
				return job_settings
			end
		end
		return nil
	end
	windower.trust.get_inventory = function()
		return player.party:get_player():get_inventory()
	end

	windower.trust.ui = {}
	windower.trust.ui.get_hud = function()
		return hud
	end

	windower.trust.ui.widgets = {}
	windower.trust.ui.get_widget = function(widget_name)
		return widgets:getWidget(widget_name)
	end

	load_ui()
	load_trust_commands(player.main_job_name_short, player.trust.main_job, player.sub_job_name_short, player.trust.sub_job, action_queue, player.party, main_trust_settings, sub_trust_settings)

	if state.AutoEnableMode.value == 'Auto' then
		addon_enabled:setValue(true)
	else
		addon_enabled:setValue(false)
	end

	register_chat_handlers()
	check_files()

	local end_time = os.clock()

	local load_time = math.floor((end_time - start_time) * 1000 + 0.5) / 1000

	addon_system_message("Trust is up to date ("..load_time.."s).")

	logger.notice('performance', 'load_user_files', 'end', load_time)
end

function load_trust_modes(job_name_short)
	trust_mode_settings = TrustModeSettings.new(job_name_short, windower.ffxi.get_player().name, state.TrustMode)
	trust_mode_settings:copySettings()

	local function update_for_new_modes(new_modes)
		for state_name, value in pairs(new_modes) do
			local state_var = get_state(state_name)
			if state_var then
				unregister_help_text(state_name, state_var)
				if S(state_var:options()):contains(value) then
					state_var:set(value)
				else
					addon_system_error(get_state_name(state_name)..' has no value '..value..'. To fix this error, choose a new value and save your profile.')
				end
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

	player.trust.trust_name = job_name_short
end

function load_trust_commands(job_name_short, main_job_trust, sub_job_name_short, sub_job_trust, action_queue, party, main_trust_settings, sub_trust_settings)
	local common_commands = L{
		AssistCommands.new(main_job_trust, action_queue),
		AttackCommands.new(main_job_trust, action_queue),
		state.AutoBuffMode and BuffCommands.new(),
		state.AutoDebuffMode and DebuffCommands.new(),
		FollowCommands.new(main_job_trust, action_queue),
		GeneralCommands.new(main_job_trust, action_queue, addon_enabled, trust_mode_settings, main_trust_settings, sub_trust_settings),
		state.AutoHealMode and HealCommands.new(main_job_trust:role_with_type("healer") and main_job_trust or sub_job_trust:role_with_type("healer") and sub_job_trust),
		state.AutoStatusRemovalMode and StatusRemovalCommands.new(),
		LoggingCommands.new(main_job_trust, action_queue),
		state.AutoMagicBurstMode and MagicBurstCommands.new(main_job_trust, main_trust_settings, action_queue),
		MenuCommands.new(main_job_trust, action_queue, hud),
		MountCommands.new(main_job_trust),
		state.AutoNukeMode and NukeCommands.new(main_job_trust, main_trust_settings, action_queue),
		PathCommands.new(main_job_trust, action_queue),
		ProfileCommands.new(main_trust_settings, sub_trust_settings, trust_mode_settings, weapon_skill_settings),
		PullCommands.new(main_job_trust, action_queue, main_job_trust:role_with_type("puller") or sub_job_trust:role_with_type("puller")),
		ScenarioCommands.new(main_job_trust, action_queue, party, addon_settings),
		SendAllCommands.new(main_job_trust, action_queue),
		SendCommands.new(main_job_trust, action_queue),
		SkillchainCommands.new(main_job_trust, weapon_skill_settings, action_queue),
		SoundCommands.new(hud.mediaPlayer),
		TargetCommands.new(main_trust_settings, state.MainTrustSettingsMode, party, action_queue, main_job_trust:role_with_type("puller") or sub_job_trust:role_with_type("puller")),
		WarpCommands.new(main_job_trust:role_with_type("follower").walk_action_queue),
	}:compact_map():extend(get_job_commands(job_name_short, main_job_trust, action_queue, main_trust_settings, weapon_skill_settings)):extend(get_job_commands(sub_job_name_short, sub_job_trust, action_queue, sub_trust_settings, weapon_skill_settings))

	hud:setCommands(common_commands)

	local add_command = function(command)
		shortcuts[command:get_command_name()] = command
	end

	for command in common_commands:it() do
		add_command(command)
	end

	local CommandWidget = require('ui/widgets/CommandWidget')

	command_widget = CommandWidget.new()
	command_widget:setPosition(16, windower.get_windower_settings().ui_y_res - 233)
	command_widget:setUserInteractionEnabled(true)
	command_widget:setAllowsMultipleSelection(false)
	command_widget:setVisible(false)

	local all_commands = L{}

	for command in common_commands:it() do
		for text in command:get_all_commands():it() do
			all_commands:append(text)
		end
	end

	for state_name, _ in pairs(state) do
		local state_var = get_state(state_name)
		if state_var then
			all_commands:append('// trust cycle '..state_name)
			for option in state_var:options():it() do
				all_commands:append('// trust set '..state_name..' '..option)
			end
		end
	end

	all_commands:sort()

	local ChatAutoCompleter = require('cylibs/ui/input/autocomplete/chat_auto_completer')
	local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

	command_widget:getDelegate():didHighlightItemAtIndexPath():addAction(function(indexPath)
		local term = command_widget:getDataSource():itemAtIndexPath(indexPath)
		if term and term:getText() then
			term = "// trust "..term:getText()

			local description

			local args = string.split(term, " ")
			if args[3] and args[4] and shortcuts[args[3]] and type(shortcuts[args[3]]) ~= 'function' then
				description = shortcuts[args[3]]:get_description(args[4], true)
			end
			if description == nil or description:empty() then
				description = term
			end

			if not hud.trustMenu:isVisible() then
				hud.infoBar:setTitle("Commands")
				hud.infoBar:setDescription(description or '')
				hud.infoBar:setVisible(description ~= nil)
				hud.infoBar:layoutIfNeeded()
			end
		end
	end)

	chat_auto_completer = ChatAutoCompleter.new(all_commands)
	chat_auto_completer:onAutoCompleteListChange():addAction(function(_, terms)
		command_widget:getDataSource():removeAllItems()
		if not addon_settings:getSettings().autocomplete.visible then
			return
		end
		if terms:length() > 0 then
			command_widget:setVisible(true)
			command_widget:setContentOffset(0, 0)
			local configItem = MultiPickerConfigItem.new("Commands", L{}, terms:map(function(term) return term:gsub("^//%s*trust ", "") end), function(term)
				return term
			end)
			command_widget:setConfigItems(L{ configItem })

			if not hud.trustMenu:isVisible() then
				hud.infoBar:setTitle("Commands")
				hud.infoBar:setDescription('Press Ctrl + Up to focus on the command list.')
				hud.infoBar:setVisible(true)
				hud.infoBar:layoutIfNeeded()
			end
		else
			if command_widget:isVisible() then
				command_widget:setVisible(false)
				command_widget:setContentOffset(0, 0)
				if not hud.trustMenu:isVisible() then
					hud.infoBar:setVisible(false)
					hud.infoBar:layoutIfNeeded()
				end
			end
		end
	end)
end

function get_job_commands(job_name_short, trust, action_queue, main_trust_settings, weapon_skill_settings)
	local root_paths = L{windower.windower_path..'addons/libs/', windower.addon_path}
	for root_path in root_paths:it() do
		local file_prefix = root_path..'cylibs/trust/commands/'..job_name_short
		if windower.file_exists(file_prefix..'_'..windower.ffxi.get_player().name..'.lua') then
			local TrustCommands = require('cylibs/trust/commands/'..job_name_short..'_'..windower.ffxi.get_player().name)
			return L{ TrustCommands.new(trust, action_queue, main_trust_settings, weapon_skill_settings) }
		elseif windower.file_exists(file_prefix..'.lua') then
			local TrustCommands = require('cylibs/trust/commands/'..job_name_short)
			return L{ TrustCommands.new(trust, action_queue, main_trust_settings, weapon_skill_settings) }
		end
	end
	return L{}
end

function load_ui()
	local FFXISoundTheme = require('sounds/FFXISoundTheme')
	local MediaPlayer = require('cylibs/sounds/media_player')

	local mediaPlayer = MediaPlayer.new(windower.addon_path..'sounds')
	mediaPlayer:setEnabled(not addon_settings:getSettings().sounds.sound_effects.disabled)

	local soundTheme = FFXISoundTheme.default()

	local TrustWidgets = require('ui/TrustWidgets')

	widgets = TrustWidgets.new(action_queue, addon_enabled, player.trust.main_job, mediaPlayer, soundTheme)
	widgets:setNeedsLayout()
	widgets:layoutIfNeeded()
	widgets:setUserInteractionEnabled(true)

	hud = TrustHud.new(player, action_queue, addon_settings, trust_mode_settings, addon_enabled, 500, 500, mediaPlayer, soundTheme)

	hud:addSubview(widgets)

	hud:setNeedsLayout()
	hud:layoutIfNeeded()
end

function trust_for_job_short(job_name_short, settings, trust_settings, addon_settings, action_queue, player, alliance, party)
	local trust
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
		trust = BardTrust.new(settings.BRD, action_queue, settings.battle, trust_settings, addon_settings)
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
		NoneTrust = require('cylibs/trust/data/NON')
		trust = NoneTrust.new(action_queue)
	end

	trust:set_player(player)
	trust:set_alliance(alliance)
	trust:set_party(party)

	return trust
end

function check_version()
	local UrlRequest = require('cylibs/util/network/url_request')

	local manifest_url = addon_settings:getSettings().updater.manifest_url or 'https://raw.githubusercontent.com/cyritegamestudios/trust/main/manifest.json'
	local request = UrlRequest.new('GET', manifest_url, {})

	local fetch = request:get()
	local success, response, code, body, status = coroutine.resume(fetch)
	if success then
		local version = body.version
		if version and version ~= _addon.version then
			return version
		end
	end
	return nil
end

function check_files()
	if addon_settings:getSettings().flags.check_files then
		if windower.file_exists(windower.windower_path..'/addons/libs/cylibs/Cylibs-Include.lua') then
			error('Please remove the', windower.windower_path..'addons/libs/cylibs/', 'folder and reload Trust.')
		end
	end
end

function register_chat_handlers()
	local ChatInput = require('cylibs/ui/input/chat_input')
	chat_input = ChatInput.new(main_trust_settings, state.MainTrustSettingsMode)
end

-- Helpers

function addon_message(color,str)
    windower.add_to_chat(color, _addon.name..': '..str)
end

function addon_system_message(str)
	windower.add_to_chat(122, str)
end

function addon_system_error(str)
	windower.add_to_chat(123, str)
end

-- Handlers

function handle_stop()
	addon_enabled:setValue(false)
end

function handle_tic(old_time, new_time)
	if should_check_version then
		if os.time() - addon_load_time > 5 then
			should_check_version = false
			local new_version = check_version()
			if new_version then
				addon_system_message("A newer version of Trust is available! Use the installer to update to v"..new_version..".")
			end
		end
	end

	player.alliance:tic(old_time, new_time)

	if not player.trust.main_job or not windower.ffxi.get_player() or not addon_enabled:getValue() or not player or not player.trust then return end

	action_queue:set_enabled(addon_enabled:getValue())

	player.trust.main_job:tic(old_time, new_time)
	player.trust.sub_job:tic(old_time, new_time)
end

function handle_status_change(new_status_id, old_status_id)
	player.status = res.statuses[new_status_id].english

	if player.status == 'Dead' then
		if state.AutoUnloadOnDeathMode.value == 'Disable' then
			handle_stop()
		elseif state.AutoUnloadOnDeathMode.value == 'Auto' then
			handle_unload()
		end
	end
end

function handle_unload()
	windower.chat.input('// lua unload trust')
end

function handle_job_change(_, _, _, _)
	handle_stop()
	unloaded()
	handle_unload()
end

function handle_zone_change(_, _)
	action_queue:clear()
	if state.AutoDisableMode.value ~= 'Off' then
		handle_stop()
	end
end

-- Setup

local function addon_command(cmd, ...)
    local cmd = cmd or 'help'
	
	if hud.trustMenu:isVisible() and not S{ 'assist', 'send', 'sendall'}:contains(cmd) then
		addon_system_error("Unable to execute commands while the menu is open.")
		return
	end

    if shortcuts[cmd] then
		shortcuts[cmd]:handle_command(...)
	elseif shortcuts['default']:is_valid_command(cmd, ...) then
		shortcuts['default']:handle_command(cmd, ...)
	else
		error("Unknown command %s":format(cmd))
    end
end

function load_chunk_event()
	load_user_files(windower.ffxi.get_player().main_job_id, windower.ffxi.get_player().sub_job_id or 0)

	trust_remote_commands = TrustRemoteCommands.new()

	local CommandMessage = require('cylibs/messages/command_message')
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
	for key in L{'up','down','left','right','enter','numpadenter', addon_settings:getSettings().menu_key}:extend(L{'a','w','s','d','f','e','h','i','k','l'}):it() do
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
	windower.chat.input('/console console_echo Unloaded addons that conflict with Trust.')
	windower.send_command('lua unload ata')

	addon_system_message("Loading Trust...")

	if windower.ffxi.get_player() == nil or windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id) == nil then
		addon_system_error("Player not loaded, retrying in 5 seconds...")
		coroutine.schedule(function()
			loaded()
		end, 5)
		return
	end

	addon_load_time = os.time()

	should_check_version = true

	player = {}
	shortcuts = {}

	require('lists')

	local temp_dirs = L{
		windower.trust.get_temp_dir(),
		windower.trust.get_temp_dir(windower.ffxi.get_player().name),
	}
	for dir in temp_dirs:it() do
		if not windower.dir_exists(dir) then
			windower.create_dir(dir)
		end
	end

	local res = require('resources')

	local finalize_init = function()
		if not user_events then
			load_chunk_event()
			user_events = {}
			user_events.tic = windower.register_event('time change', handle_tic)
			user_events.status = windower.register_event('status change', handle_status_change)
			user_events.job_change = windower.register_event('job change', handle_job_change)
			user_events.zone_change = windower.register_event('zone change', handle_zone_change)
		end
		coroutine.schedule(function()
			windower.send_command('bind %s trust menu':format(addon_settings:getSettings().menu_key))
		end, 0.2)
	end

	local Loading = require('loading/Trust-Init-Include')

	local ActionQueue = require('cylibs/actions/action_queue')

	init_action_queue = ActionQueue.new()

	local import_paths = L{
		'includes/Windower-Include',
		'commands/Trust-Commands-Include',
		'Trust-Include',
		'includes/Trust-Cylibs-Include',
		'includes/Trust-Cylibs-Actions-Include',
		'includes/Trust-Cylibs-Conditions-Include',
		'includes/Trust-Cylibs-Settings-Include',
		'includes/Trust-Cylibs-Roles-Include',
		'includes/Trust-Cylibs-Util-Include',
	}

	local actions = L{
		Loading.LoadDependenciesAction.new(import_paths),
		Loading.LoadSettingsAction.new(settings, res.jobs[windower.ffxi.get_player().main_job_id].ens, res.jobs[windower.ffxi.get_player().sub_job_id or 0].ens),
		Loading.Loadi18nAction.new(),
		Loading.LoadGlobalsAction.new(),
		Loading.LoadLoggerAction.new(),
		Loading.LoadThemeAction.new(),
	}

	local num_complete = 0
	init_action_queue:on_action_end():addAction(function(action, success)
		num_complete = num_complete + 1
		if num_complete == actions:length() then
			finalize_init()
		end
	end)

	for action in actions:it() do
		init_action_queue:push_action(action)
	end
end

windower.register_event('addon command', addon_command)
windower.register_event('load', loaded)
windower.register_event('unload', unloaded)
windower.register_event('logout', function() windower.send_command('lua unload trust') end)