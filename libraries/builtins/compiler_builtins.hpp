#pragma once
#include <cstdint>
#include <softfloat.hpp>

extern "C" {
   __int128 ___fixdfti(uint64_t);
   __int128 ___fixsfti(uint32_t);
   __int128 ___fixtfti( float128_t);
   unsigned __int128 ___fixunsdfti(uint64_t);
   unsigned __int128 ___fixunssfti(uint32_t);
   unsigned __int128 ___fixunstfti(float128_t);
   double ___floattidf(__int128);
   double ___floatuntidf(unsigned __int128);
   __int128 __divti3(__int128,__int128);
   __int128 __modti3(__int128,__int128);
   unsigned __int128 __udivti3(unsigned __int128, unsigned __int128);
   unsigned __int128 __umodti3(unsigned __int128, unsigned __int128);
}
