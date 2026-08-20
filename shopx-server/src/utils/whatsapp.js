const twilio = require("twilio");

const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

/**
 * Send OTP via WhatsApp
 * @param {string} phone - MUST be in international format (+91..., +966...)
 * @param {string} otp - 4 digit OTP
 */




exports.sendWhatsAppOtp = async (phone, otp) => {
  try {
    if (!phone) {
      throw new Error("Phone number is required");
    }

    let to = phone.replace(/\s+/g, "").replace(/-/g, "");

    // ✅ AUTO ADD COUNTRY CODE
    if (!to.startsWith("+")) {
      // India numbers (10 digits)
      if (to.length === 10) {
        to = "+91" + to;
      }
      // Saudi numbers (9 digits)
      else if (to.length === 9) {
        to = "+966" + to;
      } else {
        throw new Error("Invalid phone number format");
      }
    }

    // ✅ ADD WHATSAPP PREFIX
    if (!to.startsWith("whatsapp:")) {
      to = "whatsapp:" + to;
    }

    console.log("📲 Sending WhatsApp OTP to:", to);

    const result = await client.messages.create({
      from: process.env.TWILIO_WHATSAPP_FROM,
      to,
      body: `🔐 JoyPros Admin Login OTP\n\nYour OTP is ${otp}\n\nValid for 5 minutes.`,
    });

    console.log("✅ WhatsApp OTP sent:", result.sid);
    return result;
  } catch (error) {
  console.error("❌ WhatsApp OTP FULL ERROR:", error);

  throw new Error(
    error?.message ||
    error?.code ||
    "Twilio WhatsApp OTP failed"
  );
}

};
