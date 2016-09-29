/**
	Provides functionality for parsing TOC(Table of Contents) files like those found in World of Warcraft.
*/
module luaaddon.tocparser;

import std.stdio;
import std.file;
import std.string;
import std.regex : matchFirst, ctRegex;
import std.algorithm;
import std.conv : to;

private enum TOC_LINE_PATTERN = r"##\s+(?P<key>.*):\s+(?P<value>.*)";

/// Parses TOC(Table of Contents) files like those found in World of Warcraft.
struct TocParser
{
	/**
		Processes text containing the TOC format.

		Params:
			text = The text to be processed.
	*/
	void processText(const string text)
	{
		auto lines = text.lineSplitter();
		auto linePattern = ctRegex!(TOC_LINE_PATTERN);

		foreach(line; lines)
		{
			line = strip(line);

			if(line.empty)
			{
				continue;
			}
			else if(line.startsWith("#"))
			{
				auto re = matchFirst(line, linePattern);

				if(!re.empty)
				{
					const string key = re["key"];
					const string value = re["value"];

					fields_[key] = value;
				}
			}
			else // Line is a file name
			{
				if(line.length != line.countchars(" ")) // Make sure line isn't only whitespace
				{
					filesList_ ~= line;
				}
			}
		}
	}

	/**
		Loads and processes a string containing the TOC text.

		Params:
			text = The text to process.

		Returns:
			True if the text has a length(not empty) false otherwise.
	*/
	bool loadString(const string text)
	{
		if(text.length)
		{
			processText(text);
			return true;
		}

		return false;
	}

	/**
		Loads and processes a file that contains the TOC text.

		Params:
			fileName = The name of the file to process.

		Returns:
			True if the file could be found false otherwise.
	*/
	bool loadFile(const string fileName)
	{
		if(fileName.exists)
		{
			processText(fileName.readText);
			return true;
		}

		return false;
	}

	/**
		Checks if a TOC field can be found.

		Params:
			name = The name of the field to find.

		Returns:
			True if the field was found false otherwise.
	*/
	bool hasField(const string name)
	{
		if(name in fields_)
		{
			return true;
		}

		return false;
	}

	/**
		Gets the value for a given field.

		Params:
			name = Name of the field to get the value for.
			defaultValue = The default value if the field wasn't found.

		Returns:
			The fields value if it was found otherwise the defaultValue.
	*/
	T getValue(T = string)(const string name, T defaultValue = T.init)
	{
		if(hasField(name))
		{
			return fields_[name].to!T;
		}

		return defaultValue;
	}

	/// Useful when you want to use getValue!T to convey the calls meaning better.
	alias as = getValue;

	/**
		Gets the list of file that a TOC file contains.

		Returns:
			A list of files that a TOC file contains.
	*/
	string[] getFilesList()
	{
		return filesList_;
	}

private:
	string[] filesList_;
	string[string] fields_;
}
