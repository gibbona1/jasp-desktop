#ifndef LOG_H
#define LOG_H

#include <ostream>
#include "enumutilities.h"

DECLARE_ENUM(logType,  cout, file, null);
DECLARE_ENUM(logError, noProblem, fileNotOpen, filePathNotSet);

class Log
{
public:
	static std::ostream & log();

	static void setDefaultDestination(logType newDestination);
	static void setLoggingToFile(bool logToFile);
	static void setLogFileName(const std::string & filePath);

private:
				Log() {}
	static void openLogFile();
};

#endif // LOG_H
