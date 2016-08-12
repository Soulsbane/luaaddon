module luaaddon.luaconfig;

import std.file : exists;
import luaaddon.luaaddon;

class LuaConfig : LuaAddon
{

	LuaTable getTable(const string name) @trusted
	{
		LuaTable variable = state_.get!LuaTable(name);
		return variable;
	}

	T getValue(T = string)(const string name)
	{
		return state_.get!T(name);
	}

	T getValue(T = string)(const string table, const string name)
	{
		return state_.get!T(table, name);
	}

	bool loadFile(const string name)
	{
		if(name.exists)
		{
			super.doFile(name);
			return true;
		}

		return false;
	}

	//Make note about loadString actually calling doString.
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
