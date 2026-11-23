---------------------------
-- Extension registration for this build.
--
-- Loaded once by the CoreAI wiring block in cylibs/trust/trust.lua,
-- right after core_ai.lua itself. This build registers only the
-- debuff hold module. Registration is pcall-isolated: a module that
-- fails to load or register is skipped and Trust runs without it.
--
-- To remove the extension layer entirely, delete the marked CoreAI
-- wiring blocks in cylibs/trust/trust.lua; nothing else in Trust
-- depends on this file.

local CoreAI = require('cylibs/trust/extensions/core_ai')
local DebuffHold = require('cylibs/trust/extensions/debuff_hold')

pcall(CoreAI.register_module, 'debuff_hold', DebuffHold)
