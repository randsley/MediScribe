//
//  FieldButton.swift
//  MediScribe
//
//  Field-optimized button component with large touch targets
//

import SwiftUI

/// Field-optimized button with glove-friendly touch targets and high visibility
struct FieldButton: View {

    // MARK: - Configuration

    let title: String
    let icon: String?
    let action: () -> Void

    var size: ButtonSize = .large
    var type: ButtonType = .primary
    var isEnabled: Bool = true

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .bold))
                }

                Text(title)
                    .font(DesignSystem.Typography.Field.bodyLarge)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: isPressed ? DesignSystem.Animation.buttonPress : DesignSystem.Animation.buttonRelease), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && isEnabled {
                        isPressed = true
                        // Haptic feedback
                        let impactMed = UIImpactFeedbackGenerator(style: .light)
                        impactMed.impactOccurred()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .disabled(!isEnabled)
    }

    // MARK: - Computed Properties

    private var iconSize: CGFloat {
        switch size {
        case .large: return 24
        case .extraLarge: return 28
        }
    }

    private var foregroundColor: Color {
        if !isEnabled {
            return DesignSystem.Colors.Text.disabled
        }

        switch type {
        case .primary:
            return .white
        case .secondary:
            return type.color
        case .destructive:
            return .white
        }
    }

    private var backgroundColor: Color {
        if !isEnabled {
            return DesignSystem.Colors.Background.tertiary
        }

        if isPressed {
            return type.color.opacity(0.8)
        }

        switch type {
        case .primary:
            return type.color
        case .secondary:
            return .clear
        case .destructive:
            return type.color
        }
    }

    private var borderColor: Color {
        if !isEnabled {
            return DesignSystem.Colors.Border.default
        }

        switch type {
        case .primary, .destructive:
            return .clear
        case .secondary:
            return type.color
        }
    }

    private var borderWidth: CGFloat {
        switch type {
        case .primary, .destructive:
            return 0
        case .secondary:
            return 2
        }
    }

    private var shadowColor: Color {
        if !isEnabled || isPressed || type == .secondary {
            return .clear
        }
        return DesignSystem.Shadow.light.color
    }

    private var shadowRadius: CGFloat {
        DesignSystem.Shadow.light.radius
    }

    private var shadowY: CGFloat {
        DesignSystem.Shadow.light.y
    }

    // MARK: - Types

    enum ButtonSize {
        case large
        case extraLarge

        var height: CGFloat {
            switch self {
            case .large: return DesignSystem.Spacing.TouchTarget.comfortable
            case .extraLarge: return DesignSystem.Spacing.TouchTarget.critical
            }
        }
    }

    enum ButtonType {
        case primary
        case secondary
        case destructive

        var color: Color {
            switch self {
            case .primary: return DesignSystem.Colors.Field.safe
            case .secondary: return DesignSystem.Colors.Field.info
            case .destructive: return DesignSystem.Colors.Field.emergency
            }
        }
    }
}

// MARK: - Preview

#Preview("Primary Buttons") {
    VStack(spacing: 20) {
        FieldButton(
            title: "Record Vitals",
            icon: "waveform.path.ecg",
            action: {}
        )

        FieldButton(
            title: "Save Note",
            icon: "checkmark.circle.fill",
            action: {},
            size: .extraLarge
        )

        FieldButton(
            title: "Delete",
            icon: "trash.fill",
            action: {},
            type: .destructive
        )

        FieldButton(
            title: "View Details",
            icon: "info.circle",
            action: {},
            type: .secondary
        )

        FieldButton(
            title: "Disabled",
            icon: "lock.fill",
            action: {},
            isEnabled: false
        )
    }
    .padding()
}
