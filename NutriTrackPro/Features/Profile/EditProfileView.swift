import SwiftUI

/// Tela de edição do perfil com recálculo automático do TDEE.
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    @State private var tdeeResult: TDEEResult?
    @State private var showTDEEResult = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Dados pessoais") {
                    TextField("Nome", text: $profile.name)

                    HStack {
                        Text("Idade")
                        Spacer()
                        Stepper("\(profile.age) anos", value: $profile.age, in: 10...100)
                    }

                    Picker("Gênero", selection: Binding(
                        get: { profile.genderEnum },
                        set: { profile.gender = $0.rawValue }
                    )) {
                        ForEach(Gender.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                }

                Section("Medidas") {
                    numericRow("Peso atual", value: $profile.weightKg, unit: "kg")
                    numericRow("Peso alvo",  value: $profile.targetWeightKg, unit: "kg")
                    numericRow("Altura",     value: $profile.heightCm, unit: "cm")
                }

                Section("Atividade e objetivo") {
                    Picker("Nível de atividade", selection: Binding(
                        get: { profile.activityEnum },
                        set: { profile.activityLevel = $0.rawValue }
                    )) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }

                    Picker("Objetivo", selection: Binding(
                        get: { profile.goalEnum },
                        set: { profile.goal = $0.rawValue }
                    )) {
                        ForEach(HealthGoal.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                }

                Section {
                    Button("Recalcular metas") { recalculate() }
                        .foregroundStyle(AppColors.primary)
                }

                if showTDEEResult, let r = tdeeResult {
                    Section("Novas metas calculadas") {
                        resultRow("Calorias",    value: "\(Int(r.targetCalories)) kcal")
                        resultRow("Proteína",    value: "\(Int(r.proteinGoal)) g")
                        resultRow("Carboidratos", value: "\(Int(r.carbsGoal)) g")
                        resultRow("Gordura",     value: "\(Int(r.fatGoal)) g")
                        resultRow("Fibras",      value: "\(Int(r.fiberGoal)) g")
                    }
                }
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salvar") {
                        if let r = tdeeResult { applyTDEE(r) }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: – Helpers

    private func numericRow(_ label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Text(unit).foregroundStyle(AppColors.textSecondary)
        }
    }

    private func resultRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }

    private func recalculate() {
        let result = NutritionCalculator.calculate(profile: profile)
        tdeeResult = result
        withAnimation { showTDEEResult = true }
    }

    private func applyTDEE(_ r: TDEEResult) {
        profile.dailyCalorieGoal = r.targetCalories
        profile.dailyProteinGoal = r.proteinGoal
        profile.dailyCarbsGoal   = r.carbsGoal
        profile.dailyFatGoal     = r.fatGoal
        profile.dailyFiberGoal   = r.fiberGoal
    }
}
