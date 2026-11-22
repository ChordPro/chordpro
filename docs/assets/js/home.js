// Home page motion. The page is complete without this file: it only adds
// the movement between states that are already in the markup. Nothing runs
// when the reader asks for reduced motion.
(function () {
  var root = document.documentElement;
  var reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reduce) {
    var v = document.getElementById("hero-video");
    if (v) { v.dataset.held = "1"; v.removeAttribute("autoplay"); }
    return;
  }
  root.classList.add("moving");

  var desk = matchMedia("(min-width: 900px)");
  var clamp = function (x) { return x < 0 ? 0 : x > 1 ? 1 : x; };
  var ease = function (t) { return 1 - Math.pow(1 - t, 3); };
  var barH = function () { return parseFloat(getComputedStyle(root).getPropertyValue("--bar-h")) || 64; };

  // Hero: the chords drop onto their syllables once the face has loaded.
  var lead = document.querySelector(".lead-set");
  if (lead) {
    lead.querySelectorAll(".ch").forEach(function (c, i) { c.style.transitionDelay = 250 + i * 120 + "ms"; });
    (document.fonts ? document.fonts.ready : Promise.resolve()).then(function () {
      requestAnimationFrame(function () { requestAnimationFrame(function () { lead.classList.add("is-on"); }); });
    });
  }

  // The lift: each chord leaves its brackets in the typed line and lands
  // over its syllable in the set line. Positions are measured, not guessed,
  // so any line from Landing.md works.
  var lift = document.querySelector("[data-lift]");
  var pairs = [], brackets = [], steps = [], page = null;
  var liftPlayed = false, liftTimer = 0;

  function measure() {
    pairs.forEach(function (p) { p.to.style.transform = ""; });
    pairs.forEach(function (p) {
      var a = p.from.getBoundingClientRect(), b = p.to.getBoundingClientRect();
      var fa = parseFloat(getComputedStyle(p.from).fontSize), fb = parseFloat(getComputedStyle(p.to).fontSize);
      p.dx = a.left - b.left;
      p.dy = (a.top + a.height / 2) - (b.top + b.height / 2);
      p.s = fa / fb;
    });
  }

  function drawLift(prog) {
    // prog 0..1 across the whole scene
    var t = clamp((prog - 0.1) / 0.42);
    var n = pairs.length, lag = 0.07;
    pairs.forEach(function (p, i) {
      var ti = ease(clamp((t - i * lag) / (1 - lag * (n - 1))));
      var k = 1 - ti;
      p.to.style.transform = "translate(" + (p.dx * k).toFixed(2) + "px," + (p.dy * k).toFixed(2) + "px) scale(" + (p.s + (1 - p.s) * ti).toFixed(4) + ")";
    });
    brackets.forEach(function (b) { b.style.opacity = (1 - clamp(t * 4)).toFixed(3); });
    // the typed words leave before the set words arrive, so the two lines
    // never sit on top of each other; the chords carry the eye across
    lift.style.setProperty("--b", (1 - clamp(t * 2.6)).toFixed(3));
    lift.style.setProperty("--a", clamp((t - 0.5) / 0.5).toFixed(3));
    // the printed page waits low in the stage like a sheet in a printer
    // tray, and rises into full view at step three
    var u = ease(clamp((prog - 0.56) / 0.3));
    if (page) {
      page.style.opacity = (0.55 + 0.45 * u).toFixed(3);
      page.style.transform = "translateY(" + ((1 - u) * 62).toFixed(2) + "%)";
    }
    var active = prog < 0.1 ? 0 : prog < 0.56 ? 1 : 2;
    steps.forEach(function (s, i) { s.classList.toggle("is-on", i === active); });
  }

  function liftProgress() {
    var r = lift.getBoundingClientRect();
    var run = lift.offsetHeight - (innerHeight - barH());
    return run > 0 ? clamp((barH() - r.top) / run) : 1;
  }

  function playLiftOnce() {
    if (liftPlayed) return;
    liftPlayed = true;
    var start = performance.now(), dur = 3200;
    (function tick(now) {
      var p = clamp((now - start) / dur);
      drawLift(p);
      if (p < 1) liftTimer = requestAnimationFrame(tick);
    })(start);
  }

  if (lift) {
    lift.querySelectorAll(".lift-line").forEach(function (line) {
      var from = line.querySelectorAll(".lift-src .ch"), to = line.querySelectorAll(".lift-set .ch");
      from.forEach(function (f, i) { if (to[i]) pairs.push({ from: f, to: to[i] }); });
    });
    brackets = [].slice.call(lift.querySelectorAll(".lift-src .sb"));
    steps = [].slice.call(lift.querySelectorAll(".lift-steps li"));
    page = lift.querySelector(".lift-page");
    if ("IntersectionObserver" in window) {
      new IntersectionObserver(function (es) {
        es.forEach(function (e) { if (e.isIntersecting && !desk.matches) playLiftOnce(); });
      }, { threshold: 0.35 }).observe(lift.querySelector(".lift-stage"));
    }
  }

  // Styles: on a wide screen the row of pages moves sideways while the
  // band holds still; on a phone it is a native swipe.
  var rail = document.querySelector("[data-rail]");
  var track = rail && rail.querySelector("[data-rail-track]");
  var railRun = 0, RAIL_PACE = 0.5;
  function sizeRail() {
    if (!rail) return;
    if (desk.matches) {
      rail.classList.add("is-pinned");
      track.style.transform = "";
      var pin = rail.querySelector(".styles-pin");
      railRun = Math.max(0, track.scrollWidth - pin.clientWidth);
      // the row moves faster than the page scrolls, so the band does not
      // hold the reader longer than it needs to
      rail.style.height = (innerHeight - barH() + railRun * RAIL_PACE) + "px";
    } else {
      rail.classList.remove("is-pinned");
      rail.style.height = "";
      track.style.transform = "";
    }
  }
  function drawRail() {
    if (!rail || !desk.matches) return;
    var r = rail.getBoundingClientRect();
    var p = railRun > 0 ? clamp((barH() - r.top) / (railRun * RAIL_PACE)) : 0;
    track.style.transform = "translate3d(" + (-p * railRun).toFixed(1) + "px,0,0)";
  }

  // On a phone the row is a native swipe; the bar under it shows where you are.
  var bar = rail && rail.querySelector(".rail-bar span");
  if (bar) {
    var syncBar = function () {
      var max = track.scrollWidth - track.clientWidth;
      var w = track.clientWidth / track.scrollWidth;
      bar.style.width = (w * 100).toFixed(1) + "%";
      bar.style.transform = "translateX(" + (max > 0 ? (track.scrollLeft / max) * (1 / w - 1) * 100 : 0).toFixed(1) + "%)";
    };
    track.addEventListener("scroll", syncBar, { passive: true });
    addEventListener("resize", syncBar);
    syncBar();
  }

  // Molly Malone's page is uncovered from the bottom when it arrives. The
  // observer watches the parent: a fully clipped element reports no area.
  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        if (!e.isIntersecting) return;
        e.target.querySelectorAll("[data-reveal]").forEach(function (el) { el.classList.add("is-in"); });
        io.unobserve(e.target);
      });
    }, { threshold: 0.15 });
    document.querySelectorAll("[data-reveal]").forEach(function (el) { io.observe(el.parentElement); });
  } else {
    document.querySelectorAll("[data-reveal]").forEach(function (el) { el.classList.add("is-in"); });
  }

  var ticking = false;
  function frame() {
    ticking = false;
    if (lift && desk.matches) drawLift(liftProgress());
    drawRail();
  }
  function onScroll() { if (!ticking) { ticking = true; requestAnimationFrame(frame); } }
  function layout() {
    cancelAnimationFrame(liftTimer);
    if (lift) { measure(); if (desk.matches) drawLift(liftProgress()); else drawLift(liftPlayed ? 1 : 0); }
    if (liftPlayed && !desk.matches) drawLift(1);
    sizeRail();
    drawRail();
  }

  var ready = Promise.all([
    document.fonts ? document.fonts.ready : null,
    new Promise(function (r) { if (document.readyState === "complete") r(); else addEventListener("load", r, { once: true }); })
  ]);
  ready.then(function () {
    layout();
    addEventListener("scroll", onScroll, { passive: true });
    var rt;
    addEventListener("resize", function () { clearTimeout(rt); rt = setTimeout(layout, 120); });
    desk.addEventListener("change", layout);
  });
})();
