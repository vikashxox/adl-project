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
      deadline,
      village = "",
      district = "",
      state = "",
    } = loan;

    // ── Fetch officer email from Firestore ─────────────────────────────────
    if (!assignedOfficerId) {
      console.warn("onLoanCreated: no assignedOfficerId on loan", loanId);
      return;
    }

    const officerDoc = await db
      .collection("users")
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
      subject: `📋 New Loan Assignment – ${beneficiaryName}`,
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
    .header p  { margin: 6px 0 0; font-size: 14px; opacity: 0.85; }
    .body { padding: 28px 24px; }
    .greeting { font-size: 16px; color: #1f2937; margin-bottom: 16px; }
    .card { background: #faf5ff; border: 1px solid #e9d5ff;
            border-radius: 10px; padding: 20px; margin-bottom: 20px; }
    .card h2 { margin: 0 0 14px; font-size: 14px; color: #7e22ce;
               text-transform: uppercase; letter-spacing: 0.5px; }
    .row { display: flex; justify-content: space-between;
           border-bottom: 1px solid #ede9fe; padding: 8px 0; font-size: 14px; }
    .row:last-child { border-bottom: none; }
    .label { color: #6b7280; }
    .value { color: #1f2937; font-weight: 500; text-align: right; }
    .badge { display: inline-block; background: #f3e8ff; color: #7e22ce;
             padding: 4px 12px; border-radius: 20px; font-size: 12px;
             font-weight: 600; margin-top: 8px; }
    .footer { padding: 16px 24px; background: #f3f4f6;
              font-size: 11px; color: #9ca3af; text-align: center; }
    .cta { text-align: center; margin: 24px 0; }
    .cta a { background: linear-gradient(135deg, #7c3aed, #9333ea);
              color: white; text-decoration: none; padding: 12px 28px;
              border-radius: 8px; font-size: 14px; font-weight: 600; }
  </style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>📋 New Loan Assignment</h1>
    <p>You have been assigned a new beneficiary loan case</p>
  </div>
  <div class="body">
    <p class="greeting">Dear <strong>${assignedOfficerName}</strong>,</p>
    <p style="color:#4b5563;font-size:14px;line-height:1.6;">
      A new loan application has been assigned to you. Please review the details
      below and follow up with the beneficiary at your earliest convenience.
    </p>

    <div class="card">
      <h2>👤 Beneficiary Details</h2>
      <div class="row">
        <span class="label">Full Name</span>
        <span class="value">${beneficiaryName}</span>
      </div>
      <div class="row">
        <span class="label">Mobile</span>
        <span class="value">${phone}</span>
      </div>
      <div class="row">
        <span class="label">Location</span>
        <span class="value">${[village, district, state].filter(Boolean).join(", ") || "N/A"}</span>
      </div>
    </div>

    <div class="card">
      <h2>💰 Loan Details</h2>
      <div class="row">
        <span class="label">Loan ID</span>
        <span class="value">${loanId}</span>
      </div>
      <div class="row">
        <span class="label">Amount</span>
        <span class="value">₹${Number(loanAmount).toLocaleString("en-IN")}</span>
      </div>
      <div class="row">
        <span class="label">Purpose</span>
        <span class="value">${loanPurpose}</span>
      </div>
      <div class="row">
        <span class="label">Disbursement Date</span>
        <span class="value">${fmt(disbursementDate)}</span>
      </div>
      <div class="row">
        <span class="label">Repayment Deadline</span>
        <span class="value">${fmt(deadline)}</span>
      </div>
      <div class="row">
        <span class="label">Status</span>
        <span class="value"><span class="badge">Pending</span></span>
      </div>
    </div>

    <div class="cta">
      <a href="https://loantrackerapp-37fba.web.app">Open Loan Tracker App</a>
    </div>

    <p style="color:#6b7280;font-size:13px;line-height:1.6;">
      If you have any questions, please contact your admin. Do not reply to this
      automated email.
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
      .collection("users")
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
      subject: `📋 Loan Assignment Notification – ${loan.name}`,
      text: `Dear ${loan.assignedOfficerName},\n\nYou have been assigned loan ID: ${loanId} for beneficiary ${loan.name}.\n\nLoan Amount: ₹${loan.loanAmount}\nPurpose: ${loan.loanPurpose}\n\nPlease open the Loan Tracker App to review.\n\nRegards,\nAdmin`,
    });

    return { success: true, message: `Email sent to ${officerEmail}` };
  }
);
