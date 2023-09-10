-- $Revision: 1.4 $
-- $Date: 2014-02-09 15:30:26 $
-- $.Path: lua_urlcode $
 
-- http://keplerproject.github.com/cgilua/index.html#download
 
----------------------------------------------------------------------------
-- Utility functions for encoding/decoding of URLs.
--
-- release $Id: urlcode.lua,v 1.10 2008/01/21 16:11:32 carregal Exp
----------------------------------------------------------------------------
 
local urlcode = { _version = "0.1.2" }
 
local ipairs, next, pairs, tonumber, type = ipairs, next, pairs, tonumber, type
local string = string
local table = table

----------------------------------------------------------------------------
-- Decode an URL-encoded string (see RFC 2396)
----------------------------------------------------------------------------
function urlcode.unescape (str)
   str = string.gsub (str, "+", " ")
   str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
   return str
end
 
----------------------------------------------------------------------------
-- URL-encode a string (see RFC 2396)
----------------------------------------------------------------------------
function urlcode.escape (str)
   str = string.gsub (str, "([^0-9a-zA-Z !'()*._~-])", -- locale independent
      function (c) return string.format ("%%%02X", string.byte(c)) end)
   str = string.gsub (str, " ", "+")
   return str
end
 
----------------------------------------------------------------------------
-- Insert a (name=value) pair into table [[args]]
-- @param args Table to receive the result.
-- @param name Key for the table.
-- @param value Value for the key.
-- Multi-valued names will be represented as tables with numerical indexes
-- (in the order they came).
----------------------------------------------------------------------------
function insertfield (args, name, value)
   if not args[name] then
      args[name] = value
   else
      local t = type (args[name])
      if t == "string" then
         args[name] = {args[name],value,}
      elseif t == "table" then
         table.insert (args[name], value)
      else
         error ("CGILua fatal error (invalid args table)!")
      end
   end
end
 
----------------------------------------------------------------------------
-- URL-encode the elements of a table creating a string to be used in a
-- URL for passing data/parameters to another script
-- @param args Table where to extract the pairs (name=value).
-- @return String with the resulting encoding.
----------------------------------------------------------------------------
function urlcode.encodeTable(Args)
   if Args == nil or next(Args) == nil then -- no args or empty args?
      return ""
   end
   local strp = ""
   for key, vals in pairs(Args) do
      if type(vals) ~= "table" then
         vals = {vals}
      end
      for i,val in ipairs(vals) do
         strp = strp.."&"..key.."="..escape(val)
      end
   end
   -- remove first &
   return string.sub(strp,2)
end

return urlcode