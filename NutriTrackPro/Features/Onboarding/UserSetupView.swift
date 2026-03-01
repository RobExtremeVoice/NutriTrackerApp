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
    @State private var waterLiters = 2.5

    // Resultado calculado
    @State private var tdeeResult: TDEEResult?
    @State private var showResult  = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Configure seu perfil")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppColors.text)
                        Text("Vamos calcular suas metas personalizadas")
                            .font(.system(size: 15))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    // Form glass card
                    VStack(spacing: 0) {

                        // Nome
                        formRow {
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 22)
                                TextField("Seu nome", text: $name)
                                    .font(.system(size: 15, weight: .medium))
                            }
                        }

                        rowDivider

                        // Idade
                        formRow {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 22)
                                Text("Idade")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppColors.text)
                                Spacer()
                                HStack(spacing: 0) {
                                    Button { if age > 10 { age -= 1 } } label: {
                                        Text("−")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(AppColors.primary)
                                            .frame(width: 36, height: 32)
                                    }
                                    Text("\(age) anos")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppColors.text)
                                        .frame(minWidth: 64, alignment: .center)
                                    Button { if age < 100 { age += 1 } } label: {
                                        Text("+")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(AppColors.primary)
                                            .frame(width: 36, height: 32)
                                    }
                                }
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        rowDivider

                        // Gênero
                        formRow {
                            Picker("Gênero", selection: $gender) {
                                ForEach(Gender.allCases, id: \.self) { g in
                                    Text(g.displayName).tag(g)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        rowDivider

                        // Peso e Meta — grade 2 colunas
                        formRow {
                            HStack(spacing: 12) {
                                metricCell(label: "⚖️ Peso Atual", value: $weightKg, unit: "kg")
                                metricCell(label: "🎯 Meta",        value: $targetKg,  unit: "kg")
                            }
                        }

                        rowDivider

                        // Altura
                        formRow {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 22)
                                Text("Altura")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppColors.text)
                                Spacer()
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    TextField("170", value: $heightCm, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 52)
                                        .font(.system(size: 16, weight: .bold))
                                    Text("cm")
                                        .font(.system(size: 13))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                        }

                        rowDivider

                        // Nível de Atividade
                        formRow {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(AppColors.primary)
                                    .frame(width: 22)
                                Text("Nível de Atividade")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppColors.text)
                                Spacer()
                                Picker("", selection: $activity) {
                                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                                        Text(level.displayName).tag(level)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(AppColors.primary)
                                .font(.system(size: 14, weight: .bold))
                            }
                        }

                        rowDivider

                        // Meta de Hidratação
                        formRow {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundStyle(Color.blue)
                                    .frame(width: 22)
                                Text("Meta de Hidratação")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppColors.text)
                                Spacer()
                                HStack(spacing: 0) {
                                    Button { if waterLiters > 1.0 { waterLiters = (waterLiters - 0.5 * 2).rounded() / 2 } } label: {
                                        Text("−")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(Color.blue)
                                            .frame(width: 36, height: 32)
                                    }
                                    Text(String(format: "%.1f L", waterLiters))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppColors.text)
                                        .frame(minWidth: 60, alignment: .center)
                                    Button { if waterLiters < 6.0 { waterLiters = (waterLiters * 2 + 1).rounded() / 2 } } label: {
                                        Text("+")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(Color.blue)
                                            .frame(width: 36, height: 32)
                                    }
                                }
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        rowDivider

                        // Objetivo
                        formRow {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("OBJETIVO")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .tracking(1)
                                Picker("", selection: $goal) {
                                    ForEach(HealthGoal.allCases, id: \.self) { g in
                                        Text(g.displayName).tag(g)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                    .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                    .padding(.horizontal, 16)

                    // Resultado TDEE
                    if showResult, let r = tdeeResult {
                        tdeeResultCard(r)
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Botão
                    VStack(spacing: 12) {
                        if showResult && tdeeResult != nil {
                            saveButton
                        } else {
                            calculateButton
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    // MARK: - Subviews

    private var rowDivider: some View {
        Divider().padding(.leading, 48)
    }

    private func formRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }

    private func metricCell(label: String, value: Binding<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.5)
            HStack {
                TextField("0", value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)
                Spacer()
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity)
    }

    private func tdeeResultCard(_ r: TDEEResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUAS METAS DIÁRIAS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .tracking(1)
                .padding(.horizontal, 4)

            HStack(spacing: 8) {
                tdeeCell(value: "\(Int(r.targetCalories))", unit: "kcal", color: AppColors.text)
                tdeeCell(value: "\(Int(r.proteinGoal))g", unit: "P", color: AppColors.protein, accent: true)
                tdeeCell(value: "\(Int(r.carbsGoal))g",   unit: "C", color: AppColors.carbs,   accent: true)
                tdeeCell(value: "\(Int(r.fatGoal))g",     unit: "G", color: AppColors.fat,     accent: true)
                tdeeCell(value: String(format: "%.1fL", waterLiters), unit: "Água", color: Color.blue, accent: true)
            }
        }
    }

    private func tdeeCell(value: String, unit: String, color: Color, accent: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .bottom) {
            if accent {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(height: 3)
                    .padding(.horizontal, 12)
                    .offset(y: -1)
            }
        }
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var calculateButton: some View {
        Button {
            calculate()
        } label: {
            HStack(spacing: 8) {
                Text("Calcular minhas metas")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "sparkles")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.primary.opacity(0.35), radius: 12, y: 4)
        }
    }

    private var saveButton: some View {
        Button {
            saveProfile()
        } label: {
            HStack(spacing: 8) {
                Text("Salvar e começar")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppColors.primary.opacity(0.35), radius: 12, y: 4)
        }
    }

    // MARK: - Logic

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
            dailyFiberGoal: r.fiberGoal,
            dailyWaterGoal: Int(waterLiters * 1000)
        )
        modelContext.insert(profile)
        hasCompletedOnboarding = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
