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
};

#endif // LOG_H
