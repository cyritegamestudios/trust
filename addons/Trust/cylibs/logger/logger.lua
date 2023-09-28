local logger = {}

logger.isEnabled = false

function logger.notice(...)
    if logger.isEnabled then
        notice(...)
    end
end

function logger.warning(...)
    if logger.isEnabled then
        warning(...)
    end
end

function logger.error(...)
    if logger.isEnabled then
        error(...)
    end
end

return logger