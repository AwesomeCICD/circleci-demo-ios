//
//  GameViewController.swift
//  Game
//
//  BCP Mobile — banking shell that displays loaded React Native mini-app modules.
//

import UIKit

struct BundleManifest: Codable {
    let build: String
    let branch: String
    let modules: [MiniAppModule]
}

struct MiniAppModule: Codable {
    let name: String
    let platform: String
    let size: Int
    let bundledAt: String
}

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.063, green: 0.122, blue: 0.302, alpha: 1.0)
        setupUI(manifest: loadManifest())
    }

    private func loadManifest() -> BundleManifest? {
        guard let url = Bundle.main.url(forResource: "bundle_manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(BundleManifest.self, from: data)
    }

    private func setupUI(manifest: BundleManifest?) {
        let headerLabel = makeLabel("BCP Mobile", size: 32, weight: .bold, alpha: 1.0)
        let subtitleLabel = makeLabel("Banco de Crédito del Perú", size: 14, weight: .regular, alpha: 0.7)

        let divider = UIView()
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let buildText = manifest.map { "Build #\($0.build)  ·  Branch: \($0.branch)" } ?? "Build: local"
        let buildLabel = UILabel()
        buildLabel.text = buildText
        buildLabel.font = UIFont(name: "Menlo-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
        buildLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        buildLabel.textAlignment = .center

        let sectionLabel = makeLabel("LOADED MINI-APP MODULES", size: 11, weight: .semibold, alpha: 0.5)
        sectionLabel.textAlignment = .left

        let moduleStack = UIStackView()
        moduleStack.axis = .vertical
        moduleStack.spacing = 12

        let modules = manifest?.modules ?? [
            MiniAppModule(name: "payments", platform: "ios", size: 0, bundledAt: ""),
            MiniAppModule(name: "transfers", platform: "ios", size: 0, bundledAt: "")
        ]
        modules.forEach { moduleStack.addArrangedSubview(moduleCard(for: $0)) }

        let statusLabel = makeLabel("● All modules loaded", size: 13, weight: .medium, alpha: 1.0)
        statusLabel.textColor = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
        statusLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [
            headerLabel,
            subtitleLabel,
            spacer(20),
            divider,
            spacer(12),
            buildLabel,
            spacer(16),
            sectionLabel,
            spacer(4),
            moduleStack,
            spacer(20),
            statusLabel
        ])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }

    private func moduleCard(for module: MiniAppModule) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        card.layer.cornerRadius = 12

        let nameLabel = makeLabel(module.name.capitalized, size: 17, weight: .semibold, alpha: 1.0)
        let platformLabel = makeLabel("iOS · React Native", size: 13, weight: .regular, alpha: 0.6)

        let sizeText = module.size > 0 ? String(format: "%.1f KB", Double(module.size) / 1024.0) : "—"
        let sizeLabel = makeLabel(sizeText, size: 13, weight: .regular, alpha: 0.7)
        sizeLabel.font = UIFont(name: "Menlo-Regular", size: 13) ?? UIFont.systemFont(ofSize: 13)
        sizeLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        sizeLabel.textAlignment = .right

        let checkmark = makeLabel("✓", size: 17, weight: .bold, alpha: 1.0)
        checkmark.textColor = UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)
        checkmark.textAlignment = .right

        let leftStack = UIStackView(arrangedSubviews: [nameLabel, platformLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 2

        let rightStack = UIStackView(arrangedSubviews: [sizeLabel, checkmark])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        rightStack.spacing = 2

        let row = UIStackView(arrangedSubviews: [leftStack, rightStack])
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
        return card
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight, alpha: CGFloat) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: size, weight: weight)
        label.textColor = UIColor.white.withAlphaComponent(alpha)
        label.textAlignment = .center
        return label
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    }

    override var prefersStatusBarHidden: Bool { return false }
}
