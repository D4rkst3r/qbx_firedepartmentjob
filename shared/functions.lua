-- ╔══════════════════════════════════════════╗
-- ║           GETEILTE HILFSFUNKTIONEN       ║
-- ╚══════════════════════════════════════════╝

---Prüft ob ein Spieler den Feuerwehr-Job hat
---@param job table QBX Job-Objekt
---@return boolean
function IsFirefighter(job)
    return job and job.name == Config.JobName
end

---Prüft ob ein Spieler den Mindestrang hat
---@param job table
---@param minGrade number
---@return boolean
function HasRequiredGrade(job, minGrade)
    return job and job.name == Config.JobName and job.grade.level >= minGrade
end

---Berechnet Entfernung zwischen zwei Vektoren (2D)
---@param a vector3
---@param b vector3
---@return number
function GetDistance2D(a, b)
    return #(vector2(a.x, a.y) - vector2(b.x, b.y))
end

---Formatiert Zeit in MM:SS
---@param seconds number
---@return string
function FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format('%02d:%02d', m, s)
end
