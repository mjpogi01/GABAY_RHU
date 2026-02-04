// Stub for dart:io File on web (dart:io is not available on web).
// Used so that code can compile; file operations are skipped on web.

class File {
  File(String path);
  bool existsSync() => false;
}
