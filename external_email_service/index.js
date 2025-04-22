const express = require("express");
const nodemailer = require("nodemailer");
const bodyParser = require("body-parser");
const cors = require("cors");

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

// Configure nodemailer transporter with Maileroo SMTP
const transporter = nodemailer.createTransport({
  host: "smtp.maileroo.com",
  port: 465,
  secure: true, // use SSL
  auth: {
    user: "emmanuel@fingerprintmis.com",
    pass: "ff5006f559d3eac5f2b642e9",
  },
  tls: {
    rejectUnauthorized: false,
  },
});

// Endpoint to send welcome email
app.post("/send-welcome-email", async (req, res) => {
  const { email, tempPassword } = req.body;

  if (!email || !tempPassword) {
    return res.status(400).json({ error: "Email and temporary password are required." });
  }

  const mailOptions = {
    from: '"FingerprintMIS" <emmanuel@fingerprintmis.com>',
    to: email,
    subject: "Welcome to FingerprintMIS",
    text: `Welcome to FingerprintMIS!\n\nYour login email: ${email}\nYour temporary password: ${tempPassword}\n\nPlease change your password after your first login.`,
  };

  try {
    await transporter.sendMail(mailOptions);
    res.json({ success: true, message: "Welcome email sent successfully." });
  } catch (error) {
    console.error("Error sending email:", error);
    res.status(500).json({ error: "Failed to send welcome email." });
  }
});

app.listen(port, () => {
  console.log(`Email service listening at http://localhost:${port}`);
});
