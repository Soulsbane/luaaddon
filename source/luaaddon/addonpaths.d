module luaaddon.addonpaths;

/**
	Provides various path related API functions for use with Lua.
*/
import std.file : exists, getcwd, thisExePath;
import std.path : dirName, buildNormalizedPath;

import dfileutils;
import dpathutils;

class AddonPaths
{
public:
	this() {}

	this(const string addonName, const string applicationName, const string organizationName = string.init)
	{
		create(addonName, applicationName, organizationName);
	}

	void create(const string addonName, const string applicationName, const string organizationName = string.init)
	{
		addonName_ = addonName;
		configPath_.create(organizationName, applicationName);
	}

	string getInstallDir()
	{
		return dirName(thisExePath());
	}

	string getBaseAddonDir()
	{
		debug
		{
			return buildNormalizedPath(getInstallDir(), getAddonDirName());
		}
		else
		{
			return configPath_.getAppDir(getAddonDirName());
		}
	}

	string getAddonDirFor(const string addonName = string.init)
	{
		debug
		{
			return buildNormalizedPath(getInstallDir(), getAddonDirName(), addonName);
		}
		else
		{
			return configPath_.getAppDir(getAddonDirName(), addonName);
		}
	}

	string getModuleDir()
	{
		debug
		{
			return buildNormalizedPath(getInstallDir(), "modules");
		}
		else
		{
			return configPath_.getAppDir("modules");
		}
	}

	string getTemplatesDir()
	{
		debug
		{
			return buildNormalizedPath(getInstallDir(), "templates");
		}
		else
		{
			return configPath_.getAppDir("templates");
		}
	}

	string getNormalizedPath(const(char)[][] params...)
	{
		return buildNormalizedPath(params);
	}

	bool createDirInAddonDir(const string addonName)
	{
		return ensurePathExists(buildNormalizedPath(getBaseAddonDir(), addonName));
	}

	bool dirExists(const string dir) const
	{
		return dir.exists;
	}

	bool addonExists(const string name)
	{
		immutable string path = buildNormalizedPath(getBaseAddonDir(), name);
		return path.exists;
	}

	string getAddonDir()
	{
		return getAddonDirFor(addonName_);
	}

	string getAddonModulesDir()
	{
		return buildNormalizedPath(getAddonDir(), "modules");
	}

	string getAddonTemplatesDir()
	{
		return buildNormalizedPath(getAddonDir(), "templates");
	}

	string getConfigDir()
	{
		return configPath_.getAppDir();
	}

	string getConfigFilesDir()
	{
		return configPath_.getAppDir("config");
	}

	string getAddonDirName()
	{
		return addonDirName_;
	}

	void setAddonDirName(const string addonDirName)
	{
		addonDirName_ = addonDirName;
	}

	string getAddonName()
	{
		return addonName_;
	}

	void setAddonName(const string addonName)
	{
		addonName_ = addonName;
	}

private:
	string addonName_;
	string addonDirName_ = "addons";
	ConfigPath configPath_;
}

unittest
{
	//auto paths = new AddonPaths("myaddon", "mycoolapp");
	//writeln(paths.getBaseAddonDir());
}
