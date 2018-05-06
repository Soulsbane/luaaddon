/**
	Provides functionality for parsing TOC(Table of Contents) files like those found in World of Warcraft.
*/
module luaaddon.tocparser;

import std.stdio;
import std.file;
import std.string;
import std.algorithm : splitter;
import std.conv : to;
import std.array;

import dstringutils.utils;

struct DefaultNamedMethods
{
	string author;
	string description;
	string name;
}

/// Parses TOC(Table of Contents) files like those found in World of Warcraft.
/// Note that in order to use this without passing a struct you must initialize it like so: TocParser!() parser;
struct TocParser(NamedMethods = DefaultNamedMethods)
{
	mixin(generateNamedMethods!NamedMethods);

	/**
		Processes text containing the TOC format.

		Params:
			text = The text to be processed.
	*/
	void processText(const string text) pure @safe
	{
		auto lines = text.lineSplitter();

		foreach(line; lines)
		{
			line = strip(line);

			if(line.startsWith("##"))
			{
				auto values = line.chompPrefix("##").strip.splitter(":").array;

				if(values.length == 2)
				{
					immutable string key = values[0].strip;
					immutable string value = values[1].strip;

					fields_[key] = value;
				}
			}
			else if(line.empty || line.startsWith("#")) // Line is a comment or empty.
			{
				continue;
			}
			else // Line is a file name
			{
				//if(line.length != line.countChars(" ")) // Make sure line isn't only whitespace
				if(!line.hasOnlySpaces()) // Make sure line isn't only whitespace
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
	bool loadString(const string text) pure @safe
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
	bool hasField(const string name) pure nothrow @safe
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
	T getValue(T = string)(const string name, T defaultValue = T.init) pure @safe
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
	string[] getFilesList() pure @safe
	{
		return filesList_;
	}

	/**
		Returns a fields value.

		Params:
			name = Name of the field to return.

		Returns:
			The value of the specified field.
	*/
	string opIndex(const string name)
	{
		return getValue(name, string.init);
	}

private:
	string[] filesList_;
	string[string] fields_;
}

/*
	This function generates the following code based on the passed struct.

	struct Methods
	{
		string author;
	}

	string getAuthor(const string name, string defaultValue = string.init) pure @safe
	{
		return getValue!string(name, defaultValue);
	}
*/
private string generateNamedMethods(T)()
{
	string code;

	foreach (i, memberType; typeof(T.tupleof))
	{
		immutable string memType = memberType.stringof;
		immutable string memName = T.tupleof[i].stringof;
		immutable string memNameCapitalized = memName[0].toUpper.to!string ~ memName[1..$];

		code ~= format(q{
			%s get%s(%s defaultValue = %s.init) pure @safe
			{
				return getValue!%s("%s", defaultValue);
			}
		}, memType, memNameCapitalized, memType, memType, memType, memNameCapitalized);
	}

	return code;
}

unittest
{
	/*immutable string tocData = q{
		##Author: Alan
		##Description: A short description.
		##Number: 100
		file.d
		app.d
		app.lua
	};

	TocParser!() parser;

	parser.loadString(tocData);
	assert(parser.hasField("Author") == true);
	assert(parser.hasField("NotAuthor") == false);
	assert(parser.getValue("Author") == "Alan");
	assert(parser.getValue("Animal", "Cat") == "Cat");
	assert(parser.as!uint("Number") == 100);
	assert(parser.getFilesList().length == 3);
	assert(parser["Author"] == "Alan");

	immutable string empty;
	TocParser!() emptyParser;

	assert(emptyParser.loadString(empty) == false);

	struct Methods
	{
		string author;
		uint number;
		uint count;
	}

	TocParser!Methods parserWithMethods;

	parserWithMethods.loadString(tocData);
	assert(parserWithMethods.getAuthor() == "Alan");
	assert(parserWithMethods.getNumber() == 100);
	assert(parserWithMethods.getCount(777) == 777);
	*/
}
