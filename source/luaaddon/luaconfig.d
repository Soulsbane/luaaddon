/**
	Allows the usage of Lua as a configuration file format.
*/
module luaaddon.luaconfig;

import std.stdio : write;
import std.string : chop;
import std.range : repeat;
import std.array : join;

import luaaddon.base;

private	string processTable(LuaTable table)
{
	string temp;

	foreach(string key, LuaObject value; table)
	{
		if(value.type == LuaType.Table)
		{
			LuaTable table;

			table.object = value;

			temp ~= key ~ " = {";
			temp ~= processTable(table);
		}
		else
		{
			if(value.type == LuaType.String)
			{
				temp ~= key ~ " = " ~ "\"" ~ value.toString ~ "\"" ~ ",";
			}
			else
			{
				temp ~= key ~ " = " ~ value.toString ~ ",";
			}
		}
	}

	temp ~= "},";

	return temp;
}

/**
	Allows the usage of Lua as a configuration file format.
	Note: This only loads Lua files and does not support saving at this time.
*/
class LuaConfig : LuaAddonBase
{
	/**
		Loads a Lua config file.

		Params:
			fileName = Name of the file to load.
			tableName = The name of the table where config values are found. Only single layer tables are supported.

		Returns:
			True if the file was found and false otherwise.
	*/
	bool loadFile(const string fileName, const string tableName = "Config")
	{
		fileName_ = fileName;
		configTableName_ = tableName;

		return doFile(fileName);
	}

	/**
		Loads a string containing the Lua table to use.

		Params:
			text = The text that contains the Lua table to use.
	 		tableName = The name of the table where config values are found. Only single layer tables are supported.
	*/
	void loadString(const string text, const string tableName = "Config")
	{
		configTableName_ = tableName;
		doString(text);
	}

	void save()
	{
		string temp = configTableName_ ~ " = {";
		auto table = getTable(configTableName_);

		temp ~= processTable(table);
		write(temp.chop);
	}
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

	T as(T = string)(const string key, T value, T defaultValue = T.init)
	{
		return get!T("Config", key, defaultValue);
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

	private string configTableName_;
	private string fileName_;
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
				secondLevelValue = "Second level",
				Another = {
					world = "Another world"
				}
			}
		}

		Exist = "I exist"

		Config = {
			number = 10,
			hello = "Hello World!",
			decimal = 3.14,
			boolean = true
		}
	};

	LuaConfig config = new LuaConfig;

	config.doString(configString);

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
	immutable bool loaded = emptyConfig.doString(emptyString);
	assert(loaded == false);

	LuaConfig multiConfig = new LuaConfig;
	multiConfig.loadString(configString);

	writeln;
	writeln;

	multiConfig.save();
	writeln;
}
