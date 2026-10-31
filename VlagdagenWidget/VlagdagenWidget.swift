import SwiftUI
import WidgetKit

struct FlagEntry: TimelineEntry {
    let date: Date
    let today: FlagDay?
    let next: FlagDay?
}

struct FlagProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlagEntry { entry(for: .now) }

    func getSnapshot(in context: Context, completion: @escaping (FlagEntry) -> Void) {
        completion(entry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlagEntry>) -> Void) {
        // Eén entry per dag, om middernacht, een week vooruit.
        let today = FlagCalendar.startOfDay(.now)
        var entries = [entry(for: .now)]
        for offset in 1...7 {
            entries.append(entry(for: FlagCalendar.addDays(offset, to: today)))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(for date: Date) -> FlagEntry {
        FlagEntry(date: date, today: FlagCalendar.flagDay(on: date), next: FlagCalendar.next(after: date))
    }
}

struct VlagdagenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FlagEntry

    private var isYes: Bool { entry.today != nil && entry.today?.kind.isLocalOnly == false }

    var body: some View {
        switch family {
        case .accessoryInline:
            if let today = entry.today {
                Label(isYes ? "Vlag uit: \(today.kind.shortTitle)" : today.kind.shortTitle, systemImage: "flag.fill")
            } else if let next = entry.next {
                Label("\(next.kind.shortTitle) · \(FlagFormat.dayMonth.string(from: next.date))", systemImage: "flag")
            }
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: isYes ? "flag.fill" : "flag")
                    if isYes {
                        Text("Ja").font(.headline)
                    } else if let next = entry.next {
                        Text("\(FlagCalendar.daysUntil(next, from: entry.date))d").font(.headline)
                    }
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Label(isYes ? "Vlag uit!" : "Vlag vandaag: nee", systemImage: "flag.fill")
                    .font(.headline)
                if let today = entry.today {
                    Text(today.title).lineLimit(1)
                    Text(today.kind.instruction).font(.caption2).lineLimit(1)
                } else if let next = entry.next {
                    Text(next.kind.shortTitle).lineLimit(1)
                    Text("\(FlagFormat.dayMonth.string(from: next.date)) · \(FlagFormat.relative(FlagCalendar.daysUntil(next, from: entry.date)).lowercased())")
                        .font(.caption2)
                }
            }
        case .systemMedium:
            HStack(spacing: 16) {
                answerBlock
                Divider().overlay(.white.opacity(0.2))
                if let next = entry.next { nextBlock(next) }
            }
        default:
            VStack(alignment: .leading, spacing: 6) {
                answerBlock
                Spacer(minLength: 0)
                if entry.today == nil, let next = entry.next {
                    Text(next.kind.shortTitle).font(.caption.weight(.semibold)).foregroundStyle(.white).lineLimit(2)
                    Text(FlagFormat.relative(FlagCalendar.daysUntil(next, from: entry.date)))
                        .font(.caption2).foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var answerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("VLAG VANDAAG?").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.gold)
                Spacer(minLength: 0)
                FlagGlyph(pennant: entry.today?.kind.hasPennant ?? false,
                          halfMast: entry.today?.kind.isHalfMast ?? false, size: 24)
            }
            Text(isYes ? "Ja." : (entry.today?.kind.isLocalOnly == true ? "Den Haag" : "Nee."))
                .font(Theme.display(isYes ? 40 : 36, weight: .bold))
                .foregroundStyle(Theme.gold)
                .minimumScaleFactor(0.6)
            if let today = entry.today {
                Text(today.title).font(.caption.weight(.semibold)).foregroundStyle(.white).lineLimit(2)
                Text(today.kind.instruction).font(.caption2).foregroundStyle(.white.opacity(0.7)).lineLimit(2)
            }
        }
    }

    private func nextBlock(_ next: FlagDay) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("VOLGENDE").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.6))
            Text(next.title).font(Theme.display(16)).foregroundStyle(.white).lineLimit(2)
            Text(FlagFormat.full.string(from: next.date).capitalizedFirst)
                .font(.caption2).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
            Spacer(minLength: 0)
            Text(FlagFormat.relative(FlagCalendar.daysUntil(next, from: entry.date)))
                .font(.caption.weight(.bold)).foregroundStyle(Theme.gold)
            if next.kind.hasPennant { Badge(text: "Wimpel") }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VlagdagenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VlagdagenWidget", provider: FlagProvider()) { entry in
            VlagdagenWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Theme.heroTop, Theme.heroBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                .widgetURL(URL(string: "vlagdagen://today"))
        }
        .configurationDisplayName("Vlagdagen")
        .description("Mag de vlag vandaag uit? En wanneer is de volgende vlagdag?")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct VlagdagenWidgetBundle: WidgetBundle {
    var body: some Widget {
        VlagdagenWidget()
    }
}
