import SwiftUI
import PhotosUI
import SwiftData

enum AddMealTab: String, CaseIterable {
    case camera  = "Câmera"
    case gallery = "Galeria"
    case text    = "Texto"

    var icon: String {
        switch self {
        case .camera:  return "camera.fill"
        case .gallery: return "photo.fill"
        case .text:    return "text.alignleft"
        }
    }
}

/// Tela de adição de refeição — câmera, galeria e entrada de texto.
struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var selectedTab: AddMealTab = .camera
    @State private var selectedMealType: MealType = .lunch
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var foodDescription = ""
    @State private var isAnalyzing = false
    @State private var analysisResult: FoodAnalysisResult?
    @State private var analysisError: String?
    @State private var showAnalysisError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Seletor de tipo de refeição
                MealTypeSelector(selected: $selectedMealType)
                    .padding(.vertical, 12)

                // Tabs de input
                tabPicker

                // Conteúdo
                if let result = Binding($analysisResult) {
                    FoodAnalysisView(result: result) {
                        saveMeal(result: analysisResult)
                    }
                } else {
                    inputContent
                }
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Adicionar Refeição")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .overlay {
                if isAnalyzing {
                    analyzingOverlay
                }
            }
            .alert("Erro na análise", isPresented: $showAnalysisError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(analysisError ?? "Erro desconhecido")
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(capturedImage: $capturedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: capturedImage) { _, image in
                if image != nil { analyzeImage() }
            }
            .onChange(of: photoPickerItem) { _, item in
                Task { await loadFromPicker(item) }
            }
        }
    }

    // MARK: – Subviews

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(AddMealTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(duration: 0.25)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        Text(tab.rawValue)
                            .font(.caption.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(selectedTab == tab ? AppColors.primary : AppColors.textSecondary)
                }
            }
        }
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                let w = geo.size.width / CGFloat(AddMealTab.allCases.count)
                let offset = w * CGFloat(AddMealTab.allCases.firstIndex(of: selectedTab) ?? 0)
                Rectangle()
                    .fill(AppColors.primary)
                    .frame(width: w, height: 2)
                    .offset(x: offset)
                    .animation(.spring(duration: 0.25), value: selectedTab)
            }
            .frame(height: 2)
        }
        .background(AppColors.surface)
    }

    @ViewBuilder
    private var inputContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedTab {
                case .camera:
                    cameraContent
                case .gallery:
                    galleryContent
                case .text:
                    BarcodeView(foodDescription: $foodDescription) {
                        analyzeText()
                    }
                }
            }
            .padding(.top, 16)
        }
    }

    private var cameraContent: some View {
        VStack(spacing: 20) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.largeCornerRadius, style: .continuous))
                    .frame(maxHeight: 280)
                    .padding(.horizontal)

                PrimaryButton(title: "Analisar com IA", icon: "sparkles") {
                    analyzeImage()
                }
                .padding(.horizontal)

                Button("Tirar nova foto") {
                    capturedImage = nil
                    showCamera = true
                }
                .font(.system(size: 14))
                .foregroundStyle(AppColors.primary)
            } else {
                cameraPlaceholder
            }
        }
    }

    private var cameraPlaceholder: some View {
        GlassCard(cornerRadius: AppConstants.largeCornerRadius) {
            VStack(spacing: 20) {
                // Ícone circular
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 88, height: 88)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(AppColors.primary.opacity(0.65))
                }

                // Texto
                VStack(spacing: 6) {
                    Text("Fotografe sua refeição")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                    Text("A IA identifica os alimentos e calcula os nutrientes automaticamente")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Botão
                Button {
                    guard appState.canUsePhotoScan() else {
                        appState.showPaywall = true
                        return
                    }
                    showCamera = true
                } label: {
                    HStack(spacing: 8) {
                        Text("Abrir câmera")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "camera.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 10, y: 4)
                }
            }
            .padding(28)
        }
        .padding(.horizontal)
    }

    private var galleryContent: some View {
        VStack(spacing: 20) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.largeCornerRadius, style: .continuous))
                    .frame(maxHeight: 280)
                    .padding(.horizontal)

                PrimaryButton(title: "Analisar com IA", icon: "sparkles") {
                    analyzeImage()
                }
                .padding(.horizontal)
            } else {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    GlassCard(cornerRadius: AppConstants.largeCornerRadius) {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.fill.on.rectangle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(AppColors.primary.opacity(0.6))
                            Text("Escolher da galeria")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AppColors.text)
                            Text("Selecione uma foto de refeição existente")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .padding(32)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            GlassCard(cornerRadius: AppConstants.largeCornerRadius) {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(AppColors.primary)
                    Text("Analisando refeição...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.text)
                    Text("A IA está identificando os alimentos")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(32)
            }
            .padding(40)
        }
    }

    // MARK: – Logic

    private func analyzeImage() {
        guard let image = capturedImage,
              let data = image.jpegData(compressionQuality: 0.8) else { return }

        guard appState.canUsePhotoScan() else {
            appState.showPaywall = true
            return
        }

        isAnalyzing = true
        Task {
            do {
                let result = try await FoodVisionService.shared.analyze(imageData: data)
                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false
                    appState.incrementPhotoScan()
                }
            } catch {
                await MainActor.run {
                    analysisError = error.localizedDescription
                    showAnalysisError = true
                    isAnalyzing = false
                }
            }
        }
    }

    private func analyzeText() {
        let text = foodDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        // Placeholder: cria resultado mock para texto (seria feita via Chat API sem imagem)
        isAnalyzing = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                analysisResult = FoodAnalysisResult(
                    mealName: text,
                    confidence: "medium",
                    foods: [
                        FoodAnalysisItem(
                            name: text,
                            estimatedWeightG: 200,
                            confidence: "medium",
                            calories: 300,
                            proteinG: 20,
                            carbsG: 30,
                            fatG: 10,
                            fiberG: 3
                        )
                    ],
                    portionNote: "Estimado"
                )
                isAnalyzing = false
            }
        }
    }

    private func loadFromPicker(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run { capturedImage = image }
        }
    }

    private func saveMeal(result: FoodAnalysisResult?) {
        guard let result else { return }
        let meal = Meal(
            type: selectedMealType,
            name: result.mealName,
            imageData: capturedImage?.jpegData(compressionQuality: 0.7)
        )
        for food in result.foods {
            let w = food.estimatedWeightG
            let item = FoodItem(
                name: food.name,
                weightG: w,
                caloriesPer100g: w > 0 ? food.calories / w * 100 : 0,
                proteinPer100g:  w > 0 ? food.proteinG / w * 100 : 0,
                carbsPer100g:    w > 0 ? food.carbsG   / w * 100 : 0,
                fatPer100g:      w > 0 ? food.fatG     / w * 100 : 0,
                fiberPer100g:    w > 0 ? food.fiberG   / w * 100 : 0,
                aiConfidence: food.confidence
            )
            meal.foods.append(item)
            modelContext.insert(item)
        }
        modelContext.insert(meal)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
