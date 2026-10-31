// Base44 backend function: generateFlagDaysICS
// Vervangt de huidige functie op vlagdagen.nl/api/functions/generateFlagDaysICS.
// Berekent de vlagdagen zelf (vorig jaar t/m drie jaar vooruit), zodat het
// agenda-abonnement nooit "leegloopt" en verschuivingen altijd kloppen.
// Dezelfde regels als Shared/FlagDays.swift in de iOS-app.

type Kind =
  | "beatrix" | "koningsdag" | "dodenherdenking" | "bevrijdingsdag" | "maxima"
  | "veteranendag" | "einde-wo2" | "prinsjesdag" | "amalia" | "koninkrijksdag";

const TITLES: Record<Kind, string> = {
  beatrix: "Verjaardag prinses Beatrix",
  koningsdag: "Koningsdag",
  dodenherdenking: "Dodenherdenking",
  bevrijdingsdag: "Bevrijdingsdag",
  maxima: "Verjaardag koningin Máxima",
  veteranendag: "Veteranendag",
  "einde-wo2": "Formeel einde Tweede Wereldoorlog",
  prinsjesdag: "Prinsjesdag (alleen in Den Haag)",
  amalia: "Verjaardag prinses Catharina-Amalia",
  koninkrijksdag: "Koninkrijksdag",
};

const PENNANT = new Set<Kind>(["beatrix", "koningsdag", "maxima", "amalia"]);

// Datums als UTC-middernacht; we werken alleen met kalenderdagen.
const d = (y: number, m: number, day: number) => new Date(Date.UTC(y, m - 1, day));
const add = (date: Date, n: number) => new Date(date.getTime() + n * 86400000);
const same = (a: Date, b: Date) => a.getTime() === b.getTime();
const ymd = (date: Date) => date.toISOString().slice(0, 10).replace(/-/g, "");

function easter(y: number): Date {
  const a = y % 19, b = Math.floor(y / 100), c = y % 100, dd = Math.floor(b / 4), e = b % 4;
  const f = Math.floor((b + 8) / 25), g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - dd - g + 15) % 30, i = Math.floor(c / 4), k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7, m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31), day = ((h + l - 7 * m + 114) % 31) + 1;
  return d(y, month, day);
}

function blocked(date: Date): boolean {
  if (date.getUTCDay() === 0) return true;
  const y = date.getUTCFullYear(), e = easter(y);
  return [e, add(e, 1), add(e, 39), add(e, 49), add(e, 50), d(y, 12, 25), d(y, 12, 26)].some((h) => same(h, date));
}

function shift(date: Date): Date {
  let x = date;
  while (blocked(x)) x = add(x, 1);
  return x;
}

export function flagDays(y: number): { kind: Kind; date: Date }[] {
  const king = d(y, 4, 27);
  let vet = d(y, 6, 30);
  while (vet.getUTCDay() !== 6) vet = add(vet, -1);
  let tue = d(y, 9, 1);
  while (tue.getUTCDay() !== 2) tue = add(tue, 1);
  return [
    { kind: "beatrix", date: shift(d(y, 1, 31)) },
    { kind: "koningsdag", date: blocked(king) ? d(y, 4, 26) : king },
    { kind: "dodenherdenking", date: d(y, 5, 4) },
    { kind: "bevrijdingsdag", date: d(y, 5, 5) },
    { kind: "maxima", date: shift(d(y, 5, 17)) },
    { kind: "veteranendag", date: vet },
    { kind: "einde-wo2", date: shift(d(y, 8, 15)) },
    { kind: "prinsjesdag", date: add(tue, 14) },
    { kind: "amalia", date: shift(d(y, 12, 7)) },
    { kind: "koninkrijksdag", date: shift(d(y, 12, 15)) },
  ];
}

const esc = (s: string) => s.replace(/\\/g, "\\\\").replace(/;/g, "\\;").replace(/,/g, "\\,").replace(/\n/g, "\\n");

// RFC 5545: regels langer dan 75 octets vouwen (UTF-8-veilig)
function fold(line: string): string {
  const enc = new TextEncoder();
  if (enc.encode(line).length <= 75) return line;
  const parts: string[] = [];
  let cur = "", size = 0, limit = 75;
  for (const ch of line) {
    const n = enc.encode(ch).length;
    if (size + n > limit) { parts.push(cur); cur = ""; size = 0; limit = 74; }
    cur += ch; size += n;
  }
  parts.push(cur);
  return parts.join("\r\n ");
}

export function buildICS(now = new Date()): string {
  const year = now.getUTCFullYear();
  const stamp = now.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Vlagdagen.nl//Vlagdagen 2.0//NL",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "X-WR-CALNAME:Nederlandse Vlagdagen",
    "X-WR-TIMEZONE:Europe/Amsterdam",
    "X-WR-CALDESC:Alle officiële vlagdagen volgens de vlaginstructie van de Rijksoverheid",
    "REFRESH-INTERVAL;VALUE=DURATION:P1D",
    "X-PUBLISHED-TTL:P1D",
  ];
  for (let y = year - 1; y <= year + 3; y++) {
    for (const { kind, date } of flagDays(y)) {
      const pennant = PENNANT.has(kind);
      let desc = pennant ? "Vlag in top, met oranje wimpel." : "Vlag in top, zonder wimpel.";
      if (kind === "dodenherdenking") desc = "Vlag halfstok van 18:00 uur tot zonsondergang.";
      if (kind === "prinsjesdag") desc = "Alleen in Den Haag wordt gevlagd.";
      lines.push(
        "BEGIN:VEVENT",
        `UID:${kind}-${y}@vlagdagen.nl`,
        `DTSTAMP:${stamp}`,
        `DTSTART;VALUE=DATE:${ymd(date)}`,
        `DTEND;VALUE=DATE:${ymd(add(date, 1))}`,
        `SUMMARY:${esc(`🇳🇱 ${TITLES[kind]}${pennant ? " (met wimpel)" : ""}`)}`,
        `DESCRIPTION:${esc(desc + "\nMeer info: https://vlagdagen.nl")}`,
        "TRANSP:TRANSPARENT",
        "CATEGORIES:Vlagdag",
        "END:VEVENT",
      );
    }
  }
  lines.push("END:VCALENDAR");
  return lines.map(fold).join("\r\n") + "\r\n";
}

// deno-lint-ignore no-explicit-any
declare const Deno: any;
if (typeof Deno !== "undefined") {
  Deno.serve(() =>
    new Response(buildICS(), {
      headers: {
        "Content-Type": "text/calendar; charset=utf-8",
        "Content-Disposition": 'inline; filename="vlagdagen.ics"',
        "Cache-Control": "public, max-age=21600",
      },
    })
  );
}
