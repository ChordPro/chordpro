// Shared page behaviour: the Contents sheet on narrow docs pages.
(function () {
  var btn = document.querySelector(".bar-menu");
  var nav = document.getElementById("docs-nav");
  if (!btn || !nav) return;

  function set(open) {
    document.body.classList.toggle("nav-open", open);
    btn.setAttribute("aria-expanded", open ? "true" : "false");
    btn.textContent = open ? "Close" : "Contents";
    if (open) {
      var here = nav.querySelector("[aria-current]") || nav.querySelector("a");
      if (here) here.focus({ preventScroll: false });
    }
  }
  btn.addEventListener("click", function () { set(!document.body.classList.contains("nav-open")); });
  nav.addEventListener("click", function (e) { if (e.target.closest("a")) set(false); });
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && document.body.classList.contains("nav-open")) { set(false); btn.focus(); }
  });
  window.addEventListener("pageshow", function () { set(false); });
  matchMedia("(min-width: 900px)").addEventListener("change", function () { set(false); });
})();
