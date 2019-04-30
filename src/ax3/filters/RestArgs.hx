package ax3.filters;

import ax3.ParseTree.TypeHint;

class RestArgs extends AbstractFilter {
	override function processFunction(fun:TFunction) {
		if (fun.expr != null) fun.expr = processExpr(fun.expr);

		if (fun.sig.args.length > 0) {
			var lastArg = fun.sig.args[fun.sig.args.length - 1];
			switch lastArg.kind {
				case TArgNormal(_):
					// nothing to do
				case TArgRest(dots, _):
					var hint:TypeHint = {
						colon: new Token(0, TkColon, ":", [], []),
						type: TPath({first: new Token(0, TkIdent, "Array", [], []), rest: []})
					};
					lastArg.kind = TArgNormal(hint, {
						equalsToken: new Token(0, TkEquals, "=", [whitespace], [whitespace]),
						expr: mkNullExpr(TTArray(TTAny))
					});
					var dotsTrivia = dots.leadTrivia.concat(dots.trailTrivia);
					lastArg.syntax.name.leadTrivia = dotsTrivia.concat(lastArg.syntax.name.leadTrivia);

					var argLocal = mk(TELocal(mkIdent(lastArg.name), lastArg.v), lastArg.type, lastArg.type);

					// TODO: indentation
					var eArrayInit = mk(TEIf({
						syntax: {
							keyword: addTrailingWhitespace(mkIdent("if")),
							openParen: mkOpenParen(),
							closeParen: addTrailingWhitespace(mkCloseParen())
						},
						econd: mk(TEBinop(
							argLocal,
							OpEquals(mkEqualsEqualsToken()),
							mkNullExpr()
						), TTBoolean, TTBoolean),
						ethen: mk(TEBinop(
							argLocal,
							OpAssign(new Token(0, TkEquals, "=", [whitespace], [whitespace])),
							mk(TEArrayDecl({
								syntax: {openBracket: mkOpenBracket(), closeBracket: mkCloseBracket()},
								elements: []
							}), tUntypedArray, tUntypedArray)
						), argLocal.type, argLocal.type),
						eelse: null
					}), TTVoid, TTVoid);
					fun.expr = concatExprs(eArrayInit, fun.expr);

			}
		}
	}

	override function processExpr(e:TExpr):TExpr {
		e = mapExpr(processExpr, e);

		switch e.kind {
			case TELocalFunction(f):
				processFunction(f.fun);

			case TENew(token, eclass = {type: TTStatic(cls)}, args) if (args != null && args.args.length > 0):
				switch getConstructor(cls) {
					case {type: TTFun(argTypes, _, TRestAs3)}:
						args.args = transformArgs(args.args, argTypes.length);

					case _:
				}

			case TECall(eobj = {type: TTFun(argTypes, _, TRestAs3)}, args) if (args.args.length > argTypes.length):
				args.args = transformArgs(args.args, argTypes.length);

			case _:
		}

		return e;
	}

	static function transformArgs(args:Array<{expr:TExpr, comma:Null<Token>}>, nonRest:Int) {
		var normalArgs = args.slice(0, nonRest);
		var restArgs = args.slice(nonRest);

		var lead = removeLeadingTrivia(restArgs[0].expr);
		var trail = removeTrailingTrivia(restArgs[restArgs.length - 1].expr);

		normalArgs.push({
			expr: mk(TEArrayDecl({
				syntax: {
					openBracket: new Token(0, TkBracketOpen, "[", lead, []),
					closeBracket: new Token(0, TkBracketClose, "]", [], trail),
				},
				elements: restArgs
			}), tUntypedArray, tUntypedArray),
			comma: null
		});

		return normalArgs;
	}
}
