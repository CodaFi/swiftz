//
//  Amb.swift
//  Swiftz
//
//  Created by Robert Widmann on 7/15/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

public struct Amb<R, A> {
	let unAmb : AmbState<Amb<R, R>, A>
	
	init(_ unAmb : AmbState<Amb<R, R>, A>) {
		self.unAmb = unAmb
	}
	
	public init(amb xs : [A]) {
		switch xs.match {
		case .Nil:
			self  = Amb((getT() as AmbState<Amb<R, R>, Amb<R, R>>).bind { (a : Amb<R, R>) -> AmbState<Amb<R, R>, A> in
				let _ = a >>> undefined() as Amb<R, A>
				fatalError()
			})
		case .Cons(let x, let xs):
			self = Amb.pure(x).or(Amb(amb: xs))
		}
	}
	
	public static func ambBool() -> Amb<R, Bool> {
		return ambCC { (k : Bool -> Amb<R, A>) -> Amb<R, Bool> in
			let rs = Amb<Amb<R, R>, Amb<R, R>>(getT()).bind { old in
				let x = Amb.init <| putT(Amb<R, ()>(putT(old) as AmbState<Amb<R, R>, ()>) >>> k(false) >>> undefined() as Amb<R, Bool>) >>> Amb<R, Bool>.pure(true)
				return undefined() as Amb<R, Bool>
			}
			return undefined() as Amb<R, Bool>
		}
	}
	
	public func or(other : Amb<R, A>) -> Amb<R, A> {
		return Amb.ambBool().bind({ r in
			return r ? self : other
		})
	}
	
	static func pure(x : A) -> Amb<R, A> {
		return Amb.init <| AmbState<Amb<R, R>, A>.pure(x)
	}
	
	public func bind<B>(f : A -> Amb<R, B>) -> Amb<R, B> {
		return Amb<R, B>.init <| self.unAmb.bind { a in f(a).unAmb }
	}
}

public func >>> <R, A, B>(l : Amb<R, A>, r : Amb<R, B>) -> Amb<R, B> {
	return l.bind { _ in
		return r
	}
}

private func unAmb<R, A>(a : Amb<R, A>) -> AmbState<Amb<R, R>, A> {
	return a.unAmb
}

public func ambCC<R, A, B>(f : (A -> Amb<R, B>) -> Amb<R, A>) -> Amb<R, A> {
	let x = callCCA { k in
		let x = f({ a in Amb(k(a)) }).unAmb
		fatalError()
	}
	fatalError()
}


struct ContState<R, A> {
	let runCont : (A -> State<[R], R>) -> State<[R], R>
	
	static func pure(x : A) -> ContState<R, A> {
		return ContState { f in
			return f(x)
		}
	}
	
	func bind<B>(f : A -> ContState<R, B>) -> ContState<R, B> {
		return ContState<R, B> { k in self.runCont({ a in f(a).runCont(k) }) }
	}
}

func callCCA<R, A, B>(f : (A -> ContState<R, B>) -> ContState<R, A>) -> ContState<R, A> {
	return ContState { k in f({ a in ContState { x in k(a) } }).runCont(k) }
}

struct AmbState<R, A> {
	let runState : R -> ContState<R, (A, R)>
	
	init(_ runState : R -> ContState<R, (A, R)>) {
		self.runState = runState
	}
	
	func eval(s : R) -> ContState<R, A> {
		return self.runState(s).bind { (r, _) in
			return ContState.pure(r)
		}
	}
	
	func exec(s : R) -> ContState<R, R> {
		return self.runState(s).bind { (_, s) in
			return ContState.pure(s)
		}
	}
	
	static func pure(a : A) -> AmbState<R, A> {
		return state { s in (a, s) }
	}
	
	func bind<B>(f : A -> AmbState<R, B>) -> AmbState<R, B> {
		return AmbState<R, B> { s in
			return self.runState(s).bind { (a, s2) in
				return f(a).runState(s2)
			}
		}
	}
}

func state<R, A>(f : R -> (A, R)) -> AmbState<R, A> {
	return AmbState<R, A>.init <| ContState<R, (A, R)>.pure • f
}

/// Fetches the current value of the state.
func getT<S>() -> AmbState<S, S> {
	return state <| { ($0, $0) }
}

/// Sets the state.
func putT<S>(s : S) -> AmbState<S, ()> {
	return state <| { _ in ((), s) }
}

