/**
	Provides a simple interface for creating a Lua addon for your program.
*/
module luaaddon.luaaddon;

import std.algorithm : each;
import std.path : buildNormalizedPath;
import std.file : exists;
import std.string : chop;
import std.stdio : writeln;

import luaaddon.base;
import luaaddon.tocparser;

///Main type for creating a Lua addon.
class LuaAddon : LuaAddonBase
{
	///
	this()
	{
		state_.openLibs();
		state_.setPanicHandler(&panic);
	}

	///
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
	T getFunctionReturnValue(T = LuaObject, S...)(const string name, S args)
	{
		auto value = state_.get!LuaFunction(name)(args);
		static if(is(T == LuaObject))
		{
			return value[0];
		}
		else
		{
			return value[0].to!T;
		}
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
		Calls a Lua function and returns it's value as type T. If T = void no value will be returned(default).

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

	/**
		Creates a new table.

		Params:
			names = A list of table names to be created.
	*/
	void createTable(string[] names...)
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
				createTable(tableName);
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
			paths = A list of path names to register.
	*/
	void registerPackagePaths(const string[] paths...)
	{
		string packagePaths;

		paths.each!(path => packagePaths ~= buildNormalizedPath(path, "?.lua") ~ ";");
		state_["package", "path"] = packagePaths.chop; // Remove trailing semicolon.
	}

	string getAuthor()
	{
		return toc_.getValue("Author", "Author");
	}

	string getDescription()
	{
		return toc_.getValue("Description", "");
	}

	string getName()
	{
		return toc_.getValue("Name", "");
	}

	size_t getVersion()
	{
		return toc_.getValue!size_t("Version", 10_000);
	}

	alias loadTocString = toc_.loadString;
	alias loadTocFile = toc_.loadFile;
	alias hasTocField = toc_.hasField;
	alias getTocValue = toc_.getValue;
	alias getTocFilesList = toc_.getFilesList;

	///
	auto opDispatch(string funcName, T...)(T args)
	{
		return mixin("state_." ~ funcName ~ "(args)");
	}

private:
	TocParser!() toc_;
}
