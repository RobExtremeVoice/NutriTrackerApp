/**
 * NutriTrack Pro — OpenAI proxy with Lambda Response Streaming
 * Runtime: nodejs20.x | Function URL InvokeMode: RESPONSE_STREAM
 *
 * Handles both:
 *  - Vision / text analysis  (stream: false) → returns full JSON
 *  - Chat completions        (stream: true)  → pipes SSE chunks through
 *
 * The `awslambda` global is injected automatically by the Lambda runtime.
 */

export const handler = awslambda.streamifyResponse(
  async (event, responseStream, _context) => {
    const apiKey = process.env.OPENAI_API_KEY;

    if (!apiKey) {
      awslambda.HttpResponseStream.from(responseStream, {
        statusCode: 500,
        headers: { "Content-Type": "application/json" },
      }).end(JSON.stringify({ error: "OPENAI_API_KEY not configured" }));
      return;
    }

    // Parse request body sent by the iOS app
    let body;
    try {
      body = JSON.parse(event.body ?? "{}");
    } catch {
      awslambda.HttpResponseStream.from(responseStream, {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
      }).end(JSON.stringify({ error: "Invalid JSON body" }));
      return;
    }

    // Forward to OpenAI — key stays server-side
    const upstreamRes = await fetch(
      "https://api.openai.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
      }
    );

    const isStreaming = body.stream === true;

    // Attach HTTP response metadata (status + headers) to the Lambda stream
    const outStream = awslambda.HttpResponseStream.from(responseStream, {
      statusCode: upstreamRes.status,
      headers: {
        "Content-Type": isStreaming
          ? "text/event-stream"
          : "application/json",
        "Cache-Control": "no-cache",
      },
    });

    // Pipe OpenAI response → Lambda response stream (works for both modes)
    for await (const chunk of upstreamRes.body) {
      outStream.write(chunk);
    }
    outStream.end();
  }
);
