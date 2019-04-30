#ifndef LOG_H
#define LOG_H

#include <string>
#include "enumutilities.h"

DECLARE_ENUM(logType,  cout, file, null);
DECLARE_ENUM(logError, noProblem, fileNotOpen, filePathNotSet);

class Log
{
public:
	static void setDefaultDestination(logType newDestination);
	static void setLoggingToFile(bool logToFile);
	static void setLogFileName(const std::string & filePath);
	static void initRedirects();

private:
				Log() { }
	static void redirectStdOut();

	static logType		_default;
	static logType		_where;
	static std::string	_logFilePath;
	static logError		_logError;
	static int			_stdoutfd;

	static const char*	_nullStream;
};

#endif // LOG_H
