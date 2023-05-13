(* ::Package:: *)

(* ::Input:: *)
(*ConnorGray`Vilfram`EnableVilfram[EvaluationNotebook[]]*)


(* ::Input:: *)
(*Dynamic[CurrentValue[EvaluationNotebook[], {TaggingRules,"Vilfram"}]]*)


BeginPackage["ConnorGray`Vilfram`"]

Needs["GeneralUtilities`"]

GeneralUtilities`SetUsage[$VilframCommands, "
$VilframCommands contains the recognized command sequences and actions to be executed.
"]

GeneralUtilities`SetUsage[EnableVilfram, "
EnableVilfram[nbobj$] enables Vilfram keyboard behavior in the notebook represented by the notebook object nbobj$.
"]

Begin["`Private`"]

(*====================================*)

$VilframCommands = {
	{"i" | "a"} :> (
		CurrentValue[EvaluationNotebook[], {TaggingRules, "Vilfram", "Mode"}] = "Insert"
	),
	{"j"} :> FrontEndTokenExecute["MoveNextLine"],
	{"k"} :> FrontEndTokenExecute["MovePreviousLine"],
	{"h"} :> FrontEndTokenExecute["MovePrevious"],
	{"l"} :> FrontEndTokenExecute["MoveNext"],
	{"b"} :> FrontEndTokenExecute["MovePreviousWord"],
	{"e"} :> FrontEndTokenExecute["MoveNextWord"],
	{"^"} :> FrontEndTokenExecute["MoveLineBeginning"],
	{"$"} :> FrontEndTokenExecute["MoveLineEnd"]
};

(*====================================*)

EnableVilfram[nb_NotebookObject] :=
	SetOptions[nb, {
		NotebookEventActions -> {
			PassEventsDown :> (
				CurrentValue[EvaluationNotebook[], {TaggingRules, "Vilfram", "Mode"}] =!= "Command"
				&& CurrentValue["EventKey"] =!= "\[RawEscape]"
			),
			"KeyDown" :> processKeyDown[EvaluationNotebook[], CurrentValue["EventKey"]]
		},
		WindowStatusArea -> Dynamic[
			"Vilfram: "
			<> CurrentValue[EvaluationNotebook[], {TaggingRules, "Vilfram", "Mode"}]
			<> " \[LongDash] " <> ToString[CurrentValue[EvaluationNotebook[], {TaggingRules, "Vilfram", "KeySequence"}]]
		]
	}]

(*====================================*)

processKeyDown[nb_NotebookObject, key_?StringQ] := With[{
	currentMode = CurrentValue[nb, {TaggingRules, "Vilfram", "Mode"}],
	setMode = mode |-> CurrentValue[nb, {TaggingRules, "Vilfram", "Mode"}] = mode
}, Module[{
	keySequence,
	result
},
	If[key === "\[RawEscape]" (* \\[RawEscape] *),
		Replace[currentMode, {
			"Command" :> (
				(* Reset the command sequence back to empty. *)
				CurrentValue[nb, {TaggingRules, "Vilfram", "KeySequence"}] = {};
			),
			"Insert" | _ :> (
				(* Switch to Command mode. *)
				setMode["Command"];
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
	keySequence = Replace[CurrentValue[nb, {TaggingRules, "Vilfram", "KeySequence"}], {
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
		Missing["NoCommandKeySequenceMatches"] :> (
			(* No command key sequence matched, so save the updated key sequence. *)
			CurrentValue[nb, {TaggingRules, "Vilfram", "KeySequence"}] = keySequence;
		),
		_ :> (
			(* A key command sequence matched the user's input, so reset the
				stored command key sequence. *)
			CurrentValue[nb, {TaggingRules, "Vilfram", "KeySequence"}] = {};
		)
	}];
]]

(*====================================*)

End[]

EndPackage[]



