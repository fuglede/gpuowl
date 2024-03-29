// Copyright Mihai Preda

#pragma once

#include "Buffer.h"

using double2 = pair<double, double>;
using TrigBuf = Buffer<double2>;
using TrigPtr = shared_ptr<TrigBuf>;

class TrigBufCache {
  const Context* context;
  std::mutex mut;

  std::map<tuple<u32, u32>, TrigPtr::weak_type> small;
  std::map<tuple<u32, u32>, TrigPtr::weak_type> middle;
  std::map<tuple<u32, u32, u32>, TrigPtr::weak_type> bhw;
  std::map<u32, TrigPtr::weak_type> sh;

public:
  TrigBufCache(const Context* context) :
    context{context}
  {}

  ~TrigBufCache();

  TrigPtr smallTrig(u32 W, u32 nW);
  TrigPtr middleTrig(u32 SMALL_H, u32 nH);
  TrigPtr trigBHW(u32 W, u32 hN, u32 BIG_H);
  TrigPtr trig2SH(u32 SMALL_H);
};
