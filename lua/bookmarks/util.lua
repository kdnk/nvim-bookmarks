local M = {}

function M.get_project_hash()
    local cwd = vim.fn.getcwd()
    local hash = vim.fn.sha256(cwd)
    return hash:sub(1, 16)
end

function M.sanitize_branch_name(branch)
    -- Replace filesystem-unsafe characters with underscores
    -- This handles: / \ : * ? " < > |
    return branch:gsub('[/\\:*?"<>|]', "_")
end

function M.get_persist_path(per_branch)
    local data_dir = vim.fn.stdpath("data")
    local project_hash = M.get_project_hash()
    local base_dir = data_dir .. "/nvim-bookmarks/" .. project_hash

    if per_branch then
        local branch = vim.fn.systemlist("git branch --show-current")[1] or ""
        if branch == "" then
            branch = "default"
        end
        branch = M.sanitize_branch_name(branch)
        return base_dir .. "/" .. branch .. ".json"
    else
        return base_dir .. "/bookmarks.json"
    end
end

return M
