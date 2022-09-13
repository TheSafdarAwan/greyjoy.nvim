-- Parse vscode tasks.json version 2 files
local ok, greyjoy = pcall(require, "greyjoy")
if not ok then
    vim.notify(
        "This plugin requires greyjoy.nvim (https://github.com/desdic/greyjoy.nvim)",
        vim.lsp.log_levels.ERROR, {title = "Plugin error"})
    return
end

local health = vim.health or require("health")

local M = {}

M.parse = function(fileinfo)
    local filename = fileinfo.filename
    local filepath = fileinfo.filepath
    local elements = {}

    local append_data = function(_, data)
        if data then
            for _, v in ipairs(data) do
                if v ~= "" then
                    local elem = {}
                    elem["name"] = "make " .. v
                    elem["command"] = {"make", v}

                    table.insert(elements, elem)
                end
            end
        end
    end

    -- From the bash makefile autocomplete
    local command = "make -f ./" .. filename ..
                        " -pRrq |awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($1 !~ \"^[#.]\") {print $1}}' |sort | grep -E -v -e '^[^[:alnum:]]'"
    local jobid = vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = append_data,
        on_stderr = append_data,
        cwd = filepath
    })

    vim.fn.jobwait({jobid}, 10)
    return elements
end

M.health = function()
    if vim.fn.executable("make") == 1 then
        health.report_ok("`make`: Ok")
    else
        health.report_error("`makefile` requires make to be installed")
    end
end

return greyjoy.register_extension({
    setup = function(_) end,
    health = M.health,
    exports = {type = "file", files = {"Makefile"}, parse = M.parse}
})
