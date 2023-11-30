local logger = {}

logger.isEnabled = false
logger.filterPattern = nil

function logger.notice(...)
    if logger.isEnabled and logger.check_filter(...) then
        notice(...)
    end
end

function logger.warning(...)
    if logger.isEnabled and logger.check_filter(...) then
        warning(...)
    end
end

function logger.error(...)
    if logger.isEnabled and logger.check_filter(...) then
        error(...)
    end
end

function logger.check_filter(...)
    if logger.filterPattern == nil then
        return true
    end
    local args = {...}
    for i = 1, select("#", ...) do
        local arg = args[i]
        if arg and type(arg) == 'string' and string.match(arg, logger.filterPattern) then
            return true
        end
    end
    return false
end

function logger.set_filter(pattern)
    logger.filterPattern = pattern
end

return logger