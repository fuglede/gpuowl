// Copyright (C) Mihai Preda

#include "Saver.h"
#include "CycleFile.h"
#include "SaveMan.h"
#include "File.h"

#include <cinttypes>

// E, k, block-size, res64, nErrors, CRC
static constexpr const char *PRP_v12 = "OWL PRP 12 %u %u %u %016" SCNx64 " %u %u\n";

// E, k, CRC
static constexpr const char *LL_v1 = "OWL LL 1 E=%u k=%u CRC=%u\n";

template<typename State>
State load(File&& f, u32 E);

template<> PRPState load<PRPState>(File&& fi, u32 exponent) {
  if (!fi) { return {exponent, 0, 400, 3, makeWords(exponent, 1), 0}; }

  u32 fileE{}, fileK{}, blockSize{}, nErrors{}, crc{};
  u64 res64{};
  vector<u32> check;

  string header = fi.readLine();
  if (sscanf(header.c_str(), PRP_v12, &fileE, &fileK, &blockSize, &res64, &nErrors, &crc) != 6) {
    log("Loading PRP from '%s': bad header '%s'\n", fi.name.c_str(), header.c_str());
    throw "bad savefile";
  }

  assert(exponent == fileE);
  check = fi.readWithCRC<u32>(nWords(exponent), crc);
  return {exponent, fileK, blockSize, res64, check, nErrors};
}

template<> LLState load<LLState>(File&& fi, u32 exponent) {
  if (!fi) { return {exponent, 0, makeWords(exponent, 4)}; }

  u32 fileE{}, fileK{}, crc{};
  vector<u32> data;

  string header = fi.readLine();
  if (sscanf(header.c_str(), LL_v1, &fileE, &fileK, &crc) != 3) {
    log("Loading LL from '%s': bad header '%s'\n", fi.name.c_str(), header.c_str());
    throw "bad savefile";
  }

  assert(exponent == fileE);
  data = fi.readWithCRC<u32>(nWords(exponent), crc);
  return {exponent, fileK, data};
}

void save(const File& fo, const PRPState& state) {
  assert(state.check.size() == nWords(state.exponent));
  if (fo.printf(PRP_v12, state.exponent, state.k, state.blockSize, state.res64, state.nErrors, crc32(state.check)) <= 0) {
      throw(ios_base::failure("can't write header"));
  }
  fo.write(state.check);
}

void save(const File& fo, const LLState& state) {
  assert(state.data.size() == nWords(state.exponent));
  if (fo.printf(LL_v1, state.exponent, state.k, crc32(state.data)) <= 0) {
      throw(ios_base::failure("can't write header"));
  }
  fo.write(state.data);
}

template<typename State>
Saver<State>::Saver(u32 exponent) :
  man{State::KIND, exponent},
  exponent{exponent}
{}

template<typename State>
Saver<State>::~Saver() = default;

template<typename State>
State Saver<State>::load() {
  return ::load<State>(man.readLast(), man.exponent);
}

template<typename State>
void Saver<State>::save(const State& s) {
  ::save(man.write(s.k), s);
}

template<typename State>
void Saver<State>::clear() { man.removeAll(); }

static fs::path unverifiedName(u32 exponent) {
  return fs::current_path() / to_string(exponent) / "unverified.prp";
}

template<>
void Saver<PRPState>::unverifiedSave(const PRPState& s) {
  auto fo = CycleFile{unverifiedName(exponent)};
  ::save(*fo, s);
}

template<>
PRPState Saver<PRPState>::unverifiedLoad() {
  return ::load<PRPState>(File::openRead(unverifiedName(exponent)), exponent);
}

template<typename State>
void Saver<State>::dropUnverified() {
  fs::remove(unverifiedName(exponent));
}

template class Saver<PRPState>;
template class Saver<LLState>;
