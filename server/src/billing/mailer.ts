export interface LicenseEmail {
  email: string;
  key: string;
  plan: string;
  kind: 'perpetual' | 'subscription' | 'trial';
}

export interface Mailer {
  sendLicenseKey(msg: LicenseEmail): Promise<void>;
}

/** Development default: logs the key. Never use in production. */
export class ConsoleMailer implements Mailer {
  constructor(private readonly log: (line: string) => void = (l) => console.log(l)) {}
  async sendLicenseKey(msg: LicenseEmail): Promise<void> {
    this.log(`[mail] to=${msg.email} plan=${msg.plan} kind=${msg.kind} key=${msg.key}`);
  }
}

/** Minimal transactional-mail client using the Resend HTTP API (no SDK dependency). */
export class ResendMailer implements Mailer {
  constructor(
    private readonly apiKey: string,
    private readonly from: string,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {}
  async sendLicenseKey(msg: LicenseEmail): Promise<void> {
    const subject = msg.kind === 'perpetual' ? 'Your MIRRORZ perpetual license' : 'Your MIRRORZ subscription is active';
    const text = [
      'Thanks for choosing MIRRORZ.',
      '',
      `Plan: ${msg.plan} (${msg.kind})`,
      `License key: ${msg.key}`,
      '',
      'Open MIRRORZ > Settings > License and paste the key. You can use it on up to the number of Macs shown in your account.',
      msg.kind === 'perpetual' ? 'Perpetual licenses include 12 months of feature updates and security updates forever.' : 'Manage or cancel anytime from the billing portal link in your receipt.',
      '',
      'No ads. No nags. Ever.',
    ].join('\n');
    const res = await this.fetchImpl('https://api.resend.com/emails', {
      method: 'POST',
      headers: { authorization: `Bearer ${this.apiKey}`, 'content-type': 'application/json' },
      body: JSON.stringify({ from: this.from, to: [msg.email], subject, text }),
    });
    if (!res.ok) throw new Error(`resend ${res.status}`);
  }
}
