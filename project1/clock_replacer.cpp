//===----------------------------------------------------------------------===//
//
//                         BusTub
//
// clock_replacer.cpp
//
// Identification: src/buffer/clock_replacer.cpp
//
// Copyright (c) 2015-2019, Carnegie Mellon University Database Group
//
//===----------------------------------------------------------------------===//

#include "buffer/clock_replacer.h"

namespace bustub {

ClockReplacer::ClockReplacer(size_t num_pages) {}

ClockReplacer::~ClockReplacer() = default;

bool ClockReplacer::Victim(frame_id_t *frame_id) {
  if (clock.empty()) {
    return false;
  }

  for (;;) {
    if (pos == clock.end()) {
      pos = clock.begin();
    }

    if (!pos->second) {
      *frame_id = pos->first;
      pos++;
      auto x = pos;
      clock.erase(--x);
      return true;
    }

    pos->second = false;
    pos++;
  }
}

void ClockReplacer::Pin(frame_id_t frame_id) {
  for (auto i = clock.cbegin(); i != clock.cend(); i++) {
    if (i->first == frame_id) {
      if (i == pos) {
        pos++;
      }
      clock.erase(i);
      return;
    }
  }
}

void ClockReplacer::Unpin(frame_id_t frame_id) {
  for (const auto &i : clock) {
    if (i.first == frame_id) {
      return;
    }
  }

  clock.insert(pos, std::pair(frame_id, false));
}

size_t ClockReplacer::Size() { return clock.size(); }

}  // namespace bustub
