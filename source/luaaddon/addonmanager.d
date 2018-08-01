module luaaddon.addonmanager;

import luaaddon.luaaddon;

class LuaAddonManager
{
	void register(LuaAddon addon)
	{
		addons_ ~= addon;
	}

	T callFunction(T = void, S...)(const string name, S args)
	{
		foreach(addon; addons_)
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
	}

	bool hasFunction(const string name, const string addonName = string.init)
	{
		return true; //TODO: Once an identification system is decided upon for each LuaAddon then we will implement this.
	}

	auto getAddon(const string addonName)
	{
		foreach(addon; addons_)
		{
			if(addon.getName() == addonName)
			{
				return addon;
			}
		}

		assert(0); //FIXME: Perhaps fire an exception?
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
	auto addon = manager.getAddon("TestAddon");
	assert(addon.getAuthor() == "Tester");
}
