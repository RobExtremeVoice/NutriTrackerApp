import SwiftUI
import SwiftData

/// Tela de diário alimentar com calendário semanal e log do dia.
struct DiaryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.timestamp, order: .reverse) private var allMeals: [Meal]

    @State private var selectedDate: Date = .now
    @State private var showAddMeal = false

    private let calendar = Calendar.current

    private var mealsForSelectedDay: [Meal] {
        allMeals.filter { $0.isOnDay(selectedDate) }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private var daysWithMeals: Set<Date> {
        Set(allMeals.map { calendar.startOfDay(for: $0.timestamp) })
    }

    private var weekNavTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate).capitalized
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Navegação de semana
                weekNavHeader
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.surface)

                // Calendário
                GlassCard(cornerRadius: 0) {
                    WeekCalendarView(
                        selectedDate: $selectedDate,
                        daysWithMeals: daysWithMeals
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }

                Divider()

                // Log do dia selecionado
                ScrollView {
                    DayLogView(meals: mealsForSelectedDay) { meal in
                        modelContext.delete(meal)
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    }
                    .padding(16)
                    Spacer(minLength: 80)
                }
                .background(AppColors.background)
            }
            .navigationTitle("Diário")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMeal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
        }
    }

    private var weekNavHeader: some View {
        HStack {
            Button {
                move(by: -7)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text(weekNavTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.text)

            Spacer()

            Button {
                move(by: 7)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 36, height: 36)
            }
        }
    }

    private func move(by days: Int) {
        withAnimation(.spring(duration: 0.3)) {
            selectedDate = calendar.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
        }
    }
}
