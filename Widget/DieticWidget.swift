import SwiftUI
import WidgetKit

private struct DiaryEntry: TimelineEntry {
    let date: Date
    let record: DiaryWidgetRecord?

    static func example(at date: Date) -> Self {
        let sample = DiaryWidgetData(day: Calendar.current.startOfDay(for: date), maintenance: 2180,
                                     calories: 1560, carbs: 166, protein: 96, fat: 57,
                                     proteinTarget: 119, fatTarget: 85, multiplier: 0.7)
        return Self(date: date, record: DiaryWidgetRecord(updated: date, data: sample))
    }
}

private struct DiaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> DiaryEntry { .example(at: .now) }

    func getSnapshot(in context: Context, completion: @escaping (DiaryEntry) -> Void) {
        let now = Date.now
        let record = DiaryWidgetRecord.today(at: now)
        completion(context.isPreview && record == nil ? .example(at: now) : DiaryEntry(date: now, record: record))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DiaryEntry>) -> Void) {
        let now = Date.now
        let midnight = Calendar.current.dateInterval(of: .day, for: now)!.end
        let current = DiaryEntry(date: now, record: DiaryWidgetRecord.today(at: now))
        // A scheduled empty entry clears yesterday even if the next refresh is delayed.
        completion(Timeline(entries: [current, DiaryEntry(date: midnight, record: nil)],
                            policy: .after(min(midnight, now.addingTimeInterval(30 * 60)))))
    }
}

private struct DiaryWidgetView: View {
    let entry: DiaryEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let journal = VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Dietic").font(.system(.headline, design: .serif).italic())
                Spacer(minLength: 2)
                if let record = entry.record {
                    Text(record.updated, style: .time).font(.caption2.monospacedDigit())
                        .accessibilityLabel("Updated \(record.updated.formatted(date: .omitted, time: .shortened))")
                }
            }
            if let data = entry.record?.data {
                HStack(spacing: 16) {
                    balance(data).frame(maxWidth: .infinity, alignment: .leading)
                    if family == .systemMedium {
                        Rectangle().fill(WarmInk.onHeaderSecondary.opacity(0.3)).frame(width: 1)
                        VStack(alignment: .leading, spacing: 7) {
                            macro("Carbs", data.carbs, data.carbTarget)
                            macro("Protein", data.protein, data.proteinTarget)
                            macro("Fat", data.fat, data.fatTarget)
                        }.frame(maxWidth: .infinity)
                    }
                }.privacySensitive()
            } else {
                Spacer(minLength: 0)
                Text("Today’s diary").font(.system(.title3, design: .serif))
                Text("Open Dietic to load today’s totals.").font(.caption)
                Spacer(minLength: 0)
            }
        }
        .foregroundStyle(WarmInk.paper)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(DiaryWidgetRecord.diaryURL)
        let background = LinearGradient(colors: [WarmInk.header, WarmInk.headerBase], startPoint: .topLeading, endPoint: .bottomTrailing)
        if #available(iOS 17.0, *) {
            journal.containerBackground(for: .widget) { background }
        } else {
            journal.padding(13).background(background)
        }
    }

    private func balance(_ data: DiaryWidgetData) -> some View {
        let net = data.balance.map { Int($0.rounded()) }
        let label = net.map { $0 > 0 ? "Estimated deficit" : ($0 < 0 ? "Estimated surplus" : "Break even") } ?? "Calories logged"
        return VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption).foregroundStyle(WarmInk.onHeaderSecondary)
            Text("\(abs(net ?? Int(data.calories.rounded())).formatted()) kcal")
                .font(.system(.title2, design: .serif).weight(.medium)).lineLimit(1).minimumScaleFactor(0.7)
            if let target = data.targetBalance {
                let kcal = Int(target.rounded())
                Text(kcal == 0 ? "Target: break even" : "Target: \(abs(kcal)) kcal \(kcal > 0 ? "deficit" : "surplus")")
                    .font(.caption2).fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Balance unavailable").font(.caption2)
            }
            Spacer(minLength: 2)
            if let goal = data.calorieGoal {
                Text("\(Int(data.calories.rounded())) / \(Int(goal)) kcal")
                    .font(.caption2.monospacedDigit()).lineLimit(1).minimumScaleFactor(0.7)
                IntakeChart(amount: data.calories.rounded(), target: goal, miniature: true)
            }
        }
    }

    private func macro(_ label: String, _ amount: Double, _ target: Double?) -> some View {
        let grams = Int(amount.rounded())
        let goal = target.map { Int($0.rounded()) }
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text(label).fontWeight(.semibold)
                Spacer(minLength: 0)
                Text(goal.map { "\(grams)/\($0) g" } ?? "\(grams) g")
            }.font(.caption2).lineLimit(1).minimumScaleFactor(0.75)
            IntakeChart(amount: amount, target: target, miniature: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(goal.map { Text("\(grams) of \($0) grams") } ?? Text("\(grams) grams, target unavailable"))
    }
}

struct DieticWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: DiaryWidgetRecord.kind, provider: DiaryProvider()) { entry in
            DiaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily balance")
        .description("See your estimated calorie balance and daily target. The medium widget also shows your macros.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct LogShortcutEntry: TimelineEntry {
    let date: Date
}

private struct LogShortcutProvider: TimelineProvider {
    func placeholder(in context: Context) -> LogShortcutEntry { .init(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (LogShortcutEntry) -> Void) { completion(.init(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<LogShortcutEntry>) -> Void) {
        completion(Timeline(entries: [.init(date: .now)], policy: .never))
    }
}

private struct LogShortcutsView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if #available(iOS 17, *) { content.containerBackground(for: .widget) { WarmInk.paper } }
        else { content.padding(6) }
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .accessoryCircular:
            Image(systemName: "barcode.viewfinder").font(.title)
                .accessibilityLabel("Scan grocery barcode").widgetURL(DiaryShortcut.barcode.url)
        case .accessoryRectangular:
            Label("Scan barcode", systemImage: "barcode.viewfinder")
                .font(.headline).widgetURL(DiaryShortcut.barcode.url)
        default:
            VStack(alignment: .leading, spacing: 8) {
                Text("Log food").font(.system(.headline, design: .serif)).foregroundStyle(WarmInk.text)
                HStack(spacing: 8) {
                    shortcut("Barcode", "barcode.viewfinder", .barcode)
                    shortcut("Plate", "camera", .plate)
                    shortcut("Quick add", "bolt", .quickAdd)
                }
            }.widgetURL(DiaryWidgetRecord.diaryURL)
        }
    }

    private func shortcut(_ name: String, _ symbol: String, _ route: DiaryShortcut) -> some View {
        Link(destination: route.url) {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.title3)
                Text(name).font(.caption.weight(.semibold))
            }.padding(.vertical, 8).frame(maxWidth: .infinity)
                .foregroundStyle(WarmInk.action).background(WarmInk.apricot.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct LoggingShortcutsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DieticLoggingShortcuts", provider: LogShortcutProvider()) { _ in LogShortcutsView() }
            .configurationDisplayName("Food shortcuts")
            .description("Scan a barcode from your Lock Screen or choose a logging method from your Home Screen.")
            .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemMedium])
    }
}

@main
struct DieticWidgets: WidgetBundle {
    var body: some Widget {
        DieticWidget()
        LoggingShortcutsWidget()
    }
}
