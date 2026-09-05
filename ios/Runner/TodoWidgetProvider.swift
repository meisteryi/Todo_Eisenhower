import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), streak: 5, q1Count: 2, totalPending: 8, workoutCompleted: 3, workoutTotal: 4)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.example.todo_eisenhower")
        let streak = userDefaults?.integer(forKey: "workout_streak") ?? 0
        let q1Count = userDefaults?.integer(forKey: "q1_count") ?? 0
        let totalPending = userDefaults?.integer(forKey: "total_pending") ?? 0
        let workoutCompleted = userDefaults?.integer(forKey: "workout_completed") ?? 0
        let workoutTotal = userDefaults?.integer(forKey: "workout_total") ?? 0
        
        let entry = SimpleEntry(
            date: Date(),
            streak: streak,
            q1Count: q1Count,
            totalPending: totalPending,
            workoutCompleted: workoutCompleted,
            workoutTotal: workoutTotal
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.example.todo_eisenhower")
        let streak = userDefaults?.integer(forKey: "workout_streak") ?? 0
        let q1Count = userDefaults?.integer(forKey: "q1_count") ?? 0
        let totalPending = userDefaults?.integer(forKey: "total_pending") ?? 0
        let workoutCompleted = userDefaults?.integer(forKey: "workout_completed") ?? 0
        let workoutTotal = userDefaults?.integer(forKey: "workout_total") ?? 0
        
        let entry = SimpleEntry(
            date: Date(),
            streak: streak,
            q1Count: q1Count,
            totalPending: totalPending,
            workoutCompleted: workoutCompleted,
            workoutTotal: workoutTotal
        )
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let q1Count: Int
    let totalPending: Int
    let workoutCompleted: Int
    let workoutTotal: Int
}

struct TodoWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("아이젠하워 & 오운완")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                Spacer()
                Text("🔥 \(entry.streak)일째")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.green)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("Q1 긴급 할 일: \(entry.q1Count)개")
                        .font(.caption)
                        .bold()
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("전체 보관 할 일: \(entry.totalPending)개")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("오늘 운동: \(entry.workoutCompleted)/\(entry.workoutTotal)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

@main
struct TodoWidgetProvider: Widget {
    let kind: String = "TodoWidgetProvider"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("아이젠하워 & 오운완")
        .description("오늘의 오운완 스트릭과 아이젠하워 긴급 할 일을 홈 화면에서 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
