_addon.author = 'Cyrite'
_addon.commands = {'Trust','trust'}
_addon.name = 'Trust'
_addon.version = '1.0'

require('luau')
require('actions')
require('lists')

require('cylibs/Cylibs-Include')

local res = require('resources')
local files = require('files')
local Party = require('cylibs/entity/party')
local TrustFactory = require('cylibs/trust/trust_factory')
local TrustRemoteCommands = require('TrustRemoteCommands')
local TrustUI = require('TrustUI')

default = {
	verbose=true
}

default.battle = {}
default.battle.melee_distance = 3
default.battle.range_distance = 21
default.battle.targets = L{}
default.battle.trusts = L{'Monberaux','Sylvie (UC)','Koru-Moru','Qultada','Brygid'}
default.remote_commands = {}
default.remote_commands.whitelist = S{}
default.trusts = {}

settings = config.load(default)

hud = TrustUI.new()

player = {}

-- States

state.AutoMagicBurstMode = M{['description'] = 'Auto Magic Burst Mode', 'Off', 'Auto'}
state.AutoDebuffMode = M{['description'] = 'Auto Debuff Mode', 'Off', 'Auto'}
state.AutoDispelMode = M{['description'] = 'Auto Dispel Mode', 'Auto', 'Off'}
state.AutoFollowMode = M{['description'] = 'Auto Follow Mode', 'Off', 'Always'} -- causes player to approach mob
state.AutoEngageMode = M{['description'] = 'Auto Engage Mode', 'Off', 'Always', 'Assist'}
state.AutoPetMode = M{['description'] = 'Auto Pet Mode', 'Off', 'Auto'}
state.AutoBuffMode = M{['description'] = 'Auto Buff Mode', 'Off', 'Auto'}
state.AutoAssaultMode = M{['description'] = 'Auto Assault Mode', 'Off', 'Auto'}
state.AutoTankMode = M{['description'] = 'Auto Tank Mode', 'Off', 'Auto'}
state.AutoEnmityReductionMode = M{['description'] = 'Auto Enmity Reduction Mode', 'Off', 'Auto'}
state.EngageMode = M{['description'] = 'Engage Mode', 'None', 'Behind'}

-- Main

function load_user_files(main_job_id, sub_job_id)

	action_queue = ActionQueue.new(nil, true, 5, false)

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

	player.party = Party.new()
	player.party:monitor()

	handle_status_change(windower.ffxi.get_player().status, windower.ffxi.get_player().status)

	main_job_trust, sub_job_trust = TrustFactory.trusts(trust_for_job_short(player.main_job_name_short, settings, action_queue, player.player, player.party), trust_for_job_short(player.sub_job_name_short, settings, action_queue, player.player, player.party))

	main_job_trust:init()
	sub_job_trust:init()

	player.trust = {}
	player.trust.main_job = main_job_trust
	player.trust.main_job_commands = load_trust_commands(player.main_job_name_short, main_job_trust, action_queue)
	player.trust.sub_job = sub_job_trust
	player.trust.sub_job_commands = load_trust_commands(player.sub_job_name_short, sub_job_trust, action_queue)

	player.trust.main_job:add_role(Attacker.new(action_queue))
	player.trust.main_job:add_role(CombatMode.new(action_queue, settings.battle.melee_distance, settings.battle.range_distance))
	player.trust.main_job:add_role(Eater.new(action_queue, main_job_trust:get_trust_settings().AutoFood))
	player.trust.main_job:add_role(Truster.new(action_queue, settings.battle.trusts))

	target_change_time = os.time()

	addon_enabled = true

	default_trust_name = string.gsub(string.lower(player.main_job_name), "%s+", "")

	handle_load_trust(default_trust_name)
	handle_start()
end

function load_trust_settings(job_name_short)
	local file_prefix = windower.addon_path..'data/'..job_name_short
	if windower.file_exists(file_prefix..'_'..windower.ffxi.get_player().name..'.lua') then
		--return dofile(file_prefix..'_'..windower.ffxi.get_player().name..'.lua')
		return require('data/'..job_name_short..'_'..windower.ffxi.get_player().name)
	elseif windower.file_exists(file_prefix..'.lua') then
		--return dofile(file_prefix..'.lua')
		return require('data/'..job_name_short)
	end
	return nil
end

function load_trust_commands(job_name_short, trust, action_queue)
	local file_prefix = windower.windower_path..'addons/libs/cylibs/trust/commands/'..job_name_short
	if windower.file_exists(file_prefix..'_'..windower.ffxi.get_player().name..'.lua') then
		local TrustCommands = require('cylibs/trust/commands/'..job_name_short..'_'..windower.ffxi.get_player().name)
		return TrustCommands.new(trust, action_queue)
	elseif windower.file_exists(file_prefix..'.lua') then
		local TrustCommands = require('cylibs/trust/commands/'..job_name_short)
		return TrustCommands.new(trust, action_queue)
	end
	return nil
end

function trust_for_job_short(job_name_short, settings, action_queue, player, party)
	local trust_settings = load_trust_settings(job_name_short)

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
	trust:set_party(party)

	return trust
end

-- Helpers

function addon_message(color,str)
    windower.add_to_chat(color, _addon.name..': '..str)
end

-- Handlers

function handle_tic(old_time, new_time)
	if not trust or not windower.ffxi.get_player() or not addon_enabled then return end

	player.trust.main_job:tic(old_time, new_time)
	player.trust.sub_job:tic(old_time, new_time)
end

function handle_status_change(new_status_id, old_status_id)
	player.status = res.statuses[new_status_id].english

	if player.status == 'Dead' then
		handle_unload()
	end

	if state.AutoFollowMode.value == 'Always' then
		if player.assist_target and player.assist_target:get_name() == windower.ffxi.get_player().name then
			return
		end
		if player.status == 'Idle' then
			coroutine.sleep(1)
			if player.assist_target and player.assist_target:get_name() ~= windower.ffxi.get_player().name then
				windower.send_command('input // follow_ext target %s 5':format(player.assist_target:get_name()))
			end
		else
			windower.send_command('input // follow_ext stop')
		end
	end
end

function handle_start()
	addon_enabled = true
	player.player:monitor()
	action_queue:enable()
	hud:set_enabled(true)
end

function handle_stop()
	addon_enabled = false
	action_queue:disable()
	hud:set_enabled(false)
end

function handle_reload()
	windower.chat.input('// lua r trust')
end

function handle_unload()
	windower.chat.input('// lua unload trust')
end

function handle_job_change(_, _, _, _)
	unloaded()
	handle_unload()
end

function handle_zone_change(_, _, _, _)
	player.assist_target = nil
	handle_stop()
end

function handle_save_trust(trust_name)
    trust_name = trust_name or player.trust.trust_name
	if trust_name == nil then
		addon_message(100, 'Invalid trust name')
		return
	end
	local trust_config = {}
	for state_name, _ in pairs(state) do
		trust_config[state_name:lower()] = state[state_name].value
	end
	settings.trusts[trust_name] = trust_config
	settings:save(windower.ffxi.get_player().name)

	addon_message(207, 'Saved trust '..trust_name)
end

function handle_load_trust(trust_name)
	if trust_name and settings.trusts[trust_name] then
		for state_name, value in pairs(settings.trusts[trust_name]) do
			local state_var = get_state(state_name)
			if state_var then
				state_var:set(value)
			end
		end
        player.trust.trust_name = trust_name

		addon_message(207, 'Loaded trust '..trust_name)
	else
		addon_message(100, 'Unable to find trust '..(trust_name or 'nil'))
	end
end

function handle_create_trust(job_name_short)
	if job_util.all_jobs():contains(job_name_short) then
		local default_settings = files.new('data/'..job_name_short..'.lua')
		if not default_settings:exists() then
			addon_message(100, 'No default settings exists for '..(job_name_short or 'nil'))
			return
		end
		local file_paths = L{
			'data/'..job_name_short..'_'..windower.ffxi.get_player().name..'.lua',
		}
		for file_path in file_paths:it() do
			local trust_settings = files.new(file_path)
			if not trust_settings:exists() then
				trust_settings:write(default_settings:read())

				addon_message(207, 'Created trust override '..file_path)
			end
		end
	else
		addon_message(100, 'Invalid job name short '..(job_name_short or 'nil'))
	end
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

function get_assist_target(name)
	if name == windower.ffxi.get_player().name then
		return player.player
	else
		return player.party:get_party_member(windower.ffxi.get_mob_by_name(name).id)
	end
end

function handle_assist(param)
	local party_member = player.party:get_party_member(windower.ffxi.get_mob_by_name(param).id)
	if party_member then
		addon_message(207, 'Now assisting '..party_member:get_name())
		player.party:set_assist_target(party_member)
	end
end

function handle_skillchain(action, param)
	if player.player:get_mob().target_index == nil then return end

	if action == 'ws' then
		player.trust.main_job:job_weapon_skill(param)
	elseif action == 'ja' then
		local job_ability = res.job_abilities:with('en', param)
		if job_ability then
			if job_ability.type == 'BloodPactRage' then
				if state.AutoAvatarMode.value ~= 'Off' and pet_util.has_pet() and pet_util.pet_name() == state.AutoAvatarMode.value and windower.ffxi.get_ability_recasts()[173] < 1 and not action_queue:contains_action_of_type('bloodpactrageaction') then
					action_queue:push_action(BloodPactRageAction.new(0, 0, 0, param), true)
				end
			else
				action_queue:push_action(JobAbilityAction.new(0, 0, 0, job_ability.en), true)
			end
		end
	elseif action == 'mb' then
		local spell = res.spells:with('en', param)
		if spell and spell.status == nil then
			local target = windower.ffxi.get_mob_by_index(player.current_target)
			if target then
				windower.send_command('gs c set MagicBurstMode Single')
				player.trust.main_job:job_magic_burst(target.id, spell)
			end
		else
			local job_ability = res.job_abilities:with('en', param)
			if job_ability then
				if job_ability.type == 'BloodPactRage' then
					if state.AutoAvatarMode.value ~= 'Off' and pet_util.has_pet() and pet_util.pet_name() == state.AutoAvatarMode.value and windower.ffxi.get_ability_recasts()[173] < 1 and not action_queue:contains_action_of_type('bloodpactrageaction') then
						local blood_pact_rage_action = BloodPactRageAction.new(0, 0, 0, param)
						--blood_pact_rage_action.priority = ActionPriority.highest
						if player_util.get_job_ability_recast('Apogee') == 0 then
							action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Apogee'), true)
							action_queue:push_action(WaitAction.new(0, 0, 0, 2))
						end
						blood_pact_rage_action.priority = ActionPriority.highest
						action_queue:push_action(blood_pact_rage_action, true)
					end
				end
			end
		end
	end
end

function handle_shortcut(...)
	local command = ''
	for _,v in ipairs(arg) do
		command = command..' '..tostring(v)
	end
	if not command:empty() then
		windower.send_command('@input '..command:trim())
		--action_queue:push_action(CommandAction.new(0, 0, 0, command:trim()), true)
	end
end

function handle_command(args)
	--[[local actions = L{
		SpellAction.new(0, 0, 0, spell_util.spell_id('Cure')),
		WaitAction.new(0, 0, 0, 4),
	}
	action_queue:push_action(SequenceAction.new(actions, 'manual'), false)]]

	local actions = L{
		SpellAction.new(0, 0, 0, spell_util.spell_id('Cure'), nil, player.player),
		WaitAction.new(0, 0, 0, 2)
	}

	--windower.send_command('@input /ma Cure <me>')


	local action = SequenceAction.new(actions, 'test_action')
	action.priority = ActionPriority.highest

	action_queue:push_action(action, false)

	--action_queue:push_action(SpellAction.new(0, 0, 0, spell_util.spell_id('Cure')), false)
	--action_queue:push_action(CommandAction.new(0, 0, 0, args), false)
end

function handle_debug()
	for action_type, count in pairs(actions_counter) do
		print('type: '..action_type..' count: '..count)
		print('actions created: '..actions_created..' actions destroyed: '..actions_destroyed)
	end

	local action_names = action_queue:get_actions():map(function(a) return a:gettype()..' '..a:getidentifier()  end)
	print(action_names)
end

-- Setup

local commands = T{}

commands['start'] = handle_start
commands['stop'] = handle_stop
commands['reload'] = handle_reload
commands['skillchain'] = handle_skillchain
commands['shortcut'] = handle_shortcut
commands['assist'] = handle_assist
commands['save'] = handle_save_trust
commands['load'] = handle_load_trust
commands['create'] = handle_create_trust
commands['status'] = handle_trust_status
commands['command'] = handle_command
commands['debug'] = handle_debug

local function addon_command(cmd, ...)
    local cmd = cmd or 'help'

    if commands[cmd] then
		local msg = nil
		if cmd == 'shortcut' then
			msg = commands['shortcut'](...)
		else
			msg = commands[cmd](unpack({...}))
		end
		if msg then
			error(msg)
		end
	elseif L{player.main_job_name_short, player.main_job_name_short:lower()}:contains(cmd) and player.trust.main_job_commands then
		player.trust.main_job_commands:handle_command(unpack({...}))
	elseif L{player.sub_job_name_short, player.sub_job_name_short:lower()}:contains(cmd) and player.trust.sub_job_commands then
		player.trust.sub_job_commands:handle_command(unpack({...}))
	else
		if not L{'cycle', 'set', 'help'}:contains(cmd) then
			error("Unknown command %s":format(cmd))
		end
    end
end

function load_chunk_event()
	load_user_files(windower.ffxi.get_player().main_job_id, windower.ffxi.get_player().sub_job_id)

	trust_remote_commands = TrustRemoteCommands.new(settings.remote_commands.whitelist, commands:keyset())
end

function unload_chunk_event()
end

function unloaded()
    if user_events then
        for _,event in pairs(user_events) do
            windower.unregister_event(event)
        end
        user_events = nil
    end
	player.trust.main_job:destroy()
	player.trust.sub_job:destroy()
	player.trust = nil
	coroutine.schedule(unload_chunk_event,0.1)
end

function loaded()
    if not user_events then
        user_events = {}
		user_events.status = windower.register_event('time change', handle_tic)
		user_events.status = windower.register_event('status change', handle_status_change)
		user_events.job_change = windower.register_event('job change', handle_job_change)
		user_events.zone_change = windower.register_event('zone change', handle_zone_change)
		coroutine.schedule(load_chunk_event,0.1)
    end
end

windower.register_event('addon command', addon_command)
windower.register_event('login','load', loaded)
windower.register_event('logout', unloaded)
