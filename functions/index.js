const functions = require('firebase-functions');
const { OpenAI } = require('openai');

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

exports.chatWithGPT = functions
  .runWith({ runtime: "nodejs18", platform: "gcfv1" })
  .https
  .onRequest(async (req, res) => {
    const userMessage = req.body?.message;

    // 🟡 Debug log
    console.log("Received userMessage:", userMessage);

    // Validate input early
    if (typeof userMessage !== 'string' || userMessage.trim().length === 0) {
      console.error('Invalid or missing message:', req.body);
      return res.status(400).json({ error: "Invalid request: 'message' must be a non-empty string" });
    }

    try {
      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content:
              "You are Sofia, an expert rugby union referee coach helping users deeply understand rugby laws and decisions. " +
              "When a user asks a vague or broad question, first ask clarifying follow-up questions before giving an answer. " +
              "Only provide final answers after gathering enough context. " +
              "Do not answer questions unrelated to rugby union. Politely explain that you only answer rugby union questions. " +
              "Link responses to relevant laws or guidelines when possible. " +
              "Keep answers short, clear, and suitable for a messaging format.",
          },
          { role: "user", content: userMessage },
        ],
        temperature: 0.55,
        max_tokens: 300,
      });

      const reply = response.choices[0]?.message?.content?.trim();
      console.log("AI reply:", reply);

      res.json({ reply: reply });
    } catch (error) {
      console.error('OpenAI API error:', error, 'Request body:', req.body);
      res.status(500).send("Error communicating with OpenAI");
    }
  });
