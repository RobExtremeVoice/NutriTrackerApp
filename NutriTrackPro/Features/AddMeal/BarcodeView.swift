import SwiftUI
import SwiftData

/// Entrada manual de alimentos — busca na biblioteca pessoal do usuário e confirmação via IA.
struct BarcodeView: View {
    @Binding var foodDescription: String
    let onAnalyze: () -> Void

    @State private var searchText    = ""
    @State private var selectedFood: LibraryFood? = nil
    @FocusState private var searchFocused: Bool

    /// Todos os itens já registrados pelo usuário (fonte da biblioteca pessoal)
    @Query(sort: \FoodItem.name) private var allFoodItems: [FoodItem]

    /// Top 20 alimentos mais frequentes nos registros do usuário
    private var libraryFoods: [LibraryFood] {
        var frequency: [String: (item: FoodItem, count: Int)] = [:]
        for item in allFoodItems {
            let key = item.name.lowercased()
            if let existing = frequency[key] {
                frequency[key] = (existing.item, existing.count + 1)
            } else {
                frequency[key] = (item, 1)
            }
        }
        return frequency.values
            .sorted { $0.count > $1.count }
            .prefix(20)
            .map { entry in
                let n = entry.item.nutrition
                let weight = entry.item.weightG
                return LibraryFood(
                    name:    entry.item.name,
                    portion: "\(Int(weight))g",
                    kcal:    n.calories,
                    protein: n.protein,
                    carbs:   n.carbs,
                    fat:     n.fat,
                    count:   entry.count
                )
            }
    }

    private var filteredFoods: [LibraryFood] {
        guard !searchText.isEmpty else { return libraryFoods }
        return libraryFoods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var canConfirm: Bool {
        selectedFood != nil || !foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {

                    // Barra de busca
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.textSecondary)
                        TextField("Buscar alimento...", text: $searchText)
                            .font(.system(size: 15))
                            .focused($searchFocused)
                            .onChange(of: searchText) { _, v in foodDescription = v }
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                foodDescription = ""
                                selectedFood = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Card do alimento selecionado
                    if let food = selectedFood {
                        selectedFoodCard(food)
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Lista de sugestões / resultados
                    VStack(alignment: .leading, spacing: 8) {
                        if libraryFoods.isEmpty && searchText.isEmpty {
                            emptyLibraryState
                        } else {
                            Text(searchText.isEmpty ? "Minha Biblioteca" : "Resultados")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColors.textSecondary)
                                .padding(.horizontal, 16)

                            if filteredFoods.isEmpty {
                                emptySearchState
                            } else {
                                ForEach(filteredFoods) { food in
                                    foodRow(food)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 96)
                }
            }

            // Botão fixo no rodapé
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [AppColors.background.opacity(0), AppColors.background],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 24)

                Button {
                    onAnalyze()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: selectedFood != nil ? "plus.circle.fill" : "sparkles")
                            .font(.system(size: 16))
                        Text(selectedFood != nil ? "Adicionar ao Diário" : "Analisar com IA")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canConfirm ? AppColors.primary : AppColors.primary.opacity(0.45))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: canConfirm ? AppColors.primary.opacity(0.35) : .clear, radius: 12, y: 4)
                }
                .disabled(!canConfirm)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .background(AppColors.background)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func selectedFoodCard(_ food: LibraryFood) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.text)
                        Text(food.portion)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedFood = nil
                            searchText = ""
                            foodDescription = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                Divider()

                // Macros em 4 colunas
                HStack(spacing: 0) {
                    macroMini("Kcal", value: food.kcal,    color: AppColors.text)
                    Divider().frame(height: 36)
                    macroMini("Prot", value: food.protein, color: AppColors.protein)
                    Divider().frame(height: 36)
                    macroMini("Carb", value: food.carbs,   color: AppColors.carbs)
                    Divider().frame(height: 36)
                    macroMini("Gord", value: food.fat,     color: AppColors.fat)
                }
            }
            .padding(16)
        }
    }

    private func macroMini(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%.0f", value))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
    }

    private func foodRow(_ food: LibraryFood) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                selectedFood = food
                foodDescription = food.name
                searchFocused = false
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.text)
                        Text("\(food.portion) · \(Int(food.kcal)) kcal")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    // Frequência de uso
                    if food.count > 1 {
                        Text("\(food.count)x")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColors.primary.opacity(0.7))
                            .padding(.trailing, 4)
                    }
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.primary)
                }
                .padding(14)
            }
            .padding(.horizontal, 16)
        }
    }

    /// Mostrado quando o usuário ainda não tem histórico (primeiro uso)
    private var emptyLibraryState: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.textSecondary.opacity(0.35))
            Text("Sua biblioteca está vazia")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
            Text("Os alimentos que você registrar\naparecerão aqui automaticamente.")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
            Text("Use \"Analisar com IA\" para começar ↓")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    /// Mostrado quando a busca não retorna resultados
    private var emptySearchState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
            Text("Nenhum resultado para\n\"\(searchText)\"")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Text("Tente analisar com IA ↓")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Model

struct LibraryFood: Identifiable {
    let id      = UUID()
    let name:    String
    let portion: String
    let kcal:    Double
    let protein: Double
    let carbs:   Double
    let fat:     Double
    let count:   Int   // vezes que o usuário registrou esse alimento
}
