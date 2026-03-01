import SwiftUI
import SwiftData

/// Formulário de configuração inicial — coleta dados e calcula TDEE.
struct UserSetupView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(AppConstants.Defaults.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    // Campos do formulário
    @State private var name        = ""
    @State private var age         = 25
    @State private var gender      = Gender.male
    @State private var weightKg    = 70.0
    @State private var targetKg    = 70.0
    @State private var heightCm    = 170.0
    @State private var activity    = ActivityLevel.moderate
    @State private var goal        = HealthGoal.maintain

    // Resultado calculado
    @State private var tdeeResult: TDEEResult?
    @State private var showResult  = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Configure seu perfil")
                            .font(.title.weight(.bold))
                            .foregroundStyle(AppColors.text)
                        Text("Vamos calcular suas metas personalizadas")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.top, 24)

                    // Form
                    GlassCard(cornerRadius: AppConstants.largeCornerRadius) {
                        VStack(spacing: 20) {
                            formTextField("Nome completo", text: $name, icon: "person.fill")

                            Divider()

                            HStack {
                                Label("Idade", systemImage: "birthday.cake.fill")
                                    .foregroundStyle(AppColors.text)
                                    .font(.system(size: 15))
                                Spacer()
                                Stepper("\(age) anos", value: $age, in: 10...100)
                                    .font(.system(size: 15))
                            }

                            Divider()

                            Picker("Gênero", selection: $gender) {
                                ForEach(Gender.allCases, id: \.self) { g in
                                    Text(g.displayName).tag(g)
                                }
                            }
                            .pickerStyle(.segmented)

                            Divider()

                            formNumericRow("Peso atual",  value: $weightKg, unit: "kg", icon: "scalemass.fill")
                            formNumericRow("Peso alvo",   value: $targetKg,  unit: "kg", icon: "target")
                            formNumericRow("Altura",      value: $heightCm,  unit: "cm", icon: "ruler.fill")

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Label("Nível de atividade", systemImage: "figure.run")
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppColors.text)

                                Picker("", selection: $activity) {
                                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                                        Text(level.displayName).tag(level)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(AppColors.primary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Label("Objetivo", systemImage: "flag.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppColors.text)

                                Picker("", selection: $goal) {
                                    ForEach(HealthGoal.allCases, id: \.self) { g in
                                        Text(g.displayName).tag(g)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 16)

                    // Resultado do TDEE
                    if showResult, let r = tdeeResult {
                        tdeeResultCard(r)
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Botões
                    VStack(spacing: 12) {
                        if showResult && tdeeResult != nil {
                            PrimaryButton(title: "Salvar e começar", icon: "checkmark.circle.fill") {
                                saveProfile()
                            }
                        } else {
                            PrimaryButton(title: "Calcular minhas metas", icon: "sparkles") {
                                calculate()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: – Subviews

    private func formTextField(_ label: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.primary)
                .frame(width: 20)
            TextField(label, text: text)
                .font(.system(size: 15))
        }
    }

    private func formNumericRow(_ label: String, value: Binding<Double>, unit: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(AppColors.primary)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.text)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
            Text(unit)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func tdeeResultCard(_ r: TDEEResult) -> some View {
        GlassCard(cornerRadius: AppConstants.largeCornerRadius) {
            VStack(spacing: 16) {
                Text("Suas metas diárias")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.text)

                HStack(spacing: 0) {
                    tdeeMetric("Calorias", value: "\(Int(r.targetCalories))", unit: "kcal", color: AppColors.accent)
                    Divider().frame(height: 50)
                    tdeeMetric("Proteína", value: "\(Int(r.proteinGoal))", unit: "g", color: AppColors.protein)
                    Divider().frame(height: 50)
                    tdeeMetric("Carbs",    value: "\(Int(r.carbsGoal))",   unit: "g", color: AppColors.carbs)
                    Divider().frame(height: 50)
                    tdeeMetric("Gordura",  value: "\(Int(r.fatGoal))",     unit: "g", color: AppColors.fat)
                }

                Text("Baseado na fórmula Mifflin-St Jeor com fator de atividade \(String(format: "×%.2f", r.tdee / r.bmr))")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
    }

    private func tdeeMetric(_ label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textSecondary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Logic

    private func calculate() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let result = NutritionCalculator.calculate(
            weightKg: weightKg, heightCm: heightCm, age: age,
            gender: gender, activity: activity, goal: goal
        )
        tdeeResult = result
        withAnimation(.spring(duration: 0.5)) { showResult = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func saveProfile() {
        guard let r = tdeeResult else { return }
        let profile = UserProfile(
            name: name,
            age: age,
            gender: gender,
            weightKg: weightKg,
            heightCm: heightCm,
            targetWeightKg: targetKg,
            activityLevel: activity,
            goal: goal,
            dailyCalorieGoal: r.targetCalories,
            dailyProteinGoal: r.proteinGoal,
            dailyCarbsGoal: r.carbsGoal,
            dailyFatGoal: r.fatGoal,
            dailyFiberGoal: r.fiberGoal
        )
        modelContext.insert(profile)
        hasCompletedOnboarding = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
