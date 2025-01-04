---------------------------
-- Job file for Beastmaster.
-- @class module
-- @name Beastmaster

local ReadyMove = require('cylibs/battle/abilities/ready_move')

local Job = require('cylibs/entity/jobs/job')
local Beastmaster = setmetatable({}, {__index = Job })
Beastmaster.__index = Beastmaster

local familiar_info = {['FunguarFamiliar']="Funguar, Plantoid, Warrior",['CourierCarrie']="Crab, Aquan, Paladin",
                  ['AmigoSabotender']="Cactuar, Plantoid, Warrior",['NurseryNazuna']="Sheep, Beast, Warrior",
                  ['CraftyClyvonne']="Coeurl, Beast, Warrior",['FleetReinhard']="Raptor, Lizard, Warrior",
                  ['PrestoJulio']="Flytrap, Plantoid, Warrior",['SwiftSieghard']="Raptor, Lizard, Warrior",
                  ['MailbusterCetas']="Fly, Vermin, Warrior",['AudaciousAnna']="Lizard, Lizard, Warrior",
                  ['TurbidToloi']="Pugil, Aquan, Warrior",['SlipperySilas']="Toad, Aquan, Warrior",
                  ['LuckyLulush']="Rabbit, Beast, Warrior",['DipperYuly']="Ladybug, Vermin, Thief",
                  ['FlowerpotMerle']="Mandragora, Plantoid, Monk",['DapperMac']="Apkallu, Bird, Monk",
                  ['DiscreetLouise']="Funguar, Plantoid, Warrior",['FatsoFargann']="Leech, Amorph, Warrior",
                  ['FaithfulFalcorr']="Hippogryph, Bird, Thief",['BugeyedBroncha']="Eft, Lizard, Warrior",
                  ['BloodclawShasra']="Lynx, Beast, Warrior",['GorefangHobs']="Tiger, Beast, Warrior",
                  ['GooeyGerard']="Slug, Amorph, Warrior",['CrudeRaphie']="Adamantoise, Lizard, Paladin",
                  ['DroopyDortwin']="Rabbit, Beast, Warrior",['PonderingPeter']="HQ Rabbit, Beast, Warrior",
                  ['SunburstMalfik']="Crab, Aquan, Paladin",['AgedAngus']="HQ Crab, Aquan, Paladin",
                  ['WarlikePatrick']="Lizard, Lizard, Warrior",['MosquitoFamiliar']="Mosquito, Vermin, Dark Knight",
                  ['Left-HandedYoko']="Mosquito, Vermin, Dark Knight",['ScissorlegXerin']="Chapuli, Vermin, Warrior",
                  ['BouncingBertha']="HQ Chapuli, Vermin, Warrior",['RhymingShizuna']="Sheep, Beast, Warrior",
                  ['AttentiveIbuki']="Tulfaire, Bird, Warrior",['SwoopingZhivago']="HQ Tulfaire, Bird, Warrior",
                  ['BrainyWaluis']="Funguar, Plantoid, Warrior",['SuspiciousAlice']="Eft, Lizard, Warrior",
                  ['HeadbreakerKen']="Fly, Vermin, Warrior",['RedolentCandi']="Snapweed, Plantoid, Warrior",
                  ['AlluringHoney']="HQ Snapweed, Plantoid, Warrior",['CaringKiyomaro']="Raaz, Beast, Monk",
                  ['SurgingStorm']="Apkallu, Bird, Monk",['SubmergedIyo']="Apkallu, Bird, Monk",
                  ['CursedAnnabelle']="Antlion, Vermin, Warrior",['AnklebiterJedd']="Diremite, Vermin, Dark Knight",
                  ['VivaciousVickie']="HQ Raaz, Beast, Monk",['HurlerPercival']="Beetle, Vermin, Paladin",
                  ['BlackbeardRandy']="Tiger, Beast, Warrior",['GenerousArthur']="Slug, Amorph, Warrior",
                  ['ThreestarLynn']="Ladybug, Vermin, Thief",['BraveHeroGlenn']="Frog, Aquan, Warrior",
                  ['SharpwitHermes']="Mandragora, Plantoid, Monk",['ColibriFamiliar']="Colibri, Bird, Red Mage",
                  ['GussyHachirobe']="HQ Spider, Vermin, Warrior",['AcuexFamiliar']="Acuex, Amorph, Black Mage",
                  ['ChoralLeera']="HQ Colibri, Bird, Red Mage",['SpiderFamiliar']="Spider, Vermin, Warrior",
                  ['AmiableRoche']="Pugil, Aquan, Warrior",['HeraldHenry']="Crab, Aquan, Paladin",
                  ['FluffyBredo']="HQ Acuex, Amorph, Black Mage",
}

-------
-- Default initializer for a new Beastmaster.
-- @tparam ActionQueue action_queue Action queue
-- @treturn Beastmaster A Beastmaster
function Beastmaster.new(action_queue)
    local self = setmetatable(Job.new('BST'), Beastmaster)

    self.action_queue = action_queue

    return self
end

-------
-- Destroy function for a Summoner.
function Beastmaster:destroy()
    Job.destroy(self)
end

-------
-- Returns a list of known job abilities.
-- @tparam function filter Optional filter function
-- @treturn list List of known job ability ids
function Beastmaster:get_job_abilities(filter)
    filter = filter or function(_) return true end
    local job_abilities = Job.get_job_abilities(self, filter)
    job_abilities = (job_abilities + self:get_ready_moves():map(function(ready_move) return ready_move:get_ability_id() end):filter(filter)):unique(function(job_ability_id) return job_ability_id end)
    return job_abilities
end

-------
-- Returns all ready moves matching the given filter.
-- @tparam function filter Filter function for ready moves (optional)
-- @treturn list List of JobAbility
function Beastmaster:get_ready_moves(filter)
    if filter == nil then
        filter = function(_) return true  end
    end
    local all_ready_moves = L(res.job_abilities:with_all('type', 'Monster')):filter(filter):compact_map():map(function(ready_move) return JobAbility.new(ready_move.en)  end)
    return all_ready_moves
end

-------
-- Calls a familiar with Bestial Loyalty.
function Beastmaster:bestial_loyalty()
    if job_util.can_use_job_ability('Bestial Loyalty') then
        self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Bestial Loyalty'), true)
    end
end

-------
-- Returns whether a mob is a jug pet.
-- @tparam string mob_name Mob name
-- @treturn Boolean True if the mob is a jug pet
function Beastmaster:is_jug_pet(mob_name)
    return familiar_info[mob_name] ~= nil
end

return Beastmaster