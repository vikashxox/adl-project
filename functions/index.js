/**
 * Firebase Cloud Functions – Loan Tracker App
 * Triggers:
 *   1. onLoanCreated  – fires when a doc is added to "beneficiaries"
 *                       sends an email to the assigned officer.
 *   2. sendEmail      – callable function (optional manual trigger).
 *
 * Deploy:
 *   firebase deploy --only functions
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const nodemailer = require("nodemailer");
const { defineSecret } = require("firebase-functions/params");

// ── Initialise Firebase Admin ─────────────────────────────────────────────────
initializeApp();

// ── Secrets (set with: firebase functions:secrets:set GMAIL_USER etc.) ────────
const GMAIL_USER = defineSecret("GMAIL_USER");
const GMAIL_PASS = defineSecret("GMAIL_PASS");

// ── Helper: create transporter ────────────────────────────────────────────────
function createTransporter(user, pass) {
  return nodemailer.createTransport({
    service: "gmail",
    auth: { user, pass },
  });
}

// ── Trigger 1: Firestore onDocumentCreated ────────────────────────────────────
// Fires every time a new document is written to "beneficiaries/{loanId}"
exports.onLoanCreated = onDocumentCreated(
  {
    document: "beneficiaries/{loanId}",
    secrets: [GMAIL_USER, GMAIL_PASS],
    region: "asia-south1", // Mumbai — change to match your Firebase project region
  },
  async (event) => {
    const db = getFirestore();
    const snap = event.data;
    if (!snap) return;

    const loan = snap.data();
    const loanId = event.params.loanId;

    const {
      name: beneficiaryName = "N/A",
      phone = "N/A",
      loanAmount = "N/A",
      loanPurpose = "N/A",
      assignedOfficerId,
      assignedOfficerName = "Officer",
      disbursementDate,
      disbursedDate,
      deadline,
      village = "",
      district = "",
      state = "",
    } = loan;

    const actualDisbursementDate = disbursementDate || disbursedDate;

    // ── Fetch officer email from Firestore ─────────────────────────────────
    if (!assignedOfficerId) {
      console.warn("onLoanCreated: no assignedOfficerId on loan", loanId);
      return;
    }

    const officerDoc = await db
      .collection("officers")
      .doc(assignedOfficerId)
      .get();

    if (!officerDoc.exists) {
      console.warn("onLoanCreated: officer doc not found", assignedOfficerId);
      return;
    }

    const officerEmail = officerDoc.data().email;
    if (!officerEmail) {
      console.warn("onLoanCreated: officer has no email field", assignedOfficerId);
      return;
    }

    // ── Format dates ───────────────────────────────────────────────────────
    const fmt = (ts) => {
      if (!ts) return "N/A";
      const d = ts.toDate ? ts.toDate() : new Date(ts);
      return d.toLocaleDateString("en-IN", {
        day: "2-digit",
        month: "short",
        year: "numeric",
      });
    };

    // ── Build email ────────────────────────────────────────────────────────
    const mailOptions = {
      from: `"Loan Tracker App" <${GMAIL_USER.value()}>`,
      to: officerEmail,
      subject: `📋 New Loan Assignment`,
      html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <style>
    body { font-family: Arial, sans-serif; background: #f9fafb; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 32px auto; background: #ffffff;
                 border-radius: 12px; overflow: hidden;
                 box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #7c3aed, #9333ea);
              padding: 32px 24px; color: white; }
    .header h1 { margin: 0; font-size: 22px; font-weight: 600; }
    .body { padding: 28px 24px; }
    .greeting { font-size: 16px; color: #1f2937; margin-bottom: 16px; }
    .cta { text-align: center; margin: 24px 0; }
    .cta a { background: linear-gradient(135deg, #7c3aed, #9333ea);
              color: white; text-decoration: none; padding: 12px 28px;
              border-radius: 8px; font-size: 14px; font-weight: 600; }
    .footer { padding: 16px 24px; background: #f3f4f6;
              font-size: 11px; color: #9ca3af; text-align: center; }
  </style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>📋 New Loan Assignment</h1>
  </div>
  <div class="body">
    <p class="greeting">Dear <strong>${assignedOfficerName}</strong>,</p>
    <p style="color:#4b5563;font-size:14px;line-height:1.6;">
      A new loan application for <strong>${beneficiaryName}</strong> has been assigned to you.
    </p>

    <div class="cta">
      <a href="https://loantrackerapp-37fba.web.app">Open Loan Tracker App</a>
    </div>

    <p style="color:#6b7280;font-size:13px;line-height:1.6;">
      Please log in to the application to review the details.
    </p>
  </div>
  <div class="footer">
    This is an automated message from the Government Loan Tracking System.<br/>
    © ${new Date().getFullYear()} Loan Tracker App. All rights reserved.
  </div>
</div>
</body>
</html>
      `.trim(),
    };

    // ── Send ───────────────────────────────────────────────────────────────
    const transporter = createTransporter(GMAIL_USER.value(), GMAIL_PASS.value());
    await transporter.sendMail(mailOptions);

    console.log(
      `✅ Loan assignment email sent to ${officerEmail} for loan ${loanId}`
    );
  }
);

// ── Trigger 2: Callable function (optional manual/test trigger) ───────────────
exports.sendLoanAssignmentEmail = onCall(
  {
    secrets: [GMAIL_USER, GMAIL_PASS],
    region: "asia-south1",
  },
  async (request) => {
    const db = getFirestore();
    const { loanId } = request.data;

    if (!loanId) throw new HttpsError("invalid-argument", "loanId is required.");

    const loanDoc = await db.collection("beneficiaries").doc(loanId).get();
    if (!loanDoc.exists) {
      throw new HttpsError("not-found", "Loan not found.");
    }

    const loan = loanDoc.data();
    const officerDoc = await db
      .collection("officers")
      .doc(loan.assignedOfficerId)
      .get();

    if (!officerDoc.exists || !officerDoc.data().email) {
      throw new HttpsError("not-found", "Officer or officer email not found.");
    }

    const officerEmail = officerDoc.data().email;
    const transporter = createTransporter(GMAIL_USER.value(), GMAIL_PASS.value());

    await transporter.sendMail({
      from: `"Loan Tracker App" <${GMAIL_USER.value()}>`,
      to: officerEmail,
      subject: `📋 Loan Assignment Notification`,
      text: `Dear ${loan.assignedOfficerName},\n\nYou have been assigned a new loan application for ${loan.name}.\n\nPlease open the Loan Tracker App to review.\n\nRegards,\nAdmin`,
    });

    return { success: true, message: `Email sent to ${officerEmail}` };
  }
);
