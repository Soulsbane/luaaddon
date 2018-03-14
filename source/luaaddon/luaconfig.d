/**
	Allows the usage of Lua as a configuration file format.
*/
module luaaddon.luaconfig;

import std.stdio : write, File;
import std.string : chop;
import std.range : repeat;
import std.array : join, Appender, appender;

import luaaddon.base;
private enum DEFAULT_CONFIG_FILE_NAME = "config.lua";

private	string processTable(LuaTable table, const size_t currentDepth)
{
	auto temp = appender!string();

	size_t depth = currentDepth + 1;

	foreach(string key, LuaObject value; table)
	{
		if(value.type == LuaType.Table)
		{
			LuaTable table;

			table.object = value;

			temp.put("\t".repeat(depth).join);
			temp.put(key);
			temp.put(" = {\n");
			temp.put(processTable(table, depth));
		}
		else
		{
			if(value.type == LuaType.String)
			{
				temp.put("\t".repeat(depth).join);
				temp.put(key);
				temp.put(" = \"");
				temp.put(value.toString);
				temp.put("\",\n");
			}
			else
			{
				temp.put("\t".repeat(depth).join);
				temp.put(key);
				temp.put(" = ");
				temp.put(value.toString);
				temp.put(",\n");
			}
		}
	}

	depth = depth - 1;

	temp.put("\t".repeat(depth).join);
	temp.put("},\n");

	return temp.data;
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

	/**
		Saves config values to the config file.
	*/
	void save()
	{
		save(fileName_);
	}

	/**
		Saves config values to the config file.

		Params:
			configFileName = Name of the file to save config values to.
	*/
	void save(const string configFileName)
	{
		string fileName = configFileName;

		if(!fileName.length)
		{
			fileName = DEFAULT_CONFIG_FILE_NAME;
		}

		string temp = configTableName_ ~ " = {\n";
		auto table = getTable(configTableName_);
		auto configFile = File(fileName, "w+");

		temp ~= processTable(table, 0);
		configFile.write(temp.chop.chop); // Remove \n and trailing period from string before writing.
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

	/**
		Returns a value of type T associated with the key from 'Config' table.
		Use 'get' method if you want to access another table beside 'Config'.

		Params:
			key = The config variable that should be returned.
			defaultValue = The default value if the variable can't be found.
	*/
	T as(T = string)(const string key, T defaultValue = T.init)
	{
		return get!T(configTableName_, key, defaultValue);
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
			value = The value to set the table to.
	*/
	void set(T, S...)(S args, T value)
	{
		state_[args] = value;
	}

	/**
		Gets the value of a variable in a lua config file.

		Params:
			name = The name of the variable value to get.

		Returns:
			The value converted to T.
	*/
	T getVariableValue(T = string)(string name)
	{
		return state_.get!T(name);
	}

	/**
		Gets the value of a table variable in a lua config file.

		Params:
			tableName = The name of the table to get variable value from.
			name = The name of the variable to get.

		Returns:
			The value converted to T.
	*/
	T getTableVariableValue(T = string)(const string tableName, const string name)
	{
		auto value = state_.get!T(tableName, name);
		return value;
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

		Config = {
			DeleteAllTodoFilesAtStart = true,
			DefaultTodoFileName = "todo",
		}

		MultiLevel = {
			SecondLevel = {
				secondLevelValue = "Second level",
				Another = {
					world = "Another world",
					number = 42
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
	auto configVars = config.getTable("Config");

	foreach(string key, bool value; patterns)
	{
		writeln("Key => ", key, " Value => ", value);
	}

	assert(config.get!bool("Config", "NoValue", true)); // A default value must always be passed.

	assert(config.get("Exist", "Won't print!") == "I exist");
	assert(config.get("MultiLevel", "SecondLevel", "secondLevelValue", "Default value") == "Second level");
	assert(config.get("MultiLevel", "SecondLevel", "noSecondLevelValue", "Default value") == "Default value");
	config.set("MultiLevel", "SecondLevel", "secondLevelValue", "Changed value");
	assert(config.get("MultiLevel", "SecondLevel", "secondLevelValue", "Default value") == "Changed value");

	assert(config.get("NonExist", "The default Value") == "The default Value");
	assert(config.get("Exist", "The default Value") == "I exist");
	config.set("Exist", "No I'm not so sure.");
	assert(config.get("Exist", "The default Value") == "No I'm not so sure.");

	assert(config.get("Config", "DeleteAllTodoFilesAtStart", false) == true);
	config.set("Config", "DeleteAllTodoFilesAtStart", false);
	assert(config.get("Config", "DeleteAllTodoFilesAtStart", false) == false);

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
	multiConfig.loadString(configString, "MultiLevel");

	writeln;
	writeln;

	multiConfig.save();
	writeln;
}
