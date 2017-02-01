// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/src/io.dart' as io;
import 'package:meta/meta.dart';

import 'common.dart';
import 'mutable_recording.dart';
import 'recording_directory.dart';
import 'recording_file.dart';
import 'recording_file_system.dart';
import 'recording_link.dart';
import 'recording_proxy_mixin.dart';

abstract class RecordingFileSystemEntity<T extends FileSystemEntity,
        D extends io.FileSystemEntity> extends Object
    with RecordingProxyMixin
    implements FileSystemEntity {
  RecordingFileSystemEntity(this.fileSystem, this.delegate) {
    methods.addAll(<Symbol, Function>{
      #exists: delegate.exists,
      #existsSync: delegate.existsSync,
      #rename: _rename,
      #renameSync: _renameSync,
      #resolveSymbolicLinks: delegate.resolveSymbolicLinks,
      #resolveSymbolicLinksSync: delegate.resolveSymbolicLinksSync,
      #stat: delegate.stat,
      #statSync: delegate.statSync,
      #delete: _delete,
      #deleteSync: delegate.deleteSync,
      #watch: delegate.watch,
    });

    properties.addAll(<Symbol, Function>{
      #path: () => delegate.path,
      #uri: () => delegate.uri,
      #isAbsolute: () => delegate.isAbsolute,
      #absolute: _getAbsolute,
      #parent: _getParent,
    });
  }

  /// A unique entity id.
  final int uid = newUid();

  @override
  final RecordingFileSystemImpl fileSystem;

  @override
  MutableRecording get recording => fileSystem.recording;

  @override
  Stopwatch get stopwatch => fileSystem.stopwatch;

  @protected
  final D delegate;

  /// Returns an entity with the same file system and same type as this
  /// entity but backed by the specified delegate.
  ///
  /// If the specified delegate is the same as this entity's delegate, this
  /// will return this entity.
  ///
  /// Subclasses should override this method to instantiate the correct wrapped
  /// type if this super implementation returns `null`.
  @protected
  @mustCallSuper
  T wrap(D delegate) => delegate == this.delegate ? this as T : null;

  @protected
  Directory wrapDirectory(io.Directory delegate) =>
      new RecordingDirectory(fileSystem, delegate);

  @protected
  File wrapFile(io.File delegate) => new RecordingFile(fileSystem, delegate);

  @protected
  Link wrapLink(io.Link delegate) => new RecordingLink(fileSystem, delegate);

  Future<T> _rename(String newPath) => delegate
      .rename(newPath)
      .then((io.FileSystemEntity entity) => wrap(entity as D));

  T _renameSync(String newPath) => wrap(delegate.renameSync(newPath) as D);

  Future<T> _delete({bool recursive: false}) => delegate
      .delete(recursive: recursive)
      .then((io.FileSystemEntity entity) => wrap(entity as D));

  T _getAbsolute() => wrap(delegate.absolute as D);

  Directory _getParent() => wrapDirectory(delegate.parent);
}