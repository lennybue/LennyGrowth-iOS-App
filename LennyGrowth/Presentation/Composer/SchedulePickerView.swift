import SwiftUI

struct SchedulePickerView: View {
    @Binding var selectedDate: Date
    let onSchedule: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var calendarDate: Date = Date()
    @State private var selectedTime: Date = Date.nextHour()
    private let minimumDate = Date()

    var body: some View {
        VStack(spacing: 0) {
            // Calendar date strip
            calendarStrip
                .padding()

            Divider()

            // Time picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Time")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal)

                DatePicker(
                    "Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)

                Text("Your post will be sent at \(combinedDate.fullDateString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
            .padding(.vertical)

            Divider()

            // Quick time suggestions
            quickTimeOptions
                .padding()

            Spacer()

            // CTA
            VStack(spacing: 12) {
                Button {
                    selectedDate = combinedDate
                    onSchedule()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("Schedule for \(combinedDate.scheduledString)")
                    }
                }
                .primaryButtonStyle()
                .disabled(combinedDate <= Date())

                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Schedule Post")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calendarDate = selectedDate.startOfDay()
            selectedTime = selectedDate
        }
    }

    private var combinedDate: Date {
        let calendar = Calendar.current
        var timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: calendarDate)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        return calendar.date(from: dateComponents) ?? selectedTime
    }

    private var calendarStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Date")
                .font(.subheadline)
                .fontWeight(.semibold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(nextSevenDays, id: \.self) { date in
                        DayButton(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: calendarDate)
                        ) {
                            calendarDate = date
                        }
                    }
                }
            }
        }
    }

    private var nextSevenDays: [Date] {
        (0..<14).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: Date().startOfDay())
        }
    }

    private var quickTimeOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Options")
                .font(.subheadline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(quickTimes, id: \.0) { label, time in
                    Button {
                        selectedTime = time
                        calendarDate = time.startOfDay()
                    } label: {
                        Text(label)
                            .font(.caption)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }

    private var quickTimes: [(String, Date)] {
        let now = Date()
        return [
            ("In 1 hour", now.adding(hours: 1)),
            ("In 3 hours", now.adding(hours: 3)),
            ("Tomorrow morning", Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: now.adding(days: 1)) ?? now.adding(hours: 24)),
            ("Tomorrow afternoon", Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: now.adding(days: 1)) ?? now.adding(hours: 28)),
        ]
    }
}

struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .secondary)

                Text(dayNumber)
                    .font(.headline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)

                if isToday {
                    Circle()
                        .fill(isSelected ? .white : Color.primaryBrand)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 48, height: 64)
            .background(isSelected ? Color.primaryBrand : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

#Preview {
    NavigationStack {
        SchedulePickerView(selectedDate: .constant(Date.nextHour())) {}
    }
}
