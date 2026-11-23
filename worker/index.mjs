import { packageLabelResponse } from "./package-labels.mjs";

function upstreamURL(url) {
  if (/^\/v1\/food\/[1-9]\d{0,9}$/.test(url.pathname)) {
    return new URL("https://api.nal.usda.gov/fdc" + url.pathname);
  }
  if (url.pathname !== "/v1/foods/search") return null;

  const query = url.searchParams.get("query")?.trim();
  if (!query || query.length > 200) return null;

  const upstream = new URL("https://api.nal.usda.gov/fdc/v1/foods/search");
  upstream.searchParams.set("query", query);
  upstream.searchParams.set("pageSize", "40");
  if (url.searchParams.get("dataType") === "Branded") {
    upstream.searchParams.set("dataType", "Branded");
  }
  return upstream;
}

export default {
  async fetch(request, env) {
    if (!env.USDA_API_KEY || !env.DIETIC_ACCESS_TOKEN) return new Response(null, { status: 503 });
    if (request.headers.get("Authorization") !== "Bearer " + env.DIETIC_ACCESS_TOKEN) {
      return new Response(null, { status: 401 });
    }
    if (request.method !== "GET") return new Response(null, { status: 405, headers: { Allow: "GET" } });

    const requestURL = new URL(request.url);
    const label = packageLabelResponse(requestURL);
    if (label) return label;

    const url = upstreamURL(requestURL);
    if (!url) return new Response(null, { status: 400 });

    try {
      const result = await fetch(url, {
        headers: { "X-Api-Key": env.USDA_API_KEY, Accept: "application/json", "User-Agent": "Dietic/1.0" },
        redirect: "manual",
      });
      if (!result.ok) {
        const status = [404, 429].includes(result.status) ? result.status : 502;
        return new Response(null, { status, headers: { "X-Upstream-Status": String(result.status) } });
      }
      return new Response(result.body, {
        headers: { "Content-Type": "application/json", "Cache-Control": "private, no-store" },
      });
    } catch {
      return new Response(null, { status: 502 });
    }
  },
};
