import SwiftUI

/// Calendário de 7 dias horizontais com indicadores de refeições.
struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    let daysWithMeals: Set<Date>  // dates normalized to start of day

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: selectedDate)
        // Começa na segunda-feira da semana atual
        let weekday  = calendar.component(.weekday, from: today)
        // weekday: 1=Dom, 2=Seg... convertemos para segunda como início
        let offset   = (weekday + 5) % 7   // dias desde segunda
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0 - offset, to: today) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                dayCell(day)
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let calendar  = Calendar.current
        let isToday   = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasLog    = daysWithMeals.contains(calendar.startOfDay(for: date))

        let dayLabel: String = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.dateFormat = "EEE"
            return formatter.string(from: date).prefix(3).uppercased()
        }()

        let dayNumber = calendar.component(.day, from: date)

        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedDate = date
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 6) {
                Text(dayLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? .white : AppColors.textSecondary)

                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.primary : (isToday ? AppColors.primary.opacity(0.12) : Color.clear))
                        .frame(width: 32, height: 32)
                    Text("\(dayNumber)")
                        .font(.system(size: 14, weight: isSelected || isToday ? .bold : .regular))
                        .foregroundStyle(isSelected ? .white : (isToday ? AppColors.primary : AppColors.text))
                }

                // Ponto indicador de refeições
                Circle()
                    .fill(hasLog ? AppColors.primary : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
