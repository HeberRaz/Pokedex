//
//  FeatureFlagsDebugViewController.swift
//  Pokedex
//
//  Created by GitHub Copilot on 14/02/26.
//

//swiftlint:disable all
#if DEBUG
import UIKit

/// Simple debug UI to inspect and override feature controls.
///
/// It reads the last persisted `FeatureControlsSnapshot` from
/// `FileFeatureControlsSnapshotStore` and uses `UserDefaultsLocalOverrideStore`
/// to manage local overrides. This keeps it decoupled from the live service
/// while still affecting evaluations (service consults the same overrides).
final class FeatureFlagsDebugViewController: UIViewController {

    private enum Section: Int, CaseIterable {
        case flags
        case rollouts
        case experiments
        case throttles

        var title: String {
            switch self {
                case .flags: return "Flags"
                case .rollouts: return "Rollouts"
                case .experiments: return "Experiments"
                case .throttles: return "Throttling"
            }
        }
    }

    private struct Row {
        enum Kind {
            case control
            case rolloutButton
        }

        let control: FeatureControlDTO
        let kind: Kind
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let snapshotStore = FileFeatureControlsSnapshotStore()
    private let overrideStore = UserDefaultsLocalOverrideStore()

    // Rollout percentage picker (10–100%)
    private let rolloutPercentageOptions: [Int] = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    private let rolloutPicker = UIPickerView()
    private let rolloutPickerTextField = UITextField(frame: .zero)
    private var activeRolloutControlId: String?

    private var sections: [Section: [Row]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Feature Flags Debug"
        view.backgroundColor = .systemBackground

        // Picker setup (hidden textField with picker as inputView)
        rolloutPicker.dataSource = self
        rolloutPicker.delegate = self

        rolloutPickerTextField.isHidden = true
        rolloutPickerTextField.inputView = rolloutPicker
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissRolloutPicker))
        toolbar.items = [flex, done]
        rolloutPickerTextField.inputAccessoryView = toolbar
        view.addSubview(rolloutPickerTextField)

        setupTableView()
        setupNavigationItems()
        loadSnapshot()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavigationItems() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear Overrides",
            style: .plain,
            target: self,
            action: #selector(clearOverrides)
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(close)
        )
    }

    private func loadSnapshot() {
        // 1) Try the last persisted snapshot from disk (if the service has refreshed).
        if let persisted = try? snapshotStore.load() {
            let snapshot = persisted
            sections = groupedSections(from: snapshot)
            tableView.reloadData()
            return
        }

        // 2) Fallback: read the local JSON contract bundled in the app.
        if let bundled = try? loadBundledSnapshot() {
            sections = groupedSections(from: bundled)
        } else {
            sections = [:]
        }

        tableView.reloadData()
    }

    private func loadBundledSnapshot() throws -> FeatureControlsSnapshot {
        guard let url = Bundle.main.url(forResource: "feature_controls", withExtension: "json") else {
            throw NSError(domain: "FeatureFlagsDebug", code: 1, userInfo: [NSLocalizedDescriptionKey: "feature_controls.json not found in bundle"])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FeatureControlsSnapshot.self, from: data)
    }

    private func groupedSections(from snapshot: FeatureControlsSnapshot) -> [Section: [Row]] {
        var grouped: [Section: [Row]] = [:]
        for control in snapshot.controls {
            switch control.type {
                case .flag:
                    grouped[.flags, default: []].append(Row(control: control, kind: .control))
                case .rollout:
                    // Main rollout row + extra button row to select percentage
                    grouped[.rollouts, default: []].append(Row(control: control, kind: .control))
                    grouped[.rollouts, default: []].append(Row(control: control, kind: .rolloutButton))
                case .experiment:
                    grouped[.experiments, default: []].append(Row(control: control, kind: .control))
                case .throttle:
                    grouped[.throttles, default: []].append(Row(control: control, kind: .control))
            }
        }

        // Stable ordering by id for deterministic UI.
        for key in Section.allCases {
            grouped[key] = grouped[key]?.sorted { $0.control.id < $1.control.id }
        }
        return grouped
    }

    // MARK: - Actions

    @objc private func clearOverrides() {
        overrideStore.clearAll()
        tableView.reloadData()
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    // MARK: - Helpers

    private func boolOverride(for id: String) -> Bool? {
        overrideStore.overrideBool(for: id)
    }

    private func setBoolOverride(_ value: Bool?, for id: String) {
        overrideStore.setBoolOverride(value, for: id)
    }

    private func rolloutPercentageOverride(for id: String) -> Int? {
        overrideStore.overrideRolloutPercentage(for: id)
    }

    private func setRolloutPercentageOverride(_ value: Int?, for id: String) {
        overrideStore.setRolloutPercentageOverride(value, for: id)
    }

    private func variantOverride(for id: String) -> ExperimentVariant? {
        overrideStore.overrideVariant(for: id)
    }

    private func setVariantOverride(_ value: ExperimentVariant?, for id: String) {
        overrideStore.setVariantOverride(value, for: id)
    }

    private func throttleOverride(for id: String) -> ThrottleConfig? {
        overrideStore.overrideThrottle(for: id)
    }

    private func setThrottleOverride(_ value: ThrottleConfig?, for id: String) {
        overrideStore.setThrottleOverride(value, for: id)
    }
}

extension FeatureFlagsDebugViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.filter { !(sections[$0]?.isEmpty ?? true) }.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let nonEmpty = Section.allCases.filter { !(sections[$0]?.isEmpty ?? true) }
        return nonEmpty[section].title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let nonEmpty = Section.allCases.filter { !(sections[$0]?.isEmpty ?? true) }
        let key = nonEmpty[section]
        return sections[key]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let nonEmpty = Section.allCases.filter { !(sections[$0]?.isEmpty ?? true) }
        let sectionKey = nonEmpty[indexPath.section]
        guard let rows = sections[sectionKey],
              indexPath.row < rows.count else {
            return UITableViewCell()
        }
        let row = rows[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        configure(cell: cell, with: row, in: sectionKey)
        return cell
    }

    private func configure(cell: UITableViewCell, with row: Row, in section: Section) {
        let control = row.control
        // Reset base styles to avoid reuse artifacts
        cell.accessoryView = nil
        cell.textLabel?.textAlignment = .natural
        cell.textLabel?.textColor = .label
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.textLabel?.text = control.id
        cell.detailTextLabel?.text = nil
        cell.selectionStyle = .none

        switch section {
            case .flags:
                let toggle = UISwitch()
                let override = boolOverride(for: control.id)
                toggle.isOn = override ?? control.enabled
                toggle.addAction(UIAction { [weak self] _ in
                    guard let self else { return }
                    self.setBoolOverride(toggle.isOn, for: control.id)
                }, for: .valueChanged)
                cell.accessoryView = toggle
                if let override {
                    cell.detailTextLabel?.text = "override: \(override ? "ON" : "OFF")"
                } else {
                    cell.detailTextLabel?.text = "remote: \(control.enabled ? "ON" : "OFF")"
                }

            case .rollouts:
                switch row.kind {
                    case .control:
                        let toggle = UISwitch()
                        let override = boolOverride(for: control.id)
                        toggle.isOn = override ?? control.enabled
                        toggle.addAction(UIAction { [weak self] _ in
                            guard let self else { return }
                            self.setBoolOverride(toggle.isOn, for: control.id)
                        }, for: .valueChanged)
                        cell.accessoryView = toggle
                        if let override {
                            cell.detailTextLabel?.text = "override: \(override ? "ON" : "OFF")"
                        } else if let pctOverride = rolloutPercentageOverride(for: control.id) {
                            let base = control.percentage.map { "\($0)%" } ?? "n/a"
                            cell.detailTextLabel?.text = "override: \(pctOverride)% (remote: \(base))"
                        } else if let pct = control.percentage {
                            cell.detailTextLabel?.text = "remote: enabled (\(pct)%)"
                        } else {
                            cell.detailTextLabel?.text = "remote: enabled"
                        }

                    case .rolloutButton:
                        cell.textLabel?.text = "Select percentage"
                        cell.textLabel?.textAlignment = .center
                        cell.textLabel?.textColor = view.tintColor
                        cell.selectionStyle = .default
                        cell.accessoryView = nil
                        cell.detailTextLabel?.text = nil
                }

            case .experiments:
                let override = variantOverride(for: control.id)
                let segmented = UISegmentedControl(items: ["Remote", "A", "B"])
                switch override {
                    case .none:
                        segmented.selectedSegmentIndex = 0
                    case .some(.a):
                        segmented.selectedSegmentIndex = 1
                    case .some(.b):
                        segmented.selectedSegmentIndex = 2
                }
                segmented.addAction(UIAction { [weak self] _ in
                    guard let self else { return }
                    switch segmented.selectedSegmentIndex {
                        case 1: self.setVariantOverride(.a, for: control.id)
                        case 2: self.setVariantOverride(.b, for: control.id)
                        default: self.setVariantOverride(nil, for: control.id)
                    }
                }, for: .valueChanged)
                cell.accessoryView = segmented
                if let variants = control.variants {
                    let a = variants["A"] ?? 0
                    let b = variants["B"] ?? 0
                    cell.detailTextLabel?.text = "weights A=\(a) B=\(b)"
                }

            case .throttles:
                let override = throttleOverride(for: control.id)
                let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
                textField.keyboardType = .numberPad
                textField.borderStyle = .roundedRect
                textField.textAlignment = .right
                textField.placeholder = "remote"
                if let override {
                    textField.text = String(override.maxPerMinute)
                }
                textField.addAction(UIAction { [weak self] _ in
                    guard let self else { return }
                    let trimmed = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if trimmed.isEmpty {
                        self.setThrottleOverride(nil, for: control.id)
                    } else if let value = Int(trimmed), value > 0 {
                        self.setThrottleOverride(ThrottleConfig(maxPerMinute: value), for: control.id)
                    }
                }, for: .editingDidEnd)
                cell.accessoryView = textField
                if let max = control.maxPerMinute {
                    cell.detailTextLabel?.text = "remote: max/min = \(max)"
                }
        }
    }
}
extension FeatureFlagsDebugViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let nonEmpty = Section.allCases.filter { !(sections[$0]?.isEmpty ?? true) }
        let sectionKey = nonEmpty[indexPath.section]

        defer { tableView.deselectRow(at: indexPath, animated: true) }

        guard sectionKey == .rollouts,
              let rows = sections[.rollouts],
              indexPath.row < rows.count
        else { return }

        let row = rows[indexPath.row]
        guard row.kind == .rolloutButton else { return }

        let control = row.control
        activeRolloutControlId = control.id

        // Preselect picker row based on override or remote percentage
        let currentOverride = rolloutPercentageOverride(for: control.id)
        let base = currentOverride ?? control.percentage
        if let base, let index = rolloutPercentageOptions.firstIndex(of: base) {
            rolloutPicker.selectRow(index + 1, inComponent: 0, animated: false)
        } else {
            rolloutPicker.selectRow(0, inComponent: 0, animated: false)
        }

        rolloutPickerTextField.becomeFirstResponder()
    }
}

// MARK: - Rollout Picker

extension FeatureFlagsDebugViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // Row 0 = Remote (no override), rest are percentage options
        1 + rolloutPercentageOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 { return "Remote" }
        let value = rolloutPercentageOptions[row - 1]
        return "\(value)%"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let controlId = activeRolloutControlId else { return }

        if row == 0 {
            setRolloutPercentageOverride(nil, for: controlId)
        } else {
            let value = rolloutPercentageOptions[row - 1]
            setRolloutPercentageOverride(value, for: controlId)
        }

        // Refresh only the rollout row to reflect new metadata
          if let rows = sections[.rollouts],
              let rowIndex = rows.firstIndex(where: { $0.control.id == controlId && $0.kind == .control }) {
            let nonEmpty = Section.allCases.filter { !(sections[$0]?.isEmpty ?? true) }
            if let rolloutSectionIndex = nonEmpty.firstIndex(of: .rollouts) {
                let indexPath = IndexPath(row: rowIndex, section: rolloutSectionIndex)
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
}

// MARK: - Actions

extension FeatureFlagsDebugViewController {
    @objc private func dismissRolloutPicker() {
        rolloutPickerTextField.resignFirstResponder()
    }
}

#endif
//swiftlint:enable all
