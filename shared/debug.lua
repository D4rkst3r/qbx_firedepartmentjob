-- ╔══════════════════════════════════════════╗
-- ║          SHARED / DEBUG.LUA             ║
-- ╚══════════════════════════════════════════╝

Config.Debug = false  -- Standard: aus. Per /fddebug togglen

---Gibt eine Debug-Nachricht in die Console aus
---@param source string  Dateiname / Kontext
---@param msg string
---@param ... any  Formatierungsargumente
function DebugLog(source, msg, ...)
    if not Config.Debug then return end
    local text = string.format(msg, ...)
    local prefix = string.format('^3[FD DEBUG | %s]^7 ', source)
    print(prefix .. text)
end