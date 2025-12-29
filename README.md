# Festive Shader Journey

## A Claude Code Skills Showcase

This project demonstrates the power of **Claude Code Skills** — a way to teach Claude specialized knowledge that it can apply automatically. The entire festive shader application you see here was built by Claude using a custom skill for Flutter fragment shader development.

**The workflow was simple:**
1. Create a skill that teaches Claude about Flutter shaders
2. Ask Claude to "create a festive shader showcase"
3. Claude automatically applied the skill knowledge to build 7 complete GLSL shaders, Dart integration code, and a polished app

> No manual shader coding required. Just a skill + a prompt = a complete GPU-powered application.

---

## What's Inside

Seven beautiful shader scenes that auto-play as a journey from Christmas to New Year:

| Scene | Effect | Interaction |
|-------|--------|-------------|
| **Snowfall** | Peaceful winter night with falling snow | Mouse creates warm glow, shake adds wind |
| **Aurora** | Northern lights dancing across the sky | Hold space (hiss) intensifies the aurora |
| **Matrix** | Developer-style terminal rain | Mouse reveals "HAPPY 2026" message |
| **Countdown** | Epic 10-9-8... countdown with energy rings | Mouse creates ripples, hiss adds glow |
| **Fireworks** | Explosive celebration! | Tap anywhere to launch fireworks |
| **Celebration** | 2026 party with confetti & disco | Shake adds bass effect |
| **Finale** | Cyberpunk "Happy Coding 2026" neon text | Shake adds glitch effects |

---

## The Skill That Built This

<details>
<summary><strong>Click to expand the full skill prompt</strong></summary>

This is the comprehensive skill document that was created to teach Claude about Flutter shader development:

---

### Skill: Develop Flutter Fragment Shaders (GLSL) end-to-end

This is a comprehensive, agent-oriented "playbook" for building, integrating, debugging, and shipping Flutter fragment shaders using Flutter's FragmentProgram / FragmentShader APIs.

Primary reference: Flutter's official "Writing and using fragment shaders" guide.

---

#### 1) What Flutter shader work means (scope)

**Supported shader type**
- Flutter supports fragment shaders (pixel shaders). It does not support vertex shaders in the SDK's shader pipeline.

**Core runtime objects**
- `FragmentProgram`: a compiled shader asset that can create shader instances.
- `FragmentShader`: an instance with a particular set of uniforms (float values + samplers) that you bind into `Paint.shader`, or sometimes into `ImageFilter.shader` (Impeller-only).

**Backends (why behavior differs)**
- Flutter runs with Skia or Impeller backends depending on platform/config. Both support custom shaders, but some APIs differ (notably `ImageFilter.shader` is Impeller-only).

---

#### 2) Minimum prerequisites for an agent

The agent should know / be able to derive:
- GLSL basics: uniform, vec2/3/4, sampler2D, texture(), coordinate normalization, time-driven animation.
- Flutter rendering primitives: CustomPainter, Canvas, Paint.shader, ShaderMask, ImageFiltered/BackdropFilter patterns.
- Performance concerns: shader compilation jank + mitigation strategies.

---

#### 3) Project setup (the "never forget" checklist)

**A. Put shader files under an assets folder**

Typical layout:
```
/shaders
  my_effect.frag
/lib
  shaders/
  widgets/
```

**B. Declare shaders in pubspec.yaml**

Flutter compiles declared .frag files and bundles them like assets.

```yaml
flutter:
  shaders:
    - shaders/my_effect.frag
```

**C. Hot reload behavior**
- In debug, editing a shader triggers recompilation and updates on hot reload/hot restart.

---

#### 4) Shader authoring rules (Flutter-specific constraints)

Start with the canonical header + include:

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;
```

**Coordinate access (important)**

Use `FlutterFragCoord()` (not `gl_FragCoord`) for the current fragment position.

**Common limitations (don't fight them)**

Flutter's shader pipeline restricts features; key ones include:
- Only `sampler2D` is supported (no samplerCube, etc.)
- Only the two-argument `texture(sampler, uv)` form
- No extra varying inputs
- No UBO/SSBO
- Unsigned ints and booleans not supported

**Impeller + OpenGLES texture Y-flip (when sampling engine textures)**

If you use `ImageFilter.shader` / BackdropFilter input textures, you may need to un-flip UVs on OpenGLES:

```glsl
vec2 uv = FlutterFragCoord().xy / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
```

---

#### 5) Uniforms + samplers: how indexing actually works

**Rule 1: float uniforms are indexed in declaration order**

float / vec2 / vec3 / vec4 are set via `setFloat(index, value)` in the order declared.

**Rule 2: samplers use a separate index space**

sampler2D uniforms are set via `setImageSampler(samplerIndex, image)` and do not consume float indices.

**Example (pay attention to indexing):**

```glsl
uniform float uScale;
uniform sampler2D uTexture;
uniform vec2 uMagnitude;
uniform vec4 uColor;
```

```dart
shader.setFloat(0, 23); // uScale
shader.setFloat(1, 114); // uMagnitude.x
shader.setFloat(2, 83);  // uMagnitude.y
shader.setFloat(3, r); shader.setFloat(4, g); shader.setFloat(5, b); shader.setFloat(6, a);
shader.setImageSampler(0, image); // uTexture (samplers start at 0)
```

---

#### 6) Loading and using shaders in Flutter (canonical patterns)

**A. Load a program from an asset**

```dart
final program = await FragmentProgram.fromAsset('shaders/my_effect.frag');
```

**B. Create a shader instance and bind uniforms**

```dart
final shader = program.fragmentShader();
shader.setFloat(0, timeSeconds);
shader.setFloat(1, width);
shader.setFloat(2, height);
```

Then draw with it:

```dart
canvas.drawRect(rect, Paint()..shader = shader);
```

**C. Apply as an ImageFilter (Impeller-only)**

Flutter provides `ImageFilter.shader(shader)` for ImageFiltered / BackdropFilter, but it is only supported by Impeller.

---

#### 7) Recommended "agent workflow" (from idea → shipped effect)

**Step 1 — Translate effect into a shader spec**

Write a mini-spec like:
- Inputs (uniforms): u_time, u_size, parameters (strength, color, frequency, seed)
- Whether it samples a texture (sampler2D) or is purely procedural
- Where it's applied: full-screen rect, clipped region, mask, backdrop, etc.

**Step 2 — Create a stable uniform contract**

Use a consistent uniform naming & ordering convention per shader:
1. `uniform vec2 u_size;` (or pass as two floats)
2. `uniform float u_time;`
3. Effect params…

Then mirror that order in Dart with constants/enums for indices.

**Step 3 — Implement integration wrapper (reusable widget)**

Typical wrapper choices:
- CustomPainter for drawing into a Canvas
- ShaderMask for masking child content
- BackdropFilter / ImageFiltered for post-processing (Impeller-only)

**Step 4 — Performance hardening**
- Reuse FragmentShader where possible instead of creating a new instance each frame
- On Skia, shader compilation can be expensive at runtime; precache FragmentProgram before an animation starts
- If you hit "first animation jank" on Skia, apply SkSL warm-up capture & bundle workflow
- For classic (non-custom) jank mitigation, ShaderWarmUp exists to pre-trigger shader compilation
- Consider Impeller where available: it precompiles engine shaders at build-time to reduce runtime compilation stalls

**Step 5 — Cross-platform validation**
- Test on at least: Android (OpenGLES/Vulkan differences), iOS (Metal), and Web if you target it.
- Web renderer choice matters; Flutter Web has multiple renderers (e.g., CanvasKit vs skwasm) and build modes.

---

#### 8) Debugging & introspection tactics

**A. "Black screen / nothing renders"**

Common causes:
- `fragColor` never written
- Wrong coordinate normalization (e.g., using raw FlutterFragCoord without dividing by size)
- Uniform indices don't match declaration order (especially around samplers)

**B. Uniform layout auditing (deep debugging)**

Flutter's shader pipeline can output reflection data; use `impellerc` + `flatc` to inspect uniforms/offsets.

**C. Backend-specific runtime error**
- If using `ImageFilter.shader` on non-Impeller backend, Flutter warns it throws.

---

#### 9) Concrete templates (copy/paste starter kits)

**Template A — Pure procedural full-rect shader**

shaders/wave.frag:
```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2  u_size;
uniform float u_time;
uniform float u_amp;
uniform float u_freq;

void main() {
  vec2 p = FlutterFragCoord().xy / u_size;
  float y = sin((p.x * u_freq + u_time) * 6.28318) * u_amp;
  float v = smoothstep(0.02, 0.0, abs(p.y - (0.5 + y)));
  fragColor = vec4(vec3(v), 1.0);
}
```

**Template B — Post-processing via BackdropFilter (Impeller-only)**

Use the pattern: `BackdropFilter(filter: ImageFilter.shader(shader))` and clip to constrain area.

---

#### 10) Reference material (high-signal)

Use these as the agent's canonical sources:
- Flutter official guide: "Writing and using fragment shaders"
- Dart API: FragmentProgram docs
- Flutter performance: Impeller overview
- SkSL warm-up workflow (Skia backend)
- Dart API: ShaderWarmUp
- Web renderer overview
- Utility package: flutter_shaders

</details>

---

## Using Claude Code for Shaders

This project includes Claude Code integrations to help you work with Flutter shaders:

### The `/shader` Command

Quick command for shader tasks:

```bash
/shader create a plasma effect with rainbow colors
/shader debug why my shader shows black
/shader explain how uniform indexing works
/shader optimize my fireworks shader for mobile
```

### The `shader-assistant` Agent

A specialized agent that automatically activates when you're working with shaders. It knows:
- How to create new shaders from effect descriptions
- How to debug common issues (black screen, wrong colors, texture problems)
- Flutter's uniform indexing rules (the #1 source of shader bugs!)
- Cross-platform considerations (Skia vs Impeller, OpenGLES Y-flip)

### The `flutter-shader` Skill

The core knowledge base in `.claude/skills/flutter-shader/`:
- `SKILL.md` — Complete development guide
- `TEMPLATES.md` — 6 copy-paste shader patterns
- `REFERENCE.md` — API docs & troubleshooting

---

## Controls

- **Mouse/Touch**: Move for position-based effects
- **Tap/Click**: Trigger scene-specific events
- **Hold Space**: "Hiss" effect (simulates audio input)
- **Arrow Keys**: "Shake" effect (simulates accelerometer)
- **Scene Chips**: Jump to any scene directly
- **Auto/Manual**: Toggle auto-progression

---

## Running

```bash
flutter run
```

Works best on:
- Desktop (macOS, Windows, Linux)
- iOS/Android (Impeller backend recommended)
- Web (CanvasKit renderer)

---

## Project Structure

```
.claude/
  skills/flutter-shader/     # The skill that taught Claude shaders
    SKILL.md                 # Core knowledge
    TEMPLATES.md             # Starter patterns
    REFERENCE.md             # API & troubleshooting
  commands/
    shader.md                # /shader command
  agents/
    shader-assistant.md      # Proactive shader agent

shaders/
  snowfall.frag              # Procedural snowflakes + aurora hint
  aurora.frag                # Northern lights with mountains
  matrix.frag                # Code rain with hidden message
  countdown.frag             # 7-segment countdown display
  fireworks.frag             # Particle explosions + city silhouette
  celebration.frag           # 2026 text + confetti + disco
  cyberpunk_ending.frag      # Neon "Happy Coding 2026" finale

lib/
  main.dart                  # App entry + splash screen
  shaders/
    shader_cache.dart        # Preloading & caching
  widgets/
    interaction_detector.dart # Mouse, tap, shake, hiss handling
  scenes/
    scene_painter.dart       # CustomPainter implementations
    festive_journey.dart     # Scene orchestration
```

---

## Technical Highlights

### Shader Techniques Used
- **Procedural noise** (FBM, gradient noise) for aurora & backgrounds
- **Particle systems** for snow, fireworks, confetti
- **SDF rendering** for countdown digits
- **Post-processing** patterns for matrix effect
- **Color space conversions** (HSV) for rainbow effects

### Flutter Integration Patterns
- `FragmentProgram.fromAsset()` with warm-up caching
- `FragmentShader` uniform binding with correct index mapping
- `CustomPainter` for efficient shader rendering
- Smooth scene transitions with `AnimationController`

### Uniform Convention
All shaders follow a consistent pattern:
```glsl
uniform vec2 u_size;    // indices 0-1
uniform float u_time;   // index 2
// ...scene-specific params
```

---

## For Developers

This project demonstrates:
1. How to write Flutter-compatible GLSL (use `FlutterFragCoord()`, not `gl_FragCoord`)
2. Proper uniform indexing (vec2 = 2 floats, samplers are separate)
3. Performance optimization via shader caching
4. Interactive shader parameters driven by user input
5. **How to create Claude Code skills for specialized domains**

### Try It Yourself

1. Clone this repo
2. Run `flutter run`
3. Use `/shader create [your effect]` to add new shaders
4. Check `.claude/skills/flutter-shader/` to see how the skill works
5. Adapt the skill pattern for your own specialized domains!

---

## Credits

Built by **[Moinsen Development](https://moinsen.dev)** using Claude Code.

> *Creative AI-powered development. Crazy ideas. Fast delivery. Decades of experience.*

At Moinsen Development, we specialize in **agentic AI coding** — turning ambitious visions into reality at lightning speed. We combine deep software engineering expertise with cutting-edge AI tools to deliver what others think is impossible.

This project showcases how Claude Code skills can encode specialized knowledge and enable Claude to build complete applications from high-level descriptions. The entire festive shader journey — from concept to polished app — was created in a single Claude Code session.

Made with GLSL, Flutter & Claude Code for the developer community.

**Happy Coding 2026!** 🚀
