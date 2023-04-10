//
//  ViewController.swift
//  WebBrowser
//
//  Created by c.mos on 2020/05/21.
//  Copyright © 2020 c.mos. All rights reserved.
//

import UIKit
import WebKit

let javaScript = """
var style = document.createElement('style');
style.type = "text/css";
style.innerText = '%@';
document.getElementsByTagName('head').item(0).appendChild(style);
document.querySelector('.topbar-spacer').style['padding-top'] = '48px';
"""

let userAgentSafari = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15"

enum Button: Int {
	case back = 0
	case forward = 1
	case reload = 2
}

let colorNormal = UIColor(red: 76.0/255, green: 158.0/255, blue: 235.0/255, alpha: 1.0)
let colorBGHot  = UIColor(red: 76.0/255, green: 158.0/255, blue: 235.0/255, alpha: 0.4)
let colorDisabled = UIColor.lightGray

class ViewController: UIViewController {

	let webView = WKWebView()

	var buttons: [UIButtonEx?] = []

    let targetUrl = "https://twitter.com/"
    let cssFilename = "twitter.css"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        guard let dirUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("documentDirectory error.")
        }
        let fileUrl = dirUrl.appendingPathComponent(cssFilename)
        if !FileManager.default.fileExists(atPath: fileUrl.path) {
            print("'\(cssFilename)' not exist, copy it.")
            guard let path = Bundle.main.path(forResource: "twitter", ofType: "css") else {
                fatalError("'\(cssFilename)' file not found.")
            }
            guard let cssText = try? String(contentsOfFile: path) else {
                fatalError("'\(cssFilename)' read failed.")
            }
            do {
                try cssText.write(to: fileUrl, atomically: false, encoding: .utf8)
            } catch {
                fatalError("'\(cssFilename)' write failed.")
            }
        }
        guard let cssString = try? String(contentsOfFile: fileUrl.path) else {
            fatalError("'\(cssFilename)' read failed.")
        }
        let cssString1 = cssString.replacingOccurrences(of: "\n", with: "")
        let cssScript = String(format: javaScript, cssString1)
//      print(cssScript)

        
		let script = WKUserScript(source: cssScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
		webView.configuration.userContentController.addUserScript(script)

        webView.frame = view.frame
		webView.navigationDelegate = self
		webView.uiDelegate = self
		webView.customUserAgent = userAgentSafari
		webView.allowsBackForwardNavigationGestures = true // Enable back/forward by swiping

		let urlRequest = URLRequest(url:URL(string:targetUrl)!)
		webView.load(urlRequest)
		view.addSubview(webView)

		createButtons()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

    override var prefersHomeIndicatorAutoHidden: Bool { true }

    private func createButtons() {
		createButton(name: "back", selector: #selector(goBack), isEnabled: false)
		createButton(name: "forward", selector: #selector(goForward), isEnabled: false)
		createButton(name: "reload", selector: #selector(reload), isEnabled: true)
	}

	private func createButton(name: String, selector: Selector, isEnabled: Bool) {
		let size = CGSize(width:40, height:40)
//		let offseetUnderBottom:CGFloat = 60
//		let yPos = (UIScreen.main.bounds.height - offseetUnderBottom)
		let xPos: CGFloat = 316
		let yPos: CGFloat = 8
        let xPaddings:[CGFloat] = [ 0, 10, 24]
		let index = buttons.count

		let pos = CGPoint(x:(size.width + xPaddings[index]) * CGFloat(index) + xPos, y:yPos)
		let button = UIButtonEx(frame: CGRect(origin: pos, size: size))
		buttons.append(button)
        button.name = name
		button.layer.backgroundColor = UIColor.clear.cgColor
//		button.layer.opacity = 0.0
		button.layer.cornerRadius = 5.0
		
		let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
		button.setImage(image, for: .normal)
		button.tintColor = colorNormal

		button.addTarget(self, action: selector, for: .touchUpInside)
		button.addTarget(self, action: #selector(buttonDown), for: .touchDown)
		button.isEnabled = isEnabled
		view.addSubview(button)
	}

	@objc private func goBack(_ button: UIButton) {
		button.layer.backgroundColor = UIColor.clear.cgColor
		webView.goBack()
	}

	@objc private func goForward(_ button: UIButton) {
		button.layer.backgroundColor = UIColor.clear.cgColor
		webView.goForward()
	}

	@objc private func reload(_ button: UIButton) {
		button.layer.backgroundColor = UIColor.clear.cgColor
		webView.reload()
	}

	@objc private func buttonDown(_ button: UIButton) {
		button.layer.backgroundColor = colorBGHot.cgColor
	}
}

class UIButtonEx : UIButton {
    var name:String = ""

    open override var isEnabled: Bool{
        didSet {
            print("\(name) button " + (isEnabled ? "enabled" : "disabled"))
			tintColor = isEnabled ?  colorNormal : colorDisabled
        }
    }
}

extension ViewController: WKNavigationDelegate {

	// Called when content load completes
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

		if buttons.count > 0 {
			print("didFinish navigation")
			buttons[Button.back.rawValue]?.isEnabled = (webView.canGoBack) ? true : false
			buttons[Button.forward.rawValue]?.isEnabled = (webView.canGoForward) ? true : false
		}
	}
	
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		let url = navigationAction.request.url
		guard url != nil else {
			decisionHandler(.allow)
			return
		}

		print("URL:", url!.description)
		if !url!.description.lowercased().contains("twitter.com") {
			decisionHandler(.cancel)
			UIApplication.shared.open(url!, options: [:], completionHandler: nil)
		} else {
			decisionHandler(.allow)
		}
	}
}

// Fix target=_blank
extension ViewController: WKUIDelegate {

	func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
				 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

		if navigationAction.targetFrame == nil {
			webView.load(navigationAction.request)
		}
		return nil
	}

}
