import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String

    static let all: [FAQItem] = [
        .init(question: "Wanneer mag ik de vlag uithangen?",
              answer: "Altijd. Nederland heeft geen wet die bepaalt wanneer u mag vlaggen. Op de officiële vlagdagen hangt de vlag uit op gebouwen van de Rijksoverheid. Burgers, bedrijven en organisaties kunnen die vlaginstructie als richtlijn volgen. Dat is niet verplicht."),
        .init(question: "Hoe moet de vlag worden opgehangen?",
              answer: "Rood boven, wit in het midden, blauw onder. De vlag mag nooit de grond raken of het verkeer hinderen, en moet vrij kunnen wapperen."),
        .init(question: "Wat zijn de regels voor de wimpel?",
              answer: "De oranje wimpel gaat alleen uit op Koningsdag en op de verjaardagen van koningin Máxima, prinses Beatrix en de Prinses van Oranje (prinses Amalia). De wimpel hangt boven de vlag."),
        .init(question: "Mag je op een zondag vlaggen?",
              answer: "Ja. Wel schuiven de meeste vaste vlagdagen een dag op als ze op een zondag of een christelijke feestdag vallen. Uitzonderingen zijn 4 en 5 mei: die blijven altijd op dezelfde datum. Koningsdag gaat bij een zondag naar zaterdag 26 april."),
        .init(question: "Wat zijn de regels voor halfstok vlaggen?",
              answer: "Halfstok betekent dat de vlag op een derde van de masthoogte hangt, gemeten vanaf de top. Hijs de vlag eerst in top en laat hem dan zakken. Bij het strijken gaat hij eerst weer in top. Op 4 mei hangt de vlag halfstok van 18:00 uur tot zonsondergang. Een wimpel gaat nooit halfstok uit."),
        .init(question: "Mag ik een versleten vlag ophangen?",
              answer: "Liever niet. Een gescheurde of verkleurde vlag doet afbreuk aan het nationale symbool. Vervang de vlag als de kleuren vervaagd zijn of de rafels zichtbaar worden."),
        .init(question: "Hoe vouw ik de vlag correct op?",
              answer: "Vouw de vlag netjes in de lengte en daarna in de breedte, zonder dat hij de grond raakt. Berg de vlag altijd droog op; een vochtige vlag gaat schimmelen en verkleurt."),
        .init(question: "Mag ik de vlag ’s nachts laten hangen?",
              answer: "Het is gebruik om de vlag niet te laten hangen tussen zonsondergang en zonsopkomst. Laat u hem toch hangen? Verlicht hem dan, zodat de kleuren goed zichtbaar zijn."),
        .init(question: "Mag ik meerdere vlaggen naast elkaar hangen?",
              answer: "Ja. De Nederlandse vlag krijgt dan de ereplaats. Bij drie vlaggen is dat het midden; bij twee vlaggen rechts, gezien met de rug naar de vlaggen."),
        .init(question: "Zijn er speciale vlaginstructies voor rouwdagen?",
              answer: "Ja. Bij een nationale ramp of het overlijden van een lid van het Koninklijk Huis kan de minister-president een speciale vlaginstructie uitgeven, bijvoorbeeld om halfstok te vlaggen."),
        .init(question: "Vlag uit bij bijzondere gebeurtenissen?",
              answer: "Bij een geboorte, huwelijk of overlijden in het Koninklijk Huis kan de minister-president een speciale vlaginstructie afkondigen. Komt er een buitenlands staatshoofd op officieel bezoek, dan wordt alleen gevlagd in de gemeenten die worden bezocht."),
    ]
}

struct FAQView: View {
    @State private var expanded: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Heldere antwoorden op de meestgestelde vragen over de Nederlandse vlag.")
                        .font(.subheadline).foregroundStyle(Theme.muted)
                        .padding(.bottom, 6)

                    ForEach(FAQItem.all) { item in
                        DisclosureGroup(isExpanded: Binding(
                            get: { expanded.contains(item.id) },
                            set: { open in
                                withAnimation(.snappy) {
                                    if open { expanded.insert(item.id) } else { expanded.remove(item.id) }
                                }
                            }
                        )) {
                            Text(item.answer)
                                .font(.subheadline)
                                .foregroundStyle(Theme.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        } label: {
                            Text(item.question)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(16)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Link(destination: URL(string: "https://www.rijksoverheid.nl/onderwerpen/grondwet-en-statuut/vraag-en-antwoord/wanneer-kan-ik-de-vlag-uithangen-en-wat-is-de-vlaginstructie")!) {
                        Label("Vlaginstructie op rijksoverheid.nl", systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("FAQ")
        }
    }
}
