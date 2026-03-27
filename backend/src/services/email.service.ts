import { env } from '../config/env.js'

const RESEND_API = 'https://api.resend.com/emails'

// ─── Core sender ──────────────────────────────────────────────────────────────

async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!env.RESEND_API_KEY) {
    // Development fallback — log to console
    console.log(`\n📧 [EMAIL] To: ${to}\n   Subject: ${subject}\n`)
    return
  }

  const res = await fetch(RESEND_API, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${env.RESEND_API_KEY}`,
    },
    body: JSON.stringify({ from: env.EMAIL_FROM, to, subject, html }),
  })

  if (!res.ok) {
    const body = await res.text()
    console.error(`Email send failed (${res.status}): ${body}`)
    // Non-blocking: don't throw — email failure shouldn't crash a request
  }
}

// ─── Password reset ───────────────────────────────────────────────────────────

export async function sendPasswordResetEmail(
  to: string,
  resetToken: string,
  displayName: string
): Promise<void> {
  const resetLink = `${env.APP_URL}/reset-password?token=${resetToken}`

  const html = `<!DOCTYPE html>
<html lang="de">
<head><meta charset="utf-8"><title>Passwort zurücksetzen</title></head>
<body style="margin:0;padding:0;background:#0C1222;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0">
    <tr><td align="center" style="padding:40px 16px;">
      <table width="560" cellpadding="0" cellspacing="0" style="background:#111827;border-radius:16px;overflow:hidden;border:1px solid rgba(255,255,255,0.08);">
        <!-- Header -->
        <tr><td style="background:linear-gradient(135deg,#FF006E,#4CC9F0);padding:32px;text-align:center;">
          <h1 style="margin:0;color:#fff;font-size:24px;font-weight:700;letter-spacing:-0.5px;">LennyGrowth</h1>
          <p style="margin:8px 0 0;color:rgba(255,255,255,0.8);font-size:14px;">Passwort zurücksetzen</p>
        </td></tr>
        <!-- Body -->
        <tr><td style="padding:32px;">
          <p style="margin:0 0 16px;color:#94A3B8;font-size:15px;line-height:1.6;">Hallo ${displayName},</p>
          <p style="margin:0 0 24px;color:#94A3B8;font-size:15px;line-height:1.6;">
            Du hast eine Anfrage zur Passwort-Zurücksetzung erhalten. Klicke auf den Button unten um ein neues Passwort zu setzen.
          </p>
          <div style="text-align:center;margin:32px 0;">
            <a href="${resetLink}"
               style="display:inline-block;background:#FF006E;color:#fff;text-decoration:none;padding:14px 32px;border-radius:12px;font-weight:700;font-size:15px;letter-spacing:0.3px;">
              Passwort zurücksetzen
            </a>
          </div>
          <p style="margin:24px 0 0;color:#64748B;font-size:13px;line-height:1.6;">
            Dieser Link ist <strong style="color:#94A3B8;">1 Stunde</strong> gültig.<br>
            Falls du kein neues Passwort angefordert hast, kannst du diese E-Mail ignorieren.
          </p>
        </td></tr>
        <!-- Footer -->
        <tr><td style="padding:20px 32px;border-top:1px solid rgba(255,255,255,0.06);text-align:center;">
          <p style="margin:0;color:#475569;font-size:12px;">© ${new Date().getFullYear()} Lennard Büssow · <a href="${env.APP_URL}" style="color:#4CC9F0;text-decoration:none;">lennardbuessow.digital</a></p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`

  await sendEmail(to, 'Passwort zurücksetzen – LennyGrowth', html)
}

// ─── Welcome email ────────────────────────────────────────────────────────────

export async function sendWelcomeEmail(to: string, displayName: string): Promise<void> {
  const html = `<!DOCTYPE html>
<html lang="de">
<head><meta charset="utf-8"><title>Willkommen bei LennyGrowth</title></head>
<body style="margin:0;padding:0;background:#0C1222;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0">
    <tr><td align="center" style="padding:40px 16px;">
      <table width="560" cellpadding="0" cellspacing="0" style="background:#111827;border-radius:16px;overflow:hidden;border:1px solid rgba(255,255,255,0.08);">
        <tr><td style="background:linear-gradient(135deg,#FF006E,#16E1C4);padding:32px;text-align:center;">
          <h1 style="margin:0;color:#fff;font-size:28px;font-weight:700;">Willkommen 🚀</h1>
          <p style="margin:8px 0 0;color:rgba(255,255,255,0.85);font-size:15px;">Du bist jetzt Teil von LennyGrowth</p>
        </td></tr>
        <tr><td style="padding:32px;">
          <p style="margin:0 0 16px;color:#94A3B8;font-size:15px;line-height:1.6;">Hallo ${displayName},</p>
          <p style="margin:0 0 20px;color:#94A3B8;font-size:15px;line-height:1.6;">
            Schön, dass du dabei bist! Mit LennyGrowth erstellst du viralen LinkedIn- und Threads-Content in Sekunden –
            powered by KI und dem Know-how von Lennard Büssow.
          </p>
          <ul style="margin:0 0 24px;padding-left:20px;color:#94A3B8;font-size:14px;line-height:2;">
            <li>🤖 Bis zu <strong style="color:#fff;">20 KI-Generierungen/Tag</strong> kostenlos</li>
            <li>📅 Post-Planer für optimale Posting-Zeiten</li>
            <li>📚 Exklusive Marketing-Artikel & Ressourcen</li>
            <li>🎁 5 kostenlose Downloads sofort verfügbar</li>
          </ul>
          <div style="text-align:center;margin:28px 0;">
            <a href="${env.APP_URL}"
               style="display:inline-block;background:#16E1C4;color:#0C1222;text-decoration:none;padding:14px 32px;border-radius:12px;font-weight:700;font-size:15px;">
              App öffnen
            </a>
          </div>
        </td></tr>
        <tr><td style="padding:20px 32px;border-top:1px solid rgba(255,255,255,0.06);text-align:center;">
          <p style="margin:0;color:#475569;font-size:12px;">© ${new Date().getFullYear()} Lennard Büssow · <a href="${env.APP_URL}" style="color:#4CC9F0;text-decoration:none;">lennardbuessow.digital</a></p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`

  await sendEmail(to, `Willkommen bei LennyGrowth, ${displayName}!`, html)
}
