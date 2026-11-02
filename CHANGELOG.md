# Changelog

Alle noemenswaardige wijzigingen in de Vlagdagen-app.

## [2.0.1] (build 5), november 2026

### Nieuw
- **Ontdekken**: onderaan in Instellingen een kaart *Meer apps van de ontwikkelaar*, die naar lrvdlinden.app leidt.
- **Vraag om een beoordeling**: de app vraagt op een rustig moment om een App Store-beoordeling.
  - De eerste keer pas 4 uur na het eerste gebruik op dat apparaat.
  - Daarna hoogstens één keer per week (iOS toont het venster sowieso maximaal 3 keer per jaar).
  - Nooit tijdens het openings- of welkomstscherm, en niet als er een venster openstaat.

## [2.0.0] (build 3), november 2026

Een volledig nieuwe app, vanaf nul opnieuw gebouwd in SwiftUI. Ten opzichte van versie 1.0.1:

### Nieuw
- **Geanimeerd openingsscherm**: de vlag wordt gehesen, gaat wapperen en krijgt de oranje wimpel.
- **Vandaag-scherm** met een groot *Ja.* of *Nee.* en precies hoe de vlag vandaag hangt: in top, met wimpel, of halfstok.
- **Aftelklok** tot de volgende vlagdag, in dagen, uren, minuten en seconden.
- **Ochtendmelding op een tijd naar keuze** (standaard 08:00), ook als de app gesloten is.
  - Optioneel ook een seintje de avond ervoor (20:00).
  - Op 4 mei een extra herinnering om 17:45: tijd om de vlag halfstok te hangen.
  - Meldingen per vlagdag aan of uit te zetten. Prinsjesdag staat standaard uit, omdat dan alleen in Den Haag wordt gevlagd.
  - Testmelding versturen vanuit Instellingen.
- **Zonsondergangstijd op 4 mei**, zodat je weet tot wanneer de vlag halfstok blijft.
- **Agenda-abonnement** voor Apple Agenda, Google Agenda en Outlook, dat elk jaar vanzelf bijwerkt.
- **Agenda** van dit jaar en de twee jaren daarna. Verschoven datums zijn duidelijk gemarkeerd, bijvoorbeeld *Verschoven van 17 mei*.
- **Detailpagina per vlagdag**: achtergrond, instructie, uitgebreid of beperkt vlaggen, en delen.
- **Handleiding** in stappen: de vlag hijsen, halfstok vlaggen en de wimpel bevestigen.
- **Widgets** voor het beginscherm (klein en middel) en het toegangsscherm.
- **iPad-ondersteuning**, in alle schermstanden.
- **Donkere modus.**

### Verbeterd
- **Altijd de juiste datums.** De app rekent de vlagdagen zelf uit volgens de vlaginstructie van de Rijksoverheid, voor elk jaar. Valt een vlagdag op een zondag of een christelijke feestdag (Pasen, Hemelvaart, Pinksteren, Kerst), dan schuift hij automatisch door. Koningsdag gaat dan naar zaterdag 26 april.
- **Vlagadvies**: beoordeelt windstoten, regen en onweer, met een duidelijk advies.
- **FAQ** volledig herschreven.
- **Nieuw ontwerp** in de stijl van vlagdagen.nl, met een nieuw app-icoon.
- **Privacy**: de app verzamelt geen persoonsgegevens. Meldingen worden lokaal op je toestel ingepland.

### Opgelost
- Veteranendag valt nu altijd op de laatste zaterdag van juni, en Prinsjesdag op de derde dinsdag van september.
- Verjaardagen die op zondag vallen, worden correct naar maandag verschoven. Een voorbeeld is prinses Beatrix in 2027: 1 februari.

### Gewijzigd
- Minimaal iOS 17 vereist; versie 1.x werkte vanaf iOS 15.6.

## [1.0.1], 10 januari 2025
- Bugfixes en kleine verbeteringen.

## [1.0.0], 7 januari 2025
- Eerste versie: vlagdagen, meldingen, agenda, vlagadvies en FAQ.
