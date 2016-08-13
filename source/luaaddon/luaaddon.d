module luaaddon.luaaddon;

import std.algorithm : each;
import std.path : buildNormalizedPath;

public import luad.all;

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

	bool callFunction(T...)(const string name, T args)
	{
		if(hasFunction(name))
		{
			state_.get!LuaFunction(name)(args);
			return true;
		}

		return false;
	}

	auto getFunctionReturnValue(T...)(const string name, T args)
	{
		auto value = state_.get!LuaFunction(name)(args);
		return value[0];
	}

	auto getFunctionReturnValues(T...)(const string name, T args)
	{
		return state_.get!LuaFunction(name)(args);
	}

	bool hasFunction(const string name)
	{
		return state_[name].isNil ? false : true;
	}

	alias hasTable = hasFunction; // Just to make function calls clearer.

	void createNewTable(string[] names...)
	{
		names.each!(name =>	state_[name] = state_.newTable);
	}

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

	void registerFunction(T)(const string funcName, T func)
	{
		registerFunction(string.init, funcName, func);
	}

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
