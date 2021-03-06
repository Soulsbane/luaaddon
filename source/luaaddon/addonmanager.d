module luaaddon.addonmanager;

import std.exception : enforce;
import std.array : array;
import std.algorithm : filter;

import luaaddon.luaaddon;
import luaaddon.addonexception;

class LuaAddonManager
{
	/**
		Register an addon.

		Params:
			addon = The addon object to register.
	*/
	void register(LuaAddon addon)
	{
		addons_ ~= addon;
	}

	/**
		Calls a Lua function and returns it's value as type T. If T = void no value will be returned(default).

		Params:
			T = The type to convert the returned value to.
			name = The name of the function to call.
			args = The arguments to the function to call.
	*/
	T callFunctionForAll(T = void, S...)(const string name, S args)
	{
		foreach(addon; addons_)
		{
			callFunction(addon);
		}
	}

	/**
		Calls a Lua function and returns it's value as type T. If T = void no value will be returned(default).

		Params:
			T = The type to convert the returned value to.
			addon = The addon object to call.
			name = The name of the function to call.
			args = The arguments to the function to call.
	*/
	T callFunction(T = void, S...)(LuaAddon addon, const string name, S args)
	{
		if(addon.hasFunction(name))
		{
			static if(is(T == void))
			{
				addon.callFunction(name, args);
			}
			else
			{
				auto value = addon.callFunction(name, args);
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
		Determines if an addon has a function defined.

		Params:
			functionName = Name of the function to find.
			addonName = Name of the addon to check.

		Returns:
			True if the function exists false otherwise.
	*/
	bool hasFunction(const string functionName, const string addonName = string.init)
	{
		auto addon = getAddon(addonName);

		if(addon.hasFunction(functionName))
		{
			return true;
		}

		return false;
	}

	/**
		Checks if the given addon name is registered in AddonManager.

		Params:
			addonName = Name of the addon to look for.

		Returns:
			True if the addon is registered false otherwise.
	*/
	bool hasAddon(const string addonName)
	{
		size_t foundCount = addons_.filter!(addon => addon.getName() == addonName).array.length;

		if(foundCount > 0)
		{
			return true;
		}

		return false;
	}

	/**
		Returns the LuaAddon object that matches the name passed to this method.

		Params:
			addonName = The name of the LuaAddon to get.

		Returns:
			The LuaAddon object that matches the name passed to this method.
	*/
	auto getAddon(const string addonName)
	{
		auto addons = addons_.filter!(addon => addon.getName() == addonName).array;

		enforce!LuaAddonException(addons.length == 1, "Could not load addon: " ~ addonName);
		return addons[0];
	}

	/**
		Gets the number of registered addons.

		Returns:
			The number of registered addons.
	*/
	size_t getAddonCount()
	{
		return addons_.length;
	}

private:
	LuaAddon[] addons_;
}

version(unittest)
{
	class TestAddon : LuaAddon
	{
		override string getAuthor()
		{
			return "Tester";
		}

		override string getName()
		{
			return "TestAddon";
		}

		override size_t getVersion()
		{
			return 1_000;
		}

		override string getDescription()
		{
			return "This is a test";
		}
	}
}

unittest
{
	TestAddon gen = new TestAddon;
	LuaAddonManager manager = new LuaAddonManager;

	manager.register(gen);

	assert(manager.hasAddon("TestAddon") == true);
	assert(manager.hasAddon("ShouldFail") == false);

	auto addon = manager.getAddon("TestAddon");
	assert(addon.getAuthor() == "Tester");
	assert(manager.getAddonCount() == 1);
	//auto explode = manager.getAddon("ExplodeAddon");
}
