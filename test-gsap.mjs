import { gsap } from "gsap";

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`✓ ${name}`);
    passed++;
  } catch (e) {
    console.log(`✗ ${name}: ${e.message}`);
    failed++;
  }
}

function assert(condition, msg) {
  if (!condition) throw new Error(msg);
}

// 1. GSAP s'importe correctement
test("GSAP est importé", () => {
  assert(gsap !== undefined, "gsap est undefined");
  assert(typeof gsap.to === "function", "gsap.to n'est pas une fonction");
  assert(typeof gsap.from === "function", "gsap.from n'est pas une fonction");
  assert(typeof gsap.fromTo === "function", "gsap.fromTo n'est pas une fonction");
  assert(typeof gsap.timeline === "function", "gsap.timeline n'est pas une fonction");
});

// 2. Version disponible
test("Version GSAP disponible", () => {
  assert(typeof gsap.version === "string", "version n'est pas une string");
  assert(gsap.version.startsWith("3."), `version inattendue: ${gsap.version}`);
  console.log(`   → version: ${gsap.version}`);
});

// 3. gsap.to() crée un tween valide
test("gsap.to() crée un tween", () => {
  const obj = { x: 0, y: 0 };
  const tween = gsap.to(obj, { x: 100, y: 50, duration: 1 });
  assert(tween !== undefined, "tween est undefined");
  assert(typeof tween.kill === "function", "tween.kill n'est pas disponible");
  tween.kill();
});

// 4. gsap.from() crée un tween valide
test("gsap.from() crée un tween", () => {
  const obj = { x: 100 };
  const tween = gsap.from(obj, { x: 0, duration: 0.5 });
  assert(tween !== undefined, "tween est undefined");
  tween.kill();
});

// 5. gsap.fromTo() fonctionne
test("gsap.fromTo() crée un tween", () => {
  const obj = { opacity: 0 };
  const tween = gsap.fromTo(obj, { opacity: 0 }, { opacity: 1, duration: 1 });
  assert(tween !== undefined, "tween est undefined");
  tween.kill();
});

// 6. timeline() fonctionne
test("gsap.timeline() crée une timeline", () => {
  const tl = gsap.timeline();
  const obj = { x: 0 };
  tl.to(obj, { x: 100, duration: 0.5 });
  tl.to(obj, { x: 0, duration: 0.5 });
  assert(tl.totalDuration() > 0, "durée totale = 0");
  console.log(`   → durée totale: ${tl.totalDuration()}s`);
  tl.kill();
});

// 7. gsap.set() applique immédiatement
test("gsap.set() applique les valeurs immédiatement", () => {
  const obj = { x: 0, opacity: 1 };
  gsap.set(obj, { x: 200, opacity: 0.5 });
  assert(obj.x === 200, `x attendu 200, reçu ${obj.x}`);
  assert(obj.opacity === 0.5, `opacity attendu 0.5, reçu ${obj.opacity}`);
});

// 8. Easing disponible
test("Easings disponibles", () => {
  assert(gsap.parseEase !== undefined, "parseEase manquant");
  const ease = gsap.parseEase("power2.out");
  assert(typeof ease === "function", "ease n'est pas une fonction");
});

console.log(`\n${passed + failed} tests — ${passed} passés, ${failed} échoués`);
if (failed > 0) process.exit(1);
