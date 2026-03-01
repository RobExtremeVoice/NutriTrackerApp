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

    private let quickPrompts: [(icon: String, text: String)] = [
        ("fork.knife",    "Quanto de proteína comi hoje?"),
        ("sparkles",      "Sugestão de lanche saudável"),
        ("drop.fill",     "Dicas para beber mais água"),
        ("chart.bar",     "Como está minha hidratação?"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Área de mensagens
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty {
                                welcomeView
                                quickPromptsBar
                            }

                            ForEach(messages) { msg in
                                MessageBubbleView(message: msg)
                                    .id(msg.id)
                            }

                            if isStreaming {
                                if streamingText.isEmpty {
                                    HStack {
                                        TypingIndicatorView()
                                        Spacer()
                                    }
                                } else {
                                    MessageBubbleView(
                                        message: ChatMessage(role: "assistant", content: streamingText)
                                    )
                                    .id("streaming")
                                }
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: messages.count) {
                        withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                    }
                    .onChange(of: streamingText) {
                        withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
                    }
                }

                Divider()

                // Campo de entrada
                inputBar
            }
            .background(Color(.systemGray6).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Nutri IA")
                        .font(.system(size: 17, weight: .bold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("Pro")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.primary.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(AppColors.primary.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }

    // MARK: – Subviews

    private var welcomeView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(AppColors.primary)
            }
            .padding(.top, 24)

            Text("NutriTrack Pro")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text("Olá! Sou a Nutri, sua nutricionista IA.\nComo posso ajudar no seu plano alimentar hoje?")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.bottom, 8)
    }

    private var quickPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.text) { prompt in
                    Button {
                        send(text: prompt.text)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: prompt.icon)
                                .font(.system(size: 12))
                            Text(prompt.text)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(AppColors.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppColors.primary.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(AppColors.primary.opacity(0.25), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Pergunte à Nutri...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .focused($fieldFocused)

            Button {
                guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                send(text: inputText)
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        inputText.isEmpty ? AppColors.primary.opacity(0.35) : AppColors.primary,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
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
                        content: "Desculpe, ocorreu um erro ao processar sua mensagem. Tente novamente."
                    ))
                    streamingText = ""
                    isStreaming = false
                }
            }
        }
    }
}
