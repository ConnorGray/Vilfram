(* ::Package:: *)

(* ::Input:: *)
(*ConnorGray`Vilfram`EnableVilfram[EvaluationNotebook[]]*)


BeginPackage["ConnorGray`Vilfram`"]

Needs["GeneralUtilities`"]

GeneralUtilities`SetUsage[EnableVilfram, "
EnableVilfram[nbobj$] enables Vilfram keyboard behavior in the notebook represented by the notebook object nbobj$.
"]

Begin["`Private`"]

EnableVilfram[nb_NotebookObject] :=
	SetOptions[nb, {
		NotebookEventActions -> {
			PassEventsDown :> (
				CurrentValue[EvaluationNotebook[], {TaggingRules, "VilframMode"}] =!= "Command"
				&& CurrentValue["EventKey"] =!= "\[RawEscape]"
			),
			"KeyDown" :> processKeyDown[EvaluationNotebook[], CurrentValue["EventKey"]]
		},
		WindowStatusArea -> Dynamic[
			"Vilfram: " <> CurrentValue[EvaluationNotebook[], {TaggingRules, "VilframMode"}]
		]
	}]

(*====================================*)

processKeyDown[nb_NotebookObject, key_?StringQ] := With[{
	currentMode = CurrentValue[nb, {TaggingRules, "VilframMode"}],
	setMode = mode |-> CurrentValue[nb, {TaggingRules, "VilframMode"}] = mode
},
	If[currentMode =!= "Command",
		If[key === "\[RawEscape]",
			setMode["Command"]
		];
		Return[Null];
	];

	Replace[key, {
		"i" | "a" :> (
			CurrentValue[EvaluationNotebook[], {TaggingRules, "VilframMode"}] = "Insert"
		),
		"j" :> FrontEndTokenExecute["MoveNextLine"],
		"k" :> FrontEndTokenExecute["MovePreviousLine"],
		"h" :> FrontEndTokenExecute["MovePrevious"],
		"l" :> FrontEndTokenExecute["MoveNext"],
		"b" :> FrontEndTokenExecute["MovePreviousWord"],
		"e" :> FrontEndTokenExecute["MoveNextWord"],
		"^" :> FrontEndTokenExecute["MoveLineBeginning"],
		"$" :> FrontEndTokenExecute["MoveLineEnd"],
		"d" :> (
			CurrentValue[EvaluationNotebook[], {TaggingRules, "VilframMode"}] = "Delete"
		)
	}]
]

End[]

EndPackage[]



