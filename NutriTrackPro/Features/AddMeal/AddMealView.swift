import SwiftUI
import PhotosUI
import SwiftData
import WidgetKit

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
    @State private var milestoneReached: Int? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Seletor de tipo de refeição
                MealTypeSelector(selected: $selectedMealType)
                    .padding(.vertical, 12)

                // Tab picker pill-style
                tabPicker
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

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
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .overlay {
                if isAnalyzing { analyzingOverlay }
            }
            .alert("Erro na análise", isPresented: $showAnalysisError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(analysisError ?? "Erro desconhecido")
            }
            .alert(milestoneTitle, isPresented: milestoneBinding) {
                Button("Incrível! 🎉") { dismiss() }
            } message: {
                Text(milestoneMessage)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(capturedImage: $capturedImage).ignoresSafeArea()
            }
            .onChange(of: capturedImage) { _, image in
                if image != nil { analyzeImage() }
            }
            .onChange(of: photoPickerItem) { _, item in
                Task { await loadFromPicker(item) }
            }
        }
    }

    // MARK: – Tab Picker (pill style)

    private var tabPicker: some View {
        HStack(spacing: 4) {
            ForEach(AddMealTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(duration: 0.3)) { selectedTab = tab }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .foregroundStyle(selectedTab == tab ? .white : AppColors.textSecondary)
                    .background {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.primary)
                                .shadow(color: AppColors.primary.opacity(0.3), radius: 6, y: 2)
                                .matchedGeometryEffect(id: "tab", in: tabNS)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 14))
        .animation(.spring(duration: 0.3), value: selectedTab)
    }

    @Namespace private var tabNS

    // MARK: – Conteúdo por tab

    @ViewBuilder
    private var inputContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                switch selectedTab {
                case .camera:  cameraContent
                case .gallery: galleryContent
                case .text:
                    BarcodeView(foodDescription: $foodDescription) { analyzeText() }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: – Camera

    private var cameraContent: some View {
        VStack(spacing: 16) {
            if let image = capturedImage {
                // Preview da foto capturada
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button {
                        capturedImage = nil
                        showCamera = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .bold))
                            Text("Nova foto")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.55), in: Capsule())
                    }
                    .padding(12)
                }
                .padding(.horizontal, 16)

                PrimaryButton(title: "Analisar com IA", icon: "sparkles") {
                    analyzeImage()
                }
                .padding(.horizontal, 16)

            } else {
                cameraPlaceholder
            }
        }
    }

    private var cameraPlaceholder: some View {
        ZStack {
            // Fundo escuro viewfinder
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "1A1A1E"))
                .frame(height: 320)

            // Corner brackets
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let corner: CGFloat = 28
                let lw: CGFloat = 3

                ZStack {
                    // Topo-esquerdo
                    bracketPath(x: 16, y: 16, dx: corner, dy: corner, lw: lw)
                    // Topo-direito
                    bracketPath(x: w - 16, y: 16, dx: -corner, dy: corner, lw: lw)
                    // Base-esquerdo
                    bracketPath(x: 16, y: h - 16, dx: corner, dy: -corner, lw: lw)
                    // Base-direito
                    bracketPath(x: w - 16, y: h - 16, dx: -corner, dy: -corner, lw: lw)
                }
            }
            .frame(height: 320)
            .allowsHitTesting(false)

            // Conteúdo central
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 80, height: 80)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 6) {
                    Text("Fotografe sua refeição")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("A IA identifica os alimentos e calcula\nos nutrientes automaticamente")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }

                Button {
                    guard appState.canUsePhotoScan() else {
                        appState.showPaywall = true
                        return
                    }
                    showCamera = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Abrir câmera")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(Color(hex: "1A1A1E"))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(AppColors.primary, in: Capsule())
                    .shadow(color: AppColors.primary.opacity(0.4), radius: 10, y: 4)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    /// Desenha dois segmentos de canto (L-shape) em (x, y) com deltas.
    private func bracketPath(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat, lw: CGFloat) -> some View {
        Path { p in
            p.move(to: CGPoint(x: x + dx, y: y))
            p.addLine(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x, y: y + dy))
        }
        .stroke(.white.opacity(0.45), style: StrokeStyle(lineWidth: lw, lineCap: .round))
    }

    // MARK: – Gallery

    private var galleryContent: some View {
        VStack(spacing: 16) {
            if let image = capturedImage {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .bold))
                            Text("Trocar foto")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.55), in: Capsule())
                    }
                    .padding(12)
                }
                .padding(.horizontal, 16)

                PrimaryButton(title: "Analisar com IA", icon: "sparkles") {
                    analyzeImage()
                }
                .padding(.horizontal, 16)

            } else {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.systemGray6))
                            .frame(height: 320)

                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                AppColors.primary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                            )
                            .frame(height: 320)

                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 34, weight: .medium))
                                    .foregroundStyle(AppColors.primary.opacity(0.7))
                            }
                            VStack(spacing: 6) {
                                Text("Escolher da galeria")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(AppColors.text)
                                Text("Selecione uma foto de refeição existente")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Abrir galeria")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 13)
                            .background(AppColors.primary, in: Capsule())
                            .shadow(color: AppColors.primary.opacity(0.4), radius: 10, y: 4)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: – Analyzing Overlay

    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.15))
                        .frame(width: 80, height: 80)

                    ProgressView()
                        .scaleEffect(1.6)
                        .tint(AppColors.primary)
                }

                VStack(spacing: 6) {
                    Text("Analisando refeição...")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Text("A IA está identificando os alimentos")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .padding(36)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(40)
        }
    }

    // MARK: – Logic

    private func analyzeImage() {
        guard let image = capturedImage,
              let data = image.jpegData(compressionQuality: 0.8) else { return }
        guard appState.canUsePhotoScan() else { appState.showPaywall = true; return }
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
        guard appState.canUsePhotoScan() else { appState.showPaywall = true; return }
        isAnalyzing = true
        Task {
            do {
                let result = try await FoodVisionService.shared.analyzeText(text)
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

    private func loadFromPicker(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run { capturedImage = image }
        }
    }

    private func saveMeal(result: FoodAnalysisResult?) {
        guard let result else { return }
        let meal = Meal(type: selectedMealType, name: result.mealName,
                        imageData: capturedImage?.jpegData(compressionQuality: 0.7))
        for food in result.foods {
            let w = food.estimatedWeightG
            let item = FoodItem(
                name: food.name, weightG: w,
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

        // Update streak and check milestones
        var hitMilestone = false
        var savedProfile: UserProfile? = nil
        if let profile = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first {
            savedProfile = profile
            updateStreak(profile: profile)
            hitMilestone = checkStreakMilestone(streak: profile.streakDays)
        }

        // Sync nutrition to Apple Health if authorised
        if appState.healthKitEnabled {
            Task { try? await HealthKitService.shared.syncNutrition(meal: meal) }
        }

        // Reset the 26h re-engagement timer on every successful log
        Task { await NotificationService.shared.scheduleReEngagementReminder() }

        // Update Home Screen widget with today's totals
        let startOfDay = Calendar.current.startOfDay(for: Date())
        if let todayMeals = try? modelContext.fetch(
            FetchDescriptor<Meal>(predicate: #Predicate { $0.timestamp >= startOfDay })
        ) {
            let total = todayMeals.reduce(NutritionInfo.zero) { $0 + $1.totalNutrition }
            WidgetDataStore.shared.write(NutriWidgetEntry(
                caloriesConsumed: total.calories,
                calorieGoal:      savedProfile?.dailyCalorieGoal ?? 2000,
                protein:          total.protein,
                carbs:            total.carbs,
                fat:              total.fat,
                streakDays:       savedProfile?.streakDays ?? 0,
                updatedAt:        .now
            ))
            WidgetCenter.shared.reloadAllTimelines()
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // If a milestone was reached, show the achievement alert before dismissing
        if !hitMilestone { dismiss() }
    }

    // MARK: – Streak milestones

    private static let milestones = [7, 14, 21, 30, 60, 100]

    /// Retorna `true` se `streak` bate um marco — e aciona o alerta.
    @discardableResult
    private func checkStreakMilestone(streak: Int) -> Bool {
        guard Self.milestones.contains(streak) else { return false }
        milestoneReached = streak
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        return true
    }

    private var milestoneBinding: Binding<Bool> {
        Binding(
            get: { milestoneReached != nil },
            set: { if !$0 { milestoneReached = nil } }
        )
    }

    private var milestoneTitle: String {
        guard let days = milestoneReached else { return "" }
        switch days {
        case 7:   return "1 semana consecutiva! 🔥"
        case 14:  return "2 semanas seguidas! 💪"
        case 21:  return "21 dias — novo hábito! 🧠"
        case 30:  return "1 mês de sequência! 🏆"
        case 60:  return "2 meses imparáveis! 🚀"
        case 100: return "100 dias lendários! 👑"
        default:  return "Nova conquista! 🎉"
        }
    }

    private var milestoneMessage: String {
        guard let days = milestoneReached else { return "" }
        return "Você registrou \(days) dias seguidos no NutriPack Pro. Continue assim!"
    }

    /// Atualiza a sequência diária do usuário (streakDays + lastLogDate).
    private func updateStreak(profile: UserProfile) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let last = profile.lastLogDate, calendar.isDate(last, inSameDayAs: Date()) {
            // Já registrou hoje — sem alteração
            return
        } else if let last = profile.lastLogDate,
                  calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: today).day == 1 {
            profile.streakDays += 1   // dia consecutivo
        } else {
            profile.streakDays = 1    // primeira vez ou sequência quebrada
        }
        profile.lastLogDate = today
    }
}
