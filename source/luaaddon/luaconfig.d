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

		Returns:
			The value of variableName
	*/
	T getValue(T = string)(const string variableName)
	{
		return state_.get!T(variableName);
	}

	/**
		Returns a variables value from a config file using its table name and variable name.

		Params:
			table = The name of the table the variable resides in. Only supports a top level table.
			name = The name of the variable to return.

		Returns:
			The value of tableName.variableName
	*/
	T getValue(T = string)(const string table, const string variableName)
	{
		return state_.get!T(table, variableName);
	}

	/**
		Loads a config file using doFile.

		Params:
			name = The config file to load.

		Returns:
			True if the file exists false otherwise.
	*/
	bool loadFile(const string name)
	{
		if(name.exists)
		{
			super.doFile(name);
			return true;
		}

		return false;
	}

	/**
		Loads a string using doString.

		Params:
			data = The string to load.

		Returns:
			True if the string isn't empty false otherwise.
	*/
	bool loadString(const string data)
	{
		if(data.length)
		{
			super.doString(data);
			return true;
		}

		return false;
	}
}
