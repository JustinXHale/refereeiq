const functions = require('firebase-functions');
const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

exports.chatWithGPT = functions
  .runWith({ runtime: "nodejs18", platform: "gcfv1" })
  .https
  .onRequest(async (req, res) => {
    const userMessage = req.body?.message;

    // 🟡 Debug log — will show in firebase functions:log
    console.log("Received userMessage:", userMessage);

    // Validate input early
    if (typeof userMessage !== 'string' || userMessage.trim().length === 0) {
      console.error('Invalid or missing message:', req.body);
      return res.status(400).json({ error: "Invalid request: 'message' must be a non-empty string" });
    }

    try {
      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [{ role: "user", content: userMessage }],
        max_tokens: 300,
      });

      res.json({ reply: response.choices[0].message.content });
    } catch (error) {
      console.error('OpenAI API error:', error, 'Request body:', req.body);
      res.status(500).send("Error communicating with OpenAI");
    }
  });
