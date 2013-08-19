#include "ttestonesample.h"

#include "options.h"
#include "option.h"
#include "options/optionfields.h"
#include "options/optionboolean.h"
#include "options/optioninteger.h"
#include "options/optionintegerarray.h"
#include "options/optionlist.h"
#include "options/optionnumber.h"

#include "rinterface.h"

using namespace Json;
using namespace analyses;

TTestOneSample::TTestOneSample(int id)
	: Analysis(id, "TTestOneSample")
{
}

Options *TTestOneSample::createDefaultOptions()
{
	Options *options = new Options();

	options->add(new OptionFields("variables"));
	options->add(new OptionNumber("testValue", 0));
	options->add(new OptionList("tails", "twoTailed"));

	options->add(new OptionBoolean("meanDifference"));
	options->add(new OptionBoolean("confidenceInterval"));
	options->add(new OptionNumber("confidenceIntervalInterval", .95, 0, 1, 3));
	options->add(new OptionBoolean("descriptives"));

	options->add(new OptionList("missingValues", "excludeAnalysisByAnalysis"));

	return options;
}
