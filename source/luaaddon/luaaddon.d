/**
	Provides a simple interface for creating a Lua addon for your program.
*/
module luaaddon.luaaddon;

import std.algorithm : each;
import std.path : buildNormalizedPath;

public import luad.all;

///The main class for creating a Lua addon.
class LuaAddon
{
	this()
	{
		setupEnvironment();
	}

	static void panic(LuaState lua, in char[] error)
	{
		import std.stdio : writeln;
		writeln("Error in addon code!\n", error, "\n");
	}

	/**
		Calls Lua function with no return value. Useful for an OnInitialize function that should be called at program start and
		has no return value.

		Params:
			name = The name of the function to call.
			args = The arguments to the function to call.
	*/
	bool callFunction(T...)(const string name, T args)
	{
		if(hasFunction(name))
		{
			state_.get!LuaFunction(name)(args);
			return true;
		}

		return false;
	}

	/**
		Calls a Lua function and returns its value. This should only be used with Lua functions that return only a
		single value.

		Params:
			name = The name of the function to call.
			args = The arguments to the function to call.

		Returns:
			The value from the Lua function that was called.
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
		packagePaths = packagePaths[0..$ - 1];
		state_["package", "path"] = packagePaths;
	}

	auto opDispatch(string funcName, T...)(T args)
	{
		return mixin("state_." ~ funcName ~ "(args)");
	}

private:
	void setupEnvironment()
	{
		state_ = new LuaState;

		state_.openLibs();
		state_.setPanicHandler(&panic);
	}

protected:
	LuaState state_;
	alias state_ this;
}
