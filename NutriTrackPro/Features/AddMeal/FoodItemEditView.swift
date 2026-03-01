import SwiftUI

/// Sheet para editar um alimento individualmente com recálculo em tempo real.
struct FoodItemEditView: View {
    @Binding var item: FoodAnalysisItem
    @Environment(\.dismiss) private var dismiss

    @State private var name: String       = ""
    @State private var weightText: String = ""
    @State private var cal100Text: String = ""
    @State private var pro100Text: String = ""
    @State private var carb100Text: String = ""
    @State private var fat100Text: String = ""
    @State private var fib100Text: String = ""

    private var weightG: Double   { Double(weightText)  ?? 0 }
    private var cal100:  Double   { Double(cal100Text)  ?? 0 }
    private var pro100:  Double   { Double(pro100Text)  ?? 0 }
    private var carb100: Double   { Double(carb100Text) ?? 0 }
    private var fat100:  Double   { Double(fat100Text)  ?? 0 }
    private var fib100:  Double   { Double(fib100Text)  ?? 0 }

    private func scaled(_ per100: Double) -> Double { (per100 * weightG) / 100 }

    private var calculatedCals: Double { (pro100 * 4 + carb100 * 4 + fat100 * 9) * weightG / 100 }
    private var mismatch: Bool {
        guard cal100 > 0 else { return false }
        return abs(scaled(cal100) - calculatedCals) > scaled(cal100) * 0.10
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Alimento") {
                    TextField("Nome", text: $name)
                    HStack {
                        Text("Peso")
                        Spacer()
                        TextField("gramas", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g").foregroundStyle(AppColors.textSecondary)
                    }
                }

                Section("Valores por 100g") {
                    numericRow("Calorias",    binding: $cal100Text,  unit: "kcal")
                    numericRow("Proteína",    binding: $pro100Text,  unit: "g")
                    numericRow("Carboidratos", binding: $carb100Text, unit: "g")
                    numericRow("Gordura",     binding: $fat100Text,  unit: "g")
                    numericRow("Fibras",      binding: $fib100Text,  unit: "g")
                }

                Section("Totais para \(weightText.isEmpty ? "0" : weightText)g") {
                    previewRow("Calorias",    value: scaled(cal100),  unit: "kcal", color: AppColors.accent)
                    previewRow("Proteína",    value: scaled(pro100),  unit: "g",    color: AppColors.protein)
                    previewRow("Carboidratos", value: scaled(carb100), unit: "g",    color: AppColors.carbs)
                    previewRow("Gordura",     value: scaled(fat100),  unit: "g",    color: AppColors.fat)
                    previewRow("Fibras",      value: scaled(fib100),  unit: "g",    color: AppColors.fiber)
                }

                if mismatch {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Divergência detectada", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColors.carbs)
                            Text("As calorias informadas (\(Int(scaled(cal100))) kcal) diferem das calculadas pelos macros (\(Int(calculatedCals)) kcal) em mais de 10%.")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            Button("Recalcular automaticamente") {
                                cal100Text = String(format: "%.0f", (pro100 * 4 + carb100 * 4 + fat100 * 9))
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppColors.primary)
                        }
                    }
                }
            }
            .navigationTitle("Editar alimento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salvar") { saveAndDismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { populateFields() }
        }
    }

    private func numericRow(_ label: String, binding: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: binding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Text(unit).foregroundStyle(AppColors.textSecondary).frame(width: 32)
        }
    }

    private func previewRow(_ label: String, value: Double, unit: String, color: Color) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(String(format: "%.1f %@", value, unit))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func populateFields() {
        name        = item.name
        weightText  = String(format: "%.0f", item.estimatedWeightG)
        // Backcompute per-100g values from absolute
        let w = item.estimatedWeightG > 0 ? item.estimatedWeightG : 100
        cal100Text  = String(format: "%.1f", item.calories  / w * 100)
        pro100Text  = String(format: "%.1f", item.proteinG  / w * 100)
        carb100Text = String(format: "%.1f", item.carbsG    / w * 100)
        fat100Text  = String(format: "%.1f", item.fatG      / w * 100)
        fib100Text  = String(format: "%.1f", item.fiberG    / w * 100)
    }

    private func saveAndDismiss() {
        item.name              = name
        item.estimatedWeightG  = weightG
        item.calories          = scaled(cal100)
        item.proteinG          = scaled(pro100)
        item.carbsG            = scaled(carb100)
        item.fatG              = scaled(fat100)
        item.fiberG            = scaled(fib100)
        dismiss()
    }
}
