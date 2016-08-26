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
	LuaTable getTable(const string name) @trusted
	{
		LuaTable variable = state_.get!LuaTable(name);
		return variable;
	}

	/**
		Returns a variables value from a config file.

		Params:
			name = The name of the variable to return.
			defaultValue = The value to return if config variable isn't found.

		Returns:
			The value of variableName
	*/
	T getValue(T = string)(const string variableName, T defaultValue = T.init)
	{
		if(state_[variableName].isNil)
		{
			return defaultValue;
		}

		return state_.get!T(variableName);
	}

	/**
		Returns a variables value from a config file using its table name and variable name.

		Params:
			table = The name of the table the variable resides in. Only supports a top level table.
			name = The name of the variable to return.
			defaultValue = The value to return if config variable isn't found.

		Returns:
			The value of tableName.variableName
	*/
	T getTableValue(T = string)(const string table, const string variableName, T defaultValue = T.init)
	{
		if(state_[table, variableName].isNil)
		{
			return defaultValue;
		}

		return state_.get!T(table, variableName);
	}

	/**
		Returns a variables value from a config file using its table name and variable name.
		This function allows the retrieval of a value through multiple layers of a table.
		NOTE: Unlike the other get methods this is method requires the defaultValue as the first parameter due to a
		limitation in D's templates.

		Params:
			defaultValue = The default value to use if the variable isn't found.
			args = The name of the table(s) the variable resides in.

		Returns:
			The value of firstTable.secondTable.variableName.
	*/
	T getTableValueEx(T = string, S...)(T defaultValue, S args)
	{
		if(state_[args].isNil)
		{
			return defaultValue;
		}

		return state_.get!T(args);
	}
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

	assert(config.getTableValue!bool("AppConfigVars", "DeleteAllTodoFilesAtStart"));
	assert(config.getTableValue!bool("AppConfigVars", "NoValue", true));

	assert(config.getTableValueEx("The default Value", "NonExist") == "The default Value");
	assert(config.getTableValueEx("Won't print!", "Exist") == "I exist");
	assert(config.getTableValueEx("Default value", "MultiLevel", "SecondLevel", "secondLevelValue") == "Second level");
	assert(config.getTableValueEx("Default value", "MultiLevel", "SecondLevel", "noSecondLevelValue") == "Default value");

	assert(config.getValue("NonExist", "The default Value") == "The default Value");
	assert(config.getValue("Exist", "The default Value") == "I exist");

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
