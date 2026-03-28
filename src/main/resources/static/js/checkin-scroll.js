/**
 * Subtle scroll-triggered reveals. Respects prefers-reduced-motion.
 */
(function () {
  'use strict';

  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var nodes = document.querySelectorAll('[data-reveal], [data-stagger]');

  if (!nodes.length) return;

  if (reduce) {
    nodes.forEach(function (el) {
      el.classList.add('is-visible');
    });
    return;
  }

  var io = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.classList.add('is-visible');
        io.unobserve(entry.target);
      });
    },
    { rootMargin: '0px 0px -6% 0px', threshold: 0.08 }
  );

  nodes.forEach(function (el) {
    io.observe(el);
  });
})();
