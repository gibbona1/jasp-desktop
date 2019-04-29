#define ENUM_DECLARATION_CPP
#include "log.h"

#include <iostream>

#include "boost/iostreams/stream.hpp"
#include "boost/iostreams/device/null.hpp"
#include "boost/nowide/fstream.hpp"

typedef boost::nowide::ofstream bofstream; //Use this to work around problems on Windows with utf8 conversion

//Not defined in class because I want the header to be as light as possible:
static logType		_default		= logType::cout;
static logType		_where			= logType::cout;
static std::string	_logFilePath	= "";
static bofstream	_logFile		= bofstream();
static logError		_logError		= logError::noProblem;

std::ostream & Log::log()
{
	switch(_where)
	{
	case logType::cout:		return std::cout;
	case logType::null:
	{
		static boost::iostreams::stream<boost::iostreams::null_sink> nullstream((boost::iostreams::null_sink())); //https://stackoverflow.com/questions/8243743/is-there-a-null-stdostream-implementation-in-c-or-libraries
		return nullstream;
	}
	case logType::file:		return _logFile;
	};
}


void Log::setDefaultDestination(logType newDestination)
{
	if(newDestination != logType::file) //It doesnt make any sense to have the default non-file logType be file...
		_default = newDestination;
}

void Log::setLoggingToFile(bool logToFile)
{
	_where = logToFile ? logType::file : _default;

	if(logToFile)				openLogFile();
	else if(_logFile.is_open())	_logFile.close();
}

void Log::setLogFileName(const std::string & filePath)
{
	_logFilePath = filePath;

	if(_where == logType::file)
		openLogFile();
}

void Log::openLogFile()
{
	if(_logFilePath == "")
	{
		_logError = logError::filePathNotSet;
		_where    = _default;
		return;
	}

	_logFile.open(_logFilePath, std::ios_base::app | std::ios_base::out);

	if(_logFile.fail())
	{
		_logError	= logError::fileNotOpen;
		_where		= _default;
		return;
	}

	_logError = logError::noProblem;
}
