import SwiftUI
import Charts
import CoreData

enum TimeScope: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    var id: Self { self }
}

struct StatsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BeerEntry.date, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<BeerEntry>

    @State private var scope: TimeScope = .week

    private var calendar: Calendar { Calendar.current }
    private var now = Date()

    // MARK: – Filtered entries in the chosen range
    private var scopedEntries: [BeerEntry] {
        guard let start = startDate(for: scope) else { return [] }
        return entries.filter {
            guard let d = $0.date else { return false }
            return d >= start && d <= now
        }
    }

    // MARK: – Summary stats
    private var totalBeers: Int { scopedEntries.count }
    private var uniqueBeers: Int {
        Set(scopedEntries.compactMap { $0.name }).count
    }
    private var busiestDayLabel: String {
        let grouped = Dictionary(grouping: scopedEntries) {
            calendar.startOfDay(for: $0.date!)
        }
        guard let (day, _) = grouped.max(by: { $0.value.count < $1.value.count }) else {
            return "—"
        }
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        return fmt.string(from: day)
    }

    // MARK: – Data for “Beers Over Time” chart
    private var timeBuckets: [(label: String, count: Int)] {
        switch scope {
        case .week:
            return lastSevenDays()
        case .month:
            return bucketsByWeekOfMonth()
        case .year:
            return bucketsByMonth()
        }
    }

    // MARK: – Top 5 beers in scope
    private var topBeers: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: scopedEntries, by: { $0.name ?? "Unknown" })
        return grouped.map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Scope picker
                Picker("Scope", selection: $scope) {
                    ForEach(TimeScope.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Summary cards
                HStack(spacing: 16) {
                    StatCard(title: "Total", value: "\(totalBeers)")
                    StatCard(title: "Unique", value: "\(uniqueBeers)")
                    StatCard(title: "Busiest", value: busiestDayLabel)
                }
                .padding(.horizontal)

                // Beers over time chart
                Card {
                    VStack(alignment: .leading) {
                        Text(chartTitle())
                            .font(.headline)
                        Chart(timeBuckets, id: \.label) { bucket in
                            BarMark(
                                x: .value("Period", bucket.label),
                                y: .value("Count", bucket.count)
                            )
                        }
                        .chartXAxis {
                            AxisMarks(values: timeBuckets.map { $0.label })
                        }
                    }
                    .padding()
                }
                .frame(height: 260)
                .padding(.horizontal)

                // Top 5 beers pie chart
                Card {
                    VStack(alignment: .leading) {
                        Text("Top 5 Beers")
                            .font(.headline)
                        Chart(topBeers, id: \.name) { item in
                            SectorMark(
                                angle: .value("Count", item.count)
                            )
                            .foregroundStyle(by: .value("Beer", item.name))
                        }
                        .chartLegend(.visible)
                        .chartLegend(position: .trailing)
                    }
                    .padding()
                }
                .frame(height: 280)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Stats")
    }

    // MARK: – Helpers

    private func startDate(for scope: TimeScope) -> Date? {
        switch scope {
        case .week:
            return calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            )
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: now)
            return calendar.date(from: comps)
        case .year:
            let comps = calendar.dateComponents([.year], from: now)
            return calendar.date(from: comps)
        }
    }

    private func lastSevenDays() -> [(String, Int)] {
        // Use the week’s Monday as the start
        guard let weekStart = startDate(for: .week) else { return [] }
        let fmt = DateFormatter(); fmt.dateFormat = "E"
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let label = fmt.string(from: date)
            let count = scopedEntries.filter {
                guard let d = $0.date else { return false }
                return calendar.isDate(d, inSameDayAs: date)
            }.count
            return (label, count)
        }
    }

    private func bucketsByWeekOfMonth() -> [(String, Int)] {
        let comps = scopedEntries.compactMap { entry -> Int? in
            guard let d = entry.date else { return nil }
            return calendar.component(.weekOfMonth, from: d)
        }
        let grouped = Dictionary(grouping: comps, by: { $0 })
        return grouped.sorted(by: { $0.key < $1.key }).map { (week, arr) in
            ("W\(week)", arr.count)
        }
    }

    private func bucketsByMonth() -> [(String, Int)] {
        let fmt = DateFormatter(); fmt.dateFormat = "MMM"
        let grouped = Dictionary(grouping: scopedEntries) { entry -> Int in
            guard let d = entry.date else { return 0 }
            return calendar.component(.month, from: d)
        }
        return grouped.sorted(by: { $0.key < $1.key }).map { (month, arr) in
            (fmt.shortMonthSymbols[month-1], arr.count)
        }
    }

    private func chartTitle() -> String {
        switch scope {
        case .week:  return "Beers This Week"
        case .month: return "Beers This Month"
        case .year:  return "Beers This Year"
        }
    }
}

// MARK: – Card & StatCard

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(radius: 4)
            )
    }
}

struct StatCard: View {
    let title: String, value: String
    var body: some View {
        VStack {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Text(value).font(.title).bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 4)
        )
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatsView()
                .environment(\.managedObjectContext,
                             PersistenceController.preview.container.viewContext)
        }
        .preferredColorScheme(.dark)
    }
}
