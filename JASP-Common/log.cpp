#define ENUM_DECLARATION_CPP
#include "log.h"
#include "boost/nowide/cstdio.hpp"
#include <chrono>
#ifdef WIN32
#include <io.h>
#endif

std::string Log::logFileNameBase	= "";

logType		Log::_where				= logType::cout;
std::string	Log::_logFilePath		= "";
logError	Log::_logError			= logError::noProblem;
int			Log::_stdoutfd			= -1;

logType		Log::_default			=
#ifdef JASP_DEBUG
	logType::cout;
#else
	logType::null;
#endif

const char*	Log::_nullStream =
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

void Log::setWhere(logType where)
{
	if(where == _where)
		return;

	_where = where;

	redirectStdOut();
}

void Log::setLoggingToFile(bool logToFile)
{
	setWhere(logToFile ? logType::file : _default);
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
	if(_stdoutfd != -1) //Because then it is inited?
		return;

#ifdef WIN32
	_stdoutfd = _dup(fileno(stdout)); //Also maybe should close this after closing program? dup opens new FILE*
	_dup2(fileno(stdout), fileno(stderr));
#else
	_stdoutfd = dup(fileno(stdout)); //Also maybe should close this after closing program? dup opens new FILE*
	dup2(fileno(stdout), fileno(stderr));
#endif

	_where = _default;
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
#ifdef WIN32
		_dup2(_stdoutfd, fileno(stdout));
#else
		 dup2(_stdoutfd, fileno(stdout));
#endif

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

Json::Value	Log::createLogCfgMsg()
{
	Json::Value json	= Json::objectValue;

	json["where"]		= logTypeToString(_where);

	return json;
}

void Log::parseLogCfgMsg(const Json::Value & json)
{
	setWhere(logTypeFromString(json["where"].asString()));
}
