//
//  Cont.swift
//  Swiftz
//
//  Created by Robert Widmann on 7/14/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

public struct Cont<R, A> {
	let run : (A -> R) -> R
}

extension Cont : Functor {
	typealias B = Any
	typealias FB = Cont<R, B>
	public func fmap<B>(f : A -> B) -> Cont<R, B> {
		return Cont<R, B> { k in
			return self.run { a in k(f(a)) }
		}
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
		return Cont<R, B> { k in self.run({ a in f(a).run(k) }) }
	}
}

public func callcc<R, A, B>(f : (A -> Cont<R, B>) -> Cont<R, A> ) -> Cont<R, A> {
	return Cont { k in f({ a in Cont { x in k(a) } }).run(k) }
}
