import SwiftUI

struct GuideStep: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}

struct Guide: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let steps: [GuideStep]

    static let all: [Guide] = [
        Guide(id: "hijsen", title: "De vlag hijsen", symbol: "arrow.up.to.line", steps: [
            .init(title: "Juiste kant boven", text: "De rode baan hoort bovenaan, de witte in het midden, de blauwe onderaan. Zorg dat de vlag strak is, zonder kreuken."),
            .init(title: "Bevestig aan de lijn", text: "Haak de karabijnhaken van de vlag aan de lijn. De vlag hangt aan de buitenste kant van de mast."),
            .init(title: "Hijs helemaal in top", text: "Trek de lijn omhoog totdat de vlag volledig boven aan de mast hangt. Zet de lijn daarna stevig vast."),
            .init(title: "Controleer de stand", text: "De vlag moet vrij kunnen wapperen en mag de grond, bomen of gebouwen niet raken."),
        ]),
        Guide(id: "halfstok", title: "Halfstok vlaggen", symbol: "arrow.down.to.line", steps: [
            .init(title: "Hijs eerst helemaal in top", text: "Begin altijd door de vlag helemaal naar boven te hijsen, tot de top van de mast."),
            .init(title: "Laat zakken tot een derde", text: "Laat de vlag daarna zakken tot hij op een derde van de masthoogte hangt, gemeten vanaf de top."),
            .init(title: "Zet de lijn vast", text: "Zet de lijn op deze positie vast. De vlag blijft hier hangen tijdens de hele herdenking."),
            .init(title: "Strijken: eerst weer in top", text: "Haal je de vlag in? Hijs hem dan eerst terug naar de top, en laat hem pas daarna helemaal zakken."),
        ]),
        Guide(id: "wimpel", title: "De wimpel bevestigen", symbol: "flag.2.crossed.fill", steps: [
            .init(title: "Controleer of een wimpel hoort", text: "De oranje wimpel hoort alleen bij Koningsdag en de verjaardagen van koningin Máxima, prinses Beatrix en prinses Amalia."),
            .init(title: "Bevestig boven de vlag", text: "De wimpel komt boven de vlag, aan de top van de mast. De punt wijst van de mast af."),
            .init(title: "Hijs de vlag eronder", text: "Hijs daarna de vlag zoals normaal, zodat de wimpel boven wappert en de vlag eronder hangt."),
            .init(title: "Haal tegelijk in", text: "Strijk vlag en wimpel tegelijk. Bewaar de wimpel droog en opgerold voor de volgende keer."),
        ]),
    ]
}

struct GuideView: View {
    @State private var selected = "hijsen"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Stap voor stap uitgelegd: hijsen, halfstok vlaggen en de wimpel.")
                        .font(.subheadline).foregroundStyle(Theme.muted)

                    Picker("Onderwerp", selection: $selected.animation(.snappy)) {
                        ForEach(Guide.all) { Text($0.id.capitalizedFirst).tag($0.id) }
                    }
                    .pickerStyle(.segmented)

                    if let guide = Guide.all.first(where: { $0.id == selected }) {
                        HStack {
                            Text(guide.title).font(Theme.display(26)).foregroundStyle(Theme.ink)
                            Spacer()
                            FlagGlyph(pennant: guide.id == "wimpel", halfMast: guide.id == "halfstok", size: 56)
                        }
                        .padding(.top, 4)

                        ForEach(Array(guide.steps.enumerated()), id: \.element.id) { index, step in
                            HStack(alignment: .top, spacing: 14) {
                                Text(String(format: "%02d", index + 1))
                                    .font(Theme.display(20, weight: .bold))
                                    .foregroundStyle(Theme.gold)
                                    .frame(width: 34, alignment: .leading)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title).font(.headline).foregroundStyle(Theme.ink)
                                    Text(step.text).font(.subheadline).foregroundStyle(Theme.muted)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Handleiding")
        }
    }
}
