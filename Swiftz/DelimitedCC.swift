//
//  DelimitedCC.swift
//  Swiftz
//
//  Created by Robert Widmann on 7/14/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

struct Prompt<Answer, A> {
	let tag : Int
}

struct PromptSupplier<Answer, A> {
	let unP : State<Int, A>
	
	static func newPrompt() -> PromptSupplier<Answer, Prompt<Answer, A>> {
		return PromptSupplier<Answer, Prompt<Answer, A>>(unP: get() >>- { i in
			return put(i + 1) >>- { _ in State.pure(Prompt(tag: i)) }
		})
	}
}

func runP<Answer>(ps : PromptSupplier<Answer, Answer>) -> Answer {
	return ps.unP.eval(0)
}

struct CCT<Answer, A> {
	let unCCT : FrameSeq<Answer, A> -> PromptSupplier<Answer, Answer>
	
	func runCCT() -> A {
		return runP(self.unCCT(.EmptyS))
	}
	
	private func apply(f : FrameSeq<Answer, A>, _ x : A) -> PromptSupplier<Answer, Answer> {
		switch f {
		case .EmptyS:
			return PromptSupplier(unP: State<Int, A>.pure(x))
		case .PushP(_, let k):
			return self.apply(k(), x)
		}
	}
}

struct DelimitedCont<Answer, A> {
	let unDelimit : CCT<Answer, A>
	
	
}

enum Frame<Answer, A, B> {
	case FFrame(A -> B)
	case MFrame(A -> CCT<Answer, B>)
}

enum FrameSeq<Answer, A> {
	case EmptyS
	case PushP(Prompt<Answer, A>, () -> FrameSeq<Answer, A>)
}

struct SubCont<Answer, A, B> {
	let unSubCont : [Frame<Answer, A, B>]
}
