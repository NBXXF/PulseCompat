// The MIT License (MIT)
//
// Copyright (c) 2020-2023 Alexander Grebenyuk (github.com/kean).

import Pulse
import PulseUI
import SwiftUI
import UIKit

final class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [MenuSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "PulseUI"

        sections = [
            MenuSection(title: "Main", footer: "Demonstartes how to show the entire PulseUI interface (all four tabs)", items: [
                MenuItem(title: "MainViewController", isPush: false, action: { [unowned self] in
                    let vc = MainViewController(store: .mock)
                    self.present(vc, animated: true, completion: nil)
                }),
                MenuItem(title: "MainViewController (Fullscreen)", isPush: false, action: { [unowned self] in
                    let vc = MainViewController(store: .mock)
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: nil)
                }),
            ]),
            MenuSection(title: "Components", footer: "Demonstrates how you can push individual PulseUI screens into an existing navigation (UINavigationController or NavigationView)", items: [
                MenuItem(title: "ConsoleView", action: { [unowned self] in
                    let vc = UIHostingController(rootView: ConsoleView(store: .mock).closeButtonHidden())
                    self.navigationController?.pushViewController(vc, animated: true)
                }),
                MenuItem(title: "ConsoleView (Logs)", action: { [unowned self] in
                    let vc = UIHostingController(rootView: ConsoleView(store: .mock, mode: .logs).closeButtonHidden())
                    self.navigationController?.pushViewController(vc, animated: true)
                }),
                MenuItem(title: "ConsoleView (Network)", action: { [unowned self] in
                    let vc = UIHostingController(rootView: ConsoleView(store: .mock, mode: .network).closeButtonHidden())
                    self.navigationController?.pushViewController(vc, animated: true)
                }),
            ]),
            MenuSection(title: "Custom Views", footer: "Custom views into the underlying logger data", items: [
                MenuItem(title: "User Analytics", action: { [unowned self] in
                    let view = DebugAnalyticsView()
                        .environment(\.managedObjectContext, LoggerStore.mock.viewContext)
                    let vc = UIHostingController(rootView: view)
                    self.navigationController?.pushViewController(vc, animated: true)
                }),
            ]),
            MenuSection(title: "Modal", footer: "The same screens, but as a modal view controller", items: [
                MenuItem(title: "Show Modally", action: { [unowned self] in
                    let vc = ViewController()
                    let navigation = UINavigationController(rootViewController: vc)
                    self.present(navigation, animated: true)
                }),
            ]),
        ]

        view.addSubview(tableView)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "a")

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])

        tableView.dataSource = self
        tableView.delegate = self
    }

    func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        sections[section].footer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "a", for: indexPath)
        let item = sections[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.isPush ? .disclosureIndicator : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]
        item.action()
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

struct MenuSection {
    let title: String
    let footer: String
    let items: [MenuItem]
}

struct MenuItem {
    let title: String
    var isPush: Bool = true
    let action: () -> Void
}
