const functions = require('firebase-functions');
const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

exports.chatWithGPT = functions
  .runWith({ runtime: "nodejs18", platform: "gcfv1" })
  .https
  .onRequest(async (req, res) => {
    const userMessage = req.body.message;

    try {
      const response = await openai.chat.completions.create({
        model: "gpt-4o", // or "gpt-3.5-turbo"
        messages: [{ role: "user", content: userMessage }],
      });

      res.json({ reply: response.choices[0].message.content });
    } catch (error) {
      console.error(error);
      res.status(500).send("Error communicating with OpenAI");
    }
  });
