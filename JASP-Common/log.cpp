#define ENUM_DECLARATION_CPP
#include "log.h"
#include "boost/nowide/cstdio.hpp"
#include <chrono>

//Not defined in class because I want the header to be as light as possible:
static logType		_default		= logType::cout;
static logType		_where			= logType::cout;
static std::string	_logFilePath	= "";
static logError		_logError		= logError::noProblem;
static int			_stdoutfd		= -1;

static const char*	_nullStream =
#ifdef WIN32
	"nul:";
#else
	"/dev/null";
#endif

void Log::setDefaultDestination(logType newDestination)
{
	if(newDestination == logType::file) //It doesnt make any sense to have the default non-file logType be file...
		newDestination = logType::cout;

	if(_default == newDestination)
		return;

	bool setNewDefaultToWhere = _where == _default;

	_default = newDestination;

	if(setNewDefaultToWhere)
		redirectStdOut();
}

void Log::setLoggingToFile(bool logToFile)
{
	logType where = logToFile ? logType::file : _default;

	if(where == _where)
		return;

	_where = where;

	redirectStdOut();
}

void Log::setLogFileName(const std::string & filePath)
{
	if(_logFilePath == filePath)
		return;

	_logFilePath = filePath;

	if(_where == logType::file)
		redirectStdOut();
}

void Log::initRedirects()
{
	if(_stdoutfd != -1)
		return;

	_stdoutfd = dup(fileno(stdout)); //Probably useless on Windows. //Also maybe should close this after closing program? dup opens new FILE*

#ifdef WIN32
	_dup2(fileno(stdout), fileno(stderr));
#else
	dup2(fileno(stdout), fileno(stderr));
#endif
}

void Log::redirectStdOut()
{


	switch(_where)
	{
	case logType::null:
		if (!freopen(_nullStream, "a", stdout))
			throw std::runtime_error("Could not redirect stdout to null");

		break;

	case logType::cout:
		dup2(_stdoutfd, fileno(stdout));
		break;

	case logType::file:
	{
		if(_logFilePath == "")
		{
			_logError = logError::filePathNotSet;
			_where    = _default;
			redirectStdOut();
			return;
		}

		if(!freopen(_logFilePath.c_str(), "a", stdout))
		{
			_logError	= logError::fileNotOpen;
			_where		= _default;
			redirectStdOut();
			return;
		}
		break;
	};
	}

	_logError = logError::noProblem;
}
