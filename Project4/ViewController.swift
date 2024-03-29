//
//  ViewController.swift
//  Project4
//
//  Created by Anouar El maaroufi on 3/5/24.
//  Copyright © 2024 Anouar El maaroufi. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    var progressView: UIProgressView!
    var allowedWebsites = [String]()
    
    override func loadView() {
        webView = WKWebView()
        
        // Add self (current view controller) as the web view's navigation delegatei
        webView.navigationDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Reading the proprty List from the app bundle
        let filePath = Bundle.main.path(forResource: "allowed_websites", ofType: "plist")!
        
        if let data = FileManager.default.contents(atPath: filePath) {
            let websites = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
            if let websiteArray = websites as? [String] {
                for website in websiteArray {
                    allowedWebsites.append(website)
                }
            }
        }

        // Loading the first URL to the web view
        let url = URL(string: "https://" + allowedWebsites[0])!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Open", style: .plain, target: self, action: #selector(openTapped))

        // Progress bar
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.sizeToFit()
        let progressButton = UIBarButtonItem(customView: progressView)

        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: webView, action: #selector(webView.reload))
        let navigatorBack = UIBarButtonItem(image: UIImage(named: "left_arrow"), style: .plain, target: webView, action: #selector(webView.goBack))
        let navigatorForward = UIBarButtonItem(image: UIImage(named: "right_arrow"), style: .plain, target: webView, action: #selector(webView.goForward))

        navigationItem.leftBarButtonItem = refresh
        toolbarItems = [navigatorBack, spacer, progressButton, spacer, navigatorForward]
        navigationController?.isToolbarHidden = false

        // Add observer to the estimated property of the WKWebView object using KVO methodology
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
        }
    }

    @objc func openTapped() {
        let ac = UIAlertController(title: "Open page…", message: nil, preferredStyle: .actionSheet)
        for website in allowedWebsites {
            ac.addAction(UIAlertAction(title: website, style: .default, handler: openPage))
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        present(ac, animated: true)
    }

    func openPage(action: UIAlertAction) {
        let url = URL(string: "https://" + action.title!)!
        webView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        if let host = url?.host {
            for website in allowedWebsites {
                if host.contains(website) {
                    decisionHandler(.allow)
                    return
                }
            }
            let ac = UIAlertController(title: "Blocked", message: "The website you visited is not allowed", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Continue", style: .cancel))
            ac.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
            present(ac, animated: true)
        }
        decisionHandler(.cancel)
    }

}
