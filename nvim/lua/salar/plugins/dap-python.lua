return {
    "mfussenegger/nvim-dap-python",
    ft = { "python" },
    dependencies = {
        "mfussenegger/nvim-dap",
    },

    config = function()
        local dap = require("dap")
        local dap_python = require("dap-python")
        local project = require("salar.core.project")
        local project_config = project.current()
        local is_windows = vim.fn.has("win32") == 1

        local function normalize_path_list(value)
            if type(value) == "string" and value ~= "" then
                return { value }
            end

            if type(value) == "table" then
                return value
            end

            return {}
        end

        local function pythonpath_value()
            local paths = {}

            for _, path in ipairs(normalize_path_list(project_config.dap and project_config.dap.pythonpath)) do
                if path ~= "" then
                    paths[#paths + 1] = path
                end
            end

            if project_config.cwd and project_config.cwd ~= "" then
                paths[#paths + 1] = project_config.cwd
            end

            local existing = os.getenv("PYTHONPATH")
            if existing and existing ~= "" then
                paths[#paths + 1] = existing
            end

            return table.concat(paths, is_windows and ";" or ":")
        end

        local function merged_launch_env()
            local env = {
                PYTHONPATH = pythonpath_value(),
            }

            local from_file = project_config.dap and project_config.dap.env_from_file or nil
            if type(from_file) == "table" then
                for key, value in pairs(from_file) do
                    env[key] = value
                end
            end

            local manual_env = project_config.dap and project_config.dap.env or nil
            if type(manual_env) == "table" then
                for key, value in pairs(manual_env) do
                    env[key] = value
                end
            end

            return env
        end

        local launch_env = merged_launch_env()

        dap_python.resolve_python = function()
            return project.resolve_python()
        end

        dap_python.setup(project.debugpy_python())
        dap_python.test_runner = "pytest"

        dap.defaults.python = dap.defaults.python or {}
        dap.defaults.python.exception_breakpoints = {}
        dap.defaults.debugpy = dap.defaults.debugpy or {}
        dap.defaults.debugpy.exception_breakpoints = {}

        local python_configurations = {
            {
                name = "Launch file",
                type = "python",
                request = "launch",
                program = "${file}",
                cwd = "${workspaceFolder}",
                console = "integratedTerminal",
                stopOnEntry = false,
                justMyCode = true,
                showReturnValue = true,
                redirectOutput = true,
                env = launch_env,
            },
            {
                name = "Launch file (stop on entry)",
                type = "python",
                request = "launch",
                program = "${file}",
                cwd = "${workspaceFolder}",
                console = "integratedTerminal",
                stopOnEntry = true,
                justMyCode = true,
                showReturnValue = true,
                redirectOutput = true,
                env = launch_env,
            },
            {
                name = "Attach",
                type = "python",
                request = "attach",
                connect = {
                    host = "127.0.0.1",
                    port = (project_config.dap and project_config.dap.python_attach_port) or 5678,
                },
            },
        }

        dap.configurations.python = python_configurations
        dap.configurations.debugpy = python_configurations

        dap.listeners.before.launch["salar-project-config"] = function(session)
            session.config = project.apply_dap_defaults(session.config)
        end

        vim.keymap.set("n", "<leader>dnp", dap_python.test_method, { desc = "Python test method" })
        vim.keymap.set("n", "<leader>dnc", dap_python.test_class, { desc = "Python test class" })
        vim.keymap.set("v", "<leader>dns", dap_python.debug_selection, { desc = "Python debug selection" })
    end,
}
