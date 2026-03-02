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

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedDate).capitalized
    }

    private var selectedDateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "EEEE, d 'de' MMMM"
        let str = f.string(from: selectedDate).capitalized
        return calendar.isDateInToday(selectedDate) ? "Hoje · \(str)" : str
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Calendar card with integrated month navigation + swipe gesture
                    calendarCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // Selected date label + "Hoje" shortcut
                    HStack {
                        Text(selectedDateLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        if !calendar.isDateInToday(selectedDate) {
                            Button("Hoje") {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedDate = .now
                                }
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                    // Day meals log
                    DayLogView(
                        meals: mealsForSelectedDay,
                        onAddMeal: { showAddMeal = true }
                    ) { meal in
                        modelContext.delete(meal)
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationTitle("Diário")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottomTrailing) { fab }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
        }
    }

    // MARK: – Calendar card

    private var calendarCard: some View {
        GlassCard {
            VStack(spacing: 4) {
                // Month navigation row
                HStack {
                    Button { move(by: -7) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 36, height: 36)
                    }
                    Spacer()
                    Text(monthTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Button { move(by: 7) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 10)

                // Week days
                WeekCalendarView(
                    selectedDate: $selectedDate,
                    daysWithMeals: daysWithMeals
                )
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
        }
        // Swipe left → next week, swipe right → prev week
        .gesture(
            DragGesture(minimumDistance: 40, coordinateSpace: .local)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    withAnimation(.spring(duration: 0.3)) {
                        move(by: value.translation.width < 0 ? 7 : -7)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
        )
    }

    // MARK: – FAB

    private var fab: some View {
        Button { showAddMeal = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppColors.primary, in: Circle())
                .shadow(color: AppColors.primary.opacity(0.4), radius: 12, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private func move(by days: Int) {
        selectedDate = calendar.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
    }
}
