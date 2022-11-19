--[[Copyright © 2019, Cyrite

Farm v1.0.0

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

require('tables')
require('lists')
require('logger')
require('vectors')

local packets = require('packets')
local res = require('resources')
local recipes_lookup = require('cylibs/synth/recipes_lookup')
local synth_util = require('cylibs/synth/synth_util')
local md5 = require('cylibs/util/md5')
local urlcode = require('cylibs/util/urlcode')

local SynthRecipe = {}
SynthRecipe.__index = SynthRecipe


function SynthRecipe.new(data)
	local self = setmetatable({}, SynthRecipe)
	self.packet = packets.parse('outgoing', data);
	return self
end

function SynthRecipe:get_item()
	local ingredients = self:get_ingredients():map(function(item) 
		return item.en 
	end)
	ingredients:sort()
	
	local m = md5.new()
	m:update(synth_util.get_nq_crystal(self:get_crystal()))
	for ingredient in ingredients:it() do
		m:update(ingredient)
	end
	local hash = md5.tohex(m:finish())
	local recipe_name = recipes_lookup[hash]
	if recipe_name ~= nil then
		for i=1, 9, 1 do
			recipe_name = recipe_name:gsub("%%d":format(i), "")
		end
		recipe_name = string.trim(recipe_name)
		
		local item = synth_util.match_recipe_to_item(recipe_name)
		return item
	else
		return nil
	end
end

function SynthRecipe:get_ingredients()
	local ingredients = L{}
	for i=1, self:get_ingredient_count(), 1 do
		local item_id = tonumber(self.packet["Ingredient %d":format(i)])
		if item_id ~= 0 and res.items[item_id] ~= nil then
			ingredients:append(res.items[item_id])
		end
	end
	return ingredients
end

function SynthRecipe:get_ingredient_count()
	return self.packet["Ingredient count"]
end

function SynthRecipe:get_crystal()
	local item_id = self.packet['Crystal']
	return res.items[item_id]
end

function SynthRecipe:get_packet()
	return self.packet
end

function SynthRecipe:tostring()
	return "SynthRecipe: %s":format(self:get_ingredients())
end

return SynthRecipe



