const twilio = require("twilio");

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

exports.sendSMS = async (to, message) => {
  try {
    // Note: SMS requires paid Twilio number in production
    // This is kept for reference
    const result = await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER, // Requires paid number
      to: to
    });
    
    console.log(`SMS sent to: ${to}`);
    return result;
  } catch (error) {
    console.error("SMS sending failed:", error);
    throw new Error("SMS service temporarily unavailable");
  }
};


