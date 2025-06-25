const functions = require('firebase-functions');
const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

exports.chatWithGPT = functions
  .runWith({ runtime: "nodejs18", platform: "gcfv1" })
  .https
  .onRequest(async (req, res) => {
    const userMessages = req.body?.messages;

    // 🟡 Debug log — will show in firebase functions:log
    console.log("Received userMessages:", userMessages);

    // Validate input early
    if (!Array.isArray(userMessages) || userMessages.length === 0) {
      console.error('Invalid or missing messages array:', req.body);
      return res.status(400).json({ error: "Invalid request: 'messages' must be a non-empty array" });
    }

    try {
      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: `You are Sofia, an expert Rugby Union referee coach.
You help users deeply understand rugby laws, referee decisions, and positioning.
When users ask vague or broad questions, you ask clarifying follow-up questions before answering.
You only provide final answers after gathering enough context.
You never answer questions unrelated to rugby.
You reference rugby laws when possible.
Keep your answers short and clear, like a text message.`,
          },
          ...userMessages
        ],
        max_tokens: 300,
        temperature: 0.6,
      });

      res.json({ reply: response.choices[0].message.content });
    } catch (error) {
      console.error('OpenAI API error:', error, 'Request body:', req.body);
      res.status(500).send("Error communicating with OpenAI");
    }
  });
