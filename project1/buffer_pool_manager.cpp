//===----------------------------------------------------------------------===//
//
//                         BusTub
//
// buffer_pool_manager.cpp
//
// Identification: src/buffer/buffer_pool_manager.cpp
//
// Copyright (c) 2015-2019, Carnegie Mellon University Database Group
//
//===----------------------------------------------------------------------===//

#include "buffer/buffer_pool_manager.h"

#include <list>
#include <unordered_map>

namespace bustub {

BufferPoolManager::BufferPoolManager(size_t pool_size, DiskManager *disk_manager, LogManager *log_manager)
    : pool_size_(pool_size), disk_manager_(disk_manager), log_manager_(log_manager) {
  // We allocate a consecutive memory space for the buffer pool.
  pages_ = new Page[pool_size_];
  replacer_ = new ClockReplacer(pool_size);

  // Initially, every page is in the free list.
  for (size_t i = 0; i < pool_size_; ++i) {
    free_list_.emplace_back(static_cast<int>(i));
  }
}

BufferPoolManager::~BufferPoolManager() {
  delete[] pages_;
  delete replacer_;
}

Page *BufferPoolManager::FetchPageImpl(page_id_t page_id) {
  // 1.     Search the victim table for the requested victim (P).
  // 1.1    If P exists, pin it and return it immediately.
  // 1.2    If P does not exist, find a replacement victim (victim_frame_id) from either the free list or the
  // replacer.
  //        Note that pages are always found from the free list first.
  // 2.     If victim_frame_id is dirty, write it back to the disk.
  // 3.     Delete victim_frame_id from the victim table and insert P.
  // 4.     Update P's metadata, read in the victim content from disk, and then return a pointer to P.
  if (page_table_.find(page_id) != page_table_.end()) {
    auto frame_id = page_table_[page_id];
    pages_[frame_id].pin_count_++;
    replacer_->Pin(frame_id);
    return pages_ + frame_id;
  }

  int victim_frame_id;
  if (!free_list_.empty()) {
    victim_frame_id = free_list_.front();
    free_list_.pop_front();
  } else {
    frame_id_t id;
    if (!replacer_->Victim(&id)) {
      return nullptr;
    }
    victim_frame_id = id;
  }

  auto &victim = pages_[victim_frame_id];
  FlushPageImpl(victim.page_id_);

  page_table_.erase(victim.page_id_);
  page_table_.insert(std::pair(page_id, victim_frame_id));

  victim.pin_count_ = 1;
  victim.page_id_ = page_id;
  victim.is_dirty_ = false;
  disk_manager_->ReadPage(page_id, victim.GetData());

  return pages_ + victim_frame_id;
}

bool BufferPoolManager::UnpinPageImpl(page_id_t page_id, bool is_dirty) {
  if (page_table_.find(page_id) == page_table_.end()) {
    return false;
  }
  auto &page = pages_[page_table_[page_id]];
  page.is_dirty_ = is_dirty;
  if (--page.pin_count_ <= 0) {
    replacer_->Unpin(page_table_[page_id]);
  }

  return true;
}

bool BufferPoolManager::FlushPageImpl(page_id_t page_id) {
  // Make sure you call DiskManager::WritePage!
  if (page_table_.find(page_id) == page_table_.end() || pages_[page_table_[page_id]].GetPageId() == INVALID_PAGE_ID) {
    return false;
  }

  Page &page = pages_[page_table_[page_id]];
  if (page.IsDirty()) {
    disk_manager_->WritePage(page_id, page.GetData());
    page.is_dirty_ = false;
  }

  return true;
}

Page *BufferPoolManager::NewPageImpl(page_id_t *page_id) {
  // 0.   Make sure you call DiskManager::AllocatePage!
  // 1.   If all the pages in the buffer pool are pinned, return nullptr.
  // 2.   Pick a victim_frame victim victim_frame from either the free list or the replacer. Always pick from the free
  // list first.
  // 3.   Update victim_frame's metadata, zero out memory and add victim_frame to the victim table.
  // 4.   Set the victim ID output parameter. Return a pointer to victim_frame.
  int victim_frame;
  if (!free_list_.empty()) {
    victim_frame = free_list_.front();
    free_list_.pop_front();
  } else {
    frame_id_t id;
    if (!replacer_->Victim(&id)) {
      return nullptr;
    }
    victim_frame = id;
  }
  auto &victim = pages_[victim_frame];
  FlushPageImpl(victim.page_id_);
  auto Pid = disk_manager_->AllocatePage();

  page_table_.erase(victim.page_id_);
  page_table_.insert(std::pair(Pid, victim_frame));

  victim.page_id_ = Pid;
  victim.is_dirty_ = false;
  victim.pin_count_ = 1;
  victim.ResetMemory();

  *page_id = Pid;
  return pages_ + victim_frame;
}

bool BufferPoolManager::DeletePageImpl(page_id_t page_id) {
  // 0.   Make sure you call DiskManager::DeallocatePage!
  // 1.   Search the page table for the requested page (P).
  // 1.   If P does not exist, return true.
  // 2.   If P exists, but has a non-zero pin-count, return false. Someone is using the page.
  // 3.   Otherwise, P can be deleted. Remove P from the page table, reset its metadata and return it to the free list.
  disk_manager_->DeallocatePage(page_id);
  if (page_table_.find(page_id) == page_table_.end()) {
    return true;
  }

  frame_id_t frame_id = page_table_[page_id];
  auto &P = pages_[frame_id];
  if (P.pin_count_ > 0) {
    return false;
  }

  replacer_->Unpin(frame_id);
  page_table_.erase(page_id);
  P.is_dirty_ = false;
  P.ResetMemory();
  free_list_.push_back(frame_id);

  return true;
}

void BufferPoolManager::FlushAllPagesImpl() {
  // You can do it!
  for (const auto &e : page_table_) {
    FlushPageImpl(e.first);
  }
}

}  // namespace bustub
