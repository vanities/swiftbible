//
//  AppIconPickerView.swift
//  swiftbible
//

import SwiftUI

struct AppIconPickerView: View {
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.system.rawValue
    @Environment(\.colorScheme) private var colorScheme
    private var readingTheme: ReadingTheme {
        ReadingTheme(rawValue: readingThemeRaw) ?? .system
    }
    @AppStorage("selectedAppIcon") private var selectedIconRaw: String = AppIconOption.automatic.rawValue

    private let iconOptions: [AppIconOption] = AppIconOption.allCases.map { $0 }

    private var selectedIcon: AppIconOption {
        AppIconOption(rawValue: selectedIconRaw) ?? .automatic
    }

    var body: some View {
        List {
            ForEach(iconOptions, id: \.self) { (option: AppIconOption) in
                Button {
                    setIcon(option)
                } label: {
                    HStack(spacing: 16) {
                        iconPreview(for: option)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.displayName)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(option.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedIcon == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.brandAccent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(option.displayName), \(option.subtitle)")
                .accessibilityAddTraits(selectedIcon == option ? .isSelected : [])
            }
        }
        .readingThemeContentBackground(readingTheme, colorScheme: colorScheme)
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func iconPreview(for option: AppIconOption) -> some View {
        if let uiImage = UIImage(named: option.previewAsset) {
            Image(uiImage: uiImage)
                .resizable()
                .frame(width: 60, height: 60)
                .cornerRadius(13)
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 13)
                .fill(.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "app.fill")
                        .foregroundStyle(.gray)
                )
        }
    }

    private func setIcon(_ option: AppIconOption) {
        let name = option.iconName
        print("[AppIcon] Setting icon to: \(name ?? "nil (default)")")

        selectedIconRaw = option.rawValue
        UIApplication.shared.setAlternateIconName(name) { error in
            if let error {
                print("[AppIcon] ERROR: \(error.localizedDescription)")
                print("[AppIcon] Error domain: \((error as NSError).domain) code: \((error as NSError).code)")
            } else {
                print("[AppIcon] SUCCESS: Icon set to \(name ?? "default")")
            }
        }
        AnalyticsService.shared.capture(.appIconChanged, properties: [
            "icon": option.rawValue
        ])
    }
}

#Preview {
    NavigationStack {
        AppIconPickerView()
    }
}
