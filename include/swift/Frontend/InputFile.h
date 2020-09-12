//===--- InputFile.h --------------------------------------------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_FRONTEND_INPUTFILE_H
#define SWIFT_FRONTEND_INPUTFILE_H

#include "swift/Basic/PrimarySpecificPaths.h"
#include "swift/Basic/SupplementaryOutputPaths.h"
#include "llvm/Support/MemoryBuffer.h"
#include <string>

namespace swift {

enum class InputFileKind {
  None,
  Swift,
  SwiftLibrary,
  SwiftModuleInterface,
  SIL,
  LLVM,
  ObjCHeader,
};

// Inputs may include buffers that override contents, and eventually should
// always include a buffer.
class InputFile {
/// An \c InputFile encapsulates information about an input passed to the
/// frontend.
///
/// Compiler inputs are usually passed on the command line without a leading
/// flag. However, there are clients that use the \c CompilerInvocation as
/// a library like LLDB and SourceKit that generate their own \c InputFile
/// instances programmatically. Note that an \c InputFile need not actually be
/// backed by a physical file, nor does its file name actually reflect its
/// contents. \c InputFile has a constructor that will try to figure out the file
/// type from the file name if none is provided, but many clients that
/// construct \c InputFile instances themselves may provide bogus file names
/// with pre-computed kinds. It is imperative that \c InputFile::getType be used
/// as a source of truth for this information.
///
/// \warning \c InputFile takes an unfortunately lax view of the ownership of
/// its primary data. It currently only owns the file name and a copy of any
/// assigned \c PrimarySpecificPaths outright. It is the responsibility of the
/// caller to ensure that an associated memory buffer outlives the \c InputFile.
class InputFile final {
  std::string Filename;
  bool IsPrimary;
  /// Points to a buffer overriding the file's contents, or nullptr if there is
  /// none.
  llvm::MemoryBuffer *Buffer;

  /// If there are explicit primary inputs (i.e. designated with -primary-input
  /// or -primary-filelist), the paths specific to those inputs (other than the
  /// input file path itself) are kept here. If there are no explicit primary
  /// inputs (for instance for whole module optimization), the corresponding
  /// paths are kept in the first input file.
  PrimarySpecificPaths PSPs;

public:
  /// Does not take ownership of \p buffer. Does take ownership of (copy) a
  /// string.
  InputFile(StringRef name, bool isPrimary,
            llvm::MemoryBuffer *buffer = nullptr,
            StringRef outputFilename = StringRef())
      : Filename(
            convertBufferNameFromLLVM_getFileOrSTDIN_toSwiftConventions(name)),
        IsPrimary(isPrimary), Buffer(buffer), PSPs(PrimarySpecificPaths()) {
    assert(!name.empty());
  }

  bool isPrimary() const { return IsPrimary; }
  llvm::MemoryBuffer *buffer() const { return Buffer; }
  const std::string &file() const {
    assert(!Filename.empty());
    return Filename;
  }

  /// Return Swift-standard file name from a buffer name set by
  /// llvm::MemoryBuffer::getFileOrSTDIN, which uses "<stdin>" instead of "-".
  static StringRef convertBufferNameFromLLVM_getFileOrSTDIN_toSwiftConventions(
      StringRef filename) {
    return filename.equals("<stdin>") ? "-" : filename;
  }

  std::string outputFilename() const { return PSPs.OutputFilename; }

  const PrimarySpecificPaths &getPrimarySpecificPaths() const { return PSPs; }

  void setPrimarySpecificPaths(const PrimarySpecificPaths &PSPs) {
    this->PSPs = PSPs;
  }

  // The next set of functions provides access to those primary-specific paths
  // accessed directly from an InputFile, as opposed to via
  // FrontendInputsAndOutputs. They merely make the call sites
  // a bit shorter. Add more forwarding methods as needed.

  std::string dependenciesFilePath() const {
    return getPrimarySpecificPaths().SupplementaryOutputs.DependenciesFilePath;
  }
  std::string loadedModuleTracePath() const {
    return getPrimarySpecificPaths().SupplementaryOutputs.LoadedModuleTracePath;
  }
  std::string serializedDiagnosticsPath() const {
    return getPrimarySpecificPaths().SupplementaryOutputs
        .SerializedDiagnosticsPath;
  }
  std::string fixItsOutputPath() const {
    return getPrimarySpecificPaths().SupplementaryOutputs.FixItsOutputPath;
  }
};
} // namespace swift

#endif // SWIFT_FRONTEND_INPUTFILE_H
