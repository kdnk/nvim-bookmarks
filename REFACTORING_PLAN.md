# Refactoring Plan

## 1. Optimize Sync Performance (`sync.lua` / `bookmark.lua`)

**Problem:**
`sync.extmarks_to_bookmarks` is triggered on every `TextChanged` event. It currently calls `bookmark.list()`, which performs expensive operations:
- Creating a deep copy of all bookmarks.
- Grouping bookmarks by filename.
- Sorting bookmarks.
- Iterating through *all* bookmarks to find those belonging to the current buffer (O(N)).

**Solution:**
- Add a `get_by_bufnr(bufnr)` method to `bookmark.lua` to efficiently retrieve only the bookmarks for a specific buffer.
- Refactor `sync.lua` to use `get_by_bufnr`, eliminating unnecessary copying and iteration over unrelated bookmarks.

## 2. Eliminate Recursion in `sanitize` (`bookmark.lua`)

**Problem:**
The `sanitize` function currently uses recursion. While likely safe for typical usage, it poses a risk of stack overflow in edge cases and is generally harder to debug than iterative solutions.

**Solution:**
- Rewrite `sanitize` to use a `while` loop instead of recursion.

## 3. Avoid Unnecessary Sorting (`bookmark.lua`)

**Problem:**
`bookmark.list()` always returns a sorted and grouped list. However, internal synchronization processes (like `bookmarks_to_signs`) often don't require this order, making the sorting overhead unnecessary.

**Solution:**
- Introduce a lightweight accessor (e.g., `get_all()`) that returns the raw list or a simple copy without sorting/grouping.
- Update internal consumers to use this lightweight method where order is irrelevant.
