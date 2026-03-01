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

    private let quickPrompts = [
        "Quanto de proteína comi hoje?",
        "Sugestão de lanche saudável",
        "Estou no caminho certo?",
        "O que falta para atingir minha meta?",
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
                                        message: ChatMessage(
                                            role: "assistant",
                                            content: streamingText
                                        )
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

                // Quick prompts
                if messages.isEmpty {
                    quickPromptsBar
                }

                Divider()

                // Campo de entrada
                inputBar
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Nutri IA")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: – Subviews

    private var welcomeView: some View {
        VStack(spacing: 12) {
            Text("🥗")
                .font(.system(size: 48))
            Text("Olá! Sou a Nutri, sua nutricionista IA.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.text)
                .multilineTextAlignment(.center)
            Text("Posso analisar sua alimentação de hoje, sugerir refeições e te ajudar a atingir seus objetivos.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    private var quickPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button {
                        send(text: prompt)
                    } label: {
                        Text(prompt)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppColors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.primary.opacity(0.1), in: Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Pergunte à Nutri...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .focused($fieldFocused)

            Button {
                guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                send(text: inputText)
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().fill(inputText.isEmpty ? AppColors.primary.opacity(0.3) : AppColors.primary)
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isStreaming)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.surface)
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
