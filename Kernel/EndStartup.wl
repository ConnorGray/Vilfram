{$Context, $ContextPath, $ContextAliases} = Wolfram`VilframStartup`$ContextInfo;

(* NOTE:
	Paclets that have been disabled with PacletDisable but are
	"Loading" -> "Startup" are still loaded at startup. So we need to check if
	this paclet has been disabled, and if so, avoid
*)
Wolfram`VilframStartup`$IsEnabled =
	PacletFind["ConnorGray/Vilfram", <| "Enabled" -> False|>] === {}

If[TrueQ[Wolfram`VilframStartup`$IsEnabled],
	(* Enable Vilfram in the current FrontEndSession. *)
	ConnorGray`Vilfram`EnableVilfram[$FrontEndSession]
]

Once[
	FrontEndExecute @ FrontEnd`AddMenuCommands["FindNextMisspelling", {
			Delimiter,
			MenuItem[
				"Enable Vilfram",
				FrontEnd`KernelExecute[
					Needs["ConnorGray`Vilfram`"];
					ConnorGray`Vilfram`EnableVilfram[];
				],
				FrontEnd`MenuEvaluator -> Automatic
			],
			MenuItem[
				"Disable Vilfram",
				FrontEnd`KernelExecute[
					Needs["ConnorGray`Vilfram`"];
					ConnorGray`Vilfram`DisableVilfram[];
				],
				FrontEnd`MenuEvaluator -> Automatic
			]
	}],
	"FrontEndSession"
]