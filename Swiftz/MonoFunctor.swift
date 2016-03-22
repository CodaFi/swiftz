//
//  MonoFunctor.swift
//  Swiftz
//
//  Created by Robert Widmann on 1/11/16.
//  Copyright © 2016 TypeLift. All rights reserved.
//

public protocol MonoFunctor {
	typealias Element

	/// Map over a monomorphic container
	func omap(_ : Element -> Element) -> Self
}


public protocol MonoFoldable {
	typealias Element

	func ofoldMap<M : Monoid>(f : Element -> M) -> M
	func oFoldr<B>(f : (Element, B) -> B, initial : B) -> B
	func oFoldl<A>(f : (A, Element) -> A, initial : A) -> A
}

//extension MonoFoldable {
//	var oToList : [Self.Element] {
//		return
//	}
//
//	public func oAll(f : Self.Element -> Bool) -> Bool {
//		return self.ofoldMap(All.init • f).getAll
//	}
//
//	public func oAny(f : Self.Element -> Bool) -> Bool {
//		return self.ofoldMap(Any.init • f).getAny
//	}
//
//	public var oNull : Bool {
//		return self.oAll(const(false))
//	}
//
//	public var oLength : UInt {
//		return self.oFoldl({ (i, _) in i + 1 }, initial: 0)
//	}
//
//	
//}
