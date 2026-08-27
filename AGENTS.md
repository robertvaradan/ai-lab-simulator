# AI Lab Simulator repository contract

## Specification voice

- Write normative project documentation, requirements, and implementation specifications in ASD-STE100 Simplified Technical English.
- Use short, direct sentences. Use one instruction or requirement per sentence.
- Use consistent approved terms. Do not use different terms for the same system, state, rule, or operation.
- Use `must` for requirements, `must not` for prohibitions, and `can` for capability. Do not use ambiguous modal verbs.
- Update the canonical specification when a requirement changes. Do not replace the canonical specification with an alternate document.

## Godot runtime

- This project uses the standard, non-.NET Godot runtime because its runtime code is GDScript and GLSL.
- The canonical Windows editor is `<repository-root>\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64.exe`.
- The canonical Windows automation executable is `<repository-root>\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`.
- The canonical macOS editor and automation executable is `<repository-root>/.tools/godot/4.7.2/Godot.app/Contents/MacOS/Godot`.
- Do not use `Godot_mono.exe`, `Godot_mono_console.exe`, a Downloads-folder copy, a Program Files copy, `/Applications/Godot.app`, or an executable discovered through `PATH` for project automation.
- Each checked-in automation script must resolve the canonical executable for the current host from the repository root.
- Each checked-in automation script must fail if the canonical executable is missing, reports a Mono/.NET build, or reports a version other than Godot 4.7.2 stable.
- Do not add a runtime fallback lookup path or an executable override parameter.
- If the project deliberately adopts C# later, change this contract, the checked-in scripts, export templates, and verification together.

## No fallbacks as fixes

Systems must work through explicit contracts. Fix invalid state or missing dependencies at the source; do not add permissive defaults, alternate lookup paths, silent recovery, or renderer substitutions.
