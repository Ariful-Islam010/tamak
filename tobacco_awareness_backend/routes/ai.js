const express = require('express');
const router = express.Router();
const Groq = require('groq-sdk');
const config = require('../config');

const groq = new Groq({ apiKey: config.GROQ_API_KEY });

/**
 * Generate a specific chunk of days (max 20 days per chunk) using Groq llama-3.3-70b-versatile
 */
async function generatePlanChunk({ startDay, endDay, totalDays, age, gender }) {
  const isFirstChunk = startDay === 1;
  const isFinalChunk = endDay === totalDays;

  const prompt = `
You are an AI assistant helping a user quit tobacco usage.
User Profile: Age ${age}, Gender ${gender}.
Total Quit Duration: ${totalDays} days.

Task: Generate day-by-day quit plan objects ONLY for Day ${startDay} to Day ${endDay} (inclusive) in clear, high-quality Bengali language.

For each day in range [${startDay} to ${endDay}], produce a JSON object with:
1. "day": Exact day number as integer (from ${startDay} to ${endDay})
2. "title": Concise focus title in Bengali
3. "desc": Detailed strategy/guidance in clear Bengali
4. "user_task": Specific action required from the user today
5. "ai_task": What AI assistant has prepared for today
6. "daily_target": Today's maximum target (e.g. "সম্পূর্ণ ট্র্যাকিং", "নিয়ন্ত্রণ রাখা", "০ (শূন্য) - তামাকমুক্ত থাকুন!").

Theme progression context:
${isFirstChunk ? `- Day 1: Daily Check-in & Triggers (আজ অ্যাপের 'Daily Check-in' সম্পন্ন করতে হবে এবং ট্রিগার পয়েন্ট ডায়েরিতে রাখতে হবে।)
- Day 2: The SOS Emergency (আজ তামাক ব্যবহারের তীব্র ইচ্ছা হলে অ্যাপের 'SOS Emergency' অপশনটি ব্যবহার করতে হবে।)
- Day 3: Peer Support (Community) (আজ সাপোর্ট গ্রুপে অন্যদের সাথে অভিজ্ঞতা শেয়ার করুন।)
- Day 4: Money Saver Goal (আজ অ্যাপের 'Money Saver' অপশনে গিয়ে নিজের একটি গোল সেট করুন।)
- Day 5: Virtual Quit-Tree (ভার্চুয়াল গাছের যত্ন নিন ও স্ট্রিক বজায় রাখুন।)
- Day 6: Educational Content (এডুকেশনাল আর্টিকেল পড়ুন এবং আত্মবিশ্বাসী থাকুন।)` : ''}
${isFinalChunk ? `- Day ${totalDays}: The Celebration! (অভিনন্দন! সফলভাবে চ্যালেঞ্জ শেষ করেছেন, মানি সেভারের গোল পূরণ করুন ও ব্যাজ শেয়ার করুন।)` : ''}
- For other days: Maintain logical sequence, focus on breaking habits, managing cravings, physical exercise, mindfulness, saving money, avoiding triggers, and personal recovery milestones.

CRITICAL INSTRUCTIONS:
- Output EXACTLY ${endDay - startDay + 1} day objects corresponding to days ${startDay} to ${endDay}.
- Ensure Bengali spelling, grammar, and font characters are flawless. Do NOT generate corrupted or gibberish text.
- Return ONLY a valid JSON object with a single key "plans" that contains the array of these day objects.
`;

  const chatCompletion = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: "You are a helpful assistant that only outputs valid JSON. You must output a JSON object containing a 'plans' array with valid day objects in clear Bengali.",
      },
      { role: 'user', content: prompt },
    ],
    response_format: { type: 'json_object' },
    temperature: 0.6,
  });

  const content = chatCompletion.choices[0]?.message?.content || '{}';
  const parsed = JSON.parse(content);
  return Array.isArray(parsed.plans) ? parsed.plans : (Array.isArray(parsed) ? parsed : []);
}

// POST /api/ai/generate-plan
router.post('/generate-plan', async (req, res) => {
  try {
    const { durationInDays, age, gender } = req.body;
    const totalDays = parseInt(durationInDays, 10) || 7;

    const CHUNK_SIZE = 20; // 20-day chunks for synchronized, non-truncating generation
    let allPlans = [];

    for (let startDay = 1; startDay <= totalDays; startDay += CHUNK_SIZE) {
      const endDay = Math.min(startDay + CHUNK_SIZE - 1, totalDays);
      console.log(`[AI Plan Generation] Generating Days ${startDay} to ${endDay} of ${totalDays}...`);
      
      const chunkPlans = await generatePlanChunk({
        startDay,
        endDay,
        totalDays,
        age,
        gender,
      });

      allPlans = allPlans.concat(chunkPlans);
    }

    // Ensure day numbers are sorted properly
    allPlans.sort((a, b) => (a.day || 0) - (b.day || 0));

    return res.json({ plans: allPlans });
  } catch (error) {
    console.error('Error calling Groq API:', error);
    return res.status(500).json({ detail: error.message });
  }
});

// POST /api/ai/get-sos-advice
router.post('/get-sos-advice', async (req, res) => {
  try {
    const { triggerReason } = req.body;

    const chatCompletion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        {
          role: 'system',
          content: 'You are an empathetic, concise AI assistant helping someone overcome a sudden tobacco craving. Provide a brief, actionable coping strategy instantly in Bengali language. Do not lecture, just give immediate practical advice.',
        },
        {
          role: 'user',
          content: `I am having a strong craving for tobacco right now because: ${triggerReason}. What should I do right now?`,
        },
      ],
      temperature: 0.7,
      max_tokens: 200,
    });

    const advice = chatCompletion.choices[0]?.message?.content?.trim() || '';
    return res.json({ advice });
  } catch (error) {
    console.error('Error calling Groq SOS:', error);
    return res.status(500).json({ detail: error.message });
  }
});

module.exports = router;

