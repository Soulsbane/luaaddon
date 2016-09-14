/**
	Allows the usage of Lua as a configuration file format.
*/
module luaaddon.luaconfig;

import std.file : exists;
import luaaddon.luaaddon;

/**
	Allows the usage of Lua as a configuration file format.
	Note: This only loads Lua files and does not support saving at this time.
*/
class LuaConfig : LuaAddon
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

	T get(T = string, S...)(S args, T defaultValue)
	{
		if(state_[args].isNil)
		{
			return defaultValue;
		}

		return state_.get!T(args);
	}

	void set(T...)(T args)
	{
		static if(args.length >= 2) //TODO: Figure out what to do if < 2 args are passed.
		{
			state_[args[0..$ - 1]] = args[$ - 1];
		}
	}

	LuaTable config_;
}

struct LuaConfig2
{
	this(const string fileName, const string tableName = "Config")
	{
		state_ = new LuaState;

	}

	LuaState state_;
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
