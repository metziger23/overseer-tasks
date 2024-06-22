local ctx = require("exrc").init()
local qmake = "/Volumes/k/Qt/6.6.2/macos/bin/qmake"
local pro_file = "~/Development/ConsoleApplication/ConsoleApplication.pro"
local qmake_all = "/usr/bin/make qmake_all"
local debug = "CONFIG+=debug"
local other = "-spec macx-clang  CONFIG+=qml_debug"
local make_dir = "--directory ~/Development/ConsoleApplication/"
local executable = "~/Development/ConsoleApplication/ConsoleApplication"

local overseer = require("overseer")

local default_components = {
	{ "on_output_summarize", max_lines = 10 },
	{ "on_exit_set_status" },
	{ "on_complete_notify" },
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
			components = {},
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
			cmd = "compiledb make -j8" .. " " .. dir,
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
			cmd = "make -j8" .. " " .. dir,
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
			cmd = "make clean -j8" .. " " .. dir,
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
	name = "build and run target orchestrator",
	params = {},
	condition = exrc_condition,
	builder = function()
		return {
			cmd = "",
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

overseer.register_template({
	name = "build and run target",
	params = {},
	condition = exrc_condition,
	builder = function()
		local build_and_run_components = vim.deepcopy(default_components)
		local seq_tasks = {
			"dependencies",
			task_names = {
				"make",
				"run target",
			},
			sequential = true,
		}
		table.insert(build_and_run_components, seq_tasks)
		return {
			cmd = "",
			components = build_and_run_components,
		}
	end,
})

-- overseer.add_template_hook({ name = "run target" }, function(task_defn)
-- 	task_defn.env = vim.tbl_extend("force", task_defn.env or {}, {
-- 		DYLD_FRAMEWORK_PATH = "/Volumes/k/Qt/6.6.2/macos/lib",
-- 		DYLD_LIBRARY_PATH = "/Volumes/k/Qt/6.6.2/macos/lib",
-- 	})
-- end)
