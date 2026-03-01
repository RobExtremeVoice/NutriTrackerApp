import SwiftUI

/// Entrada manual de alimentos — busca, detalhe e confirmação via IA.
struct BarcodeView: View {
    @Binding var foodDescription: String
    let onAnalyze: () -> Void

    @State private var searchText    = ""
    @State private var selectedFood: RecentFood? = nil
    @FocusState private var searchFocused: Bool

    // Sugestões mock — em produção viria de banco ou API
    private let recentFoods: [RecentFood] = [
        RecentFood(name: "Arroz branco cozido", portion: "100g", kcal: 130, protein: 2.7, carbs: 28.2, fat: 0.3),
        RecentFood(name: "Frango grelhado",      portion: "100g", kcal: 165, protein: 31.0, carbs: 0.0,  fat: 3.6),
        RecentFood(name: "Feijão carioca cozido",portion: "100g", kcal:  76, protein: 4.8,  carbs: 13.6, fat: 0.5),
        RecentFood(name: "Ovo mexido",            portion: "1 un",kcal:  91, protein: 6.3,  carbs: 0.6,  fat: 6.8),
        RecentFood(name: "Banana nanica",         portion: "1 un",kcal:  89, protein: 1.1,  carbs: 22.8, fat: 0.3),
        RecentFood(name: "Salada verde mista",    portion: "100g", kcal:  20, protein: 1.5,  carbs: 2.8,  fat: 0.4),
    ]

    private var filteredFoods: [RecentFood] {
        guard !searchText.isEmpty else { return recentFoods }
        return recentFoods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                        Text(searchText.isEmpty ? "Recentes" : "Resultados")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.horizontal, 16)

                        if filteredFoods.isEmpty {
                            emptyState
                        } else {
                            ForEach(filteredFoods) { food in
                                foodRow(food)
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

    // MARK: – Subviews

    @ViewBuilder
    private func selectedFoodCard(_ food: RecentFood) -> some View {
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

    private func foodRow(_ food: RecentFood) -> some View {
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
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.primary)
                }
                .padding(14)
            }
            .padding(.horizontal, 16)
        }
    }

    private var emptyState: some View {
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

struct RecentFood: Identifiable {
    let id      = UUID()
    let name:    String
    let portion: String
    let kcal:    Double
    let protein: Double
    let carbs:   Double
    let fat:     Double
}
