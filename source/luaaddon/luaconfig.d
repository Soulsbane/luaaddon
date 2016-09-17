/**
	Allows the usage of Lua as a configuration file format.
*/
module luaaddon.luaconfig;

import luaaddon.base;

/**
	Allows the usage of Lua as a configuration file format.
	Note: This only loads Lua files and does not support saving at this time.
*/
class LuaConfig : LuaAddonBase
{
	/**
		Returns a table from a config file.

		Params:
			name = The name of the table to return.

		Returns:
			The table.
	*/
	LuaTable getTable(const string name)
	{
		LuaTable variable = state_.get!LuaTable(name);
		return variable;
	}

	/**
		Returns a value of type T from a config file(variable, table).

		Params:
			args = A list of tables or variables that should be returned.
			defaultValue = The default value if the table or variable can't be found.
	*/
	T get(T = string, S...)(S args, T defaultValue)
	{
		if(state_[args].isNil)
		{
			return defaultValue;
		}

		return state_.get!T(args);
	}

	/**
		Sets a value variable or table value.

		Params:
			args = A list of tables or variables that that will be set.
	*/
	void set(T, S...)(S args, T value)
	{
		state_[args] = value;
	}

	private LuaTable config_;
}

///
unittest
{
	import std.stdio : writeln;

	enum configString =
	q{
		TodoTaskPatterns = {
			["(?P<tag>[A-Z]+):(?P<message>.*)"] = false,
			["\\W+(?P<tag>[a-zA-Z]+):\\s+(?P<message>.*)"] = false,
			["\\W+(?P<tag>INFO|NOTE|FIXME|TODO):\\s+(?P<message>.*)"] = false,
			["[;'#-*@/]*\\s*(?P<tag>INFO|NOTE|FIXME|TODO|XXX):?\\s*(?P<message>.*)"] = true,
		}

		AppConfigVars = {
			DeleteAllTodoFilesAtStart = true,
			DefaultTodoFileName = "todo",
		}

		MultiLevel = {
			SecondLevel = {
				secondLevelValue = "Second level"
			}
		}

		Exist = "I exist"
	};

	LuaConfig config = new LuaConfig;

	config.loadString(configString);

	auto patterns = config.getTable("TodoTaskPatterns");
	auto configVars = config.getTable("AppConfigVars");

	foreach(string key, bool value; patterns)
	{
		writeln("Key => ", key, " Value => ", value);
	}

	assert(config.get!bool("AppConfigVars", "NoValue", true)); // A default value must always be passed.

	assert(config.get("Exist", "Won't print!") == "I exist");
	assert(config.get("MultiLevel", "SecondLevel", "secondLevelValue", "Default value") == "Second level");
	assert(config.get("MultiLevel", "SecondLevel", "noSecondLevelValue", "Default value") == "Default value");
	config.set("MultiLevel", "SecondLevel", "secondLevelValue", "Changed value");
	assert(config.get("MultiLevel", "SecondLevel", "secondLevelValue", "Default value") == "Changed value");

	assert(config.get("NonExist", "The default Value") == "The default Value");
	assert(config.get("Exist", "The default Value") == "I exist");
	config.set("Exist", "No I'm not so sure.");
	assert(config.get("Exist", "The default Value") == "No I'm not so sure.");

	assert(config.get("AppConfigVars", "DeleteAllTodoFilesAtStart", false) == true);
	config.set("AppConfigVars", "DeleteAllTodoFilesAtStart", false);
	assert(config.get("AppConfigVars", "DeleteAllTodoFilesAtStart", false) == false);

	foreach(string key, LuaObject value; configVars)
	{
		if(value.type == LuaType.Boolean)
		{
			writeln("Its a boolean");
		}

		writeln("Key => ", key, " Value => ", value.toString);
	}

	enum emptyString = "";

	LuaConfig emptyConfig = new LuaConfig;
	bool loaded = emptyConfig.loadString(emptyString);
	assert(loaded == false);
}
