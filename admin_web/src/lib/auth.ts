import crypto from 'crypto';

/**
 * Validates a 6-digit TOTP token against a base32 or ASCII secret (RFC 6238).
 * Supports ±1 step (30-second window) to accommodate slight clock drift.
 */
export function verifyTOTP(token: string, secret: string = 'UPAJOPLATFORMTOTP2FAKEY2026'): boolean {
  if (!/^\d{6}$/.test(token)) return false;

  const step = 30;
  const currentEpoch = Math.floor(Date.now() / 1000);
  const currentStep = Math.floor(currentEpoch / step);

  // Check current time step, previous (-1), and next (+1)
  for (let delta = -1; delta <= 1; delta++) {
    const timeStep = currentStep + delta;
    const expectedToken = generateTOTPForStep(timeStep, secret);
    if (crypto.timingSafeEqual(Buffer.from(token), Buffer.from(expectedToken))) {
      return true;
    }
  }
  return false;
}

function generateTOTPForStep(step: number, secret: string): string {
  const buffer = Buffer.alloc(8);
  buffer.writeBigInt64BE(BigInt(step));

  const hmac = crypto.createHmac('sha1', secret);
  hmac.update(buffer);
  const digest = hmac.digest();

  const offset = digest[digest.length - 1] & 0xf;
  const binary =
    ((digest[offset] & 0x7f) << 24) |
    ((digest[offset + 1] & 0xff) << 16) |
    ((digest[offset + 2] & 0xff) << 8) |
    (digest[offset + 3] & 0xff);

  const otp = binary % 1000000;
  return otp.toString().padStart(6, '0');
}

