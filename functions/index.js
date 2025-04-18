const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Configure SMTP transport for Gmail with app password
const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 465,
  secure: true, // use SSL
  auth: {
    user: "eg8217178@gmail.com",
    pass: "jqbykuydtedadjar",
  },
});

// Cloud Function to send welcome email after admin registers a user
exports.sendWelcomeEmail = functions.https.onCall(async (data, context) => {
  const email = data.email;
  const tempPassword = data.tempPassword;

  if (!email || !tempPassword) {
    // eslint-disable-next-line max-len
    throw new functions.https.HttpsError("invalid-argument", "Email and temporary password are required.");
  }

  const mailOptions = {
    from: `"FingerprintMIS" <eg8217178@gmail.com>`,
    to: email,
    subject: "Welcome to FingerprintMIS",
    // eslint-disable-next-line max-len
    text: `Welcome to FingerprintMIS!\n\nYour login email: ${email}\nYour temporary password: ${tempPassword}\n\nPlease change your password after your first login.`,
  };

  try {
    await transporter.sendMail(mailOptions);
    return {success: true};
  } catch (error) {
    console.error("Error sending email:", error);
    throw new functions.https.HttpsError("internal", "Failed to send email");
  }
});
