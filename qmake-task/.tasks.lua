local qmake = ""
local pro_file = ""
local qmake_all = "/usr/bin/make qmake_all"
local debug = "CONFIG+=debug"
local spec = ""
local make_dir = ""
local executable = ""

local function get_qmake_path(qmake_arg)
	if qmake_arg ~= "" then
		return qmake_arg
	end

	local possible_paths = {
		"/Volumes/ADATA-LEGEND-960-MAX/Qt/6.7.2/macos/bin/qmake",
	}

	for _, possible_path in pairs(possible_paths) do
		local path_exists = io.open(possible_path, "r")
		if path_exists ~= nil then
			return possible_path
		end
	end

	return ""
end

local function get_spec(spec_arg)
	if spec_arg ~= "" then
		return spec_arg
	end
	if vim.fn.has("mac") == 1 then
		return "macx-clang"
	elseif vim.fn.has("linux") == 1 then
		return "linux-g++"
	end
	return ""
end

local function get_pro_file(pro_file_arg)
	if pro_file_arg ~= "" then
		return pro_file_arg
	end

	local cwd = vim.fn.getcwd()
	local files = vim.fn.readdir(cwd)
	for _, file in ipairs(files) do
		if file:match("%.pro$") then
			return cwd .. "/" .. file
		end
	end
	return ""
end

-- local function get_pro_file(pro_file_arg)
-- 	if pro_file_arg ~= "" then
-- 		return pro_file_arg
-- 	end
--
-- 	local found_pro_file = vim.fn.findfile("*.pro",  ".;")
-- 	if found_pro_file ~= "" then
-- 		return found_pro_file
-- 	end
-- 	return ""
-- end

local function get_directory(directory_arg)
	if directory_arg ~= "" then
		return directory_arg
	end

	local found_pro_file = get_pro_file("")

	if found_pro_file ~= "" then
		return vim.fn.fnamemodify(found_pro_file, ":p:h")
	end
	return ""
end

local function get_executable(executable_arg)
	if executable_arg ~= "" then
		return executable_arg
	end

	local found_pro_file = get_pro_file("")

	if found_pro_file ~= "" then
		return vim.fn.fnamemodify(found_pro_file, ":t:r")
	end
	return ""
end

pro_file = get_pro_file(pro_file)
qmake = get_qmake_path(qmake)
spec = get_spec(spec)
make_dir = "--directory " .. get_directory(make_dir)
executable = "./" .. get_executable(executable)

local other = "-spec " .. spec .. " CONFIG+=qml_debug"

local ctx = require("exrc").init()
local overseer = require("overseer")

local default_components = {
	{ "on_output_summarize", max_lines = 10 },
	{ "on_exit_set_status" },
	-- { "on_complete_notify" },
	{ "unique" },
	{ "display_duration" },
}

local exrc_condition = {
	callback = function(_)
		return ctx.exrc_dir == vim.fn.getcwd()
	end,
}

overseer.register_template({
	name = "qmake debug",
	params = {},
	condition = exrc_condition,
	builder = function()
		return {
			cmd = qmake .. " " .. pro_file .. " " .. other .. " " .. debug .. " && " .. qmake_all,
			components = default_components,
		}
	end,
})

overseer.register_template({
	name = "qmake release",
	params = {},
	condition = exrc_condition,
	builder = function()
		return {
			cmd = qmake .. " " .. pro_file .. " " .. other .. " && " .. qmake_all,
			components = default_components,
		}
	end,
})

overseer.register_template({
	name = "compiledb",
	params = {},
	condition = exrc_condition,
	builder = function()
		local dir = make_dir
		return {
			cmd = "compiledb make -j" .. " " .. dir,
			components = default_components,
		}
	end,
})

overseer.register_template({
	name = "make",
	params = {},
	condition = exrc_condition,
	builder = function()
		local dir = make_dir
		return {
			cmd = "make -j" .. " " .. dir,
			components = default_components,
		}
	end,
})

overseer.register_template({
	name = "make clean",
	params = {},
	condition = exrc_condition,
	builder = function()
		local dir = make_dir
		return {
			cmd = "make clean -j" .. " " .. dir,
			components = default_components,
		}
	end,
})

overseer.register_template({
	name = "run target",
	params = {},
	condition = exrc_condition,
	builder = function()
		return {
			cmd = executable,
			components = default_components,
		}
	end,
})

overseer.register_template({
	name = "build and run target",
	params = {},
	condition = exrc_condition,
	builder = function()
		return {
			cmd = "",
			components = default_components,
			strategy = {
				"orchestrator",
				tasks = {
					"make",
					"run target",
				},
			},
		}
	end,
})

-- overseer.add_template_hook({ name = "run target" }, function(task_defn)
-- 	task_defn.env = vim.tbl_extend("force", task_defn.env or {}, {
-- 		DYLD_FRAMEWORK_PATH = "/Volumes/k/Qt/6.6.2/macos/lib",
-- 		DYLD_LIBRARY_PATH = "/Volumes/k/Qt/6.6.2/macos/lib",
-- 	})
-- end)
