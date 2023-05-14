(* ::Package:: *)

(* ::Input:: *)
(*ConnorGray`Vilfram`EnableVilfram[EvaluationNotebook[]]*)


(* ::Input:: *)
(*Dynamic[CurrentValue[EvaluationNotebook[], {TaggingRules,"Vilfram"}]]*)


BeginPackage["ConnorGray`Vilfram`"];

Needs["GeneralUtilities`"]

GeneralUtilities`SetUsage[$VilframCommands, "
$VilframCommands contains the recognized command sequences and actions to be executed.
"];

GeneralUtilities`SetUsage[EnableVilfram, "
EnableVilfram[nbobj$] enables Vilfram keyboard behavior in the notebook represented by the notebook object nbobj$.
"];

GeneralUtilities`SetUsage[$RetainKeyCommandSequence, "
RetainKeySequence is a special value that, when returned from a Vilfram command handler, indicates
that the current key sequence should not be reset.

This is intended to be used by Vilfram command that is 'sticky'.
"];


Begin["`Private`"];

(*====================================*)

$VilframCommands = {
	(*--------------------*)
	(* Common Vi Commands *)
	(*--------------------*)
	{"i" | "a"} :> (
		setState[EvaluationNotebook[], "Mode" -> "Insert"]
	),
	{"j"} :> FrontEndTokenExecute["MoveNextLine"],
	{"k"} :> FrontEndTokenExecute["MovePreviousLine"],
	{"h"} :> FrontEndTokenExecute["MovePrevious"],
	{"l"} :> FrontEndTokenExecute["MoveNext"],
	(* TODO: This should be MovePreviousWord, however that token appears to a
		have a bug when used in textual cells: it gets "stuck" at the beginning
		of a word boundary and won't move back. MovePreviousNaturalWord doesn't
		have that problem, and also works in box/typesetting cells. *)
	{"b"} :> FrontEndTokenExecute["MovePreviousNaturalWord"],
	(* TODO: This isn't the right behavior. `B` should move back through all
		consecutive non-whitespace. *)
	{"B"} :> FrontEndTokenExecute["MovePreviousNaturalWord"],
	{"e"} :> FrontEndTokenExecute["MoveNextWord"],
	{"^"} :> FrontEndTokenExecute["MoveLineBeginning"],
	{"$"} :> FrontEndTokenExecute["MoveLineEnd"],
	{"G"} :> SelectionMove[EvaluationNotebook[], Before, Notebook],
	{"g", "g"} :> SelectionMove[EvaluationNotebook[], After, Notebook],
	{"u"} :> FrontEndTokenExecute["Undo"],
	{"x"} :> FrontEndTokenExecute["Cut"],
	{"y"} :> FrontEndTokenExecute["Copy"],
	{"p"} :> FrontEndTokenExecute["Paste"],
	{":", "w", "\r"} :> (
		FrontEndTokenExecute["Save"];
	),
	{":", "x", "\r"} :> (
		FrontEndTokenExecute["Save"];
		FrontEndTokenExecute["Close"];
	),
	{"d", "e"} :> FrontEndTokenExecute["DeleteNextWord"],
	{"d", "b"} :> FrontEndTokenExecute["DeletePreviousWord"],
	{"d", "w"} :> FrontEndTokenExecute["DeleteNextNaturalWord"],
	{"d", "^"} :> FrontEndTokenExecute["DeleteLineBeginning"],
	{"d", "$"} :> FrontEndTokenExecute["DeleteLineEnd"],
	(*--------------------------------*)
	(* Visual selection sub-commands. *)
	(*--------------------------------*)
	{"v", ___, "h"} :> (
		FrontEndTokenExecute["SelectPrevious"];
		$RetainKeyCommandSequence
	),
	{"v", ___, "l"} :> (
		FrontEndTokenExecute["SelectNext"];
		$RetainKeyCommandSequence
	),
	{"v", ___, "j"} :> (
		FrontEndTokenExecute["SelectNextLine"];
		$RetainKeyCommandSequence
	),
	{"v", ___, "k"} :> (
		FrontEndTokenExecute["SelectPreviousLine"];
		$RetainKeyCommandSequence
	),
	{"v", ___, "e"} :> (
		FrontEndTokenExecute["SelectNextWord"];
		$RetainKeyCommandSequence
	),
	{"v", ___, "b"} :> (
		FrontEndTokenExecute["SelectPreviousWord"];
		$RetainKeyCommandSequence
	),
	{"v", ___, "$"} :> (
		FrontEndTokenExecute["SelectLineEnd"];
		$RetainKeyCommandSequence
	),
	{"v", ___, "^"} :> (
		FrontEndTokenExecute["SelectLineBeginning"];
		$RetainKeyCommandSequence
	),
	{"v", ___, "i"} :> (
		FrontEndTokenExecute["ExpandSelection"];
		$RetainKeyCommandSequence
	),
	{"v", ___, "x"} :> (
		FrontEndTokenExecute["Cut"];
	),
	(*------------------*)
	(* Vi-like Commands *)
	(*------------------*)
	{"d", Repeated["i"]} :> (
		FrontEndTokenExecute["ExpandSelection"];
		$RetainKeyCommandSequence
	),
	{"d", Repeated["i"], "\r"} :> (
		NotebookDelete[EvaluationNotebook[]]
	)
};

(*====================================*)

EnableVilfram[obj:$FrontEndSession] :=
	setVilframOptions[obj]

setVilframOptions[obj : $FrontEndSession | _NotebookObject] :=
	SetOptions[obj, {
		NotebookEventActions -> {
			PassEventsDown :> (
				getState[EvaluationNotebook[], "Mode"] =!= "Command"
				&& CurrentValue["EventKey"] =!= "\[RawEscape]"
			),
			"KeyDown" :> processKeyDown[EvaluationNotebook[], CurrentValue["EventKey"]]
		}
	}]

(*====================================*)

processKeyDown[nb_NotebookObject, key_?StringQ] := With[{
	currentMode = getState[nb, "Mode"],
	setMode = mode |-> setState[nb, "Mode" -> mode]
}, Module[{
	keySequence,
	result
},
	If[key === "\[RawEscape]" (* \\[RawEscape] *),
		Replace[currentMode, {
			"Command" :> (
				(* Reset the command sequence back to empty. *)
				setState[nb, "KeySequence" -> {}];
			),
			"Insert" | _ :> (
				(* Switch to Command mode. *)
				setState[nb, "Mode" -> "Command"];
			)
		}];

		Return[Null];
	];

	(* We're not in Command mode, so do no further processing. *)
	If[currentMode =!= "Command",
		Return[Null];
	];

	(*----------------------------------*)
	(* Process the key command sequence *)
	(*----------------------------------*)

	(* Construct the key command sequence by appending the latest key to
		any keys stored keys that were previously pressed but didn't match
		a key command pattern. *)
	keySequence = Replace[getState[nb, "KeySequence"], {
		Inherited -> {key},
		keys:{___?StringQ} :> Append[keys, key],
		other_ :> (
			(* FIXME: Generate a better error. *)
			Throw["ERROR: Unrecognized Vilfram KeySequence stored: ", InputForm[other]];
		)
	}];

	(* FIXME: If the command action throws an exception or abort,
		we should still reset the store "KeySequence" *)
	result = Replace[
		keySequence,
		Append[
			$VilframCommands,
			_ :> Missing["NoCommandKeySequenceMatches"]
		]
	];

	Replace[result, {
		Missing["NoCommandKeySequenceMatches"] | $RetainKeyCommandSequence :> (
			(* No command key sequence matched, so save the updated key sequence. *)
			setState[nb, "KeySequence" -> keySequence];
		),
		_ :> (
			(* A key command sequence matched the user's input, so reset the
				stored command key sequence. *)
			setState[nb, "KeySequence" -> {}];
		)
	}];
]]

(*====================================*)

(*
	Store Vilfram state on a per-notebook basis, but without storing it into
	the notebook itself.

	These use $FrontEndSession so that separate command state is maintained in
	different notebooks, but the overall state is cleared when the FrontEnd is
	restarted.
*)

getState[nb_NotebookObject, key_?StringQ] :=
	CurrentValue[
		$FrontEndSession,
		{PrivateFrontEndOptions, "InterfaceSettings", "ConnorGray/Vilfram", nb, key}
	];

setState[nb_NotebookObject, key_?StringQ -> value_] :=
	CurrentValue[
		$FrontEndSession,
		{PrivateFrontEndOptions, "InterfaceSettings", "ConnorGray/Vilfram", nb, key}
	] = value;

(*====================================*)

End[];

EndPackage[];

