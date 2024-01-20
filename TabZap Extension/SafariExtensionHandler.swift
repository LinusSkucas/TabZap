//
//  SafariExtensionHandler.swift
//  TabZap Extension
//
//  Created by Linus Skucas on 1/19/24.
//

import SafariServices
import os.log

class SafariExtensionHandler: SFSafariExtensionHandler {

    override func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        os_log(.default, "The extension received a request for profile: %@", profile?.uuidString ?? "none")
    }

    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        page.getPropertiesWithCompletionHandler { properties in
            os_log(.default, "The extension received a message (%@) from a script injected into (%@) with userInfo (%@)", messageName, String(describing: properties?.url), userInfo ?? [:])
        }
    }

    override func toolbarItemClicked(in window: SFSafariWindow) {
        os_log(.default, "The extension's toolbar item was clicked")
        Task {
            var tabList = [(URL, SFSafariTab)]()
            let tabs = await window.allTabs()
            for tab in tabs {
                if let page = await tab.activePage(),
                   let pageProperties = await page.properties(),
                   let url = pageProperties.url {
                    tabList.append((url, tab))
                }
            }
            
            // Compare and close tabs
            let crossReference = Dictionary(grouping: tabList, by: \.0)
            crossReference
                .filter {
                    $1.count > 1
                }
                .forEach { (url, tabs) in
                    tabs.dropFirst().forEach { (_, tab) in
                        tab.close()
                    }
                }
        }
    }

    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        validationHandler(true, "")
    }

    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }

}
