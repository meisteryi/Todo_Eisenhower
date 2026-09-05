import WidgetKit
import SwiftUI

// MARK: - Dashboard Summary Widget (Q1 ~ Q4 + Workout)
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), streak: 5, q1Count: 2, q2Count: 3, q3Count: 1, q4Count: 0, totalPending: 6, workoutCompleted: 3, workoutTotal: 4)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func loadEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.example.todo_eisenhower")
        let streak = userDefaults?.integer(forKey: "workout_streak") ?? 0
        let q1Count = userDefaults?.integer(forKey: "q1_count") ?? 0
        let q2Count = userDefaults?.integer(forKey: "q2_count") ?? 0
        let q3Count = userDefaults?.integer(forKey: "q3_count") ?? 0
        let q4Count = userDefaults?.integer(forKey: "q4_count") ?? 0
        let totalPending = userDefaults?.integer(forKey: "total_pending") ?? 0
        let workoutCompleted = userDefaults?.integer(forKey: "workout_completed") ?? 0
        let workoutTotal = userDefaults?.integer(forKey: "workout_total") ?? 0
        
        return SimpleEntry(
            date: Date(),
            streak: streak,
            q1Count: q1Count,
            q2Count: q2Count,
            q3Count: q3Count,
            q4Count: q4Count,
            totalPending: totalPending,
            workoutCompleted: workoutCompleted,
            workoutTotal: workoutTotal
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let q1Count: Int
    let q2Count: Int
    let q3Count: Int
    let q4Count: Int
    let totalPending: Int
    let workoutCompleted: Int
    let workoutTotal: Int
}

struct TodoWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("아이젠하워 & 오운완")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.gray)
                Spacer()
                Text("🔥 \(entry.streak)일째")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.green)
            }
            
            Divider()
            
            // 4 Quadrants Grid
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🚨 Q1 긴급: \(entry.q1Count)개")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.red)
                    Text("👥 Q3 대리: \(entry.q3Count)개")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("🎯 Q2 목표: \(entry.q2Count)개")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.green)
                    Text("🗑 Q4 휴식: \(entry.q4Count)개")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(.orange)
                    .font(.caption2)
                Text("운동: \(entry.workoutCompleted)/\(entry.workoutTotal)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("전체: \(entry.totalPending)개")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct TodoWidgetProvider: Widget {
    let kind: String = "TodoWidgetProvider"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("아이젠하워 Q1~Q4 요약")
        .description("Q1 긴급, Q2 목표, Q3 대리, Q4 휴식 할 일 및 운동 스트릭을 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Today Q1 & Q2 Tasks List Widget (Medium Horizontal)
struct TasksEntry: TimelineEntry {
    let date: Date
    let q1Count: Int
    let q2Count: Int
    let q1Titles: [String]
    let q2Titles: [String]
}

struct TasksProvider: TimelineProvider {
    func placeholder(in context: Context) -> TasksEntry {
        TasksEntry(date: Date(), q1Count: 2, q2Count: 2, q1Titles: ["팀 미팅 준비", "보고서 제출"], q2Titles: ["운동 30분", "독서 1시간"])
    }

    func getSnapshot(in context: Context, completion: @escaping (TasksEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TasksEntry>) -> ()) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func loadEntry() -> TasksEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.example.todo_eisenhower")
        let q1Count = userDefaults?.integer(forKey: "q1_count") ?? 0
        let q2Count = userDefaults?.integer(forKey: "q2_count") ?? 0
        
        let t1 = userDefaults?.string(forKey: "q1_title_1") ?? ""
        let t2 = userDefaults?.string(forKey: "q1_title_2") ?? ""
        let t3 = userDefaults?.string(forKey: "q1_title_3") ?? ""
        let q1Titles = [t1, t2, t3].filter { !$0.isEmpty }

        let q2t1 = userDefaults?.string(forKey: "q2_title_1") ?? ""
        let q2t2 = userDefaults?.string(forKey: "q2_title_2") ?? ""
        let q2t3 = userDefaults?.string(forKey: "q2_title_3") ?? ""
        let q2Titles = [q2t1, q2t2, q2t3].filter { !$0.isEmpty }

        return TasksEntry(
            date: Date(),
            q1Count: q1Count,
            q2Count: q2Count,
            q1Titles: q1Titles,
            q2Titles: q2Titles
        )
    }
}

struct TodoTasksWidgetEntryView : View {
    var entry: TasksProvider.Entry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Q1 Column
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("🚨 Q1 긴급 (\(entry.q1Count))")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.red)
                }
                Divider()
                if entry.q1Titles.isEmpty {
                    Text("• (없음)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                } else {
                    ForEach(entry.q1Titles.prefix(3), id: \.self) { title in
                        Text("• \(title)")
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Q2 Column
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("🎯 Q2 목표 (\(entry.q2Count))")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.green)
                }
                Divider()
                if entry.q2Titles.isEmpty {
                    Text("• (없음)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                } else {
                    ForEach(entry.q2Titles.prefix(3), id: \.self) { title in
                        Text("• \(title)")
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct TodoTasksWidgetProvider: Widget {
    let kind: String = "TodoTasksWidgetProvider"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TasksProvider()) { entry in
            TodoTasksWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Q1 & Q2 오늘의 할 일")
        .description("오늘 기준 Q1(긴급/중요) 및 Q2(목표/계획) 할 일 리스트를 한눈에 확인하세요.")
        .supportedFamilies([.systemMedium])
    }
}
