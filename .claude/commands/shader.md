---
description: Create, debug, or get help with Flutter fragment shaders
argument-hint: [task] [description]
---

# Flutter Shader Assistant

Help with Flutter fragment shader development based on the request: **$ARGUMENTS**

## Your Task

Analyze what the user needs and take the appropriate action:

### If creating a new shader:
1. Design the shader spec (uniforms, inputs, effect type)
2. Use the patterns from @.claude/skills/flutter-shader/TEMPLATES.md as a base
3. Create the .frag file in `/shaders/`
4. Create the corresponding Dart CustomPainter in `/lib/shaders/`
5. Update `pubspec.yaml` to declare the new shader
6. Provide usage example

### If debugging a shader issue:
1. Check @.claude/skills/flutter-shader/REFERENCE.md troubleshooting section
2. Common issues:
   - Black screen → Check fragColor is written, verify coordinate normalization
   - Wrong colors → Audit uniform index mapping (vec2 = 2 floats!)
   - Texture not showing → Remember samplers have SEPARATE index space
3. Provide the fix with explanation

### If explaining concepts:
1. Reference the @.claude/skills/flutter-shader/SKILL.md for core concepts
2. Provide clear examples with code

### If optimizing:
1. Check for shader instance reuse
2. Verify FragmentProgram precaching
3. Suggest SkSL warm-up if targeting Skia backend

## Key Rules (Always Follow)
- Use `FlutterFragCoord()` not `gl_FragCoord`
- Include the required header: `#version 460 core` + `#include <flutter/runtime_effect.glsl>`
- Samplers use separate index space from float uniforms
- Add OpenGLES Y-flip fix when sampling engine textures
