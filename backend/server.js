require('dotenv').config();

const express = require("express");
const cors = require("cors");
const OpenAI = require("openai");

const app = express();

app.use(cors());
app.use(express.json());

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

app.post("/translate", async (req, res) => {
  try {
    const { text, from, to } = req.body;

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "You are a translator. Translate exactly and naturally.",
        },
        {
          role: "user",
          content: `Translate from ${from} to ${to}: ${text}`,
        },
      ],
    });

    res.json({
      translated:
        response.choices[0].message.content,
    });

  } catch (error) {
    console.log(error);

    res.status(500).json({
      error: "Translation failed",
    });
  }
});

app.listen(3000, () => {
  console.log(
    "BridgeCall AI backend running on http://localhost:3000"
  );
});