/* Background video. Every <video data-bg> plays muted, inline and on a loop,
   on phones as well as desktops, and only while it is on screen. A phone that
   refuses autoplay (an iPhone in Low Power Mode does) starts it on the first
   tap. A [data-video-toggle] button pauses and resumes the video it controls,
   which is the pause control WCAG 2.2.2 asks for. */
(function () {
  var vids = [].slice.call(document.querySelectorAll("video[data-bg]"));
  if (!vids.length) return;
  var seen = new Map();

  function play(v) {
    if (v.dataset.held === "1") return;
    v.muted = true; v.defaultMuted = true; v.playsInline = true;
    var p = v.play();
    if (p && p.catch) p.catch(function () {});
  }

  vids.forEach(function (v) {
    // On a phone the first <source> (the desktop cut, gated by media) does not
    // match, so the phone crop plays; give it the poster cut the same way
    var first = v.querySelector("source[media]");
    if (v.dataset.posterM && first && window.matchMedia && !matchMedia(first.media).matches) v.poster = v.dataset.posterM;
    v.muted = true;
    v.setAttribute("muted", "");
    v.setAttribute("playsinline", "");
    v.setAttribute("webkit-playsinline", "");
    v.addEventListener("playing", function () { v.classList.add("is-playing"); });
    seen.set(v, false);
  });

  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        seen.set(e.target, e.isIntersecting);
        if (e.isIntersecting) play(e.target); else e.target.pause();
      });
    }, { rootMargin: "120px 0px", threshold: 0.01 });
    vids.forEach(function (v) { io.observe(v); });
  } else {
    vids.forEach(function (v) { seen.set(v, true); play(v); });
  }

  // Autoplay refused: a real tap is a user gesture, and play() inside it works
  function wake() { vids.forEach(function (v) { if (v.paused && seen.get(v)) play(v); }); }
  ["touchend", "click", "keydown"].forEach(function (t) { document.addEventListener(t, wake, { passive: true }); });
  document.addEventListener("visibilitychange", function () { if (!document.hidden) wake(); });

  [].slice.call(document.querySelectorAll("[data-video-toggle]")).forEach(function (b) {
    var v = document.getElementById(b.getAttribute("aria-controls"));
    if (!v) return;
    function sync() {
      var off = v.dataset.held === "1";
      b.setAttribute("aria-pressed", off ? "true" : "false");
      b.setAttribute("aria-label", off ? (b.dataset.play || "Play the background video") : (b.dataset.pause || "Pause the background video"));
      b.classList.toggle("is-held", off);
    }
    b.addEventListener("click", function (e) {
      e.stopPropagation();
      if (v.dataset.held === "1") { v.dataset.held = ""; play(v); } else { v.dataset.held = "1"; v.pause(); }
      sync();
    });
    sync();
  });
})();
