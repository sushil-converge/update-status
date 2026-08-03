/**
 * Demo status page — Cloudflare Worker.
 *
 * Serves the rendered demo-status HTML at an unguessable slug, in the same shape as the
 * Boardly links (https://<name>.workers.dev/b/<slug>).
 *
 * SECURITY MODEL, stated plainly: the slug is the only thing protecting this page. That is
 * obscurity, not access control. It is not indexed and not guessable, but anyone with the
 * link has it forever. Deploy with PUBLIC_MODE="redacted" if the audience is wider than the
 * people who already know the client's name.
 */

import { HTML_FULL, HTML_REDACTED, META } from "./status.gen.js";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const slug = env.SLUG || "";
    const path = url.pathname.replace(/\/+$/, ""); // tolerate a trailing slash

    const notFound = () =>
      new Response("Not found", {
        status: 404,
        headers: { "content-type": "text/plain; charset=utf-8", ...noIndex() },
      });

    if (!slug) return notFound();

    // Only /b/<slug> is served. Everything else — including the bare root — 404s, so the
    // hostname alone reveals nothing.
    if (path !== `/b/${slug}`) return notFound();

    const redacted = (env.PUBLIC_MODE || "full") === "redacted";
    const body = redacted ? HTML_REDACTED : HTML_FULL;

    // ?json returns the metadata block only — never the full status source, which carries
    // the same client detail as the page.
    if (url.searchParams.has("json")) {
      return new Response(JSON.stringify({ ...META, mode: redacted ? "redacted" : "full" }, null, 2), {
        headers: { "content-type": "application/json; charset=utf-8", ...noIndex(), ...cache() },
      });
    }

    return new Response(body, {
      headers: { "content-type": "text/html; charset=utf-8", ...noIndex(), ...cache() },
    });
  },
};

function noIndex() {
  return {
    "x-robots-tag": "noindex, nofollow, noarchive",
    "referrer-policy": "no-referrer",
    "x-content-type-options": "nosniff",
  };
}

function cache() {
  // Short cache: the page changes daily during the sprint, and a stale status page is
  // worse than a slow one.
  return { "cache-control": "public, max-age=120, must-revalidate" };
}
