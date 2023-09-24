#define LIB_NAME "PartialEase"
#define MODULE_NAME "PartialEase"

#define SINE_TABLE_SIZE 256
#define SINE_TABLE_SIZE1 255
#define PI 3.14159265358979323846
#define IPI 1.57079632679489661923
#define DPI 6.28318530717958647692

#if 2147483647L+1L == -2147483648L 
typedef long i32;
typedef unsigned long u32;
#else
typedef int i32;           /* In 64-bit systems, long may be 64-bit, */
typedef unsigned int u32; /* here we force it to be 32-bit. */
#endif

// include the Defold SDK
#include <dmsdk/sdk.h>
#include <dmsdk/dlib/vmath.h>
#include <dmsdk/script/script.h>
typedef dmVMath::Vector3* v3p;
typedef dmVMath::Vector4* v4p;

static const double sineTable[SINE_TABLE_SIZE] = {
	0.0,
	0.024541228522912288,
	0.049067674327418015,
	0.073564563599667426,
	0.098017140329560604,
	0.1224106751992162,
	0.14673047445536175,
	0.17096188876030122,
	0.19509032201612825,
	0.2191012401568698,
	0.24298017990326387,
	0.26671275747489837,
	0.29028467725446233,
	0.31368174039889152,
	0.33688985339222005,
	0.35989503653498811,
	0.38268343236508978,
	0.40524131400498986,
	0.42755509343028208,
	0.44961132965460654,
	0.47139673682599764,
	0.49289819222978404,
	0.51410274419322166,
	0.53499761988709715,
	0.55557023301960218,
	0.57580819141784534,
	0.59569930449243336,
	0.61523159058062682,
	0.63439328416364549,
	0.65317284295377676,
	0.67155895484701833,
	0.68954054473706683,
	0.70710678118654746,
	0.72424708295146689,
	0.74095112535495911,
	0.75720884650648446,
	0.77301045336273699,
	0.78834642762660623,
	0.80320753148064483,
	0.81758481315158371,
	0.83146961230254524,
	0.84485356524970701,
	0.85772861000027212,
	0.87008699110871135,
	0.88192126434835494,
	0.89322430119551532,
	0.90398929312344334,
	0.91420975570353069,
	0.92387953251128674,
	0.93299279883473885,
	0.94154406518302081,
	0.94952818059303667,
	0.95694033573220894,
	0.96377606579543984,
	0.97003125319454397,
	0.97570213003852857,
	0.98078528040323043,
	0.98527764238894122,
	0.98917650996478101,
	0.99247953459870997,
	0.99518472667219682,
	0.99729045667869021,
	0.99879545620517241,
	0.99969881869620425,
	1.0,
	0.99969881869620425,
	0.99879545620517241,
	0.99729045667869021,
	0.99518472667219693,
	0.99247953459870997,
	0.98917650996478101,
	0.98527764238894122,
	0.98078528040323043,
	0.97570213003852857,
	0.97003125319454397,
	0.96377606579543984,
	0.95694033573220894,
	0.94952818059303667,
	0.94154406518302081,
	0.93299279883473885,
	0.92387953251128674,
	0.91420975570353069,
	0.90398929312344345,
	0.89322430119551521,
	0.88192126434835505,
	0.87008699110871146,
	0.85772861000027212,
	0.84485356524970723,
	0.83146961230254546,
	0.81758481315158371,
	0.80320753148064494,
	0.78834642762660634,
	0.7730104533627371,
	0.75720884650648468,
	0.74095112535495899,
	0.72424708295146689,
	0.70710678118654757,
	0.68954054473706705,
	0.67155895484701855,
	0.65317284295377664,
	0.63439328416364549,
	0.61523159058062693,
	0.59569930449243347,
	0.57580819141784545,
	0.55557023301960218,
	0.53499761988709715,
	0.51410274419322177,
	0.49289819222978415,
	0.47139673682599786,
	0.44961132965460687,
	0.42755509343028203,
	0.40524131400498992,
	0.38268343236508989,
	0.35989503653498833,
	0.33688985339222033,
	0.31368174039889141,
	0.29028467725446239,
	0.26671275747489848,
	0.24298017990326407,
	0.21910124015687005,
	0.19509032201612861,
	0.17096188876030122,
	0.1467304744553618,
	0.12241067519921635,
	0.098017140329560826,
	0.073564563599667732,
	0.049067674327417966,
	0.024541228522912326,
	0.0,
	-0.02454122852291208,
	-0.049067674327417724,
	-0.073564563599667496,
	-0.09801714032956059,
	-0.1224106751992161,
	-0.14673047445536158,
	-0.17096188876030097,
	-0.19509032201612836,
	-0.2191012401568698,
	-0.24298017990326382,
	-0.26671275747489825,
	-0.29028467725446211,
	-0.31368174039889118,
	-0.33688985339222011,
	-0.35989503653498811,
	-0.38268343236508967,
	-0.40524131400498969,
	-0.42755509343028181,
	-0.44961132965460665,
	-0.47139673682599764,
	-0.49289819222978393,
	-0.51410274419322155,
	-0.53499761988709693,
	-0.55557023301960196,
	-0.57580819141784534,
	-0.59569930449243325,
	-0.61523159058062671,
	-0.63439328416364527,
	-0.65317284295377653,
	-0.67155895484701844,
	-0.68954054473706683,
	-0.70710678118654746,
	-0.72424708295146678,
	-0.74095112535495888,
	-0.75720884650648423,
	-0.77301045336273666,
	-0.78834642762660589,
	-0.80320753148064505,
	-0.81758481315158382,
	-0.83146961230254524,
	-0.84485356524970701,
	-0.85772861000027201,
	-0.87008699110871135,
	-0.88192126434835494,
	-0.89322430119551521,
	-0.90398929312344312,
	-0.91420975570353047,
	-0.92387953251128652,
	-0.93299279883473896,
	-0.94154406518302081,
	-0.94952818059303667,
	-0.95694033573220882,
	-0.96377606579543984,
	-0.97003125319454397,
	-0.97570213003852846,
	-0.98078528040323032,
	-0.98527764238894111,
	-0.9891765099647809,
	-0.99247953459871008,
	-0.99518472667219693,
	-0.99729045667869021,
	-0.99879545620517241,
	-0.99969881869620425,
	-1.0,
	-0.99969881869620425,
	-0.99879545620517241,
	-0.99729045667869021,
	-0.99518472667219693,
	-0.99247953459871008,
	-0.9891765099647809,
	-0.98527764238894122,
	-0.98078528040323043,
	-0.97570213003852857,
	-0.97003125319454397,
	-0.96377606579543995,
	-0.95694033573220894,
	-0.94952818059303679,
	-0.94154406518302092,
	-0.93299279883473907,
	-0.92387953251128663,
	-0.91420975570353058,
	-0.90398929312344334,
	-0.89322430119551532,
	-0.88192126434835505,
	-0.87008699110871146,
	-0.85772861000027223,
	-0.84485356524970723,
	-0.83146961230254546,
	-0.81758481315158404,
	-0.80320753148064528,
	-0.78834642762660612,
	-0.77301045336273688,
	-0.75720884650648457,
	-0.74095112535495911,
	-0.724247082951467,
	-0.70710678118654768,
	-0.68954054473706716,
	-0.67155895484701866,
	-0.65317284295377709,
	-0.63439328416364593,
	-0.61523159058062737,
	-0.59569930449243325,
	-0.57580819141784523,
	-0.55557023301960218,
	-0.53499761988709726,
	-0.51410274419322188,
	-0.49289819222978426,
	-0.47139673682599792,
	-0.44961132965460698,
	-0.42755509343028253,
	-0.40524131400499042,
	-0.38268343236509039,
	-0.359895036534988,
	-0.33688985339222,
	-0.31368174039889152,
	-0.2902846772544625,
	-0.26671275747489859,
	-0.24298017990326418,
	-0.21910124015687016,
	-0.19509032201612872,
	-0.17096188876030177,
	-0.14673047445536239,
	-0.12241067519921603,
	-0.098017140329560506,
	-0.073564563599667412,
	-0.049067674327418091,
	-0.024541228522912448
};

// fast_sin by Marc Pony(marc_pony@163.com)
static inline double ArSin(double x)
{
	// int sign = x > 0.0 ? 1 : -1;
	// int si = (int)(x * SINE_TABLE_SIZE / (2.0 * PI) + sign * 0.5);
	int si = (int)(x * SINE_TABLE_SIZE / DPI + 0.5);
	double d = x - si * (DPI / SINE_TABLE_SIZE);
	int ci = si + (SINE_TABLE_SIZE >> 2);
	si &= (SINE_TABLE_SIZE1);
	ci &= (SINE_TABLE_SIZE1);
	return sineTable[si] + (sineTable[ci] - 0.5 * sineTable[si] * d) * d;
}

// fast_cos by Marc Pony(marc_pony@163.com)
static inline double ArCos(double x)
{
	// int sign = x > 0.0 ? 1 : -1;
	// int ci = (int)(x * SINE_TABLE_SIZE / (2.0 * PI) + sign * 0.5);
	int ci = (int)(x * SINE_TABLE_SIZE / DPI + 0.5);
	double d = x - ci * ( DPI / SINE_TABLE_SIZE);
	int si = ci + (SINE_TABLE_SIZE >> 2);
	si &= (SINE_TABLE_SIZE1);
	ci &= (SINE_TABLE_SIZE1);
	return sineTable[si] - (sineTable[ci] + 0.5 * sineTable[si] * d) * d;
}

// Carmack Square Root
static inline float ArSqrtRev(float number)
{
	union {float f;	u32 i;} conv = { .f = number };
	conv.i  = 0x5f375a86 - (conv.i >> 1);
	conv.f *= 1.5F - (number * 0.5F * conv.f * conv.f);
	return conv.f;
}

// fast_sin by Marc Pony(marc_pony@163.com)
// Lua Version
static inline int Sin(lua_State* L)
{
	lua_Number x = lua_tonumber(L, 1);
	double d = x > 0.0 ? 0.5 : -0.5;
	int si = (int)(x * SINE_TABLE_SIZE / DPI + d);
	int ci = si + (SINE_TABLE_SIZE >> 2);
	d = x - si * (DPI / SINE_TABLE_SIZE);
	si &= (SINE_TABLE_SIZE1);
	ci &= (SINE_TABLE_SIZE1);

	DM_LUA_STACK_CHECK(L, 1);
	lua_pushnumber(L, sineTable[si] + (sineTable[ci] - 0.5 * sineTable[si] * d) * d );
	return 1;
}

// fast_cos by Marc Pony(marc_pony@163.com)
// Lua Version
static inline int Cos(lua_State* L)
{
	lua_Number x = lua_tonumber(L, 1);
	double d = x > 0.0 ? 0.5 : -0.5;
	int ci = (int)(x * SINE_TABLE_SIZE / DPI + d);
	int si = ci + (SINE_TABLE_SIZE >> 2);
	d = x - ci * (DPI / SINE_TABLE_SIZE) ;
	si &= (SINE_TABLE_SIZE1);
	ci &= (SINE_TABLE_SIZE1);

	DM_LUA_STACK_CHECK(L, 1);
	lua_pushnumber(L, sineTable[si] - (sineTable[ci] + 0.5 * sineTable[si] * d) * d );
	return 1;
}

// Carmack Square Root
// Lua Version
static inline int Sqrt(lua_State* L)
{
	float number = lua_tonumber(L, 1);
	union {float f;	u32 i;} conv = { .f = number };
	conv.i  = 0x5f375a86 - (conv.i >> 1);
	conv.f *= 1.5F - (number * 0.5F * conv.f * conv.f);

	DM_LUA_STACK_CHECK(L, 1);
	lua_pushnumber(L, 1.0f / conv.f );
	return 1;
}


static inline int EASE(lua_State* L)
{
	// Gets Parameters
	lua_Number ratio = lua_tonumber(L, 1);
	int type = (int)lua_tonumber(L, 2);

	switch(type)
	{
		case 1:
		ratio = lua_Number( 1.0f / ArSqrtRev( 1.0f - float(ratio*ratio) ) );
		ratio = 1.0 - ratio;
		break;
		case 2:
		ratio = 1.0 - ratio;
		ratio = lua_Number( 1.0f / ArSqrtRev( 1.0f - float(ratio*ratio) ) );
		break;
		case 3:
		ratio *= ratio;
		break;
		case 4:
		ratio = 1.0 - ratio;
		ratio = 1.0 - ratio*ratio;
		break;
		case 5:
		ratio *= ratio;
		ratio *= ratio;
		break;
		case 6:
		ratio = 1.0 - ratio;
		ratio *= ratio;
		ratio = 1.0 - ratio*ratio;
		break;
	}

	// Return
	DM_LUA_STACK_CHECK(L, 1);
	lua_pushnumber(L, ratio);
	return 1;
}

static inline int PEASE(lua_State* L)
{
	// Gets Parameters
	lua_Number RX = lua_tonumber(L, 1);
	int ArType = (int)lua_tonumber(L, 2);

	// Decode the ArType
	int ArER = ArType & 0x3ff;	ArType >>= 10;
	int ArIR = ArType & 0x3ff;	ArType >>= 10;
	//if (RX < 0) { RX = 0; }	else if (RX > 1) { RX = 1; }
	//if (ArIR < 0) { ArIR = 0; }	else if (ArIR > 1000) { ArIR = 1000; }
	//if (ArER < 0) { ArER = 0; }	else if (ArER > 1000) { ArER = 1000; }
	//if (ArType < 1) { ArType = 1; }	else if (ArType > 7) { ArType = 7; }

	// Check for Reversed Status
	bool Reversed = false;
	if (ArIR > ArER)
	{
		ArIR ^= ArER;	ArER ^= ArIR;	ArIR ^= ArER;  // Swaps ArIR and ArER Bitwisely.
		Reversed = true;
	}
	RX = ArIR + (ArER - ArIR) * RX;
	RX /= 1000.0;
	
	lua_Number RY = RX;
	// Caculate RX,RY by ArType
	if (Reversed)
	{
		switch (ArType)
		{
			case 1: // xOutQuad
			RX = 1 - RX;	RX = 1 - RX * RX;	break;
			case 2: // xOutCirc
			RX = 1 - RX;	RX = 1.0 / ArSqrtRev( 1 - RX * RX );	break;
			case 3: // xCosine
			RX = ArCos( RX * IPI );	break;
			case 4: // yOutQuad
			RY = 1 - RY;	RY = 1 - RY * RY;	break;
			case 5: // yOutCirc
			RY = 1 - RY;	RY = 1.0 / ArSqrtRev( 1 - RY * RY );	break;
			case 6: // yCosine
			RY = ArCos( RY * IPI );	break;
			case 7: // xyOutQuad
			RX = 1 - RX;	RX = 1 - RX * RX;	RY = RX;	break;
		}
	}
	else
	{
		switch (ArType)
		{
			case 1: // xInQuad
				RX *= RX;	break;
			case 2: // xInCirc
				RX = 1 - RX*RX;	RX = 1 - 1.0 / ArSqrtRev(RX);	break;
			case 3: // xSine
				RX = ArSin( RX * IPI );	break;
			case 4: // yInQuad
				RY *= RY;	break;
			case 5: // yInCirc
				RY = 1 - RY*RY;	RY = 1 - 1.0 / ArSqrtRev(RY);	break;
			case 6: // ySine
				RY = ArSin( RY * IPI );	break;
			case 7: // xyInQuad
				RX *= RX;	RY = RX;	break;
		}
	}
	
	// Return
	DM_LUA_STACK_CHECK(L, 3);
	lua_pushnumber(L, RX);
	lua_pushnumber(L, RY);
	lua_pushboolean(L, Reversed);
	return 3;
}

static inline int _PHint(lua_State* L)
{
	v4p Hint = dmScript::ToVector4(L, 1);
	Hint->setX( Hint->getX()*112.5f );
	Hint->setY( Hint->getY()*112.5f + 90.0f);
	Hint->setW( 0.0f );
	return 0;
}

static inline int _PWish(lua_State* L)
{
	v3p Hint = dmScript::ToVector3(L, 1);
	float x = Hint->getX()*112.5f;
	float y = Hint->getY()*112.5f + 90.0f;
	float z = Hint->getZ();
	z = z - int(z);
	
	Hint->setX(x);
	Hint->setY(y);
	Hint->setZ(z);

	DM_LUA_STACK_CHECK(L, 2);
	lua_pushnumber( L, lua_Number(x) );
	lua_pushnumber( L, lua_Number(y) );
	
	return 2;
}

static inline int _PHint_hasCam(lua_State* L)
{
	v4p Hint = dmScript::ToVector4(L, 1);
	lua_Number rotrad = lua_tonumber(L, 4);
	lua_Number posx = Hint->getX();
	lua_Number posy = Hint->getY();
	//lua_Number xscale = lua_tonumber(L, 2);
	//lua_Number yscale = lua_tonumber(L, 3);
	//lua_Number xdelta = lua_tonumber(L, 5);
	//lua_Number ydelta = lua_tonumber(L, 6);
	if ( rotrad>-0.01 && rotrad<0.01 )
	{
		posx = 8.0 + (posx - 8.0) * lua_tonumber(L, 2) + lua_tonumber(L, 5);
		posy = 4.0 + (posy - 4.0) * lua_tonumber(L, 3) + lua_tonumber(L, 6);
	}
	else
	{
		lua_Number s = rotrad>0.0 ? ArSin(rotrad) : -ArSin(-rotrad);
		lua_Number c = rotrad>0.0 ? ArCos(rotrad) : ArCos(-rotrad);
		lua_Number dx = (posx - 8.0) * lua_tonumber(L, 2);
		lua_Number dy = (posy - 4.0) * lua_tonumber(L, 3);
		posx = 8.0 + dx*c - dy*s + lua_tonumber(L, 5);
		posy = 4.0 + dx*s + dy*c + lua_tonumber(L, 6);
	}
	Hint->setX( float(posx)*112.5f );
	Hint->setY( float(posy)*112.5f + 90.0f);
	Hint->setW( 0.0f );
	return 0;
}

static inline int _PWish_hasCam(lua_State* L)
{
	v3p Hint = dmScript::ToVector3(L, 1);
	lua_Number rotrad = lua_tonumber(L, 4);
	lua_Number posx = Hint->getX();
	lua_Number posy = Hint->getY();
	//lua_Number xscale = lua_tonumber(L, 2);
	//lua_Number yscale = lua_tonumber(L, 3);
	//lua_Number xdelta = lua_tonumber(L, 5);
	//lua_Number ydelta = lua_tonumber(L, 6);
	if ( rotrad>-0.01 && rotrad<0.01 )
	{
		posx = 8.0 + (posx - 8.0) * lua_tonumber(L, 2) + lua_tonumber(L, 5);
		posy = 4.0 + (posy - 4.0) * lua_tonumber(L, 3) + lua_tonumber(L, 6);
	}
	else
	{
		lua_Number s = rotrad>0.0 ? ArSin(rotrad) : -ArSin(-rotrad);
		lua_Number c = rotrad>0.0 ? ArCos(rotrad) : ArCos(-rotrad);
		lua_Number dx = (posx - 8.0) * lua_tonumber(L, 2);
		lua_Number dy = (posy - 4.0) * lua_tonumber(L, 3);
		posx = 8.0 + dx*c - dy*s + lua_tonumber(L, 5);
		posy = 4.0 + dx*s + dy*c + lua_tonumber(L, 6);
	}

	float x = float(posx)*112.5f;
	float y = float(posy)*112.5f + 90.0f;
	float z = Hint->getZ();
	z = z - int(z);
	
	Hint->setX(x);
	Hint->setY(y);
	Hint->setZ(z);

	DM_LUA_STACK_CHECK(L, 2);
	lua_pushnumber( L, lua_Number(x) );
	lua_pushnumber( L, lua_Number(y) );
	
	return 2;
}

static inline int _IpWish(lua_State* L)
{
	float progress = lua_tonumber(L, 1);
	int poll_progress = int( lua_tonumber(L, 2) );
	int current_wish_len = int( lua_tonumber(L, 3) );
	v4p before = dmScript::ToVector4(L, 4);
	v4p after = dmScript::ToVector4(L, 5);
	v4p to = dmScript::ToVector4(L, 6);

	float current_x0 = before->getX();
	float current_y0 = before->getY();
	float current_dx = after->getX() - current_x0;
	float current_dy = after->getY() - current_y0;

	float current_t0 = before->getZ();
	int current_type = int( before->getW() );
	float ratiox = (progress - current_t0) / (after->getZ() - current_t0);

	if (poll_progress == 3)
	{
		if (ratiox <= 0.237f)
		{
			to->setW( 2.0f + ratiox );
		}
		else
		{
			to->setW( 0.0f );
		}
	}
	else if (poll_progress == current_wish_len - 1  &&  ratiox >= 0.763f)
	{
		to->setW( -2.0f - ratiox );
	}
	else
	{
		to->setW( 0.0f );
	}
	
	if (current_type > 1048575)
	{
		// Gets Parameters: ratiox, ratioy, current_type
		// Decode the Type
		int ArER = current_type & 0x3ff;	current_type >>= 10;
		int ArIR = current_type & 0x3ff;	current_type >>= 10;

		// Check for Reversed Status
		bool Reversed = false;
		if (ArIR > ArER)
		{
			ArIR ^= ArER;	ArER ^= ArIR;	ArIR ^= ArER;  // Swaps ArIR and ArER Bitwisely.
			Reversed = true;
		}
		ratiox = ( ArIR + (ArER - ArIR) * ratiox ) / 1000.0;
		float ratioy = ratiox;

		// Caculation
		if (Reversed)
		{
			switch (current_type)
			{
				case 1: // xOutQuad
				ratiox = 1 - ratiox;	ratiox = 1 - ratiox * ratiox;	break;
				case 2: // xOutCirc
				ratiox = 1 - ratiox;	ratiox = 1.0 / ArSqrtRev( 1 - ratiox * ratiox );	break;
				case 3: // xCosine
				ratiox = ArCos( ratiox * IPI );	break;
				case 4: // yOutQuad
				ratioy = 1 - ratioy;	ratioy = 1 - ratioy * ratioy;	break;
				case 5: // yOutCirc
				ratioy = 1 - ratioy;	ratioy = 1.0 / ArSqrtRev( 1 - ratioy * ratioy );	break;
				case 6: // yCosine
				ratioy = ArCos( ratioy * IPI );	break;
				case 7: // xyOutQuad
				ratiox = 1 - ratiox;	ratiox = 1 - ratiox * ratiox;	ratioy = ratiox;	break;
			}
		}
		else
		{
			switch (current_type)
			{
				case 1: // xInQuad
				ratiox *= ratiox;	break;
				case 2: // xInCirc
				ratiox = 1 - ratiox*ratiox;	ratiox = 1 - 1.0 / ArSqrtRev(ratiox);	break;
				case 3: // xSine
				ratiox = ArSin( ratiox * IPI );	break;
				case 4: // yInQuad
				ratioy *= ratioy;	break;
				case 5: // yInCirc
				ratioy = 1 - ratioy*ratioy;	ratioy = 1 - 1.0 / ArSqrtRev(ratioy);	break;
				case 6: // ySine
				ratioy = ArSin( ratioy * IPI );	break;
				case 7: // xyInQuad
				ratiox *= ratiox;	ratioy = ratiox;	break;
			}
		}

		// Setting Values
		to->setX( current_x0 + current_dx * ratiox );
		to->setY( current_y0 + current_dy * ratioy );
	}
	else if (current_type)
	{
		float ratioy = ratiox;
		switch ( current_type/10 )
		{
			case 1:
			ratiox = 1.0f / ArSqrtRev( 1.0f - ratiox*ratiox );
			ratiox = 1.0f - ratiox;
			break;

			case 2:
			ratiox = 1.0f - ratiox;
			ratiox = 1.0f / ArSqrtRev( 1.0f - ratiox*ratiox );
			break;

			case 3:
			ratiox *= ratiox;
			break;

			case 4:
			ratiox = 1.0f - ratiox;
			ratiox = 1.0f - ratiox * ratiox;
			break;

			case 5:
			ratiox *= ratiox;
			ratiox *= ratiox;
			break;

			case 6:
			ratiox = 1.0f - ratiox;
			ratiox *= ratiox;
			ratiox = 1.0f - ratiox * ratiox;
			break;
		}
		to->setX( current_x0 + current_dx * ratiox );
		switch ( current_type%10 )
		{
			case 1:
			ratioy = 1.0f / ArSqrtRev( 1.0f - ratioy*ratioy );
			ratioy = 1.0f - ratioy;
			break;

			case 2:
			ratioy = 1.0f - ratioy;
			ratioy = 1.0f / ArSqrtRev( 1.0f - ratioy*ratioy );
			break;

			case 3:
			ratioy *= ratioy;
			break;

			case 4:
			ratioy = 1.0f - ratioy;
			ratioy = 1.0f - ratioy * ratioy;
			break;

			case 5:
			ratioy *= ratioy;
			ratioy *= ratioy;
			break;

			case 6:
			ratioy = 1.0f - ratioy;
			ratioy *= ratioy;
			ratioy = 1.0f - ratioy * ratioy;
			break;
		}
		to->setY( current_y0 + current_dy * ratioy );
	}
	else
	{
		to->setX( current_x0 + current_dx * ratiox );
		to->setY( current_y0 + current_dy * ratiox );
	}

	DM_LUA_STACK_CHECK(L, 1);
	lua_pushboolean(L, true);
	return 1;
}

static inline int _IpCam(lua_State* L)
{
	float progress = float( lua_tonumber(L, 1) );
	v3p before = dmScript::ToVector3(L, 2);
	v3p after = dmScript::ToVector3(L, 3);

	float t0 = before->getX();
	float v0 = before->getY();
	int type = int(before->getZ());
	float dt = after->getX() - t0;
	float dv = after->getY() - v0;
	progress = (progress-t0) / dt;

	switch(type)
	{
		case 1:
		progress = 1.0f / ArSqrtRev( 1.0f - progress*progress );
		progress = 1.0f - progress;
		break;
		
		case 2:
		progress = 1.0f - progress;
		progress = 1.0f / ArSqrtRev( 1.0f - progress*progress );
		break;
		
		case 3:
		progress *= progress;
		break;
		
		case 4:
		progress = 1.0f - progress;
		progress = 1.0f - progress * progress;
		break;
		
		case 5:
		progress *= progress;
		progress *= progress;
		break;
		
		case 6:
		progress = 1.0f - progress;
		progress *= progress;
		progress = 1.0f - progress * progress;
		break;
	}
	
	DM_LUA_STACK_CHECK(L, 1);
	lua_pushnumber(L, lua_Number(v0+dv*progress) );
	return 1;
}

static inline int V3V4Apply(lua_State* L)
{
	v3p a = dmScript::ToVector3(L, 1);
	v4p b = dmScript::ToVector4(L, 2);

	a->setX( b->getX() );
	a->setY( b->getY() );
	a->setZ( b->getZ() );
	
	DM_LUA_STACK_CHECK(L, 1);
	lua_pushnumber(L, lua_Number( b->getW() ) );
	return 1;
}

static inline int Ctint(lua_State* L)
{
	lua_Number ctint = lua_tonumber(L, 1);
	lua_Number tintw = 1.0;
	lua_Number expand_wish = 1.0;
	
	if (ctint >= 2.0)
	{
		tintw = ctint - 2.0;
		tintw = 1 - tintw / 0.237;
		expand_wish = 1 + tintw * tintw / 2;
		tintw = 1 - tintw * tintw * tintw;
	}
	else if (ctint <= -2.0)
	{
		tintw = ctint + 3.0;
		tintw /= 0.237;
		tintw = tintw * tintw * tintw;
	}
	
	DM_LUA_STACK_CHECK(L, 2);
	lua_pushnumber(L, tintw);
	lua_pushnumber(L, expand_wish);
	return 2;
}

static inline int HAPos(lua_State* L)
{
	v3p vecsi = dmScript::ToVector3(L, 1);
	v4p chint = dmScript::ToVector4(L, 2);
	float viz = float( lua_tonumber(L, 3) );

	vecsi->setX( chint->getX() );
	vecsi->setY( chint->getY() );
	vecsi->setZ( viz );

	DM_LUA_STACK_CHECK(L, 1);
	dmScript::PushVector3(L, *vecsi);
	return 1;
}

static inline int GetLVL(lua_State* L)
{
	v4p cur = dmScript::ToVector4(L, 1);
	float _x = cur->getX();
	float _y = cur->getY();

	DM_LUA_STACK_CHECK(L, 3);
	lua_pushnumber(L, (lua_Number)_x);
	lua_pushnumber(L, (lua_Number)_y);
	lua_pushnumber(L, (int)(_x*109) + (int)(_y*113) );
	return 3;
}


// Functions exposed to Lua
static const luaL_reg Module_methods[] =
{
	{"EASE", EASE},
	{"PEASE", PEASE},
	{"Sin", Sin},
	{"Cos", Cos},
	{"Sqrt", Sqrt},
	{"_IpCam", _IpCam},
	{"_IpWish", _IpWish},
	{"_PHint", _PHint},
	{"_PHint_hasCam", _PHint_hasCam},
	{"_PWish", _PWish},
	{"_PWish_hasCam", _PWish_hasCam},
	{"V3V4Apply", V3V4Apply},
	{"Ctint", Ctint},
	{"HAPos", HAPos},
	{"GetLVL", GetLVL},
	{0, 0}
};

inline dmExtension::Result AcAppOK(dmExtension::AppParams* params) {return dmExtension::RESULT_OK;}
inline dmExtension::Result AcOK(dmExtension::Params* params) {return dmExtension::RESULT_OK;}
inline dmExtension::Result Initialize(dmExtension::Params* params)
{
	luaL_register(params->m_L, MODULE_NAME, Module_methods);
	lua_pop(params->m_L, 1);
	return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(PartialEase, LIB_NAME, AcAppOK, AcAppOK, Initialize, 0, 0, AcOK)