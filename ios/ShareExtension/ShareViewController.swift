import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private let appGroupId = "group.com.clib.clib"
    private let sharedKey = "SharedURLs"
    private let labelsKey = "SharedLabels"

    private var sharedURL: String?
    private var labels: [(name: String, colorValue: Int)] = []
    private var selectedLabels: Set<String> = []
    private var chipButtons: [UIButton] = []

    // MARK: - UI

    private let handleBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray4
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Clib에 저장"
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let urlLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingMiddle
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let labelSectionTitle: UILabel = {
        let l = UILabel()
        l.text = "라벨"
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let chipsContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let cancelButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "취소"
        config.baseForegroundColor = .systemGray
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "저장"
        config.cornerStyle = .capsule
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        loadLabels()
        setupUI()
        extractSharedURL()

        cancelButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
    }

    // MARK: - Setup

    private func loadLabels() {
        guard let userDefaults = UserDefaults(suiteName: appGroupId),
              let jsonString = userDefaults.string(forKey: labelsKey),
              let data = jsonString.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return }

        labels = array.compactMap { dict in
            guard let name = dict["name"] as? String,
                  let colorValue = dict["colorValue"] as? Int
            else { return nil }
            return (name: name, colorValue: colorValue)
        }
    }

    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(handleBar)
        containerView.addSubview(titleLabel)
        containerView.addSubview(urlLabel)

        let divider = UIView()
        divider.backgroundColor = UIColor.separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(divider)

        containerView.addSubview(labelSectionTitle)
        containerView.addSubview(chipsContainer)

        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            handleBar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            handleBar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 40),
            handleBar.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            urlLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            urlLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            urlLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            divider.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 16),
            divider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            labelSectionTitle.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
            labelSectionTitle.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),

            chipsContainer.topAnchor.constraint(equalTo: labelSectionTitle.bottomAnchor, constant: 12),
            chipsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            chipsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            buttonStack.topAnchor.constraint(equalTo: chipsContainer.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 48),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])

        buildChips()
    }

    private func buildChips() {
        chipButtons.forEach { $0.removeFromSuperview() }
        chipButtons = []

        if labels.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "앱에서 라벨을 추가하면 여기서 선택할 수 있어요"
            emptyLabel.font = .systemFont(ofSize: 13)
            emptyLabel.textColor = .tertiaryLabel
            emptyLabel.numberOfLines = 2
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            chipsContainer.addSubview(emptyLabel)
            NSLayoutConstraint.activate([
                emptyLabel.topAnchor.constraint(equalTo: chipsContainer.topAnchor),
                emptyLabel.bottomAnchor.constraint(equalTo: chipsContainer.bottomAnchor),
                emptyLabel.leadingAnchor.constraint(equalTo: chipsContainer.leadingAnchor),
                emptyLabel.trailingAnchor.constraint(equalTo: chipsContainer.trailingAnchor),
            ])
            return
        }

        // Flow layout
        let chipHeight: CGFloat = 34
        let hSpacing: CGFloat = 8
        let vSpacing: CGFloat = 8
        let maxWidth = UIScreen.main.bounds.width - 40

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var totalHeight: CGFloat = chipHeight

        for labelData in labels {
            let btn = makeChipButton(for: labelData)
            btn.sizeToFit()
            let btnWidth = max(btn.intrinsicContentSize.width + 24, 60)

            if currentX + btnWidth > maxWidth && currentX > 0 {
                currentX = 0
                currentY += chipHeight + vSpacing
                totalHeight += chipHeight + vSpacing
            }

            btn.frame = CGRect(x: currentX, y: currentY, width: btnWidth, height: chipHeight)
            chipsContainer.addSubview(btn)
            chipButtons.append(btn)

            currentX += btnWidth + hSpacing
        }

        // 고정 높이
        let heightConstraint = chipsContainer.heightAnchor.constraint(equalToConstant: totalHeight)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }

    private func makeChipButton(for labelData: (name: String, colorValue: Int)) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(labelData.name, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.layer.cornerRadius = 17
        btn.layer.masksToBounds = true
        btn.tag = labels.firstIndex(where: { $0.name == labelData.name }) ?? 0

        let color = UIColor(argb: labelData.colorValue)
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = color.cgColor
        btn.setTitleColor(color, for: .normal)
        btn.setTitleColor(.white, for: .selected)
        btn.backgroundColor = .clear

        btn.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        return btn
    }

    // MARK: - Actions

    @objc private func chipTapped(_ sender: UIButton) {
        let name = labels[sender.tag].name
        let color = UIColor(argb: labels[sender.tag].colorValue)

        if selectedLabels.contains(name) {
            selectedLabels.remove(name)
            sender.isSelected = false
            sender.backgroundColor = .clear
        } else {
            selectedLabels.insert(name)
            sender.isSelected = true
            sender.backgroundColor = color
        }
    }

    @objc private func save() {
        guard let url = sharedURL else {
            close()
            return
        }

        let payload: [String: Any] = [
            "url": url,
            "labels": Array(selectedLabels)
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: data, encoding: .utf8),
           let userDefaults = UserDefaults(suiteName: appGroupId) {
            var items = userDefaults.stringArray(forKey: sharedKey) ?? []
            items.append(jsonString)
            userDefaults.set(items, forKey: sharedKey)
            userDefaults.synchronize()
        }

        close()
    }

    @objc private func close() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    // MARK: - URL Extraction

    private func extractSharedURL() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else { return }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, _ in
                        DispatchQueue.main.async {
                            if let url = data as? URL {
                                self?.sharedURL = url.absoluteString
                                self?.urlLabel.text = url.absoluteString
                            }
                        }
                    }
                    return
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, _ in
                        DispatchQueue.main.async {
                            if let text = data as? String,
                               let url = self?.extractURL(from: text) {
                                self?.sharedURL = url
                                self?.urlLabel.text = url
                            }
                        }
                    }
                    return
                }
            }
        }
    }

    private func extractURL(from text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(location: 0, length: text.utf16.count)
        return detector?.matches(in: text, options: [], range: range).first?.url?.absoluteString
    }
}

// MARK: - UIColor from ARGB Int

private extension UIColor {
    convenience init(argb: Int) {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
