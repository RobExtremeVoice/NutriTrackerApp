import SwiftUI

/// Bolha de mensagem — variante usuário (direita/verde) e IA (esquerda/branca).
struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
                bubble
            } else {
                aiAvatar
                bubble
                Spacer(minLength: 60)
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
                .background(
                    message.isUser
                        ? AnyShapeStyle(AppColors.primary)
                        : AnyShapeStyle(AppColors.surface),
                    in: RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                )
                .shadow(color: .black.opacity(message.isUser ? 0.08 : 0.06), radius: 6, y: 2)

            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 4)
        }
    }

    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary.opacity(0.12))
            Text("🥗")
                .font(.system(size: 16))
        }
        .frame(width: 30, height: 30)
    }
}
