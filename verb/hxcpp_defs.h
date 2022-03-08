#pragma once
#ifdef WIN32
	#define HX_WINDOWS
	#ifdef _WIN64
		#define HXCPP_M64
	#endif
#endif
#ifdef NDEBUG
	#define NO_HXCPP_DEBUG
#else
#endif
#include <HxcppConfig.h>
#ifndef HXCPP_H
#include <hxcpp.h>
#endif


static inline void HaxeInitGC()
{
	HX_TOP_OF_STACK
    hx::Boot();
    __boot_all();
}
