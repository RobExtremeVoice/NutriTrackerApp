import SwiftUI

/// Bolha de mensagem — usuário (direita/verde degradê) e IA (esquerda/branca).
struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 56)
                bubble
            } else {
                aiAvatar
                bubble
                Spacer(minLength: 56)
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            Text(message.content)
                .font(.system(size: 15))
                .foregroundStyle(message.isUser ? .white : AppColors.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    if message.isUser {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColors.surface)
                    }
                }
                .shadow(color: .black.opacity(message.isUser ? 0.1 : 0.06), radius: 6, y: 2)

            Text(message.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 4)
        }
    }

    private var aiAvatar: some View {
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
        .shadow(color: AppColors.primary.opacity(0.25), radius: 4, y: 2)
    }
}
