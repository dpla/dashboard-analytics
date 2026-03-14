/**
 * Cloudflare Worker: analytics-dashboard.dp.la error interceptor
 *
 * Transparently proxies all requests to the origin. If the origin returns
 * a 5xx response OR is unreachable (timeout / 504), returns a styled
 * error page instead of Cloudflare's generic error page.
 *
 * Deploy route: analytics-dashboard.dp.la/*
 */

const ERROR_HTML = `<!DOCTYPE html>
<html>
<head>
  <title>An error occurred — DPLA Analytics Dashboard</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Roboto,
                   "Helvetica Neue", Helvetica, sans-serif;
      color: #515354;
      line-height: 1.25;
      display: flex;
      flex-direction: column;
      min-height: 100vh;
    }
    header {
      padding: 0 40px;
      background-color: #000;
      color: #fff;
      border-bottom: 3px solid #2c7da0;
    }
    header div { display: inline-block; margin: 16px 0; font-size: 16px; }
    main { flex: 1; }
    .heading {
      width: 100%;
      background-color: #f9f6f0;
      height: 80px;
      border-bottom: 1px solid #e9dec8;
      padding: 10px 40px;
    }
    h1 { margin: 10px 0; color: #000; font-size: 1.75em; line-height: 60px; }
    .body { padding: 40px; }
    .body p { margin-bottom: 16px; font-size: 1.1em; }
    .body a { color: #ad5c1d; text-decoration: none; }
    .body a:hover { text-decoration: underline; }
    .body ul { margin-left: 24px; color: #666; }
    .body ul li { margin-bottom: 8px; font-size: 1.05em; }
    footer {
      background-color: #273443;
      color: #dadfe0;
      padding: 20px 40px;
      margin-top: auto;
    }
    footer a, footer a:visited { color: #dadfe0; text-decoration: none; }
    footer a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <header>
    <div><span>DPLA Analytics Dashboard</span></div>
  </header>
  <main>
    <div class="heading"><h1>An error occurred.</h1></div>
    <div class="body">
      <p>Thanks for your patience while we work to fix this issue.</p>
      <p>Try one of these:</p>
      <ul>
        <li>Reload the page and try again</li>
        <li><a href="https://analytics-dashboard.dp.la/">Go to the Analytics Dashboard</a></li>
        <li>Email <a href="mailto:analytics-dashboard@dp.la">analytics-dashboard@dp.la</a> if the problem persists</li>
      </ul>
    </div>
  </main>
  <footer>
    <div>Your feedback is welcome at <a href="mailto:analytics-dashboard@dp.la">analytics-dashboard@dp.la</a></div>
  </footer>
</body>
</html>`;

addEventListener("fetch", (event) => {
  event.respondWith(
    handleRequest(event.request).catch(() => errorResponse(503))
  );
});

async function handleRequest(request) {
  const response = await fetch(request);
  if (response.status >= 500) {
    return errorResponse(response.status);
  }
  return response;
}

function errorResponse(status) {
  return new Response(ERROR_HTML, {
    status,
    headers: { "Content-Type": "text/html; charset=utf-8" },
  });
}
