#ifndef ANOVAONEWAY_H
#define ANOVAONEWAY_H

#include "analysis.h"

#include "../JASP-Common/lib_json/json.h"

namespace analyses
{

class AnovaOneWay : public Analysis
{
public:
	AnovaOneWay(int id);

protected:

	virtual Options *createDefaultOptions() OVERRIDE;

};

}

#endif // ANOVAONEWAY_H
