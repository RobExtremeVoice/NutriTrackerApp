import SwiftUI
import SwiftData

/// Chat com nutricionista IA — streaming GPT-4o.
struct ChatView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \UserProfile.name) private var profiles: [UserProfile]
    @Query(sort: \Meal.timestamp, order: .reverse) private var allMeals: [Meal]

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isStreaming = false
    @State private var streamingText = ""
    @FocusState private var fieldFocused: Bool

    private var profile: UserProfile? { profiles.first }

    private var todayMeals: [Meal] {
        allMeals.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var todayNutrition: NutritionInfo {
        todayMeals.reduce(.zero) { $0 + $1.totalNutrition }
    }

    private var systemPrompt: String {
        let p = profile
        let goal = p?.dailyCalorieGoal ?? 2000
        let meals = todayMeals.map { "\($0.name) (\(Int($0.totalCalories)) kcal)" }.joined(separator: ", ")
        return """
        Você é uma nutricionista brasileira amigável e experiente chamada Nutri.
        Contexto do usuário hoje:
        - Calorias consumidas: \(Int(todayNutrition.calories)) de \(Int(goal)) kcal
        - Proteína: \(Int(todayNutrition.protein))g de \(Int(p?.dailyProteinGoal ?? 120))g
        - Carboidratos: \(Int(todayNutrition.carbs))g
        - Gordura: \(Int(todayNutrition.fat))g
        - Refeições hoje: \(meals.isEmpty ? "nenhuma ainda" : meals)
        - Objetivo: \(p?.goalEnum.displayName ?? "manter peso")
        Responda sempre em Português do Brasil. Seja direta, prática e encorajadora.
        Máximo 150 palavras por resposta.
        """
    }

    // MARK: – Quick prompts (8 items, 2 categories)

    private struct QuickPrompt {
        let icon: String
        let text: String
        let color: Color
    }

    private let quickPrompts: [QuickPrompt] = [
        QuickPrompt(icon: "fork.knife.circle.fill", text: "Quanto de proteína comi hoje?",       color: Color(hex: "3B82F6")),
        QuickPrompt(icon: "chart.bar.fill",         text: "Como está minha meta calórica?",      color: Color(hex: "F97316")),
        QuickPrompt(icon: "sparkles",               text: "Sugestão de lanche saudável",         color: Color(hex: "22C55E")),
        QuickPrompt(icon: "moon.stars.fill",        text: "O que comer no jantar hoje?",         color: Color(hex: "8B5CF6")),
        QuickPrompt(icon: "drop.fill",              text: "Dicas para beber mais água",          color: Color(hex: "0EA5E9")),
        QuickPrompt(icon: "flame.fill",             text: "Alimentos para ganhar músculo",       color: Color(hex: "EF4444")),
        QuickPrompt(icon: "heart.fill",             text: "Como melhorar minha dieta?",          color: Color(hex: "F43F5E")),
        QuickPrompt(icon: "leaf.fill",              text: "Substitutos saudáveis para doces",    color: Color(hex: "16A34A")),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty {
                                welcomeView
                                quickPromptsGrid
                            }

                            ForEach(messages) { msg in
                                MessageBubbleView(message: msg)
                                    .id(msg.id)
                            }

                            if isStreaming {
                                HStack(alignment: .bottom, spacing: 8) {
                                    aiAvatarSmall
                                    if streamingText.isEmpty {
                                        TypingIndicatorView()
                                    } else {
                                        MessageBubbleView(
                                            message: ChatMessage(role: "assistant", content: streamingText)
                                        )
                                        .id("streaming")
                                    }
                                    Spacer(minLength: 60)
                                }
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 8)
                    }
                    .onChange(of: messages.count) {
                        withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                    }
                    .onChange(of: streamingText) {
                        withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
                    }
                }

                Divider()
                inputBar
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    // MARK: – Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Nutri IA")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.text)
                    Text("Nutricionista virtual")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            if !messages.isEmpty {
                Button {
                    withAnimation(.spring(duration: 0.35)) { messages = [] }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    // MARK: – Welcome screen

    private var welcomeView: some View {
        VStack(spacing: 16) {
            // Animated avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary.opacity(0.2), AppColors.primaryDark.opacity(0.08)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: AppColors.primary.opacity(0.35), radius: 10, y: 4)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 20)

            VStack(spacing: 6) {
                Text("Olá! Sou a Nutri 👋")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.text)
                Text("Sua nutricionista IA pessoal. Posso analisar\nsua dieta, sugerir receitas e tirar dúvidas\nsobre alimentação saudável.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // Today's context pill
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.accent)
                Text("\(Int(todayNutrition.calories)) de \(Int(profile?.dailyCalorieGoal ?? 2000)) kcal hoje")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.text)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppColors.accent.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(AppColors.accent.opacity(0.2), lineWidth: 1))
            .padding(.bottom, 4)
        }
    }

    // MARK: – Quick prompts grid

    private var quickPromptsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Perguntas rápidas")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 4)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(quickPrompts, id: \.text) { prompt in
                    promptCard(prompt)
                }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    private func promptCard(_ prompt: QuickPrompt) -> some View {
        Button { send(text: prompt.text) } label: {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(prompt.color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: prompt.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(prompt.color)
                }
                Text(prompt.text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: – Shared AI avatar (used in streaming row)

    private var aiAvatarSmall: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "leaf.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 30, height: 30)
    }

    // MARK: – Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 0) {
                TextField("Pergunte à Nutri...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 15))
                    .padding(.leading, 14)
                    .padding(.trailing, 8)
                    .padding(.vertical, 10)
                    .focused($fieldFocused)

                if !inputText.isEmpty {
                    Button { inputText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(.systemGray3))
                            .padding(.trailing, 8)
                    }
                }
            }
            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Button {
                guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                send(text: inputText)
            } label: {
                Image(systemName: isStreaming ? "stop.circle.fill" : "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        inputText.isEmpty && !isStreaming
                            ? AnyShapeStyle(AppColors.primary.opacity(0.35))
                            : AnyShapeStyle(LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )),
                        in: RoundedRectangle(cornerRadius: 13)
                    )
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 6, y: 2)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isStreaming)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white)
    }

    // MARK: – Logic

    private func send(text: String) {
        guard appState.canUseChat() else {
            appState.showPaywall = true
            return
        }
        let userMsg = ChatMessage(role: "user", content: text)
        messages.append(userMsg)
        inputText = ""
        isStreaming = true
        streamingText = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        appState.incrementChatMessage()

        Task {
            do {
                let stream = await ChatService.shared.sendStream(
                    messages: messages,
                    systemPrompt: systemPrompt
                )
                for try await token in stream {
                    await MainActor.run { streamingText += token }
                }
                await MainActor.run {
                    messages.append(ChatMessage(role: "assistant", content: streamingText))
                    streamingText = ""
                    isStreaming = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(
                        role: "assistant",
                        content: "Desculpe, ocorreu um erro. Tente novamente."
                    ))
                    streamingText = ""
                    isStreaming = false
                }
            }
        }
    }
}
