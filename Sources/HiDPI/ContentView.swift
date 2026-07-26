import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var displayService: DisplayService
    @ObservedObject var systemSettings: SystemSettings
    @ObservedObject var localizationSettings: LocalizationSettings

    var body: some View {
        VStack(spacing: 0) {
            appHeader
            Divider()

            if displayService.displays.isEmpty {
                emptyState
            } else {
                displayList
            }

            Divider()
            footer
        }
        .frame(width: 336)
        .onAppear {
            displayService.refresh()
        }
        .alert("Bird HiDPI", isPresented: errorBinding) {
            Button(L10n.tr("common.ok", fallback: "OK"), role: .cancel) {}
        } message: {
            Text(
                displayService.errorMessage ?? systemSettings.errorMessage ??
                    L10n.tr("error.unknown", fallback: "Unknown error")
            )
        }
    }

    private var appHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "display.2")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 1) {
                Text("Bird HiDPI")
                    .font(.system(size: 14, weight: .semibold))
                Text(headerStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private var displayList: some View {
        VStack(spacing: 0) {
            ForEach(displayService.displays) { display in
                displayPanel(display)
                if display.id != displayService.displays.last?.id {
                    Divider()
                }
            }
        }
    }

    private func displayPanel(_ display: DisplayDevice) -> some View {
        let output = displayService.configuration(for: display)
        let resolutions = displayService.availableResolutions(
            for: display,
            isHiDPI: output.isHiDPI
        )
        let isActive = displayService.activeConfiguration?.displayID == display.id
        let isApplying = displayService.isApplyingDisplayID == display.id
        let isCurrent = display.currentMode?.matches(output) == true
        let controlsDisabled = isApplying ||
            (displayService.isApplyingDisplayID != nil && !isApplying)

        return VStack(spacing: 0) {
            displayHeader(
                display,
                isActive: isActive,
                isApplying: isApplying,
                isCurrent: isCurrent
            )
            Divider().padding(.leading, 46)
            renderingRow(display, output: output, disabled: controlsDisabled)
            Divider().padding(.leading, 46)

            VStack(spacing: 0) {
                ForEach(resolutions) { resolution in
                    ResolutionRow(
                        resolution: resolution,
                        isSelected: output.resolution == resolution,
                        isDisabled: controlsDisabled
                    ) {
                        displayService.setResolution(resolution, for: display)
                    }
                    if resolution != resolutions.last {
                        Divider().padding(.leading, 46)
                    }
                }
            }
        }
    }

    private func displayHeader(
        _ display: DisplayDevice,
        isActive: Bool,
        isApplying: Bool,
        isCurrent: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "display")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(display.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(L10n.format(
                    "display.connectionSummary",
                    fallback: "Native %@ · %@",
                    display.nativeSizeLabel,
                    display.refreshRateLabel
                ))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isApplying {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text(L10n.tr("status.applying", fallback: "Applying"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if isCurrent {
                Label(
                    L10n.tr("status.current", fallback: "Current"),
                    systemImage: "checkmark.circle.fill"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
                .help(L10n.tr(
                    "help.current",
                    fallback: "Selection matches the current mode; nothing to apply"
                ))
            } else {
                Button {
                    displayService.enable(on: display)
                } label: {
                    Text(L10n.tr("action.apply", fallback: "Apply"))
                        .frame(minWidth: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    displayService.isApplyingDisplayID != nil ||
                        (displayService.activeConfiguration != nil && !isActive)
                )
                .help(L10n.tr(
                    "help.apply",
                    fallback: "Apply the selected resolution and HiDPI mode"
                ))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private func renderingRow(
        _ display: DisplayDevice,
        output: DisplayOutputConfiguration,
        disabled: Bool
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 15))
                .foregroundStyle(output.isHiDPI ? Color.green : Color.secondary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr("mode.hidpi", fallback: "HiDPI"))
                    .font(.system(size: 13, weight: .medium))
                Text(L10n.format(
                    "output.framebuffer",
                    fallback: "%@ framebuffer",
                    "\(output.pixelWidth) x \(output.pixelHeight)"
                ))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: Binding(
                get: { displayService.configuration(for: display).isHiDPI },
                set: { displayService.setHiDPI($0, for: display) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
            .disabled(
                disabled ||
                    !displayService.hasModes(for: display, isHiDPI: !output.isHiDPI)
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var headerStatus: String {
        L10n.tr("header.subtitle.inactive", fallback: "External display scaling")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "display.trianglebadge.exclamationmark")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text(L10n.tr(
                "empty.noCompatibleDisplay",
                fallback: "No external display detected"
            ))
            .font(.headline)
            Button(L10n.tr("action.openDisplaySettings", fallback: "Open Display Settings")) {
                systemSettings.openDisplaySettings()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Menu {
                Toggle(
                    L10n.tr("setting.launchAtLogin", fallback: "Launch at Login"),
                    isOn: Binding(
                        get: { systemSettings.launchAtLogin },
                        set: { systemSettings.setLaunchAtLogin($0) }
                    )
                )
                Divider()
                Button {
                    systemSettings.openDisplaySettings()
                } label: {
                    Label(
                        L10n.tr("action.displaySettings", fallback: "Display Settings"),
                        systemImage: "display"
                    )
                }
            } label: {
                Image(systemName: "gearshape")
                    .frame(width: 26, height: 24)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help(L10n.tr("action.displaySettings", fallback: "Display Settings"))

            Menu {
                ForEach(AppLanguage.menuCases) { language in
                    Button {
                        localizationSettings.language = language
                    } label: {
                        if localizationSettings.language == language {
                            Label(language.displayName, systemImage: "checkmark")
                        } else {
                            Text(language.displayName)
                        }
                    }
                }
            } label: {
                Image(systemName: "globe")
                    .frame(width: 26, height: 24)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help(L10n.tr("setting.language", fallback: "Language"))

            Spacer()

            Button {
                displayService.disable()
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .frame(width: 26, height: 24)
            }
            .buttonStyle(.borderless)
            .help(L10n.tr("action.quit", fallback: "Quit"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { displayService.errorMessage != nil || systemSettings.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    displayService.errorMessage = nil
                    systemSettings.errorMessage = nil
                }
            }
        )
    }
}

private struct ResolutionRow: View {
    let resolution: DisplayResolution
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 24, height: 24)

                Text(resolution.label)
                    .font(.system(size: 13).monospacedDigit())

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 12)
                } else {
                    Color.clear
                        .frame(width: 12, height: 12)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovered ? Color.primary.opacity(0.055) : Color.clear)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isSelected)
        .onHover { isHovered = $0 }
    }
}
