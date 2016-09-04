/**
	Provides a simple interface for creating a Lua addon for your program.
*/
module luaaddon.luaaddon;

import std.algorithm : each;
import std.path : buildNormalizedPath;
import std.file : exists;
import std.string : chop;
import std.stdio : writeln;

public import luad.all;
import luad.c.all;

///Main type for creating a Lua addon.
class LuaAddon
{
	this()
	{
		// FIXME: Workaround for a LuaD bug  where LuaState is used but was already destroyed. See LuaD issue# 11.
		auto L = luaL_newstate();

		state_ = new LuaState(L);
		state_.openLibs();
		state_.setPanicHandler(&panic);
	}

	static void panic(LuaState lua, in char[] error)
	{
		writeln("Error in addon code!\n", error, "\n");
	}

	/**
		Calls a Lua function and returns its value. This should only be used with Lua functions that return only a
		single value.

		Params:
			name = The name of the function to call.
			args = The arguments to the function to call.

		Returns:
			The value(LuaObject) from the Lua function that was called.
	*/
	auto getFunctionReturnValue(T...)(const string name, T args)
	{
		auto value = state_.get!LuaFunction(name)(args);
		return value[0];
	}

	/**
		Calls a Lua function and returns its value as a tuple

		Params:
			name = The name of the function to call.
			args = The arguments to the function to call.
		Returns:
			The value as a tuple from the Lua function that was called.
	*/
	auto getFunctionReturnValues(T...)(const string name, T args)
	{
		return state_.get!LuaFunction(name)(args);
	}

	/**
		Calls Lua function with no return value. Useful for an OnInitialize function that should be called at program start and
		has no return value.

		Params:
			T = The type to convert the returned value to.
			name = The name of the function to call.
			args = The arguments to the function to call.
	*/
	T callFunction(T = void, S...)(const string name, S args)
	{
		if(hasFunction(name))
		{
			static if(is(T == void))
			{
				state_.get!LuaFunction(name)(args);
			}
			else
			{
				auto value = state_.get!LuaFunction(name)(args);
				return value[0].to!T;
			}
		}
		else
		{
			static if(!is(T == void))
			{
				return T.init;
			}
		}
	}

	/**
		Checks if a function is defined in the Lua addon.

		Params:
			name = Name of the function to find.

		Retruns:
			True if the function was found false otherwise.
	*/
	bool hasFunction(const string name)
	{
		return state_[name].isNil ? false : true;
	}

	/// Just makes function calls clearer.
	alias hasTable = hasFunction;

	/**
		Creates a new table.

		Params:
			names = A list of table names to be created.
	*/
	void createNewTable(string[] names...)
	{
		names.each!(name =>	state_[name] = state_.newTable);
	}

	/**
		Registers a function that can be called from Lua code.

		Params:
			tableName = Creates a table which the funcName will be associated with. Ex. IO.ReadText.
			funcName = The name to use for the function on in Lua code.
			func = The function to register.
	*/
	void registerFunction(T)(const string tableName, const string funcName, T func)
	{
		if(tableName.length)
		{
			if(!hasTable(tableName))
			{
				createNewTable(tableName);
			}

			state_[tableName, funcName] = func;
		}
		else
		{
			state_[funcName] = func;
		}
	}

	/**
		Registers a function that can be called from Lua code.

		Params:
			funcName = The name to use for the function on in Lua code.
			func = The function to register.
	*/
	void registerFunction(T)(const string funcName, T func)
	{
		registerFunction(string.init, funcName, func);
	}

	/**
		Registers a path that lua code will search for packages/modules.

		Params:
			path = A list of path names to register.
	*/
	void registerPackagePaths(const string[] paths...)
	{
		string packagePaths;

		paths.each!(path => packagePaths ~= buildNormalizedPath(path, "?.lua") ~ ";");
		state_["package", "path"] = packagePaths.chop; // Remove trailing semicolon.
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
			state_.doFile(name);
			return true;
		}

		return false;
	}

	/**
		Loads a Lua file(s) using doFile.

		Params:
			paths = A list of files to load.
	*/
	void loadFiles(const string[] paths...)
	{
		paths.each!(path => loadFile(path));
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
			state_.doString(data);
			return true;
		}

		return false;
	}

	auto opDispatch(string funcName, T...)(T args)
	{
		return mixin("state_." ~ funcName ~ "(args)");
	}

	protected LuaState state_;
}
