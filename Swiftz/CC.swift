//
//  Cont.swift
//  Swiftz
//
//  Created by Robert Widmann on 7/14/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

/// `Cont<R, A>` is a computation in continuation-passing style (CPS) that produces an intermediate
/// result of type `A` within a CPS computation whose final result type is of type `R`. A CPS-
/// style function result is not returned, but is instead passed to another function passed as a
/// parameter (the continuation).  Computation is performed by sequencing nested continuations,
/// finally terminating in a final continuation (usually `identity`) that produces a final
/// overall result.
///
/// Code written in CPS-style has an incredible amount of power over the flow of computation, but
/// often suffers from readability or maintainability issues.
public struct Cont<R, A> {
	/// The result of running a CPS computation with a given final continuation.
	public let runCont : (A -> R) -> R
}

extension Cont : Functor {
	typealias B = Any
	typealias FB = Cont<R, B>
	
	/// Applies a function to transform the result of a continuation-passing computation.
	public func fmap<B>(f : A -> B) -> Cont<R, B> {
		return Cont<R, B> { k in
			return self.runCont { a in k(f(a)) }
		}
	}
	
	/// Applies a function to transform the continuation passed to a CPS computation.
	public func withCont<B>(f : ((B -> R) -> (A -> R))) -> Cont<R, B> {
		return Cont<R, B>(runCont: self.runCont • f)
	}
}

extension Cont : Pointed {
	public static func pure(x : A) -> Cont<R, A> {
		return Cont { f in
			return f(x)
		}
	}
}

extension Cont : Applicative {
	typealias FAB = Cont<R, A -> B>
	
	public func ap<B>(f : Cont<R, A -> B>) -> Cont<R, B> {
		return f.bind { fs in
			return self.bind { x in
				return Cont<R, B>.pure(fs(x))
			}
		}
	}
}

extension Cont : Monad {
	public func bind<B>(f : A -> Cont<R, B>) -> Cont<R, B> {
		return Cont<R, B> { k in self.runCont({ a in f(a).runCont(k) }) }
	}
}

/// call-with-current-continuation calls the argument function then applies the current 
/// continuation.  `callCC` mimicks the control-flow of `throw` and `catch` statements in that
/// it interrupts the current continuation and replaces it with the applied continuation, thus
/// forcing the overall result to evaluate to the argument of the continuation.
///
/// The advantage of this function over calling `pure` is that it makes the continuation explicit,
/// allowing more flexibility and better control.
public func callCC<R, A, B>(f : (A -> Cont<R, B>) -> Cont<R, A>) -> Cont<R, A> {
	return Cont { k in f({ a in Cont { x in k(a) } }).runCont(k) }
}
