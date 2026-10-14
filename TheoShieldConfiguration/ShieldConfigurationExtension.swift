import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            title: .init(text: "Deadline Theo", color: .label),
            subtitle: .init(text: "给我学。\nYou asked me to stop you.", color: .secondaryLabel),
            primaryButtonLabel: .init(text: "好，回去学习", color: .white),
            primaryButtonBackgroundColor: .systemBlue
        )
    }
}
