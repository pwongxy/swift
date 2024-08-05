// RUN: %empty-directory(%t)
// RUN: split-file %s %t
// RUN: %target-swift-frontend -emit-module -o %t %t/InternalUsesOnly.swift
// RUN: %target-swift-frontend -emit-module -o %t %t/InternalUsesOnlyDefaultedImport.swift
// RUN: %target-swift-frontend -emit-module -o %t %t/PackageUsesOnly.swift
// RUN: %target-swift-frontend -emit-module -o %t %t/PublicUsesOnly.swift
// RUN: %target-swift-frontend -emit-module -o %t %t/PublicUsesOnlyDefaultedImport.swift
// RUN: %target-swift-frontend -emit-module -o %t %t/MixedUses.swift
// RUN: %target-swift-frontend -emit-module -o %t %t/InternalUsesOnlyTransitivelyImported.swift
// RUN: %target-swift-frontend -emit-module -o %t %t/Exports.swift -I %t
// RUN: %target-swift-frontend -typecheck -verify -swift-version 5 \
// RUN:   -primary-file %t/function_bodies.swift \
// RUN:   -primary-file %t/function_signatures.swift \
// RUN:   %t/imports.swift \
// RUN:   -I %t -package-name Package \
// RUN:   -enable-experimental-feature MemberImportVisibility

//--- function_bodies.swift

// FIXME: The access level is wrong on many of these fix-its.
import Swift // Just here to anchor the fix-its
// expected-note      {{add import of module 'InternalUsesOnly'}}{{1-1=internal import InternalUsesOnly\n}}
// expected-note@-1   {{add import of module 'InternalUsesOnlyDefaultedImport'}}{{1-1=import InternalUsesOnlyDefaultedImport\n}}
// expected-note@-2   {{add import of module 'PackageUsesOnly'}}{{1-1=internal import PackageUsesOnly\n}}
// expected-note@-3   {{add import of module 'PublicUsesOnly'}}{{1-1=internal import PublicUsesOnly\n}}
// expected-note@-4   {{add import of module 'PublicUsesOnlyDefaultedImport'}}{{1-1=import PublicUsesOnlyDefaultedImport\n}}
// expected-note@-5 3 {{add import of module 'MixedUses'}}{{1-1=internal import MixedUses\n}}
// expected-note@-6   {{add import of module 'InternalUsesOnlyTransitivelyImported'}}{{1-1=internal import InternalUsesOnlyTransitivelyImported\n}}

func internalFunc(_ x: Int) {
  _ = x.memberInInternalUsesOnly // expected-error {{property 'memberInInternalUsesOnly' is not available due to missing import of defining module 'InternalUsesOnly'}}
  _ = x.memberInInternalUsesOnlyDefaultedImport // expected-error {{property 'memberInInternalUsesOnlyDefaultedImport' is not available due to missing import of defining module 'InternalUsesOnlyDefaultedImport'}}
  _ = x.memberInMixedUses // expected-error {{property 'memberInMixedUses' is not available due to missing import of defining module 'MixedUses'}}
  _ = x.memberInInternalUsesOnlyTransitivelyImported // expected-error {{property 'memberInInternalUsesOnlyTransitivelyImported' is not available due to missing import of defining module 'InternalUsesOnlyTransitivelyImported'}}
}

@inlinable package func packageInlinableFunc(_ x: Int) {
  _ = x.memberInPackageUsesOnly // expected-error {{property 'memberInPackageUsesOnly' is not available due to missing import of defining module 'PackageUsesOnly'}}
  _ = x.memberInMixedUses // expected-error {{property 'memberInMixedUses' is not available due to missing import of defining module 'MixedUses'}}
}

@inlinable public func inlinableFunc(_ x: Int) {
  _ = x.memberInPublicUsesOnly // expected-error {{property 'memberInPublicUsesOnly' is not available due to missing import of defining module 'PublicUsesOnly'}}
  _ = x.memberInPublicUsesOnlyDefaultedImport // expected-error {{property 'memberInPublicUsesOnlyDefaultedImport' is not available due to missing import of defining module 'PublicUsesOnlyDefaultedImport'}}
  _ = x.memberInMixedUses // expected-error {{property 'memberInMixedUses' is not available due to missing import of defining module 'MixedUses'}}
}

//--- function_signatures.swift

import Swift // Just here to anchor the fix-its
// expected-note    2 {{add import of module 'InternalUsesOnly'}}{{1-1=internal import InternalUsesOnly\n}}
// expected-note@-1   {{add import of module 'PackageUsesOnly'}}{{1-1=package import PackageUsesOnly\n}}
// expected-note@-2   {{add import of module 'PublicUsesOnly'}}{{1-1=public import PublicUsesOnly\n}}
// expected-note@-3 2 {{add import of module 'MixedUses'}}{{1-1=public import MixedUses\n}}

extension Int {
  private func usesTypealiasInInternalUsesOnly_Private(x: TypealiasInInternalUsesOnly) {} // expected-error {{type alias 'TypealiasInInternalUsesOnly' is not available due to missing import of defining module 'InternalUsesOnly'}}
  internal func usesTypealiasInInternalUsesOnly(x: TypealiasInInternalUsesOnly) {} // expected-error {{type alias 'TypealiasInInternalUsesOnly' is not available due to missing import of defining module 'InternalUsesOnly'}}
  package func usesTypealiasInPackageUsesOnly(x: TypealiasInPackageUsesOnly) {} // expected-error {{type alias 'TypealiasInPackageUsesOnly' is not available due to missing import of defining module 'PackageUsesOnly'}}
  public func usesTypealiasInPublicUsesOnly(x: TypealiasInPublicUsesOnly) {} // expected-error {{type alias 'TypealiasInPublicUsesOnly' is not available due to missing import of defining module 'PublicUsesOnly'}}
  // expected-warning@-1 {{cannot use type alias 'TypealiasInPublicUsesOnly' here; 'PublicUsesOnly' was not imported by this file}}
  public func usesTypealiasInMixedUses(x: TypealiasInMixedUses) {} // expected-error {{type alias 'TypealiasInMixedUses' is not available due to missing import of defining module 'MixedUses'}}
  // expected-warning@-1 {{cannot use type alias 'TypealiasInMixedUses' here; 'MixedUses' was not imported by this file}}
  internal func usesTypealiasInMixedUses_Internal(x: TypealiasInMixedUses) {} // expected-error {{type alias 'TypealiasInMixedUses' is not available due to missing import of defining module 'MixedUses'}}
}

//--- imports.swift

internal import InternalUsesOnly
import InternalUsesOnlyDefaultedImport
internal import PackageUsesOnly
internal import PublicUsesOnly
import PublicUsesOnlyDefaultedImport
internal import MixedUses
internal import Exports

//--- InternalUsesOnly.swift

extension Int {
  public typealias TypealiasInInternalUsesOnly = Self
  public var memberInInternalUsesOnly: Int { return self }
}

//--- InternalUsesOnlyDefaultedImport.swift

extension Int {
  public typealias TypealiasInInternalUsesOnlyDefaultedImport = Self
  public var memberInInternalUsesOnlyDefaultedImport: Int { return self }
}

//--- PackageUsesOnly.swift

extension Int {
  public typealias TypealiasInPackageUsesOnly = Self
  public var memberInPackageUsesOnly: Int { return self }
}

//--- PublicUsesOnly.swift

extension Int {
  public typealias TypealiasInPublicUsesOnly = Self
  public var memberInPublicUsesOnly: Int { return self }
}

//--- PublicUsesOnlyDefaultedImport.swift

extension Int {
  public typealias TypealiasInPublicUsesOnlyDefaultedImport = Self
  public var memberInPublicUsesOnlyDefaultedImport: Int { return self }
}

//--- MixedUses.swift

extension Int {
  public typealias TypealiasInMixedUses = Self
  public var memberInMixedUses: Int { return self }
}

//--- InternalUsesOnlyTransitivelyImported.swift

extension Int {
  public typealias TypealiasInInternalUsesOnlyTransitivelyImported = Self
  public var memberInInternalUsesOnlyTransitivelyImported: Int { return self }
}

//--- Exports.swift

@_exported import InternalUsesOnlyTransitivelyImported
