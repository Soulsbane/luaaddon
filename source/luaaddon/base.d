/**
	Provides a base class for LuaAddon and LuaConfig.
*/
module luaaddon.base;

import std.file : exists;
import std.typecons : Tuple;

public import luad.all;
import luad.c.all;

alias DoFilesReturnType = Tuple!(bool, "found", string, "path");

/**
	Provides a base class for LuaAddon and LuaConfig.
*/
class LuaAddonBase
{
	///
	this()
	{
		// FIXME: Workaround for a LuaD bug  where LuaState is used but was already destroyed. See LuaD issue# 11.
		auto L = luaL_newstate();
		state_ = new LuaState(L);
	}

	/**
		Loads a Lua file using LuaD's doFile.

		Params:
			name = The file to load.

		Returns:
			True if the file exists false otherwise.
	*/
	bool doFile(const string name)
	{
		if(name.exists)
		{
			state_.doFile(name);
			return true;
		}

		return false;
	}

	/**
		Loads, executes and passes arguments to a Lua file using LuaD's loadFile.

		Params:
			name = The file to load.
			args = The arguments to pass to the Lua chunk/file.

		Returns:
			True if the file exists false otherwise.
	*/
	bool loadFile(T...)(const string name, T args)
	{
		if(name.exists)
		{
			state_.loadFile(name)(args);
			return true;
		}

		return false;
	}

	/**
		Loads a Lua file(s) using doFile.

		Params:
			paths = A list of files to load.

		Returns:
			True if all files were found false otherwise.
	*/
	DoFilesReturnType doFiles(const string[] paths...)
	{
		foreach(path; paths)
		{
			immutable bool found = doFile(path);

			if(!found)
			{
				return DoFilesReturnType(false, path);
			}
		}

		return DoFilesReturnType(true, string.init);
	}

	/**
		Loads a string using LuaD's doString.

		Params:
			data = The string to load.

		Returns:
			True if the string isn't empty false otherwise.
	*/
	bool doString(const string data)
	{
		if(data.length)
		{
			state_.doString(data);
			return true;
		}

		return false;
	}

	/**
		Checks for the existence of a Lua table.

		Params:
			name = Name of the table to find.

		Retruns:
			True if the table was found false otherwise.
	*/
	bool hasTable(const string name)
	{
		return state_[name].isNil ? false : true;
	}

	protected LuaState state_;
}
