import SwiftUI
import UIKit

struct DiaryCalendar: View {
    let manager: FastingManager
    let select: (Date) -> Void
    @State private var visible: Date
    @State private var logged = Set<Date>()
    @State private var readFailed = false

    init(manager: FastingManager, select: @escaping (Date) -> Void) {
        self.manager = manager
        self.select = select
        _visible = State(initialValue: manager.todaysDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MarkedCalendar(selected: manager.todaysDate, displayed: $visible, logged: logged, select: select)
                .frame(maxWidth: .infinity).frame(minHeight: 330)
            if readFailed {
                Text("Diary dates could not be loaded.").font(.caption).foregroundStyle(WarmInk.muted)
            } else {
                Label("Days with logged foods", systemImage: "circle.fill")
                    .font(.caption).foregroundStyle(WarmInk.action)
            }
        }
        .task(id: Calendar.current.dateInterval(of: .month, for: visible)?.start) {
            let calendar = Calendar.current
            guard let month = calendar.dateInterval(of: .month, for: visible),
                  let start = calendar.date(byAdding: .day, value: -7, to: month.start),
                  let end = calendar.date(byAdding: .day, value: 7, to: month.end) else { return }
            do {
                let days = try await manager.loggedDays(from: start, until: end)
                try Task.checkCancellation()
                logged = days
                readFailed = false
            } catch {
                if !Task.isCancelled { logged = []; readFailed = true }
            }
        }
    }
}

private struct MarkedCalendar: UIViewRepresentable {
    let selected: Date
    @Binding var displayed: Date
    let logged: Set<Date>
    let select: (Date) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = .current
        view.locale = .current
        view.availableDateRange = DateInterval(start: .distantPast, end: .now)
        view.tintColor = UIColor(WarmInk.action)
        view.delegate = context.coordinator
        let behavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = behavior
        let day = view.calendar.dateComponents([.year, .month, .day], from: selected)
        view.setVisibleDateComponents(day, animated: false)
        behavior.setSelected(day, animated: false)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UICalendarView, context: Context) {
        let previous = context.coordinator.parent.logged
        context.coordinator.parent = self
        let changed = previous.symmetricDifference(logged)
        if !changed.isEmpty {
            view.reloadDecorations(forDateComponents: changed.map {
                view.calendar.dateComponents([.year, .month, .day], from: $0)
            }, animated: false)
        }
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: MarkedCalendar
        init(parent: MarkedCalendar) { self.parent = parent }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = calendarView.calendar.date(from: dateComponents),
                  parent.logged.contains(calendarView.calendar.startOfDay(for: date)) else { return nil }
            return .default(color: UIColor(WarmInk.action), size: .small)
        }

        func calendarView(_ calendarView: UICalendarView, didChangeVisibleDateComponentsFrom previous: DateComponents) {
            guard let date = calendarView.calendar.date(from: calendarView.visibleDateComponents),
                  !calendarView.calendar.isDate(parent.displayed, equalTo: date, toGranularity: .month) else { return }
            DispatchQueue.main.async { [weak self] in self?.parent.displayed = date }
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate components: DateComponents?) {
            guard let components, let date = Calendar.current.date(from: components), date <= .now else { return }
            parent.select(date)
        }
    }
}
